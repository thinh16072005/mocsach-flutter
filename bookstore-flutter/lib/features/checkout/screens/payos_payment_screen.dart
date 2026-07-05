import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_endpoints.dart';

class PayOSPaymentScreen extends StatefulWidget {
  const PayOSPaymentScreen({super.key});

  @override
  State<PayOSPaymentScreen> createState() => _PayOSPaymentScreenState();
}

class _PayOSPaymentScreenState extends State<PayOSPaymentScreen>
    with WidgetsBindingObserver {
  final _dio = DioClient.instance;
  Timer? _pollTimer;
  bool _checking = false;
  bool _leaving = false;

  late final int _orderId;
  late final double _totalPrice;
  late final String _qrCode;
  late final String? _accountNumber;
  late final String? _accountName;
  late final int _amount;
  late final String? _couponCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final args = Get.arguments as Map;
    _orderId = args['orderId'] as int;
    _totalPrice = (args['totalPrice'] as num).toDouble();
    _qrCode = args['qrCode'] as String? ?? '';
    _accountNumber = args['accountNumber'] as String?;
    _accountName = args['accountName'] as String?;
    _amount = (args['amount'] as num?)?.toInt() ?? _totalPrice.round();
    _couponCode = args['couponCode'] as String?;

    _checkPayment();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkPayment());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPayment();
    }
  }

  Future<void> _checkPayment() async {
    if (_checking || _leaving) return;
    setState(() => _checking = true);
    try {
      final resp = await _dio.get(ApiEndpoints.verifyPayOS(_orderId));
      if (resp.data['success'] == true) {
        final status = resp.data['data']?.toString() ?? 'PENDING';
        if (status == 'PAID') {
          _pollTimer?.cancel();
          await _applyCouponIfAny();
          Get.offNamed('/payment-success', arguments: {
            'orderId': _orderId,
            'totalPrice': _totalPrice,
            'awaitingPayOS': false,
          });
        } else if (status == 'CANCELLED') {
          await _cancelOrderAndLeave(showMessage: false);
        }
      }
    } on DioException {
      // Thử lại ở lần poll sau.
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _applyCouponIfAny() async {
    final code = _couponCode?.trim();
    if (code == null || code.isEmpty) return;
    try {
      await _dio.put(ApiEndpoints.couponUse, queryParameters: {'code': code});
    } on DioException {
      // Đơn đã PAID; coupon lỗi không chặn luồng thành công.
    }
  }

  Future<void> _cancelOrderAndLeave({bool showMessage = true}) async {
    if (_leaving) return;
    _leaving = true;
    _pollTimer?.cancel();
    try {
      await _dio.put(ApiEndpoints.cancelOrder(_orderId));
    } on DioException {
      // Vẫn quay lại checkout để user thử lại.
    }
    if (!mounted) return;
    if (showMessage) {
      Get.snackbar('Đã hủy', 'Đơn hàng đã được hủy vì chưa thanh toán');
    }
    Get.offNamed('/checkout');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasQr = _qrCode.isNotEmpty;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancelOrderAndLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thanh toán PayOS'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _cancelOrderAndLeave,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Quét mã QR để thanh toán',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Đơn #$_orderId • ${_amount.toString()}đ',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              if (hasQr)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: _qrCode,
                    version: QrVersions.auto,
                    size: 260,
                    gapless: true,
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Không nhận được mã QR từ PayOS.'),
                ),
              if (_accountName != null && _accountName!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Chủ TK: $_accountName', textAlign: TextAlign.center),
              ],
              if (_accountNumber != null && _accountNumber!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('STK: $_accountNumber', textAlign: TextAlign.center),
              ],
              if (_checking) ...[
                const SizedBox(height: 24),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('Đang chờ xác nhận thanh toán…'),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              TextButton(
                onPressed: _cancelOrderAndLeave,
                child: const Text('Hủy và quay lại thanh toán'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
