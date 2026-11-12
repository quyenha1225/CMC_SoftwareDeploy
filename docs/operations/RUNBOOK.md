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

Chuẩn bị `/opt/sms/staging` và `/opt/sms/production`, deploy user, Docker/Compose/Python, DNS, firewall chỉ mở 80/443/SSH đã giới hạn, token registry read-only trên VPS. Cài cấu hình/secrets trên host; không truyền secrets qua bundle build. DB root không dùng bởi backend.

Dùng `compose.prod.yaml` độc lập; đặt image `BACKEND_IMAGE`, `FRONTEND_IMAGE`, `MIGRATION_IMAGE` đúng `registry/repository@sha256:...`. Đặt SMS_SEED_DEMO=false, SMS_ENVIRONMENT=production, SESSION_SECURE=true, APP_DOMAIN và SMS_PUBLIC_URL=https://domain. Core migration không có dữ liệu demo. Không copy `.env` local chứa cấu hình demo sang production.

Lần đầu: dựng DB, chạy migration core, bootstrap BGH bằng secret qua một lần chạy backend có SMS_BOOTSTRAP_ENABLED=true; sau đó tắt cờ trước khi chạy lâu dài. Runner bootstrap không ghi đè tài khoản đã có. Chạy `compose.prod.yaml` kết hợp `compose.tls.yaml` để Caddy cấp TLS sau khi DNS/port hợp lệ. Xác minh login/role với tài khoản production do trường quản lý, không dùng DemoProvisioner.

Triển khai sau khi đã khởi tạo: `scripts/deploy.py apply --manifest <release.json> --allow-migration`. Script yêu cầu backup + restore-test, pull digest, migrate, up --no-build, smoke và lưu receipt trong `.local/releases/`. Jenkins dùng `remote`, scp bundle không chứa secrets qua SSH với host key đã xác minh. `--allow-migration` xác nhận kế hoạch đã được review; không thay thế review bằng suy đoán tương thích schema.

## Rollback

```sh
python3 scripts/deploy.py rollback --manifest .local/releases/<release-cu>.json
```

Receipt phải có schema_version khớp DB hiện tại, gồm phiên bản và chữ ký DDL/lịch sử migration (kể cả bản ghi thất bại). Nếu health fail và schema không đổi, apply khôi phục các digest trước. Nếu schema thay đổi, dừng để review expand/contract hoặc phục hồi có kiểm soát; không tự DROP, down -v hay ghi đè DB. Rollback image không đồng nghĩa rollback dữ liệu.

## Backup và restore sự cố

Backup hằng ngày và trước release, lưu SQL + private archive + manifest/checksum; mã hóa và sao chép offsite theo chính sách của trường. Lệnh mẫu lịch cron trên VPS: `0 2 * * * cd /opt/sms/production && python3 scripts/docker.py --production backup` (thêm lịch restore-test định kỳ). Cần giám sát lỗi job, dung lượng, retention theo chính sách; script không tự xóa backup.

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
