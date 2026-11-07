import React, { useMemo, useState } from "react";
import "./Schedule.css";
import Icon from "../../../components/common/Icon.jsx";
import {
  STUDENT_ID,
  WEEKDAYS,
  EXAM_SCHEDULES,
  semesterLabel,
  semesterDates,
  getCourse,
  getSection,
} from "../../../data/portalData.js";
import {
  Badge,
  Button,
  Card,
  Empty,
  Field,
  Modal,
  PageHeader,
  todayVN,
  displayDay,
} from "../../../components/ui.jsx";

const TIMES = [
  ["07:30", "09:50"],
  ["09:55", "12:15"],
  ["13:00", "15:20"],
  ["15:25", "17:45"],
];
const parseDate = (value) => new Date(`${value}T12:00:00`);
const mondayOf = (date) => {
  const monday = new Date(date);
  monday.setDate(monday.getDate() - ((monday.getDay() + 6) % 7));
  return monday;
};
const isoDay = (date) => ((date.getDay() + 6) % 7) + 1;
const dateKey = (date) =>
  `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
const shortDate = (date) =>
  date.toLocaleDateString("vi-VN", { day: "2-digit", month: "2-digit" });
const displayDate = (date) => date.toLocaleDateString("vi-VN");

export default function Schedule({ state, role, update, notify, view = "classes", onViewChange }) {
  const [selectedSection, setSelectedSection] = useState(null);
  const [editingSection, setEditingSection] = useState(null);
  const semesters = useMemo(
    () =>
      [...new Set(state.sections.map((section) => section.semester))]
        .filter(Boolean)
        .sort(),
    [state.sections],
  );
  const [semester, setSemester] = useState(
    () =>
      state.sections.find((section) =>
        role === "lecturer"
          ? section.teacher === "Trần Quốc Huy"
          : state.enrollmentIds.includes(section.id),
      )?.semester ||
      semesters[0] ||
      "",
  );
  const semesterPeriod = semesterDates(semester);
  const today = new Date();
  const todayWithinSemester =
    semesterPeriod &&
    dateKey(today) >= semesterPeriod.startsOn &&
    dateKey(today) <= semesterPeriod.endsOn;
  const [selectedDate, setSelectedDate] = useState(() =>
    todayWithinSemester
      ? today
      : semesterPeriod?.startsOn
        ? parseDate(semesterPeriod.startsOn)
        : today,
  );
  const [monthCursor, setMonthCursor] = useState(() => {
    const date = todayWithinSemester
      ? today
      : semesterPeriod?.startsOn
        ? parseDate(semesterPeriod.startsOn)
        : today;
    return new Date(date.getFullYear(), date.getMonth(), 1);
  });
  const owned =
    role === "lecturer"
      ? state.sections.filter(
          (section) =>
            section.teacher === "Trần Quốc Huy" &&
            section.semester === semester,
        )
      : state.enrollmentIds
          .map((id) => getSection(state, id))
          .filter((section) => section?.semester === semester);
  const weekStart = mondayOf(selectedDate);
  const weekDates = Array.from({ length: 6 }, (_, index) => {
    const date = new Date(weekStart);
    date.setDate(weekStart.getDate() + index);
    return date;
  });
  const monthDays = (() => {
    const first = new Date(monthCursor.getFullYear(), monthCursor.getMonth(), 1);
    const gridStart = mondayOf(first);
    return Array.from({ length: 42 }, (_, index) => {
      const date = new Date(gridStart);
      date.setDate(gridStart.getDate() + index);
      return date;
    });
  })();
  const roster = selectedSection
    ? [
        ...new Set([
          ...state.grades
            .filter((grade) => grade.sectionId === selectedSection.id)
            .map((grade) => grade.studentId),
          ...(state.enrollmentIds.includes(selectedSection.id)
            ? [STUDENT_ID]
            : []),
        ]),
      ]
        .map((studentId) =>
          state.students.find((student) => student.id === studentId),
        )
        .filter(Boolean)
    : [];
  const inSemester = (date) =>
    !semesterPeriod ||
    (dateKey(date) >= semesterPeriod.startsOn &&
      dateKey(date) <= semesterPeriod.endsOn);
  const classesFor = (date, start, end) =>
    inSemester(date)
      ? owned.filter(
          (section) =>
            section.day === isoDay(date) &&
            section.start >= start &&
            section.start < end,
        )
      : [];
  const chooseSemester = (term) => {
    setSemester(term);
    const startsOn = semesterDates(term)?.startsOn;
    if (startsOn) {
      const date = parseDate(startsOn);
      setSelectedDate(date);
      setMonthCursor(new Date(date.getFullYear(), date.getMonth(), 1));
    }
  };
  const moveWeek = (amount) => {
    const next = new Date(selectedDate);
    next.setDate(next.getDate() + amount * 7);
    if (semesterPeriod) {
      const nextEnd = new Date(next);
      nextEnd.setDate(nextEnd.getDate() + 5);
      if (
        dateKey(nextEnd) < semesterPeriod.startsOn ||
        dateKey(next) > semesterPeriod.endsOn
      )
        return;
    }
    setSelectedDate(next);
    setMonthCursor(new Date(next.getFullYear(), next.getMonth(), 1));
  };
  const goToCurrentWeek = () => {
    const target =
      semesterPeriod &&
      (dateKey(today) < semesterPeriod.startsOn ||
        dateKey(today) > semesterPeriod.endsOn)
        ? parseDate(semesterPeriod.startsOn)
        : today;
    setSelectedDate(target);
    setMonthCursor(new Date(target.getFullYear(), target.getMonth(), 1));
  };
  const moveMonth = (amount) =>
    setMonthCursor(
      (current) =>
        new Date(current.getFullYear(), current.getMonth() + amount, 1),
    );
  const saveSchedule = () => {
    if (!editingSection?.room.trim() || editingSection.start >= editingSection.end)
      return notify("Vui lòng kiểm tra phòng học và khung giờ.", "error");
    const conflict = state.sections.some(
      (section) =>
        section.id !== editingSection.id &&
        section.teacher === "Trần Quốc Huy" &&
        section.semester === editingSection.semester &&
        section.day === Number(editingSection.day) &&
        section.start < editingSection.end &&
        section.end > editingSection.start,
    );
    if (conflict)
      return notify("Lịch mới bị trùng với lớp khác được phân công.", "error");
    update((current) => ({
      ...current,
      sections: current.sections.map((section) =>
        section.id === editingSection.id
          ? {
              ...section,
              day: Number(editingSection.day),
              start: editingSection.start,
              end: editingSection.end,
              room: editingSection.room.trim(),
            }
          : section,
      ),
    }));
    setSelectedSection(null);
    setEditingSection(null);
    notify("Đã cập nhật lịch lớp học phần.", "success");
  };

  return (
    <>
      <PageHeader
        title={role === "lecturer" ? "Lịch giảng dạy" : "Thời khóa biểu"}
        description={`${semesterLabel(semester)}${semesterPeriod ? ` · ${displayDate(parseDate(semesterPeriod.startsOn))} – ${displayDate(parseDate(semesterPeriod.endsOn))}` : ""}.`}
        action={
          <Badge tone="green" dot>
            {owned.length} lớp học phần
          </Badge>
        }
      />
      <div className="schedule-semesters" role="tablist" aria-label="Chọn học kỳ">
        {semesters.map((term) => (
          <button
            key={term}
            type="button"
            role="tab"
            aria-selected={semester === term}
            className={semester === term ? "active" : ""}
            onClick={() => chooseSemester(term)}
          >
            {semesterLabel(term)}
          </button>
        ))}
      </div>
      <div className="schedule-view-picker">
        <span className="schedule-view-icon"><Icon name={view === "exams" ? "grades" : "calendar"} size={23} /></span>
        <label>
          <span>TRA CỨU LỊCH CÁ NHÂN</span>
          <select aria-label="Chọn lịch học hoặc lịch thi" value={view} onChange={event => onViewChange?.(event.target.value)}>
            <option value="classes">Lịch học</option>
            <option value="exams">Lịch thi</option>
          </select>
        </label>
        <Icon name="down" size={19} />
      </div>
      {view === "classes" && <>
      <div className="week-summary">
        <div>
          <Icon name="calendar" size={21} />
          <div>
            <b>
              {shortDate(weekDates[0])} – {shortDate(weekDates[5])}
            </b>
            <span>{todayVN()} · Chọn ngày để xem lịch tuần</span>
          </div>
        </div>
        <div className="week-summary-actions">
          <Button kind="outline" small onClick={goToCurrentWeek}>
            Tuần hiện tại
          </Button>
          <Button
            kind="outline"
            small
            disabled={
              !!semesterPeriod &&
              (() => {
                const previousEnd = mondayOf(selectedDate);
                previousEnd.setDate(previousEnd.getDate() - 1);
                return dateKey(previousEnd) < semesterPeriod.startsOn;
              })()
            }
            onClick={() => moveWeek(-1)}
          >
            ←
          </Button>
          <Button
            kind="outline"
            small
            disabled={
              !!semesterPeriod &&
              (() => {
                const next = new Date(selectedDate);
                next.setDate(next.getDate() + 7);
                return dateKey(next) > semesterPeriod.endsOn;
              })()
            }
            onClick={() => moveWeek(1)}
          >
            →
          </Button>
        </div>
      </div>
      <div className="schedule-content">
        <Card className="calendar-card">
          <div className="schedule-wrap">
            <div className="schedule-grid" key={dateKey(weekDates[0])}>
              <div className="schedule-head time-col">Ca học</div>
              {weekDates.map((date) => (
                <div className="schedule-head" key={dateKey(date)}>
                  <span>{WEEKDAYS[isoDay(date) - 1]}</span>
                  <b>{shortDate(date)}</b>
                </div>
              ))}
              {TIMES.map(([start, end], index) => (
                <React.Fragment key={start}>
                  <div className="time-block">
                    <strong>Ca {index + 1}</strong>
                    <span>{start}</span>
                    <span>{end}</span>
                  </div>
                  {weekDates.map((date) => (
                    <div className="schedule-cell" key={`${start}-${dateKey(date)}`}>
                      {classesFor(date, start, end).map((section) => (
                        <button
                          key={section.id}
                          className="class-tile"
                          style={{ "--tile": section.color }}
                          type="button"
                          aria-haspopup="dialog"
                          onClick={() => setSelectedSection(section)}
                        >
                          <strong>{getCourse(section.courseId)?.name}</strong>
                          <span>{section.code}</span>
                          <small>
                            <Icon name="clock" size={13} />
                            {section.start}–{section.end}
                          </small>
                          <small>
                            <Icon name="building" size={13} />
                            {section.room}
                          </small>
                        </button>
                      ))}
                    </div>
                  ))}
                </React.Fragment>
              ))}
            </div>
          </div>
        </Card>
        <Card className="month-calendar">
          <div className="month-calendar-head">
            <div>
              <b>
                {monthCursor.toLocaleDateString("vi-VN", {
                  month: "long",
                  year: "numeric",
                })}
              </b>
              <span>Lịch tháng · Chọn ngày</span>
            </div>
            <div>
              <button type="button" onClick={() => moveMonth(-1)} aria-label="Tháng trước">‹</button>
              <button type="button" onClick={() => moveMonth(1)} aria-label="Tháng sau">›</button>
            </div>
          </div>
          <div className="month-calendar-grid month-calendar-weekdays">
            {["T2", "T3", "T4", "T5", "T6", "T7", "CN"].map((day) => (
              <span key={day}>{day}</span>
            ))}
          </div>
          <div
            className="month-calendar-grid"
            key={`${monthCursor.getFullYear()}-${monthCursor.getMonth()}`}
          >
            {monthDays.map((date) => {
              const hasClass =
                inSemester(date) &&
                owned.some((section) => section.day === isoDay(date));
              const hasExam = EXAM_SCHEDULES.some(
                (exam) =>
                  exam.semester === semester && exam.date === dateKey(date),
              );
              const isSelected = dateKey(date) === dateKey(selectedDate);
              const sameMonth = date.getMonth() === monthCursor.getMonth();
              return (
                <button
                  type="button"
                  key={dateKey(date)}
                  className={`${sameMonth ? "" : "outside-month"} ${isSelected ? "selected-day" : ""} ${hasClass ? "has-class" : ""} ${hasExam ? "has-exam" : ""}`}
                  aria-pressed={isSelected}
                  onClick={() => setSelectedDate(date)}
                >
                  {date.getDate()}
                  {(hasClass || hasExam) && <i />}
                </button>
              );
            })}
          </div>
          <div className="month-calendar-legend">
            <i /> Có lớp
            <i className="exam-legend" /> Có lịch thi
          </div>
          <p className="month-calendar-hint">
            {owned.length
              ? "Chọn một ngày để xem lịch trong tuần tương ứng."
              : "Chưa có lớp được phân công hoặc đăng ký."}
          </p>
        </Card>
      </div>
      </>}
      {view === "exams" && <section className="exam-schedule">
        <button
          type="button"
          className="exam-schedule-toggle"
          aria-expanded={true}
        >
          <span>
            <Icon name="calendar" size={18} />
            <span>
              <strong>Lịch thi học kỳ</strong>
              <small>{EXAM_SCHEDULES.filter((exam) => exam.semester === semester).length} lịch thi · {semesterLabel(semester)}</small>
            </span>
          </span>
        </button>
        {(
          <div className="exam-schedule-body">
            <p className="exam-schedule-notice">
              Lịch thi dưới đây là dữ liệu mẫu để minh họa giao diện, chưa phải
              lịch chính thức của trường. Phòng Đào tạo cần xác nhận ngày và ca
              thi trước khi áp dụng.
            </p>
            {EXAM_SCHEDULES.filter((exam) => exam.semester === semester).length ? (
              <div className="table-wrap">
                <table className="data-table">
                  <thead><tr><th>Ngày thi</th><th>Học phần</th><th>Loại</th><th>Giờ thi</th><th>Phòng</th></tr></thead>
                  <tbody>
                    {EXAM_SCHEDULES.filter((exam) => exam.semester === semester).map((exam) => (
                      <tr key={exam.id}>
                        <td>{displayDate(parseDate(exam.date))}</td>
                        <td><strong>{getCourse(exam.courseId)?.name}</strong><small className="cell-sub">{exam.courseId}</small></td>
                        <td>{exam.type}</td>
                        <td>{exam.start}–{exam.end}</td>
                        <td>{exam.room}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : <Empty title="Chưa có lịch thi trong học kỳ này" />}
          </div>
        )}
      </section>}
      <div className="hint-line">
        <Icon name="info" size={16} />
        Lịch lớp được lặp theo tuần trong ngày bắt đầu/kết thúc học kỳ. Dùng lịch
        tháng hoặc nút tuần trước/sau để tra các tuần trong kỳ.
      </div>
      {selectedSection && (
        <Modal
          title={getCourse(selectedSection.courseId)?.name || "Chi tiết ca học"}
          subtitle={`Lớp học phần ${selectedSection.code}`}
          wide
          onClose={() => setSelectedSection(null)}
        >
          <div className="schedule-detail-grid">
            <div><span>Giảng viên</span><strong>{selectedSection.teacher}</strong></div>
            <div><span>Ca học</span><strong>{displayDay(selectedSection.day)} · {selectedSection.start}–{selectedSection.end}</strong></div>
            <div><span>Phòng học</span><strong>{selectedSection.room}</strong></div>
            <div><span>Sĩ số</span><strong>{selectedSection.registered}/{selectedSection.limit} sinh viên</strong></div>
            <div><span>Học kỳ</span><strong>{semesterLabel(selectedSection.semester)}</strong></div>
            {semesterPeriod && <div><span>Thời gian học kỳ</span><strong>{displayDate(parseDate(semesterPeriod.startsOn))} – {displayDate(parseDate(semesterPeriod.endsOn))}</strong></div>}
          </div>
          {role === "lecturer" &&
            selectedSection.teacher === "Trần Quốc Huy" && (
              <div className="schedule-edit-action">
                <Button
                  kind="outline"
                  icon="edit"
                  onClick={() => setEditingSection({ ...selectedSection })}
                >
                  Chỉnh lịch học
                </Button>
              </div>
            )}
          <div className="schedule-roster">
            <h3>Danh sách lớp có dữ liệu</h3>
            {roster.length > 0 ? (
              <div className="table-wrap">
                <table className="data-table">
                  <thead><tr><th>Mã sinh viên</th><th>Họ và tên</th><th>Lớp hành chính</th></tr></thead>
                  <tbody>
                    {roster.map((student) => (
                      <tr key={student.id}><td>{student.id}</td><td>{student.name}</td><td>{student.className}</td></tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : (
              <Empty icon="users" title="Chưa có danh sách sinh viên" description="Chưa có dữ liệu đăng ký hoặc điểm cho lớp này." />
            )}
            <p>
              Danh sách gồm sinh viên có dữ liệu đăng ký hoặc điểm trong bản
              hiện tại; có thể chưa đại diện toàn bộ sĩ số lớp.
            </p>
          </div>
        </Modal>
      )}
      {editingSection && (
        <Modal
          title={`Chỉnh lịch · ${editingSection.code}`}
          subtitle={getCourse(editingSection.courseId)?.name}
          onClose={() => setEditingSection(null)}
        >
          <div className="form-grid">
            <Field label="Thứ">
              <select
                className="control"
                value={editingSection.day}
                onChange={(event) =>
                  setEditingSection((current) => ({
                    ...current,
                    day: Number(event.target.value),
                  }))
                }
              >
                {WEEKDAYS.map((day, index) => (
                  <option value={index + 1} key={day}>{day}</option>
                ))}
              </select>
            </Field>
            <Field label="Phòng học">
              <input
                className="control"
                value={editingSection.room}
                onChange={(event) =>
                  setEditingSection((current) => ({
                    ...current,
                    room: event.target.value,
                  }))
                }
              />
            </Field>
            <Field label="Giờ bắt đầu">
              <input
                className="control"
                type="time"
                value={editingSection.start}
                onChange={(event) =>
                  setEditingSection((current) => ({
                    ...current,
                    start: event.target.value,
                  }))
                }
              />
            </Field>
            <Field label="Giờ kết thúc">
              <input
                className="control"
                type="time"
                value={editingSection.end}
                onChange={(event) =>
                  setEditingSection((current) => ({
                    ...current,
                    end: event.target.value,
                  }))
                }
              />
            </Field>
          </div>
          <div className="modal-actions">
            <Button kind="outline" onClick={() => setEditingSection(null)}>Hủy</Button>
            <Button icon="check" onClick={saveSchedule}>Lưu lịch</Button>
          </div>
        </Modal>
      )}
    </>
  );
}
