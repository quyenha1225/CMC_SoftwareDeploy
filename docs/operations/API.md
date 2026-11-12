# Danh mục REST API từ controller

Được sinh từ các annotation hiện có. Mọi API ngoài auth/public/health yêu cầu xác thực; service kiểm tra vai trò, sở hữu và trạng thái. Không nhận role do client tự khai. Chi tiết payload nằm ở controller/service và frontend gọi API tương ứng.

| Controller | Method | Endpoint |
|---|---|---|
| AccountsController | POST | `/api/accounts` |
| AccountsController | POST | `/api/accounts/password` |
| ApiController | GET | `/api/admission-periods/{id}/requirements` |
| ApiController | POST | `/api/admission-periods/{id}/requirements` |
| ApiController | GET | `/api/emails/{id}/attempts` |
| ApiController | GET | `/api/reports/{id}/reviews` |
| ApiController | GET | `/api/grade-sheets/{id}/reviews` |
| ApiController | GET | `/api/notifications/{id}/recipients` |
| ApiController | POST | `/api/students/{id}/photo` |
| ApiController | GET | `/api/students/{id}/photo` |
| ApiController | POST | `/api/mailboxes/{id}/provision` |
| ApiController | POST | `/api/emails/{id}/retry` |
| ApiController | POST | `/api/students/{id}/mailbox` |
| ApiController | GET | `/api/meta` |
| ApiController | POST | `/api/requests/{id}/attachments` |
| ApiController | GET | `/api/request-attachments/{id}/download` |
| ApiController | GET | `/api/resources/{key}` |
| ApiController | GET | `/api/resources/{key}/{id}` |
| ApiController | POST | `/api/resources/{key}` |
| ApiController | PUT | `/api/resources/{key}/{id}` |
| ApiController | GET | `/api/admissions/{id}` |
| ApiController | POST | `/api/admissions/{id}/actions/{action}` |
| ApiController | POST | `/api/admissions/{id}/documents` |
| ApiController | POST | `/api/documents/{id}/verify` |
| ApiController | GET | `/api/documents/{id}/download` |
| ApiController | PUT | `/api/admissions/{id}/identity` |
| ApiController | PUT | `/api/admissions/{id}/high-school` |
| ApiController | POST | `/api/sections/{id}/register` |
| ApiController | POST | `/api/sections/{id}/cancel` |
| ApiController | GET | `/api/sections/{id}/roster` |
| ApiController | GET | `/api/sections/{id}/schedules` |
| ApiController | POST | `/api/sections/{id}/schedules` |
| ApiController | PUT | `/api/enrollments/{id}/grade` |
| ApiController | POST | `/api/sections/{id}/sheet/{action}` |
| ApiController | POST | `/api/invoices/issue` |
| ApiController | GET | `/api/invoices/{id}/items` |
| ApiController | POST | `/api/payments` |
| ApiController | POST | `/api/adjustments` |
| ApiController | POST | `/api/adjustments/{id}/decision` |
| ApiController | POST | `/api/remittances` |
| ApiController | POST | `/api/remittances/{id}/decision` |
| ApiController | GET | `/api/remittances/{id}/allocations` |
| ApiController | POST | `/api/reports` |
| ApiController | POST | `/api/reports/{id}/decision` |
| ApiController | GET | `/api/reports/{id}/summary` |
| ApiController | GET | `/api/timetable` |
| ApiController | GET | `/api/lookups` |
| ApiController | POST | `/api/users/{id}/roles` |
| ApiController | POST | `/api/requests` |
| ApiController | POST | `/api/requests/{id}/process` |
| AuthController | GET | `/api/auth/csrf` |
| AuthController | POST | `/api/auth/login` |
| AuthController | POST | `/api/auth/forgot-password` |
| AuthController | POST | `/api/auth/reset-password` |
| AuthController | GET | `/api/me` |
| AuthController | GET | `/api/public/admission-options` |
| AuthController | POST | `/api/public/admissions` |
| ExamController | GET | `/api/exams/sections` |
| ExamController | GET | `/api/exams` |
| ExamController | POST | `/api/exams` |
| ExamController | PUT | `/api/exams/{id}` |
| HelloController | GET | `/api/hello` |
| RelationsController | GET | `/api/curricula/{id}/courses` |
| RelationsController | POST | `/api/curricula/{id}/courses` |
| RelationsController | GET | `/api/notifications/{id}` |
| RelationsController | POST | `/api/notifications/{id}/read` |
| RelationsController | POST | `/api/notifications/{id}/deliver` |
| RelationsController | GET | `/api/requests/{id}/detail` |
| ReviewWorkflowController | GET | `/api/reviews/{key}` |
| ReviewWorkflowController | POST | `/api/invoice-proposals` |
| ReviewWorkflowController | PUT | `/api/invoice-proposals/{id}` |
| ReviewWorkflowController | GET | `/api/invoice-proposals/{id}` |
| ReviewWorkflowController | POST | `/api/invoice-proposals/{id}/{action}` |
| StudentAcademicController | GET | `/api/student/academic` |
| StudentAcademicController | GET | `/api/student/profile` |
| StudentAcademicController | GET | `/api/sections/{id}/detail` |

## Quy ước phản hồi

- 400: dữ liệu không hợp lệ; 401: chưa đăng nhập/phiên hết hạn; 403: sai quyền; 404: không tồn tại hoặc ngoài phạm vi; 409: xung đột nghiệp vụ; 429: quá số lần thử.
- Các thao tác thay đổi qua cookie auth yêu cầu CSRF header từ `/api/auth/csrf`.
- `/api/meta` và `/api/lookups` giúp dựng giao diện; `/api/reviews/*` chỉ nhận nội dung đã trình, không cho BGH thao tác bước của CTSV/PĐT.
- `/api/hello` là API xác thực; smoke không dùng endpoint này khi chưa đăng nhập.
- `/api/actuator/health` là đường Nginx tới readiness management, chỉ báo UP/DOWN, không công khai cấu hình/metrics.
