STUDENT MANAGEMENT SYSTEM (SMS)
Đề tài: Xây dựng và triển khai hệ thống quản lý sinh viên trên nền tảng Web, tích hợp CI/CD và giám sát hệ thống.

Học phần: Triển khai phần mềm
Nhóm thực hiện: 5 thành viên
Trạng thái: Đang phân tích, thiết kế và phát triển
1. Giới thiệu
Student Management System (SMS) là hệ thống web hỗ trợ nhà trường quản lý tập trung hồ sơ sinh viên và các hoạt động đào tạo cơ bản. Hệ thống hướng đến việc giảm thao tác thủ công, nâng cao tính nhất quán của dữ liệu và cung cấp thông tin phù hợp cho từng nhóm người dùng.

Ngoài phần mềm nghiệp vụ, dự án còn tập trung vào quy trình kiểm thử, tích hợp liên tục, triển khai tự động và giám sát vận hành, đáp ứng yêu cầu của học phần Triển khai phần mềm.
2. Mục tiêu
- Quản lý hồ sơ và trạng thái học tập của sinh viên một cách tập trung.
- Hỗ trợ tổ chức lớp học phần, phân công giảng viên, đăng ký học phần và tra cứu lịch học.
- Hỗ trợ nhập, kiểm tra, phê duyệt và công bố kết quả học tập theo phân quyền.
- Theo dõi học phí phát sinh từ học phần đã đăng ký và tình trạng thanh toán.
- Cung cấp bảng điều khiển, báo cáo và công cụ tra cứu cho từng vai trò.
- Xây dựng quy trình CI/CD, đóng gói Docker, triển khai qua SSH lên máy chủ và giám sát hệ thống.
3. Đối tượng sử dụng
Vai trò	Phạm vi sử dụng chính
Quản trị viên hệ thống (Admin)	Quản lý tài khoản, vai trò và quyền truy cập.
Ban giám hiệu	Theo dõi báo cáo tổng hợp, xét duyệt các nghiệp vụ được phân quyền.
Phòng Đào tạo	Quản lý sinh viên, khoa/ngành/lớp, học phần, lịch học; kiểm tra và trình duyệt điểm.
Giảng viên	Xem lớp được phân công, lịch dạy, danh sách sinh viên; nhập điểm và đánh giá.
Sinh viên	Xem hồ sơ, đăng ký học phần, lịch học, điểm, học phí và gửi yêu cầu.


4. Phạm vi chức năng dự kiến
1. Tài khoản và phân quyền: Đăng nhập, đổi mật khẩu, quản lý tài khoản, phân quyền theo vai trò.
2. Quản lý sinh viên: Hồ sơ, thông tin liên hệ, lớp, ngành, khóa và tình trạng học tập.
3. Quản lý đào tạo: Khoa, ngành, năm học, học kỳ, học phần và lớp học phần.
4. Đăng ký học phần và lịch học: Đăng ký/hủy đăng ký theo điều kiện, phân công giảng viên, thời khóa biểu.
5. Điểm và đánh giá: Giảng viên nhập điểm → Phòng Đào tạo kiểm tra → Ban giám hiệu/người được ủy quyền phê duyệt → công bố cho sinh viên.
6. Học phí: Tính học phí theo học phần, theo dõi công nợ và ghi nhận thanh toán thủ công.
7. Yêu cầu, thông báo: Sinh viên gửi yêu cầu; bộ phận phụ trách tiếp nhận, xử lý và phản hồi.
8. Dashboard và báo cáo: Thống kê sinh viên, kết quả học tập và học phí.
Giới hạn phạm vi: Chưa triển khai cổng thanh toán trực tuyến, tự động xếp thời khóa biểu, quản lý tuyển sinh, lương giảng viên hoặc hệ thống kế toán đầy đủ.
Các chức năng trên là kế hoạch phát triển, không phải danh sách tính năng đã hoàn thành.

5. Công nghệ dự kiến
Thành phần	Công nghệ
Frontend	React, Vite
Backend / API	Java, Spring Boot
Cơ sở dữ liệu	MySQL
Xác thực và phân quyền	Spring Security, JWT
Quản lý mã nguồn	Git, GitHub
CI/CD	Jenkins
Phân tích chất lượng mã nguồn	SonarQube
Container	Docker, Docker Compose
Máy chủ triển khai	Ubuntu VPS, SSH
Giám sát	Prometheus, Grafana


Kiến trúc dự kiến: React → Spring Boot REST API → MySQL. Các thành phần được đóng gói và triển khai bằng Docker Compose.
6. Thành viên nhóm
Thành viên	Công việc phụ trách chính
Hà Văn Võ Quyền (Trưởng nhóm)	Phân tích tổng thể, tài khoản/phân quyền, hồ sơ sinh viên, điều phối GitHub và Jenkins.
Nguyễn Hà Khoa	Khoa/ngành/lớp, học phần, đăng ký môn, lịch học; hỗ trợ Docker.
Ngần Thái Thường	Giảng viên, điểm, đánh giá và xét duyệt; hỗ trợ SonarQube và kiểm thử.
Đặng Long Quân	Học phí, công nợ, yêu cầu sinh viên; hỗ trợ VPS, SSH và triển khai.
Khuất Thùy Linh	Giao diện tổng thể, Dashboard, báo cáo; hỗ trợ giám sát Grafana.


7. Quy trình làm việc trên GitHub
- main: Nhánh ổn định phục vụ phát hành/triển khai.
- develop: Nhánh tích hợp các chức năng đã được kiểm tra.
- feature/<ten-chuc-nang>: Nhánh do từng thành viên tự tạo từ develop để phát triển chức năng được giao.
- Mọi thay đổi nên được gửi qua Pull Request (PR) vào develop, được thành viên khác xem xét trước khi gộp.
- Chỉ gộp develop vào main khi phiên bản đã được kiểm thử và sẵn sàng triển khai.
Quy ước commit đề xuất:
feat: them chuc nang quan ly sinh vien
fix: sua loi dang ky hoc phan
docs: cap nhat tai lieu du an
test: bo sung kiem thu diem
chore: cap nhat cau hinh docker
8. Cài đặt và chạy dự án
Dự án đang trong giai đoạn khởi tạo. Hướng dẫn cài đặt và các lệnh chạy frontend, backend, cơ sở dữ liệu và Docker Compose sẽ được cập nhật sau khi nhóm thống nhất cấu trúc thư mục và tạo mã nguồn ban đầu.
9. Triển khai và giám sát dự kiến
Quy trình mục tiêu:
GitHub → Jenkins (Build/Test) → SonarQube → Docker Image
       → SSH / Docker Compose trên VPS → Prometheus & Grafana
Các đầu ra cần đạt: ứng dụng hoạt động qua địa chỉ public, pipeline tự động chạy được, có kiểm thử và báo cáo giám sát vận hành.
10. Tiến độ dự kiến
Từ 27/10/2026 đến 03/12/2026. Kế hoạch chi tiết được theo dõi trong backlog/Jira của nhóm, gồm khảo sát nhu cầu, xác định phạm vi, phân tích thiết kế, lập trình, kiểm thử, triển khai và nghiệm thu.
