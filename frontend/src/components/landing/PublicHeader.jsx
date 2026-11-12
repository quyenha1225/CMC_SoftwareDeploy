import React, { useEffect, useState } from "react";
import Icon from "../common/Icon.jsx";
import "./PublicHeader.css";

export default function PublicHeader({ onLogin, onBack, onApply, onSearch, sqlOnly=false }) {
  const [menuOpen, setMenuOpen] = useState(false);
  const [searchOpen, setSearchOpen] = useState(false), [query, setQuery] = useState("");
  const [activeSection, setActiveSection] = useState("");

  useEffect(() => {
    if (onBack) return undefined;
    const sections = ["training", "students", "events", "regulations", "guide"]
      .map((id) => document.getElementById(id))
      .filter(Boolean);
    if (!sections.length) return undefined;

    const observer = new IntersectionObserver(
      (entries) => {
        const visibleSections = entries
          .filter((entry) => entry.isIntersecting)
          .sort((a, b) => b.intersectionRatio - a.intersectionRatio);
        if (visibleSections[0]) setActiveSection(visibleSections[0].target.id);
      },
      { rootMargin: "-100px 0px -55% 0px", threshold: [0, 0.15, 0.35] },
    );
    sections.forEach((section) => observer.observe(section));
    return () => observer.disconnect();
  }, [onBack]);

  return (
    <header className={`public-header ${onBack ? "login-header" : ""}`}>
      <a
        className="site-brand"
        href="#top"
        onClick={
          onBack
            ? (event) => {
                event.preventDefault();
                onBack();
              }
            : undefined
        }
      >
        <span className="site-brand-mark">
          <Icon name="graduation" size={23} />
        </span>
        <span>
          EduPortal<small>CỔNG THÔNG TIN ĐÀO TẠO</small>
        </span>
      </a>
      {onBack ? (
        <button className="login-back" onClick={onBack}>
          <Icon name="arrow" size={16} /> Trang chủ
        </button>
      ) : (
        <>
          <nav
            className={`public-nav ${menuOpen ? "public-nav-open" : ""}`}
            aria-label="Điều hướng trang chủ"
          >
            {!sqlOnly&&<a href="#events" className={activeSection === "events" ? "nav-active" : ""} onClick={() => setMenuOpen(false)}>Tin tức & Sự kiện</a>}
            <a
              href="#training"
              className={activeSection === "training" ? "nav-active" : ""}
              onClick={() => setMenuOpen(false)}
            >
              Đào tạo
            </a>
            <a
              href="#students"
              className={activeSection === "students" ? "nav-active" : ""}
              onClick={() => setMenuOpen(false)}
            >
              Sinh viên
            </a>
            <a
              href="#regulations"
              className={activeSection === "regulations" ? "nav-active" : ""}
              onClick={() => setMenuOpen(false)}
            >
              Quy chế
            </a>
            <a
              href="#guide"
              className={activeSection === "guide" ? "nav-active" : ""}
              onClick={() => setMenuOpen(false)}
            >
              Hướng dẫn
            </a>
            {onApply && <button className="public-apply-link" onClick={() => { setMenuOpen(false); onApply(); }}>Nộp hồ sơ trực tuyến</button>}
          </nav>
          <div className="public-header-actions">
            {onSearch && <button className="public-search-toggle" aria-label="Tìm thông tin nhà trường" aria-expanded={searchOpen} aria-controls="public-search-bar" onClick={() => setSearchOpen(!searchOpen)}><Icon name="search" size={20} /></button>}
            <button className="public-login-button" onClick={onLogin}>
              Đăng nhập <Icon name="arrow" size={17} />
            </button>
            {!onBack && (
              <button
                className="public-menu-toggle"
                aria-label={menuOpen ? "Đóng điều hướng" : "Mở điều hướng"}
                aria-expanded={menuOpen}
                onClick={() => setMenuOpen((open) => !open)}
              >
                <Icon name={menuOpen ? "x" : "menu"} size={20} />
              </button>
            )}
          </div>
          {searchOpen && onSearch && <form className="public-header-search" id="public-search-bar" role="search" onSubmit={event => { event.preventDefault(); onSearch(query); setSearchOpen(false); setMenuOpen(false); }}><label htmlFor="public-query">Tìm tin tức, hội thảo và thông báo</label><div><input id="public-query" type="search" autoFocus value={query} onChange={event => setQuery(event.target.value)} placeholder="Nhập thông tin bạn quan tâm…" /><button type="submit">Tìm kiếm</button><button type="button" aria-label="Đóng tìm kiếm" onClick={() => setSearchOpen(false)}><Icon name="x" size={17} /></button></div></form>}
        </>
      )}
    </header>
  );
}
