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

export default function CourseDetail({ state, selectedCourse, setSelectedCourse, semester, semesterSections }) {
  return (
    <>
{selectedCourse && (
        <Modal
          title={getCourse(selectedCourse, state)?.name || "Chi tiết học phần"}
          subtitle={`Mã học phần ${selectedCourse}`}
          onClose={() => setSelectedCourse(null)}
        >
          <div className="course-detail-facts">
            <div><span>Tín chỉ</span><strong>{getCourse(selectedCourse, state)?.credits}</strong></div>
            <div><span>Khoa</span><strong>{getCourse(selectedCourse, state)?.faculty || "Chưa cập nhật"}</strong></div>
            <div><span>Học kỳ</span><strong>{semesterLabel(semester)}</strong></div>
            <div><span>Thời gian</span><strong>{semesterDates(semester, state)?.startsOn && semesterDates(semester, state)?.endsOn ? `${new Date(`${semesterDates(semester, state).startsOn}T12:00:00`).toLocaleDateString("vi-VN")} – ${new Date(`${semesterDates(semester, state).endsOn}T12:00:00`).toLocaleDateString("vi-VN")}` : "Chưa cập nhật"}</strong></div>
          </div>
          <h3 className="course-detail-heading">Các lớp học phần trong kỳ</h3>
          <div className="table-wrap">
            <table className="data-table">
              <thead><tr><th>Mã lớp</th><th>Giảng viên</th><th>Lịch học</th><th>Phòng</th><th>Sĩ số</th></tr></thead>
              <tbody>
                {semesterSections.filter((section) => section.courseId === selectedCourse).map((section) => (
                  <tr key={section.id}>
                    <td>{section.code}</td>
                    <td>{section.teacher}</td>
                    <td>{displayDay(section.day)} · {section.start}–{section.end}</td>
                    <td>{section.room}</td>
                    <td>{section.registered}/{section.limit}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Modal>
      )}
    </>
  );
}
