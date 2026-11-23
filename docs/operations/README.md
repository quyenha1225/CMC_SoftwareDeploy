# Docker local và CI/CD SMS

Đối chiếu `SMS_Dac_Ta_Yeu_Cau_Van_Hanh_He_Thong_Docker_Jenkins_CICD.docx`, bản V1.0 ngày 12/11/2026. Tài liệu là yêu cầu mục tiêu; trạng thái kiểm thử thực tế nằm trong [nghiệm thu](ACCEPTANCE.md).

## Chạy trên Windows

Yêu cầu Docker Desktop **Linux containers**, Python 3, Internet cho lần tải image đầu tiên. Website cũ :5173/MySQL trên máy không bị thay thế. Jenkins Windows giữ :8080.

```powershell
# Từ thư mục gốc. init chỉ chạy lần đầu, từ chối ghi đè .env/secrets đã có.
python scripts/docker.py init
python scripts/docker.py config
python scripts/docker.py up
python scripts/docker.py status
python scripts/docker.py smoke
```

Website container: **http://localhost:8088**. Script `up` build 3 image (frontend, backend, migration), đợi MySQL/Flyway/backend healthy, kích hoạt 15 tài khoản **chỉ trong database demo Docker**, rồi kiểm tra đăng nhập. Khi đã init, chạy lại từ `config`/`up`; không chạy lại `init`.

Mật khẩu Docker là mật khẩu riêng, khác bản chạy trực tiếp trên máy. Danh sách nằm trong `backend/.local/docker-credentials.md`, không commit hoặc đưa vào ảnh/image. Root `.env` chỉ chứa cấu hình Docker không bí mật; `.secrets/` chứa các secret được mount vào `/run/secrets/`. `backend/.env.local` tiếp tục phục vụ chế độ chạy Java trực tiếp, không COPY vào container.

Trên Linux, `.secrets/` phải thuộc deploy user và có quyền 0700. Secret file có thể đọc trong container qua bind-mount; thư mục cha ngăn user khác trên host truy cập. Compose file secrets không phải secret store được mã hóa như Swarm/Vault; cần bảo vệ và sao lưu host.

## Kiểm tra lưu dữ liệu và phục hồi

```powershell
python scripts/docker.py restart-test
python scripts/docker.py backup
python scripts/docker.py restore-test --backup-dir backups/sms_local/<thoi-diem>
```

Backup gồm database, tệp private, checksum và số dòng từng bảng. Restore-test dùng container MySQL riêng, không có network/port public, kiểm tra số dòng, 16 điều kiện toàn vẹn và khả năng đọc archive. Không ghi đè database đang chạy. File backup chứa dữ liệu nhạy cảm, nằm ngoài Git; production cần mã hóa backup/offsite và chính sách lưu trữ.

Dừng ứng dụng bằng `docker --context desktop-linux compose stop`. Không dùng `down -v` cho local/staging/production đang lưu dữ liệu. Chỉ CI tự xóa volume trong namespace `sms_ci_*` do chính lần kiểm thử tạo ra.

## Giám sát

```powershell
docker --context desktop-linux compose --env-file .env -f compose.yaml -f compose.monitoring.yaml --profile monitoring up -d --build
```

Prometheus http://localhost:9090; Grafana http://localhost:3000. Chỉ bind loopback. Grafana username `admin`, mật khẩu ở `.secrets/grafana_password`. Dashboard **SMS operations** tự provision: availability, request rate, p95, 5xx, JVM, CPU, DB pool, 401/403. Rule cảnh báo có sẵn; chưa gửi ra email/chat khi chưa cấu hình receiver.

Backend management :9092 và MySQL :3306 không publish ra host. Nginx chỉ cho health tổng qua `/api/actuator/health`; chặn các đường management khác. `/api/hello` vẫn yêu cầu đăng nhập, không được nới quyền để làm smoke.

### Thông báo Discord

- **Kênh giám sát hệ thống** dùng webhook riêng trong `.secrets/discord_webhook_url` hoặc file cùng tên trong `SMS_SECRETS_DIR`. Backend gửi trạng thái sẵn sàng và lỗi 5xx. Alertmanager gửi mức độ, tên cảnh báo, thành phần, tóm tắt lỗi và trạng thái phục hồi. Lệnh `python scripts/docker.py init` tạo file rỗng cho môi trường mới. Với môi trường cũ chưa có file, chạy `python scripts/docker.py config` trước khi chạy Compose trực tiếp. File rỗng tắt Discord. Nếu chạy backend ngoài Docker, đặt biến môi trường `DISCORD_WEBHOOK_URL`.
- **Kênh CI/CD** dùng webhook riêng của `#jenkins`, lưu trong Jenkins với ID `sms-discord-webhook`. Dùng **Secret text** với URL, hoặc **Secret file** với file `jenkins_discord_webhook_url`. Khi một stage lỗi, thông báo ghi tên stage, bước kiểm tra nếu có, branch, commit và link console. Cuối pipeline gửi tổng kết CI/CD.
- **Backend** thông báo khi sẵn sàng và khi có lỗi HTTP 5xx, kèm mẫu route. **Alertmanager** gửi cảnh báo và tin phục hồi theo các rule Prometheus, gồm backend, frontend, tỷ lệ 5xx, độ trễ, dung lượng đĩa và volume. Nếu đã cấu hình Telegram, Alertmanager gửi qua cả hai kênh.
- Trên staging hoặc production, dùng `-f compose.prod.yaml -f compose.monitoring.yaml --profile monitoring` với các image digest của bản phát hành. Sau khi cập nhật webhook, tạo lại container backend và Alertmanager để cả hai đọc cấu hình mới.

CD local cập nhật stack giám sát sau smoke test của ứng dụng. Prometheus thu metrics, Grafana hiển thị dashboard **SMS infrastructure**, Alertmanager gửi cảnh báo lỗi và phục hồi tới `#giám-sát-hệ-thống`. Kênh `#jenkins` nhận trạng thái và lỗi của CI/CD từ Jenkins.

#### Bản tin trạng thái Discord

Chạy từ thư mục gốc để xem trạng thái ngay hoặc gửi bản tin vào kênh giám sát.

```powershell
python scripts/monitoring_status.py
python scripts/monitoring_status.py --discord
```

Trên Windows, đặt lịch mỗi giờ trong Task Scheduler. Lệnh dưới đây tạo tác vụ chạy theo tài khoản đang đăng nhập, bắt đầu sau một giờ.

```powershell
$smsPython = (Get-Command python -CommandType Application | Select-Object -First 1).Source
$smsScript = (Resolve-Path scripts/monitoring_status.py).Path
$smsAction = New-ScheduledTaskAction -Execute $smsPython -Argument ('"{0}" --discord' -f $smsScript)
$smsTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddHours(1) -RepetitionInterval (New-TimeSpan -Hours 1)
Register-ScheduledTask -TaskName 'SMS Monitoring Discord Status' -Action $smsAction -Trigger $smsTrigger
```

Bản tin dùng số liệu tức thời từ Prometheus và liệt kê các cảnh báo đang phát. MySQL được kiểm tra qua kết nối TCP. Khi Prometheus không phản hồi, bản tin báo chưa xác định trạng thái. Máy chạy tác vụ cần hoạt động và tài khoản thực thi cần đọc được webhook.

| Thành phần | Theo dõi |
|---|---|
| Frontend | HTTP `/healthz` và độ trễ probe |
| Backend | Scrape metrics, HTTP readiness, tỷ lệ HTTP 5xx và p95 GET |
| MySQL | Kết nối TCP nội bộ, readiness của backend và dung lượng volume. Smoke test CD kiểm tra thêm SQL |
| Máy chạy Docker | CPU, RAM khả dụng, dung lượng đĩa, số liệu volume. Grafana hiển thị CPU/RAM từng container |
| Hệ thống giám sát | Scrape Prometheus, Alertmanager, Grafana, Node Exporter và cAdvisor, probe Blackbox bị mất, lỗi gửi thông báo Alertmanager |

Chạy `python scripts/ci.py monitoring-config` để kiểm tra cấu hình Prometheus và tình huống alert phát sinh/phục hồi. Sau deploy, mở Prometheus **Status → Targets** để xem trạng thái từng nguồn. Nếu Prometheus, Alertmanager, Docker host hoặc đường gửi Discord đều mất, cần một dịch vụ giám sát bên ngoài stack để phát cảnh báo về sự cố đó.

Nếu Prometheus đang chạy khi cập nhật rule, dùng cùng các tùy chọn Compose ở trên với lệnh `restart prometheus` để nạp lại cấu hình.

## Tài liệu liên quan

- [Kiến trúc và ERD](ARCHITECTURE.md)
- [Cấu hình Jenkins/GitHub/Registry](JENKINS.md)
- [Runbook triển khai và xử lý sự cố](RUNBOOK.md)
- [Nghiệm thu và đối chiếu yêu cầu](ACCEPTANCE.md)
- [Danh mục API](API.md)

Nguồn kỹ thuật: [Docker Compose services](https://docs.docker.com/reference/compose-file/services/), [Flyway Docker](https://documentation.red-gate.com/flyway/reference/usage/flyway-docker), [Jenkins Pipeline](https://www.jenkins.io/doc/book/pipeline/), [Spring Boot metrics](https://docs.spring.io/spring-boot/reference/actuator/metrics.html).
