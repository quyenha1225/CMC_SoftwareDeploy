# SMS V6 — Chốt thiết kế dữ liệu và quy trình vận hành

**Phạm vi:** hệ thống quản lý sinh viên, nhập học trực tuyến, Phòng Công tác sinh viên (CTSV), Ban giám hiệu (BGH), Phòng Đào tạo, Giảng viên và Sinh viên. **Không có vai trò Admin độc lập, không có đăng nhập Google.** Ban giám hiệu là vai trò quản trị và phê duyệt cao nhất.

## 1. Ba file SQL, đúng thứ tự chạy

1. `01_SCHEMA_ALL.sql`: toàn bộ **47 bảng**, PK, UNIQUE, CHECK và **78 quan hệ FK** (tính cả 2 khóa thêm bằng `ALTER` có kiểm tra metadata). Không dùng `DROP`, `TRUNCATE`, `DELETE` tự động.
2. `02_SEED_DEMO.sql`: dữ liệu giả lập, tài khoản bị khóa và không có mật khẩu sử dụng được; `INSERT ... WHERE NOT EXISTS`, chạy lặp để thử chống trùng.
3. `03_QUERIES_CHECK.sql`: tạo/thay thế VIEW, xuất báo cáo và kiểm tra toàn vẹn. Chạy lại không sinh bản ghi mới.

**LƯU Ý:** Nếu đã chạy SQL V5, V4 hoặc phiên bản thay đổi thủ công, hãy **backup database trước**. `CREATE TABLE IF NOT EXISTS` không nâng cấp được một bảng đã tồn tại nhưng có cấu trúc không đúng. File 01 chứa các nâng cấp V2–V5 có kiểm tra metadata, không thay thế quy trình migration chuyên biệt trên dữ liệu thật.

### Cách chạy MySQL Workbench

- Mở một lần lượt ba file và Execute; **không dùng V5 ALL_IN_ONE đồng thời với V6**.
- Chạy lại `02_SEED_DEMO.sql`, rồi `03_QUERIES_CHECK.sql` để xác nhận số bản ghi không tăng; các dòng `violation_count` cần bằng 0.
- Sử dụng MySQL 8.0.16+ (CHECK có hiệu lực).
- Mọi đường dẫn dữ liệu/tệp tin demo chỉ là dữ liệu giả lập, không chứa ảnh CCCD/học bạ thật.

## 2. Xác nhận liên thông CTSV → BGH

**Có liên kết ở mức thiết kế database**, nhưng **chưa có Backend/Frontend tích hợp**. Một hồ sơ duy nhất nằm trong `admission_applications` (`id`/`application_code`). CTSV và BGH cùng thao tác trên hồ sơ đó; mỗi quyết định tạo một dòng ở `admission_review_events.application_id → admission_applications.id`.

Luồng trạng thái:

`DRAFT → SUBMITTED → IN_REVIEW → CTSV_APPROVED → SENT_TO_SCHOOL → SCHOOL_APPROVED → PDT_VERIFIED → ENROLLED`.

Ngoại lệ: CTSV có thể `CHANGES_REQUESTED`, `CTSV_REJECTED`; BGH có thể `SCHOOL_REJECTED` hoặc trả lại CTSV theo nghiệp vụ. Backend phải ràng buộc các chuyển trạng thái hợp lệ và lưu event trong **cùng transaction** với cập nhật trạng thái. BGH đọc `v_school_admission_queue`; không tạo bảng `studentApprovals` thứ hai.

**Lúc cấp MSSV:** chỉ PĐT được tạo `students` sau khi có `SCHOOL_APPROVE` hợp lệ của BGH và xác minh hồ sơ. `admission_applications.student_id` liên kết sinh viên đã tạo; mã MSSV `students.student_code` có UNIQUE. Email trường được đặt trước trong `student_school_mailboxes`, chỉ chuyển `ACTIVE` sau khi dịch vụ email trường tạo hộp thư thật; `outbound_emails` và `email_delivery_attempts` lưu lịch sử gửi tới địa chỉ cá nhân.

### Chỉnh Frontend `quyen/admin`

Trong nhánh hiện tại `frontend/src/data/portalData.js` chứa mảng `studentApprovals`, còn `frontend/src/pages/administration/StudentApprovals.jsx` tự đẩy hồ sơ duyệt vào `state.students`. Đây là logic DEMO riêng và chưa đúng luồng CTSV. Khi kết nối API:

- Thay `studentApprovals` localStorage bằng **GET `/api/admissions?status=SENT_TO_SCHOOL`** (được đọc từ cùng bảng `admission_applications`).
- BGH **POST `/api/admissions/{id}/school-approve`** hoặc **`/school-reject`**; Backend xác thực `PRINCIPAL` và ghi một event `admission_review_events` trong transaction.
- KHÔNG tạo sinh viên trong màn BGH. PĐT mới dùng **POST `/api/admissions/{id}/enroll`** để cấp MSSV, liên kết lớp và gửi sự kiện email.
- Màn CTSV dùng chung `/api/admissions`, POST các hành động verify/request-changes/forward; không có `applications` nguồn độc lập.

## 3. Đăng ký → thời khóa biểu → nhập điểm

- `course_sections` là một lớp học phần mở trong `semesters`, có một `course` và giảng viên phụ trách.
- `section_schedules` chứa các buổi học của lớp học phần.
- `enrollments` là đăng ký gốc của sinh viên với lớp học phần: `UNIQUE(student_id,section_id)`.
- `v_student_timetable` lấy lịch học bằng cách JOIN `enrollments → course_sections → section_schedules`, tránh lưu thêm bản sao thời khóa biểu cho từng sinh viên.
- `grades.enrollment_id` UNIQUE, chỉ có điểm khi đã có bản ghi đăng ký.
- `grade_sheets` quản lý duyệt bảng điểm: Giảng viên gửi → PĐT kiểm tra → BGH duyệt → PĐT công bố. `v_grade_entry_roster` giúp giảng viên nhập điểm đúng danh sách học phần; `v_student_results` chỉ hiển thị bảng điểm `PUBLISHED`.

Backend phải kiểm tra trùng môn, trùng giờ học, sĩ số, kỳ đăng ký, quyền giảng viên và thứ tự duyệt; ràng buộc FK/UNIQUE không tự giải quyết hết các nghiệp vụ này.

## 4. Hóa đơn → thu → quỹ CTSV → bàn giao → báo cáo

- `invoices(student_id,semester_id)` UNIQUE: một hóa đơn học phí chính cho sinh viên/một học kỳ.
- `invoice_items.enrollment_id` UNIQUE: mỗi lần đăng ký học phần được tính đúng một dòng học phí. Snapshot tín chỉ và đơn giá khi phát hành để giữ số liệu lịch sử.
- `tuition_adjustments`: phụ thu hoặc giảm trừ phát sinh. Chỉ điều chỉnh `APPROVED` mới được tính.
- `payments.invoice_id`: một hóa đơn có thể thu nhiều lần; `reference_no` UNIQUE chống thu trùng chứng từ. `payments.fund_id` nối với quỹ CTSV; `NULL` ở dữ liệu cũ nghĩa là **chưa đối soát**, không tự coi là thu vào quỹ.
- `ctsv_funds` nhận tổng các `payments` đã phân quỹ; `ctsv_remittances` ghi bàn giao nhà trường với trạng thái `CONFIRMED`, và `ctsv_remittance_allocations` nối **từng chứng từ thanh toán** với **đợt bàn giao** (có thể phân bổ một khoản thu qua nhiều đợt). Số dư quỹ là **thu – tiền bàn giao đã xác nhận**, không lưu thêm cột `balance` cố định.
- `ctsv_semester_reports` là một báo cáo/một học kỳ; `ctsv_semester_report_reviews` lưu sự kiện BGH trả lại/phê duyệt.
- `v_invoice_balances`: công nợ theo từng hóa đơn, từ chi tiết hóa đơn + điều chỉnh được duyệt – thanh toán.
- **`v_school_tuition_by_semester`**: số học phí phải thu, đã thu, còn nợ **của toàn trường theo kỳ**.
- **`v_school_tuition_total`**: tổng toàn trường qua tất cả học kỳ, không bị giới hạn ở một sinh viên.
- `v_ctsv_semester_finance`: số thu qua CTSV, số chưa phân quỹ, số đã bàn giao và số phản ánh, sự vụ của sinh viên.

**Quy tắc quan trọng ngoài SQL:** Mọi khoản tiền thu cần xác minh thực tế, đối soát `reference_no`, không được vượt nợ trừ khi có cơ chế ghi có/hoàn tiền được phê duyệt; mọi khoản bàn giao được BGH xác nhận phải kiểm tra số dư có thể bàn giao trong transaction. Không xóa/sửa chứng từ đã xác nhận mà cần cơ chế điều chỉnh có dấu vết.

## 5. Chức năng và quyền

| Vai trò trong `roles.code` | Quyền chính | Không được |
|---|---|---|
| `APPLICANT` | Đăng ký tài khoản, nộp/sửa hồ sơ của mình, upload giấy tờ | Duyệt hồ sơ, cấp MSSV |
| `CTSV` | Tiếp nhận, kiểm tra giấy tờ, yêu cầu bổ sung, chuyển hồ sơ BGH, tiếp nhận yêu cầu SV, thu/đối soát học phí và quỹ, lập báo cáo | Phê duyệt cuối hồ sơ, tự xác nhận bàn giao, công bố điểm |
| `PRINCIPAL` (**BGH, cao nhất**) | Phê duyệt/từ chối hồ sơ, duyệt bảng điểm, duyệt điều chỉnh học phí, xác nhận bàn giao và báo cáo, quản lý tài khoản/phân quyền và xem báo cáo toàn trường | Không tự tạo khoản thu thay CTSV nếu không có phân quyền nghiệp vụ phù hợp |
| `TRAINING_OFFICE` | Kiểm tra quyết định nhập học, tạo sinh viên/MSSV, phân lớp, mở học phần, xét duyệt bước PĐT và công bố bảng điểm | Duyệt hồ sơ thay BGH, xác nhận quỹ |
| `LECTURER` | Lớp phụ trách, danh sách SV, nhập và gửi bảng điểm | Chấm lớp người khác, công bố điểm trước khi duyệt |
| `STUDENT` | Xem hồ sơ/lịch/điểm đã công bố/công nợ của mình, đăng ký học phần và gửi yêu cầu CTSV | Sửa điểm/thu tiền/duyệt hồ sơ |

**Không có `SYS_ADMIN` trong seed V6 mới.** Nếu database của bạn đã có role `SYS_ADMIN` hoặc `admin_demo` từ V5, V6 **không tự xóa/đổi các bản ghi đó** để tránh mất dữ liệu. Trong Backend/Frontend không sử dụng actor Admin riêng, và cần thực hiện một migration được duyệt để vô hiệu hóa/quy đổi role cũ nếu môi trường của bạn có sẵn.

## 6. Vai trò hệ thống — không nhầm với người thao tác

- Màn BGH không có bản sao hồ sơ `studentApprovals`; đây chỉ là một màn lọc từ `admission_applications`.
- Không lưu lịch học riêng vào bảng sinh viên: truy xuất từ `enrollments`.
- Không lưu `total_debt` trên từng sinh viên: tính bởi các VIEW từ giao dịch thực tế.
- Không lưu bản sao email trường trong từng hóa đơn; dùng `student_school_mailboxes`.
- Dữ liệu cá nhân nhạy cảm như học bạ, CCCD, nơi sinh và địa chỉ phải có phân quyền truy cập và nhật ký xem; tệp scan được giữ trong private storage, số CCCD đầy đủ cần mã hóa ngoài khóa DB.

## 7. Kiểm tra đã thực hiện và giới hạn

Đã kiểm tra tĩnh các định nghĩa 47 bảng, 78 FK, tham chiếu tên bảng/cột, tính độc nhất của khóa, các lệnh seed V6, và xuất sơ đồ trực tiếp từ metadata SQL. **Chưa chạy thực tế trên MySQL 8 của bạn** và chưa tích hợp Frontend/Backend. Trước khi triển khai production: backup, migration trên bản sao DB, chạy 3 SQL, rà soát toàn bộ kết quả validation và kiểm thử giao dịch đồng thời trên Backend.
