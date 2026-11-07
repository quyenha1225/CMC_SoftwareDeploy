# Từ điển dữ liệu – SMS v2

Có **28 bảng**, chia theo nhóm. Giữ nguyên danh sách thực thể của ERD cũ; các cột thừa được chuẩn hóa hơn. Mỗi bảng có khóa chính (`id` hoặc khóa ghép), khóa tự nhiên để ngăn bản ghi trùng và các khóa ngoại.

**Actor nghiệp vụ:** `STUDENT`, `LECTURER`, `TRAINING_OFFICE`, `PRINCIPAL`. Không thêm `SYS_ADMIN` vào luồng nghiệp vụ; Phòng Đào tạo quản lý tài khoản/cấu hình, Ban Giám hiệu là cấp phê duyệt học vụ cuối.

| Bảng | Đối tượng và liên kết chính | Ràng buộc chống trùng |
|---|---|---|
| `users` | Thông tin đăng nhập, tên và email người dùng | `username`, `email` UNIQUE |
| `roles` | Vai trò hệ thống | `code` UNIQUE |
| `user_roles` | N–N giữa tài khoản và vai trò | PK(`user_id`,`role_id`) |
| `faculties` | Danh mục khoa | `code` UNIQUE |
| `majors` | Ngành thuộc khoa | `code` UNIQUE; (`faculty_id`,`name`) UNIQUE |
| `cohorts` | Khóa tuyển sinh | `code` UNIQUE |
| `academic_classes` | Lớp hành chính thuộc ngành và khóa | `code` UNIQUE |
| `students` | Hồ sơ sinh viên: lớp, ngày sinh, trạng thái | `student_code` và `user_id` UNIQUE |
| `lecturers` | Hồ sơ giảng viên thuộc khoa | `lecturer_code` và `user_id` UNIQUE |
| `academic_years` | Năm học | `name` UNIQUE |
| `semesters` | Học kỳ thuộc năm học, kỳ đăng ký | (`academic_year_id`,`code`) UNIQUE |
| `courses` | Học phần trong danh mục | `course_code` UNIQUE |
| `curricula` | Chương trình theo ngành và khóa | (`major_id`,`cohort_id`) UNIQUE |
| `curriculum_courses` | N–N giữa chương trình và học phần | PK(`curriculum_id`,`course_id`) |
| `course_sections` | Lớp mở của học phần trong học kỳ, phân công giảng viên | (`semester_id`,`section_code`) UNIQUE |
| `section_schedules` | Lịch học của lớp học phần | (`section_id`,`day_of_week`,`starts_at`,`ends_at`) UNIQUE |
| `enrollments` | Sinh viên đăng ký lớp học phần | (`student_id`,`section_id`) UNIQUE |
| `grade_sheets` | Trạng thái duyệt bảng điểm của lớp học phần | `section_id` UNIQUE |
| `grades` | Điểm thành phần của 1 lượt đăng ký | `enrollment_id` UNIQUE |
| `grade_reviews` | Lịch sử thao tác duyệt bảng điểm | `event_key` UNIQUE khi dùng cho import/seed |
| `tuition_rates` | Học phí/tín chỉ cho 1 học kỳ (MVP) | `semester_id` UNIQUE |
| `invoices` | Hóa đơn học phí sinh viên/học kỳ | (`student_id`,`semester_id`) UNIQUE |
| `invoice_items` | Các lượt đăng ký được tính tiền trong hóa đơn | `enrollment_id` UNIQUE |
| `payments` | Thanh toán thuộc hóa đơn | `reference_no` UNIQUE |
| `student_requests` | Yêu cầu do sinh viên gửi | `request_code` UNIQUE |
| `notifications` | Thông báo từ nhà trường | `notification_code` UNIQUE |
| `notification_recipients` | N–N người nhận/thông báo, thời gian đọc | PK(`notification_id`,`user_id`) |
| `audit_logs` | Nhật ký quan trọng, chi tiết JSON | `event_key` UNIQUE cho sự kiện nhập khẩu/demo |

## 3 VIEW đọc dữ liệu, không tạo thêm bảng

- `v_student_results`: tính điểm tổng kết theo điểm thành phần và trọng số tại `course_sections`, chỉ hiển thị điểm đã công bố.
- `v_invoice_balances`: tính tổng hóa đơn, giảm trừ, đã thu, dư nợ và trạng thái.
- `v_section_registration_counts`: tính số lượng đăng ký và chỗ còn trống của lớp.

## Các thay đổi so với SQL bản cũ

- Bỏ `grades.sheet_id`, `grades.total_score` vì có thể suy ra qua `enrollments.section_id` và tính điểm; giảm khả năng điểm tham chiếu sai lớp.
- Giữ workflow tại `grade_sheets`; các tác nhân thao tác và lịch sử duyệt lấy từ `grade_reviews` để tránh lặp lại `approved_by`, `verified_by`.
- Bỏ `invoices.base_amount`, `invoices.status` vì có thể tính trong VIEW từ `invoice_items` + `payments`.
- `invoice_items` lưu ảnh chụp `credits_at_issue` + `unit_price_at_issue`, `amount` GENERATED để giữ lịch sử tính học phí.
- Thêm mã tự nhiên duy nhất cho thanh toán, thông báo, yêu cầu và sự kiện seed.
- Đổi `section_schedules.day_of_week` sang ISO 1..7 (phải đồng bộ Frontend/Backend khi viết API).

> **Chuẩn hóa:** Các bảng danh mục, quan hệ N–N và dữ liệu học vụ được tách để phần lớn thông tin đạt cấu trúc 3NF. Snapshot đơn giá và số tín chỉ trong hóa đơn là ngoại lệ có chủ đích phục vụ lưu trữ lịch sử tài chính; không nên xóa snapshot chỉ để đạt chuẩn hóa hình thức.
