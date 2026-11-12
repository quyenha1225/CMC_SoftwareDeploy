import React, { useEffect, useState } from 'react';
import { api, display } from './api.js';
import { Button, Card, Empty, Modal, PageHeader } from '../components/ui.jsx';
import { Facts } from './AcademicDetails.jsx';

export default function ExamSchedule({ role, lookups, notify }) {
  const [rows, setRows] = useState([]), [sections, setSections] = useState([]), [semester, setSemester] = useState('');
  const [error, setError] = useState(''), [detail, setDetail] = useState(null), [form, setForm] = useState(null), [busy, setBusy] = useState(false), [revision, setRevision] = useState(0);
  useEffect(() => {
    const controller = new AbortController();
    api('/exams', { signal: controller.signal }).then(value => { setRows(value); setError(''); }).catch(error => error.name !== 'AbortError' && setError(error.message));
    if (role === 'TRAINING_OFFICE') api('/exams/sections', { signal: controller.signal }).then(setSections).catch(error => error.name !== 'AbortError' && setError(error.message));
    return () => controller.abort();
  }, [revision, role]);
  const filtered = rows.filter(row => !semester || String(row.semester_id) === semester);
  const set = (key, value) => setForm(previous => ({ ...previous, [key]: value }));
  async function save(event) {
    event.preventDefault(); setBusy(true);
    try {
      const { id, ...body } = form;
      await api(`/exams${id ? `/${id}` : ''}`, { method: id ? 'PUT' : 'POST', body });
      setForm(null); setRevision(value => value + 1); notify('Đã lưu lịch thi.');
    } catch (error) { notify(error.message, 'error'); }
    finally { setBusy(false); }
  }
  function edit(row = {}) {
    const value = Object.fromEntries(['section_id', 'starts_at', 'ends_at', 'room_id', 'exam_type_id', 'note', 'status'].map(key => [key, row[key] ?? (key === 'status' ? 'DRAFT' : '')]));
    if (row.id) value.id = row.id;
    setForm(value);
  }
  return <><PageHeader title="Lịch thi" description="Lịch thi do Phòng Đào tạo lập và công bố theo lớp học phần." action={role === 'TRAINING_OFFICE' && <Button onClick={() => edit()}>Thêm lịch thi</Button>} /><Card>{filtered.some(row=>row.data_origin==='DEMO')&&<p className="profile-completeness" role="note">Lịch thi thuộc bộ dữ liệu thực hành của dự án.</p>}<label className="v6-search">Học kỳ<select className="control" value={semester} onChange={event => setSemester(event.target.value)}><option value="">Tất cả học kỳ</option>{(lookups.semesters || []).map(term => <option key={term.id} value={term.id}>{term.code} · {display(term.starts_on, 'starts_on')} – {display(term.ends_on, 'ends_on')}</option>)}</select></label>{error && <p className="v6-error" role="alert">{error}</p>}<div className="table-wrap"><table className="data-table" data-exam-list="true"><thead><tr><th>Học phần</th><th>Loại thi</th><th>Ngày / giờ bắt đầu</th><th>Kết thúc</th><th>Phòng</th><th>Giảng viên</th><th>Thao tác</th></tr></thead><tbody>{filtered.map(row => <tr key={row.id}><td><strong>{row.title}</strong><small className="academic-sub">{row.section_code}</small></td><td>{row.exam_type}</td><td>{display(row.starts_at, 'starts_at')}</td><td>{display(row.ends_at, 'ends_at')}</td><td>{row.room}</td><td>{row.lecturer_name || 'Chưa phân công'}</td><td><div className="v6-row-actions"><Button small kind="outline" onClick={() => setDetail(row)}>Chi tiết</Button>{role === 'TRAINING_OFFICE' && <Button small kind="outline" onClick={() => edit(row)}>Sửa / công bố</Button>}</div></td></tr>)}</tbody></table></div>{!filtered.length && !error && <Empty title="Chưa có lịch thi được công bố" description="Khi Phòng Đào tạo công bố lịch cho lớp đã đăng ký, lịch thi sẽ xuất hiện tại đây." />}</Card>
    {detail && <Modal title={`Lịch thi · ${detail.title}`} onClose={() => setDetail(null)}><Facts value={detail} fields={['section_code', 'title', 'exam_type', 'starts_at', 'ends_at', 'room', 'lecturer_name', 'status', 'data_origin', 'note']} /></Modal>}
    {form && <Modal title="Lập / cập nhật lịch thi" onClose={() => !busy && setForm(null)}><form onSubmit={save}><div className="v6-fields"><label className="field"><span>Lớp học phần</span><select className="control" required value={form.section_id} onChange={event => set('section_id', event.target.value)}><option value="">Chọn lớp</option>{sections.map(section => <option key={section.id} value={section.id}>{section.section_code} · {section.title}</option>)}</select></label>{[['starts_at', 'Bắt đầu', 'datetime-local'], ['ends_at', 'Kết thúc', 'datetime-local']].map(([key, label, type]) => <label className="field" key={key}><span>{label}</span><input className="control" type={type} required maxLength={80} value={type === 'datetime-local' ? String(form[key]).replace(' ', 'T').slice(0, 16) : form[key]} onChange={event => set(key, event.target.value)} /></label>)}{[['room_id','Phòng thi','rooms'],['exam_type_id','Loại thi','exam_types']].map(([key,label,source])=><label className="field" key={key}><span>{label}</span><select className="control" required value={form[key]} onChange={event=>set(key,event.target.value)}><option value="">Chọn {label.toLowerCase()}</option>{(lookups[source]||[]).filter(item=>item.active||String(item.id)===String(form[key])).map(item=><option key={item.id} value={item.id}>{item.name} · {item.code}</option>)}</select></label>)}<label className="field"><span>Trạng thái</span><select className="control" value={form.status} onChange={event => set('status', event.target.value)}>{['DRAFT', 'PUBLISHED', 'CANCELLED'].map(status => <option key={status} value={status}>{display(status)}</option>)}</select></label><label className="field v6-wide"><span>Ghi chú</span><textarea className="control" maxLength={1000} value={form.note} onChange={event => set('note', event.target.value)} /></label></div><div className="modal-actions"><Button kind="outline" disabled={busy} onClick={() => setForm(null)}>Quay lại</Button><Button type="submit" disabled={busy}>{busy ? 'Đang lưu…' : 'Lưu lịch thi'}</Button></div></form></Modal>}
  </>;
}
