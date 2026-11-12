# Flyway migrations

- `core/V1__v6_normalized_schema.sql`: schema đã chuẩn hóa, 6 role/loại thi và registry checksum; không có dữ liệu người học/tài chính.
- `demo/V2__fictional_demo_only.sql`: chỉ local/CI, dữ liệu giả lập cùng các extension 05–14, đã sửa thứ tự catalog/trigger và mã SV khi nạp fresh.
- `source-manifest.json`: checksum các SQL nguồn. Không thay thế backup hoặc bằng chứng chạy migration.

Migration được chạy trong image riêng, bằng sms_migrator; backend chỉ dùng sms_app. Production chỉ tìm trong core. Không đặt demo trong core, không bật baseline-on-migrate, không sửa file đã áp dụng. Database host đang chạy sms_v6_original vẫn dùng lịch sử checksum cũ, không tự chuyển sang Flyway.

Cấu trúc baseline được xuất từ bản cài trắng, đã bỏ DEFINER của máy cá nhân và dùng SQL SECURITY INVOKER cho view. Trigger vẫn yêu cầu quyền DDL của migration user. `scripts/ci.py mysql` kiểm tra trên MySQL container riêng, gồm restore và persistence.
