import React, { useEffect, useState } from 'react';
import { api, display } from './api.js';
import { Button, Card, Empty, Modal, PageHeader } from '../components/ui.jsx';
import { Facts, ScheduleList, SectionDetails, termName } from './AcademicDetails.jsx';
import Icon from '../components/common/Icon.jsx';
import OverviewOrbit from './OverviewOrbit.jsx';

function useAcademic() {
  const [data, setData] = useState(null);
  const [error, setError] = useState('');
  const [revision, setRevision] = useState(0);
  useEffect(() => {
    const controller = new AbortController();
    api('/student/academic', { signal: controller.signal }).then(value => {
      setData(value);
      setError('');
    }).catch(error => error.name !== 'AbortError' && setError(error.message));
    return () => controller.abort();
  }, [revision]);
  return { data, error, reload: () => setRevision(value => value + 1) };
}

export function StudentOverview({ user, navigate }) {
  const { data, error } = useAcademic();
  const [notices, setNotices] = useState([]);
  useEffect(() => {
    const controller = new AbortController();
    api('/resources/notifications?size=2', { signal:controller.signal }).then(result => setNotices(result.items)).catch(() => {});
    return () => controller.abort();
  }, []);
  const owned = data?.enrollments.filter(item => item.status !== 'CANCELLED') || [];
  const profile = data?.profile[0];
  const credits = owned.reduce((sum, item) => sum + Number(data.sections.find(section => section.id === item.section_id)?.credits || 0), 0);
  const upcoming = [];
  const now = new Date();
  for (let offset = 0; offset < 7; offset++) {
    const day = new Date(now.getFullYear(), now.getMonth(), now.getDate() + offset);
    const key = `${day.getFullYear()}-${String(day.getMonth()+1).padStart(2,'0')}-${String(day.getDate()).padStart(2,'0')}`;
    for (const enrollment of owned) {
      const section = data.sections.find(section => section.id === enrollment.section_id);
      if (!section || key < section.starts_on || key > section.ends_on) continue;
      for (const slot of section.schedules) {
        if (Number(slot.day_of_week) !== (day.getDay()+6)%7+1) continue;
        const start = new Date(`${key}T${slot.starts_at}`);
        if (start >= now) upcoming.push({ ...slot, title:section.title, section_code:section.section_code, date:key, start });
      }
    }
  }
  upcoming.sort((a,b) => a.start-b.start);
  return <div className="student-overview-compact" data-overview-ready={!!data}>
    <section className="admin-welcome student-welcome"><div className="student-welcome-content"><span className="admin-eyebrow">HÀNH TRÌNH HỌC TẬP</span><h1>Xin chào, {user.name}</h1><p>Theo dõi lịch học và những bước tiến mỗi ngày.</p><p className="student-welcome-profile">{profile ? `${profile.student_code} · ${profile.class_code}` : 'Đang tải thông tin…'}</p><Button onClick={() => navigate('timetable')}>Xem lịch học <Icon name="arrow" size={17}/></Button></div><OverviewOrbit/></section>
    {error && <p className="v6-error" role="alert">{error}</p>}
    <div className="overview-summary" aria-label="Tóm tắt học tập">
      <div><strong>{data ? owned.length : '—'}</strong><span>Học phần đã đăng ký</span></div>
      <div><strong>{data ? credits : '—'}</strong><span>Tín chỉ đăng ký</span></div>
      <div><strong>{data ? owned.filter(item => item.total_score != null).length : '—'}</strong><span>Học phần có điểm công bố</span></div>
    </div>
    <Card className="overview-brief"><div className="overview-brief-columns">
      <section><div className="overview-list-heading"><h2>Lịch học sắp tới</h2><button onClick={() => navigate('timetable')}>Xem lịch</button></div>
        {upcoming.slice(0,2).map((slot,index) => <button className="overview-brief-row" key={index} onClick={() => navigate('timetable')}><span className="overview-date-label">{display(slot.date,'starts_on').slice(0,5)}<small>{String(slot.starts_at).slice(0,5)}</small></span><span><strong>{slot.title}</strong><small>{slot.section_code} · Phòng {slot.room}</small></span></button>)}
        {!upcoming.length && <p className="v6-muted">{data ? 'Không có buổi học trong 7 ngày tới.' : 'Đang tải lịch học…'}</p>}
      </section>
      <section><div className="overview-list-heading"><h2>Thông báo mới</h2><button onClick={() => navigate('notifications')}>Xem tất cả</button></div>
        {notices.map(notice => <button className="overview-brief-row" key={notice.id} onClick={() => navigate('notifications')}><span><strong>{notice.title}</strong><small>{display(notice.created_at,'created_at')}</small></span></button>)}
        {!notices.length && <p className="v6-muted">Chưa có thông báo mới.</p>}
      </section>
    </div></Card>
  </div>;
}

export default function StudentAcademic({ mode, notify }) {
  const { data, error, reload } = useAcademic();
  const [semester, setSemester] = useState('');
  const [tab, setTab] = useState(mode === 'enrollments' ? 'mine' : 'all');
  const [search, setSearch] = useState('');
  const [selected, setSelected] = useState(null);
  const [confirm, setConfirm] = useState(null);
  const [busy, setBusy] = useState(false);
  useEffect(() => { setTab(mode === 'enrollments' ? 'mine' : 'all'); setSearch(''); setSelected(null); }, [mode]);
  const grades = mode === 'grades';
  const registration = mode === 'enrollments';
  const terms = [...new Map((data?.sections || []).map(item => [String(item.semester_id), termName(item)])).entries()];
  const own = section => data?.enrollments.find(item => item.section_id === section.id && item.status !== 'CANCELLED');
  const rows = (data?.sections || []).filter(section => (!semester || String(section.semester_id) === semester)
    && (!grades && tab === 'all' || own(section))
    && `${section.title} ${section.section_code} ${section.lecturer_name}`.toLocaleLowerCase('vi').includes(search.toLocaleLowerCase('vi')));
  const activeSelected = selected && data?.sections.find(item => item.id === selected.id);
  const published = rows.filter(section => own(section)?.total_score != null);
  const gradedCredits = published.reduce((sum, section) => sum + Number(section.credits), 0);
  const average = gradedCredits ? (published.reduce((sum, section) => sum + Number(own(section).total_score) * Number(section.credits), 0) / gradedCredits).toFixed(2) : '—';
  async function submit() {
    setBusy(true);
    try {
      await api(`/sections/${confirm.section.id}/${confirm.cancel ? 'cancel' : 'register'}`, { method: 'POST', body: {} });
      notify(confirm.cancel ? 'Đã hủy đăng ký học phần.' : 'Đăng ký học phần thành công.');
      setConfirm(null);
      reload();
    } catch (error) { notify(error.message, 'error'); reload(); }
    finally { setBusy(false); }
  }
  function actions(section, inDetail = false) {
    const enrollment = own(section);
    const cancel = !!enrollment;
    const reason = section[cancel ? 'cancel_reason' : 'register_reason'];
    return <div className="academic-action">{!inDetail && <Button small kind="outline" onClick={() => setSelected(section)}>Chi tiết</Button>}{registration && <><Button small disabled={busy || !!reason} onClick={() => setConfirm({ section, cancel })}>{cancel ? 'Hủy đăng ký' : 'Đăng ký'}</Button>{reason && <details className="registration-reason"><summary>Điều kiện đăng ký</summary><p>{reason}</p></details>}</>}</div>;
  }
  return <>
    <PageHeader title={grades ? 'Kết quả học tập' : mode === 'sections' ? 'Tra cứu lớp học phần' : 'Đăng ký / hủy học phần'} description={grades ? 'Xem đầy đủ các học phần đã đăng ký. Điểm chỉ hiển thị sau khi nhà trường công bố.' : registration ? 'Chọn lớp để đăng ký hoặc quản lý các học phần đã đăng ký.' : 'Tra cứu học phần, giảng viên và lịch học. Đăng ký và hủy tại mục Đăng ký / hủy học phần.'} />
    {error && <p className="v6-error" role="alert">{error}</p>}
    {!data && !error && <p role="status">Đang tải dữ liệu học tập…</p>}
    {data && grades && <div className="overview-summary"><div><strong>{average}</strong><span>Điểm trung bình hệ 10</span></div><div><strong>{gradedCredits}</strong><span>Tín chỉ có điểm</span></div><div><strong>{published.length}/{rows.length}</strong><span>Học phần đã công bố điểm</span></div></div>}
    {data && <Card><div className="academic-toolbar"><label>Học kỳ<select className="control" value={semester} onChange={event => setSemester(event.target.value)}><option value="">Tất cả học kỳ</option>{terms.map(([id, name]) => <option key={id} value={id}>{name}</option>)}</select></label><label>Tìm học phần / giảng viên<input className="control" type="search" value={search} onChange={event => setSearch(event.target.value)} placeholder="Tên môn, mã lớp, giảng viên…" /></label></div>
      {registration && <div className="academic-tabs"><Button kind={tab === 'all' ? 'primary' : 'outline'} onClick={() => setTab('all')}>Chọn lớp để đăng ký</Button><Button kind={tab === 'mine' ? 'primary' : 'outline'} onClick={() => setTab('mine')}>Đã đăng ký</Button></div>}
      <div className="table-wrap"><table className="data-table"><thead><tr><th>Học phần</th><th>Học kỳ / tín chỉ</th><th>Giảng viên</th>{grades ? <><th>Chuyên cần</th><th>Giữa kỳ</th><th>Cuối kỳ</th><th>Tổng kết</th><th>Công bố</th></> : <><th>Lịch học / phòng</th><th>Sĩ số / trạng thái</th></>}<th>Thao tác</th></tr></thead><tbody>{rows.map(section => {
        const enrollment = own(section);
        return <tr key={section.id}><td><strong>{section.title}</strong><small className="academic-sub">{section.course_code} · {section.section_code}</small></td><td>{termName(section)}<small className="academic-sub">{section.credits} tín chỉ</small></td><td>{section.lecturer_name || 'Chưa phân công'}</td>{grades ? <>{['attendance_score', 'midterm_score', 'final_score', 'total_score'].map(key => <td key={key}>{display(enrollment?.[key])}</td>)}<td>{enrollment?.sheet_status === 'PUBLISHED' ? 'Đã công bố' : 'Chưa công bố'}</td></> : <><td><ScheduleList rows={section.schedules} /></td><td>{section.registered}/{section.capacity}<small className="academic-sub">{enrollment ? display(enrollment.status) : 'Chưa đăng ký'}</small></td></>}<td>{actions(section)}</td></tr>;
      })}</tbody></table></div>{!rows.length && <Empty title="Chưa có học phần phù hợp" />}
      <p className="v6-muted">{rows.length} lớp học phần.{registration && ' Chỉ thay đổi đăng ký trong thời gian nhà trường cho phép; học kỳ đã phát hành hóa đơn cần gửi yêu cầu điều chỉnh.'}</p>
    </Card>}
    {activeSelected && <Modal title={`Chi tiết · ${activeSelected.title}`} wide onClose={() => setSelected(null)}><SectionDetails section={activeSelected} />{grades && <><h3>Điểm học phần</h3><Facts value={own(activeSelected) || {}} fields={['attendance_score', 'midterm_score', 'final_score', 'total_score', 'remark']} /><p className="v6-muted">{own(activeSelected)?.sheet_status === 'PUBLISHED' ? 'Bảng điểm đã công bố.' : 'Bảng điểm chưa công bố; điểm nội bộ không hiển thị cho sinh viên.'}</p></>}{registration && actions(activeSelected,true)}</Modal>}
    {confirm && <Modal title={confirm.cancel ? 'Xác nhận hủy đăng ký' : 'Xác nhận đăng ký học phần'} onClose={() => !busy && setConfirm(null)}><h3>{confirm.section.title}</h3><p>{confirm.section.section_code} · {confirm.section.credits} tín chỉ · {confirm.section.lecturer_name || 'Chưa phân công'}</p><ScheduleList rows={confirm.section.schedules} /><div className="modal-actions"><Button kind="outline" disabled={busy} onClick={() => setConfirm(null)}>Quay lại</Button><Button disabled={busy} onClick={submit}>{busy ? 'Đang xử lý…' : 'Xác nhận'}</Button></div></Modal>}
  </>;
}
