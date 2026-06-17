import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/widgets/custom_button.dart';

class ActiveAccountScreen extends StatefulWidget {
  const ActiveAccountScreen({super.key});

  @override
  State<ActiveAccountScreen> createState() => _ActiveAccountScreenState();
}

class _ActiveAccountScreenState extends State<ActiveAccountScreen> {
  final _dio = DioClient.instance;
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Đọc từ GetX arguments khi chuyển hướng từ màn hình đăng ký
    final args = Get.arguments;
    if (args is Map) {
      _emailCtrl.text = args['email'] ?? '';
      _codeCtrl.text = args['code'] ?? '';
    }
  }

  Future<void> _activate() async {
    if (_emailCtrl.text.trim().isEmpty || _codeCtrl.text.trim().isEmpty) {
      Get.snackbar('Lỗi', 'Vui lòng nhập email và mã kích hoạt');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final resp = await _dio.get(ApiEndpoints.activate, queryParameters: {
        'email': _emailCtrl.text.trim(),
        'code': _codeCtrl.text.trim(),
      });
      if (resp.data['success'] == true) {
        Get.snackbar('Thành công', 'Kích hoạt tài khoản thành công!');
        Get.offAllNamed('/login');
      } else {
        Get.snackbar('Lỗi', resp.data['message'] ?? 'Kích hoạt thất bại');
      }
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data?['message'] ?? 'Kích hoạt thất bại');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kích hoạt tài khoản')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Nhập mã OTP 6 chữ số được gửi đến email của bạn để kích hoạt tài khoản.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                  labelText: 'Email', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                  labelText: 'Mã OTP (6 chữ số)',
                  border: OutlineInputBorder(),
                  counterText: ""),
            ),
            const SizedBox(height: 24),
            CustomButton(text: 'Xác nhận kích hoạt', isLoading: _isLoading, onPressed: _activate),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }
}
