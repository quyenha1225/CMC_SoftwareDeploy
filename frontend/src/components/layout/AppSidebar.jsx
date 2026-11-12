import React, { useState } from "react";
import Icon from "../common/Icon.jsx";
import { MENU } from "./navigation.js";

export default function AppSidebar({
  role,
  page,
  activeProfileSection,
  activeScheduleSection,
  collapsed,
  sidebarOpen,
  noticesCount,
  onNavigate,
  onExpand,
  onClose,
}) {
  const [expandedItem, setExpandedItem] = useState(null);

  return (
    <>
      <aside
        className={`sidebar ${sidebarOpen ? "sidebar-open" : ""} ${
          collapsed ? "sidebar-collapsed" : ""
        }`}
      >
        <div className="brand">
          <div className="brand-logo">
            <Icon name="graduation" size={27} strokeWidth={2} />
          </div>
          <div>
            <strong>
              EduPortal<span>.</span>
            </strong>
            <small>STUDENT MANAGEMENT</small>
          </div>
          <button
            className="sidebar-close icon-button"
            onClick={onClose}
            aria-label="Đóng menu"
          >
            <Icon name="x" />
          </button>
        </div>
        <div className="workspace-label">KHÔNG GIAN LÀM VIỆC</div>
        <div className="workspace">
          <div className="workspace-icon">
            <Icon name="building" size={21} />
          </div>
          <div>
            <b>SMS Campus</b>
            <span>Năm học 2026–2027</span>
          </div>
          <Icon name="down" size={16} />
        </div>
        <div className="menu-group-title">DANH MỤC</div>
        <nav className="navigation" aria-label="Điều hướng chính">
          {MENU[role].map(([label, id, icon, children]) => {
            const isExpanded = expandedItem === id;
            const isActive = page === id;

            return (
              <div className="nav-group" key={id}>
                <button
                  className={`nav-item ${isActive ? "nav-active" : ""}`}
                  onClick={() => {
                    if (children) {
                      if (collapsed) onExpand();
                      setExpandedItem(isExpanded ? null : id);
                      return;
                    }
                    onNavigate(id);
                  }}
                  aria-expanded={children ? isExpanded : undefined}
                  title={collapsed ? label : undefined}
                >
                  <Icon name={icon} size={19} />
                  <span>{label}</span>
                  {id === "notices" && (
                    <i className="nav-bubble">{noticesCount}</i>
                  )}
                  {children && (
                    <Icon
                      name="down"
                      size={15}
                      className={`nav-chevron ${isExpanded ? "is-expanded" : ""}`}
                    />
                  )}
                </button>
                {children && isExpanded && !collapsed && (
                  <div className={`nav-submenu ${id === "schedule" ? "schedule-submenu" : ""}`}>
                    {children.map(([childLabel, childId, childIcon]) => (
                      <button
                        key={childId}
                        className={`nav-subitem ${
                          page === id && (activeProfileSection === childId || activeScheduleSection === childId)
                            ? "nav-subitem-active"
                            : ""
                        }`}
                        onClick={() => onNavigate(childId)}
                        aria-current={page === id && (activeProfileSection === childId || activeScheduleSection === childId) ? "page" : undefined}
                      >
                        {childIcon ? <Icon name={childIcon} size={18} /> : <span className="nav-subitem-dot" />}
                        <span>{childLabel}</span>
                      </button>
                    ))}
                  </div>
                )}
              </div>
            );
          })}
        </nav>
        <div className="sidebar-bottom">
          <div className="sidebar-help">
            <div className="help-art">
              <Icon name="sparkle" size={22} />
            </div>
            <b>Cần hỗ trợ?</b>
            <p>Gửi yêu cầu hỗ trợ đến nhà trường.</p>
            <button onClick={() => onNavigate("requests")}>
              Tạo yêu cầu <Icon name="arrow" size={15} />
            </button>
          </div>
          <div className="sidebar-footer">
            <span className="green-dot" /> EduPortal
          </div>
        </div>
      </aside>
      {sidebarOpen && (
        <button
          className="mobile-overlay"
          aria-label="Đóng menu"
          onClick={onClose}
        />
      )}
    </>
  );
}
