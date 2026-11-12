import React, { useEffect, useLayoutEffect, useMemo, useRef, useState } from 'react';
import { api, display } from './api.js';
import { PageHeader, Modal, Empty, Button } from '../components/ui.jsx';
import { Facts, dayName } from './AcademicDetails.jsx';
import '../pages/student/schedule/HourlyCalendar.css';

const dateKey = date => `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
const parse = date => new Date(`${date}T12:00:00`);
const minute = value => { const [h, m] = String(value).split(':').map(Number); return h * 60 + m; };

export default function Timetable({ lookups }) {
  const calendarRef = useRef(null), rangeRef = useRef(null), previousRef = useRef(null);
  const [rows, setRows] = useState([]), [error, setError] = useState('');
  const [semester, setSemester] = useState(String(lookups.semesters?.find(term => dateKey(new Date()) >= term.starts_on && dateKey(new Date()) <= term.ends_on)?.id || lookups.semesters?.[0]?.id || ''));
  const [selected, setSelected] = useState(null), [date, setDate] = useState(dateKey(new Date())), [view, setView] = useState('week');
  const term = lookups.semesters?.find(item => String(item.id) === semester);
  useLayoutEffect(() => {
    const previous = previousRef.current;
    previousRef.current = { date, view, semester };
    if (!previous || window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
    const grid = calendarRef.current?.firstElementChild;
    if (!grid?.animate) return;
    const changingView = previous.view !== view;
    const direction = date < previous.date ? -1 : 1;
    const entrance = grid.animate([
      { opacity: .45, transform: changingView ? 'translate3d(0, 8px, 0)' : `translate3d(${direction * 14}px, 0, 0)` },
      { opacity: 1, transform: 'translate3d(0, 0, 0)' },
    ], { duration: 260, easing: 'cubic-bezier(.22, 1, .36, 1)' });
    const caption = rangeRef.current?.animate([{ opacity: .4 }, { opacity: 1 }], { duration: 220 });
    return () => { entrance.cancel(); caption?.cancel(); };
  }, [date, view, semester]);
  useEffect(() => {
    if (!term) return;
    const today = dateKey(new Date());
    setDate(today >= term.starts_on && today <= term.ends_on ? today : term.starts_on);
  }, [semester]);
  useEffect(() => {
    const controller = new AbortController();
    api('/timetable', { signal: controller.signal }).then(setRows).catch(error => error.name !== 'AbortError' && setError(error.message));
    return () => controller.abort();
  }, []);
  const days = useMemo(() => {
    const first = parse(date);
    if (view === 'month') first.setDate(1);
    if (view !== 'day') first.setDate(first.getDate() - (first.getDay() + 6) % 7);
    return Array.from({ length: view === 'month' ? 42 : view === 'day' ? 1 : 7 }, (_, index) => {
      const day = new Date(first); day.setDate(day.getDate() + index); return day;
    });
  }, [date, view]);
  const forDay = day => rows.filter(row => String(row.semester_id) === semester && Number(row.day_of_week) === (day.getDay() + 6) % 7 + 1 && (!term || dateKey(day) >= term.starts_on && dateKey(day) <= term.ends_on));
  function move(amount) {
    const next = parse(date);
    if (view === 'month') { next.setDate(1); next.setMonth(next.getMonth() + amount); }
    else next.setDate(next.getDate() + amount * (view === 'week' ? 7 : 1));
    setDate(dateKey(next));
  }
  return <section className="v6-timetable">
    <PageHeader title="Lịch học" description="Xem lịch theo ngày, tuần hoặc tháng. Bấm vào buổi học để xem chi tiết." />
    <div className="v6-calendar-tools"><select className="control" aria-label="Học kỳ" value={semester} onChange={event => setSemester(event.target.value)}>{(lookups.semesters || []).map(item => <option key={item.id} value={item.id}>{item.code} · {display(item.starts_on, 'starts_on')} – {display(item.ends_on, 'ends_on')}</option>)}</select><input aria-label="Chọn ngày xem lịch" className="control" type="date" value={date} onChange={event => event.target.value && setDate(event.target.value)} />{[['day', 'Ngày'], ['week', 'Tuần'], ['month', 'Tháng']].map(([key, title]) => <Button key={key} kind={view === key ? 'primary' : 'outline'} onClick={() => setView(key)}>{title}</Button>)}<Button kind="outline" onClick={() => move(-1)}>← Trước</Button><Button kind="outline" onClick={() => setDate(dateKey(new Date()))}>Hôm nay</Button><Button kind="outline" onClick={() => move(1)}>Sau →</Button></div>
    {error && <p className="v6-error" role="alert">{error}</p>}
    <p className="calendar-range" ref={rangeRef} aria-live="polite">{view === 'month' ? `Tháng ${parse(date).getMonth() + 1}/${parse(date).getFullYear()}` : `${display(dateKey(days[0]), 'starts_on')} – ${display(dateKey(days.at(-1)), 'ends_on')}`} · {term?.code}</p>
    {view === 'month' ? <div className="academic-month-scroll" ref={calendarRef}><div className="academic-month">{Array.from({ length: 7 }, (_, index) => <strong className="academic-month-heading" key={index}>{dayName(index + 1)}</strong>)}{days.map(day => <div key={dateKey(day)} className={`academic-month-day ${day.getMonth() !== parse(date).getMonth() ? 'outside' : ''} ${dateKey(day) === date ? 'is-selected' : ''}`}><button className="academic-date" aria-pressed={dateKey(day) === date} onClick={() => { setDate(dateKey(day)); setView('day'); }}>{day.getDate()}</button>{forDay(day).map((row, index) => <button className="academic-month-event" key={index} onClick={() => setSelected({ ...row, date: dateKey(day) })}><strong>{row.course_title || row.title}</strong><span>{String(row.starts_at).slice(0, 5)} · {row.room}</span></button>)}</div>)}</div></div> : <div className="hourly-scroll" ref={calendarRef}><div className={`hourly-calendar v6-hourly ${view === 'day' ? 'academic-single-day' : ''}`}><div className="hourly-heading hourly-corner">Giờ học</div>{days.map(day => <div key={dateKey(day)} className={`hourly-heading ${dateKey(day) === date ? 'is-selected' : ''}`}><span>{dayName((day.getDay() + 6) % 7 + 1)}</span><b>{day.toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit' })}</b></div>)}<div className="hourly-axis">{Array.from({ length: 17 }, (_, index) => <span key={index} style={{ top: index / 16 * 100 + '%' }}>{String(index + 6).padStart(2, '0')}:00</span>)}</div>{days.map(day => <div className="hourly-day" key={dateKey(day)}>{forDay(day).map((row, index) => {
      const start = Math.max(360, minute(row.starts_at)), end = Math.min(1320, minute(row.ends_at));
      const overlaps = forDay(day).filter(other => minute(other.starts_at) < minute(row.ends_at) && minute(other.ends_at) > minute(row.starts_at));
      const lane = Math.max(0, overlaps.indexOf(row));
      return start < end ? <button key={index} className="hourly-event" style={{ '--tile': ['#31866c', '#6775ad', '#ad864d'][index % 3], top: (start - 360) / 960 * 100 + '%', height: `calc(${(end - start) / 960 * 100}% - 4px)`, left: `calc(${lane / overlaps.length * 100}% + 4px)`, width: `calc(${100 / overlaps.length}% - 8px)` }} onClick={() => setSelected({ ...row, date: dateKey(day) })}><strong>{row.course_title || row.title}</strong><span className="hourly-code">{row.section_code}</span><span>{String(row.starts_at).slice(0, 5)}–{String(row.ends_at).slice(0, 5)}</span><span>Phòng {row.room}</span><span>{row.lecturer_name || 'Chưa phân công giảng viên'}</span></button> : null;
    })}</div>)}</div></div>}
    {!rows.some(row => String(row.semester_id) === semester) && <Empty title="Học kỳ này chưa có lịch học" />}
    {selected && <Modal title={selected.course_title || selected.title} onClose={() => setSelected(null)}><Facts value={selected} fields={['section_code', 'date', 'starts_at', 'ends_at', 'room', 'lecturer_name', 'credits']} /><p>{dayName(selected.day_of_week)} · {display(selected.date, 'starts_on')}</p></Modal>}
  </section>;
}
