import React from "react";
import Icon from "../common/Icon.jsx";
import { ROLE_NAMES } from "../../data/portalData.js";
import { Avatar } from "../ui.jsx";

export default function AppHeader({
  pageTitle,
  account,
  role,
  search,
  alerts,
  announcements,
  onSearch,
  onClearSearch,
  onSearchKeyDown,
  onRoleChange,
  onAlertToggle,
  onNavigate,
  onHome,
  onLogout,
  onMenuToggle,
  sidebarCollapsed,
  sidebarOpen,
}) {
  return (
    <header className="topbar">
      <div className="topbar-left">
        <button
          className="icon-button sidebar-toggle"
          onClick={onMenuToggle}
          aria-label={
            sidebarOpen
              ? "Đóng menu"
              : sidebarCollapsed
                ? "Mở rộng menu"
                : "Thu gọn menu"
          }
          title={
            sidebarCollapsed
              ? "Mở rộng menu"
              : sidebarOpen
                ? "Đóng menu"
                : "Thu gọn menu"
          }
        >
          <Icon name="menu" />
        </button>
        <button
          className="portal-home-button"
          onClick={onHome}
          aria-label="Về trang chủ"
        >
          <Icon name="home" size={17} />
          <span>Trang chủ</span>
        </button>
        <div className="breadcrumb">
          <Icon name="chevron" size={14} />
          <span>{pageTitle}</span>
        </div>
      </div>
      <div className="topbar-right">
        <div className="demo-label">
          <span className="green-dot" /> Cổng học vụ
        </div>
        <div className="head-search">
          <Icon name="search" size={18} />
          <input
            value={search}
            placeholder="Tìm nhanh chức năng..."
            onChange={onSearch}
            onKeyDown={onSearchKeyDown}
          />
          {search && (
            <button onClick={onClearSearch} aria-label="Xóa tìm kiếm">
              <Icon name="x" size={13} />
            </button>
          )}
        </div>
        <div className="notification-wrap">
          <button
            className="icon-button notification-button"
            aria-label="Thông báo"
            onClick={onAlertToggle}
          >
            <Icon name="bell" size={21} />
            <span className="notif-dot" />
          </button>
          {alerts && (
            <div className="notif-popup">
              <div>
                <b>Thông báo</b>
                <button onClick={() => onNavigate("notices")}>
                  Xem tất cả
                </button>
              </div>
              {announcements.slice(0, 3).map((notice) => (
                <button key={notice.id} onClick={() => onNavigate("notices")}>
                  <span className="popup-dot" />
                  {notice.title}
                </button>
              ))}
            </div>
          )}
        </div>
        <span className="topbar-sep" />
        <Avatar name={account.name} size="sm" />
        <div className="account-switch">
          <select
            value={role}
            onChange={(event) => onRoleChange(event.target.value)}
            aria-label="Vai trò làm việc"
          >
            {Object.entries(ROLE_NAMES).map(([key, name]) => (
              <option value={key} key={key}>
                {name}
              </option>
            ))}
          </select>
          <span>{account.name}</span>
        </div>
        <button
          className="icon-button logout-button"
          onClick={onLogout}
          aria-label="Đăng xuất"
          title="Đăng xuất"
        >
          <Icon name="logout" size={18} />
        </button>
      </div>
    </header>
  );
}
