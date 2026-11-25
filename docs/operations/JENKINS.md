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
| Checkout / Check Environment / Prepare | Checkout đúng SHA, gửi thông báo bắt đầu, kiểm tra Python, Java, Docker và Chrome, chuẩn bị BuildKit và chạy test công cụ |
| Backend | Maven Wrapper clean verify, JUnit và JaCoCo |
| Frontend | npm ci → lint → API tests + Vitest/RTL + coverage/JUnit → build |
| Validate Docker Compose | Render Compose kèm profile giám sát. Promtool kiểm tra cấu hình scrape, các rule và test cảnh báo khi lỗi/phục hồi |
| Sonar/Quality Gate | Token từ Jenkins, waitForQualityGate; lỗi chặn các bước sau |
| Image Build | 3 image tag full commit SHA, gồm image migration bất biến |
| MySQL Integration | DB riêng `sms_ci_*`, Flyway, 15 login, 8 luồng/kiểm tra nghiệp vụ, 6 vai trò trên trình duyệt, health/SQL, backup/restore và restart; xóa đúng volume CI sau test |
| Security | npm audit mức Critical; Trivy dependency/images chặn Critical; secret scan riêng chặn mọi severity, report che giá trị bí mật |
| Deploy Local Docker | Branch `quyen/admin` hoặc `develop`, build thường. Backup nếu DB/backend đang chạy, chạy migration, khởi động app bằng image đã test, provision tài khoản demo, chạy smoke test và cập nhật stack giám sát |
| Post | Lưu JUnit, coverage và báo cáo CI. Gửi tổng kết trên Discord với trạng thái CI/CD và link console |

Job hiện tại triển khai Docker local. Registry, staging và production là luồng phát hành riêng. SonarQube chạy trên build nhánh khi bật tham số RUN_SONAR, mặc định bật. PR chạy các kiểm tra phù hợp và không deploy. Lỗi ở một gate chặn các bước triển khai sau đó.

## Credentials và thông số

| ID / biến | Loại | Mục đích |
|---|---|---|
| github-read | GitHub App/token | Cấu hình repository trong Multibranch, quyền đọc tối thiểu |
| registry-push | Username/password | Registry token chỉ push repository cần thiết |
| sonar-token | Secret text | Gắn vào SonarQube server của Jenkins |
| sms-discord-webhook | Secret text hoặc Secret file | Webhook của kênh `#jenkins`. Với Secret text, dán URL. Với Secret file, dùng file `jenkins_discord_webhook_url`. Scope Global. |
| vps-ssh | SSH private key | Deploy user, không gửi key vào chat/Git |
| vps-known-hosts | Secret file | Host key đã xác minh ngoài kênh; StrictHostKeyChecking=yes |
| REGISTRY_NAMESPACE | Job parameter | Ví dụ ghcr.io/ten-nhom; chưa có thì không bật publish release |
| STAGING_HOST / PRODUCTION_HOST | Agent/job env | Hostname/IP; không kèm command/path |

Registry password truyền qua stdin, không nằm trong lệnh. Jenkins Credentials masking không ngăn script độc hại lấy secret; chỉ chạy credential stages trên nhánh đã review và agent tin cậy.

Jenkins gửi thông báo sau checkout, khi stage lỗi, khi CD bắt đầu và khi pipeline kết thúc. Nội dung gồm job, build, branch, commit, stage hoặc bước kiểm tra nếu có, và link console. Dòng `Discord notification delivered (HTTP 200, message …)` xác nhận Discord đã nhận thông báo. Cảnh báo Alertmanager dùng webhook riêng của kênh giám sát.

## Webhook

Jenkins cần endpoint HTTPS GitHub truy cập được. Cấu hình GitHub Settings → Webhooks → `https://<ci-domain>/github-webhook/`, application/json, push/PR theo plugin, secret/chữ ký được plugin/relay kiểm tra. Không dùng localhost làm URL của GitHub. Có thể dùng Poll SCM tạm thời; không ghi nhận AC webhook đã đạt khi chưa có delivery 2xx/build link đúng SHA.

## Chạy từng bước tại máy

Trên Windows, pipeline mặc định dùng Docker Desktop Linux Engine. Có thể chỉ định Engine khác bằng `SMS_DOCKER_CONTEXT` hoặc `SMS_DOCKER_HOST` trong môi trường agent. Ở stage **Check Environment**, Jenkins thử lại kết nối khoảng 2 phút nếu Engine chưa sẵn sàng. Khi Engine phản hồi, build tiếp tục tự động. Khi hết thời gian chờ, Jenkins ghi lỗi kết nối vào console và gửi cảnh báo Discord kèm stage, nguyên nhân và link console. Các bước build, Compose và test dùng cùng endpoint.

Thông báo Discord dùng credential `sms-discord-webhook` và hoạt động độc lập với Docker. Với nhánh `quyen/admin` hoặc `develop`, quản trị viên có thể cấu hình `SMS_DISCORD_WEBHOOK_FILE` trong môi trường agent làm phương án dự phòng, trỏ đến file webhook được bảo vệ bên ngoài thư mục checkout. Jenkins agent cần đọc được file này và kết nối HTTPS đến Discord.

## Phân tích lỗi CI/CD bằng AI

Với build có kết quả `FAILURE`, `UNSTABLE`, `ABORTED` hoặc `NOT_BUILT` trên `quyen/admin` hoặc `develop`, pipeline gửi thông báo Discord hiện có trước. Sau đó agent đọc `consoleText` của build bằng Jenkins API và chuyển nội dung sang backend. Backend lọc các dạng bí mật phổ biến, lưu console đến thời điểm thu thập trong MySQL, rồi trả `202 Accepted`. Giới hạn mỗi console là 10 MiB. Bản ghi được nhận diện theo URL job và số build.

1. Triển khai backend và migration `V4__jenkins_incidents.sql`. Cấp các biến dưới đây cho container backend qua môi trường triển khai được bảo vệ. Với Docker Compose, truyền chúng khi tạo lại backend. Giữ giá trị bí mật ngoài repository và tránh ghi kết quả `docker compose config` vào log.

   | Biến backend | Giá trị |
   |---|---|
   | `SMS_JENKINS_INGEST_TOKEN` | Token ngẫu nhiên riêng có ít nhất 32 ký tự |
   | `SMS_CI_AI_URL` | URL HTTPS đầy đủ của API Chat Completions tương thích, gồm đường dẫn endpoint |
   | `SMS_CI_AI_MODEL` | Tên model theo nhà cung cấp |
   | `SMS_CI_AI_KEY` | API key của nhà cung cấp |
   | `SMS_CI_DISCORD_WEBHOOK_URL` | Webhook của kênh `#jenkins`, cùng đích với credential `sms-discord-webhook` |

2. Trong Jenkins, tạo credential **Username with password** có ID `sms-jenkins-console-reader`. Điền tên tài khoản có quyền đọc job và API token của tài khoản đó. Tạo credential **Secret text** có ID `sms-jenkins-incident-token`, trùng token backend.
3. Job Windows local `SMS-CICD` mặc định gửi về `http://127.0.0.1:8088/api/ops/jenkins-incidents`. Đặt `SMS_JENKINS_INGEST_URL` nếu dùng cổng khác, backend khác hoặc job khác. Dùng HTTPS khi đi qua mạng. Agent cần kết nối tới cả Jenkins console URL và backend.
4. Dùng một build lỗi để xác minh console có dòng `Jenkins incident accepted for build #...` và kênh `#jenkins` nhận tin **Phân tích AI · Jenkins #...**.

Backend gửi phần log đã lọc và giới hạn dung lượng tới nhà cung cấp AI. Bộ lọc nhận dạng các dạng bí mật phổ biến. Tránh in dữ liệu cá nhân và bí mật vào build log, đồng thời chọn nhà cung cấp được phép xử lý log của dự án. Tác vụ nền lưu kết quả AI trước khi gửi Discord và giãn thời gian thử lại khi API hoặc webhook lỗi.

Nếu backend tạm ngừng, Jenkins thử gửi lại ngắn hạn và giữ console gốc theo chính sách lưu build. Khi backend hoạt động, có thể nạp lại build đã kết thúc bằng script dưới đây. Chạy với các biến `SMS_JENKINS_INGEST_URL`, `SMS_JENKINS_INGEST_TOKEN`, `SMS_JENKINS_CONSOLE_USER` và `SMS_JENKINS_CONSOLE_TOKEN` đã được cấp qua môi trường an toàn.

```powershell
python scripts/jenkins_incident.py --build-url http://localhost:8080/job/SMS-CICD/45/ --result FAILURE
```

Cảnh báo vận hành và bản tin trạng thái tiếp tục chạy qua Prometheus, Alertmanager và webhook giám sát.

Windows agent tự tạo và khởi động builder `sms-jenkins-linux` bằng driver `docker-container` ở stage **Prepare**. Builder dùng cache riêng, tắt `unpigz` trong tiến trình BuildKit và nạp image vào cùng Docker Engine bằng `--load` cho MySQL integration, Trivy và deploy. Khi đổi sang một Docker endpoint khác, đặt `SMS_CI_BUILDER` thành tên riêng cho endpoint đó trong môi trường agent.

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

## CI duration and native Node crashes

Each Python CI subprocess logs elapsed time and decimal/hex exit status. Frontend installation keeps `npm ci` and the lockfile, with `--prefer-offline --no-fund` to reuse the npm cache. Lint uses a content-based ESLint cache; test, audit and release gates remain enabled. Warm runs can be faster; first installation, image build and security database downloads still take time.

A native stacktrace during `npm run lint` is not an ESLint rule violation or evidence of a Sonar webhook problem. Check the preceding error, Node version, Windows Event Viewer and available host memory. Do not mark the stage successful or retry silently. Avoid running `npm ci` in the same directory as a running Vite server: Windows can lock native module files; Jenkins should use its dedicated workspace.

A Sonar webhook with Last delivery = Never is configured but unverified. Run a fresh analysis after saving it, check HTTP 200 delivery and matching HMAC secret in Jenkins. SonarQube 26.11 may block private webhook targets; local-only configuration must explicitly permit the intended internal callback.

### Timing, evidence and demo rollout

Each build clears Jenkins report outputs after checkout, before publishing JUnit, coverage or archives. Keep evidence from previous runs in the Jenkins build archive. `artifacts/reports/stage-timings.json` identifies the build and checked-out commit, with stage transitions and elapsed time between recorded work checks. A check interrupted without an end event has a null duration. An unavailable workspace or incomplete checkout can prevent publishing an archive. The console remains the evidence for those cases.

MySQL CI writes `mysql-runtime.log`. Local deployment failures collect `docker-local.log` from the resolved local Compose project. Server apply and public smoke failures attempt `docker-server.log` over the same verified SSH connection. The console records failed log collection separately from the original deployment failure.

Local and SSH deployments require a passing Quality Gate and a clean checkout that matches the current build identity. For an existing demo database, provision verifies the mounted secret before replacing frontend/backend and verifies it again after startup. Missing, disabled or mismatched accounts block rollout without resetting passwords. Reconcile intentional changes explicitly before retrying. Fresh initialization starts from an empty schema. It records a private pending marker tied to the MySQL server UUID and schema so an interruption after migration can be retried with the same database. The marker is removed after a successful transaction. Keep the existing runtime secret directory with the matching database if a fresh deployment is interrupted.


## Phase 3–4: one CI owner, explicit promotion

Install Lockable Resources and configure resources sms-deploy-local and sms-deploy-server. Keep SMS-CICD as the only push-triggered job. Disable GitHub Push Trigger and Poll SCM in SMS-CICD-Server; the Jenkinsfile no longer installs polling. Verify actual webhook delivery before removing polling from the CI owner. Restrict job configuration, Replay, credentials and artifact modification to trusted administrators; the Jenkins controller is the release trust boundary.

| Mode | Job | Inputs |
|---|---|---|
| CI_ONLY | SMS-CICD | RUN_SONAR=true for a promotable release |
| FULL (default) | SMS-CICD | RUN_SONAR=true; publishes, then local rollout and server rollout on SMS_SERVER_BRANCH |
| DEPLOY_LOCAL_ONLY | SMS-CICD | RELEASE_BUILD and RELEASE_SHA |
| DEPLOY_SERVER_ONLY | SMS-CICD-Server | RELEASE_BUILD and RELEASE_SHA |

CI_ONLY on approved branches now requires registry access to publish a verified release (not a deployment). Configure REGISTRY_NAMESPACE and registry authentication for the service account on the CI owner, and pull authorization for deployment agents. Sonar-disabled diagnostic runs cannot create a release. Set SMS_SERVER_BRANCH on the CI owner and server retry job to the same approved branch (default quyen/admin). Configure SSH credentials, target and registry on the CI owner for automatic server deployment. A failed local rollout stops the subsequent server stage; no manual approval is required. Set JENKINS_URL to the actual trusted controller URL; HTTP is accepted only on loopback. The existing sms-jenkins-console-reader credential must have read access to the exact source build and artifacts. CD checks out the specified SHA only if it is an ancestor of the configured allowed branch; ensure the clone has adequate history. Do not enable CD on arbitrary branches or PRs.

The checkpoint records three immutable digests, image IDs, CI stage statuses, exact Sonar task/analysis, test and scan evidence checksums. Default freshness is 24 hours (SMS_RELEASE_MAX_AGE_HOURS, administrator controlled, 1–168 hours). CD rejects stale, wrong, dirty, incomplete or altered evidence. A failed FULL build can be reused only with an archived checkpoint and explicit local deployment failure receipt. Older releases without this checkpoint need new CI. Do not bypass a failed verification. Build logs and archives must be retained for the promotion window.

For a manual retry or after a CI_ONLY build on the approved branch, copy the source build number and full SHA from verified-release.json in the Jenkins archive. Run DEPLOY_LOCAL_ONLY or DEPLOY_SERVER_ONLY with these exact inputs. No Maven/npm/Trivy or image build is executed in these modes. Local deployment resolves the published digest and checks the image ID. Server deployment continues the existing SSH backup, restore rehearsal, migration and smoke/rollback flow. Do not run simultaneous manual deployment commands outside Jenkins locks. If local rollout fails after changing containers, use the existing backup and review schema compatibility before restoring previous images; never automatically revert database migrations.

### Retention (review only)

Run when the Docker Engine is idle, with the same context as Jenkins:

```powershell
python scripts/docker_retention.py --protected-release C:/secure/current.json --protected-release C:/secure/rollback1.json --protected-release C:/secure/rollback2.json
docker system df -v
docker buildx du --builder sms-jenkins-linux
```

Supply verified-release.json files for ALL current releases, at least two rollback releases per environment and pending releases. Keep copies outside expiring Jenkins archives. The report excludes images used by any container (including stopped), protected release IDs/digests, foreign/shared tags, published digests and unlabelled images. Candidates are old SMS SHA tags (minimum 30 days). The script never deletes anything. Review registry retention separately. Measure dedicated builder cache and configure BuildKit GC only after choosing a host-specific budget; no automatic prune is introduced. Do not prune volumes or backups. Recheck protected references immediately before any operator-approved removal.

### Acceptance before merging

Run Declarative Linter and Sandbox, all operations tests, a full CI_ONLY build with registry, exact local and staging/server-only promotions, wrong SHA/digest, expired/modified evidence, failed FULL retry, cancellation, and Discord/incident delivery. Verify no CI steps execute during CD-only, and compare timings. Confirm the CI owner and server job triggers and lock configuration. Retention must be reviewed against actual running and stopped containers and rollback receipts. Do not deploy production merely to test this change.
