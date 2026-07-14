import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../shared/widgets/custom_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _authController = Get.find<AuthController>();
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Tạo tài khoản mới', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text('Tham gia cộng đồng yêu sách',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _buildField(_firstNameCtrl, 'Họ đệm', Icons.badge_outlined)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildField(_lastNameCtrl, 'Tên', Icons.person_outline)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildField(_emailCtrl, 'Email', Icons.email_outlined,
                        keyboard: TextInputType.emailAddress,
                        validator: (v) {
                      final value = v?.trim() ?? '';
                      final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
                      return emailRegex.hasMatch(value) ? null : 'Email không hợp lệ';
                    }),
                    const SizedBox(height: 16),
                    _buildField(_usernameCtrl, 'Tên đăng nhập', Icons.account_circle_outlined),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Mật khẩu tối thiểu 6 ký tự'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    Obx(() => _authController.errorMessage.isNotEmpty
                        ? Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: scheme.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(_authController.errorMessage.value,
                                style: TextStyle(color: scheme.error)),
                          )
                        : const SizedBox.shrink()),
                    Obx(() => CustomButton(
                          text: 'Đăng ký',
                          isLoading: _authController.isLoading.value,
                          onPressed: _onRegister,
                        )),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboard, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: validator ?? (v) => (v == null || v.isEmpty) ? 'Không được để trống' : null,
    );
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await _authController.register(
      _usernameCtrl.text.trim(),
      _passwordCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _firstNameCtrl.text.trim(),
      _lastNameCtrl.text.trim(),
    );
    if (success) {
      Get.snackbar('Thành công',
          'Đăng ký thành công! Vui lòng nhập mã OTP đã được gửi đến email của bạn.');
      Get.toNamed('/active-account', arguments: {'email': _emailCtrl.text.trim()});
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _emailCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }
}
