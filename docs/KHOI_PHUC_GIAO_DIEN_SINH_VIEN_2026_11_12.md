# Khôi phục giao diện sinh viên — 12/11/2026

## Các phần đã bổ sung

- Hiệu ứng chào EduPortal khi mở phiên trình duyệt, chuyển trang nhẹ; hỗ trợ giảm chuyển động theo cài đặt hệ điều hành.
- Tổng quan sinh viên đọc MySQL: MSSV, lớp, ngành, học phần, tín chỉ và số học phần có điểm; liên kết đến từng màn nghiệp vụ.
- Lớp học phần và đăng ký: lọc học kỳ, tìm môn/giảng viên, hai danh sách lớp và đăng ký của tôi, buổi học, phòng, sĩ số, giảng viên, chi tiết tỷ trọng điểm và thời gian mở đăng ký.
- Đăng ký/hủy có hộp xác nhận. API trả lý do khóa thao tác và kiểm tra lại khi gửi: thời gian mở kỳ, trạng thái sinh viên, hóa đơn đã phát hành, bảng điểm, sĩ số, trùng môn/lịch và chương trình đào tạo. Cùng một hàm backend kiểm tra điều kiện hiển thị và điều kiện ghi dữ liệu.
- Lịch học ngày/tuần/tháng, Chủ nhật, chọn ngày, chuyển khoảng thời gian; bấm buổi học để xem ngày, giờ, phòng, tín chỉ và giảng viên. Truy vấn lịch của nhà trường không nhân bản một buổi theo từng sinh viên.
- Điểm cá nhân hiển thị mọi học phần còn đăng ký, bao gồm các môn chưa công bố điểm. Điểm và nhận xét nội bộ không gửi xuống tài khoản sinh viên trước công bố. Trung bình hệ 10 tính theo tín chỉ của các môn đã có điểm công bố trong bộ lọc.
- Bổ sung nút xem chi tiết ở các bảng nghiệp vụ; hóa đơn có thông tin tổng hợp và các dòng học phần.
- Hồ sơ hiển thị rõ trường chưa được nhập; sinh viên có thể gửi yêu cầu cập nhật đến CTSV. Ảnh hồ sơ được tải lên qua API riêng tư.
- Khôi phục mục lịch thi: PĐT lập/sửa/công bố/hủy; BGH xem; sinh viên chỉ thấy lịch đã công bố của lớp còn đăng ký; giảng viên chỉ thấy lịch của lớp được phân công.

## SQL và dữ liệu thật

Ba file SQL gốc và dữ liệu sinh viên được giữ nguyên. Migration riêng [07_EXAM_SCHEDULES.sql](../data/v6/07_EXAM_SCHEDULES.sql) thêm bảng `exam_schedules`, đã áp dụng vào `sms_v6_original`. Tổng số bảng hiện là 50: 47 bảng gốc, 2 bảng bảo mật/ảnh và 1 bảng lịch thi.

Khi cài database mới, chạy migration 07 sau schema gốc và các migration bảo mật. Migration 07 dành cho database chưa từng áp dụng extension 04; nếu đã có bảng `exam_schedules` từ 04, cần bổ sung các cột `status`, `note` và kiểm tra cấu trúc trước khi sử dụng.

Seed gốc không có lịch thi. Không lấy lịch giả cố định từ frontend cũ làm lịch thi chính thức. PĐT tạo lịch trong giao diện, chọn lớp, ngày giờ, phòng, loại thi và trạng thái. API từ chối lịch có giờ kết thúc không hợp lệ hoặc trùng phòng/giảng viên/sinh viên với lịch khác.

Tài khoản `student_demo_001` có 4 đăng ký còn hiệu lực, 11 tín chỉ và 1 học phần đã công bố điểm tại thời điểm kiểm tra. Một số trường hồ sơ để NULL trong seed nên vẫn cần nhà trường bổ sung. Đăng ký HK1 đã đóng; HK2 có hóa đơn nên không cho tự đổi đăng ký. Không sửa lịch mở kỳ hoặc xóa hóa đơn để làm nút có thể bấm.

## API bổ sung

| Phương thức | Đường dẫn | Vai trò / kết quả |
|---|---|---|
| GET | `/api/student/academic` | Sinh viên: hồ sơ, lớp, các buổi, đăng ký của mình, điểm được công bố và lý do khóa thao tác |
| GET | `/api/sections/{id}/detail` | Người có quyền xem lớp: thông tin lớp, học kỳ và các buổi |
| GET | `/api/exams` | Lịch thi theo phạm vi tài khoản và trạng thái công bố |
| GET | `/api/exams/sections` | PĐT: toàn bộ lớp để lập lịch, không giới hạn 50 dòng |
| POST | `/api/exams` | PĐT: tạo lịch |
| PUT | `/api/exams/{id}` | PĐT: sửa, công bố hoặc chuyển CANCELLED |

Ví dụ dữ liệu gửi khi lập lịch (ngày minh họa, không phải seed):

```json
{
  "section_id": 1,
  "starts_at": "2027-01-10T08:00",
  "ends_at": "2027-01-10T10:00",
  "room": "A201",
  "exam_type": "Cuối kỳ",
  "status": "DRAFT",
  "note": ""
}
```

## Kiểm tra

- Backend: 24 kiểm thử thành công, gồm đăng ký–hủy–đăng ký lại, ẩn điểm/nhận xét chưa công bố, phạm vi xem lịch thi, quyền PĐT, công bố/hủy và từ chối lịch trùng.
- Frontend: build thành công, 4 kiểm thử API thành công.
- Chrome với MySQL và tài khoản sinh viên: 59 lượt kiểm tra desktop/mobile, 12 hộp chi tiết, không phát hiện lỗi JavaScript/API hiển thị.
- Chrome với H2 độc lập, sáu vai trò: 401 lượt kiểm tra giao diện, 117 hộp chi tiết, không phát hiện lỗi JavaScript/API hiển thị.
- Các kiểm tra trình duyệt trên MySQL chỉ đọc dữ liệu và mở form; không tạo lịch thi hoặc thay đổi đăng ký gốc. Các kiểm thử ghi dữ liệu chạy trong H2 và rollback.

Ảnh và báo cáo tại `screenshots/recheck-2026-11-12/student-restored/` và `six-roles/`. Kết quả kiểm tra chỉ bao phủ các tình huống đã nêu, không thay cho kiểm thử mọi tổ hợp dữ liệu thực tế.
