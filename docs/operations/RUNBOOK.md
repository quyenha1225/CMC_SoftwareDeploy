# Runbook SMS

## Bảng cổng và trạng thái

| Dịch vụ | Local | Production |
|---|---|---|
| Website | localhost:8088 | HTTPS :443 qua Caddy |
| Backend | Nội bộ :8081 | Nội bộ :8081 |
| Management | Nội bộ :9092 | Nội bộ :9092 |
| MySQL | Nội bộ :3306 | Nội bộ :3306 |
| Jenkins hiện có | :8080 | Host CI riêng / HTTPS ingress |
| Grafana/Prometheus | Loopback :3000/:9090 | VPN/SSH tunnel |

## Staging/production khi có VPS

### Job Jenkins triển khai qua SSH

Tạo một job **Pipeline** tên chính xác `SMS-CICD-Server`. Chọn **Pipeline script from SCM**, dùng cùng repo và đường dẫn `Jenkinsfile`, chọn nhánh `develop` (hoặc nhánh cấu hình bằng `SMS_SERVER_BRANCH` trên agent). Job local hiện tại vẫn dùng stage Docker local. Job server theo dõi Git, chạy cùng các bước CI và chỉ publish/deploy khi SonarQube Quality Gate, kiểm thử và quét bảo mật đều qua.

| Cấu hình trên agent Jenkins | Giá trị |
|---|---|
| `DEPLOY_TARGET` | `production` (mặc định) hoặc `staging` |
| `PRODUCTION_HOST` hoặc `STAGING_HOST` | Host SSH tương ứng |
| `REGISTRY_NAMESPACE` | Namespace registry, ví dụ `ghcr.io/your-org` |
| `SMS_SERVER_PUBLIC_URL` | URL HTTPS bên ngoài, ví dụ `https://sms.example.org` |
| `SMS_SERVER_BRANCH` | Nhánh tự động deploy, mặc định `develop` |
| Credential `sms-server-ssh` | SSH Username with private key dùng được trong chế độ BatchMode |
| Credential `sms-server-known-hosts` | Secret file chứa host key SSH đã xác minh |

Agent cần `ssh`, `scp`, Docker Linux và quyền push vào registry bằng tài khoản chạy job. Server cần quyền pull nếu registry riêng tư. SSH dùng port 22 mặc định. Gán label `sms-docker` cho agent và chuẩn bị riêng máy chủ cho mỗi đích dùng cổng 80/443. Khi thành công console có `DEPLOY_OK` và `PUBLIC_SMOKE_OK`, và tin Jenkins ghi URL public. Smoke public kiểm tra trang HTML và readiness của backend từ Jenkins qua HTTPS.

### Chuẩn bị máy chủ một lần

Chuẩn bị `/opt/sms/staging` và `/opt/sms/production`, deploy user, Docker/Compose/Python, DNS, firewall chỉ mở 80/443/SSH đã giới hạn, token registry read-only trên VPS. Cài cấu hình/secrets trên host; không truyền secrets qua bundle build. DB root không dùng bởi backend.

Dùng `compose.prod.yaml` với `compose.tls.yaml`. Ví dụ `.env` trên server mới:

```dotenv
COMPOSE_PROJECT_NAME=sms_production
SMS_ENVIRONMENT=production
SMS_SEED_DEMO=false
SESSION_SECURE=true
APP_DOMAIN=sms.example.org
SMS_PUBLIC_URL=https://sms.example.org
APP_BIND=127.0.0.1
SMS_SECRETS_DIR=./.secrets
```

Giá trị `SMS_PUBLIC_URL` trên server phải khớp `SMS_SERVER_PUBLIC_URL` của job. Core migration tạo schema dành cho dữ liệu thật.

Với server mới và database trống, bỏ ba biến image khỏi `.env` để job điền từ release manifest. Chuẩn bị các file `mysql_root_password`, `db_password`, `migrator_password`, `jwt_secret`, `identity_key`, `bootstrap_password`, `smtp_password`, `discord_webhook_url` và `grafana_password` dưới `.secrets/` của server. Dùng các giá trị riêng cho server. `identity_key` là 32 byte ngẫu nhiên mã hóa Base64. Lần deploy đầu khởi tạo DB sạch và áp dụng core migration. Có thể bật `SMS_BOOTSTRAP_ENABLED=true` để tạo tài khoản BGH bằng secret trong lần đầu, rồi đổi lại `false` trước khi chạy lâu dài. Caddy cấp TLS sau khi DNS và các cổng đã trỏ đúng. Xác minh login/role bằng tài khoản production.

Triển khai sau khi đã khởi tạo: `scripts/deploy.py apply --manifest <release.json> --allow-migration`. Script yêu cầu backup + restore-test, pull digest, migrate, up --no-build, smoke và lưu receipt trong `.local/releases/`. Jenkins dùng `remote`, scp bundle không chứa secrets qua SSH với host key đã xác minh. `--allow-migration` xác nhận kế hoạch đã được review; không thay thế review bằng suy đoán tương thích schema.

## Rollback

```sh
python3 scripts/deploy.py rollback --manifest .local/releases/<release-cu>.json
```

Receipt phải có schema_version khớp DB hiện tại, gồm phiên bản và chữ ký DDL/lịch sử migration (kể cả bản ghi thất bại). Nếu health fail và schema không đổi, apply khôi phục các digest trước. Nếu schema thay đổi, dừng để review expand/contract hoặc phục hồi có kiểm soát; không tự DROP, down -v hay ghi đè DB. Rollback image không đồng nghĩa rollback dữ liệu.

## Backup và restore sự cố

Backup hằng ngày và trước release, lưu SQL + private archive + manifest/checksum; mã hóa và sao chép offsite theo chính sách của trường. Lệnh mẫu lịch cron trên VPS: `0 2 * * * cd /opt/sms/production && python3 scripts/docker.py --production backup` (thêm lịch restore-test định kỳ). Cần giám sát lỗi job, dung lượng, retention theo chính sách; script không tự xóa backup.

Restore-test chờ MySQL cô lập sẵn sàng tối đa **240 giây** theo mặc định. Có thể đặt `SMS_RESTORE_STARTUP_TIMEOUT_SECONDS` trong `.env` của môi trường hoặc biến môi trường của tiến trình restore-test khi máy cần thêm thời gian (1–900 giây). Từng probe tối đa 15 giây và dùng phần ngân sách còn lại khi gần hết hạn. Hết hạn sẽ chặn deploy, ghi trạng thái container, CPU/RAM/I/O và tóm tắt log MySQL, rồi dọn container thử nghiệm. Chẩn đoán tối đa 5 giây mỗi lệnh, bên ngoài ngân sách readiness.

Restore thật chỉ sau khi kiểm tra checksum, thử restore cô lập, xác nhận thời điểm mất dữ liệu có thể chấp nhận và dừng các tác vụ ghi. Không tự khôi phục backup lên DB đang phục vụ người dùng. Cần khôi phục đồng bộ SQL và private-files.

## Xử lý lỗi

| Hiện tượng | Kiểm tra / xử lý |
|---|---|
| Docker pipe không tồn tại | Mở Docker Desktop; dùng Linux containers, kiểm tra context desktop-linux |
| Port 8080 bị chiếm | Giữ Jenkins; web dùng 8088 |
| 502 | Compose ps/log backend, DB readiness, upstream backend:8081 |
| DB unhealthy | Logs db, secret file/quyền đọc, không sửa mật khẩu bằng cách chỉ đổi .env sau init |
| Flyway fail | Dừng deploy; xem version/checksum, backup; MySQL DDL không rollback toàn bộ |
| Trigger thiếu quyền | Migrator có DDL trong DB; log_bin_trust_function_creators đã cấu hình; không nâng runtime thành root |
| Script Linux lỗi CRLF | .gitattributes quy định LF; không lưu .sh thành CRLF |
| Backend 401/403 | Cookie/session/CSRF và vai trò; không bỏ kiểm tra quyền để sửa giao diện |
| Gmail chưa gửi | Chỉ bật sau khi có app password/Workspace, email trường ACTIVE thật |
| Quỹ/tệp/ảnh còn thiếu | Xem báo cáo validate; không suy đoán quỹ, không tạo giấy tờ thật giả |
| p95/5xx tăng | Dashboard, logs, pool DB, release SHA; cảnh báo chưa gửi ngoài khi chưa cấu hình receiver |

Jenkins home/plugin/credentials cần backup theo hướng dẫn Jenkins, tách khỏi backup nghiệp vụ. Dashboard/provisioning được version trong Git. Không lưu PII/token/password trong log hoặc minh chứng công khai.
