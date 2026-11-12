# KIEM TRA TINH (QA) — SMS V6

- Bang: **47** bang, deu co PRIMARY KEY.
- Quan he: **78** FOREIGN KEY, ten rang buoc khong trung va bang duoc tham chieu deu ton tai.
- Nhung bang moi: `tuition_adjustments`, `ctsv_semester_report_reviews`, `email_delivery_attempts`, `ctsv_remittance_allocations`.
- Seed: **190 lenh INSERT** tren 43 bang; tat ca ten bang co dinh nghia trong schema.
- Chay lai seed: `INSERT ... WHERE NOT EXISTS` va UNIQUE key; khong phat sinh tai khoan admin rieng.
- Demo ho so chung: `APP-DEMO-V6-004` co su kien CTSV duyet, chuyen BGH, BGH duyet (join theo `application_id`).
- View/query: **16 VIEW** khong trung ten, co cong no hoc ky va toan truong, CTSV, quy, lich hoc, nhap diem, email.
- Kiem tra chinh: can bang ngoac/nhay don, ten bang INSERT, ten FK.

**Gioi han:** Chi moi la kiem tra tinh. Moi truong tao file khong co MySQL Server 8 de test DDL/DML that. Chua test giao dich dong thoi/quyen truy cap Backend. Phai BACKUP va chay thu tren ban sao MySQL truoc khi dung database co du lieu that.
