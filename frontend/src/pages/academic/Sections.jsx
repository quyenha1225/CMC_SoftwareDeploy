import Pagination, { usePagination } from "../../components/common/Pagination.jsx";
import React, { useState } from "react";
import "./Sections.css";
import Icon from "../../components/common/Icon.jsx";
import {
  ROLE_NAMES,
  ACCOUNTS,
  STUDENT_ID,
  WEEKDAYS,
  COURSE_LIST,
  semesterLabel,
  semesterDates,
  initialState,
  getCourse,
  getSection,
  getGradeSheet,
  gradeTotal,
  courseLabel,
  money,
  gradeStatusText,
  requestStatusText,
  studentStatusText,
  PRICE_PER_CREDIT,
} from "../../data/portalData.js";
import {
  Badge,
  Button,
  Card,
  PageHeader,
  Avatar,
  Stat,
  Empty,
  Modal,
  Field,
  LevelBar,
  GradeChip,
  TextRows,
  Donut,
  AreaChart,
  todayVN,
  number,
  displayDay,
  slot,
  colorByStatus,
  csvDownload,
} from "../../components/ui.jsx";

export default function Sections({ state, update, notify }) {
  const [search, setSearch] = useState(""),
    [edit, setEdit] = useState(null),
    [semester, setSemester] = useState("2026-1");
  const semesters = [...new Set(state.sections.map((section) => section.semester))]
    .filter(Boolean)
    .sort();
  const items = state.sections.filter(
    (section) =>
      section.semester === semester &&
      `${section.code} ${getCourse(section.courseId, state)?.name} ${section.teacher}`
        .toLowerCase()
        .includes(search.toLowerCase()),
  );
  const period = semesterDates(semester, state);
  function save() {
    if (
      !edit.code.trim() ||
      !edit.teacher.trim() ||
      !edit.room.trim() ||
      !edit.courseId ||
      !Number.isInteger(Number(edit.limit)) || Number(edit.limit) < 1
    )
      return notify("Vui lòng điền đầy đủ thông tin lớp học phần.", "error");
    if (edit.start >= edit.end)
      return notify("Giờ kết thúc phải sau giờ bắt đầu.", "error");
    if (state.sections.some((s) => s.code === edit.code && s.id !== edit.id))
      return notify("Mã lớp học phần đã tồn tại.", "error");
    if (Number(edit.limit) < (edit.registered || 0)) return notify("Sĩ số tối đa không được nhỏ hơn số đã đăng ký.", "error");
    if (state.sections.some(section => section.id !== edit.id && section.semester === edit.semester && section.day === Number(edit.day) && section.start < edit.end && edit.start < section.end && (section.teacher === edit.teacher || section.room === edit.room))) return notify("Trùng lịch giảng viên hoặc phòng học.", "error");
    const payload = {
      ...edit,
      limit: Number(edit.limit),
      day: Number(edit.day),
      semester: edit.semester,
      teacherId: state.lecturers.find(item => item.name === edit.teacher)?.id,
    };
    update((s) => ({
      ...s,
      sections: edit.id
        ? s.sections.map((x) => (x.id === edit.id ? payload : x))
        : [
            ...s.sections,
            {
              ...payload,
              id: `SEC-${Date.now()}`,
              registered: 0,
              color: "#5676e9",
            },
          ],
    }));
    notify("Đã lưu lớp học phần.", "success");
    setEdit(null);
  }
  const pagination = usePagination(items, search + semester);
  return (
    <>
      <PageHeader
        title="Quản lý lớp học phần"
        description="Phân công giảng viên, lịch học, phòng học và giới hạn sĩ số."
        action={
          <Button
            icon="plus"
            onClick={() =>
              setEdit({
                id: "",
                code: "",
                courseId: "IT201",
                teacher: "Trần Quốc Huy",
                room: "",
                day: 1,
                start: "07:30",
                end: "09:50",
                limit: 40,
                semester: getCourse("IT201", state)?.semester || "2026-1",
              })
            }
          >
            Mở lớp học phần
          </Button>
        }
      />
      <Card
        title="Danh sách lớp học phần"
        subtitle={`${items.length} lớp học phần · ${semesterLabel(semester)}${period ? ` · ${new Date(`${period.startsOn}T12:00:00`).toLocaleDateString("vi-VN")} – ${new Date(`${period.endsOn}T12:00:00`).toLocaleDateString("vi-VN")}` : ""}`}
        extra={
          <div className="searchbox">
            <Icon name="search" size={17} />
            <input
              placeholder="Tìm tên môn, mã lớp..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
        }
      >
        <div className="semester-tabs" role="tablist" aria-label="Lọc lớp theo học kỳ">
          {semesters.map((term) => (
            <button
              key={term}
              type="button"
              role="tab"
              aria-selected={semester === term}
              className={semester === term ? "active" : ""}
              onClick={() => setSemester(term)}
            >
              {semesterLabel(term)}
            </button>
          ))}
        </div>
        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>Mã lớp</th>
                <th>Tên học phần</th>
                <th>Học kỳ</th>
                <th>Giảng viên</th>
                <th>Lịch học</th>
                <th>Phòng</th>
                <th>Sĩ số</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {pagination.rows.map((s) => (
                <tr key={s.id}>
                  <td>
                    <b>{s.code}</b>
                  </td>
                  <td>{getCourse(s.courseId, state)?.name}</td>
                  <td>{semesterLabel(s.semester)}</td>
                  <td>{s.teacher}</td>
                  <td>
                    {displayDay(s.day)}, {s.start}–{s.end}
                  </td>
                  <td>{s.room}</td>
                  <td>
                    {s.registered}/{s.limit}
                  </td>
                  <td>
                    <Button small kind="outline" onClick={() => setEdit(s)}>
                      Sửa
                    </Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
      <Pagination {...pagination} />

        </div>
      </Card>
      {edit && (
        <Modal
          title={edit.id ? "Chỉnh sửa lớp học phần" : "Mở lớp học phần mới"}
          onClose={() => setEdit(null)}
        >
          <div className="form-grid">
            <Field label="Mã lớp">
              <input
                className="control"
                value={edit.code}
                onChange={(e) =>
                  setEdit((v) => ({ ...v, code: e.target.value }))
                }
              />
            </Field>
            <Field label="Học phần">
              <select
                className="control"
                value={edit.courseId}
                onChange={(e) =>
                  setEdit((v) => ({
                    ...v,
                    courseId: e.target.value,
                    semester: v.semester,
                  }))
                }
              >
                {state.courses.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name}
                  </option>
                ))}
              </select>
            </Field>
            <Field label="Học kỳ">
              <select className="control" value={edit.semester} onChange={event => setEdit({ ...edit, semester: event.target.value })}>{state.semesters.map(term => <option key={term.id} value={term.id}>{semesterLabel(term.id)}</option>)}</select>
            </Field>
            <Field label="Giảng viên">
              <select className="control" value={edit.teacher} onChange={event => setEdit({ ...edit, teacher: event.target.value })}>{state.lecturers.map(teacher => <option key={teacher.id} value={teacher.name}>{teacher.name}</option>)}</select>
            </Field>
            <Field label="Phòng học">
              <input
                className="control"
                value={edit.room}
                onChange={(e) =>
                  setEdit((v) => ({ ...v, room: e.target.value }))
                }
              />
            </Field>
            <Field label="Thứ">
              <select
                className="control"
                value={edit.day}
                onChange={(e) =>
                  setEdit((v) => ({ ...v, day: Number(e.target.value) }))
                }
              >
                {WEEKDAYS.map((d, i) => (
                  <option key={d} value={i + 1}>
                    {d}
                  </option>
                ))}
              </select>
            </Field>
            <Field label="Sĩ số tối đa">
              <input
                className="control"
                type="number"
                min="1"
                value={edit.limit}
                onChange={(e) =>
                  setEdit((v) => ({ ...v, limit: e.target.value }))
                }
              />
            </Field>
            <Field label="Giờ bắt đầu">
              <input
                className="control"
                type="time"
                value={edit.start}
                onChange={(e) =>
                  setEdit((v) => ({ ...v, start: e.target.value }))
                }
              />
            </Field>
            <Field label="Giờ kết thúc">
              <input
                className="control"
                type="time"
                value={edit.end}
                onChange={(e) =>
                  setEdit((v) => ({ ...v, end: e.target.value }))
                }
              />
            </Field>
          </div>
          <div className="modal-actions">
            <Button kind="outline" onClick={() => setEdit(null)}>
              Hủy
            </Button>
            <Button onClick={save}>Lưu lớp</Button>
          </div>
        </Modal>
      )}
    </>
  );
}
