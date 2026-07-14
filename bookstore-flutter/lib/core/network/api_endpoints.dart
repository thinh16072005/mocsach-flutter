import 'package:flutter/foundation.dart';

class ApiEndpoints {
  // ========================================================
  // ⚙️ CẤU HÌNH MÔI TRƯỜNG - chỉ cần sửa ở đây
  // ========================================================
  // Để trống ('') = tự động chọn theo nền tảng
  // Điền IP máy tính (VD: '192.168.1.5') = dùng cho điện thoại thật qua WiFi
  static const String _hostIp = '';
  // ========================================================

  static String get baseUrl {
    if (_hostIp.isNotEmpty) {
      return 'http://$_hostIp:8080/api/v1';
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080/api/v1';
    }
    return 'http://localhost:8080/api/v1';
  }

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String activate = '/auth/activate';
  static const String forgotPassword = '/auth/forgot-password';
  static const String changePassword = '/auth/change-password';

  // Users
  static const String users = '/users';
  static String userById(int id) => '/users/$id';
  static String userProfile(int id) => '/users/$id/profile';
  static String userAvatar(int id) => '/users/$id/avatar';

  // Books
  static const String books = '/books';
  static const String bookBestsellers = '/books/bestsellers';
  static const String bookSearch = '/books/search';
  static String bookById(int id) => '/books/$id';
  static String bookStock(int id) => '/books/$id/stock';
  static const String genres = '/genres';
  static String genreById(int id) => '/genres/$id';

  // Reviews
  static const String reviews = '/reviews';
  static String reviewsByBook(int bookId) => '/reviews/book/$bookId';

  // Favorites
  static const String favorites = '/favorites';
  static String favoritesByUser(int userId) => '/favorites/user/$userId';
  static String removeFavorite(int bookId, int userId) => '/favorites/$bookId/user/$userId';

  // Cart
  static String cart(int userId) => '/cart/$userId';
  static const String cartItems = '/cart/items';
  static String cartItem(int id) => '/cart/items/$id';

  // Orders
  static const String orders = '/orders';
  static String orderById(int id) => '/orders/$id';
  static String ordersByUser(int userId) => '/orders/user/$userId';
  static String orderStatus(int id) => '/orders/$id/status';
  static String cancelOrder(int id) => '/orders/$id/cancel';

  // Deliveries (order-service)
  static const String deliveries = '/deliveries';

  // Payments
  static const String payments = '/payments';
  static const String createPayOSLink = '/payments/payos/create';
  static String verifyPayOS(int orderCode) => '/payments/payos/verify/$orderCode';

  // Coupons
  static const String coupons = '/coupons';
  static const String couponValidate = '/coupons/validate';
  static const String couponUse = '/coupons/use';
  static String couponById(int id) => '/coupons/$id';
  static String couponToggle(int id) => '/coupons/$id/activate';
  static const String couponBatch = '/coupons/batch';

  // Feedbacks
  static const String feedbacks = '/feedbacks';
  static const String feedbackUnreadCount = '/feedbacks/unread-count';
  static String feedbackById(int id) => '/feedbacks/$id';
  static String feedbackRead(int id) => '/feedbacks/$id/read';
}
