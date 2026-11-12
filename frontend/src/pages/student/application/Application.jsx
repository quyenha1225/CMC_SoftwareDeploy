import React, { useState } from "react";
import { STUDENT_ID } from "../../../data/portalData.js";
import { Button, Card, Field, PageHeader, Badge } from "../../../components/ui.jsx";
import ApplicationDetail from "./ApplicationDetail.jsx";
import { APPLICATION_STATUS, DOCUMENT_TYPES, ALLOWED_TYPES, MAX_DOCUMENT_BYTES, MAX_TOTAL_BYTES } from "./applicationData.js";
import "./Application.css";
import Pagination, { usePagination } from "../../../components/common/Pagination.jsx";

const blank = { name: "", email: "", phone: "", address: "", major: "Công nghệ thông tin", identityNumber: "", identityDate: "", identityPlace: "", highSchool: "", graduationYear: "" };
const readFile = file => new Promise((resolve, reject) => { const reader = new FileReader(); reader.onload = () => resolve(reader.result); reader.onerror = () => reject(new Error("Không đọc được tệp.")); reader.readAsDataURL(file); });

export default function Application({ state, update, student = false }) {
  const [ownerToken] = useState(() => {
    const saved = localStorage.getItem("sms-application-owner");
    if (saved) return saved;
    const token = crypto.randomUUID();
    localStorage.setItem("sms-application-owner", token);
    return token;
  });
  const [form, setForm] = useState(blank), [documents, setDocuments] = useState([]);
  const [error, setError] = useState(""), [busy, setBusy] = useState(false), [receipt, setReceipt] = useState(null);
  const [editing, setEditing] = useState(null), [detail, setDetail] = useState(null), [fileKey, setFileKey] = useState(0);
  const mine = (state.applications || []).filter(item => student ? item.studentId === STUDENT_ID : item.ownerToken === ownerToken);
  const pagination = usePagination(mine);
  async function choose(kind, file) {
    setError("");
    if (!file) { setDocuments(previous => previous.filter(doc => doc.kind !== kind)); return; }
    if (!ALLOWED_TYPES.includes(file.type) || file.size > MAX_DOCUMENT_BYTES) { setError("Chỉ nhận PDF, JPG, PNG; tối đa 1 MB mỗi tệp."); return; }
    setBusy(true);
    try {
      const data = await readFile(file);
      setDocuments(previous => [...previous.filter(doc => doc.kind !== kind), { kind, name: file.name, size: file.size, data }]);
    } catch (failure) { setError(failure.message); } finally { setBusy(false); }
  }
  function submit(event) {
    event.preventDefault(); setError("");
    if (busy) return;
    if (editing && !mine.some(item => item.id === editing && item.status === "SUPPLEMENT")) return setError("Hồ sơ không còn ở trạng thái yêu cầu bổ sung.");
    if (!editing && mine.some(item => !["REJECTED", "SCHOOL_REJECTED"].includes(item.status))) return setError("Bạn đã có hồ sơ đang được xử lý hoặc đã hoàn tất. Vui lòng theo dõi hồ sơ đã nộp.");
    if (!/^(?:\d{9}|\d{12}|[A-Za-z]\d{7,8})$/.test(form.identityNumber.trim())) return setError("CCCD/CMND gồm 9 hoặc 12 số; hộ chiếu gồm chữ cái và 7–8 số.");
    if (form.identityDate > new Date().toISOString().slice(0, 10) || Number(form.graduationYear) < 1980 || Number(form.graduationYear) > new Date().getFullYear()) return setError("Kiểm tra lại ngày cấp giấy tờ và năm tốt nghiệp.");
    if (Object.values(form).some(value => !value.trim()) || !/^[+\d][\d\s.-]{8,14}$/.test(form.phone)) return setError("Điền đủ thông tin và số điện thoại hợp lệ (9–15 ký tự).");
    if (DOCUMENT_TYPES.some(kind => !documents.some(doc => doc.kind === kind))) return setError("Vui lòng đính kèm đủ bốn loại giấy tờ.");
    if (documents.reduce((sum, doc) => sum + doc.size, 0) > MAX_TOTAL_BYTES) return setError("Tổng dung lượng giấy tờ không vượt quá 2 MB.");
    const at = new Date().toLocaleString("vi-VN");
    const application = { ...form, id: editing || `HS-${crypto.randomUUID().slice(0, 8).toUpperCase()}`, studentId: student ? STUDENT_ID : null, ownerToken: student ? null : ownerToken, documents, status: "SUBMITTED", submittedAt: at, history: [...((state.applications || []).find(item => item.id === editing)?.history || []), { status: "SUBMITTED", at, note: editing ? "Người nộp đã bổ sung hồ sơ." : "Đã gửi hồ sơ trực tuyến đến CTSV." }] };
    const applications = editing ? state.applications.map(item => item.id === editing ? application : item) : [application, ...(state.applications || [])];
    // Check browser capacity before showing success; keep the form if saving fails.
    try { localStorage.setItem("sms-portal-demo-v1", JSON.stringify({ ...state, applications })); }
    catch { return setError("Trình duyệt không đủ dung lượng lưu hồ sơ. Vui lòng dùng tệp nhỏ hơn."); }
    update(previous => ({ ...previous, applications, mailLog: [{ id: crypto.randomUUID(), to: form.email, subject: editing ? "Đã nhận hồ sơ bổ sung" : "Đã nhận hồ sơ trực tuyến", date: at, status: "SIMULATED" }, ...previous.mailLog] }));
    setReceipt(application); setEditing(null); setForm(blank); setDocuments([]); setFileKey(key => key + 1);
  }
  return <>
    <PageHeader title="Nộp hồ sơ trực tuyến" description="Gửi hồ sơ nhập học đến Phòng Công tác sinh viên và theo dõi quá trình tiếp nhận." />
    {receipt && <div className="application-receipt" role="status">Đã gửi hồ sơ <strong>{receipt.id}</strong> · Chờ CTSV tiếp nhận. <Button kind="outline" onClick={() => setDetail(receipt)}>Xem phiếu hồ sơ</Button></div>}
    <Card title={editing ? `Bổ sung hồ sơ ${editing}` : "Thông tin người nộp"}>
      <form onSubmit={submit}>
        <div className="application-fields">{[["name", "Họ và tên", "text"], ["email", "Email liên hệ", "email"], ["phone", "Số điện thoại", "tel"], ["address", "Địa chỉ liên hệ", "text"]].map(([key, label, type]) => <Field key={key} label={label}><input className="control" type={type} required maxLength={key === "address" ? 300 : 120} value={form[key]} onChange={event => setForm(previous => ({ ...previous, [key]: event.target.value }))} /></Field>)}
        <Field label="Ngành đăng ký"><select className="control" value={form.major} onChange={event => setForm(previous => ({ ...previous, major: event.target.value }))}>{state.majors.map(item => <option key={item.id} value={item.name}>{item.name}</option>)}</select></Field></div>
        <h3>Thông tin giấy tờ & học bạ THPT</h3>
        <div className="application-fields">{[["identityNumber", "Số CCCD / CMND / hộ chiếu", "text"], ["identityDate", "Ngày cấp", "date"], ["identityPlace", "Nơi cấp", "text"], ["highSchool", "Trường THPT", "text"], ["graduationYear", "Năm tốt nghiệp", "number"]].map(([key, label, type]) => <Field key={key} label={label}><input className="control" required type={type} value={form[key]} min={type === "number" ? 1980 : undefined} max={type === "number" ? new Date().getFullYear() : undefined} onChange={event => setForm(previous => ({ ...previous, [key]: event.target.value }))} /></Field>)}</div>
        <h3>Giấy tờ hồ sơ</h3><p>PDF, JPG hoặc PNG · Tối đa 1 MB/tệp, tổng 2 MB.</p>
        <div className="application-fields" key={fileKey}>{DOCUMENT_TYPES.map(kind => <Field label={kind} key={kind}><input className="control" type="file" accept="application/pdf,image/jpeg,image/png" disabled={busy} onChange={event => choose(kind, event.target.files[0])} /><small>{documents.find(doc => doc.kind === kind)?.name || "Chưa có tệp"}</small></Field>)}</div>
        {error && <p role="alert" className="application-error">{error}</p>}
        <div className="modal-actions">{editing && <Button kind="outline" onClick={() => { setEditing(null); setForm(blank); setDocuments([]); setFileKey(key => key + 1); }}>Hủy bổ sung</Button>}<Button type="submit" disabled={busy}>{busy ? "Đang đọc tệp…" : editing ? "Gửi lại hồ sơ" : "Nộp hồ sơ"}</Button></div>
      </form>
    </Card>
    <Card title="Hồ sơ đã nộp">{!mine.length ? <p>Chưa có hồ sơ đã gửi.</p> : pagination.rows.map(item => <div className="application-row" key={item.id}><div><strong>{item.id}</strong><p>{item.name} · {item.submittedAt}</p><Badge tone={["ACCEPTED", "ENROLLED"].includes(item.status) ? "green" : "amber"}>{APPLICATION_STATUS[item.status]}</Badge><p>{item.history.at(-1)?.note}</p></div><div><Button kind="outline" onClick={() => setDetail(item)}>Chi tiết</Button>{item.status === "SUPPLEMENT" && <Button onClick={() => { setEditing(item.id); setForm(Object.fromEntries(Object.entries(blank).map(([key, value]) => [key, item[key] || value]))); setDocuments(item.documents); setFileKey(key => key + 1); }}>Bổ sung hồ sơ</Button>}</div></div>)}<Pagination {...pagination} /></Card>
    {detail && <ApplicationDetail application={detail} onClose={() => setDetail(null)} />}
  </>;
}
