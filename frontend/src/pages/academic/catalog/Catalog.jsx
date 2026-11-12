import React, { useState } from "react";
import { Button, Card, Empty, Field, Modal, PageHeader } from "../../../components/ui.jsx";
import Pagination, { usePagination } from "../../../components/common/Pagination.jsx";
import "./Catalog.css";

const definitions = {
  faculties: { title: "Khoa", fields: [] },
  majors: { title: "Ngành", fields: [["facultyId", "Khoa", "faculties"]] },
  classes: { title: "Lớp hành chính", fields: [["majorId", "Ngành", "majors"]] },
  lecturers: { title: "Giảng viên", fields: [["facultyId", "Khoa", "faculties"], ["email", "Email", "email"]] },
  courses: { title: "Học phần", fields: [["facultyId", "Khoa", "faculties"], ["credits", "Tín chỉ", "number"]] },
  semesters: { title: "Học kỳ", fields: [["startsOn", "Bắt đầu", "date"], ["endsOn", "Kết thúc", "date"], ["registrationOpen", "Mở đăng ký học phần", "checkbox"]] },
};
export default function Catalog({ state, update, notify }) {
  const [type, setType] = useState("faculties"), [search, setSearch] = useState(""), [edit, setEdit] = useState(null);
  const definition = definitions[type];
  const rows = state[type].filter(item => `${item.id} ${item.name}`.toLowerCase().includes(search.toLowerCase()));


  const label = (item, key, source) => state[source]?.find(row => row.id === item[key])?.name || item[key] || "—";
  function save(event) {
    event.preventDefault();
    if (!edit.id.trim() || !edit.name.trim()) return notify("Nhập mã và tên danh mục.", "error");
    if (!edit.originalId && state[type].some(item => item.id.toLowerCase() === edit.id.trim().toLowerCase())) return notify("Mã đã tồn tại.", "error");
    if (definition.fields.some(([key, , source]) => state[source] && !state[source].some(item => item.id === edit[key]))) return notify("Chọn danh mục liên kết hợp lệ.", "error");
    if (type === "semesters" && (!/^\d{4}-\d+$/.test(edit.id) || edit.startsOn >= edit.endsOn)) return notify("Mã học kỳ dạng 2026-1; ngày kết thúc phải sau ngày bắt đầu.", "error");
    if (type === "courses" && (!Number.isInteger(Number(edit.credits)) || edit.credits < 1 || edit.credits > 20)) return notify("Tín chỉ từ 1 đến 20, là số nguyên.", "error");
    const payload = { ...edit, id: edit.id.trim(), name: edit.name.trim() };
    delete payload.originalId;
    if (type === "courses") { payload.credits = Number(payload.credits); payload.code = payload.id; payload.faculty = state.faculties.find(item => item.id === payload.facultyId)?.name; }
    const old = state[type].find(item => item.id === edit.originalId);
    update(previous => {
      const next = { ...previous, [type]: edit.originalId ? previous[type].map(item => item.id === edit.originalId ? payload : item) : [...previous[type], payload] };
      if (old && type === "lecturers") next.sections = previous.sections.map(item => item.teacherId === old.id || item.teacher === old.name ? { ...item, teacherId: payload.id, teacher: payload.name } : item);
      if (old && type === "classes") next.students = previous.students.map(item => item.classId === old.id || item.className === old.name ? { ...item, classId: payload.id, className: payload.name, major: previous.majors.find(major => major.id === payload.majorId)?.name } : item);
      if (old && type === "majors") next.students = previous.students.map(item => item.major === old.name ? { ...item, major: payload.name } : item);
      return next;
    });
    setEdit(null); notify("Đã lưu danh mục.");
  }
  const pagination = usePagination(rows, `${type}:${search}`);
  return <>
    <PageHeader title="Danh mục đào tạo" description="Quản lý tập trung khoa, ngành, lớp, giảng viên, học phần và học kỳ." />
    <div className="catalog-tabs">{Object.entries(definitions).map(([key, value]) => <button key={key} className={type === key ? "active" : ""} onClick={() => { setType(key); setSearch(""); }}>{value.title}<span>{state[key].length}</span></button>)}</div>
    <Card title={definition.title} extra={<Button icon="plus" onClick={() => setEdit({ id: "", name: "", credits: 3, registrationOpen: true, ...Object.fromEntries(definition.fields.filter(([, , source]) => state[source]).map(([key, , source]) => [key, state[source][0]?.id || ""])) })}>Thêm {definition.title.toLowerCase()}</Button>}>
      <Field label="Tìm theo mã hoặc tên"><input className="control" value={search} onChange={event => setSearch(event.target.value)} placeholder="Nhập từ khóa…" /></Field>
      <div className="table-wrap"><table className="data-table"><thead><tr><th>Mã</th><th>Tên</th>{definition.fields.map(([key, title]) => <th key={key}>{title}</th>)}<th>Thao tác</th></tr></thead><tbody>{pagination.rows.map(item => <tr key={item.id}><td><b>{item.id}</b></td><td>{item.name}</td>{definition.fields.map(([key, , source]) => <td key={key}>{source === "checkbox" ? item[key] ? "Đang mở" : "Đã đóng" : label(item, key, source)}</td>)}<td><Button small kind="outline" onClick={() => setEdit({ ...item, originalId: item.id, facultyId: item.facultyId || state.faculties[0]?.id })}>Chỉnh sửa</Button></td></tr>)}</tbody></table></div>
      {!rows.length && <Empty title="Chưa có dữ liệu phù hợp" />}<Pagination {...pagination} />
    </Card>
    {edit && <Modal title={`${edit.originalId ? "Chỉnh sửa" : "Thêm"} ${definition.title.toLowerCase()}`} onClose={() => setEdit(null)}><form onSubmit={save}><div className="form-grid">
      <Field label="Mã"><input className="control" required disabled={!!edit.originalId} maxLength={40} value={edit.id} placeholder={type === "semesters" ? "2026-1" : "Mã duy nhất"} onChange={event => setEdit({ ...edit, id: event.target.value })} /></Field>
      <Field label="Tên"><input className="control" required maxLength={160} value={edit.name} onChange={event => setEdit({ ...edit, name: event.target.value })} /></Field>
      {definition.fields.map(([key, title, source]) => <Field label={title} key={key}>{state[source] ? <select className="control" required value={edit[key] || ""} onChange={event => setEdit({ ...edit, [key]: event.target.value })}><option value="">Chọn {title.toLowerCase()}</option>{state[source].map(item => <option key={item.id} value={item.id}>{item.name}</option>)}</select> : source === "checkbox" ? <input type="checkbox" checked={!!edit[key]} onChange={event => setEdit({ ...edit, [key]: event.target.checked })} /> : <input className="control" type={source} required min={source === "number" ? 1 : undefined} max={source === "number" ? 20 : undefined} value={edit[key] || ""} onChange={event => setEdit({ ...edit, [key]: event.target.value })} />}</Field>)}
    </div><div className="modal-actions"><Button kind="outline" onClick={() => setEdit(null)}>Hủy</Button><Button type="submit">Lưu danh mục</Button></div></form></Modal>}
  </>;
}
