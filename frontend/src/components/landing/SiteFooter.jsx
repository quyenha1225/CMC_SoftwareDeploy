import React from "react";
import Icon from "../common/Icon.jsx";
import "./SiteFooter.css";

export default function SiteFooter() {
  return (
    <footer className="site-footer">
      <div className="site-footer-main">
        <div className="site-footer-about">
          <a className="site-brand site-footer-brand" href="#top">
            <span className="site-brand-mark">
              <Icon name="graduation" size={22} />
            </span>
            <span>
              EduPortal<small>CỔNG THÔNG TIN ĐÀO TẠO</small>
            </span>
          </a>
          <p>
            Không gian tra cứu học tập và kết nối giữa nhà trường với người học.
          </p>
        </div>
        <div className="site-footer-contact">
          <h2>Liên hệ</h2>
          <p>
            <Icon name="building" size={17} /> Tòa JIS HVQ – Hà Đông
          </p>
          <p>
            <Icon name="mail" size={17} />{" "}
            <a href="mailto:quyenha419@gmail.com">quyenha419@gmail.com</a>
          </p>
          <p>
            <Icon name="user" size={17} />{" "}
            <a href="tel:0385416387">0385 416 387 · 07:00–19:00</a>
          </p>
        </div>
        <div className="site-footer-links">
          <h2>Tra cứu nhanh</h2>
          <a href="#training">Đào tạo</a>
          <a href="#regulations">Quy chế</a>
          <a href="#guide">Hướng dẫn sử dụng</a>
        </div>
      </div>
      <div className="site-footer-bottom">
        <span>© 2026 EduPortal</span>
        <span>
          Thông tin chính thức được cập nhật theo thông báo của nhà trường.
        </span>
      </div>
    </footer>
  );
}
