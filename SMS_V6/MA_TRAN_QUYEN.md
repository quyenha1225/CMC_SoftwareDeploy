# Ma trận quyền thống nhất — KHÔNG CÓ ADMIN RIÊNG

Ký hiệu: ✓ thực hiện; X xem; – không được phép. Quyền kiểm tra ở Spring Security + Service theo mã vai trò, dữ liệu phải lọc theo người sở hữu/đơn vị.

| Nghiệp vụ | Ứng viên `APPLICANT` | CTSV | BGH `PRINCIPAL` | PĐT | Giảng viên | Sinh viên |
|---|---:|---:|---:|---:|---:|---:|
| Nộp/sửa hồ sơ của mình | ✓ | – | X | – | – | – |
| Kiểm tra học bạ/CCCD, yêu cầu bổ sung | – | ✓ | X | – | – | – |
| Chuyển hồ sơ lên BGH | – | ✓ | X | – | – | – |
| Duyệt/từ chối hồ sơ nhập học cuối | – | – | ✓ | – | – | – |
| Cấp MSSV, phân lớp, xác minh PĐT | – | – | X | ✓ | – | – |
| Cấu hình email trường/quản lý tài khoản | – | – | ✓ | X | – | – |
| Xem lịch học/đăng ký học phần | – | – | X | ✓ | X theo lớp | ✓ của mình |
| Nhập/gửi bảng điểm | – | – | X | X | ✓ lớp phụ trách | – |
| Kiểm tra/công bố điểm | – | – | X | ✓ | – | X khi đã công bố |
| Duyệt bảng điểm | – | – | ✓ | – | – | – |
| Lập hóa đơn học phí theo kỳ | – | ✓ | X | Cung cấp dữ liệu HP | – | X của mình |
| Ghi nhận thu học phí, quỹ CTSV | – | ✓ | X | – | – | X của mình |
| Đề nghị điều chỉnh học phí | – | ✓ | X | – | – | Đề nghị qua yêu cầu |
| Duyệt điều chỉnh học phí | – | – | ✓ | – | – | – |
| Bàn giao tiền cho nhà trường | – | ✓ lập | ✓ xác nhận | – | – | – |
| Lập báo cáo cuối học kỳ | – | ✓ | X | – | – | – |
| Phê duyệt/trả lại báo cáo CTSV | – | – | ✓ | – | – | – |
| Tra cứu tổng công nợ toàn trường | – | X nghiệp vụ | ✓ | X theo nhu cầu | – | X của mình |
| Tiếp nhận/yêu cầu sinh viên | – | ✓ | X cấp trường | X nếu được chuyển | – | ✓ gửi yêu cầu |

## Ràng buộc thiết kế

- **BGH là cấp quản trị cao nhất**, nhưng thao tác thu tiền vẫn do CTSV chịu trách nhiệm và phải có dấu vết xác nhận của BGH.
- Một người có thể được cấp nhiều vai trò thông qua `user_roles` khi được BGH ủy quyền; trường hợp đó Backend vẫn kiểm tra quyền của **hành động cụ thể**, không chỉ kiểm tra sự hiện diện của tài khoản.
- Không còn dùng `SYS_ADMIN` làm actor của sản phẩm; các tài khoản cũ nếu có cần xử lý bằng migration được duyệt.
- Quyền xem tệp học bạ/CCCD phải được ghi `audit_logs`, không trả file công khai từ thư mục static.
