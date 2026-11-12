# EduPortal — Hướng dẫn chạy hệ thống SMS

Ứng dụng quản lý sinh viên sử dụng React/Vite, Spring Boot/Java 21 và MySQL. Có hai cách chạy độc lập: **Docker local** để dùng toàn hệ thống, hoặc **chạy backend/frontend trực tiếp** để phát triển. Jenkins điều phối kiểm thử và phát hành; không bắt buộc để mở website local.

## 1. Chuẩn bị trên Windows

- Docker Desktop đang chạy, chọn **Linux containers**, có Docker Compose.
- Python 3.10+ và Git; terminal gọi được `python`.
- Internet để tải image và dependency lần đầu.
- Nếu chạy trực tiếp hoặc chạy CI: Java 21, Node.js 22.12+ và Google Chrome. Script `backend/Start-V6.ps1` còn yêu cầu `mvn.cmd` trên PATH; kiểm thử CI dùng Maven Wrapper.

Mở PowerShell tại thư mục gốc repository, nơi có `compose.yaml` và `Jenkinsfile`:

```powershell
python --version
docker version
docker compose version
```

Các lệnh bên dưới mặc định thực hiện tại thư mục gốc, trừ khi có hướng dẫn khác.

## 2. Chạy toàn hệ thống bằng Docker — cách khuyến nghị

### Lần đầu trên máy mới

```powershell
python scripts/docker.py init
python scripts/docker.py config
python scripts/docker.py up
python scripts/docker.py status
python scripts/docker.py smoke
```

`init` sinh `.env`, thư mục `.secrets/` và tài khoản thực hành. Script từ chối ghi đè cấu hình đã có. **Nếu máy đã có `.env` và `.secrets/`, bỏ qua `init`**, bắt đầu từ `config` và `up`; không xóa chúng để chạy lại.

`up` build frontend/backend/migration, khởi động MySQL, chạy Flyway và kích hoạt tài khoản trong database thực hành Docker. Không cần tự nhập `01_SCHEMA_ALL.sql` vào database container. Không chạy chồng bộ SQL cũ lên database đã được Flyway quản lý.

### Địa chỉ và đăng nhập

| Thành phần | Địa chỉ / nơi xem |
|---|---|
| Website Docker | http://localhost:8088 |
| Health backend qua Nginx | http://localhost:8088/api/actuator/health |
| Tài khoản, mật khẩu Docker | `backend/.local/docker-credentials.md` trên máy sau `init` |
| MySQL/backend nội bộ | Không công bố cổng MySQL/backend ra host |

Tài khoản Docker khác tài khoản của database chạy trực tiếp trên Windows. Có các vai trò BGH, PĐT, CTSV, giảng viên, sinh viên và ứng viên. Không chép mật khẩu vào README, Git hoặc ảnh báo cáo.

### Những lần chạy tiếp theo

```powershell
python scripts/docker.py up
python scripts/docker.py status
python scripts/docker.py smoke
```

Trong **Docker Desktop → Containers → sms_local**, mở từng container để xem Logs, Inspect, Stats hoặc Exec. `migrate` kết thúc với **exit code 0** là bình thường; đó là tác vụ migration chạy một lần.

Xem log nhanh:

```powershell
python scripts/docker.py logs
```

Dừng hoặc chạy lại container đã có, không xóa dữ liệu:

```powershell
docker --context desktop-linux compose --env-file .env -f compose.yaml stop
docker --context desktop-linux compose --env-file .env -f compose.yaml start
```

Các lệnh Docker trực tiếp trong tài liệu dùng context `desktop-linux` của Docker Desktop. Nếu máy dùng context khác, xem `docker context ls` và thay tên tương ứng. Script Python trên Windows mặc định dùng Linux engine của Docker Desktop.

## 3. Bật giám sát Prometheus/Grafana

Sau khi hệ thống Docker chạy được:

```powershell
docker --context desktop-linux compose --env-file .env -f compose.yaml --profile monitoring up -d prometheus grafana
python scripts/verify_runtime.py --monitoring
```

- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000; username `admin`, mật khẩu trong `.secrets/grafana_password`.
- Dashboard **SMS operations** theo dõi tình trạng backend, request, thời gian phản hồi, lỗi, JVM và kết nối database.

Giám sát local không đồng nghĩa đã gửi cảnh báo email/chat. Receiver cần được cấu hình riêng. Grafana và Prometheus cũng không thay thế SonarQube.

## 4. Sao lưu, kiểm tra phục hồi và cập nhật

Trước khi cập nhật bản đang dùng:

```powershell
python scripts/docker.py backup
```

Lệnh in ra đường dẫn backup. Dùng đúng đường dẫn đó để thử khôi phục trong container tách biệt, ví dụ:

```powershell
python scripts/docker.py restore-test --backup-dir backups/sms_local/THOI_DIEM_BACKUP
```

Thay `THOI_DIEM_BACKUP` bằng thư mục thực tế. Restore-test kiểm tra bản sao; **không ghi đè database đang dùng**. Backup chứa SQL, tệp riêng tư và checksum, cần giữ ngoài Git.

Sau khi lấy bản code đã được kiểm tra, cập nhật local:

```powershell
python scripts/docker.py up
python scripts/docker.py smoke
```

Kiểm tra dữ liệu còn sau khi khởi động lại MySQL, chỉ thực hiện khi chấp nhận gián đoạn ngắn:

```powershell
python scripts/docker.py restart-test
```

**Không dùng `docker compose down -v`, không xóa volume MySQL trong Docker Desktop.** `.secrets/` chứa cả khóa ký và khóa mã hóa dữ liệu; cần giữ và sao lưu an toàn, không tự tạo lại khi database còn dữ liệu.

## 5. Chạy trực tiếp để phát triển — không cần Docker cho ứng dụng

Chế độ này dùng MySQL cài trên Windows, độc lập với database Docker. Máy hiện tại dùng database `sms_v6_original`. Máy mới cần chuẩn bị V6 theo [hướng dẫn database](data/v6/README.md), không nhập đè vào database hiện có hoặc trộn schema v2/V6.

Cấu hình kết nối và bí mật cục bộ ở `backend/.env.local`; không commit. Sau khi database đã được chuẩn bị đúng phiên bản, mở terminal thứ nhất:

```powershell
powershell -ExecutionPolicy Bypass -File .\backend\Start-V6.ps1
```

Script dùng `backend/.env.local` khi không truyền tham số kết nối. Backend: http://127.0.0.1:8081/api.

Terminal thứ hai:

```powershell
cd frontend
npm.cmd ci
npm.cmd run dev -- --host 127.0.0.1
```

Frontend thường ở http://127.0.0.1:5173; dùng URL Vite thực tế in ra. `/api` được proxy sang backend. Không dùng tài khoản Docker để suy ra mật khẩu của database host; xem hồ sơ tài khoản cục bộ đúng môi trường.

## 6. Kiểm thử bằng dòng lệnh

```powershell
python scripts/ci.py prepare
python scripts/ci.py backend
python scripts/ci.py frontend
python scripts/ci.py build
python scripts/ci.py mysql
python scripts/ci.py security
python scripts/ci.py secrets
```

- `prepare`: kiểm tra công cụ và chạy kiểm thử script vận hành.
- `backend`: Maven Wrapper, test và coverage.
- `frontend`: cài dependency, lint, test, coverage và build.
- `build`: build ba image theo commit.
- `mysql`: kiểm thử MySQL thật, sáu vai trò trên trình duyệt, backup/restore và restart trong môi trường `sms_ci_*` riêng.
- `security`/`secrets`: quét bảo mật theo chính sách trong script; không phải cam kết không còn mọi loại lỗ hổng.

Các container CI là tạm thời và được dọn sau kiểm thử. CI đạt không tự cập nhật website `sms_local:8088`. Báo cáo nằm trong `artifacts/reports/`, `backend/target/` và `frontend/coverage/`; Jenkins lưu các báo cáo được cho phép khi chạy job.

## 7. Chạy bằng Jenkins trên Windows

### Chuẩn bị agent

Jenkins dự kiến ở http://localhost:8080, agent có label `sms-docker`. Tài khoản dịch vụ Jenkins phải chạy được Git, Python, Java 21, Node.js, Chrome và Docker Linux. Terminal người dùng chạy được chưa chứng minh dịch vụ Jenkins cũng chạy được.

Nếu lỗi không tìm thấy Python: **Manage Jenkins → Nodes → node chạy build → Configure → Node Properties → Environment variables**, đặt `PYTHON_EXE` là đường dẫn tuyệt đối tới `python.exe`, không thêm dấu ngoặc kép hay tham số. Ưu tiên Python cài cho tất cả người dùng; không giả định dịch vụ đọc được thư mục profile Admin. Các lệnh Windows dùng `scripts/jenkins-python.cmd`.

### Tạo job và chạy

1. Cài các plugin Pipeline, Git, GitHub Branch Source, Credentials Binding, JUnit và **SonarQube Scanner for Jenkins**.
2. Khuyến nghị tạo **Multibranch Pipeline**, chọn repository GitHub, nhánh cần build và Script Path `Jenkinsfile`. Nếu dùng Pipeline from SCM, điều kiện `branch`/tag của các stage phát hành cần được kiểm tra theo kiểu job; không coi job đơn nhánh tương đương Multibranch.
3. Cấu hình SonarQube như phần tiếp theo.
4. Push thay đổi Jenkinsfile/script đã review lên nhánh Jenkins đang lấy, rồi **Build Now** hoặc **Scan Multibranch Pipeline Now**.
5. Xem **Console Output**, kết quả test và Artifacts. Tìm lỗi đầu tiên; các stage sau báo skipped thường chỉ là hệ quả.

Giữ `DEPLOY_STAGING=false` và `DEPLOY_PRODUCTION=false` khi chưa có máy triển khai. Publish chỉ áp dụng cho nhánh/tag được Jenkinsfile cho phép và cần Registry/credential thật; chạy local không cần bật publish/deploy.

### SonarQube: phần cần cài thêm

**Repository hiện chưa cung cấp service/server SonarQube trong Compose.** Plugin Jenkins chỉ là bộ kết nối. Không có server thì chưa có URL/token hợp lệ; pipeline hiện sẽ dừng tại SonarQube thay vì giả báo đạt Quality Gate.

Khi quản trị viên đã chạy một server SonarQube:

1. Mở URL thực tế của server. `http://localhost:9000` chỉ đúng nếu server được công bố ở cổng 9000 trên cùng máy Windows chạy Jenkins.
2. Tạo project key `cmc-sms` và token phân tích.
3. Trong Jenkins → **Manage Jenkins → System → SonarQube servers → Add SonarQube**: Name phải là `sonarqube`, Server URL là URL vừa xác minh.
4. Thêm credential loại **Secret text**, ID `sonar-token`, chứa token; chọn trong **Server authentication token** rồi Save.
5. Cấu hình webhook trên SonarQube về `http://DIA_CHI_JENKINS:8080/sonarqube-webhook/`. Nếu SonarQube chạy trong Docker Desktop và Jenkins chạy trên Windows, thường dùng `http://host.docker.internal:8080/sonarqube-webhook/`, cần kiểm tra kết nối thực tế.
6. Chạy lại job để kiểm tra phân tích và Quality Gate. Không dùng URL Jenkins :8080 hoặc Grafana :3000 làm URL SonarQube.

Hướng dẫn đầy đủ về GitHub webhook, credentials, Registry và stage: [Jenkins/CI/CD](docs/operations/JENKINS.md). GitHub không truy cập được endpoint `localhost` của máy bạn; webhook GitHub cần địa chỉ có thể truy cập từ bên ngoài.

## 8. Ý nghĩa cấu hình và trạng thái triển khai

| Tệp | Mục đích |
|---|---|
| `compose.yaml` | Hệ thống local, build source, dữ liệu thực hành và monitoring tùy chọn |
| `compose.prod.yaml` | Staging/production dùng image digest, không build source trên máy triển khai |
| `compose.tls.yaml` | Bổ sung gateway HTTPS khi có tên miền và cấu hình phù hợp |
| `Jenkinsfile` | Điều phối test, Quality Gate, image scan, publish và deploy có điều kiện |
| `.env` | Tham số Docker không bí mật; `TZ=Asia/Ho_Chi_Minh` là giờ Việt Nam, không có dấu gạch chéo cuối dòng |
| `.secrets/` | Mật khẩu, khóa ký JWT và khóa mã hóa; không commit |
| `backend/.env.local` | Cấu hình riêng khi chạy Java trực tiếp trên host |

Chưa có VPS/domain/Registry được thiết lập trong phạm vi local. Có script triển khai, phê duyệt và rollback có điều kiện nhưng không đồng nghĩa đã chạy production. Hiện chưa có cơ chế bắt buộc đúng digest đã qua staging trước production hoặc kênh thông báo kết quả/cảnh báo thực tế. Xem [nghiệm thu và giới hạn](docs/operations/ACCEPTANCE.md).

SMTP/outbox mặc định tắt để tránh gửi vào địa chỉ thực hành. Chỉ bật khi có tài khoản gửi hợp lệ, cấu hình bí mật đúng môi trường và hộp thư người nhận đã được xác minh. Script `backend/Configure-Gmail.ps1` phục vụ cấu hình host; Docker dùng biến cấu hình và secret tương ứng. Chưa tích hợp tự cấp hộp thư Google hoặc thanh toán trực tuyến.

## 9. Xử lý lỗi thường gặp

| Hiện tượng | Kiểm tra / cách xử lý |
|---|---|
| Jenkins không tìm thấy Python | Cấu hình `PYTHON_EXE` cho đúng node và quyền tài khoản dịch vụ |
| `No such DSL method withSonarQubeEnv` | Cài/bật SonarQube Scanner for Jenkins, khởi động lại khi không có build chạy |
| Không có cấu hình `sonarqube` | Thêm server đúng Name và token trong Manage Jenkins → System |
| Quality Gate chờ hết thời gian | Kiểm tra phân tích, webhook SonarQube → Jenkins và khả năng kết nối |
| Docker engine không kết nối được | Mở Docker Desktop, chọn Linux containers, kiểm tra quyền dịch vụ/context |
| Không mở được :8088 | Chạy `status`, `logs`, `smoke`; kiểm tra `APP_PORT` trong `.env` và xung đột cổng |
| `Environment already exists` | Bỏ qua `init`; không xóa cấu hình và secret đang dùng |
| Login không được | Dùng đúng tài khoản/mật khẩu của môi trường Docker hoặc host |
| Jenkins báo skipped/no test reports | Tìm lỗi đầu tiên phía trên; test có thể chưa được chạy |

## 10. Tài liệu chi tiết

- [Vận hành Docker và CI/CD](docs/operations/README.md)
- [Runbook triển khai, backup và xử lý sự cố](docs/operations/RUNBOOK.md)
- [Kiến trúc hệ thống](docs/operations/ARCHITECTURE.md)
- [Backend và luồng nghiệp vụ](docs/BACKEND_V6_LUONG_NGHIEP_VU.md)
- [API backend V6](docs/API_BACKEND_V6.md)
- [Migration Docker/Flyway](db/migration/README.md)
- [Dữ liệu thực hành](docs/BO_DU_LIEU_THUC_HANH.md)
- [Bảo mật](SECURITY.md)

Dữ liệu mang tên cụ thể trong seed là **dữ liệu thực hành**, không phải hồ sơ/chứng từ chính thức của nhà trường. Không tự điền chứng từ, quỹ hoặc giấy tờ còn thiếu để làm báo cáo trông đầy đủ.