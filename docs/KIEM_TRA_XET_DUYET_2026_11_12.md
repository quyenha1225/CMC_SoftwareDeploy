# Kết quả kiểm tra luồng xét duyệt — 12/11/2026

Đã áp dụng migration 13–14 lên `sms_v6_original` sau khi backup và chạy thử trên database bản sao. Backend mới chạy cổng 8081, frontend cổng 5173.

| Kiểm tra | Kết quả |
|---|---|
| Backend Maven | 31 bài đạt, 0 lỗi; 1 bài UI tùy chọn không chạy trong lượt Maven |
| Frontend | Build đạt, 4 bài API đạt |
| SQL cài mới 01–03 + 05–14 | Cài thành công trên database mới, 16 kiểm tra toàn vẹn bằng 0 |
| SQL đang chạy | Checksum migration đúng; 16 kiểm tra toàn vẹn bằng 0 |
| Đăng nhập MySQL thật | 15 tài khoản đăng nhập đúng vai trò |
| BGH | 81 lượt kiểm tra màn hình, 26 hộp thoại đạt |
| PĐT | 162 lượt kiểm tra màn hình, 53 hộp thoại đạt |
| CTSV | 81 lượt kiểm tra màn hình, 26 hộp thoại đạt |
| Giảng viên | 36 lượt kiểm tra màn hình, 6 hộp thoại đạt |
| Sinh viên | 51 lượt kiểm tra màn hình, 8 hộp thoại đạt |
| Ứng viên | 13 lượt kiểm tra màn hình, 2 hộp thoại đạt |

Kiểm tra trình duyệt dùng các tài khoản MySQL vừa kích hoạt, gồm màn hình desktop/mobile, mở chi tiết, lỗi JavaScript và tràn bố cục. Đây là kiểm tra tự động theo các tình huống hiện có, không khẳng định mọi tình huống sử dụng đều đã được bao phủ.

Trên database bản sao, đã thực hiện thành công chuỗi PĐT trình → BGH duyệt → PĐT công bố; trình/duyệt/phát hành học phí; trả lại/sửa đề nghị; PĐT xác minh/cấp MSSV. Kiểm tra từ chối quyền xác nhận BGH không thể tự thực hiện bước của PĐT/CTSV. Các thao tác thử có thay đổi trạng thái được giới hạn ở bản sao.

Đối chiếu SHA-256 trước/sau cập nhật trên database chính: toàn bộ dòng của `tuition_rates`, `invoices`, `invoice_items`, `payments` và kết quả `v_invoice_balances` không thay đổi. Dữ liệu chờ duyệt mới chưa tạo khoản thu hoặc tự đổi công nợ.

Log chi tiết nằm trong `backend/logs/review-*`; backup và báo cáo chạy thử trong `backend/.local/backups/20261112_112901/`. Tài khoản ở file riêng `backend/.local/actor-credentials-sms_v6_original.md`, không đưa lên Git. Xem [luồng nghiệp vụ](LUONG_XET_DUYET_VA_TAI_KHOAN.md).
