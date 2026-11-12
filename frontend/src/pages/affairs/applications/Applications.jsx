import React, { useState } from "react";
import { Badge, Button, Card, Empty, Field, PageHeader, Modal } from "../../../components/ui.jsx";
import ApplicationDetail from "../../student/application/ApplicationDetail.jsx";
import { APPLICATION_STATUS, canTransition } from "../../student/application/applicationData.js";
import "../../student/application/Application.css";
import { forwardApplication } from "../../../data/workflows.js";
import Pagination, { usePagination } from "../../../components/common/Pagination.jsx";

export default function Applications({ state, update, notify }) {
  const [filter, setFilter] = useState("ALL"), [search, setSearch] = useState("");
  const [detail, setDetail] = useState(null), [action, setAction] = useState(null), [note, setNote] = useState("");
  const applications = state.applications || [];
  const [forward, setForward] = useState(null), [classId, setClassId] = useState("");
  const visible = applications.filter(item => (filter === "ALL" || item.status === filter) && `${item.id} ${item.name} ${item.email}`.toLowerCase().includes(search.toLowerCase()));


  function process(event) {
    event.preventDefault();
    const current = applications.find(item => item.id === action.id);
    if (!current || !canTransition(current.status, action.status)) return notify("Trạng thái hồ sơ đã thay đổi. Vui lòng kiểm tra lại.", "error");
    if (["SUPPLEMENT", "REJECTED"].includes(action.status) && !note.trim()) return notify("Nhập lý do hoặc giấy tờ cần bổ sung.", "error");
    const entry = { status: action.status, at: new Date().toLocaleString("vi-VN"), note: note.trim() || "CTSV đã cập nhật hồ sơ." };
    if (action.status === "ACCEPTED" && current.documents.some(doc => !current.documentChecks?.[doc.kind])) return notify("Kiểm tra và đánh dấu đạt từng giấy tờ trong chi tiết hồ sơ trước khi hoàn tất.", "error");
    update(previous => ({ ...previous, mailLog: [{ id: crypto.randomUUID(), to: current.email, subject: `${APPLICATION_STATUS[action.status]}: ${entry.note}`, date: entry.at, status: "SIMULATED" }, ...previous.mailLog], applications: previous.applications.map(item => item.id === action.id ? { ...item, status: action.status, history: [...item.history, entry] } : item) }));
    setAction(null); setNote(""); notify("Đã cập nhật trạng thái hồ sơ.");
  }
  const pagination = usePagination(visible, `${filter}:${search}`);
  return <>
    <PageHeader title="Tiếp nhận hồ sơ · CTSV" description="Kiểm tra hồ sơ trực tuyến, phản hồi giấy tờ cần bổ sung và xác nhận hoàn tất." />
    <div className="summary-strip"><span>Tổng hồ sơ: <strong>{applications.length}</strong></span><span>Chờ tiếp nhận: <strong>{applications.filter(item => item.status === "SUBMITTED").length}</strong></span><span>Cần bổ sung: <strong>{applications.filter(item => item.status === "SUPPLEMENT").length}</strong></span></div>
    <Card title="Danh sách hồ sơ">
      <div className="application-fields"><Field label="Trạng thái"><select className="control" value={filter} onChange={event => setFilter(event.target.value)}><option value="ALL">Tất cả</option>{Object.entries(APPLICATION_STATUS).map(([key, label]) => <option key={key} value={key}>{label}</option>)}</select></Field><Field label="Tìm mã hồ sơ, họ tên, email"><input className="control" value={search} onChange={event => setSearch(event.target.value)} /></Field></div>
      {!visible.length ? <Empty title="Không có hồ sơ phù hợp" description="Hồ sơ nộp trực tuyến sẽ hiển thị tại đây để tiếp nhận." /> : pagination.rows.map(item => <div className="application-row" key={item.id}>
        <div><strong>{item.name} · {item.id}</strong><p>{item.major} · {item.email}</p><p>{item.submittedAt}</p><Badge tone={item.status === "ACCEPTED" ? "green" : "amber"}>{APPLICATION_STATUS[item.status]}</Badge></div>
        <div><Button kind="outline" onClick={() => setDetail(item)}>Xem hồ sơ / tệp</Button>{item.status === "ACCEPTED" && <Button onClick={() => { setForward(item); setClassId(""); }}>Xếp lớp & chuyển Nhà trường</Button>}{(item.status === "SUBMITTED" ? ["RECEIVED"] : item.status === "RECEIVED" ? ["SUPPLEMENT", "ACCEPTED", "REJECTED"] : []).map(status => <Button key={status} kind={status === "REJECTED" ? "danger-outline" : "primary"} onClick={() => { setAction({ id: item.id, status }); setNote(""); }}>{status === "RECEIVED" ? "Tiếp nhận" : APPLICATION_STATUS[status]}</Button>)}</div>
      </div>)}
      <Pagination {...pagination} />
    </Card>
    {detail && <ApplicationDetail application={state.applications.find(item => item.id === detail.id) || detail} onClose={() => setDetail(null)} onCheck={(kind, checked) => update(previous => ({ ...previous, applications: previous.applications.map(item => item.id === detail.id ? { ...item, documentChecks: { ...item.documentChecks, [kind]: checked } } : item) }))} />}
    {forward && <Modal title="Xếp lớp & chuyển Nhà trường" onClose={() => setForward(null)}><Field label="Lớp hành chính đúng ngành đăng ký"><select className="control" value={classId} onChange={event => setClassId(event.target.value)}><option value="">Chọn lớp</option>{state.classes.filter(item => state.majors.find(major => major.id === item.majorId)?.name === forward.major).map(item => <option key={item.id} value={item.id}>{item.name}</option>)}</select></Field><div className="modal-actions"><Button kind="outline" onClick={() => setForward(null)}>Hủy</Button><Button disabled={!classId} onClick={() => { try { const next = forwardApplication(state, forward.id, classId); update(() => next); setForward(null); notify("Đã chuyển hồ sơ đến Ban giám hiệu."); } catch (error) { notify(error.message, "error"); } }}>Gửi xét duyệt</Button></div></Modal>}
    {action && <Modal title={APPLICATION_STATUS[action.status]} onClose={() => setAction(null)}><form onSubmit={process}><Field label="Phản hồi cho người nộp"><textarea className="control textarea" rows={4} maxLength={1500} required={["SUPPLEMENT", "REJECTED"].includes(action.status)} value={note} onChange={event => setNote(event.target.value)} /></Field><div className="modal-actions"><Button kind="outline" onClick={() => setAction(null)}>Hủy</Button><Button type="submit">Xác nhận</Button></div></form></Modal>}
  </>;
}
