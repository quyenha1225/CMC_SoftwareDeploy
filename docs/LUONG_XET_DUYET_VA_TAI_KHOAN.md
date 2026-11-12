# Luồng xét duyệt và dữ liệu thực hành

Ngày cập nhật: 12/11/2026. Dữ liệu mang tên người cụ thể để thực hành, không phải hồ sơ chính thức của trường.

| Nghiệp vụ | Đơn vị chuẩn bị và trình | Ban giám hiệu | Sau khi được duyệt |
|---|---|---|---|
| Bảng điểm | Giảng viên nhập/gửi; PĐT kiểm tra và trình | Phê duyệt hoặc trả lại, có lịch sử | PĐT công bố; sinh viên chỉ xem điểm đã công bố |
| Hồ sơ nhập học | CTSV kiểm tra đạt và chuyển BGH | Duyệt, từ chối hoặc trả lại CTSV | PĐT xác minh, cấp MSSV và phân lớp |
| Học phí | CTSV lập đề nghị theo đăng ký và đơn giá học kỳ, sau đó trình | Duyệt hoặc trả lại đề nghị | CTSV phát hành hóa đơn từ số tiền đã duyệt và ghi nhận thu riêng |
| Điều chỉnh học phí | CTSV đề nghị DEBIT/CREDIT có lý do | Duyệt hoặc từ chối | Chỉ khoản được duyệt ảnh hưởng công nợ |
| Bàn giao tiền | CTSV phân bổ khoản đã thu và trình | Xác nhận hoặc từ chối | Không tạo thêm khoản thu khi xác nhận bàn giao |
| Báo cáo CTSV | CTSV lập/gửi báo cáo học kỳ | Duyệt hoặc trả lại | Lưu lịch sử, không tự thêm doanh thu |

BGH mở mặc định danh sách **Chờ xét duyệt**. Tab **Đã xử lý** chứa lịch sử; bản nháp và nội dung chưa được đơn vị phụ trách trình không vào hàng chờ. Màn tài khoản là quản trị tài khoản, độc lập với duyệt hồ sơ sinh viên.

## Học phí và kiểm soát dữ liệu

Migration `13_INVOICE_REVIEW_WORKFLOW.sql` bổ sung đề nghị, chi tiết học phần và lịch sử xét duyệt. Các khóa ngoại trỏ vào sinh viên, học kỳ và đăng ký hiện có. Mỗi sinh viên/học kỳ có tối đa một đề nghị và một hóa đơn.

Đề nghị lưu tín chỉ/đơn giá tại thời điểm lập. Khi trình và duyệt, backend kiểm tra lại với đăng ký và biểu phí; thay đổi phải được trả lại và lập lại. Đăng ký liên quan bị khóa khi đề nghị đang chờ duyệt hoặc đã duyệt. Phát hành dùng đúng số liệu đã duyệt. Hóa đơn cũ được giữ nguyên, không tạo lịch sử phê duyệt hồi tố. BGH không có quyền phát hành hóa đơn hoặc thu tiền.

Migration `14_REVIEW_PRACTICE_DATA.sql` bổ sung các tình huống để kiểm tra:

- Bảng điểm NW103 chờ PĐT kiểm tra; BA101 đã được PĐT trình BGH.
- Đề nghị `DHP-2026-HK2-003` chờ BGH; `DHP-2026-HK2-004` là bản nháp CTSV. Mỗi đề nghị 3 tín chỉ × 900.000đ, lấy từ đơn giá HK2 đã có.
- Hai đăng ký WD104 cho sinh viên SV260003/SV260004, kèm dòng điểm chưa nhập; không tự gán điểm.
- Đề nghị CREDIT 100.000đ đang chờ duyệt; chưa làm giảm công nợ.
- Bàn giao phần 400.000đ còn lại của khoản thu đã có; không thêm chứng từ thu.
- Báo cáo kỳ 2025–2026 HK2 chờ duyệt có tổng bằng 0 vì chưa có hóa đơn/khoản thu kỳ đó.

Kiểm tra chỉ đọc: `python backend/scripts/Migrate-Database.py --check`. Gồm 10 kiểm tra chuẩn hóa và 6 kiểm tra luồng phê duyệt; số vi phạm phải bằng 0.

## SQL và tài khoản

Cài đầy đủ bằng `data/v6/Install-Original.ps1 -WithApplicationMigrations` trên database mới: SQL 01–03, sau đó migration 05–14. Không chạy file 04 tham khảo và không sửa migration đã áp dụng. Schema ứng dụng có 56 bảng, tính cả bảng quản lý migration.

Sau khi bootstrap tài khoản quản trị theo tài liệu backend, chạy từ thư mục gốc:

```powershell
python backend/scripts/Initialize-PracticeAccounts.py
python backend/scripts/Verify-PracticeAccounts.py --credentials backend/.local/actor-credentials-sms_v6_original.json
```

Script chỉ kích hoạt 15 tài khoản thực hành đã định danh, tạo mật khẩu riêng bằng nguồn ngẫu nhiên an toàn và lưu BCrypt trong MySQL; không đổi mật khẩu các tài khoản đang hoạt động. Danh sách đăng nhập riêng trên máy nằm trong `backend/.local/actor-credentials-sms_v6_original.md`, đã loại khỏi Git. Các file seed công khai không chứa mật khẩu dùng được.

Email khôi phục chỉ gửi thật sau khi cấu hình Gmail/Workspace và bật mail. Hộp thư RESERVED không được xem là đã cấp thành công. Không dùng địa chỉ `.test` để thử nhận email thật.
