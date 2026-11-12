# Bảo mật EduPortal V6

## Đã triển khai

- JWT HS512 bằng khóa riêng tối thiểu 64 byte, cookie HttpOnly, gắn với phiên server và dấu vân tay mật khẩu; kiểm tra issuer/audience/thời hạn. Đổi mật khẩu làm JWT cũ bị từ chối.
- Token khôi phục 32 byte ngẫu nhiên, chỉ lưu SHA-256 trong DB; hạn 20 phút, dùng một lần, chỉ gửi email trường đã ACTIVE.
- Ảnh sinh viên lưu riêng tư, kiểm tra định dạng/kích thước và chuyển JPEG để loại metadata.

- Spring Security xác thực username/email và mật khẩu BCrypt; phiên server, cookie HttpOnly/SameSite, hết hạn sau 30 phút không hoạt động.
- API lấy trạng thái enabled và các vai trò từ MySQL trên mỗi yêu cầu. Đổi vai trò trên FE chỉ chuyển giữa quyền được server cấp.
- Mở thông tin truy cập chỉ trong luồng nộp hồ sơ: tạo APPLICANT và hồ sơ DRAFT cùng transaction. Chỉ PRINCIPAL được tạo nhân sự/gán quyền; không tự đổi quyền hoặc khóa tài khoản đang dùng.
- Kiểm tra quyền và phạm vi dữ liệu ở BE: sinh viên chỉ xem dữ liệu mình, giảng viên chỉ lớp được giao; không tin student_id/role từ trình duyệt.
- CSRF cho thao tác ghi, đổi session ID khi đăng nhập, giới hạn thử đăng nhập theo IP trong tiến trình.
- Transaction và khóa dòng cho đăng ký, chuyển trạng thái, thu và bàn giao; kiểm tra số dư, thời gian đăng ký, sĩ số, trùng lịch.
- Tệp PDF/PNG/JPEG tối đa 5 MB; kiểm tra chữ ký tệp, UUID riêng, tải qua API có quyền, không phục vụ thư mục tệp công khai.
- CCCD/hộ chiếu mã hóa AES-GCM bằng khóa môi trường, trả về 4 ký tự cuối. Nhật ký ghi truy cập giấy tờ và thao tác nghiệp vụ.
- SQL init và Hibernate DDL bị tắt. Seed gốc bị khóa; bootstrap BGH mặc định tắt, không có mật khẩu mặc định.

## Trước khi vận hành công khai

Đặt FE và API cùng origin sau HTTPS; reverse proxy chuyển /api tới BE. Đặt SESSION_SECURE=true, cấu hình DB bằng tài khoản quyền tối thiểu, không dùng root. Hạn chế cổng DB/API, quản lý bí mật ngoài Git và sao lưu DB cùng kho tệp/khóa mã hóa.

Các kiểm thử hiện tại chạy trên H2 tương thích MySQL, chưa thay thế kiểm thử MySQL thật, kiểm thử tải hoặc đánh giá bảo mật độc lập. Cần rà ma trận quyền theo đơn vị triển khai.

Chưa có MFA, kho phiên phân tán/giới hạn đăng nhập dùng chung nhiều node, quét mã độc tệp và hệ thống audit chống sửa bởi quản trị DB. Giới hạn dung lượng kho và tốc độ đăng ký/tải lên cần cấu hình ở hạ tầng.

Đã bổ sung Gmail SMTP, worker outbox có giới hạn gửi lại và khôi phục mật khẩu qua token một lần cho mailbox trường ACTIVE. Gửi thật còn chờ tài khoản SMTP được cấu hình và kiểm chứng. Cấp hộp thư tại Google và thanh toán online chưa tích hợp. Không coi QUEUED/RESERVED là đã gửi email hay đã tạo hộp thư.

## Kiểm chứng

Backend test kiểm tra khách chưa đăng nhập, truy cập chéo sinh viên, tự nâng quyền, tài khoản bị khóa, thiếu CSRF, BGH không được cấp MSSV và CTSV không tự xác nhận bàn giao. Xem `backend/src/test/java/com/sms/backend/V6SecurityTests.java`.
