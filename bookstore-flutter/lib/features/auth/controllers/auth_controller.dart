import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';

class AuthController extends GetxController {
  final _dio = DioClient.instance;

  final isLoading = false.obs;
  final errorMessage = ''.obs;

  Future<bool> login(String username, String password) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await _dio.post(ApiEndpoints.login,
          data: {'username': username, 'password': password});

      final body = response.data;
      if (body['success'] == true) {
        final token = body['data']['token'];
        await TokenStorage.saveToken(token);

        // Giải mã JWT để lấy userId và role (ép kiểu an toàn để không crash)
        final payload = _decodeJwt(token);
        final userId = (payload['id'] as num?)?.toInt() ?? 0;
        final role = payload['role']?.toString() ?? 'USER';
        await TokenStorage.saveUserInfo(userId, role);

        return true;
      } else {
        errorMessage.value = body['message'] ?? 'Đăng nhập thất bại!';
        return false;
      }
    } on DioException catch (e) {
      errorMessage.value = e.response?.data?['message'] ?? 'Lỗi kết nối!';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> register(String username, String password, String email,
      String firstName, String lastName) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await _dio.post(ApiEndpoints.register, data: {
        'username': username,
        'password': password,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
      });
      final body = response.data;
      if (body['success'] == true) return true;
      errorMessage.value = body['message'] ?? 'Đăng ký thất bại!';
      return false;
    } on DioException catch (e) {
      errorMessage.value = e.response?.data?['message'] ?? 'Lỗi kết nối!';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await _dio.put(
        ApiEndpoints.changePassword,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );
      final body = response.data;
      if (body['success'] == true) return true;
      errorMessage.value = body['message'] ?? 'Đổi mật khẩu thất bại!';
      return false;
    } on DioException catch (e) {
      errorMessage.value = e.response?.data?['message'] ?? 'Lỗi kết nối!';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await _dio.put(ApiEndpoints.forgotPassword,
          data: {'email': email});
      final body = response.data;
      if (body['success'] == true) return true;
      errorMessage.value = body['message'] ?? 'Không thể gửi mật khẩu tạm';
      return false;
    } on DioException catch (e) {
      errorMessage.value = e.response?.data?['message'] ?? 'Email không tồn tại hoặc lỗi kết nối';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await TokenStorage.clearAll();
    Get.offAllNamed('/home');
  }

  /// Điều hướng sau khi xác thực: ADMIN → /admin, còn lại → /home.
  /// Dùng chung ở Login và Splash để tránh lệch logic.
  Future<void> navigateAfterAuth() async {
    final role = await TokenStorage.getUserRole();
    Get.offAllNamed(role == 'ADMIN' ? '/admin' : '/home');
  }

  Map<String, dynamic> _decodeJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return {};
    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    return json.decode(utf8.decode(base64Url.decode(normalized)));
  }
}
