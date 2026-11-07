# EduPortal – Student Management System (Frontend Demo)

Giao diện React/Vite tiếng Việt, chạy độc lập **không cần Backend, không cần MySQL**. Mặc định mở ở cổng Sinh viên, hỗ trợ chuyển giữa bốn vai trò nghiệp vụ: Sinh viên, Giảng viên, Phòng Đào tạo và Ban Giám hiệu.

## Chạy trên Windows 11

```powershell
cd frontend
npm.cmd install
npm.cmd run dev
```

Mở http://localhost:5173. Nếu Terminal đã ở trong `frontend` thì bỏ qua lệnh `cd frontend`.

Kiểm tra build:

```powershell
npm.cmd run build
```

> Với Windows PowerShell chặn `npm.ps1`, sử dụng `npm.cmd` như trên, không cần đổi Execution Policy.

## Cách ghép vào Repo hiện tại

1. Đảm bảo Repository đúng là `CMC_SoftwareDeploy` có `frontend/`, `backend/`, `Readme.md`.
2. Sao lưu `frontend/src/` đang dùng (nếu đã chỉnh sửa). Không động tới thư mục `backend/`, `database/`.
3. Sao chép **nội dung** của thư mục `frontend/` trong gói này vào **thư mục `frontend/` hiện có** của Repo. Không tạo `frontend/frontend/`.
4. Trong `frontend/`, dùng `npm.cmd install` để cập nhật `package-lock.json`, tiếp theo `npm.cmd run dev`.
5. Commit lên nhánh feature riêng rồi tạo Pull Request vào `develop` khi nhóm thống nhất.

## Chức năng demo

| Vai trò | Màn hình | Tương tác |
|---|---|---|
| Sinh viên | Tổng quan, Đăng ký học phần, Lịch, Kết quả, Học phí, Yêu cầu, Thông báo, Hồ sơ | Đăng ký/hủy có kiểm tra lịch và sĩ số; xem chi tiết học phần/điểm; tra cứu lịch tuần và lịch thi |
| Giảng viên | Tổng quan, Lớp phân công, Lịch giảng dạy, Nhập điểm, Thông báo, Hồ sơ | Chỉnh lịch lớp được phân công; nhập điểm 0–10, lưu nháp, xem chi tiết và gửi bảng điểm |
| Phòng Đào tạo | Tổng quan, Sinh viên, Lớp học phần, Kiểm tra điểm, Học phí, Yêu cầu, Thông báo, Tài khoản, Cấu hình | Quản lý hồ sơ/lớp/tài khoản; xác nhận và công bố điểm; đăng tin toàn trường hoặc theo đối tượng; xử lý yêu cầu |
| Ban giám hiệu | Tổng quan, Phê duyệt hồ sơ sinh viên, Phê duyệt điểm, Báo cáo, Thông báo | Phê duyệt hoặc trả lại hồ sơ và bảng điểm; xuất báo cáo CSV |

Ban Giám hiệu là cấp phê duyệt học vụ cuối; Phòng Đào tạo phụ trách vận hành nghiệp vụ. Không có actor Admin riêng trong ứng dụng.

Thời khóa biểu hiển thị ngày bắt đầu/kết thúc học kỳ và lịch lớp lặp theo thứ/giờ đã xếp trong kỳ. Nút tuần trước/sau và lịch tháng cho phép tra các tuần khác. Lịch thi hiện là dữ liệu mẫu có ghi chú, cần Phòng Đào tạo xác nhận trước khi dùng như lịch chính thức.

## Quy trình thử nhập và công bố điểm

1. Chọn vai trò `Giảng viên` → `Nhập & gửi điểm`. Chọn `IT203-02`, nhập đủ điểm ba cột cho 2 sinh viên và bấm **Gửi Phòng Đào tạo**.
2. Đổi sang `Phòng Đào tạo` → `Kiểm tra bảng điểm`, chọn bảng vừa gửi → **Trình Ban giám hiệu**.
3. Đổi sang `Ban giám hiệu` → `Phê duyệt bảng điểm` → **Phê duyệt**.
4. Đổi về `Phòng Đào tạo` → `Kiểm tra bảng điểm` → **Công bố cho sinh viên**.
5. Đổi về `Sinh viên` → `Kết quả học tập` để xem điểm chính thức.

## Lưu trữ và giới hạn

- Toàn bộ dữ liệu chỉ là **mock**, lưu trong `localStorage` của trình duyệt (`sms-portal-demo-v1`). Đây không phải xác thực thật; người dùng có thể chuyển vai trò mà không đăng nhập.
- Màn Phòng Đào tạo chỉ mô phỏng tác vụ ở một số hồ sơ. **Không có giao dịch tiền thật**, không phát hành hóa đơn pháp lý, không gửi email hoặc thông báo đến thiết bị ngoài trình duyệt.
- Demo chưa gọi API và chưa ghi vào MySQL. Khi tích hợp Backend: tách `data.js` thành dữ liệu do API trả về; thêm lớp dịch vụ cho hồ sơ, học phần, enrollments, grade_sheets, grades, invoices, payments, student_requests, notifications; dùng JWT và RBAC thật ở server.
- Dùng `Phòng Đào tạo` → `Cấu hình hệ thống` → `Đặt lại` để trả về dữ liệu mẫu ban đầu.

## Thư mục

```
frontend/
├── index.html
├── package.json
├── vite.config.js
├── src/
│   ├── main.jsx                        # Khởi tạo React
│   ├── App.jsx                         # Shell, điều hướng và trạng thái
│   ├── pages/
│   │   ├── student/                    # Mỗi màn hình gồm Page.jsx + Page.css
│   │   ├── academic/
│   │   ├── administration/
│   │   └── public/                     # Landing.jsx + Landing.css, Login.jsx + Login.css
│   ├── components/
│   │   ├── landing/                    # Mỗi phần landing có JSX/CSS riêng
│   │   ├── layout/                     # Header/sidebar/footer dùng chung
│   │   └── common/                     # Thành phần UI nhỏ dùng chung
│   ├── styles/
│   │   ├── portal.css                  # Quy tắc dùng chung cho cổng học vụ
│   │   ├── public-site.css             # Khung và responsive cho trang công khai
│   │   └── theme.css                   # Màu sắc và kiểu chữ dùng chung
│   ├── index.css                       # Reset CSS
│   └── data/portalData.js              # Dữ liệu và hàm tính toán
└── README_FRONTEND.md
```

### Chỉnh sửa từng trang

Các trang được viết bằng React JSX (phần cấu trúc HTML nằm trong `.jsx`) và đặt cạnh stylesheet cùng tên. Ví dụ: `pages/student/Schedule.jsx` và `pages/student/Schedule.css`. Landing page được ghép từ các component trong `components/landing/`; mỗi component có stylesheet riêng, ví dụ `RegulationsSection.jsx` và `RegulationsSection.css`. CSS khung dùng chung nằm trong `src/styles/`, còn tuỳ biến riêng của màn hình đặt trong stylesheet của chính trang/component.
