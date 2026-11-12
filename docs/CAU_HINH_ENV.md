# Cấu hình môi trường

## Vị trí

```text
backend/
  .env.local       # Kết nối và bí mật cục bộ, Git bỏ qua
  src/main/resources/application.properties  # Ánh xạ env → thuộc tính Spring
frontend/
  .env.example     # Mẫu host/port/proxy Vite
  .env.local       # Cấu hình máy hiện tại, Git bỏ qua
```

Backend chỉ dùng `backend/.env.local`; không giữ thêm file mẫu. Frontend có cấu hình riêng trong `frontend/.env.local`. Khi chuyển máy, tạo cấu hình riêng theo danh sách biến bên dưới; không đưa file chứa bí mật lên Git.

## Backend

| Nhóm | Biến |
|---|---|
| HTTP server | `SERVER_ADDRESS`, `SERVER_PORT`, `SMS_PUBLIC_URL` |
| MySQL | `DB_URL`, `DB_USERNAME`, `DB_PASSWORD` |
| JWT/phiên | `SMS_JWT_SECRET`, `SMS_JWT_TTL_SECONDS`, `SESSION_TIMEOUT`, `SESSION_SECURE` |
| Mã hóa định danh | `SMS_IDENTITY_KEY` |
| Kho tệp | `SMS_FILES_DIR`, `SMS_MAX_FILE_SIZE`, `SMS_MAX_REQUEST_SIZE` |
| Địa chỉ trường dự kiến | `SMS_SCHOOL_EMAIL_DOMAIN` |
| Gmail SMTP | `SMS_MAIL_ENABLED`, `SMS_SMTP_HOST`, `SMS_SMTP_PORT`, `SMS_SMTP_USERNAME`, `SMS_SMTP_PASSWORD`, `SMS_SMTP_TIMEOUT_MS` |
| Worker email | `SMS_OUTBOX_ENABLED`, `SMS_OUTBOX_DELAY_MS` |
| Tạo BGH lần đầu | `SMS_BOOTSTRAP_ENABLED`, `SMS_BOOTSTRAP_USERNAME`, `SMS_BOOTSTRAP_EMAIL`, `SMS_BOOTSTRAP_PASSWORD` |

`application.properties` giữ cấu hình framework và ánh xạ tên biến sang `sms.*`/`spring.*`; Java đọc thuộc tính Spring, không nhúng địa chỉ máy hoặc tài khoản kết nối. Một số giá trị mặc định dùng cho local và kiểm thử được tập trung trong `application.properties`.

Spring đọc `.env.local` bằng bộ đọc **Java properties**, không phải shell: viết `KEY=value`, không dùng `export` và không bọc giá trị trong dấu nháy. Ví dụ đường dẫn Windows dùng `D:/private-files` hoặc escape dấu `\` thành `\\`. Những giá trị hiện có đã đúng định dạng; không đưa chúng vào báo cáo/log.

Hỗ trợ chạy ở thư mục backend hoặc gốc repository. Biến môi trường của tiến trình có ưu tiên cao hơn cấu hình file. Không đặt cùng một biến bí mật ở cả `.env.local` thư mục gốc và backend để tránh nhầm giá trị ưu tiên. Test dùng `application-test.properties`, tắt import file cục bộ và dùng H2/khóa test riêng.

JWT cần ít nhất 64 byte ngẫu nhiên dạng Base64, khóa định danh đúng 32 byte dạng Base64. Hai khóa phải khác nhau; không đổi khóa định danh đang dùng nếu chưa có kế hoạch chuyển dữ liệu đã mã hóa. Đổi khóa JWT làm phiên cũ không hợp lệ. Khi cài máy mới, tạo khóa riêng; không dùng chung khóa giữa các môi trường.

`SMS_PUBLIC_URL` là địa chỉ frontend dùng trong link khôi phục. `SMS_SCHOOL_EMAIL_DOMAIN` chỉ áp dụng địa chỉ dự kiến khi nhập học mới, không đổi email đã có và không tự tạo hộp thư Google. SMTP dùng mật khẩu ứng dụng nhập qua `Configure-Gmail.ps1`; script cập nhật đúng nhóm biến, không in bí mật và không tự bật worker outbox cũ.

## Frontend

| Biến | Vai trò |
|---|---|
| `DEV_SERVER_HOST` | Host Vite lắng nghe |
| `DEV_SERVER_PORT` | Port Vite |
| `API_PROXY_TARGET` | Địa chỉ backend mà Vite chuyển `/api` tới |

Các biến này được `vite.config.js` đọc phía server; browser vẫn dùng đường dẫn cùng origin `/api` để cookie/CSRF hoạt động. Không copy `.env.local` của backend sang frontend; không thêm tiền tố `VITE_` cho password, JWT hoặc SMTP, vì Vite có thể đưa biến tiền tố này vào JavaScript gửi xuống browser.

`SMS_TEST_API_TARGET` chỉ được bộ audit trình duyệt truyền vào tiến trình Vite kiểm thử để trỏ H2 cổng 8082, có ưu tiên hơn proxy cục bộ. Không đặt biến này trong cấu hình vận hành.

## Áp dụng thay đổi

- Sửa backend `.env.local`: khởi động lại backend bằng `Start-V6.ps1` hoặc Maven.
- Sửa frontend `.env.local`: khởi động lại Vite. Với bản build triển khai, cấu hình reverse proxy chuyển `/api` tới backend; dev proxy không đi kèm thư mục `dist`.
- Đổi `SERVER_PORT` thì đổi `API_PROXY_TARGET` tương ứng. Đổi địa chỉ frontend thì đổi `SMS_PUBLIC_URL` để link email đúng nơi.
- File local và các biến thể `.env.*` bị Git bỏ qua; frontend giữ `.env.example` làm mẫu. Không bật gửi thư hoặc bootstrap chỉ để kiểm tra cấu hình.
