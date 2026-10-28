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
Vai trò	                     Phạm vi sử dụng chính
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
8. Cài đặt và khởi chạy dự án trên Windows
Hướng dẫn này dành cho thành viên nhóm mới clone repository về Windows, sử dụng VS Code + PowerShell. Đây là quy trình chạy local trong giai đoạn phát triển, chưa phải quy trình deploy bằng Docker/Jenkins.
8.1. Phần mềm cần cài đặt
Phần mềm	              Yêu cầu / phiên bản nhóm dùng	              Kiểm tra
Git hoặc GitHub Desktop	Đã đăng nhập và có quyền truy cập repository	git --version
Visual Studio Code	       Có thể mở thư mục dự án	                     Mở VS Code
Node.js và npm	       Node.js 24.x (máy khởi tạo dùng 24.21.0)	       node -v và npm.cmd -v
Java JDK	              JDK 21 (Eclipse Temurin hoặc tương đương)	       java -version và javac -version
Maven	       Không bắt buộc cài Maven toàn cục vì đã có mvnw.cmd trong backend	.\mvnw.cmd -version

Lưu ý về Maven: Lệnh kiểm tra đúng là .\mvnw.cmd -version được trình bày tại mục 8.5. Không sử dụng mvn compile khi máy chưa thiết lập Maven vào PATH.

8.2. Clone source từ GitHub
– GitHub Desktop: File → Clone repository → URL, dán địa chỉ bên dưới rồi chọn thư mục lưu. Sau đó bấm Open in Visual Studio Code.


Nếu Git cho đường dẫn khác thư mục đang mở, kiểm tra lại để tránh chạy hoặc commit nhầm source.
8.3. Cấu trúc thư mục khi khởi tạo
CMC_SoftwareDeploy/
├── frontend/               # React + Vite
│   ├── src/
│   └── package.json
├── backend/                # Spring Boot + Maven Wrapper
│   ├── src/main/java/com/sms/backend/
│   ├── src/main/resources/application.properties
│   ├── pom.xml
│   └── mvnw.cmd
├── mysql.sql               # Câu lệnh khởi tạo database (nếu có)
└── Readme.md / README.md   # Tài liệu dự án
Các thư mục docs/, database/ và infrastructure/ sẽ được bổ sung khi nhóm triển khai những giai đoạn tương ứng. Không tạo bản sao thứ hai của backend hoặc frontend ở thư mục cha.
8.4. Khởi động MySQL và tạo cơ sở dữ liệu
Bước 1 – Kiểm tra dịch vụ MySQL trong PowerShell:
Get-Service *mysql*
Máy khởi tạo dự án đang dùng tên dịch vụ MySQL267. Nếu trạng thái là Stopped, mở Windows PowerShell bằng quyền Administrator rồi chạy:
Start-Service -Name MySQL267
Get-Service MySQL267
Kết quả mong muốn: Running. Nếu tên dịch vụ trên máy bạn khác, thay bằng tên thật hiển thị ở lệnh kiểm tra. Có thể mở services.msc để kiểm tra hoặc khởi động thủ công. Nếu dịch vụ vẫn không chạy thì cần xử lý lỗi MySQL Server trước.

Bước 2 – Kiểm tra cổng:
Test-NetConnection 127.0.0.1 -Port 3306
Cần có TcpTestSucceeded : True nếu MySQL dùng cổng 3306. Nếu False dù dịch vụ đang chạy, dùng MySQL Command Line Client để kiểm tra cổng thực tế:
SHOW VARIABLES LIKE 'port';
Bước 3 – Tạo database: Mở MySQL Command Line Client hoặc MySQL Workbench, đăng nhập bằng tài khoản MySQL của bạn rồi chạy:
CREATE DATABASE IF NOT EXISTS sms_db
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

SHOW DATABASES LIKE 'sms_db';
Khi truy vấn cuối trả về sms_db, database đã tồn tại. Bước này chỉ tạo database, chưa cần tự tạo bảng nghiệp vụ.
8.5. Cấu hình và chạy Backend Spring Boot
Bước 1 – Mở file backend/src/main/resources/application.properties, bảo đảm có cấu hình local tương ứng:
spring.application.name=backend
server.port=8081

# MySQL local
spring.datasource.url=jdbc:mysql://127.0.0.1:3306/sms_db
spring.datasource.username=${DB_USERNAME:root}
spring.datasource.password=${DB_PASSWORD}

# Chỉ sử dụng ddl-auto=update khi phát triển local
spring.jpa.hibernate.ddl-auto=update
spring.jpa.open-in-view=false

# Endpoint kiểm tra trạng thái
management.endpoints.web.exposure.include=health,info
- Đổi 3306 nếu MySQL trên máy dùng cổng khác.
- Backend sử dụng cổng 8081 để không xung đột với Jenkins đang dùng cổng 8080 trên máy khởi tạo.
- Không viết mật khẩu MySQL trực tiếp vào application.properties hoặc commit mật khẩu lên GitHub.
Bước 2 – Mở Terminal PowerShell mới tại thư mục gốc repository, sau đó chạy:
cd backend
Test-Path .\mvnw.cmd
.\mvnw.cmd -version
Test-Path phải trả về True. Nếu False, bạn đang đứng sai thư mục; tìm wrapper bằng:
Get-ChildItem -Path . -Filter mvnw.cmd -Recurse -File |
    Select-Object -ExpandProperty FullName
Bước 3 – Thiết lập thông tin kết nối MySQL trong chính Terminal sẽ chạy Backend:
$env:DB_USERNAME = "root"
$secure = Read-Host "Nhap mat khau MySQL" -AsSecureString
$env:DB_PASSWORD = [System.Net.NetworkCredential]::new("", $secure).Password
Remove-Variable secure
Mật khẩu khi nhập sẽ không hiện trên màn hình. Các biến trên chỉ có hiệu lực trong cửa sổ Terminal hiện tại. Với môi trường thực tế, dùng tài khoản cơ sở dữ liệu riêng có quyền tối thiểu thay cho root.

Bước 4 – Biên dịch và chạy:
.\mvnw.cmd clean compile
.\mvnw.cmd spring-boot:run
Nếu biên dịch thành công sẽ có BUILD SUCCESS. Khi ứng dụng chạy thành công, Terminal sẽ có thông báo tương tự:
Tomcat started on port 8081 (http)
Started BackendApplication
Không đóng Terminal Backend khi đang sử dụng ứng dụng. Spring Boot là một máy chủ chạy liên tục nên Terminal không tự quay về dấu nhắc; đó không phải lỗi treo.

Bước 5 – Kiểm tra Backend trên trình duyệt:
- http://localhost:8081/actuator/health → kết quả mong muốn: {"status":"UP"}.
- http://localhost:8081/api/hello → trả về JSON thử nghiệm nếu nhóm đã thêm HelloController.
8.6. Cài đặt và chạy Frontend React
Mở Terminal thứ hai trong VS Code; giữ Terminal Backend hoạt động. Tại thư mục gốc repository, chạy:
cd frontend
npm.cmd install
npm.cmd run dev
Nếu Frontend đã được cài thư viện thì lần sau chỉ cần npm.cmd run dev.

Mở đường dẫn Vite hiển thị trong Terminal, thông thường:
http://localhost:5173/
Vì sao dùng npm.cmd? PowerShell trên một số máy chặn npm.ps1 với lỗi running scripts is disabled. npm.cmd giải quyết trường hợp này mà không phải thay đổi Execution Policy của Windows.

Lưu ý: Frontend chạy được chưa đồng nghĩa với đã kết nối Backend. Nhóm còn cần bổ sung API client, CORS hoặc Vite Proxy khi triển khai chức năng gọi dữ liệu.
8.7. Bảng địa chỉ truy cập local
Thành phần	Địa chỉ / cổng	Kiểm tra
React + Vite	http://localhost:5173	Trang giao diện React
Spring Boot	http://localhost:8081	http://localhost:8081/actuator/health
API thử nghiệm	http://localhost:8081/api/hello	JSON trả về nếu controller đã được tạo
MySQL	127.0.0.1:3306 (hoặc cổng thực tế)	Test-NetConnection
Jenkins	http://localhost:8080	Giao diện Jenkins (nếu dịch vụ đang chạy)

4. Mở Terminal 2, vào frontend/, chạy npm.cmd run dev.
5. Mở http://localhost:5173/ để phát triển và kiểm thử giao diện.
Dừng ứng dụng: Nhấn Ctrl + C trong từng Terminal chạy Backend/Frontend. Không cần dừng dịch vụ MySQL sau mỗi lần làm việc nếu còn ứng dụng khác cần sử dụng.
