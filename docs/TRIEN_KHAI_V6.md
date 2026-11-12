# Triển khai theo SQL V6

Cập nhật 10/11/2026: [backend/luồng nghiệp vụ](BACKEND_V6_LUONG_NGHIEP_VU.md) và [API](API_BACKEND_V6.md). Giữ nguyên dữ liệu sinh viên. Đã bổ sung JWT, tài khoản BGH riêng, ảnh hồ sơ, token khôi phục và Gmail SMTP; thêm hai bảng riêng, tổng 49 bảng. Tài khoản SMTP chưa được cấu hình, chưa gửi email thật.

## Phạm vi đã chuyển

Runtime FE hiện tại ở `frontend/src/v6`; gọi API thực, không dùng state/localStorage cũ để đăng nhập hoặc lưu nghiệp vụ. BE truy vấn các bảng/VIEW V6 qua JDBC, giữ ID/FK và enum SQL.

- Sáu vai trò, tài khoản đa vai trò, mật khẩu BCrypt, phiên và quyền từ server.
- Một hồ sơ gốc, giấy tờ theo đợt và các phiên bản tệp, định danh/học bạ/điểm THPT, lịch sử duyệt; CTSV → BGH → PĐT cấp MSSV/phân lớp.
- Khoa/ngành/khóa/lớp, năm học/học kỳ/chương trình đào tạo và học phần của chương trình.
- Đăng ký theo cửa sổ thời gian, sĩ số, chương trình và trùng nhiều buổi; lịch tuần có Chủ nhật, khung 07–19 giờ.
- Điểm liên kết enrollment_id, tỷ trọng theo lớp; GV gửi → PĐT kiểm tra → BGH duyệt → PĐT công bố.
- CTSV phát hành hóa đơn snapshot, dùng đơn giá từng kỳ, ghi nhận thu có mã chứng từ duy nhất; điều chỉnh do BGH duyệt.
- Bàn giao phân bổ một phần khoản thu, CTSV lập/BGH duyệt; một báo cáo CTSV mỗi học kỳ.
- Yêu cầu sinh viên chuyển CTSV/PĐT, có phản hồi và lịch sử; thông báo có danh sách người nhận/đánh dấu đọc.
- Chỉ dùng 47 bảng SQL gốc; đã bỏ chức năng sự kiện/theo dõi/lịch thi ngoài schema.
- Bỏ đăng ký tài khoản độc lập. Luồng nộp hồ sơ tạo APPLICANT và hồ sơ nháp cùng transaction; STUDENT chỉ cấp sau duyệt.
- Bổ sung cấu hình giấy tờ theo đợt, lịch sử duyệt điểm/báo cáo, lần gửi email và người nhận thông báo.
- Danh sách phân trang/tìm kiếm server, abort request cũ, debounce 250 ms.

## Chưa hoàn tất / cần tích hợp tiếp

- Đã nhập ba SQL gốc vào sms_v6_original và kiểm tra danh mục API trên MySQL; không ghi đè dữ liệu v2.
- Chưa có công cụ migration bản ghi v2 sang V6; tài khoản seed không được tự kích hoạt.
- Đã có SMTP worker/retry, mặc định tắt và chưa cấu hình Gmail thật; cấp hộp thư chưa kết nối nhà cung cấp.
- Quên mật khẩu đã có token một lần qua email trường ACTIVE; còn chờ kiểm chứng với Gmail thật.
- Chưa kết nối cổng thanh toán, đối soát ngân hàng tự động; CTSV ghi nhận chứng từ.
- Chưa có tệp thật tương ứng đường dẫn seed. Tệp phải được tải qua API để đưa vào kho riêng.
- Các báo cáo sử dụng VIEW số liệu hiện tại; chưa xuất PDF/ký số.
- Phần giao diện/test cũ được giữ tham khảo; không được xem localStorage cũ là dữ liệu đã chuyển sang SQL.

## Chạy và kiểm chứng

Xem [Readme](../Readme.md) và [database V6](../data/v6/README.md). Test dùng H2 với fixture chuyển đổi kiểu dữ liệu từ schema V6. Cần chạy tiếp bộ SQL kiểm tra gốc trên database MySQL V6 đã nhập, rồi kiểm thử đủ sáu vai trò trên dữ liệu của trường trước khi triển khai.

[Báo cáo đối chiếu trước khi chuyển đổi](DOI_CHIEU_DU_LIEU_V6.md) là mốc lịch sử; bảng lệch trong tài liệu đó mô tả runtime localStorage cũ, không phải toàn bộ trạng thái hiện tại.
