import React from "react";
import Icon from "../common/Icon.jsx";
import "./UsageGuide.css";

const steps = [
  [
    "Đăng nhập",
    "Chọn nhóm người dùng để mở không gian phù hợp với sinh viên, giảng viên hoặc cán bộ.",
  ],
  [
    "Chọn chức năng",
    "Dùng thanh điều hướng để mở đăng ký học phần, lịch học, điểm hoặc các nghiệp vụ liên quan.",
  ],
  [
    "Kiểm tra cập nhật",
    "Xem mục thông báo để theo dõi các nội dung mới và lưu ý trong học kỳ.",
  ],
];

export default function UsageGuide({ onLogin }) {
  return (
    <section className="landing-section guide-section" id="guide">
      <div className="section-heading">
        <div>
          <span className="section-kicker">BẮT ĐẦU SỬ DỤNG</span>
          <h2>Hướng dẫn nhanh</h2>
        </div>
        <p>Ba bước để làm quen với cổng thông tin và các chức năng học vụ.</p>
      </div>
      <div className="guide-grid">
        {steps.map(([title, description], index) => (
          <article key={title}>
            <span>0{index + 1}</span>
            <h3>{title}</h3>
            <p>{description}</p>
          </article>
        ))}
      </div>
      <div className="guide-callout">
        <Icon name="info" size={18} />
        <p>
          Liên hệ bộ phận hỗ trợ khi cần hướng dẫn về tài khoản hoặc thông tin học vụ.
        </p>
        <button onClick={onLogin}>
          Đăng nhập <Icon name="arrow" size={16} />
        </button>
      </div>
    </section>
  );
}
