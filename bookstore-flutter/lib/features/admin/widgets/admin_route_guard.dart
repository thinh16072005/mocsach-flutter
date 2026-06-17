import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/storage/token_storage.dart';

/// Bọc mọi màn admin: kiểm tra role == ADMIN trước khi cho xem.
/// Khách (kể cả gõ URL/deep link) sẽ bị chặn và đưa về /home.
class AdminGuard extends StatefulWidget {
  final Widget child;
  const AdminGuard({super.key, required this.child});

  @override
  State<AdminGuard> createState() => _AdminGuardState();
}

class _AdminGuardState extends State<AdminGuard> {
  bool _allowed = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _ensureAdmin();
  }

  Future<void> _ensureAdmin() async {
    final role = await TokenStorage.getUserRole();
    if (!mounted) return;
    if (role != 'ADMIN') {
      Get.snackbar('Từ chối', 'Bạn không có quyền truy cập');
      Get.offAllNamed('/home');
      return;
    }
    setState(() {
      _allowed = true;
      _checked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked || !_allowed) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return widget.child;
  }
}
