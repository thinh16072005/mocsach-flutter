import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_controller.dart';
import '../widgets/admin_ui.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final controller = Get.put(AdminController());
  final _searchCtrl = TextEditingController();
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    controller.fetchUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<dynamic> _filteredUsers() {
    if (_keyword.trim().isEmpty) return controller.users;
    return controller.users.where((u) {
      return adminMatchesKeyword(_keyword, [
        u['firstName']?.toString(),
        u['lastName']?.toString(),
        u['email']?.toString(),
        u['phoneNumber']?.toString(),
        u['username']?.toString(),
      ]);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final searching = _keyword.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý người dùng')),
      body: Column(
        children: [
          AdminSearchBar(
            controller: _searchCtrl,
            hint: 'Tìm theo tên, email, SĐT...',
            onChanged: (v) => setState(() => _keyword = v),
          ),
          if (searching)
            Obx(() => AdminFilterResultBar(count: _filteredUsers().length)),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = _filteredUsers();
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    searching
                        ? 'Không tìm thấy người dùng với "$_keyword"'
                        : 'Chưa có người dùng nào.',
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: items.length,
                itemBuilder: (ctx, i) {
                  final user = items[i];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${user['idUser']}')),
                      title: Text('${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim()),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['email'] ?? ''),
                          if ((user['phoneNumber'] ?? '').toString().isNotEmpty)
                            Text('SĐT: ${user['phoneNumber']}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditDialog(controller, user),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(AdminController controller, dynamic user) {
    final firstName = TextEditingController(text: user['firstName'] ?? '');
    final lastName = TextEditingController(text: user['lastName'] ?? '');
    final phone = TextEditingController(text: user['phoneNumber'] ?? '');
    final address = TextEditingController(text: user['deliveryAddress'] ?? '');

    Get.dialog(AlertDialog(
      title: const Text('Sửa người dùng'),
      content: SingleChildScrollView(
        child: AdminFormFields(
          children: [
            adminDialogField(controller: firstName, label: 'Họ đệm'),
            adminDialogField(controller: lastName, label: 'Tên'),
            adminDialogField(
              controller: phone,
              label: 'SĐT',
              keyboardType: TextInputType.phone,
            ),
            adminDialogField(controller: address, label: 'Địa chỉ'),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Huỷ')),
        ElevatedButton(
          onPressed: () async {
            final success = await controller.updateUser(user['idUser'], {
              'firstName': firstName.text.trim(),
              'lastName': lastName.text.trim(),
              'phoneNumber': phone.text.trim(),
              'deliveryAddress': address.text.trim(),
            });
            Get.back();
            if (success) Get.snackbar('Thành công', 'Cập nhật thành công');
          },
          child: const Text('Lưu'),
        ),
      ],
    ));
  }
}
