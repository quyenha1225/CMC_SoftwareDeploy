import React, { useState } from "react";
import { ROLE_NAMES } from "../../data/portalData.js";
import { uid } from "../../data/workflows.js";
import { Badge, Button, Card, Empty, Field, Modal, PageHeader } from "../../components/ui.jsx";
import Pagination, { usePagination } from "../../components/common/Pagination.jsx";
import "./Accounts.css";

export default function Accounts({ state, update, notify }) {
  const [search, setSearch] = useState(""), [role, setRole] = useState("ALL"), [edit, setEdit] = useState(null);
  const rows = state.users.filter(item => (role === "ALL" || item.role === role) && `${item.name} ${item.login} ${item.email || ""}`.toLowerCase().includes(search.toLowerCase()));
  const page = usePagination(rows, search + role);
  function save(event) {
    event.preventDefault();
    if (!edit.name.trim() || !/^[a-zA-Z0-9._-]{3,60}$/.test(edit.login) || !ROLE_NAMES[edit.role]) return notify("Nhập họ tên, vai trò và tên đăng nhập từ 3–60 ký tự chữ/số/dấu chấm/gạch.", "error");
    if (state.users.some(item => item.id !== edit.id && item.login.toLowerCase() === edit.login.trim().toLowerCase())) return notify("Tên đăng nhập đã tồn tại.", "error");
    if (edit.studentId && edit.role !== "student") return notify("Tài khoản gắn sinh viên phải giữ vai trò Sinh viên.", "error");
    const payload = { ...edit, id: edit.id || uid("U"), name: edit.name.trim(), login: edit.login.trim().toLowerCase() };
    update(previous => ({ ...previous, users: edit.id ? previous.users.map(item => item.id === edit.id ? payload : item) : [...previous.users, payload] }));
    setEdit(null); notify("Đã lưu tài khoản và vai trò.");
  }
  return <>
    <PageHeader title="Tài khoản & vai trò" description="Quản lý thông tin tài khoản, trạng thái hoạt động và vai trò." action={<Button icon="plus" onClick={() => setEdit({ name: "", login: "", email: "", role: "student", status: "ACTIVE" })}>Tạo tài khoản</Button>} />
    <Card title="Danh sách tài khoản"><div className="finance-filters"><Field label="Tìm tên / tài khoản / email"><input className="control" value={search} onChange={event => setSearch(event.target.value)} /></Field><Field label="Vai trò"><select className="control" value={role} onChange={event => setRole(event.target.value)}><option value="ALL">Tất cả</option>{Object.entries(ROLE_NAMES).map(([key, title]) => <option key={key} value={key}>{title}</option>)}</select></Field></div>
      <div className="table-wrap"><table className="data-table"><thead><tr><th>Họ tên</th><th>Tài khoản / email</th><th>Vai trò</th><th>Trạng thái</th><th>Thao tác</th></tr></thead><tbody>{page.rows.map(item => <tr key={item.id}><td><b>{item.name}</b></td><td>{item.login}<small className="cell-sub">{item.email || "Chưa có email"}</small></td><td>{ROLE_NAMES[item.role]}</td><td><Badge tone={item.status === "ACTIVE" ? "green" : "red"}>{item.status === "ACTIVE" ? "Hoạt động" : "Đã khóa"}</Badge></td><td><div className="finance-actions"><Button small kind="outline" onClick={() => setEdit({ ...item, email: item.email || "" })}>Sửa</Button><Button small kind="outline" onClick={() => { update(previous => ({ ...previous, users: previous.users.map(row => row.id === item.id ? { ...row, status: row.status === "ACTIVE" ? "LOCKED" : "ACTIVE" } : row) })); notify("Đã cập nhật trạng thái tài khoản."); }}>{item.status === "ACTIVE" ? "Khóa" : "Mở khóa"}</Button></div></td></tr>)}</tbody></table></div>{!rows.length && <Empty title="Không có tài khoản phù hợp" />}<Pagination {...page} />
    </Card>
    {edit && <Modal title={edit.id ? "Chỉnh sửa tài khoản" : "Tạo tài khoản"} onClose={() => setEdit(null)}><form onSubmit={save}><div className="form-grid">{[["name", "Họ và tên", "text"], ["login", "Tên đăng nhập", "text"], ["email", "Email", "email"]].map(([key, title, type]) => <Field label={title} key={key}><input className="control" type={type} required value={edit[key]} onChange={event => setEdit({ ...edit, [key]: event.target.value })} /></Field>)}<Field label="Vai trò"><select className="control" disabled={!!edit.studentId} value={edit.role} onChange={event => setEdit({ ...edit, role: event.target.value })}>{Object.entries(ROLE_NAMES).map(([key, title]) => <option key={key} value={key}>{title}</option>)}</select></Field></div><div className="modal-actions"><Button kind="outline" onClick={() => setEdit(null)}>Hủy</Button><Button type="submit">Lưu tài khoản</Button></div></form></Modal>}
  </>;
}
