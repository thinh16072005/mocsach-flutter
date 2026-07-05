import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/widgets/custom_button.dart';

class PaymentSuccessScreen extends StatefulWidget {
  const PaymentSuccessScreen({super.key});

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with WidgetsBindingObserver {
  final _dio = DioClient.instance;
  Timer? _pollTimer;
  Timer? _homeTimer;
  bool _checking = false;
  bool _paid = false;
  bool _cancelled = false;
  String _payStatus = 'PENDING';
  int _countdown = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final args = Get.arguments;
    final awaitingPayOS = args is Map && args['awaitingPayOS'] == true;
    final orderId = args is Map ? args['orderId'] as int? : null;
    if (awaitingPayOS && orderId != null) {
      _checkPayOS(orderId);
      _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!_paid && !_cancelled && mounted) _checkPayOS(orderId);
      });
    } else {
      _startHomeCountdown();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final args = Get.arguments;
      final awaitingPayOS = args is Map && args['awaitingPayOS'] == true;
      final orderId = args is Map ? args['orderId'] as int? : null;
      if (awaitingPayOS && orderId != null && !_paid && !_cancelled) {
        _checkPayOS(orderId);
      }
    }
  }

  void _startHomeCountdown() {
    _homeTimer?.cancel();
    setState(() => _countdown = 5);
    _homeTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_countdown <= 1) {
        t.cancel();
        Get.offAllNamed('/home');
      } else {
        setState(() => _countdown--);
      }
    });
  }

  Future<void> _checkPayOS(int orderId) async {
    if (_checking || _paid || _cancelled) return;
    setState(() => _checking = true);
    try {
      final resp = await _dio.get(ApiEndpoints.verifyPayOS(orderId));
      if (resp.data['success'] == true) {
        final status = resp.data['data']?.toString() ?? 'PENDING';
        if (status == 'PAID') {
          setState(() {
            _paid = true;
            _payStatus = 'PAID';
          });
          _pollTimer?.cancel();
          _startHomeCountdown();
        } else if (status == 'CANCELLED') {
          setState(() => _cancelled = true);
          _pollTimer?.cancel();
          try {
            await _dio.put(ApiEndpoints.cancelOrder(orderId));
          } on DioException {
            // ignore
          }
          Get.offNamed('/checkout');
        } else {
          setState(() => _payStatus = status);
        }
      }
    } on DioException {
      // Thử lại ở lần poll sau.
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _homeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final int? orderId = args is Map ? args['orderId'] as int? : null;
    final double? totalPrice =
        args is Map && args['totalPrice'] != null ? (args['totalPrice'] as num).toDouble() : null;
    final awaitingPayOS = args is Map && args['awaitingPayOS'] == true;
    final showSuccess = !awaitingPayOS || _paid;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                showSuccess ? Icons.check_circle : Icons.payment,
                color: showSuccess ? Colors.green : Colors.orange,
                size: 100,
              ),
              const SizedBox(height: 16),
              Text(
                showSuccess ? 'Thanh toán thành công!' : 'Hoàn tất thanh toán PayOS',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                showSuccess
                    ? 'Cảm ơn bạn đã mua hàng. Về trang chủ sau $_countdown giây…'
                    : 'Thanh toán trên cổng PayOS (tab trình duyệt). App tự kiểm tra trạng thái.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              if (showSuccess) ...[
                const SizedBox(height: 16),
                Text(
                  '$_countdown',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
              if (awaitingPayOS && !_paid) ...[
                const SizedBox(height: 12),
                if (_checking)
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('Đang kiểm tra thanh toán…'),
                    ],
                  )
                else
                  Text('Trạng thái PayOS: $_payStatus',
                      style: Theme.of(context).textTheme.bodySmall),
              ],
              if (orderId != null) ...[
                const SizedBox(height: 16),
                Text('Mã đơn hàng: #$orderId',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
              if (totalPrice != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Tổng tiền: ${totalPrice.toStringAsFixed(0)}đ',
                      style: const TextStyle(
                          fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              const SizedBox(height: 32),
              if (awaitingPayOS && orderId != null && !_paid)
                CustomButton(
                  text: 'Kiểm tra lại thanh toán',
                  icon: Icons.refresh,
                  onPressed: _checking ? null : () => _checkPayOS(orderId),
                ),
              if (showSuccess) ...[
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Về trang chủ ngay',
                  icon: Icons.home,
                  onPressed: () {
                    _homeTimer?.cancel();
                    Get.offAllNamed('/home');
                  },
                ),
              ],
              if (awaitingPayOS && !_paid) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Get.offNamed('/checkout'),
                  child: const Text('Quay lại thanh toán'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
