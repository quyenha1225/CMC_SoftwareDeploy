# EduPortal — Quản lý sinh viên

Tài liệu chi tiết: [Backend và luồng nghiệp vụ](docs/BACKEND_V6_LUONG_NGHIEP_VU.md) · [Danh sách API và ví dụ body](docs/API_BACKEND_V6.md).

Máy hiện tại: database `sms_v6_original`, backend `8081`, FE `5173`. Tài khoản BGH mới: xem tệp cục bộ `backend/.local/admin-credentials.txt`. Khóa ký JWT/định danh và cấu hình DB nằm trong `backend/.env.local`, không commit. Schema 01 và truy vấn 03 giữ từ bản V6; seed 02 đã được cập nhật tên/mã thực hành theo yêu cầu mới. Sáu bản ghi sinh viên giữ nguyên ID, hồ sơ được cập nhật qua migration 12. Schema ứng dụng hiện có 53 bảng sau migration 05–12, gồm bảo mật/ảnh, lịch thi, danh mục phòng/loại thi và sổ phiên bản. Xem [chuẩn hóa SQL và nghiệm thu](docs/CHUAN_HOA_SQL_2026_11_12.md).

React/Vite · Spring Boot/JDK 21 · MySQL V6.

## 1. Database và backend

Nhập SQL vào **database V6 mới** theo [hướng dẫn database](data/v6/README.md). Không chạy chồng lên v2.

```powershell
cd backend
$env:DB_URL = "jdbc:mysql://127.0.0.1:3306/sms_v6"
$env:DB_USERNAME = "root"
$dbCredential = Get-Credential -UserName $env:DB_USERNAME
$env:DB_PASSWORD = $dbCredential.GetNetworkCredential().Password
mvn.cmd spring-boot:run
```

Cần Maven 3.9+; có thể dùng `.\mvnw.cmd` nếu wrapper trên máy hoạt động. API tại `http://127.0.0.1:8081/api`.

Lần đầu, trước khi chạy backend, cấu hình tài khoản BGH mới:

```powershell
$env:SMS_BOOTSTRAP_ENABLED = "true"
$env:SMS_BOOTSTRAP_USERNAME = "principal"
$env:SMS_BOOTSTRAP_EMAIL = "principal@ten-truong.edu.vn"
$principalCredential = Get-Credential -UserName $env:SMS_BOOTSTRAP_USERNAME
$env:SMS_BOOTSTRAP_PASSWORD = $principalCredential.GetNetworkCredential().Password
```

Mật khẩu từ 12 ký tự. Bootstrap chỉ tạo khi chưa có BGH hoạt động; không sửa tài khoản seed. Sau lần đầu, tắt `SMS_BOOTSTRAP_ENABLED` và xóa biến mật khẩu bootstrap. BGH tạo tài khoản nhân sự; người mới chỉ mở thông tin truy cập khi bắt đầu nộp hồ sơ. Cấp vai trò giảng viên xong, PĐT tạo bản ghi giảng viên liên kết đúng tài khoản.

Để lưu CCCD/hộ chiếu, đặt `SMS_IDENTITY_KEY` là khóa ngẫu nhiên 32 byte dạng Base64 và giữ ổn định trong kho bí mật. Mất khóa sẽ mất khả năng giải mã; không đưa khóa vào Git. Tệp hồ sơ lưu ở `backend/private-files` hoặc đường dẫn `SMS_FILES_DIR`.

## 2. Frontend

Node.js 22.12+ hoặc 24; mở terminal thứ hai:

```powershell
cd frontend
npm.cmd ci
npm.cmd run dev -- --host 127.0.0.1
```

Mở URL Vite in ra, thường `http://127.0.0.1:5173`. FE gọi backend qua proxy `/api`; cần backend và V6 sẵn sàng. Đăng nhập bằng tài khoản thật; không chọn tùy ý vai trò.

## 3. Kiểm tra

```powershell
# Tại backend
mvn.cmd test
# Tại frontend
npm.cmd run build
```

Test BE dùng H2 riêng, không thay MySQL. Các test nghiệp vụ FE cũ nằm trong `frontend/tests`, không chứng minh tích hợp V6.

Luồng chính: ứng viên nộp → CTSV kiểm tra → BGH duyệt → PĐT xác minh/cấp MSSV/phân lớp. CTSV thu/quỹ; BGH duyệt điều chỉnh, bàn giao và báo cáo. Điểm qua GV → PĐT → BGH → PĐT công bố.

Đã có Gmail SMTP, worker outbox và khôi phục mật khẩu bằng email trường. Cần chạy `backend/Configure-Gmail.ps1`, cấu hình tài khoản gửi thật và xác nhận hộp thư trường ACTIVE; chưa kiểm chứng gửi thư thật. Worker outbox mặc định tắt để tránh gửi vào địa chỉ demo. Chưa tích hợp tự cấp hộp thư Google hoặc thanh toán trực tuyến. Thu tiền là ghi nhận chứng từ của CTSV. Xem [tình trạng V6](docs/TRIEN_KHAI_V6.md) và [bảo mật](SECURITY.md).

Bộ dữ liệu thực hành đã được đặt tên cụ thể và cập nhật vào seed/database theo yêu cầu mới. Xem [bảng tên và kiểm tra liên kết/học phí](docs/BO_DU_LIEU_THUC_HANH.md).


## Docker và Jenkins CI/CD

Đóng gói local cổng 8088, Flyway, Jenkinsfile, monitoring và runbook: [hướng dẫn vận hành](docs/operations/README.md). Database host và frontend :5173 vẫn độc lập. Xem [trạng thái nghiệm thu theo đặc tả](docs/operations/ACCEPTANCE.md) trước khi coi các bước Registry/VPS/Webhook là đã chạy thật.
