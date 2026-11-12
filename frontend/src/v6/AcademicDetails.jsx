import React from 'react';
import { display, labels } from './api.js';

export const dayName = day => Number(day) === 7 ? 'Chủ nhật' : `Thứ ${Number(day) + 1}`;
export const termName = section => `${section.semester_code || ''} · ${section.academic_year || ''}`;

export function Facts({ value, fields = Object.keys(value || {}), lookups = {} }) {
  const hidden = ['password_hash', 'storage_key', 'token_hash'];
  function format(key) {
    const source = { semester_id: 'semesters', class_id: 'academic_classes', course_id: 'courses', major_id: 'majors', fund_id: 'ctsv_funds' }[key];
    const item = source && lookups[source]?.find(item => Number(item.id) === Number(value[key]));
    if (item) return item.name || item.title || item.code;
    return display(value[key], key);
  }
  return <dl className="campus-facts">{fields.filter(key => !hidden.includes(key) && (value?.[key] == null || typeof value[key] !== 'object')).map(key =>
    <div key={key}><dt>{labels[key] || key.replaceAll('_', ' ')}</dt><dd>{format(key)}</dd></div>
  )}</dl>;
}

export function ScheduleList({ rows = [] }) {
  if (!rows.length) return <p className="v6-muted">Chưa xếp buổi học. Phòng Đào tạo cần bổ sung lịch.</p>;
  return <div className="academic-schedules">{rows.map((row, index) => <div key={row.id || index}>
    <strong>{dayName(row.day_of_week)}</strong>
    <span>{String(row.starts_at).slice(0, 5)}–{String(row.ends_at).slice(0, 5)}</span>
    <span>Phòng {row.room || 'chưa xếp'}</span>
  </div>)}</div>;
}

export function SectionDetails({ section }) {
  const term = section.semester ? {...section.semester, semester_code:section.semester.code} : section;
  return <>
    <Facts value={section} fields={['section_code', 'course_code', 'title', 'credits', 'lecturer_name', 'registered', 'capacity', 'attendance_weight', 'midterm_weight', 'final_weight', 'is_open']} />
    <h3>Thời gian học và đăng ký</h3>
    <Facts value={term} fields={['academic_year', 'semester_code', 'starts_on', 'ends_on', 'registration_from', 'registration_to']} />
    <h3>Các buổi học</h3><ScheduleList rows={section.schedules} />
  </>;
}
