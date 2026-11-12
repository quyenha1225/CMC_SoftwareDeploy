# Frontend EduPortal

Cấu hình host, port và backend proxy tại `.env.local`, theo mẫu `.env.example`. Xem [cấu hình môi trường](../docs/CAU_HINH_ENV.md). Không lưu bí mật backend trong frontend.

```powershell
npm.cmd ci
npm.cmd run dev -- --host 127.0.0.1
npm.cmd run build
```

Node.js 22.12+ hoặc 24. Backend chạy cổng 8081; Vite chuyển `/api` tới backend. Xem [hướng dẫn đầy đủ](../Readme.md).

Điểm vào hiện tại: `src/main.jsx` → `src/v6/AppV6.jsx`. Dữ liệu lấy từ API, đăng nhập bằng phiên server, danh sách phân trang và tìm kiếm phía server. Không dùng localStorage làm nguồn quyền hay dữ liệu nghiệp vụ.

Các trang và test localStorage trước V6 được giữ để tham khảo; không còn là runtime chính. Chạy `npm.cmd run test:legacy` khi cần kiểm tra riêng mã cũ.
