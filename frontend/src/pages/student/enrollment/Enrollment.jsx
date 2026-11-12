import Pagination, { usePagination } from "../../../components/common/Pagination.jsx";
import CourseDetail from "./CourseDetail.jsx";
import React, { useMemo, useState } from "react";
import "./Enrollment.css";
import Icon from "../../../components/common/Icon.jsx";
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
} from "../../../data/portalData.js";
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
} from "../../../components/ui.jsx";
import ConfirmDialog from "../../../components/common/ConfirmDialog.jsx";

export default function Enrollment({ state, update, notify, navigate }) {
  const [search, setSearch] = useState(""),
    [tab, setTab] = useState("all"),
    [selectedCourse, setSelectedCourse] = useState(null),
    [semester, setSemester] = useState(
      () =>
        state.sections.find((s) => state.enrollmentIds.includes(s.id))
          ?.semester ||
        state.sections[0]?.semester ||
        "",
    ),
    [pendingCancellation, setPendingCancellation] = useState(null);
  const semesters = useMemo(
    () =>
      [...new Set(state.sections.map((section) => section.semester))]
        .filter(Boolean)
        .sort(),
    [state.sections],
  );
  const semesterSections = state.sections.filter(
    (section) => section.semester === semester,
  );
  const courses = semesterSections
    .filter((s) =>
      tab === "mine"
        ? state.enrollmentIds.includes(s.id)
        : tab === "available"
          ? !state.enrollmentIds.includes(s.id)
          : true,
    )
    .filter((s) =>
      `${s.code} ${getCourse(s.courseId, state)?.name} ${s.teacher}`
        .toLowerCase()
        .includes(search.toLowerCase()),
    );
  const registered = state.enrollmentIds
    .map((id) => getSection(state, id))
    .filter((section) => section?.semester === semester);
  const credits = registered.reduce(
    (sum, s) => sum + (getCourse(s.courseId, state)?.credits || 0),
    0,
  );
  function toggle(section) {
    const selected = state.enrollmentIds.includes(section.id);
    const term = state.semesters.find(item => item.id === section.semester);
    if (!term?.registrationOpen) return notify("Học kỳ đã đóng đăng ký/hủy học phần.", "error");
    if (state.issuedInvoices.some(item => item.studentId === STUDENT_ID && item.semester === section.semester)) return notify("Hóa đơn học kỳ đã chốt khi thanh toán. Liên hệ Phòng Đào tạo để điều chỉnh học phần.", "error");
    if (state.students.find(item => item.id === STUDENT_ID)?.status !== "STUDYING") return notify("Trạng thái sinh viên không cho phép đăng ký học phần.", "error");
    if (selected) {
      if (
        ["PUBLISHED", "APPROVED"].includes(
          getGradeSheet(state, section.id).status,
        )
      )
      return notify(
          "Học phần đã có kết quả, không thể hủy đăng ký.",
          "error",
        );
      setPendingCancellation(section);
      return;
    }
    if (section.registered >= section.limit)
      return notify("Lớp học phần đã đủ sĩ số.", "error");
    const clash = registered.some(
      (x) =>
        x.day === section.day && section.start < x.end && x.start < section.end,
    );
    if (clash)
      return notify(
        "Không thể đăng ký: lớp này trùng thời khóa biểu hiện tại.",
        "error",
      );
    if (credits + (getCourse(section.courseId, state)?.credits || 0) > 24)
      return notify("Không được đăng ký vượt quá 24 tín chỉ trong học kỳ.", "error");
    if (registered.some((x) => x.courseId === section.courseId))
      return notify("Bạn đã đăng ký học phần này ở nhóm khác.", "error");
    update((s) => ({
      ...s,
      enrollmentIds: [...s.enrollmentIds, section.id],
      sections: s.sections.map((x) =>
        x.id === section.id ? { ...x, registered: x.registered + 1 } : x,
      ),
    }));
    notify(
      "Đăng ký thành công! Thời khóa biểu và học phí dự kiến đã cập nhật.",
      "success",
    );
  }
  function confirmCancellation() {
    const section = pendingCancellation;
    if (!section) return;
    update((s) => ({
      ...s,
      enrollmentIds: s.enrollmentIds.filter((id) => id !== section.id),
      sections: s.sections.map((item) =>
        item.id === section.id
          ? { ...item, registered: Math.max(0, item.registered - 1) }
          : item,
      ),
    }));
    notify("Đã hủy đăng ký học phần.", "success");
    setPendingCancellation(null);
  }
  const pagination = usePagination(courses, semester + tab + search);
  return (
    <>
      <PageHeader
        title="Đăng ký học phần"
        description={`Tìm kiếm và đăng ký lớp học phần · ${semesterLabel(semester)}.`}
        action={
          <Button
            icon="calendar"
            kind="outline"
            onClick={() => navigate("schedule")}
          >
            Xem thời khóa biểu
          </Button>
        }
      />
      <div className="summary-strip">
        <div>
          <span>HỌC PHẦN ĐÃ ĐĂNG KÝ</span>
          <strong>
            {registered.length} <small>lớp</small>
          </strong>
        </div>
        <div>
          <span>TỔNG TÍN CHỈ</span>
          <strong>
            {credits} <small>/ 24 tín chỉ</small>
          </strong>
        </div>
        <div>
          <span>HỌC PHÍ DỰ KIẾN</span>
          <strong>{money(credits * PRICE_PER_CREDIT)}</strong>
        </div>
        <Badge tone="green" dot>
          Đang mở đăng ký
        </Badge>
      </div>
      <div className="enrollment-checkout">
        <p>Đã chọn xong học phần? Tiếp tục kiểm tra và thanh toán học phí.</p>
        <Button icon="wallet" disabled={!state.enrollmentIds.length} onClick={() => navigate("payment")}>Thanh toán học phí</Button>
      </div>
      <Card
        title="Danh sách lớp học phần"
        subtitle={`Danh sách lớp mở trong ${semesterLabel(semester)} · ${semesterDates(semester, state)?.startsOn ? `${new Date(`${semesterDates(semester, state).startsOn}T12:00:00`).toLocaleDateString("vi-VN")} – ${new Date(`${semesterDates(semester, state).endsOn}T12:00:00`).toLocaleDateString("vi-VN")}` : "Chưa cập nhật ngày học kỳ"}.`}
        extra={
          <div className="table-tools">
            <div className="searchbox">
              <Icon name="search" size={17} />
              <input
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Tìm mã môn, tên, giảng viên..."
              />
            </div>
          </div>
        }
      >
        <div className="semester-tabs" role="tablist" aria-label="Chọn học kỳ">
          {semesters.map((term) => {
            const count = new Set(
              state.sections
                .filter((section) => section.semester === term)
                .map((section) => section.courseId),
            ).size;
            return (
              <button
                key={term}
                type="button"
                role="tab"
                aria-selected={semester === term}
                className={semester === term ? "active" : ""}
                onClick={() => setSemester(term)}
              >
                <span>{semesterLabel(term)}</span>
                <small>{count} học phần</small>
              </button>
            );
          })}
        </div>
        <div className="tabs">
          {[
            ["all", "Tất cả lớp"],
            ["available", "Chưa đăng ký"],
            ["mine", "Đã đăng ký"],
          ].map(([id, t]) => (
            <button
              key={id}
              className={tab === id ? "active" : ""}
              onClick={() => setTab(id)}
            >
              {t}
            </button>
          ))}
        </div>
        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>Học phần</th>
                <th>Giảng viên</th>
                <th>Lịch học</th>
                <th>Tín chỉ</th>
                <th>Sĩ số</th>
                <th>Trạng thái</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {pagination.rows.map((s) => {
                const c = getCourse(s.courseId, state),
                  mine = state.enrollmentIds.includes(s.id);
                return (
                  <tr key={s.id}>
                    <td>
                      <div className="course-name">
                        <div
                          className="mini-icon"
                          style={{ background: s.color + "20", color: s.color }}
                        >
                          <Icon name="bookopen" size={18} />
                        </div>
                        <div>
                          <b>{c?.name}</b>
                          <small>{s.code}</small>
                          <button
                            type="button"
                            className="course-detail-trigger"
                            onClick={() => setSelectedCourse(c?.id)}
                          >
                            Chi tiết học phần
                          </button>
                        </div>
                      </div>
                    </td>
                    <td>{s.teacher}</td>
                    <td>
                      <span className="nowrap">
                        {displayDay(s.day)}, {s.start}
                      </span>
                      <small className="cell-sub">Phòng {s.room}</small>
                    </td>
                    <td>
                      <b>{c?.credits}</b>
                    </td>
                    <td>
                      <div className="capacity">
                        <span>
                          {s.registered}/{s.limit}
                        </span>
                        <LevelBar
                          value={(s.registered / s.limit) * 100}
                          color={
                            s.registered >= s.limit ? "#d56f68" : "#6c8ff4"
                          }
                        />
                      </div>
                    </td>
                    <td>
                      <Badge
                        tone={
                          mine
                            ? "green"
                            : s.registered >= s.limit
                              ? "red"
                              : "blue"
                        }
                        dot
                      >
                        {mine
                          ? "Đã đăng ký"
                          : s.registered >= s.limit
                            ? "Hết chỗ"
                            : "Còn chỗ"}
                      </Badge>
                    </td>
                    <td>
                      <Button
                        small
                        kind={mine ? "danger-outline" : "primary"}
                        disabled={!mine && s.registered >= s.limit}
                        onClick={() => toggle(s)}
                      >
                        {mine ? "Hủy" : "Đăng ký"}
                      </Button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
      <Pagination {...pagination} />

          {courses.length === 0 && (
            <Empty
              icon="search"
              title="Không có học phần phù hợp"
              description="Hãy thử từ khóa hoặc bộ lọc khác."
            />
          )}
        </div>
      </Card>
      <CourseDetail state={state} selectedCourse={selectedCourse} setSelectedCourse={setSelectedCourse} semester={semester} semesterSections={semesterSections} />
      {pendingCancellation && (
        <ConfirmDialog
          title="Xác nhận hủy học phần"
          message={`Bạn có chắc muốn hủy đăng ký học phần ${pendingCancellation.code} không?`}
          confirmLabel="Hủy đăng ký"
          onConfirm={confirmCancellation}
          onCancel={() => setPendingCancellation(null)}
        />
      )}
    </>
  );
}
