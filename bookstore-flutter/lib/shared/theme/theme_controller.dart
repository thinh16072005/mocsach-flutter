import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Quản lý chế độ sáng/tối (chỉ thuộc tầng giao diện, không đụng nghiệp vụ).
/// Mặc định theo hệ thống; người dùng có thể chuyển tay và được ghi nhớ.
class ThemeController extends GetxController {
  static const _key = 'theme_mode';
  final _storage = const FlutterSecureStorage();

  final mode = ThemeMode.system.obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    try {
      final saved = await _storage.read(key: _key);
      if (saved == 'light') {
        mode.value = ThemeMode.light;
      } else if (saved == 'dark') {
        mode.value = ThemeMode.dark;
      }
      // Áp dụng theme đã lưu sau khi app dựng xong (tránh rebuild lúc đang khởi động).
      if (mode.value != ThemeMode.system) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.changeThemeMode(mode.value);
        });
      }
    } catch (_) {
      // Lỗi đọc storage → giữ mặc định system.
    }
  }

  bool get isDark {
    if (mode.value == ThemeMode.system) {
      return Get.isPlatformDarkMode;
    }
    return mode.value == ThemeMode.dark;
  }

  Future<void> toggle() async {
    final next = isDark ? ThemeMode.light : ThemeMode.dark;
    mode.value = next;
    Get.changeThemeMode(next);
    try {
      await _storage.write(key: _key, value: next == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {
      // Không ghi được vẫn áp dụng cho phiên hiện tại.
    }
  }
}
