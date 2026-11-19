# Đối chiếu đặc tả và nghiệm thu

Nguồn yêu cầu: `SMS_Dac_Ta_Yeu_Cau_Van_Hanh_He_Thong_Docker_Jenkins_CICD.docx`, V1.0 ngày 12/11/2026. Phạm vi được chủ dự án chốt: **Docker local và cấu hình CI/CD trước; chưa có VPS/domain/Registry**.

## Phần bổ sung vào repository

| Yêu cầu | Thành phần thực hiện | Trạng thái |
|---|---|---|
| Docker FE/BE/MySQL, không IIS | Dockerfiles, Nginx, compose.yaml, named volume/network/healthcheck; hướng dẫn inspect volume và tạo volume demo | Chạy local :8088 |
| MySQL 8, migration version | Runner Java/Flyway chỉ MySQL, db/migration/core và demo | Kiểm tra cài trắng; core production không có sinh viên/khoản thu |
| Không nhúng secret | .dockerignore, .secrets/configtree, init riêng; 15 mật khẩu demo riêng | Kiểm tra Git ignore và secret scan |
| Tests/lint/coverage | JUnit/H2, Vitest/RTL, ESLint, JaCoCo, Python tests | Có cấu hình; trạng thái xác minh workstation hiện tại bên dưới |
| MySQL integration/E2E | scripts/ci.py mysql + mysql_workflows.py | Luồng thật trên namespace CI cô lập |
| Build/push bằng SHA/digest | Jenkinsfile, ci.py, registry_login.py | Có cấu hình và kiểm tra gate; chưa push Registry thật |
| Webhook/Jenkins | Jenkinsfile + hướng dẫn plugins/credentials/branch protection | Chưa có job/build link/webhook delivery thực |
| SonarQube Quality Gate | Jenkins stage bắt buộc trước publish, scanner/coverage config | Chưa chạy server/token Sonar thật |
| Deploy/approval/rollback | compose.prod/tls, deploy.py, known_hosts và approver | Cấu hình + tests chống tag mutable/schema lệch; chưa deploy VPS thật |
| Backup/restore | SQL + private archive + checksum + container phục hồi cô lập | Đã kiểm tra SQL và tệp fixture phục hồi đúng hash |
| Monitoring | Prometheus/Grafana dashboard và alert rules; cAdvisor raw cgroup CPU/bộ nhớ theo Docker ID; Docker Desktop/`docker stats` theo dõi chi tiết từng container | Chạy local; chưa cấu hình receiver gửi cảnh báo ra ngoài; mạng Grafana hiển thị theo interface Docker VM |
| Docs/ERD/API/runbook | Thư mục docs/operations | Đã bổ sung |

## Luồng nghiệp vụ FR-01 đến FR-11

| Mã | Bằng chứng / giới hạn |
|---|---|
| FR-01 | Một admission_application; CTSV/BGH/PĐT dùng cùng ID; API/security tests |
| FR-02 | Identity/học bạ/checklist/private file, MIME/kích thước/sở hữu; fixture ảnh upload và chống xem chéo. Metadata seed chưa thay thế được giấy tờ thật |
| FR-03 | BGH bị chặn cấp MSSV; PĐT xác minh/enroll sau phê duyệt trên MySQL thật |
| FR-04 | State mailbox và outbox/retry đã có; Google Workspace/SMTP/provisioning thật cần cấu hình ngoài, không đánh dấu đã gửi email thật |
| FR-05 | Giữ row lock và READ_COMMITTED để kiểm tra sĩ số mới sau khi chờ; có bài race ghế cuối trên MySQL |
| FR-06 | Đăng ký/hủy làm lịch học xuất hiện/biến mất từ enrollment |
| FR-07 | PĐT kiểm tra/trình → BGH duyệt → PĐT công bố; sinh viên chỉ thấy PUBLISHED |
| FR-08 | Đề nghị được BGH duyệt → CTSV phát hành snapshot; không tự phát hành khi BGH duyệt |
| FR-09 | View công nợ thống nhất, giữ nguyên chứng từ/tiền của database host |
| FR-10 | Race cùng reference chỉ một khoản thu; race khác reference không vượt nợ; phân bổ theo chứng từ/quỹ |
| FR-11 | CTSV không tự xác nhận bàn giao; BGH quyết định, có sự kiện/lịch sử |

## Kết quả xác minh hiện tại

Ngày 19/11/2026, kiểm tra trực tiếp trên Docker Desktop local:

- `python -B scripts/verify_runtime.py --monitoring`: PASS 7 nhóm; báo cáo hiện tại nằm tại `artifacts/reports/runtime-verification.json`.
- Prometheus backend và cAdvisor targets ở trạng thái `up`; cAdvisor có raw cgroup series theo Docker ID; Grafana health `ok`; dashboard `sms-operations` được nạp; có 3 alert rules.
- Bốn named volume Compose hiện diện: MySQL, private files, Prometheus và Grafana. `docker stats --no-stream` trả số liệu CPU/bộ nhớ cho các container đang chạy.
- `python -B -m unittest discover -s scripts/tests -v`: 10/10 bài vận hành đạt.
- Backend `mvn verify` chưa chạy xong vì Maven Central không phân giải được để tải dependency/plugin JaCoCo. Frontend lint/test/build chưa chạy được vì dependencies chưa cài (`eslint` không có trong `node_modules`). Đây là giới hạn kết nối/cài đặt của workstation, chưa phải kết luận source fail.

Các báo cáo chi tiết lịch sử từng được nhắc như `operations-summary.json`, browser/MySQL integration và Trivy không có trong `artifacts/reports` hiện tại; không dùng các số liệu đó làm minh chứng nghiệm thu của lần này. Khi có mạng/dependencies hoặc Jenkins agent, chạy lại các gate backend/frontend, MySQL integration và security scan rồi lưu artifacts tương ứng.

ESLint hiện 0 lỗi nhưng còn cảnh báo unused code của các màn cũ; không đồng nghĩa toàn bộ code không có cảnh báo. Flyway/MySQL có cảnh báo display width/phiên bản; các migration được thử trực tiếp trên MySQL 8.4 trong CI, không giả định H2 đại diện đầy đủ MySQL.

## Lỗi đã tìm thấy và sửa trong đợt này

- Image Nginx khóa gói cũ: bỏ các module không dùng, gỡ pin/cài bản vá; không dùng ignore CVE để qua gate.
- Image Flyway đầy đủ mang thư viện cloud/.NET có Critical: thay bằng runner Java MySQL tối thiểu, giữ gate.
- MySQL REPEATABLE READ có thể giữ snapshot từ lúc đọc actor trước khi chờ khóa. Dùng READ_COMMITTED cùng row locks ở Academic/Finance/InvoiceProposals để phép đếm/số dư sau lock thấy commit trước đó. Cần bài MySQL race thực, không chỉ H2. Nguồn: [MySQL consistent reads](https://dev.mysql.com/doc/refman/8.4/en/innodb-consistent-read.html).
- Header Nginx bị mất khi location thêm cache header: chuyển cache policy lên map/server để giữ CSP/nosniff trên index.
- Init script Linux/Windows, quyền trigger và chờ MySQL restore: đã sửa và kiểm tra fresh install/restore.

## Phần chưa được xem là nghiệm thu production

Chưa có bằng chứng webhook 2xx, Jenkins build URL, Sonar gate thật, Registry push/digest công khai, VPS HTTPS hoặc rollback VPS. Không gán đạt AC-06/AC-09/CI-01 chỉ vì đã có file cấu hình. Backup/monitoring local đã chạy; phần rollback và nhận cảnh báo thật còn cần môi trường vận hành.

Dữ liệu thực hành vẫn có các thiếu hụt đã công bố: 3 khoản thu legacy chưa gắn quỹ, 10 metadata giấy tờ chưa có file, 6 sinh viên chưa tải ảnh. Không tự điền quỹ/chứng từ hay tạo giấy tờ thật giả. Xem [validate dữ liệu](../VALIDATE_TOAN_BO_DU_LIEU.md).
