import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/order_controller.dart';
import '../../../core/models/order_model.dart';
import '../../../core/models/book_model.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_endpoints.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _orderController = Get.put(OrderController());
  OrderModel? _order;
  bool _isLoading = true;
  final Map<int, BookModel> _books = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final orderId = Get.arguments as int;
    final order = await _orderController.getOrderById(orderId);
    if (order != null) {
      await _loadBooks(order);
    }
    if (mounted) {
      setState(() {
        _order = order;
        _isLoading = false;
      });
    }
  }

  /// Tải tên + ảnh cho từng dòng sách (song song) để hiển thị thay cho "Sách ID".
  Future<void> _loadBooks(OrderModel order) async {
    final details = order.listOrderDetails ?? [];
    final ids = details.map((d) => d['bookId'] as int).toSet().toList();
    final results = await Future.wait(ids.map((id) async {
      try {
        final resp = await DioClient.instance.get(ApiEndpoints.bookById(id));
        if (resp.data['success'] == true) return BookModel.fromJson(resp.data['data']);
      } on DioException {
        // Bỏ qua, dòng vẫn hiển thị mã sách.
      }
      return null;
    }));
    for (final book in results) {
      if (book != null) _books[book.idBook] = book;
    }
  }

  Future<void> _cancelOrder() async {
    final confirmed = await Get.dialog<bool>(AlertDialog(
      title: const Text('Xác nhận'),
      content: const Text('Bạn có chắc muốn hủy đơn hàng này?'),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text('Không')),
        ElevatedButton(onPressed: () => Get.back(result: true), child: const Text('Hủy đơn')),
      ],
    ));
    if (confirmed == true && _order != null) {
      final success = await _orderController.cancelOrder(_order!.idOrder);
      if (success) {
        Get.snackbar('Thành công', 'Đã hủy đơn hàng');
        _load();
      } else {
        Get.snackbar('Lỗi', 'Không thể hủy đơn hàng');
      }
    }
  }

  Future<void> _writeReview(int bookId, int orderDetailId) async {
    final contentCtrl = TextEditingController();
    double rating = 5;
    await Get.dialog(AlertDialog(
      title: const Text('Viết đánh giá'),
      content: StatefulBuilder(
        builder: (ctx, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return IconButton(
                  icon: Icon(i < rating ? Icons.star : Icons.star_border, color: Colors.amber),
                  onPressed: () => setState(() => rating = i + 1.0),
                );
              }),
            ),
            TextField(
              controller: contentCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Nội dung', border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Huỷ')),
        ElevatedButton(
          onPressed: () async {
            try {
              await DioClient.instance.post(ApiEndpoints.reviews, data: {
                'bookId': bookId,
                'ratingPoint': rating,
                'content': contentCtrl.text.trim(),
                'orderDetailId': orderDetailId,
              });
              Get.back();
              Get.snackbar('Thành công', 'Đã gửi đánh giá!');
              _load(); // refresh để ẩn nút đánh giá đã gửi
            } on DioException catch (e) {
              Get.snackbar('Lỗi', e.response?.data?['message'] ?? 'Gửi đánh giá thất bại');
            }
          },
          child: const Text('Gửi'),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_order == null) {
      return const Scaffold(body: Center(child: Text('Không tìm thấy đơn hàng')));
    }
    final order = _order!;
    final details = order.listOrderDetails ?? [];

    return Scaffold(
      appBar: AppBar(title: Text('Đơn hàng #${order.idOrder}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Thông tin giao hàng', [
            _row('Người nhận', order.fullName),
            _row('SĐT', order.phoneNumber),
            _row('Địa chỉ', order.deliveryAddress),
            if (order.note != null && order.note!.isNotEmpty) _row('Ghi chú', order.note!),
          ]),
          const SizedBox(height: 16),
          _section('Trạng thái', [
            _row('Đơn hàng', order.status),
            _row('Thanh toán', order.paymentStatus == 'PAID' ? 'Đã thanh toán' : 'Chưa thanh toán'),
          ]),
          const SizedBox(height: 16),
          const Text('Sản phẩm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ...details.map((d) {
            final book = _books[d['bookId']];
            return Card(
              child: ListTile(
                leading: SizedBox(
                  width: 44,
                  height: 60,
                  child: book?.thumbnailUrl != null
                      ? CachedNetworkImage(
                          imageUrl: book!.thumbnailUrl!,
                          fit: BoxFit.cover,
                          placeholder: (c, u) =>
                              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          errorWidget: (c, u, e) => const Icon(Icons.book),
                        )
                      : const Icon(Icons.book),
                ),
                title: Text(book?.nameBook ?? 'Sách #${d['bookId']}'),
                subtitle: Text('SL: ${d['quantity']} × ${(d['price'] ?? 0).toStringAsFixed(0)}đ'),
                trailing: (order.status == 'Hoàn thành' && d['reviewed'] != true)
                    ? TextButton(
                        onPressed: () => _writeReview(d['bookId'], d['idOrderDetail']),
                        child: const Text('Đánh giá'),
                      )
                    : null,
              ),
            );
          }),
          const Divider(height: 32),
          _row('Tạm tính', '${order.totalPriceProduct.toStringAsFixed(0)}đ'),
          _row('Phí giao hàng', '${order.feeDelivery.toStringAsFixed(0)}đ'),
          _row('Tổng cộng', '${order.totalPrice.toStringAsFixed(0)}đ', bold: true),
          const SizedBox(height: 24),
          if (order.status != 'Bị huỷ' && order.status != 'Hoàn thành')
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: _cancelOrder,
              icon: const Icon(Icons.cancel),
              label: const Text('Hủy đơn hàng'),
            ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                    color: bold ? Colors.red : null,
                    fontSize: bold ? 16 : 14)),
          ),
        ],
      ),
    );
  }
}
