# Backend EduPortal V6

- [Kiến trúc, phân quyền, luồng nghiệp vụ và cách chạy](../docs/BACKEND_V6_LUONG_NGHIEP_VU.md)
- [Danh sách API, định dạng và ví dụ request](../docs/API_BACKEND_V6.md)
- [Bảo mật và giới hạn](../SECURITY.md)
- [Cấu trúc biến môi trường và cách cấu hình](../docs/CAU_HINH_ENV.md)
- [Kết quả kiểm tra backend và giao diện ngày 12/11/2026](../docs/KIEM_TRA_2026_11_12.md)

Java 21, Spring Boot, Spring Security, JDBC/MySQL. Cấu hình cục bộ `.env.local` tự được đọc khi chạy từ thư mục backend. Không commit tệp này hoặc `.local/admin-credentials.txt`.

## Cấu trúc mã nguồn

```text
src/main/java/com/sms/backend/
├── BackendApplication.java
├── bootstrap/          # Tạo tài khoản BGH đầu tiên
├── config/             # Cấu hình Spring Security và SMTP
├── controller/         # Nhận request, trả response API
├── exception/          # Chuẩn hóa lỗi API
├── repository/         # Truy cập database bằng JDBC
├── security/           # Danh tính, JWT và kiểm tra phiên
└── service/
    ├── academic/       # Học phần, đăng ký, lịch và điểm
    ├── admission/      # Hồ sơ nhập học, tệp, định danh, học bạ
    ├── auth/           # Khôi phục mật khẩu
    ├── finance/        # Hóa đơn, thu, điều chỉnh, bàn giao, báo cáo
    ├── mail/           # Worker gửi email hàng đợi
    ├── resource/       # Metadata, danh sách và CRUD theo quyền
    └── student/        # Ảnh hồ sơ sinh viên
```

`src/main/resources/` chứa cấu hình ứng dụng; `src/test/java/` chứa kiểm thử; `src/test/resources/` chứa cấu hình và schema H2 riêng. Thư mục `target/` chỉ chứa kết quả build. Các lớp không còn dùng package `com.sms.backend.v6`; URL API và dữ liệu SQL được giữ nguyên.

```powershell
mvn.cmd "-Dmaven.repo.local=$env:USERPROFILE/.m2/repository" spring-boot:run
```

Kiểm thử dùng H2 và mail mock: `mvn.cmd test`. Gmail thật cần cấu hình qua `Configure-Gmail.ps1`; không nhập mật khẩu vào source hoặc chat.

## Định dạng code

Java dùng Google Java Format 1.24.0, kiểu AOSP: căn lề 4 dấu cách, tách câu lệnh và xuống dòng thống nhất. `.editorconfig` cung cấp quy tắc thụt lề cho trình soạn thảo. Từ thư mục gốc dự án:

```powershell
# Định dạng toàn bộ Java, gồm mã ứng dụng và test
powershell -ExecutionPolicy Bypass -File .\backend\scripts\Format-Java.ps1

# Chỉ kiểm tra định dạng, không sửa file
powershell -ExecutionPolicy Bypass -File .\backend\scripts\Format-Java.ps1 -Check
```

Script tải formatter phiên bản cố định vào `.local/tools` khi chưa có và kiểm tra SHA-256 trước khi chạy. Công cụ không được đưa vào Git hoặc dependency runtime của ứng dụng.

## Schema SQL hiện tại

Ứng dụng dùng schema V6 đã bổ sung migration 05–14 (56 bảng), gồm danh mục phòng và loại thi có liên kết ID. Xem [cài mới/nâng cấp SQL](../data/v6/README.md), [báo cáo nghiệm thu](../docs/CHUAN_HOA_SQL_2026_11_12.md) và [toàn bộ cột/khóa](../docs/SQL_DANH_MUC_CHUAN_HOA.md). Kiểm tra chỉ đọc: `python backend/scripts/Migrate-Database.py --check` từ thư mục gốc.


Luồng trình duyệt mới: [hướng dẫn xét duyệt và tài khoản](../docs/LUONG_XET_DUYET_VA_TAI_KHOAN.md).
