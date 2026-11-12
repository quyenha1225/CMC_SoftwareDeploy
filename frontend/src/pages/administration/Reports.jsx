import React, { useState } from "react";
import { money, semesterLabel, gradeTotal } from "../../data/portalData.js";
import { invoices, stamp, uid } from "../../data/workflows.js";
import { Button, Card, Field, PageHeader, Stat, Empty, csvDownload } from "../../components/ui.jsx";
import Pagination, { usePagination } from "../../components/common/Pagination.jsx";
import "./Reports.css";

export default function Reports({ state, update, notify }) {
  const [semester, setSemester] = useState(state.semesters[0]?.id || "");
  const sections = state.sections.filter(item => item.semester === semester);
  const ids = new Set(sections.map(item => item.id));
  const enrollments = state.enrollments.filter(item => ids.has(item.sectionId));
  const studentCount = new Set(enrollments.map(item => item.studentId)).size;
  const publishedIds = new Set(state.gradeSheets.filter(item => ids.has(item.sectionId) && item.status === "PUBLISHED").map(item => item.sectionId));
  const grades = state.grades.filter(item => publishedIds.has(item.sectionId) && gradeTotal(item) !== null);
  const bills = invoices(state).filter(item => item.semester === semester);
  const totals = bills.reduce((sum, item) => ({ total: sum.total + item.total, paid: sum.paid + item.paid, debt: sum.debt + item.balance }), { total: 0, paid: 0, debt: 0 });
  const summary = { semester, students: studentCount, sections: sections.length, registrations: enrollments.length, published: publishedIds.size, passRate: grades.length ? `${Math.round(grades.filter(item => gradeTotal(item) >= 5).length / grades.length * 100)}%` : "Chưa có điểm", ...totals };
  const snapshots = state.semesterReports.filter(item => item.semester === semester).slice().reverse();
  const page = usePagination(snapshots, semester);
  function exportSummary(data) { csvDownload(`bao-cao-${data.semester}.csv`, [["Học kỳ", "Sinh viên", "Lớp học phần", "Lượt đăng ký", "Đã công bố", "Tỷ lệ đạt", "Học phí", "Đã thu", "Còn nợ"], [data.semester, data.students, data.sections, data.registrations, data.published, data.passRate, data.total, data.paid, data.debt]]); }
  return <>
    <PageHeader title="Báo cáo học kỳ" description="Tổng hợp đăng ký học phần, điểm đã công bố và hóa đơn theo học kỳ." action={<Button kind="outline" icon="download" onClick={() => exportSummary(summary)}>Xuất CSV hiện tại</Button>} />
    <Field label="Học kỳ"><select className="control" value={semester} onChange={event => setSemester(event.target.value)}>{state.semesters.map(item => <option key={item.id} value={item.id}>{semesterLabel(item.id)}</option>)}</select></Field>
    <div className="stats-grid"><Stat icon="users" label="Sinh viên đăng ký" value={String(studentCount)} /><Stat icon="bookopen" label="Lớp học phần" value={String(sections.length)} /><Stat icon="grades" label="Tỷ lệ đạt môn" value={summary.passRate} hint="Điểm đã công bố, tổng kết ≥ 5" /><Stat icon="wallet" label="Công nợ học kỳ" value={money(totals.debt)} /></div>
    <Card title="Tổng hợp học kỳ" extra={<Button onClick={() => { update(previous => ({ ...previous, semesterReports: [...previous.semesterReports, { ...summary, id: uid("REPORT"), createdAt: stamp() }] })); notify("Đã lưu bản chốt báo cáo. Dữ liệu sau này không làm thay đổi bản đã lưu."); }}>Lưu bản chốt báo cáo</Button>}><div className="text-rows"><p>Lượt đăng ký: <strong>{summary.registrations}</strong></p><p>Bảng điểm đã công bố: <strong>{summary.published} / {summary.sections}</strong></p><p>Học phí: <strong>{money(totals.total)}</strong></p><p>Đã ghi nhận thu: <strong>{money(totals.paid)}</strong></p></div></Card>
    <Card title="Các bản báo cáo đã chốt"><div className="table-wrap"><table className="data-table"><thead><tr><th>Mã báo cáo</th><th>Ngày chốt</th><th>Sinh viên</th><th>Học phí</th><th>Đã thu</th><th>Còn nợ</th><th>Xuất</th></tr></thead><tbody>{page.rows.map(item => <tr key={item.id}><td>{item.id}</td><td>{item.createdAt}</td><td>{item.students}</td><td>{money(item.total)}</td><td>{money(item.paid)}</td><td>{money(item.debt)}</td><td><Button small kind="outline" onClick={() => exportSummary(item)}>CSV</Button></td></tr>)}</tbody></table></div>{!snapshots.length && <Empty title="Chưa chốt báo cáo học kỳ này" />}<Pagination {...page} /></Card>
  </>;
}
