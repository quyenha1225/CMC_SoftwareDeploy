import Pagination, { usePagination } from "../../../components/common/Pagination.jsx";
import GradeDetail from "./GradeDetail.jsx";
import React, { useState } from "react";
import "./Results.css";
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

export default function Results({ state }) {
  const rows = state.grades
    .filter((g) => g.studentId === STUDENT_ID)
    .map((g) => ({
      ...g,
      section: getSection(state, g.sectionId),
      sheet: getGradeSheet(state, g.sectionId),
    }))
    .filter((g) => g.sheet.status === "PUBLISHED");
  const semesters = [...new Set(rows.map((row) => row.section?.semester))]
    .filter(Boolean)
    .sort();
  const [semester, setSemester] = useState(semesters[0] || "");
  const [selectedGrade, setSelectedGrade] = useState(null);
  const visibleRows = rows.filter((row) => row.section?.semester === semester);
  const semesterTotal = visibleRows.reduce(
    (sum, grade) =>
      sum + gradeTotal(grade) * (getCourse(grade.section?.courseId, state)?.credits || 0),
    0,
  );
  const credits = visibleRows.reduce(
    (a, g) => a + (getCourse(g.section?.courseId, state)?.credits || 0),
    0,
  );
  const avg = credits ? (semesterTotal / credits).toFixed(2) : "—";


  const pagination = usePagination(visibleRows, semester);
  return (
    <>
      <PageHeader
        title="Kết quả học tập"
        description={`Tra cứu điểm đã công bố · ${semesterLabel(semester)}${semesterDates(semester, state)?.startsOn ? ` · ${new Date(`${semesterDates(semester, state).startsOn}T12:00:00`).toLocaleDateString("vi-VN")} – ${new Date(`${semesterDates(semester, state).endsOn}T12:00:00`).toLocaleDateString("vi-VN")}` : ""}.`}
        action={
          <Button
            kind="outline"
            icon="download"
            onClick={() =>
              csvDownload("bang-diem.csv", [
                [
                  "Học phần",
                  "Tín chỉ",
                  "Chuyên cần",
                  "Giữa kỳ",
                  "Cuối kỳ",
                  "Tổng kết",
                ],
                ...rows.map((g) => [
                  getCourse(g.section?.courseId, state)?.name,
                  getCourse(g.section?.courseId, state)?.credits,
                  g.attendance,
                  g.midterm,
                  g.final,
                  gradeTotal(g),
                ]),
              ])
            }
          >
            Xuất bảng điểm CSV
          </Button>
        }
      />
      <div className="stats-grid three">
        <Stat
          icon="grades"
          label="Điểm TB theo tín chỉ"
          value={avg}
          hint="Thang 10 · Môn đã công bố"
        />
        <Stat
          icon="book"
          label="Học phần có kết quả"
          value={`${visibleRows.length}`}
          hint="Đã công bố điểm"
          tone="green"
        />
        <Stat
          icon="graduation"
          label="Tín chỉ có kết quả"
          value={`${credits}`}
          hint="Theo học kỳ đã chọn"
          tone="purple"
        />
      </div>
      <Card
        title="Bảng điểm học phần"
        subtitle="Những bảng điểm chưa công bố sẽ không xuất hiện với tài khoản Sinh viên"
      >
        <div className="semester-tabs" role="tablist" aria-label="Lọc kết quả theo học kỳ">
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
                <th>Học phần</th>
                <th>Số TC</th>
                <th>Chuyên cần</th>
                <th>Giữa kỳ</th>
                <th>Cuối kỳ</th>
                <th>Tổng kết</th>
                <th>Trạng thái</th>
                <th>Thao tác</th>
              </tr>
            </thead>
            <tbody>
              {pagination.rows.map((g) => (
                <tr key={g.sectionId}>
                  <td>
                    <b>{getCourse(g.section?.courseId, state)?.name}</b>
                    <small className="cell-sub">{g.section?.code}</small>
                  </td>
                  <td>{getCourse(g.section?.courseId, state)?.credits}</td>
                  <td>{g.attendance?.toFixed(1)}</td>
                  <td>{g.midterm?.toFixed(1)}</td>
                  <td>{g.final?.toFixed(1)}</td>
                  <td>
                    <GradeChip score={gradeTotal(g)} />
                  </td>
                  <td>
                    <Badge tone="green" dot>
                      Đã công bố
                    </Badge>
                  </td>
                  <td>
                    <Button small kind="outline" onClick={() => setSelectedGrade(g)}>
                      Chi tiết
                    </Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
      <Pagination {...pagination} />

          {rows.length === 0 && <Empty title="Chưa có kết quả chính thức" />}
        </div>
      </Card>
      <GradeDetail state={state} selectedGrade={selectedGrade} setSelectedGrade={setSelectedGrade} />
      <div className="hint-line">
        <Icon name="shield" size={16} /> Điểm tổng kết được tính: 10% chuyên cần
        + 30% giữa kỳ + 60% cuối kỳ .
      </div>
    </>
  );
}
