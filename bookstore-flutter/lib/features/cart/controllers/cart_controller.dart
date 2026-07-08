import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/models/cart_item_model.dart';
import '../../../core/models/book_model.dart';
import '../../../core/storage/token_storage.dart';

/// Một dòng giỏ hàng đã được "làm giàu" với thông tin sách (tên, giá, ảnh).
class CartLineView {
  final CartItemModel item;
  final BookModel? book;

  CartLineView({required this.item, this.book});

  double get lineTotal => (book?.sellPrice ?? 0) * item.quantity;
}

class CartController extends GetxController {
  final _dio = DioClient.instance;

  final cartItems = <CartItemModel>[].obs;
  // bookId -> BookModel, dùng để hiển thị tên/giá/ảnh và tính tổng.
  final _books = <int, BookModel>{}.obs;
  final isLoading = false.obs;
  
  // Track selected cart item IDs for bulk operations
  final selectedItemIds = <int>{}.obs;

  /// Các dòng giỏ hàng kèm thông tin sách (giữ thứ tự như cartItems).
  List<CartLineView> get lines => cartItems
      .map((item) => CartLineView(item: item, book: _books[item.bookId]))
      .toList();

  double get totalPrice =>
      lines.fold(0.0, (sum, line) => sum + line.lineTotal);

  /// Tổng số tiền của những dòng được chọn trong giỏ hàng
  double get selectedTotalPrice => lines
      .where((line) => selectedItemIds.contains(line.item.idCartItem))
      .fold(0.0, (sum, line) => sum + line.lineTotal);

  int get totalItemCount => cartItems.fold(0, (sum, item) => sum + item.quantity);

  BookModel? bookFor(int bookId) => _books[bookId];

  @override
  void onInit() {
    super.onInit();
    fetchCart();
  }

  Future<void> fetchCart() async {
    final userId = await TokenStorage.getUserId();
    if (userId == null) return;
    isLoading.value = true;
    try {
      final response = await _dio.get(ApiEndpoints.cart(userId));
      if (response.data['success'] == true) {
        final data = response.data['data'] as List;
        cartItems.assignAll(data.map((e) => CartItemModel.fromJson(e)).toList());
        
        // Clean up selections that are no longer in cartItems
        final validIds = cartItems.map((e) => e.idCartItem).toSet();
        selectedItemIds.retainAll(validIds);
        
        await _loadBooks();
      }
    } on DioException {
      Get.snackbar('Lỗi', 'Không thể tải giỏ hàng');
    } finally {
      isLoading.value = false;
    }
  }

  /// Lấy thông tin sách cho các bookId chưa có trong cache (song song, không N+1 tuần tự).
  Future<void> _loadBooks() async {
    final missing = cartItems
        .map((e) => e.bookId)
        .toSet()
        .where((id) => !_books.containsKey(id))
        .toList();
    if (missing.isEmpty) {
      _books.refresh();
      return;
    }
    final results = await Future.wait(missing.map(_fetchBook));
    for (final book in results) {
      if (book != null) _books[book.idBook] = book;
    }
    _books.refresh();
  }

  Future<BookModel?> _fetchBook(int id) async {
    try {
      final response = await _dio.get(ApiEndpoints.bookById(id));
      if (response.data['success'] == true) {
        return BookModel.fromJson(response.data['data']);
      }
    } on DioException {
      // Bỏ qua sách lỗi, dòng vẫn hiển thị tên mặc định.
    }
    return null;
  }

  Future<void> addItem(int bookId, {int quantity = 1}) async {
    final userId = await TokenStorage.getUserId();
    if (userId == null) {
      Get.toNamed('/login');
      Get.snackbar('Thông báo', 'Bạn cần phải đăng nhập để tiếp tục');
      return;
    }
    try {
      await _dio.post(ApiEndpoints.cartItems, data: {'bookId': bookId, 'quantity': quantity});
      Get.snackbar('Thành công', 'Đã thêm vào giỏ hàng!');
      fetchCart();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        Get.snackbar('Lỗi', 'Bạn cần phải đăng nhập để tiếp tục');
      } else {
        Get.snackbar('Lỗi', e.response?.data?['message'] ?? 'Không thể thêm vào giỏ hàng');
      }
    }
  }

  Future<void> updateQuantity(int cartItemId, int quantity) async {
    if (quantity < 1) return;
    // Giới hạn theo tồn kho nếu biết.
    final item = cartItems.firstWhereOrNull((e) => e.idCartItem == cartItemId);
    final stock = item != null ? _books[item.bookId]?.quantity : null;
    if (stock != null && quantity > stock) {
      Get.snackbar('Lỗi', 'Chỉ còn $stock sản phẩm trong kho');
      return;
    }
    try {
      await _dio.put(ApiEndpoints.cartItem(cartItemId), data: {'quantity': quantity});
      fetchCart();
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data?['message'] ?? 'Không thể cập nhật số lượng');
    }
  }

  Future<void> removeItem(int cartItemId) async {
    try {
      await _dio.delete(ApiEndpoints.cartItem(cartItemId));
      cartItems.removeWhere((item) => item.idCartItem == cartItemId);
      selectedItemIds.remove(cartItemId);
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data?['message'] ?? 'Không thể xóa sản phẩm');
    }
  }

  // ---- Bulk Operations ----
  bool isSelected(int id) => selectedItemIds.contains(id);

  void toggleSelection(int id) {
    if (selectedItemIds.contains(id)) {
      selectedItemIds.remove(id);
    } else {
      selectedItemIds.add(id);
    }
  }

  void toggleSelectAll(bool selectAll) {
    if (selectAll) {
      selectedItemIds.assignAll(cartItems.map((e) => e.idCartItem));
    } else {
      selectedItemIds.clear();
    }
  }

  bool get isAllSelected =>
      cartItems.isNotEmpty && selectedItemIds.length == cartItems.length;

  Future<void> removeItems(List<int> cartItemIds) async {
    if (cartItemIds.isEmpty) return;
    isLoading.value = true;
    try {
      await Future.wait(
        cartItemIds.map((id) => _dio.delete(ApiEndpoints.cartItem(id))),
      );
      cartItems.removeWhere((item) => cartItemIds.contains(item.idCartItem));
      selectedItemIds.removeAll(cartItemIds);
      Get.snackbar('Thành công', 'Đã xóa các sản phẩm được chọn');
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data?['message'] ?? 'Không thể xóa sản phẩm');
      fetchCart();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> clearCart() async {
    final ids = cartItems.map((e) => e.idCartItem).toList();
    await removeItems(ids);
  }
}
