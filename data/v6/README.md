# SQL V6 và các migration của ứng dụng

`01_SCHEMA_ALL.sql` và `03_QUERIES_CHECK.sql` được giữ từ ZIP. `02_SEED_DEMO.sql` đã được cập nhật tên/mã thực hành theo yêu cầu mới; xem [bộ dữ liệu thực hành](../../docs/BO_DU_LIEU_THUC_HANH.md). Không chạy lại các file này vào database đang có dữ liệu để nâng cấp.

## Database hiện có

Tại thư mục gốc dự án:

```powershell
# Tạo backup riêng tư, sao chép database, chạy migration và kiểm tra trên bản sao
python backend/scripts/Migrate-Database.py --rehearse

# Sau khi kiểm tra ứng dụng trên database bản sao, dùng đường dẫn báo cáo vừa in
python backend/scripts/Migrate-Database.py --apply backend/.local/backups/<thoi_diem>/rehearsal.json

# Kiểm tra phiên bản/checksum và toàn vẹn mà không thay đổi database
python backend/scripts/Migrate-Database.py --check
```

Script đọc kết nối từ `backend/.env.local`; không đưa mật khẩu vào tham số dòng lệnh. Lệnh apply dừng nếu dữ liệu nguồn hoặc checksum migration đã thay đổi sau lần chạy thử. Backup, báo cáo và database kiểm thử được giữ lại. DDL MySQL có implicit commit, vì vậy backup là bước bắt buộc; không giả định có thể rollback toàn bộ DDL bằng transaction.

## Cài mới đầy đủ

```powershell
powershell -ExecutionPolicy Bypass -File data/v6/Install-Original.ps1 -Database sms_v6_may_moi -WithApplicationMigrations
```

Script hỏi thông tin MySQL trên máy, dừng nếu database đã tồn tại, cài SQL gốc và lần lượt các migration 05–14. Chỉ khi các kiểm tra toàn vẹn đạt mới hoàn tất. Sau đó cấu hình `backend/.env.local` trỏ database mới và chạy `backend/Start-V6.ps1`. Tài khoản seed vẫn bị khóa; bootstrap tài khoản BGH theo tài liệu backend.

Nếu cần **chỉ bản gốc để đối chiếu**, bỏ cờ `-WithApplicationMigrations`. Bản 47 bảng gốc riêng lẻ không đủ cho các chức năng bảo mật, ảnh và lịch thi đã bổ sung trong ứng dụng hiện tại.

## Thứ tự và nội dung

| File | Nội dung |
|---|---|
| 01–03 | Schema, seed và view/kiểm tra gốc |
| 04_FEATURE_EXTENSIONS.sql | Tham khảo cũ; không chạy trong chuỗi cài hiện tại |
| 05_SECURITY_PROFILE.sql | Ảnh hồ sơ riêng tư, token khôi phục mật khẩu |
| 06_COMPLETE_SEED_LINKS.sql | Liên kết bảng điểm và địa chỉ email dự kiến còn thiếu |
| 07_EXAM_SCHEDULES.sql | Bảng lịch thi |
| 08_NORMALIZE_ACADEMIC.sql | Danh mục phòng/loại thi, FK, CHECK, đồng bộ cột tương thích |
| 09_COMPLETE_DEMO_DATA.sql | Bổ sung trường hồ sơ demo, điểm demo còn thiếu, lịch thi demo có nhãn |
| 10_VERIFY_NORMALIZED.sql | View kiểm tra toàn vẹn sau migration |
| 11_MAILBOX_EMAIL_DELIVERY.sql | Thông báo cấp email trường qua email cá nhân, có hàng đợi |
| 12_PRACTICAL_IDENTITIES.sql | Tên, mã và thông tin thực hành nhất quán, không thay tiền/chứng từ |

`schema_migrations` lưu checksum từng migration. Khi một file đã được áp dụng, bổ sung thay đổi bằng **migration mới**, không sửa nội dung file cũ rồi chạy chồng.

Schema đầy đủ có 56 bảng. Dữ liệu mẫu không phải thông tin thực của sinh viên; lịch thi mẫu được đánh dấu `data_origin=DEMO` và có cảnh báo trên giao diện. Hộp thư RESERVED không được tự chuyển thành ACTIVE. File ảnh/tài liệu thật vẫn phải tải lên private storage, không có trong seed SQL.

Xem [báo cáo chuẩn hóa và cách kiểm tra](../../docs/CHUAN_HOA_SQL_2026_11_12.md).


Luồng trình duyệt mới: [hướng dẫn xét duyệt và tài khoản](../../docs/LUONG_XET_DUYET_VA_TAI_KHOAN.md).

| Migration bổ sung | Nội dung |
|---|---|
| 13_INVOICE_REVIEW_WORKFLOW.sql | Đề nghị học phí, chi tiết và lịch sử BGH duyệt |
| 14_REVIEW_PRACTICE_DATA.sql | Dữ liệu chờ duyệt và kiểm tra toàn vẹn luồng |
