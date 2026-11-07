import React from "react";
import Icon from "../common/Icon.jsx";
import campusPhoto from "../../assets/campus.jpg";
import "./LandingHero.css";

export default function LandingHero({ onLogin }) {
  return (
    <section className="landing-hero">
      <div className="landing-hero-copy">
        <span className="section-kicker">TRƯỜNG HVQ JISS · HÀ ĐÔNG</span>
        <h1>
          Học tập vững nền tảng.
          <br />
          <span>Vươn xa bằng tri thức.</span>
        </h1>
        <p>
          Tra cứu thông tin học vụ, theo dõi tiến độ học tập và kết nối với nhà
          trường trong một không gian rõ ràng, thuận tiện.
        </p>
        <div className="landing-actions">
          <button className="button-solid" onClick={onLogin}>
            Vào cổng đào tạo <Icon name="arrow" size={17} />
          </button>
          <a className="button-text" href="#training">
            Tìm hiểu chương trình <Icon name="chevron" size={15} />
          </a>
        </div>
        <div className="landing-meta">
          <span className="status-mark" />
          Học kỳ I · Năm học 2026–2027
        </div>
      </div>
      <figure className="landing-hero-art">
        <img src={campusPhoto} alt="Khuôn viên trường đại học giữa hàng cây" />
        <figcaption className="campus-caption">
          <span className="campus-caption-icon"><Icon name="graduation" size={26} /></span>
          <span><small>KHÔNG GIAN TRI THỨC</small><strong>Kết nối hôm nay. Kiến tạo ngày mai.</strong></span>
        </figcaption>
      </figure>
    </section>
  );
}
