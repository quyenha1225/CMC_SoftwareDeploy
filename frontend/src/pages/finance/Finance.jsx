import React, { useState } from "react";
import { money, semesterLabel, STUDENT_ID } from "../../data/portalData.js";
import { invoices, recordPayment, stamp, uid } from "../../data/workflows.js";
import { Badge, Button, Card, Empty, Field, Modal, PageHeader, Stat } from "../../components/ui.jsx";
import Pagination, { usePagination } from "../../components/common/Pagination.jsx";
import "./Finance.css";

export default function Finance({ state, role, update, notify, navigate }) {
  const student = role === "student";
  const [semester, setSemester] = useState(state.semesters[0]?.id || ""), [search, setSearch] = useState(""), [filter, setFilter] = useState("ALL");
  const [detail, setDetail] = useState(null), [paying, setPaying] = useState(null), [amount, setAmount] = useState("");
  const all = invoices(state).filter(item => (!student || item.studentId === STUDENT_ID) && item.semester === semester);
  const rows = all.filter(item => (filter === "ALL" || item.status === filter) && `${item.id} ${state.students.find(person => person.id === item.studentId)?.name || ""}`.toLowerCase().includes(search.toLowerCase()));
  const page = usePagination(rows, `${semester}:${filter}:${search}`);
  const payments = state.payments.filter(item => item.semester === semester && (!student || item.studentId === STUDENT_ID));
  const history = usePagination(payments, semester);
  const totals = all.reduce((sum, item) => ({ total: sum.total + item.total, paid: sum.paid + item.paid, balance: sum.balance + item.balance }), { total: 0, paid: 0, balance: 0 });
  return <>
    <PageHeader title={student ? "Học phí & hóa đơn" : "Quản lý hóa đơn học phí"} description="Hóa đơn tách theo sinh viên và học kỳ; các khoản thu được liên kết đúng hóa đơn." />
    <div className="finance-filters"><Field label="Học kỳ"><select className="control" value={semester} onChange={event => setSemester(event.target.value)}>{state.semesters.map(item => <option key={item.id} value={item.id}>{semesterLabel(item.id)}</option>)}</select></Field><Field label="Tìm hóa đơn / sinh viên"><input className="control" value={search} onChange={event => setSearch(event.target.value)} /></Field><Field label="Tình trạng"><select className="control" value={filter} onChange={event => setFilter(event.target.value)}><option value="ALL">Tất cả</option><option value="UNPAID">Chưa nộp</option><option value="PARTIAL">Nộp một phần</option><option value="PAID">Đã hoàn tất</option></select></Field></div>
    <div className="stats-grid three"><Stat icon="wallet" label="Tổng học phí" value={money(totals.total)} /><Stat icon="checkcircle" label="Đã ghi nhận" value={money(totals.paid)} tone="green" /><Stat icon="alert" label="Công nợ" value={money(totals.balance)} tone="orange" /></div>
    <Card title="Hóa đơn học kỳ" subtitle="Hóa đơn tự chốt khi ghi nhận khoản thu đầu tiên; sau đó giữ nguyên học phần và đơn giá.">
      <div className="table-wrap"><table className="data-table"><thead><tr><th>Hóa đơn / sinh viên</th><th>Hạn dự kiến</th><th>Tổng tiền</th><th>Đã thu</th><th>Còn nợ</th><th>Trạng thái</th><th>Thao tác</th></tr></thead><tbody>{page.rows.map(item => <tr key={item.id}><td><b>{item.id}</b><small className="cell-sub">{state.students.find(person => person.id === item.studentId)?.name} · {item.studentId}</small></td><td>{state.semesters.find(term => term.id === semester)?.endsOn}</td><td>{money(item.total)}</td><td>{money(item.paid)}</td><td>{money(item.balance)}{item.credit > 0 && <small className="cell-sub">Dư nộp: {money(item.credit)}</small>}</td><td><Badge tone={item.status === "PAID" ? "green" : "amber"}>{({ PAID: "Hoàn tất", PARTIAL: "Một phần", UNPAID: "Chưa nộp" })[item.status]}</Badge></td><td><div className="finance-actions"><Button small kind="outline" onClick={() => setDetail(item)}>Chi tiết</Button>{item.balance > 0 && <Button small onClick={() => student ? navigate("payment") : (setPaying(item), setAmount(String(item.balance)))}>{student ? "Thanh toán" : "Ghi nhận thu"}</Button>}</div></td></tr>)}</tbody></table></div>
      {!rows.length && <Empty title="Chưa có hóa đơn phù hợp" />}<Pagination {...page} />
    </Card>
    <Card title="Lịch sử khoản thu"><div className="table-wrap"><table className="data-table"><thead><tr><th>Mã khoản thu</th><th>Hóa đơn</th><th>Số tiền</th><th>Ngày ghi nhận</th></tr></thead><tbody>{history.rows.map(item => <tr key={item.id}><td>{item.id}</td><td>{item.invoiceId}</td><td>{money(item.amount)}</td><td>{item.date}</td></tr>)}</tbody></table></div>{!payments.length && <Empty title="Chưa có khoản thu" />}<Pagination {...history} /></Card>
    {detail && <Modal title={detail.id} onClose={() => setDetail(null)}><div className="table-wrap"><table className="data-table"><thead><tr><th>Học phần</th><th>Tín chỉ</th><th>Thành tiền</th></tr></thead><tbody>{detail.items.map(item => <tr key={item.section.id}><td>{item.course?.name}<small className="cell-sub">{item.section.code}</small></td><td>{item.course?.credits}</td><td>{money(item.amount)}</td></tr>)}</tbody></table></div><p>Tổng: <strong>{money(detail.total)}</strong></p><p>Đã thu: {money(detail.paid)} · Còn nợ: {money(detail.balance)}</p></Modal>}
    {paying && <Modal title={`Ghi nhận thu · ${paying.studentId}`} subtitle="Kiểm tra số tiền trước khi ghi nhận" onClose={() => setPaying(null)}><form onSubmit={event => { event.preventDefault(); try { const next = recordPayment(state, paying.id, Number(amount)); update(() => next); setPaying(null); notify("Đã ghi nhận khoản thu vào hóa đơn."); } catch(error) { notify(error.message, "error"); } }}><Field label="Số tiền (VND)"><input type="number" className="control" required min={1} max={paying.balance} step={1} value={amount} onChange={event => setAmount(event.target.value)} /></Field><div className="modal-actions"><Button kind="outline" onClick={() => setPaying(null)}>Hủy</Button><Button type="submit">Xác nhận ghi nhận</Button></div></form></Modal>}
  </>;
}
