import React, { useState } from "react";
import "./Login.css";
import Icon from "../../components/common/Icon.jsx";
import { ACCOUNTS, ROLE_NAMES } from "../../data/portalData.js";
import SiteFooter from "../../components/landing/SiteFooter.jsx";
import PublicHeader from "../../components/landing/PublicHeader.jsx";
import "../../styles/public-site.css";

export default function Login({ onBack, onLogin }) {
  const [role, setRole] = useState("student");
  const [email, setEmail] = useState(ACCOUNTS[0].email);
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");

  function submit(event) {
    event.preventDefault();
    if (!email.trim() || !password.trim()) {
      setError("Vui lòng nhập email và mật khẩu để tiếp tục.");
      return;
    }
    onLogin(role);
  }

  return (
    <div className="public-site login-site">
      <PublicHeader onBack={onBack} />
      <main className="login-main">
        <section className="login-card">
          <span className="section-kicker">KHU VỰC NGƯỜI DÙNG</span>
          <h1>Đăng nhập</h1>
          <p className="login-intro">
            Đăng nhập để tiếp tục đến không gian học vụ của bạn.
          </p>
          <form onSubmit={submit}>
            <label className="login-field">
              Vai trò
              <select
                value={role}
                onChange={(event) => setRole(event.target.value)}
              >
                {Object.entries(ROLE_NAMES).map(([key, name]) => (
                  <option value={key} key={key}>
                    {name}
                  </option>
                ))}
              </select>
            </label>
            <label className="login-field">
              Email
              <span className="login-input">
                <Icon name="mail" size={17} />
                <input
                  type="email"
                  autoComplete="username"
                  value={email}
                  onChange={(event) => setEmail(event.target.value)}
                  placeholder="name@school.edu.vn"
                  required
                />
              </span>
            </label>
            <label className="login-field">
              Mật khẩu
              <input
                type="password"
                autoComplete="current-password"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                placeholder="Nhập mật khẩu"
                required
              />
            </label>
            {error && (
              <p className="login-error" role="alert">
                {error}
              </p>
            )}
            <button className="button-solid login-submit" type="submit">
              Đăng nhập <Icon name="arrow" size={17} />
            </button>
          </form>
          <div className="login-demo-note">
            <Icon name="info" size={17} />
            <p>
              Giao diện đăng nhập đang ở chế độ demo. Email và mật khẩu không
              được gửi đi hoặc xác thực.
            </p>
          </div>
        </section>
        <aside className="login-side">
          <span className="section-kicker">CỔNG THÔNG TIN HỌC VỤ</span>
          <h2>
            Một điểm đến
            <br />
            cho hành trình học tập.
          </h2>
          <p>
            Tra cứu lịch học, kết quả và thông tin học vụ trong không gian tập
            trung.
          </p>
          <div className="login-side-rule" />
          <span>TRƯỜNG HVQ JISS · HÀ ĐÔNG</span>
        </aside>
      </main>
      <SiteFooter />
    </div>
  );
}
