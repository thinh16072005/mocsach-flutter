import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/models/order_model.dart';
import '../../cart/controllers/cart_controller.dart';
import '../../orders/controllers/order_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../../shared/widgets/custom_button.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _dio = DioClient.instance;
  final _formKey = GlobalKey<FormState>();
  final _cartController = Get.find<CartController>();
  final _orderController = Get.put(OrderController());
  final _profileController = Get.put(ProfileController());

  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  List<dynamic> _paymentMethods = [];
  int? _selectedPaymentId;
  List<dynamic> _deliveryMethods = [];
  int? _selectedDeliveryId;
  final _couponCtrl = TextEditingController();
  int _discountPercent = 0;
  bool _loadingProfile = true;
  bool _loadingPayments = true;
  String? _paymentsError;
  bool _loadingDeliveries = true;
  String? _deliveriesError;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
    _loadDeliveryMethods();
    _initProfile();
  }

  Future<void> _loadDeliveryMethods() async {
    setState(() {
      _loadingDeliveries = true;
      _deliveriesError = null;
    });
    try {
      final resp = await _dio.get(ApiEndpoints.deliveries);
      if (resp.data['success'] == true) {
        final list = resp.data['data'] as List;
        setState(() {
          _deliveryMethods = list;
          _selectedDeliveryId =
              list.isNotEmpty ? list.first['idDelivery'] as int? : null;
        });
      } else {
        setState(() => _deliveriesError =
            resp.data['message'] ?? 'Không tải được hình thức giao hàng');
      }
    } on DioException catch (e) {
      setState(() => _deliveriesError =
          e.response?.data?['message'] ?? 'Không tải được hình thức giao hàng');
    } finally {
      if (mounted) setState(() => _loadingDeliveries = false);
    }
  }

  double get _selectedDeliveryFee {
    if (_selectedDeliveryId == null) return 0;
    for (final d in _deliveryMethods) {
      if (d['idDelivery'] == _selectedDeliveryId) {
        return (d['feeDelivery'] ?? 0).toDouble();
      }
    }
    return 0;
  }

  Future<void> _loadPaymentMethods() async {
    setState(() {
      _loadingPayments = true;
      _paymentsError = null;
    });
    try {
      final resp = await _dio.get(ApiEndpoints.payments);
      if (resp.data['success'] == true) {
        final list = resp.data['data'] as List;
        setState(() {
          _paymentMethods = list;
          _selectedPaymentId =
              list.isNotEmpty ? list.first['idPayment'] as int? : null;
        });
      } else {
        setState(() => _paymentsError = resp.data['message'] ?? 'Không tải được phương thức thanh toán');
      }
    } on DioException catch (e) {
      setState(() => _paymentsError =
          e.response?.data?['message'] ?? 'Không tải được phương thức thanh toán');
    } finally {
      if (mounted) setState(() => _loadingPayments = false);
    }
  }

  /// Tải profile (nếu chưa có) rồi điền sẵn thông tin giao hàng — tránh race khi user null.
  Future<void> _initProfile() async {
    if (_profileController.user.value == null) {
      await _profileController.fetchProfile();
    }
    if (!mounted) return;
    _prefillProfile();
    setState(() => _loadingProfile = false);
  }

  void _prefillProfile() {
    final user = _profileController.user.value;
    if (user != null) {
      _fullNameCtrl.text = user.fullName;
      _phoneCtrl.text = user.phoneNumber ?? '';
      _addressCtrl.text = user.deliveryAddress ?? '';
    }
  }

  Future<void> _applyCoupon() async {
    final code = _couponCtrl.text.trim();
    if (code.isEmpty) return;
    try {
      final resp = await _dio.get(ApiEndpoints.couponValidate,
          queryParameters: {'code': code});
      if (resp.data['success'] == true) {
        setState(() => _discountPercent = resp.data['data']['discountPercent']);
        Get.snackbar('Thành công', 'Áp dụng mã giảm ${_discountPercent}%!');
      } else {
        Get.snackbar('Lỗi', resp.data['message'] ?? 'Mã không hợp lệ');
      }
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data?['message'] ?? 'Mã không hợp lệ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Thông tin giao hàng',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              if (_loadingProfile)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('Đang tải thông tin giao hàng…'),
                    ],
                  ),
                ),
              _field(_fullNameCtrl, 'Họ và tên', Icons.person),
              const SizedBox(height: 12),
              _field(_phoneCtrl, 'Số điện thoại', Icons.phone,
                  keyboard: TextInputType.phone),
              const SizedBox(height: 12),
              _field(_addressCtrl, 'Địa chỉ giao hàng', Icons.location_on),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                    labelText: 'Ghi chú (tuỳ chọn)', border: OutlineInputBorder()),
              ),
              const Divider(height: 32),
              Obx(() => _buildProductList()),
              const Divider(height: 32),
              const Text('Hình thức giao hàng',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              if (_loadingDeliveries)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('Đang tải hình thức giao hàng…'),
                    ],
                  ),
                )
              else if (_deliveriesError != null)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: ListTile(
                    leading: const Icon(Icons.error_outline),
                    title: Text(_deliveriesError!),
                    trailing: TextButton(
                      onPressed: _loadDeliveryMethods,
                      child: const Text('Thử lại'),
                    ),
                  ),
                )
              else if (_deliveryMethods.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.local_shipping_outlined),
                    title: Text('Chưa có hình thức giao hàng'),
                    subtitle: Text(
                        'Thêm dữ liệu vào bảng delivery (database db_order).'),
                  ),
                )
              else
                ..._deliveryMethods.map((d) {
                  final id = d['idDelivery'] as int;
                  final fee = (d['feeDelivery'] ?? 0).toDouble();
                  final selected = _selectedDeliveryId == id;
                  return Card(
                    elevation: selected ? 2 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: RadioListTile<int>(
                      value: id,
                      groupValue: _selectedDeliveryId,
                      title: Text(
                        d['nameDelivery'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        fee > 0
                            ? 'Phí giao hàng: ${fee.toStringAsFixed(0)}đ'
                            : 'Miễn phí giao hàng',
                      ),
                      onChanged: (v) => setState(() => _selectedDeliveryId = v),
                    ),
                  );
                }),
              const Divider(height: 32),
              const Text('Mã giảm giá',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _couponCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Nhập mã', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: _applyCoupon, child: const Text('Áp dụng')),
                ],
              ),
              const Divider(height: 32),
              const Text('Phương thức thanh toán',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              if (_loadingPayments)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('Đang tải phương thức thanh toán…'),
                    ],
                  ),
                )
              else if (_paymentsError != null)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: ListTile(
                    leading: const Icon(Icons.error_outline),
                    title: Text(_paymentsError!),
                    trailing: TextButton(
                      onPressed: _loadPaymentMethods,
                      child: const Text('Thử lại'),
                    ),
                  ),
                )
              else if (_paymentMethods.isEmpty)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.payment_outlined),
                    title: const Text('Chưa có phương thức thanh toán'),
                    subtitle: const Text(
                        'Vui lòng thêm phương thức thanh toán trong database (bảng payment).'),
                  ),
                )
              else
                ..._paymentMethods.map((p) {
                  final id = p['idPayment'] as int;
                  final selected = _selectedPaymentId == id;
                  return Card(
                    elevation: selected ? 2 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: RadioListTile<int>(
                      value: id,
                      groupValue: _selectedPaymentId,
                      title: Text(
                        p['namePayment'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(p['description'] ?? ''),
                      onChanged: (v) => setState(() => _selectedPaymentId = v),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(() => _buildTotalSection()),
                const SizedBox(height: 12),
                Obx(() => CustomButton(
                      text: 'Đặt hàng',
                      isLoading: _orderController.isLoading.value,
                      onPressed: _onPlaceOrder,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalSection() {
    final subtotal = _calcSubtotal();
    final discount = subtotal * _discountPercent / 100;
    final shipFee = _selectedDeliveryFee;
    final total = subtotal - discount + shipFee;
    return Column(
      children: [
        _row('Tạm tính', '${subtotal.toStringAsFixed(0)}đ'),
        if (_discountPercent > 0)
          _row('Giảm giá ($_discountPercent%)', '-${discount.toStringAsFixed(0)}đ'),
        _row('Phí giao hàng', '${shipFee.toStringAsFixed(0)}đ'),
        const Divider(),
        _row('Tổng cộng', '${total.toStringAsFixed(0)}đ', bold: true),
      ],
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = TextStyle(
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        fontSize: bold ? 18 : 14,
        color: bold ? Colors.red : null);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }

  // Tạm tính lấy từ giỏ đã làm giàu (giá × SL). Server tính lại tổng cuối (R3).
  double _calcSubtotal() {
    if (_cartController.selectedItemIds.isNotEmpty) {
      return _cartController.selectedTotalPrice;
    }
    return _cartController.totalPrice;
  }

  bool _isPayOsSelected() {
    for (final p in _paymentMethods) {
      if (p['idPayment'] == _selectedPaymentId) {
        final name = (p['namePayment'] ?? '').toString().toLowerCase();
        return name.contains('payos');
      }
    }
    return false;
  }

  /// Tạo link PayOS + mã QR VietQR (orderCode = idOrder).
  Future<Map<String, dynamic>?> _createPayOSPayment(OrderModel order) async {
    final user = _profileController.user.value;
    try {
      final resp = await _dio.post(ApiEndpoints.createPayOSLink, data: {
        'orderCode': order.idOrder,
        'amount': order.totalPrice.round(),
        'description': 'Don hang #${order.idOrder}',
        'buyerName': _fullNameCtrl.text.trim(),
        'buyerPhone': _phoneCtrl.text.trim(),
        'buyerEmail': user?.email ?? '',
      });
      if (resp.data['success'] != true) {
        Get.snackbar('Lỗi', resp.data['message'] ?? 'Không tạo được link PayOS');
        return null;
      }
      final data = resp.data['data'];
      if (data is! Map) {
        Get.snackbar('Lỗi', 'Phản hồi PayOS không hợp lệ');
        return null;
      }
      return Map<String, dynamic>.from(data);
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data?['message'] ?? 'Tạo link PayOS thất bại');
      return null;
    }
  }

  Future<void> _onPlaceOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDeliveryId == null) {
      Get.snackbar('Lỗi', 'Vui lòng chọn hình thức giao hàng');
      return;
    }
    if (_selectedPaymentId == null) {
      Get.snackbar('Lỗi', 'Vui lòng chọn phương thức thanh toán');
      return;
    }

    final subtotal = _calcSubtotal();
    final total =
        subtotal - (subtotal * _discountPercent / 100) + _selectedDeliveryFee;

    final orderItems = _cartController.lines
        .where((line) => _cartController.selectedItemIds.isEmpty || _cartController.selectedItemIds.contains(line.item.idCartItem))
        .map((line) => {'bookId': line.item.bookId, 'quantity': line.item.quantity})
        .toList();

    final order = await _orderController.createOrder(
      deliveryAddress: _addressCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim(),
      fullName: _fullNameCtrl.text.trim(),
      totalPriceProduct: subtotal,
      totalPrice: total,
      paymentId: _selectedPaymentId!,
      paymentStatus: 'PENDING',
      deliveryId: _selectedDeliveryId!,
      note: _noteCtrl.text.trim(),
      orderItems: orderItems,
    );

    if (order != null) {
      _cartController.fetchCart();

      final awaitingPayOS = _isPayOsSelected();
      if (awaitingPayOS) {
        final payos = await _createPayOSPayment(order);
        if (payos == null) {
          await _orderController.cancelOrder(order.idOrder);
          return;
        }
        final qr = payos['qrCode'] as String? ?? '';
        if (qr.isEmpty && (payos['checkoutUrl'] as String? ?? '').isEmpty) {
          Get.snackbar('Lỗi', 'PayOS không trả mã QR');
          await _orderController.cancelOrder(order.idOrder);
          return;
        }
        final couponCode =
            _couponCtrl.text.trim().isNotEmpty && _discountPercent > 0
                ? _couponCtrl.text.trim()
                : null;
        Get.offNamed('/payos-payment', arguments: {
          'orderId': order.idOrder,
          'totalPrice': order.totalPrice,
          'qrCode': qr,
          'checkoutUrl': payos['checkoutUrl'],
          'accountNumber': payos['accountNumber'],
          'accountName': payos['accountName'],
          'amount': payos['amount'] ?? order.totalPrice.round(),
          'couponCode': couponCode,
        });
        return;
      }

      if (_couponCtrl.text.trim().isNotEmpty && _discountPercent > 0) {
        try {
          await _dio.put(ApiEndpoints.couponUse,
              queryParameters: {'code': _couponCtrl.text.trim()});
        } on DioException catch (e) {
          Get.snackbar('Lưu ý', e.response?.data?['message'] ?? 'Không thể ghi nhận mã giảm giá');
        }
      }

      Get.offNamed('/payment-success', arguments: {
        'orderId': order.idOrder,
        'totalPrice': order.totalPrice,
        'awaitingPayOS': false,
      });
    } else {
      Get.snackbar('Lỗi', _orderController.errorMessage.value);
    }
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboard}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(
          labelText: label, border: const OutlineInputBorder(), prefixIcon: Icon(icon)),
      validator: (v) => v!.trim().isEmpty ? 'Không được để trống' : null,
    );
  }

  Widget _buildProductList() {
    final items = _cartController.lines
        .where((line) =>
            _cartController.selectedItemIds.isEmpty ||
            _cartController.selectedItemIds.contains(line.item.idCartItem))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Danh sách sản phẩm',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        ...items.map((line) {
          final book = line.book;
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    height: 72,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: book?.thumbnailUrl != null
                          ? CachedNetworkImage(
                              imageUrl: book!.thumbnailUrl!,
                              fit: BoxFit.cover,
                              placeholder: (c, u) => const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              errorWidget: (c, u, e) =>
                                  const Icon(Icons.book, size: 40),
                            )
                          : const Icon(Icons.book, size: 40, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book?.nameBook ?? 'Sách #${line.item.bookId}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        if (book?.author != null && book!.author.isNotEmpty) ...[
                          Text(
                            'Tác giả: ${book!.author}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Số lượng: ${line.item.quantity}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            Text(
                              '${line.lineTotal.toStringAsFixed(0)}đ',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _noteCtrl.dispose();
    _couponCtrl.dispose();
    super.dispose();
  }
}
