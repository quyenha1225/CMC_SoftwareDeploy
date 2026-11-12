import React from "react";
import { Badge, Button, Card, Stat } from "../../../components/ui.jsx";
import Icon from "../../../components/common/Icon.jsx";
import { invoices } from "../../../data/workflows.js";
import { money } from "../../../data/portalData.js";
import "./AdminDashboard.css";

export default function AdminDashboard({ state, navigate, account }) {
  const applications = state.studentApprovals.filter(item => item.status === "PENDING");
  const sheets = state.gradeSheets.filter(item => item.status === "VERIFIED");
  const debt = invoices(state).reduce((sum, item) => sum + item.balance, 0);
  const tasks = [
    { title: "Duyệt hồ sơ nhập học", count: applications.length, icon: "file", page: "student-approvals", description: "Hồ sơ đã được đơn vị phụ trách trình duyệt." },
    { title: "Phê duyệt bảng điểm", count: sheets.length, icon: "grades", page: "approvals", description: "Bảng điểm đã qua kiểm tra của Phòng Đào tạo." },
    { title: "Quản lý tài khoản", count: state.users.length, icon: "shield", page: "accounts", description: "Theo dõi tài khoản, trạng thái và vai trò trong hệ thống." },
  ];
  return <div className="admin-dashboard">
    <section className="admin-welcome"><div><span className="admin-eyebrow">KHÔNG GIAN ĐIỀU HÀNH · NHÀ TRƯỜNG</span><h1>Tổng quan quản trị</h1><p>Xin chào {account.name}. Theo dõi hoạt động và xử lý các hồ sơ cần phê duyệt.</p><Button icon="chart" onClick={() => navigate("reports")}>Xem báo cáo học kỳ</Button></div><div className="admin-welcome-mark" aria-hidden="true"><Icon name="building" size={90} /></div></section>
    <div className="stats-grid"><Stat icon="users" label="Sinh viên toàn trường" value={String(state.students.length)} /><Stat icon="file" label="Hồ sơ chờ phê duyệt" value={String(applications.length)} tone="orange" /><Stat icon="grades" label="Bảng điểm cần duyệt" value={String(sheets.length)} tone="purple" /><Stat icon="wallet" label="Công nợ toàn trường" value={money(debt)} hint="Tổng hợp các học kỳ" /></div>
    <div className="admin-task-grid">{tasks.map(task => <Card key={task.page} className="admin-task"><span className="admin-task-icon"><Icon name={task.icon} size={24} /></span><div className="admin-task-title"><h2>{task.title}</h2><Badge tone={task.count ? "amber" : "green"}>{task.count}</Badge></div><p>{task.description}</p><Button kind="outline" onClick={() => navigate(task.page)}>Mở quản lý <Icon name="arrow" size={16} /></Button></Card>)}</div>
    <Card title="Hoạt động gần đây" subtitle="Kết quả phê duyệt và ghi nhận trong dữ liệu hiện tại"><div className="admin-activity">{state.studentApprovals.filter(item => item.status !== "PENDING").slice(-5).reverse().map(item => <div key={item.id}><Icon name="checkcircle" size={19} /><span><b>{item.student.name}</b><small>{item.status === "APPROVED" ? "Đã duyệt hồ sơ" : "Đã từ chối hồ sơ"} · {item.reviewedAt}</small></span></div>)}{!state.studentApprovals.some(item => item.status !== "PENDING") && <p>Chưa có hồ sơ đã xử lý. Các hoạt động mới sẽ hiển thị tại đây.</p>}</div></Card>
  </div>;
}
