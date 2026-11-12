import React, { useEffect, useState } from 'react';
import Icon from '../components/common/Icon.jsx';

const titles = {
  students:'Hồ sơ cá nhân', sections:'Tra cứu lớp học phần', enrollments:'Đăng ký / hủy học phần',
  timetable:'Lịch học', exams:'Lịch thi', grades:'Kết quả học tập', invoices:'Công nợ & hóa đơn',
  payments:'Lịch sử thanh toán', requests:'Yêu cầu hỗ trợ', notifications:'Thông báo',
};
const icons = {
  overview:'dashboard', students:'user', sections:'bookopen', enrollments:'list', timetable:'calendar',
  exams:'clock', grades:'grades', invoices:'wallet', payments:'wallet', requests:'file',
  notifications:'bell', mailboxes:'mail', emails:'send', users:'users', audit:'shield',
  admissions:'file', lecturers:'users', reports:'chart', grade_sheets:'grades', remittances:'wallet',
  invoice_proposals:'wallet', adjustments:'edit', rooms:'building', exam_types:'list', semesters:'calendar', courses:'bookopen',
};

export function pageTitle(key, role, resources) {
  if (key === 'overview') return 'Tổng quan';
  const reviewTitles={admissions:'Xét duyệt hồ sơ',grade_sheets:'Xét duyệt bảng điểm',invoice_proposals:'Xét duyệt học phí',adjustments:'Duyệt điều chỉnh học phí',remittances:'Duyệt bàn giao',reports:'Duyệt báo cáo'};
  if(role==='PRINCIPAL' && reviewTitles[key]) return reviewTitles[key];
  if(role==='TRAINING_OFFICE' && key==='grade_sheets') return 'Kiểm tra & trình bảng điểm';
  if (role === 'STUDENT' && titles[key]) return titles[key];
  return key === 'timetable' ? 'Lịch học' : key === 'exams' ? 'Lịch thi' : resources.find(item => item.key === key)?.title || key;
}

export default function PortalNavigation({ allowed, page, role, resources, navigate }) {
  const [open, setOpen] = useState({});
  const groups = [
    { id:'courses', title:'Học phần', icon:'bookopen', pages:['sections','enrollments'] },
    { id:'schedule', title:'Thời khóa biểu', icon:'calendar', pages:['timetable','exams'] },
    { id:'finance', title:'Học phí', icon:'wallet', pages:['invoices','payments'] },
  ].map(group => ({...group, pages:group.pages.filter(key => allowed.includes(key))})).filter(group => group.pages.length > 1);
  useEffect(() => {
    const group = groups.find(item => item.pages.includes(page));
    if (group) setOpen(previous => ({...previous, [group.id]:true}));
  }, [page, role]);
  function item(key, nested = false) {
    return <button key={key} data-page={key} className={`nav-item ${nested ? 'nav-subitem' : ''} ${page === key ? 'nav-active' : ''}`} aria-current={page === key ? 'page' : undefined} onClick={() => navigate(key)}>
      {!nested && <Icon name={icons[key] || 'list'} size={18}/>}<span>{pageTitle(key, role, resources)}</span>
    </button>;
  }
  const drawn = new Set();
  return <nav className="navigation" aria-label="Điều hướng chính">
    {item('overview')}
    {allowed.map(key => {
      const group = groups.find(group => group.pages.includes(key));
      if (!group) return item(key);
      if (drawn.has(group.id)) return null;
      drawn.add(group.id);
      const expanded = !!open[group.id];
      return <div className="nav-group" key={group.id}>
        <button className={`nav-item nav-group-toggle ${group.pages.includes(page) ? 'nav-group-current' : ''}`} aria-expanded={expanded} aria-controls={`navigation-${group.id}`} onClick={() => setOpen(previous => ({...previous, [group.id]:!expanded}))}>
          <Icon name={group.icon} size={18}/><span>{group.title}</span><Icon name="down" size={15}/>
        </button>
        <div className={`nav-group-reveal ${expanded ? 'is-open' : ''}`} id={`navigation-${group.id}`} aria-hidden={!expanded} inert={!expanded}>
          <div className="nav-group-inner">{group.pages.map(key => item(key, true))}</div>
        </div>
      </div>;
    })}
  </nav>;
}
