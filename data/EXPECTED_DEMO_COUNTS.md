# Số bản ghi dự kiến sau seed (database trống)

Đây là bộ dữ liệu mô phỏng. Bảng đếm này áp dụng khi bạn chạy `01_schema_sms.sql` và `02_seed_demo_idempotent.sql` trên **database chưa có bản ghi**.

| Bảng | Dự kiến |
|---|---:|
| roles | 4 |
| users | 11 |
| user_roles | 11 |
| faculties | 2 |
| majors | 3 |
| cohorts | 2 |
| academic_classes | 3 |
| students | 6 |
| lecturers | 3 |
| academic_years | 1 |
| semesters | 2 |
| courses | 8 |
| curricula | 3 |
| curriculum_courses | 13 |
| course_sections | 5 |
| section_schedules | 5 |
| enrollments | 13 |
| grade_sheets | 4 |
| grades | 7 |
| grade_reviews | 6 |
| tuition_rates | 2 |
| invoices | 8 |
| invoice_items | 13 |
| payments | 3 |
| student_requests | 2 |
| notifications | 2 |
| notification_recipients | 10 |
| audit_logs | 3 |

**Kỳ vọng sau khi chạy lại seed:** Số bản ghi ở 28 bảng giữ nguyên, không phát sinh dòng mới. Hãy xác nhận điều này bằng `03_validate_sms.sql` trên máy có MySQL.
