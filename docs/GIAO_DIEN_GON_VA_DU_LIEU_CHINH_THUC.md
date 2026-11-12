# Giao diện sinh viên và dữ liệu chính thức

**Cập nhật theo yêu cầu mới:** đã chuyển sang [bộ dữ liệu thực hành có tên cụ thể](BO_DU_LIEU_THUC_HANH.md). Phần nguồn chính thức bên dưới là giới hạn của lần kiểm tra trước, không cản trở việc tạo dữ liệu hư cấu để vận hành thử.

## Điều hướng gọn hơn

- **Hồ sơ cá nhân**: thông tin, ảnh, email cá nhân và email trường; không còn mục email trường riêng trong menu sinh viên.
- **Học phần** mở xuống **Tra cứu lớp học phần** (chỉ xem) và **Đăng ký / hủy học phần** (thao tác đăng ký).
- **Thời khóa biểu** mở xuống **Lịch học**, **Lịch thi**, có chuyển động nhẹ và hỗ trợ giảm chuyển động.
- **Học phí** mở xuống **Công nợ & hóa đơn**, **Lịch sử thanh toán**. Bỏ ID kỹ thuật và phân quỹ nội bộ khỏi màn sinh viên.
- Tổng quan chỉ có banner, một dòng thống kê, tối đa hai buổi học sắp tới và hai thông báo. Các thẻ chức năng lặp menu được bỏ.
- Bấm một lần để đọc thông báo; hồ sơ/chi tiết dùng các dòng thông tin, hạn chế chia thành nhiều ô.

## Số tiền và chứng từ

Thay đổi giao diện không sửa đơn giá, hóa đơn hay chứng từ trong seed/database. Công nợ đọc từ `v_invoice_balances`; học phần trên hóa đơn dùng snapshot `credits_at_issue`, `unit_price_at_issue`, `amount`. Khoản nộp hiển thị đúng số tiền, ngày thu và mã đối soát trong `payments`. Không tạo mã hoặc khoản nộp giả để lấp chỗ trống; sinh viên không được tự ghi nhận đã nộp tiền.

## Cấp email trường

Migration [11_MAILBOX_EMAIL_DELIVERY.sql](../data/v6/11_MAILBOX_EMAIL_DELIVERY.sql) bổ sung nguồn hộp thư và nội dung thư vào hàng đợi hiện có. BGH phải xác nhận hộp thư đã cấp thực tế. Chuyển sang ACTIVE lần đầu hoặc đổi địa chỉ sẽ xếp hàng thông báo đến **email cá nhân** trong hồ sơ, không gửi vào chính hộp thư mới cấp. Cập nhật lặp cùng địa chỉ ACTIVE không tạo thư trùng.

Nội dung lưu tại thời điểm xếp hàng, không chứa mật khẩu. Worker ghi nhận gửi thành công/thất bại và hỗ trợ gửi lại. Chưa có mật khẩu ứng dụng Gmail nên gửi thật vẫn tắt; QUEUED không đồng nghĩa đã gửi. Migration không tự kích hoạt tài khoản/hộp thư seed.

## Nguồn dữ liệu chính thức còn thiếu

Các SQL hiện có ghi rõ DEMO/mẫu. Không thể biến các hồ sơ, lịch thi và khoản tiền này thành dữ liệu chính thức bằng việc đổi tên hoặc bỏ nhãn. Khi chưa có nguồn xác nhận, giữ nguyên giá trị và nhãn dữ liệu.

| Nguồn cần cung cấp đường dẫn | Nội dung đối chiếu |
|---|---|
| Sinh viên / ảnh | MSSV, họ tên, lớp, liên hệ xác minh, ảnh đúng người và quyền sử dụng |
| Giảng viên | Mã, họ tên, đơn vị, lớp được phân công |
| Lịch học | Mã lớp học phần, học kỳ, ngày áp dụng, thứ, giờ, phòng |
| Lịch thi | Mã lớp, loại thi, ngày/giờ, phòng, trạng thái công bố |
| Biểu học phí | Văn bản/biểu phí theo học kỳ và đối tượng, ngày hiệu lực |
| Hóa đơn / khoản thu | MSSV, học kỳ, chi tiết, số tiền, ngày thu, mã chứng từ |
| Email trường | Địa chỉ thực đã cấp và trạng thái; không đưa mật khẩu vào seed |

Khi có nguồn, chuẩn bị seed/migration mới theo ID/FK hiện có, đối chiếu tổng tiền/chứng từ trên bản sao rồi mới áp dụng. Không sửa migration đã ghi checksum. Ba SQL gốc và các bản ghi tài chính hiện tại được giữ để đối chiếu trong khi chờ dữ liệu chính thức.

## Kiểm tra sau cập nhật

- Build FE và 4 kiểm thử API thành công.
- 29 kiểm thử backend/trình duyệt thành công, gồm email cấp hộp thư không trùng và hồ sơ đúng chủ tài khoản có nhiều vai trò.
- Trình duyệt sáu vai trò: 386 lượt kiểm tra, 105 hộp chi tiết; tài khoản sinh viên trên MySQL: 51 lượt kiểm tra, 8 hộp chi tiết. Không phát hiện lỗi JS/API/bố cục trong các tình huống đã kiểm tra.
- Migration 11 đã chạy trên bản sao trước, sau đó áp dụng vào database đang dùng; kiểm tra SQL trả 0 vi phạm.
- Checksum trước/sau của 7 bảng tài chính giữ nguyên: `tuition_rates`, `invoices`, `invoice_items`, `payments`, `tuition_adjustments`, `ctsv_remittances`, `ctsv_remittance_allocations`.
- Chưa nhập dữ liệu/ảnh chính thức vì chưa có nguồn; chưa gửi thư thật vì thiếu cấu hình mật khẩu ứng dụng Gmail.
