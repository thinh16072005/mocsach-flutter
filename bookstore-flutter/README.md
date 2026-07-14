# bookstore_flutter

Ứng dụng Flutter cho hệ thống Bookstore Microservices (Spring + GetX + Dio).

## Cấu hình kết nối backend (`_hostIp`)

App gọi API qua gateway tại `:8080/api/v1`. Địa chỉ host được chọn trong
[`lib/core/network/api_endpoints.dart`](lib/core/network/api_endpoints.dart) ở hằng `_hostIp`:

- **Web / desktop:** để `_hostIp = ''` → dùng `http://localhost:8080/api/v1`.
- **Android emulator:** để `_hostIp = ''` → tự dùng `http://10.0.2.2:8080/api/v1`
  (emulator không truy cập được `localhost` của máy host).
- **Điện thoại thật (qua WiFi cùng mạng LAN):** đặt `_hostIp` = IP máy tính chạy backend,
  ví dụ `_hostIp = '192.168.1.5'` → `http://192.168.1.5:8080/api/v1`.
  Lấy IP bằng `ipconfig` (Windows) / `ifconfig` (macOS/Linux).

> Flutter web chạy ở **port 3000** để khớp cấu hình CORS của gateway:
> `flutter run -d chrome --web-port 3000`.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
