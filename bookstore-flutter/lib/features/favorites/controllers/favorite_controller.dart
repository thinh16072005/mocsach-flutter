import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/models/book_model.dart';
import '../../../core/storage/token_storage.dart';

class FavoriteController extends GetxController {
  final _dio = DioClient.instance;

  final favorites = <dynamic>[].obs; // danh sách FavoriteBook {idFavorite, userId, bookId}
  final _books = <int, BookModel>{}.obs; // bookId -> BookModel (tải sẵn, tránh N+1)
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchFavorites();
  }

  BookModel? bookFor(int bookId) => _books[bookId];

  Future<void> fetchFavorites() async {
    final userId = await TokenStorage.getUserId();
    if (userId == null) return;
    isLoading.value = true;
    try {
      final response = await _dio.get(ApiEndpoints.favoritesByUser(userId));
      if (response.data['success'] == true) {
        favorites.assignAll(response.data['data'] as List);
        await _loadBooks();
        final filteredFavs = favorites.where((fav) {
          final bookId = fav['bookId'] as int;
          final b = _books[bookId];
          return b == null || !b.isDeleted;
        }).toList();
        if (filteredFavs.length != favorites.length) {
          favorites.assignAll(filteredFavs);
        }
      }
    } on DioException {
      Get.snackbar('Lỗi', 'Không thể tải danh sách yêu thích');
    } finally {
      isLoading.value = false;
    }
  }

  /// Tải song song thông tin sách cho các bookId chưa có (1 lượt Future.wait).
  Future<void> _loadBooks() async {
    final missing = favorites
        .map((f) => f['bookId'] as int)
        .toSet()
        .where((id) => !_books.containsKey(id))
        .toList();
    if (missing.isEmpty) {
      _books.refresh();
      return;
    }
    final results = await Future.wait(missing.map((id) async {
      try {
        final resp = await _dio.get(ApiEndpoints.bookById(id));
        if (resp.data['success'] == true) return BookModel.fromJson(resp.data['data']);
      } on DioException {
        // Bỏ qua sách lỗi.
      }
      return null;
    }));
    for (final book in results) {
      if (book != null) _books[book.idBook] = book;
    }
    _books.refresh();
  }

  bool isFavorite(int bookId) {
    return favorites.any((f) => f['bookId'] == bookId);
  }

  Future<void> addFavorite(int bookId) async {
    try {
      await _dio.post(ApiEndpoints.favorites, data: {'bookId': bookId});
      Get.snackbar('Thành công', 'Đã thêm vào yêu thích!');
      fetchFavorites();
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data?['message'] ?? 'Không thể thêm');
    }
  }

  Future<void> removeFavorite(int bookId) async {
    final userId = await TokenStorage.getUserId();
    if (userId == null) return;
    try {
      await _dio.delete(ApiEndpoints.removeFavorite(bookId, userId));
      favorites.removeWhere((f) => f['bookId'] == bookId);
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data?['message'] ?? 'Không thể xóa khỏi yêu thích');
    }
  }

  Future<void> toggleFavorite(int bookId) async {
    if (isFavorite(bookId)) {
      await removeFavorite(bookId);
    } else {
      await addFavorite(bookId);
    }
  }
}
