import React from "react";
import Icon from "./common/Icon.jsx";
import {
  ROLE_NAMES,
  ACCOUNTS,
  STUDENT_ID,
  WEEKDAYS,
  COURSE_LIST,
  initialState,
  getCourse,
  getSection,
  getGradeSheet,
  gradeTotal,
  courseLabel,
  money,
  gradeStatusText,
  requestStatusText,
  studentStatusText,
  PRICE_PER_CREDIT,
} from "../data/portalData.js";

export const STORAGE_KEY = "sms-portal-demo-v1";
export const ROLE_KEY = "sms-portal-role-v1";
export const todayVN = () => new Date().toLocaleDateString("vi-VN");
export const number = (n) => new Intl.NumberFormat("vi-VN").format(n);
export const initial = () => {
  try {
    const s = localStorage.getItem(STORAGE_KEY);
    if (!s) return structuredClone(initialState);
    const savedState = {
      ...structuredClone(initialState),
      ...JSON.parse(s),
    };
    savedState.users = (savedState.users || []).filter(
      (user) => user.role !== "admin",
    );
    savedState.announcements = (savedState.announcements || []).map((notice) => ({
      ...notice,
      audience: notice.audience || "all",
    }));
    savedState.sections = savedState.sections.map((section) => ({
      ...section,
      semester:
        getCourse(section.courseId)?.semester || section.semester || "2026-1",
    }));
    return savedState;
  } catch {
    return structuredClone(initialState);
  }
};
export const displayDay = (d) => WEEKDAYS[d - 1] || "Lịch học";
export const slot = (s) => `${displayDay(s.day)}, ${s.start}–${s.end}`;
export const colorByStatus = (s) =>
  [
    "PUBLISHED",
    "APPROVED",
    "DONE",
    "ACTIVE",
    "STUDYING",
    "REGISTERED",
  ].includes(s)
    ? "green"
    : ["VERIFIED", "PROCESSING", "SUBMITTED"].includes(s)
      ? "blue"
      : ["RETURNED", "REJECTED", "SUSPENDED", "CANCELLED"].includes(s)
        ? "red"
        : "amber";
export const csvDownload = (filename, rows) => {
  const escape = (s) => '"' + String(s ?? "").replace(/"/g, '""') + '"';
  const csv = "\ufeff" + rows.map((r) => r.map(escape).join(",")).join("\r\n");
  const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
};

export function Badge({ children, tone = "gray", dot = false }) {
  return (
    <span className={`badge badge-${tone}`}>
      {dot && <i className="badge-dot" />}
      {children}
    </span>
  );
}
export function Button({
  children,
  kind = "primary",
  icon,
  small = false,
  onClick,
  disabled = false,
  type = "button",
  className = "",
}) {
  return (
    <button
      className={`btn btn-${kind} ${small ? "btn-sm" : ""} ${className}`}
      onClick={onClick}
      disabled={disabled}
      type={type}
    >
      {icon && <Icon name={icon} size={small ? 15 : 17} />}
      <span>{children}</span>
    </button>
  );
}
export function Card({
  children,
  title,
  subtitle,
  extra,
  className = "",
  id,
}) {
  return (
    <section className={`card ${className}`} id={id}>
      {(title || extra) && (
        <div className="card-head">
          <div>
            <h3>{title}</h3>
            {subtitle && <p>{subtitle}</p>}
          </div>
          {extra}
        </div>
      )}
      {children}
    </section>
  );
}
export function PageHeader({ title, description, action, eyebrow }) {
  return (
    <div className="page-header">
      <div>
        {eyebrow && <div className="eyebrow">{eyebrow}</div>}
        <h1>{title}</h1>
        {description && <p>{description}</p>}
      </div>
      {action && <div className="page-actions">{action}</div>}
    </div>
  );
}
export function Avatar({ name, size = "md" }) {
  return (
    <span className={`avatar avatar-${size}`} aria-label={name}>
      {(name || "U")
        .split(" ")
        .slice(-2)
        .map((s) => s[0])
        .join("")
        .toUpperCase()}
    </span>
  );
}
export function Stat({ icon, label, value, hint, tone = "blue" }) {
  return (
    <div className="stat">
      <div className={`stat-icon stat-${tone}`}>
        <Icon name={icon} size={22} />
      </div>
      <div className="stat-content">
        <span className="stat-label">{label}</span>
        <strong>{value}</strong>
        <span className="stat-hint">{hint}</span>
      </div>
    </div>
  );
}
export function Empty({
  icon = "file",
  title = "Chưa có dữ liệu",
  description,
}) {
  return (
    <div className="empty-state">
      <div className="empty-icon">
        <Icon name={icon} size={28} />
      </div>
      <strong>{title}</strong>
      {description && <p>{description}</p>}
    </div>
  );
}
export function Modal({ title, subtitle, children, onClose, wide = false }) {
  return (
    <div
      className="modal-backdrop"
      onMouseDown={(e) => e.target === e.currentTarget && onClose()}
    >
      <div
        className={`modal ${wide ? "modal-wide" : ""}`}
        role="dialog"
        aria-modal="true"
        aria-label={title}
      >
        <div className="modal-head">
          <div>
            <h2>{title}</h2>
            {subtitle && <p>{subtitle}</p>}
          </div>
          <button className="icon-button" onClick={onClose} aria-label="Đóng">
            <Icon name="x" />
          </button>
        </div>
        <div className="modal-body">{children}</div>
      </div>
    </div>
  );
}
export function Field({ label, children, hint }) {
  return (
    <label className="field">
      <span>{label}</span>
      {children}
      {hint && <small>{hint}</small>}
    </label>
  );
}
export function LevelBar({ value = 0, color = "#4165e8" }) {
  return (
    <div className="progress-track">
      <div
        className="progress-fill"
        style={{
          width: `${Math.min(100, Math.max(0, value))}%`,
          background: color,
        }}
      />
    </div>
  );
}
export function GradeChip({ score }) {
  if (score === null || score === undefined)
    return <span className="muted">—</span>;
  return (
    <span
      className={`grade-chip ${score >= 8 ? "excellent" : score >= 6.5 ? "good" : "average"}`}
    >
      {score.toFixed(1)}
    </span>
  );
}
export function TextRows({ rows }) {
  return (
    <div className="detail-list">
      {rows.map(([key, val]) => (
        <div key={key}>
          <span>{key}</span>
          <b>{val}</b>
        </div>
      ))}
    </div>
  );
}
export function Donut({ percent, label }) {
  return (
    <div
      className="donut"
      style={{ "--percent": `${Math.max(0, Math.min(100, percent))}%` }}
    >
      <div>
        <strong>{percent}%</strong>
        <span>{label}</span>
      </div>
    </div>
  );
}
export function AreaChart({
  values = [42, 50, 55, 48, 66, 70, 78, 74, 86, 90, 93, 99],
}) {
  const w = 660,
    h = 195,
    min = Math.min(...values) - 10,
    max = Math.max(...values) + 8;
  const pts = values.map((v, i) => [
    18 + (i * (w - 36)) / (values.length - 1),
    h - 18 - ((v - min) / (max - min)) * (h - 38),
  ]);
  return (
    <div className="area-chart">
      <svg viewBox={`0 0 ${w} ${h}`} preserveAspectRatio="none">
        <defs>
          <linearGradient id="chartgrad" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" stopColor="#5376ea" stopOpacity=".27" />
            <stop offset="1" stopColor="#5376ea" stopOpacity="0" />
          </linearGradient>
        </defs>
        {[32, 72, 112, 152].map((y) => (
          <line
            key={y}
            x1="0"
            x2={w}
            y1={y}
            y2={y}
            stroke="#e8ecf3"
            strokeDasharray="4 5"
          />
        ))}
        <path
          d={
            `M${pts[0][0]} ${h} ` +
            pts.map(([x, y]) => `L${x} ${y}`).join(" ") +
            ` L${pts.at(-1)[0]} ${h} Z`
          }
          fill="url(#chartgrad)"
        />
        <polyline
          points={pts.map((p) => p.join(",")).join(" ")}
          fill="none"
          stroke="#4e6ee8"
          strokeWidth="3.5"
          strokeLinecap="round"
          strokeLinejoin="round"
          vectorEffect="non-scaling-stroke"
        />
        {pts.map(([x, y], i) => (
          <circle
            key={i}
            cx={x}
            cy={y}
            r={i === pts.length - 1 ? 5 : 3}
            fill="#fff"
            stroke="#4e6ee8"
            strokeWidth="2"
          />
        ))}
      </svg>
      <div className="chart-labels">
        {[
          "T1",
          "T2",
          "T3",
          "T4",
          "T5",
          "T6",
          "T7",
          "T8",
          "T9",
          "T10",
          "T11",
          "T12",
        ].map((m) => (
          <span key={m}>{m}</span>
        ))}
      </div>
    </div>
  );
}
