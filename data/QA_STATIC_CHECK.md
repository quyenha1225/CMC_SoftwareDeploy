# Kiểm tra kỹ thuật (thực hiện khi tạo bộ SQL)

- **PASS:** Có đúng 28 lệnh `CREATE TABLE IF NOT EXISTS` cho 28 thực thể trong bản ERD trước đó.
- **PASS:** Có 3 `CREATE OR REPLACE VIEW` đọc dữ liệu tính toán.
- **PASS:** Không có khóa ngoại tham chiếu đến bảng không tồn tại trong bộ schema.
- **PASS:** Seed có **158 lệnh INSERT** trên đủ 28 bảng, mỗi lệnh có `WHERE NOT EXISTS` trên khóa nghiệp vụ tương ứng.
- **PASS:** Số cột INSERT và số biểu thức SELECT khớp cho cả 158 lệnh; dấu ngoặc và dấu nháy trong biểu thức được kiểm tra tĩnh.
- **PASS:** Danh sách đếm dữ liệu mẫu khớp với số INSERT dự kiến.
- **PASS:** Không có `DROP TABLE`, `DROP DATABASE`, `TRUNCATE`, `DELETE` trong schema/seed.
- **PASS:** Có các UNIQUE khóa nghiệp vụ chống trùng cho điểm, học phần, hóa đơn, thanh toán và sự kiện seed.

**Chưa kiểm thử:** Chưa thực thi trên MySQL Server thực tế trong môi trường tạo tài liệu. Chạy trên MySQL 8.0.16+ bằng `00_preflight` → `01_schema` → `02_seed` → `03_validate`, sau đó chạy lại seed và kiểm tra số lượng bản ghi giữ nguyên. Nếu `00_preflight` phát hiện schema cũ cần migration, không chạy chồng lên trước khi sao lưu và đánh giá khác biệt.
