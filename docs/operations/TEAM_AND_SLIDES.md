# Phân công và nội dung trình bày

Đây là gợi ý từ tài liệu yêu cầu, không phải xác nhận các thành viên đã thực hiện hoặc đã được thông báo.

| Thành viên | Phạm vi đề xuất | Minh chứng cần tự xác nhận |
|---|---|---|
| Hà Văn Võ Quyền | Kiến trúc, auth/quyền, Jenkins/Webhook, tích hợp | RBAC, build link, PR/release |
| Nguyễn Hà Khoa | Đào tạo, đăng ký/lịch, Docker | API enrollment, Compose/health |
| Ngần Thái Thường | Giảng viên/điểm, tests, Sonar | JUnit và Quality Gate |
| Đặng Long Quân | Học phí/quỹ, VPS/SSH/backup | Chứng từ, deploy, restore |
| Khuất Thùy Linh | UI/API, E2E, monitoring | Ảnh giao diện, dashboard |

## Bố cục 8 phần

1. Bài toán, sáu actor, ba chuỗi nghiệp vụ và ERD.
2. React/Vite, Java 21/Spring Boot, MySQL 8, Docker, Jenkins và công cụ chất lượng.
3. Nhánh/PR/Webhook, các stage CI/CD và điều kiện dừng khi fail.
4. Image/container/network/volume; Nginx :8088, Jenkins :8080, không IIS.
5. Actuator/Prometheus/Grafana, backup, restore, xử lý sự cố.
6. RBAC, sở hữu hồ sơ/điểm, CSRF/JWT, private files và scan.
7. Demo nhập học, đăng ký/lịch/điểm, học phí/bàn giao với MySQL thật.
8. Kết quả đã chạy và phần còn chờ Registry/VPS/Sonar/Webhook; chatbot là mở rộng, không giả vờ đã có RAG/tài liệu chính thức.

## Hồ sơ minh chứng

Dùng báo cáo trong `artifacts/reports`, log `backend/logs/docker-*`, ảnh `screenshots/recheck-2026-11-12` và [ACCEPTANCE.md](ACCEPTANCE.md). Khi có hạ tầng thật cần bổ sung: webhook delivery, Jenkins build URL, Quality Gate, Registry digest, HTTPS domain và video rollback. Không đưa password, token, SSH key, dump DB hoặc giấy tờ thật lên slide/Git.
