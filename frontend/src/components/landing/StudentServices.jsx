import React from "react";
import Icon from "../common/Icon.jsx";
import "./StudentServices.css";

const services = [
  {
    title: "Đăng ký học phần",
    description: "Tìm lớp, kiểm tra lịch và theo dõi số tín chỉ đã đăng ký.",
    icon: "bookopen",
  },
  {
    title: "Thời khóa biểu",
    description: "Xem lịch học theo tuần, ca học và phòng học.",
    icon: "calendar",
  },
  {
    title: "Kết quả học tập",
    description: "Theo dõi điểm thành phần và kết quả đã công bố.",
    icon: "grades",
  },
  {
    title: "Học phí",
    description: "Tra cứu học phí dự kiến và các khoản đã ghi nhận.",
    icon: "wallet",
  },
  {
    title: "Hồ sơ sinh viên",
    description: "Kiểm tra thông tin cá nhân và thông tin liên hệ.",
    icon: "user",
  },
  {
    title: "Yêu cầu hỗ trợ",
    description: "Gửi câu hỏi và theo dõi phản hồi từ Phòng Đào tạo.",
    icon: "file",
  },
];

export default function StudentServices({ onLogin }) {
  return (
    <section className="landing-section student-section" id="students">
      <div className="section-heading">
        <div>
          <span className="section-kicker">DÀNH CHO SINH VIÊN</span>
          <h2>Mọi thông tin học tập, trong tầm tay</h2>
        </div>
        <p>
          Một nơi để chủ động theo dõi kế hoạch học tập, cập nhật hồ sơ và kết
          nối với nhà trường trong suốt học kỳ.
        </p>
      </div>

      <div className="student-service-grid">
        {services.map((service, index) => (
          <button
            className="student-service-card"
            key={service.title}
            onClick={onLogin}
          >
            <span className="student-service-icon">
              <Icon name={service.icon} size={22} />
            </span>
            <span className="student-service-number">
              {String(index + 1).padStart(2, "0")}
            </span>
            <span className="student-service-title">{service.title}</span>
            <span className="student-service-description">
              {service.description}
            </span>
            <span className="student-service-link">
              Mở chức năng <Icon name="arrow" size={15} />
            </span>
          </button>
        ))}
      </div>

      <div className="student-section-note">
        <span className="student-section-note-icon">
          <Icon name="info" size={18} />
        </span>
        <p>
          Đăng nhập để xem thông tin học tập. Tài khoản được cấp theo hướng dẫn
          của nhà trường.
        </p>
        <button className="button-solid" onClick={onLogin}>
          Vào cổng sinh viên <Icon name="arrow" size={16} />
        </button>
      </div>

      <aside className="student-collab-contact" aria-labelledby="student-collab-title">
        <div className="student-collab-copy">
          <span className="section-kicker">HỖ TRỢ SINH VIÊN</span>
          <h3 id="student-collab-title">Ban Cộng tác Sinh viên</h3>
          <p>
            Liên hệ để được hướng dẫn về hoạt động sinh viên, kết nối cộng đồng
            và các chương trình hỗ trợ.
          </p>
        </div>
        <div className="student-collab-details">
          <a href="mailto:quyenha419@gmail.com">
            <Icon name="mail" size={18} />
            <span><small>Email</small>quyenha419@gmail.com</span>
          </a>
          <a href="tel:0385416387">
            <Icon name="user" size={18} />
            <span><small>Điện thoại</small>0385 416 387</span>
          </a>
          <div>
            <Icon name="building" size={18} />
            <span><small>Văn phòng</small>Tòa JIS HVQ – Hà Đông</span>
          </div>
          <div>
            <Icon name="clock" size={18} />
            <span><small>Thời gian tiếp nhận</small>07:00–19:00</span>
          </div>
          <a href="https://github.com/quyenha1225" target="_blank" rel="noreferrer">
            <Icon name="arrow" size={18} />
            <span><small>Kênh trực tuyến</small>GitHub · quyenha1225</span>
          </a>
        </div>
      </aside>
    </section>
  );
}
