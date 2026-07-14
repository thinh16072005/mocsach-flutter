# Bookstore Microservices Project

Dự án bán sách được thiết kế theo kiến trúc Microservices (Backend Java Spring Boot) kết hợp với ứng dụng người dùng viết bằng Flutter.

## Yêu cầu hệ thống (Prerequisites)
- **Java 21** & **Maven** (để build các microservices)
- **Docker** & **Docker Compose** (để khởi chạy hệ thống backend và database)
- **Flutter SDK** (để chạy ứng dụng client)
- **SQL Server Management Studio (SSMS)** hoặc DBeaver (để quản trị CSDL)

---

## Phần 1: Hướng dẫn cài đặt và khởi chạy Backend

### Bước 1: Cấu hình file môi trường (`.env`)
Đảm bảo bạn đã có file `.env` tại thư mục gốc của dự án. 
**Lưu ý cực kỳ quan trọng:** Mật khẩu database (`DB_PASSWORD`) phải đủ mạnh (VD: `StrongPassword123!`) theo chuẩn của SQL Server (Ít nhất 8 ký tự, có chữ hoa, chữ thường, số và ký tự đặc biệt). Nếu mật khẩu yếu, database sẽ bị lỗi và Docker sẽ tự động tắt container này.

### Bước 2: Build các Microservices
Vì dự án không sử dụng Multi-stage build trong Docker, bạn cần phải tự build các file `.jar` bằng Maven trước.
Mở **PowerShell** tại thư mục gốc dự án (`d:\bookstore-microservices`) và chạy đoạn script sau để build tự động:

```powershell
$services = @("api-gateway", "auth-service", "user-service", "book-service", "order-service", "payment-service", "coupon-feedback-service")
foreach ($service in $services) {
    Write-Host "Đang build $service..." -ForegroundColor Green
    cd $service
    mvn clean package -DskipTests
    cd ..
}
```

### Bước 3: Khởi chạy Docker
Sau khi quá trình build thành công, khởi chạy toàn bộ hệ thống bằng lệnh:
```bash
docker-compose up --build -d
```

### Bước 4: Khởi tạo Database (Bắt buộc cho lần chạy đầu tiên)
Mặc định container SQL Server sẽ không có sẵn các database cho từng microservice. Bạn cần tự tạo chúng, nếu không các service sẽ báo lỗi *"Cannot open database..."* và tắt đi.
Chạy lệnh sau trên Terminal để tự động tạo toàn bộ database cần thiết:
```bash
docker exec bookstore-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P StrongPassword123! -C -Q "CREATE DATABASE db_auth; CREATE DATABASE db_user; CREATE DATABASE db_book; CREATE DATABASE db_order; CREATE DATABASE db_payment; CREATE DATABASE db_other;"
```
*(Nếu bạn dùng mật khẩu khác, hãy thay `StrongPassword123!` bằng mật khẩu thật của bạn).*

Sau khi tạo xong, hãy khởi động lại các container để chúng kết nối thành công:
```bash
docker-compose restart
```

### Bước 5: Kết nối Database bằng SSMS để quản lý
Để quan sát dữ liệu bằng SSMS mà không bị xung đột với SQL Express cài sẵn trên máy:
- **Server name:** `127.0.0.1,14333` *(Lưu ý cổng 14333)*
- **Authentication:** `SQL Server Authentication`
- **Login:** `sa`
- **Password:** `<Mật khẩu trong file .env>`
- ⚠️ **Đặc biệt (với bản SSMS mới):** Bấm vào nút `Options >>`, sang tab `Connection Properties` và **tích chọn `Trust server certificate`** (Tin cậy chứng chỉ máy chủ).
- Bấm **Connect**.

---

## Phần 2: Hướng dẫn chạy Ứng dụng Client (Frontend Flutter)

Sau khi hệ thống Backend đã chạy xanh mượt trên Docker, bạn mở một Terminal mới và thực hiện:

1. Di chuyển vào thư mục dự án Flutter:
   ```bash
   cd bookstore-flutter
   ```
2. Cài đặt các thư viện phụ thuộc (chỉ cần làm 1 lần):
   ```bash
   flutter pub get
   ```
3. Khởi chạy ứng dụng trên Chrome **đúng cổng 3000** (bắt buộc để tránh lỗi CORS):
   ```bash
   & "C:\Users\Minh\AppData\Local\Android\Sdk\emulator\emulator.exe" -avd Pixel_6a
   & "C:\Users\ASUS\AppData\Local\Android\Sdk\emulator\emulator.exe" -avd Pixel_4
   flutter run -d emulator-5554
   ```

> ⚠️ **Quan trọng:** Bắt buộc phải chạy đúng cổng `3000` vì Backend (API Gateway) chỉ cho phép các request từ `localhost:3000`. Nếu dùng cổng khác sẽ bị lỗi CORS và không thể đăng nhập/đăng ký.


