# Bộ dữ liệu thực hành có tên cụ thể

Theo yêu cầu mới, hệ thống dùng các nhân vật và thông tin liên hệ có ý nghĩa để thao tác/trình diễn. Đây là dữ liệu hư cấu của dự án, không phải hồ sơ hoặc chứng từ chính thức của trường. Nhãn môi trường thực hành được giữ gọn ở chân trang; không lặp “Sinh viên mẫu 001” trong các màn hình.

| Tài khoản giữ nguyên | Họ tên | MSSV mới | Lớp |
|---|---|---|---|
| student_demo_001 | Lê Minh Mai | SV260001 | KTPM26-A |
| student_demo_002 | Nguyễn Hoàng Nam | SV260002 | KTPM26-A |
| student_demo_003 | Trần Thu Hà | SV260003 | KTPM26-A |
| student_demo_004 | Phạm Quốc Bảo | SV260004 | KTPM26-A |
| student_demo_005 | Đỗ Khánh Linh | SV250005 | HTTT25-A |
| student_demo_006 | Vũ Đức Minh | SV260006 | QTKD26-A |

Giảng viên: Trần Quốc Huy (GV001), Nguyễn Thị Lan (GV002), Lê Anh Tuấn (GV003). Nhân sự: Nguyễn Thanh Hà, Phạm Thị Hương, Đặng Thu Trang. Ứng viên: Nguyễn Gia Huy, Bùi Ngọc Anh.

Thông tin liên hệ, người giám hộ, địa chỉ và email được gắn nhất quán với từng nhân vật. Email dùng miền `.test`; các hộp thư RESERVED không được tự kích hoạt hoặc gửi thư thật. Không tự thêm ảnh người thật cho các nhân vật hư cấu; ảnh hồ sơ vẫn có thể tải lên qua chức năng hiện có.

## File đã cập nhật

- `SMS_V6/02_SEED_DEMO.sql`: sửa trực tiếp tên, mã hiển thị và thông tin mặc định theo yêu cầu.
- `data/v6/02_SEED_DEMO.sql`: bản seed dùng cho cài đặt, nội dung khớp bản trong SMS_V6.
- [12_PRACTICAL_IDENTITIES.sql](../data/v6/12_PRACTICAL_IDENTITIES.sql): cập nhật database hiện có và hoàn thiện hồ sơ/điểm/lịch thi khi cài mới. Không sửa migration đã áp dụng trước đó.
- [DU_LIEU_THUC_HANH.json](DU_LIEU_THUC_HANH.json): bảng đối chiếu tên, mã, lớp liên hệ và email của bộ thực hành.

Chạy cài mới bằng `Install-Original.ps1 -WithApplicationMigrations` để có đủ dữ liệu sau 05–12. Chỉ chạy file seed 02 riêng lẻ không thay thế các migration và không tự cập nhật các bản ghi đã tồn tại.

## Các giá trị được giữ

Giữ nguyên ID số và tất cả quan hệ PK/FK, tên đăng nhập, mật khẩu, vai trò, trạng thái tài khoản và trạng thái cấp email. Chỉ đổi MSSV/mã giảng viên hiển thị; các bảng đăng ký, điểm, hóa đơn vẫn liên kết theo ID cũ.

Không thay đơn giá, số tiền, mã chứng từ, lịch học, ngày thi, các kỳ mở đăng ký hoặc trạng thái duyệt điểm. Checksum của bảy bảng tài chính trước/sau migration khớp nhau. Tài khoản sinh viên đã được kích hoạt để test vẫn đăng nhập bằng thông tin cũ; không bật thêm các tài khoản seed khác.

## Kiểm tra

- Nâng cấp trên bản sao trước khi áp dụng vào database đang dùng; 10 kiểm tra toàn vẹn trả 0 vi phạm.
- Cài mới toàn bộ từ seed đã sửa thành công: 6 sinh viên, 13 đăng ký, 13 bản ghi điểm, 5 lịch thi, 8 hóa đơn, 4 khoản thu.
- So sánh cài mới và dữ liệu đang dùng: mã chứng từ/số tiền từng khoản thu và đơn giá từng học kỳ khớp nhau.
- Build FE và 4 kiểm thử API đạt. Bộ kiểm thử trình duyệt được chạy lại với tên/mã mới trước khi bàn giao.

Kiểm tra trình duyệt sau áp dụng: đăng nhập bằng email `le.minh.mai@example.test` thành công; 51 lượt kiểm tra desktop/mobile và 8 hộp chi tiết đạt, không phát hiện lỗi JS/API/bố cục.
