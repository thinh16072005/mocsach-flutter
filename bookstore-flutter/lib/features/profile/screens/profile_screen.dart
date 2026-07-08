import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/theme/theme_controller.dart';
import '../controllers/profile_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../shared/widgets/custom_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileController());
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản'),
        actions: const [
          _ThemeToggle(),
        ],
      ),
      body: Obx(() {
        if (!controller.isLoggedIn.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_circle, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Bạn chưa đăng nhập', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Get.toNamed('/login'),
                  icon: const Icon(Icons.login),
                  label: const Text('Đăng nhập ngay'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        }

        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final user = controller.user.value;
        if (user == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 56, color: Colors.grey),
                const SizedBox(height: 12),
                Text(controller.errorMessage.value.isNotEmpty
                    ? controller.errorMessage.value
                    : 'Không tải được thông tin'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: controller.fetchProfile,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => _pickAvatar(controller),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          (user.avatar != null && user.avatar!.isNotEmpty)
                              ? CachedNetworkImageProvider(user.avatar!)
                              : null,
                      child: (user.avatar == null || user.avatar!.isEmpty)
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                    const Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.indigo,
                        child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(user.fullName.isEmpty ? user.email : user.fullName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(user.email, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              _infoTile(Icons.phone, 'Số điện thoại', _orDefault(user.phoneNumber)),
              _infoTile(Icons.location_on, 'Địa chỉ', _orDefault(user.deliveryAddress)),
              _infoTile(Icons.cake, 'Ngày sinh', _orDefault(user.dateOfBirth)),
              _infoTile(Icons.wc, 'Giới tính', _genderLabel(user.gender)),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Chỉnh sửa thông tin',
                icon: Icons.edit,
                onPressed: () => Get.toNamed('/edit-profile'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => Get.toNamed('/change-password'),
                  icon: const Icon(Icons.lock),
                  label: const Text('Đổi mật khẩu'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => Get.toNamed('/orders'),
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Đơn hàng của tôi'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => Get.toNamed('/favorites'),
                  icon: const Icon(Icons.favorite),
                  label: const Text('Sách yêu thích'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => Get.toNamed('/feedback'),
                  icon: const Icon(Icons.feedback),
                  label: const Text('Gửi phản hồi'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    foregroundColor: Colors.red,
                  ),
                  onPressed: () => Get.dialog(
                    AlertDialog(
                      title: const Text('Xác nhận đăng xuất'),
                      content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này?'),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () {
                            Get.back();
                            authController.logout();
                          },
                          child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Đăng xuất'),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    );
  }

  String _orDefault(String? v) => (v != null && v.isNotEmpty) ? v : 'Chưa cập nhật';

  // Backend lưu giới tính 1 ký tự ('M'/'F'); hiển thị tiếng Việt.
  String _genderLabel(String? g) {
    if (g == null || g.isEmpty) return 'Chưa cập nhật';
    switch (g.toUpperCase()) {
      case 'M':
        return 'Nam';
      case 'F':
        return 'Nữ';
      default:
        return g;
    }
  }

  Future<void> _pickAvatar(ProfileController controller) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      final success = await controller.changeAvatar(File(picked.path));
      Get.snackbar(success ? 'Thành công' : 'Lỗi',
          success ? 'Đổi avatar thành công!' : 'Đổi avatar thất bại');
    }
  }


}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    final themeController = Get.put(ThemeController(), permanent: true);
    return Obx(() => IconButton(
      tooltip: 'Chế độ sáng/tối',
      icon: Icon(themeController.isDark ? Icons.light_mode : Icons.dark_mode),
      onPressed: themeController.toggle,
    ));
  }
}