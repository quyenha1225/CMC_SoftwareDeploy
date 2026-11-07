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

export default function GradeDetail({ selectedGrade, setSelectedGrade }) {
  return (
    <>
{selectedGrade && (
        <Modal
          title={getCourse(selectedGrade.section?.courseId)?.name || "Chi tiết điểm"}
          subtitle={`${selectedGrade.section?.code} · ${semesterLabel(selectedGrade.section?.semester)}`}
          onClose={() => setSelectedGrade(null)}
        >
          <div className="grade-detail-list">
            <div><span>Chuyên cần · 10%</span><strong>{selectedGrade.attendance?.toFixed(1) ?? "—"}</strong></div>
            <div><span>Giữa kỳ · 30%</span><strong>{selectedGrade.midterm?.toFixed(1) ?? "—"}</strong></div>
            <div><span>Cuối kỳ · 60%</span><strong>{selectedGrade.final?.toFixed(1) ?? "—"}</strong></div>
            <div><span>Tổng kết</span><strong>{gradeTotal(selectedGrade)?.toFixed(1) ?? "Chưa đủ điểm"}</strong></div>
            <div><span>Tín chỉ</span><strong>{getCourse(selectedGrade.section?.courseId)?.credits}</strong></div>
            <div><span>Giảng viên</span><strong>{selectedGrade.section?.teacher}</strong></div>
          </div>
          {selectedGrade.note && <p className="grade-detail-note">Nhận xét: {selectedGrade.note}</p>}
        </Modal>
      )}
    </>
  );
}
