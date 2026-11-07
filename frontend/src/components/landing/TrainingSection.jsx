import React from "react";
import Icon from "../common/Icon.jsx";
import "./TrainingSection.css";

const programs = [
  [
    "Công nghệ thông tin",
    "Nền tảng lập trình, dữ liệu và phát triển phần mềm.",
    "bookopen",
  ],
  [
    "Quản trị kinh doanh",
    "Kiến thức quản trị, vận hành và phát triển tổ chức.",
    "chart",
  ],
  [
    "Đào tạo theo học kỳ",
    "Theo dõi học phần, thời khóa biểu và kết quả trên cùng một cổng.",
    "calendar",
  ],
];

export default function TrainingSection({ onLogin }) {
  return (
    <section className="landing-section training-section" id="training">
      <div className="section-heading">
        <div>
          <span className="section-kicker">CHƯƠNG TRÌNH HỌC</span>
          <h2>Đào tạo gắn với thực tiễn</h2>
        </div>
        <p>
          Thông tin học phần và chương trình được trình bày để người học dễ tra
          cứu, chủ động xây dựng kế hoạch học tập.
        </p>
      </div>
      <div className="program-grid">
        {programs.map(([title, description, icon], index) => (
          <article className="program-card" key={title}>
            <span className="program-number">0{index + 1}</span>
            <span className="program-icon">
              <Icon name={icon} size={22} />
            </span>
            <h3>{title}</h3>
            <p>{description}</p>
            <button onClick={onLogin}>
              Tra cứu trong cổng <Icon name="arrow" size={16} />
            </button>
          </article>
        ))}
      </div>
    </section>
  );
}
