import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/models/book_model.dart';

class BookController extends GetxController {
  final _dio = DioClient.instance;

  final books = <BookModel>[].obs;
  final bestsellers = <BookModel>[].obs;
  final genres = <dynamic>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final currentPage = 0.obs;
  final totalPages = 1.obs;
  final searchName = ''.obs;
  final selectedGenreId = RxnInt();
  final isGridView = true.obs;
  final selectedSort = RxnString();

  // Admin dùng list/paging riêng (size lớn hơn), không dùng chung customer search.
  final adminBooks = <BookModel>[].obs;
  /// Toàn bộ sách (dùng lọc tìm kiếm admin, giống BookStoreSBA allBooks).
  final adminAllBooks = <BookModel>[].obs;
  final adminPage = 0.obs;
  final adminTotalPages = 1.obs;
  final adminLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBooks();
    fetchGenres();
    fetchBestsellers();
  }

  Future<void> fetchBooks({bool reset = false}) async {
    if (reset) {
      currentPage.value = 0;
      books.clear();
    }
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await _dio.get(ApiEndpoints.bookSearch, queryParameters: {
        if (searchName.isNotEmpty) 'name': searchName.value,
        if (selectedGenreId.value != null) 'genreId': selectedGenreId.value,
        'page': currentPage.value,
        'size': 10,
        if (selectedSort.value != null) 'sort': selectedSort.value,
      });
      final body = response.data;
      if (body['success'] == true) {
        final pageData = body['data'];
        final content = pageData['content'] as List;
        var contentList = content.map((e) => BookModel.fromJson(e)).toList();
        
        // Client-side sorting fallback
        if (selectedSort.value != null) {
          final sortVal = selectedSort.value!;
          if (sortVal == 'sellPrice,asc') {
            contentList.sort((a, b) => a.sellPrice.compareTo(b.sellPrice));
          } else if (sortVal == 'nameBook,asc') {
            contentList.sort((a, b) => a.nameBook.compareTo(b.nameBook));
          } else if (sortVal == 'nameBook,desc') {
            contentList.sort((a, b) => b.nameBook.compareTo(a.nameBook));
          } else if (sortVal == 'avgRating,desc') {
            contentList.sort((a, b) => b.avgRating.compareTo(a.avgRating));
          }
        }
        
        books.assignAll(contentList);
        totalPages.value = pageData['totalPages'] ?? 1;
      }
    } on DioException catch (e) {
      errorMessage.value = e.response?.data?['message'] ?? 'Không thể tải sách';
    } finally {
      isLoading.value = false;
    }
  }

  /// Sách bán chạy: GET /books/bestsellers (soldQuantity ↓, giống BookStoreSBA).
  Future<void> fetchBestsellers({int size = 5}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.bookBestsellers,
        queryParameters: {'size': size},
      );
      final body = response.data;
      if (body['success'] == true && body['data'] is List) {
        final list = body['data'] as List;
        bestsellers.assignAll(list.map((e) => BookModel.fromJson(e)).toList());
      }
    } on DioException catch (e) {
      // Fallback: sort qua /books nếu service chưa rebuild.
      try {
        final fallback = await _dio.get(ApiEndpoints.books, queryParameters: {
          'page': 0,
          'size': size,
          'sort': 'soldQuantity,desc',
        });
        final fb = fallback.data;
        if (fb['success'] == true && fb['data']?['content'] is List) {
          final content = fb['data']['content'] as List;
          bestsellers.assignAll(content.map((e) => BookModel.fromJson(e)).toList());
        }
      } on DioException {
        debugPrint('fetchBestsellers failed: ${e.response?.data ?? e.message}');
      }
    }
  }

  Future<void> fetchGenres() async {
    try {
      final response = await _dio.get(ApiEndpoints.genres);
      if (response.data['success'] == true) {
        genres.assignAll(response.data['data'] as List);
      }
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data?['message'] ?? 'Không thể tải thể loại');
    }
  }

  Future<BookModel?> getBookById(int id) async {
    try {
      final response = await _dio.get(ApiEndpoints.bookById(id));
      if (response.data['success'] == true) {
        return BookModel.fromJson(response.data['data']);
      }
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data?['message'] ?? 'Không thể tải thông tin sách');
    }
    return null;
  }

  void search(String name, {int? genreId}) {
    searchName.value = name;
    selectedGenreId.value = genreId;
    fetchBooks(reset: true);
  }

  void changeSort(String? sort) {
    selectedSort.value = sort;
    fetchBooks(reset: true);
  }

  void nextPage() {
    if (currentPage.value < totalPages.value - 1) {
      currentPage.value++;
      fetchBooks();
    }
  }

  void prevPage() {
    if (currentPage.value > 0) {
      currentPage.value--;
      fetchBooks();
    }
  }

  // ---- Admin ----
  Future<void> fetchBooksForAdmin({bool reset = false, int size = 20}) async {
    if (reset) adminPage.value = 0;
    adminLoading.value = true;
    try {
      final response = await _dio.get(ApiEndpoints.books, queryParameters: {
        'page': adminPage.value,
        'size': size,
        'sort': 'idBook',
      });
      final body = response.data;
      if (body['success'] == true) {
        final pageData = body['data'];
        final content = pageData['content'] as List;
        adminBooks.assignAll(content.map((e) => BookModel.fromJson(e)).toList());
        adminTotalPages.value = pageData['totalPages'] ?? 1;
      }
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data?['message'] ?? 'Không thể tải sách');
    } finally {
      adminLoading.value = false;
    }
  }

  void adminNextPage() {
    if (adminPage.value < adminTotalPages.value - 1) {
      adminPage.value++;
      fetchBooksForAdmin();
    }
  }

  void adminPrevPage() {
    if (adminPage.value > 0) {
      adminPage.value--;
      fetchBooksForAdmin();
    }
  }

  /// Nạp nhiều sách một lần để tìm kiếm theo tên/tác giả trên client.
  Future<void> fetchAllBooksForAdminSearch() async {
    adminLoading.value = true;
    try {
      final response = await _dio.get(ApiEndpoints.books, queryParameters: {
        'page': 0,
        'size': 500,
        'sort': 'idBook',
      });
      final body = response.data;
      if (body['success'] == true) {
        final content = body['data']['content'] as List;
        adminAllBooks.assignAll(content.map((e) => BookModel.fromJson(e)).toList());
      }
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data?['message'] ?? 'Không thể tải sách');
    } finally {
      adminLoading.value = false;
    }
  }
}
