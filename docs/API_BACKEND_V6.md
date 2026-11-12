# Danh sách API backend V6

Sinh từ annotations của controller ngày 10/11/2026. Quy tắc chi tiết: [luồng nghiệp vụ](BACKEND_V6_LUONG_NGHIEP_VU.md). Mọi URL dưới đây có tiền tố /api; dùng cookie phiên + JWT, các thao tác ghi phải có CSRF. URL công khai chỉ gồm auth/csrf, auth/login, auth/forgot-password, auth/reset-password và public/**. `/api/auth/logout` do Spring Security xử lý, trả 204.

| Method | URL | Controller |
|---|---|---|
| POST | `/api/students/{id}/mailbox` | ApiController |
| POST | `/api/accounts/password` | AccountsController |
| POST | `/api/accounts` | AccountsController |
| GET | `/api/admission-periods/{id}/requirements` | ApiController |
| POST | `/api/admission-periods/{id}/requirements` | ApiController |
| GET | `/api/emails/{id}/attempts` | ApiController |
| GET | `/api/reports/{id}/reviews` | ApiController |
| GET | `/api/grade-sheets/{id}/reviews` | ApiController |
| GET | `/api/notifications/{id}/recipients` | ApiController |
| POST | `/api/students/{id}/photo` | ApiController |
| GET | `/api/students/{id}/photo` | ApiController |
| POST | `/api/mailboxes/{id}/provision` | ApiController |
| POST | `/api/emails/{id}/retry` | ApiController |
| GET | `/api/meta` | ApiController |
| POST | `/api/requests/{id}/attachments` | ApiController |
| GET | `/api/request-attachments/{id}/download` | ApiController |
| GET | `/api/resources/{key}` | ApiController |
| GET | `/api/resources/{key}/{id}` | ApiController |
| POST | `/api/resources/{key}` | ApiController |
| PUT | `/api/resources/{key}/{id}` | ApiController |
| GET | `/api/admissions/{id}` | ApiController |
| POST | `/api/admissions/{id}/actions/{action}` | ApiController |
| POST | `/api/admissions/{id}/documents` | ApiController |
| POST | `/api/documents/{id}/verify` | ApiController |
| GET | `/api/documents/{id}/download` | ApiController |
| PUT | `/api/admissions/{id}/identity` | ApiController |
| PUT | `/api/admissions/{id}/high-school` | ApiController |
| POST | `/api/sections/{id}/register` | ApiController |
| POST | `/api/sections/{id}/cancel` | ApiController |
| GET | `/api/sections/{id}/roster` | ApiController |
| GET | `/api/sections/{id}/schedules` | ApiController |
| POST | `/api/sections/{id}/schedules` | ApiController |
| PUT | `/api/enrollments/{id}/grade` | ApiController |
| POST | `/api/sections/{id}/sheet/{action}` | ApiController |
| POST | `/api/invoices/issue` | ApiController |
| GET | `/api/invoices/{id}/items` | ApiController |
| POST | `/api/payments` | ApiController |
| POST | `/api/adjustments` | ApiController |
| POST | `/api/adjustments/{id}/decision` | ApiController |
| POST | `/api/remittances` | ApiController |
| POST | `/api/remittances/{id}/decision` | ApiController |
| GET | `/api/remittances/{id}/allocations` | ApiController |
| POST | `/api/reports` | ApiController |
| POST | `/api/reports/{id}/decision` | ApiController |
| GET | `/api/reports/{id}/summary` | ApiController |
| GET | `/api/timetable` | ApiController |
| GET | `/api/lookups` | ApiController |
| POST | `/api/users/{id}/roles` | ApiController |
| POST | `/api/requests` | ApiController |
| POST | `/api/requests/{id}/process` | ApiController |
| GET | `/api/auth/csrf` | AuthController |
| POST | `/api/auth/login` | AuthController |
| POST | `/api/auth/forgot-password` | AuthController |
| POST | `/api/auth/reset-password` | AuthController |
| GET | `/api/me` | AuthController |
| GET | `/api/public/admission-options` | AuthController |
| POST | `/api/public/admissions` | AuthController |
| GET | `/api/curricula/{id}/courses` | RelationsController |
| POST | `/api/curricula/{id}/courses` | RelationsController |
| GET | `/api/notifications/{id}` | RelationsController |
| POST | `/api/notifications/{id}/read` | RelationsController |
| POST | `/api/notifications/{id}/deliver` | RelationsController |
| GET | `/api/requests/{id}/detail` | RelationsController |

## Hợp đồng dữ liệu chung

- `GET /resources/{key}?page=1&size=10&search=...` trả `{items,total,page,size,title,fields,canWrite}`. Size 1–50; tham số tìm kiếm dùng prepared statement. `GET /meta` trả danh mục chức năng, trường nhập và quyền ghi của tài khoản.
- `POST /resources/{key}` tạo, `PUT /resources/{key}/{id}` cập nhật theo danh sách trường metadata. Không dùng CRUD tổng quát cho khoản thu, hóa đơn, điểm, reset, bàn giao hoặc tạo sinh viên; phải dùng endpoint nghiệp vụ.
- JSON object cho body thường; tải tệp dùng multipart/form-data với trường `file`; hồ sơ bổ sung trường `type` là mã giấy tờ. Browser tự đặt multipart boundary.
- 200/204: thành công; 400: đầu vào; 401: chưa xác thực/phiên/JWT; 403: quyền/CSRF; 404: không có bản ghi trong phạm vi; 409: trạng thái, ràng buộc hoặc xung đột; 413: quá giới hạn request; 429: vượt giới hạn thử; 503: DB hoặc dịch vụ cấu hình chưa sẵn sàng. Lỗi ứng dụng thông thường có `{message}`. Lỗi upload ngoài controller có thể dùng định dạng lỗi Spring.

## Ví dụ body các nghiệp vụ

ID dưới đây chỉ minh họa định dạng; lấy ID thực tế từ lookups/list, không thay mã seed bằng các ID này.

```json
// POST /auth/login
{"username":"principal","password":"<mật khẩu cục bộ>"}
// POST /public/admissions
{"full_name":"Họ tên người nộp","email":"nguoinop@example.com","username":"nguoinop","password":"<ít nhất 12 ký tự>","period_id":1,"major_id":1}
// POST /admissions/{id}/actions/ENROLL — PĐT
{"student_code":"MSSV_THUC_TE","class_id":1,"note":"Đã xác minh"}
// POST /documents/{id}/verify — CTSV
{"verified":false,"reason":"Ảnh giấy tờ chưa rõ"}
// PUT /admissions/{id}/high-school — ứng viên của hồ sơ
{"school_name":"Trường THPT","school_province":"Hà Nội","graduation_year":2026,"graduation_status":"GRADUATED","transcript_average":8.1,"scores":[{"grade_level":12,"subject_code":"MATH","average_score":8.5}]}
// POST /sections/{id}/schedules — PĐT
{"day_of_week":1,"starts_at":"07:00","ends_at":"09:00","room":"A101"}
// PUT /enrollments/{id}/grade — GV lớp phụ trách
{"attendance_score":9,"midterm_score":8,"final_score":8.5,"remark":""}
// POST /sections/{id}/sheet/SUBMIT — GV
{"note":"Đã đối chiếu điểm"}
// POST /invoices/issue — CTSV
{"student_id":1,"semester_id":1}
// POST /payments — CTSV
{"invoice_id":1,"fund_id":1,"amount":1000000,"reference_no":"CHUNG-TU-DUY-NHAT","note":"Thu một phần"}
// POST /adjustments — CTSV
{"invoice_id":1,"kind":"CREDIT","amount":100000,"reason":"Lý do điều chỉnh"}
// POST /adjustments/{id}/decision — BGH
{"approve":true}
// POST /remittances — CTSV
{"fund_id":1,"semester_id":1,"allocations":[{"payment_id":1,"allocated_amount":500000}],"note":"Bàn giao một phần"}
// POST /remittances/{id}/decision hoặc /reports/{id}/decision — BGH
{"approve":false,"note":"Cần đối soát chứng từ"}
// POST /reports — CTSV, kỳ đã kết thúc
{"semester_id":1}
// POST /requests — sinh viên
{"request_type":"DOCUMENT_REQUEST","content":"Nội dung đề nghị"}
// POST /requests/{id}/process — CTSV
{"action":"ASSIGN","handled_by":1,"note":"Chuyển PĐT"}
// POST /notifications/{id}/deliver — nhân sự có quyền
{"role":"STUDENT"}
// POST /accounts — BGH
{"full_name":"Cán bộ","username":"canbo","email":"canbo@example.com","password":"<ít nhất 12 ký tự>","role":"CTSV"}
// POST /users/{id}/roles — BGH
{"roles":["CTSV","TRAINING_OFFICE"]}
// POST /mailboxes/{id}/provision — BGH, sau cấp thật tại Google
{"school_email":"mssv@ten-truong.edu.vn","provisioning_status":"ACTIVE","mailbox_confirmed":true,"note":"Đã kiểm tra hộp thư tại nhà cung cấp"}
// POST /auth/forgot-password
{"email":"mssv@ten-truong.edu.vn"}
// POST /auth/reset-password
{"token":"<token trong email>","new_password":"<ít nhất 12 ký tự>"}
```

Các khối trên là JSON có chú thích để đọc tài liệu (JSONC); khi gọi API chỉ gửi từng object, không gửi dòng chú thích.

Các API học vụ sinh viên, chi tiết lớp và lịch thi bổ sung ngày 12/11/2026 được mô tả tại [Khôi phục giao diện sinh viên](KHOI_PHUC_GIAO_DIEN_SINH_VIEN_2026_11_12.md).

Sau chuẩn hóa SQL 08–10, form buổi học dùng `room_id`; form lịch thi dùng `room_id`, `exam_type_id`. Danh mục có trong `/api/lookups`; PĐT quản lý qua `/api/resources/rooms` và `/api/resources/exam_types`. API vẫn nhận `room`/`exam_type` của client cũ nếu danh mục tương ứng tồn tại. `data_origin` do server/seed quản lý, client không được tự chuyển lịch mẫu thành lịch chính thức. Xem [báo cáo chuẩn hóa](CHUAN_HOA_SQL_2026_11_12.md).

GET `/api/student/profile` trả hồ sơ của chính tài khoản sinh viên, kể cả khi tài khoản có thêm vai trò nhân sự. Khi xác nhận hộp thư ACTIVE, `/api/mailboxes/{id}/provision` xếp hàng thông báo cấp email đến email cá nhân; không gửi mật khẩu. Xem [giao diện và nguồn dữ liệu chính thức](GIAO_DIEN_GON_VA_DU_LIEU_CHINH_THUC.md).
