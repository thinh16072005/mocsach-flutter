import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_endpoints.dart';

/// Controller gộp cho các màn hình quản trị (User, Book, Genre, Order, Coupon, Feedback).
/// Mọi thao tác lỗi đều hiển thị snackbar (không nuốt lỗi im lặng).
class AdminController extends GetxController {
  final _dio = DioClient.instance;

  final users = <dynamic>[].obs;
  final genres = <dynamic>[].obs;
  final orders = <dynamic>[].obs;
  final coupons = <dynamic>[].obs;
  final feedbacks = <dynamic>[].obs;
  final unreadFeedbackCount = 0.obs;
  final isLoading = false.obs;

  // Phân trang
  final couponPage = 0.obs;
  final couponTotalPages = 1.obs;
  final feedbackPage = 0.obs;
  final feedbackTotalPages = 1.obs;

  String _msg(Object e, String fallback) {
    if (e is DioException) {
      return e.response?.data?['message']?.toString() ?? fallback;
    }
    return fallback;
  }

  void _error(Object e, String fallback) {
    Get.snackbar('Lỗi', _msg(e, fallback));
  }

  // ----- USERS -----
  Future<void> fetchUsers() async {
    isLoading.value = true;
    try {
      final resp = await _dio.get(ApiEndpoints.users);
      if (resp.data['success'] == true) users.assignAll(resp.data['data'] as List);
    } on DioException catch (e) {
      _error(e, 'Không thể tải danh sách người dùng');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateUser(int id, Map<String, dynamic> data) async {
    try {
      final resp = await _dio.patch(ApiEndpoints.userById(id), data: data);
      if (resp.data['success'] == true) {
        fetchUsers();
        return true;
      }
      Get.snackbar('Lỗi', resp.data['message'] ?? 'Cập nhật người dùng thất bại');
      return false;
    } on DioException catch (e) {
      _error(e, 'Cập nhật người dùng thất bại');
      return false;
    }
  }

  // ----- GENRES -----
  Future<void> fetchGenres() async {
    isLoading.value = true;
    try {
      final resp = await _dio.get(ApiEndpoints.genres);
      if (resp.data['success'] == true) genres.assignAll(resp.data['data'] as List);
    } on DioException catch (e) {
      _error(e, 'Không thể tải thể loại');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createGenre(String name) async {
    try {
      final resp = await _dio.post(ApiEndpoints.genres, data: {'nameGenre': name});
      if (resp.data['success'] == true) {
        fetchGenres();
        return true;
      }
      Get.snackbar('Lỗi', resp.data['message'] ?? 'Tạo thể loại thất bại');
      return false;
    } on DioException catch (e) {
      _error(e, 'Tạo thể loại thất bại');
      return false;
    }
  }

  Future<bool> updateGenre(int id, String name) async {
    try {
      await _dio.put(ApiEndpoints.genreById(id), data: {'nameGenre': name});
      fetchGenres();
      return true;
    } on DioException catch (e) {
      _error(e, 'Cập nhật thể loại thất bại');
      return false;
    }
  }

  Future<bool> deleteGenre(int id) async {
    try {
      await _dio.delete(ApiEndpoints.genreById(id));
      genres.removeWhere((g) => g['idGenre'] == id);
      return true;
    } on DioException catch (e) {
      _error(e, 'Không thể xóa (thể loại có thể đang được dùng)');
      return false;
    }
  }

  // ----- ORDERS -----
  Future<void> fetchOrders() async {
    isLoading.value = true;
    try {
      final resp = await _dio.get(ApiEndpoints.orders);
      if (resp.data['success'] == true) orders.assignAll(resp.data['data'] as List);
    } on DioException catch (e) {
      _error(e, 'Không thể tải đơn hàng');
    } finally {
      isLoading.value = false;
    }
  }

  /// Lấy chi tiết đơn (kèm listOrderDetails sau R2) cho màn xem chi tiết admin.
  Future<Map<String, dynamic>?> getOrderDetail(int id) async {
    try {
      final resp = await _dio.get(ApiEndpoints.orderById(id));
      if (resp.data['success'] == true) {
        return Map<String, dynamic>.from(resp.data['data']);
      }
    } on DioException catch (e) {
      _error(e, 'Không thể tải chi tiết đơn');
    }
    return null;
  }

  Future<bool> updateOrderStatus(int id, String status) async {
    try {
      await _dio.put(ApiEndpoints.orderStatus(id), data: {'status': status});
      fetchOrders();
      return true;
    } on DioException catch (e) {
      _error(e, 'Cập nhật trạng thái thất bại');
      return false;
    }
  }

  // ----- COUPONS -----
  Future<void> fetchCoupons({int? page, int size = 10}) async {
    if (page != null) couponPage.value = page;
    isLoading.value = true;
    try {
      final resp = await _dio.get(ApiEndpoints.coupons, queryParameters: {
        'page': couponPage.value,
        'size': size,
      });
      if (resp.data['success'] == true) {
        final data = resp.data['data'];
        coupons.assignAll(data['content'] as List);
        couponTotalPages.value = data['totalPages'] ?? 1;
      }
    } on DioException catch (e) {
      _error(e, 'Không thể tải mã giảm giá');
    } finally {
      isLoading.value = false;
    }
  }

  void couponNextPage() {
    if (couponPage.value < couponTotalPages.value - 1) {
      fetchCoupons(page: couponPage.value + 1);
    }
  }

  void couponPrevPage() {
    if (couponPage.value > 0) {
      fetchCoupons(page: couponPage.value - 1);
    }
  }

  Future<bool> createCouponBatch(int quantity, int discountPercent, String expiryDate) async {
    try {
      await _dio.post('${ApiEndpoints.couponBatch}?quantity=$quantity',
          data: {'discountPercent': discountPercent, 'expiryDate': expiryDate});
      fetchCoupons(page: 0);
      return true;
    } on DioException catch (e) {
      _error(e, 'Tạo mã giảm giá thất bại');
      return false;
    }
  }

  Future<void> toggleCoupon(int id) async {
    try {
      await _dio.put(ApiEndpoints.couponToggle(id));
      fetchCoupons();
    } on DioException catch (e) {
      _error(e, 'Không thể đổi trạng thái mã');
    }
  }

  Future<void> deleteCoupon(int id) async {
    try {
      await _dio.delete(ApiEndpoints.couponById(id));
      coupons.removeWhere((c) => c['idCoupon'] == id);
    } on DioException catch (e) {
      _error(e, 'Không thể xóa mã');
    }
  }

  // ----- FEEDBACKS -----
  Future<void> fetchFeedbacks({int? page, int size = 10}) async {
    if (page != null) feedbackPage.value = page;
    isLoading.value = true;
    try {
      final resp = await _dio.get(ApiEndpoints.feedbacks, queryParameters: {
        'page': feedbackPage.value,
        'size': size,
      });
      if (resp.data['success'] == true) {
        final data = resp.data['data'];
        feedbacks.assignAll(data['content'] as List);
        feedbackTotalPages.value = data['totalPages'] ?? 1;
      }
      await fetchUnreadCount();
    } on DioException catch (e) {
      _error(e, 'Không thể tải phản hồi');
    } finally {
      isLoading.value = false;
    }
  }

  void feedbackNextPage() {
    if (feedbackPage.value < feedbackTotalPages.value - 1) {
      fetchFeedbacks(page: feedbackPage.value + 1);
    }
  }

  void feedbackPrevPage() {
    if (feedbackPage.value > 0) {
      fetchFeedbacks(page: feedbackPage.value - 1);
    }
  }

  /// Đếm phản hồi chưa đọc (cho badge dashboard).
  Future<void> fetchUnreadCount() async {
    try {
      final countResp = await _dio.get(ApiEndpoints.feedbackUnreadCount);
      if (countResp.data['success'] == true) {
        unreadFeedbackCount.value = (countResp.data['data'] as num?)?.toInt() ?? 0;
      }
    } on DioException {
      // Badge không chặn luồng; bỏ qua lỗi đếm.
    }
  }

  Future<void> markFeedbackRead(int id) async {
    try {
      await _dio.put(ApiEndpoints.feedbackRead(id));
      fetchFeedbacks();
    } on DioException catch (e) {
      _error(e, 'Không thể đánh dấu đã đọc');
    }
  }

  Future<void> deleteFeedback(int id) async {
    try {
      await _dio.delete(ApiEndpoints.feedbackById(id));
      feedbacks.removeWhere((f) => f['idFeedback'] == id);
    } on DioException catch (e) {
      _error(e, 'Không thể xóa phản hồi');
    }
  }
}
