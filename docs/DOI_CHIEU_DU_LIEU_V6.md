> Báo cáo trước khi chuyển đổi. Trạng thái triển khai mới: [TRIEN_KHAI_V6.md](TRIEN_KHAI_V6.md).

# Đối chiếu dữ liệu V6 với frontend

Ngày kiểm tra: 09/11/2026.

> Đây là báo cáo lịch sử của FE cũ. Xem [trạng thái hiện tại](TRIEN_KHAI_V6.md). Ngày 10/11/2026: bỏ đăng ký độc lập, phục hồi ảnh trang đăng nhập, giới hạn chức năng theo 47 bảng SQL gốc; kết nối MySQL thực tế còn chờ cấu hình xác thực.

**Kết luận: chưa đồng bộ.** FE hiện dùng dữ liệu cục bộ riêng, chưa đọc API/MySQL. V6 là thiết kế/seed khác với bộ SQL v2 đang có trong thư mục `data/` của repository.

Nguồn đối chiếu: `SMS_Chot_HeThong_V6_3SQL_ERD_Quyen_6VaiTro.zip`, gồm `01_SCHEMA_ALL.sql`, `02_SEED_DEMO.sql`, `03_QUERIES_CHECK.sql`, `MA_TRAN_QUYEN.md` và `README_CHOT_KIEN_TRUC.md`. Nội dung ZIP chỉ được đọc làm tài liệu tham chiếu, không thực thi SQL hoặc tự thay database.

## Những chỗ lệch cần sửa trước khi nối API

| Nhóm | V6 | Frontend hiện tại | Mức độ |
|---|---|---|---|
| Nguồn dữ liệu | 47 bảng, PK/FK và VIEW | Các mảng `portalData.js`, `workflows.js`, localStorage | Chưa kết nối |
| Vai trò | APPLICANT, CTSV, PRINCIPAL, TRAINING_OFFICE, LECTURER, STUDENT | affairs, principal, training, lecturer, student; chưa có APPLICANT | Thiếu vai trò ứng viên |
| Gán quyền | `user_roles`: một tài khoản nhiều vai trò | `users.role`: một chuỗi; chọn vai trò ở FE | Cần xác thực/quyền từ server |
| Trạng thái tài khoản | Seed đặt `enabled=FALSE`, không có mật khẩu sử dụng được | Tài khoản mẫu ACTIVE, đăng nhập không xác thực | Không thể dùng cơ chế FE để đăng nhập seed DB |
| Hồ sơ gốc | Một nguồn `admission_applications`; lịch sử ở `admission_review_events` | `applications` cộng bản sao `studentApprovals` | Hai nguồn trạng thái cần hợp nhất |
| Luồng nhập học | CTSV kiểm tra → BGH duyệt → PĐT xác minh/cấp MSSV/phân lớp → ENROLLED | CTSV xếp lớp trước; BGH duyệt là tạo sinh viên, tài khoản, email | Sai người thực hiện và thời điểm |
| Trạng thái hồ sơ | DRAFT, SUBMITTED, IN_REVIEW, CHANGES_REQUESTED, CTSV_APPROVED, CTSV_REJECTED, SENT_TO_SCHOOL, SCHOOL_APPROVED, SCHOOL_REJECTED, PDT_VERIFIED, ENROLLED | RECEIVED, SUPPLEMENT, ACCEPTED, SCHOOL_PENDING... | Cần ánh xạ/chuyển trạng thái, không gửi thẳng enum FE vào DB |
| Ứng viên/đợt nhập học | `applicant_user_id`, `period_id`; một hồ sơ/người/đợt | Mã người nộp trong localStorage; chưa có tài khoản ứng viên/đợt | Thiếu định danh và đợt nhập học |
| Giấy tờ/học bạ | Yêu cầu giấy tờ theo cấu hình; bản ghi định danh, học bạ, điểm môn lớp 10/11/12 | Bốn loại tệp cố định; thông tin CCCD và tên trường/năm tốt nghiệp | Thiếu điểm học bạ và cấu hình yêu cầu |
| Email trường | RESERVED → PROVISIONING → ACTIVE/FAILED/DISABLED | Tự tạo địa chỉ và gán ACTIVE | Chưa có nghiệp vụ cấp hộp thư |
| Email gửi ra | `outbound_emails`, `email_delivery_attempts` | mailLog với trạng thái nội bộ SIMULATED | Thiếu hàng đợi, gửi lại, lỗi từng lần gửi |
| Năm học/khóa/chương trình | `academic_years`, `cohorts`, `curricula`, `curriculum_courses` | Năm/khóa dạng chuỗi; chưa quản lý chương trình học | Thiếu thực thể và quan hệ |
| Lịch học | `section_schedules`: nhiều buổi/lớp, thứ 1–7 | Mỗi section một day/start/end; lịch tuần hiển thị thứ 2–7 | Thiếu nhiều buổi và Chủ nhật |
| Đăng ký/điểm | `enrollments.id`, `grades.enrollment_id` UNIQUE | Cặp studentId/sectionId, `enrollmentIds` riêng cho SV mẫu | Cần ID đăng ký làm liên kết gốc |
| Giảng viên | `lecturer_id`, kiểm tra lớp được phân công | Một số màn lọc cứng theo tên Trần Quốc Huy | Chưa theo danh tính đăng nhập |
| Tỷ trọng điểm | Cấu hình trên từng lớp học phần | Công thức chung 10/30/60 | Chưa đọc tỷ trọng từng lớp |
| Đăng ký theo kỳ | Có ngày mở/đóng và trạng thái | Chỉ `registrationOpen` boolean; cả hai kỳ đang mở | Chưa kiểm tra khung thời gian |
| Lập/thu học phí | CTSV thực hiện; PĐT cung cấp dữ liệu học phần | PĐT đang ghi nhận thu, SV có nút tự ghi nhận khoản nộp | Lệch phân quyền V6 |
| Đơn giá học phí | `tuition_rates` theo học kỳ | `PRICE_PER_CREDIT=780000` dùng chung | Lệch số tiền |
| Hóa đơn | Hóa đơn phát hành có items snapshot, hạn nộp và trạng thái | Hóa đơn suy ra từ đăng ký; chốt khi thu khoản đầu | Cần nghiệp vụ phát hành hóa đơn riêng |
| Điều chỉnh học phí | CTSV đề nghị DEBIT/CREDIT; BGH duyệt | Chưa có `tuition_adjustments` | Thiếu chức năng |
| Chứng từ/quỹ | `payments.invoice_id`, `fund_id`, `reference_no` duy nhất | Có liên kết hóa đơn; phân quỹ qua fundReceipts, thiếu mã chứng từ đối soát | Cần ánh xạ và kiểm tra chứng từ |
| Bàn giao | CTSV lập; BGH xác nhận/từ chối; phân bổ một khoản thu qua nhiều đợt | CTSV tự xác nhận; mỗi khoản quỹ chỉ bàn giao toàn bộ một lần | Lệch quyền và mô hình phân bổ |
| Báo cáo CTSV | CTSV lập/gửi, BGH duyệt/trả lại; một báo cáo/học kỳ | BGH tự lưu nhiều snapshot, chưa có trình duyệt | Chưa đúng luồng báo cáo V6 |
| Yêu cầu SV | CTSV tiếp nhận; PĐT xem khi được chuyển; có tệp và lịch sử xử lý | PĐT xử lý chính, chưa có chuyển đơn vị/tệp/lịch sử đầy đủ | Lệch quyền và thiếu dữ liệu |
| Nhật ký truy cập | `audit_logs`, đặc biệt xem giấy tờ nhạy cảm | Chưa có nhật ký truy cập đáng tin cậy | Cần server ghi nhận |
| Sự kiện/theo dõi | Chưa có bảng riêng trong 47 bảng V6 | `campusPosts`, `eventFollows` | FE có thêm chức năng ngoài schema |
| Lịch thi | Chưa có bảng lịch thi riêng | EXAM_SCHEDULES cố định | FE có thêm dữ liệu ngoài schema |

## Khác nhau ở dữ liệu ban đầu

So sánh mã nguồn/seed tĩnh, không phải dữ liệu MySQL đang chạy:

| Dữ liệu | FE | Seed V6 |
|---|---|---|
| Mã sinh viên | SV240102… | DEMO26001… |
| Mã ngành | IT, SE, BA | KTPM, HTTT, QTKD |
| Mã lớp | CNTT24A, CNTT24B, QTKD24A | KTPM26-A, HTTT25-A, QTKD26-A |
| Mã học phần | IT201…IT208, MA201, EN201 | SE101, DB102… |
| Số học phần/lớp HP | 10 học phần / 10 lớp | 8 học phần / 5 lệnh INSERT lớp HP |
| Đơn giá HK1/HK2 | 780.000đ / 780.000đ | 850.000đ / 900.000đ |
| Mở đăng ký | HK1 và HK2 đều true | HK1 CLOSED; HK2 OPEN, có registration_from/to |

Không nên thay mỗi mã trên giao diện: cần adapter giữa API và FE để bảo toàn ID/FK, trạng thái và dữ liệu cũ. Dữ liệu mẫu có thể khác nhau về tên, nhưng các sai lệch tiền, quyền và trạng thái là sai lệch nghiệp vụ thực sự.

## Thứ tự xử lý đề xuất

1. Chốt V6 làm phiên bản chuẩn, giữ bộ v2 riêng; migration có kiểm soát, không chạy chồng hai bộ schema.
2. Bổ sung APPLICANT, tài khoản/phiên và ánh xạ sáu vai trò từ API.
3. Hợp nhất hồ sơ; chuyển cấp MSSV/phân lớp sang PĐT sau khi BGH duyệt.
4. Chuyển thu/quỹ/yêu cầu về CTSV; BGH duyệt bàn giao, điều chỉnh và báo cáo.
5. Dùng `enrollment_id`, lịch nhiều buổi, tỷ trọng từng lớp, đơn giá từng kỳ.
6. Bổ sung schema/API cho sự kiện, theo dõi và lịch thi nếu giữ các tính năng này.

**Giới hạn kiểm tra:** đã đọc schema, seed, truy vấn kiểm tra và đối chiếu mã FE; chưa chạy ba SQL trên MySQL, chưa xác minh dữ liệu thực tế trong database của máy. Việc ẩn các nhãn kỹ thuật trên giao diện không thay đổi giới hạn tích hợp và bảo mật trong `Readme.md`/`SECURITY.md`.
