import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/models/user_model.dart';
import '../../../core/storage/token_storage.dart';

class ProfileController extends GetxController {
  final _dio = DioClient.instance;

  final user = Rxn<UserModel>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final userId = await TokenStorage.getUserId();
    if (userId == null) return;
    isLoading.value = true;
    try {
      final response = await _dio.get(ApiEndpoints.userById(userId));
      if (response.data['success'] == true) {
        user.value = UserModel.fromJson(response.data['data']);
      }
    } on DioException catch (e) {
      errorMessage.value = e.response?.data?['message'] ?? 'Không thể tải thông tin';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    final userId = await TokenStorage.getUserId();
    if (userId == null) return false;
    try {
      final response = await _dio.put(ApiEndpoints.userProfile(userId), data: data);
      if (response.data['success'] == true) {
        await fetchProfile();
        return true;
      }
      errorMessage.value = response.data['message'] ?? '';
      return false;
    } on DioException catch (e) {
      errorMessage.value = e.response?.data?['message'] ?? 'Lỗi kết nối';
      return false;
    }
  }

  Future<bool> changeAvatar(File imageFile) async {
    final userId = await TokenStorage.getUserId();
    if (userId == null) return false;
    try {
      final bytes = await imageFile.readAsBytes();
      final mime = _detectImageMime(imageFile.path, bytes);
      final base64Image = 'data:$mime;base64,${base64Encode(bytes)}';
      final response = await _dio.put(ApiEndpoints.userAvatar(userId),
          data: {'avatar': base64Image});
      if (response.data['success'] == true) {
        await fetchProfile();
        return true;
      }
      return false;
    } on DioException catch (e) {
      errorMessage.value = e.response?.data?['message'] ?? 'Đổi avatar thất bại';
      return false;
    }
  }

  /// Phát hiện mime ảnh từ magic bytes (PNG vs JPEG), mặc định jpeg.
  String _detectImageMime(String path, List<int> bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (path.toLowerCase().endsWith('.png')) return 'image/png';
    return 'image/jpeg';
  }
}
