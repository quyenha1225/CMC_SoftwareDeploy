# Database chuẩn hóa – Student Management System (SMS)

**Mục tiêu:** Database thống nhất cho 4 vai trò nghiệp vụ, đăng ký học phần, lịch học, duyệt điểm nhiều cấp, học phí, yêu cầu và thông báo. Bản này phát triển từ ERD/SQL 28 bảng trước đó, **không phải dữ liệu thật của nhà trường**.

## 1. Bộ file

| File | Sử dụng |
|---|---|
| `00_preflight_sms.sql` | Kiểm tra đã có database/schema cũ hay chưa. Không sửa dữ liệu. |
| `01_schema_sms.sql` | Tạo `sms_db`, **28 bảng**, 3 VIEW; tất cả bảng `CREATE TABLE IF NOT EXISTS`. |
| `02_seed_demo_idempotent.sql` | Tạo dữ liệu demo đủ các phân hệ, sử dụng `INSERT ... WHERE NOT EXISTS`. |
| `03_validate_sms.sql` | Kiểm tra số bảng, số hàng, trùng khóa nghiệp vụ, sai liên kết hóa đơn, quá sĩ số, thiếu điểm v.v. |
| `DATA_DICTIONARY.md` | Mô tả khóa và mối quan hệ, quy tắc chuẩn hóa. |

## 2. Chạy trên MySQL bằng Workbench (dễ nhất)

1. **Sao lưu** database `sms_db` đang dùng (nếu đã có dữ liệu thật hoặc bảng cũ). **Không xóa database hiện tại** để tránh mất dữ liệu.
2. Mở MySQL Workbench, đăng nhập máy chủ MySQL. Chạy `00_preflight_sms.sql` trước.
3. Nếu kết quả **NEW/EMPTY**, mở `01_schema_sms.sql` → Execute; sau đó mở `02_seed_demo_idempotent.sql` → Execute.
4. Cuối cùng, chạy `03_validate_sms.sql`. Kiểm tra **28 bảng, 3 VIEW**, tất cả `violation_count = 0`.
5. **Chạy lại `02_seed_demo_idempotent.sql` lần 2**, rồi chạy lại `03_validate_sms.sql`. Số hàng không được tăng (đây là kiểm thử tính idempotent).
6. Có thể chạy lại `01_schema_sms.sql` mà không tạo bảng thứ hai, **nếu đang dùng đúng schema v2**.

> Quan trọng: `CREATE TABLE IF NOT EXISTS` **không nâng cấp cấu trúc các bảng cũ**. Nếu bạn đã chạy SQL thiết kế trước (có `grades.sheet_id`, `invoices.base_amount`...), `00_preflight_sms.sql` sẽ cảnh báo `OLD SCHEMA DETECTED`. Lúc đó cần **migration ALTER có kiểm soát**, hoặc dùng một database thử nghiệm **mới hoàn toàn** để kiểm tra bộ này. Không chạy `DROP DATABASE` trên dữ liệu đang sử dụng.

## 3. Quy tắc chống trùng và chuẩn hóa

- `users.username`, `students.student_code`, `lecturers.lecturer_code`, `courses.course_code` được ràng buộc `UNIQUE`.
- `user_roles`, `curriculum_courses`, `notification_recipients` dùng **khóa chính tổng hợp**.
- Mỗi sinh viên chỉ có **1 bản ghi đăng ký cho 1 lớp học phần** (`UNIQUE(student_id, section_id)`), nhưng việc ngăn đăng ký hai lớp của **cùng một môn trong một học kỳ** phải bổ sung ở service Spring Boot.
- Mỗi sinh viên chỉ có **1 hóa đơn/học kỳ**; mỗi lần đăng ký chỉ được xuất hiện tối đa 1 lần trong `invoice_items`.
- `payments.reference_no` và các `event_key` của dữ liệu mẫu là duy nhất, giúp chạy seed lại không lặp giao dịch/lịch sử.
- Không lặp lại tên sinh viên trong bảng `students`: thông tin tên thuộc `users`; `students` chỉ lưu học vụ.
- Điểm tổng kết **tính từ điểm thành phần + tỷ trọng** qua `v_student_results`, không nhân bản dữ liệu `total_score`.
- Tổng tiền hóa đơn, đã thu, còn nợ và trạng thái trả phí **tính qua VIEW** `v_invoice_balances`, không nhân bản số tiền tổng kết trong `invoices`.
- Riêng `invoice_items.credits_at_issue`, `unit_price_at_issue` là **ảnh chụp tài chính tại thời điểm xuất hóa đơn** có chủ đích, để đơn giá mới không làm thay đổi chứng từ đã lập. `amount` là cột *generated*, không nhập tay.
- `section_schedules.day_of_week` dùng chuẩn **1=Thứ hai ... 7=Chủ nhật**.

### Vai trò nghiệp vụ

- `STUDENT`: đăng ký học phần, xem lịch/điểm đã công bố và gửi yêu cầu.
- `LECTURER`: xem lớp được phân công, nhập điểm nháp và gửi bảng điểm.
- `TRAINING_OFFICE`: vận hành học vụ, kiểm tra/công bố theo quy trình, quản lý tài khoản và thông báo.
- `PRINCIPAL`: phê duyệt học vụ cấp cuối và hồ sơ sinh viên.

Không tạo actor `SYS_ADMIN` riêng trong phạm vi ứng dụng nghiệp vụ này; quyền vận hành tài khoản/cấu hình được giao cho Phòng Đào tạo. Vai trò kỹ thuật quản trị máy chủ/triển khai là quyền hạ tầng ngoài luồng nghiệp vụ, không phải một actor người dùng bổ sung.

## 4. Dữ liệu mẫu và tài khoản

- Mọi sinh viên/giảng viên/nhân viên trong seed đều mang mã **DEMO** và tên **mẫu**, email thuộc `example.test`.
- `users.password_hash` chứa BCrypt của mật khẩu ngẫu nhiên **không được công bố**; tất cả tài khoản seed có `enabled = FALSE`. Vì vậy **không đăng nhập bằng các tài khoản này được**, cho tới khi Phòng Đào tạo cấp mật khẩu mới và kích hoạt qua ứng dụng. Không có tài khoản quản trị mặc định công khai.
- Các mục `payments` là **giao dịch giả lập**, không phải giao dịch tài chính thật.
- Seed không dùng dữ liệu của sinh viên hay giảng viên ngoài đời.

## 5. Tích hợp Spring Boot

```properties
spring.application.name=backend
server.port=8081
spring.datasource.url=jdbc:mysql://127.0.0.1:3306/sms_db?useUnicode=true&characterEncoding=utf8
spring.datasource.username=${DB_USERNAME:root}
spring.datasource.password=${DB_PASSWORD}
spring.jpa.hibernate.ddl-auto=validate
spring.jpa.open-in-view=false
```

- Sau khi schema đã chạy thành công, dùng `ddl-auto=validate` để Spring Boot **kiểm tra** bảng thay vì tự sửa schema.
- Dùng `ddl-auto=none` nếu dự án Entity chưa khớp schema lúc đang thiết kế. **Không bật `create`/`create-drop`** trên DB dùng chung.
- Spring Boot chưa có đầy đủ Entity thì `validate` sẽ không xác minh tất cả 28 bảng, vì vậy vẫn phải chạy `03_validate_sms.sql`.
- Khi chạy trong Docker Compose, thay `127.0.0.1` bằng **tên service MySQL**, ví dụ `db:3306`.
- Luôn lấy mật khẩu MySQL từ **biến môi trường / secrets**, không commit vào `application.properties` hay GitHub.

## 6. Ràng buộc cần viết ở Service (không thể dựa vào UNIQUE/FK đơn thuần)

1. Kiểm tra sinh viên thuộc chương trình phù hợp, thời gian mở đăng ký, sĩ số, trùng lịch và lớp học phần bị trùng môn.
2. Chống race condition khi hai sinh viên đăng ký suất cuối cùng: transaction + locking hoặc cập nhật có điều kiện.
3. Chặn giảng viên nhập điểm cho lớp không được phân công; không cho sửa sau nộp trừ khi bảng bị trả lại.
4. Điểm phải qua `DRAFT → SUBMITTED → VERIFIED → APPROVED → PUBLISHED`; chỉ `PUBLISHED` được trả về API sinh viên.
5. Khi lập hóa đơn, kiểm tra `invoice_items` thuộc đúng **sinh viên và học kỳ**; giữ lịch sử đơn giá đã chốt.
6. Khi ghi nhận thanh toán, cấm vượt nợ và tạo giao dịch lặp; cần kiểm tra trong transaction.
7. Thay đổi trạng thái học tập phải có kiểm tra quyền và nhật ký, không xóa cứng hồ sơ lịch sử.

## 7. Chạy đi chạy lại an toàn nghĩa là gì?

- **Schema:** Tạo các bảng còn thiếu, không tạo trùng tên; không tự ý DROP. Không tự xử lý được database cũ có cấu trúc khác.
- **Seed:** Dùng mã demo ổn định + `NOT EXISTS` + `UNIQUE`; lần chạy thứ hai sẽ không cộng thêm bản ghi demo.
- **Không dùng** `INSERT IGNORE` đại trà vì có thể che lỗi dữ liệu hoặc khóa ngoại.
- **Không dùng** `DROP TABLE IF EXISTS` hoặc `TRUNCATE` cho lệnh cài đặt bình thường.

**Trạng thái xác minh:** Đã kiểm tra tĩnh tên bảng, quan hệ FK, dữ liệu seed và tính lặp bằng kịch bản SQL; **chưa chạy trên MySQL Server thật trong môi trường tạo tài liệu này**. Kết quả chạy Workbench + file `03_validate_sms.sql` là bước nghiệm thu cần thực hiện trên máy dự án.
