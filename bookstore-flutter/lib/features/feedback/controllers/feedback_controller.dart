import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_endpoints.dart';

class FeedbackController extends GetxController {
  final _dio = DioClient.instance;

  final isLoading = false.obs;

  Future<bool> sendFeedback(String content) async {
    isLoading.value = true;
    try {
      final response = await _dio.post(ApiEndpoints.feedbacks, data: {'content': content});
      return response.data['success'] == true;
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data?['message'] ?? 'Gửi phản hồi thất bại');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
