import React, { useState } from "react";
import "./Teaching.css";
import Icon from "../../components/common/Icon.jsx";
import {
  ROLE_NAMES,
  ACCOUNTS,
  STUDENT_ID,
  WEEKDAYS,
  COURSE_LIST,
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

export default function Teaching({ state, navigate }) {
  const sections = state.sections.filter((s) => s.teacher === "Trần Quốc Huy");
  return (
    <>
      <PageHeader
        title="Lớp học phần được phân công"
        description="Các lớp giảng dạy của tài khoản giảng viên demo."
        action={
          <Button
            kind="outline"
            icon="calendar"
            onClick={() => navigate("schedule")}
          >
            Xem lịch dạy
          </Button>
        }
      />
      <div className="stats-grid three">
        <Stat
          icon="bookopen"
          label="Lớp được phân công"
          value={`${sections.length}`}
          hint="Năm học 2026–2027"
        />
        <Stat
          icon="users"
          label="Sinh viên toàn lớp (mô phỏng)"
          value={number(sections.reduce((a, s) => a + s.registered, 0))}
          hint="Tổng sĩ số danh nghĩa"
          tone="purple"
        />
        <Stat
          icon="grades"
          label="Bảng điểm cần hoàn thiện"
          value={`${sections.filter((s) => getGradeSheet(state, s.id).status === "DRAFT" || getGradeSheet(state, s.id).status === "RETURNED").length}`}
          hint="Nhập và gửi về PĐT"
          tone="orange"
        />
      </div>
      <div className="course-card-grid">
        {sections.map((s) => (
          <Card key={s.id} className="course-card">
            <div
              className="course-card-icon"
              style={{ color: s.color, background: s.color + "1c" }}
            >
              <Icon name="bookopen" size={25} />
            </div>
            <div className="course-card-header">
              <span>{s.code}</span>
              <Badge tone={colorByStatus(getGradeSheet(state, s.id).status)}>
                {gradeStatusText[getGradeSheet(state, s.id).status]}
              </Badge>
            </div>
            <h3>{getCourse(s.courseId)?.name}</h3>
            <p>
              <Icon name="calendar" size={15} />
              {slot(s)}
            </p>
            <p>
              <Icon name="building" size={15} />
              Phòng {s.room} · {s.registered} sinh viên
            </p>
            <Button
              kind="outline"
              icon="grades"
              onClick={() => navigate("grade-entry")}
            >
              Quản lý bảng điểm
            </Button>
          </Card>
        ))}
      </div>
    </>
  );
}
