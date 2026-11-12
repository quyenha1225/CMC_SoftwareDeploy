import React, { useState } from "react";
import PublicHeader from "../../../components/landing/PublicHeader.jsx";
import "../Login.css";

export default function ForgotPassword({ onBack, onLogin }) {
  const [email, setEmail] = useState("");
  const [sent, setSent] = useState(false);
  return <div className="public-site recovery-site">
    <PublicHeader onBack={onBack} />
    <main className="recovery-main"><section className="login-card">
      <span className="section-kicker">HỖ TRỢ TÀI KHOẢN</span>
      <h1>Quên mật khẩu</h1>
      {sent ? <div role="status"><p>Email cần hỗ trợ: <strong>{email}</strong>.</p><p>Liên hệ bộ phận quản trị để xác minh tài khoản và được hướng dẫn khôi phục mật khẩu.</p><button className="button-solid" onClick={onLogin}>Quay lại đăng nhập</button><button className="auth-text-button" onClick={() => setSent(false)}>Nhập email khác</button></div> : <form onSubmit={event => { event.preventDefault(); setSent(true); }}>
        <p className="login-intro">Nhập email đã đăng ký để yêu cầu khôi phục tài khoản.</p>
        <label className="login-field">Email đăng ký<input type="email" required value={email} onChange={event => setEmail(event.target.value)} autoComplete="email" placeholder="name@school.edu.vn" /></label>
        <button type="submit" className="button-solid login-submit">Gửi yêu cầu khôi phục</button>
        <button type="button" className="auth-text-button" onClick={onLogin}>Quay lại đăng nhập</button>
      </form>}
    </section></main>
  </div>;
}
