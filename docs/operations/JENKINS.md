# Jenkins, GitHub Webhook và Registry

Jenkinsfile hỗ trợ agent Windows/Linux, label **sms-docker**, có Java 21, Node 22+, Python 3, Git, Google Chrome (hoặc CHROME_PATH), Docker Linux và Maven Wrapper. Giữ Jenkins Windows :8080, website :8088. Service account của Jenkins phải truy cập được Docker engine; Docker access tương đương quyền quản trị host, chỉ dùng agent tin cậy.

## Tạo job

1. Cài Pipeline, Git, GitHub, GitHub Branch Source, Credentials Binding, JUnit và SonarQube Scanner for Jenkins.
2. Tạo Multibranch Pipeline, repository của nhóm, Script Path `Jenkinsfile`; discovery `develop`, `main`, tags và PR. Bảo vệ main/develop bằng CI xanh và review. Không tự merge/push thay đổi từ máy này.
3. Cấu hình JDK/Node/Python trên PATH agent; gán label `sms-docker`. Maven Wrapper sẽ tải đúng Maven theo `.mvn/wrapper/maven-wrapper.properties`.
4. Configure System → SonarQube servers → tên **sonarqube**, URL server và token credential. SonarQube tạo project `cmc-sms`; cấu hình webhook về `https://<jenkins>/sonarqube-webhook/` để `waitForQualityGate` hoạt động.
5. Chạy Build Now. Không bật deploy khi chưa có VPS và chưa kiểm tra restore. Job sẽ dừng ở gate thiếu cấu hình, không báo xanh giả hoặc bỏ qua scan.

## Stages và lệnh tương ứng

| Stage | Lệnh / kết quả |
|---|---|
| Checkout/Prepare | SHA, dirty flag, công cụ; `python scripts/ci.py prepare` |
| Backend | Maven Wrapper clean verify, JUnit và JaCoCo |
| Frontend | npm ci → lint → API tests + Vitest/RTL + coverage/JUnit → build |
| Sonar/Quality Gate | Token từ Jenkins, waitForQualityGate; lỗi chặn các bước sau |
| Image Build | 3 image tag full commit SHA, gồm image migration bất biến |
| MySQL Integration | DB riêng `sms_ci_*`, Flyway, 15 login, 8 luồng/kiểm tra nghiệp vụ, 6 vai trò trên trình duyệt, health/SQL, backup/restore và restart; xóa đúng volume CI sau test |
| Security | npm audit mức Critical; Trivy dependency/images chặn Critical; secret scan riêng chặn mọi severity, report che giá trị bí mật |
| Publish | Chỉ develop/main/tag tin cậy, không PR; ghi digest 3 image vào `artifacts/reports/release.json` |
| Staging | Chỉ develop và bật tham số DEPLOY_STAGING |
| Production | main/tag v*, bật tham số và thành viên nhóm `sms-release-approvers` phê duyệt |
| Post | JUnit, coverage, build/release/scan JSON; không archive secrets/SQL dump |

PR từ fork không được nhận Sonar credential; không publish/deploy từ PR. Agent kiểm thử PR không được đặt chung secrets production. Với các PR tin cậy, Sonar gate là bắt buộc trước publish. Lint hiện phân biệt lỗi với cảnh báo unused code cũ; 0 lỗi là điều kiện qua, cảnh báo vẫn nằm trong log.

## Credentials và thông số

| ID / biến | Loại | Mục đích |
|---|---|---|
| github-read | GitHub App/token | Cấu hình repository trong Multibranch, quyền đọc tối thiểu |
| registry-push | Username/password | Registry token chỉ push repository cần thiết |
| sonar-token | Secret text | Gắn vào SonarQube server của Jenkins |
| vps-ssh | SSH private key | Deploy user, không gửi key vào chat/Git |
| vps-known-hosts | Secret file | Host key đã xác minh ngoài kênh; StrictHostKeyChecking=yes |
| REGISTRY_NAMESPACE | Job parameter | Ví dụ ghcr.io/ten-nhom; chưa có thì không bật publish release |
| STAGING_HOST / PRODUCTION_HOST | Agent/job env | Hostname/IP; không kèm command/path |

Registry password truyền qua stdin, không nằm trong lệnh. Jenkins Credentials masking không ngăn script độc hại lấy secret; chỉ chạy credential stages trên nhánh đã review và agent tin cậy.

## Webhook

Jenkins cần endpoint HTTPS GitHub truy cập được. Cấu hình GitHub Settings → Webhooks → `https://<ci-domain>/github-webhook/`, application/json, push/PR theo plugin, secret/chữ ký được plugin/relay kiểm tra. Không dùng localhost làm URL của GitHub. Có thể dùng Poll SCM tạm thời; không ghi nhận AC webhook đã đạt khi chưa có delivery 2xx/build link đúng SHA.

## Chạy từng bước tại máy

```powershell
python scripts/ci.py prepare
python scripts/ci.py backend
python scripts/ci.py frontend
python scripts/ci.py build
python scripts/ci.py mysql
python scripts/ci.py security
```

SonarQube/Registry/SSH cần dịch vụ và credential thật. Không commit các giá trị này. Production không build source trên VPS; chỉ pull digest đã scan/test.

## Windows: Python unavailable to Jenkins service

Checkout can succeed while Prepare fails because the service account has a different PATH from the interactive user. Windows pipeline commands use `scripts/jenkins-python.cmd`: `PYTHON_EXE`, then `python`, then `py -3`, then the common all-users Python313 path. Python 3.10+ is required.

In Manage Jenkins > Nodes > select the build node > Configure > Node Properties > Environment variables, set `PYTHON_EXE` to the absolute path of an accessible `python.exe` (no quotes or arguments). Prefer an all-users installation. Restart the agent/service after changing its system PATH. A Python installed under an Admin user profile is not guaranteed accessible to the Jenkins service account. Commit/push the wrapper and Jenkinsfile changes before rebuilding an SCM-based job.
