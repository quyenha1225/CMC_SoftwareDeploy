import React, { useState } from "react";
import "./Reports.css";
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

export default function Reports({ state, notify }) {
  const study = state.students.filter((s) => s.status === "STUDYING").length;
  const byClass = [...new Set(state.students.map((s) => s.className))].map(
    (name) => ({
      name,
      count: state.students.filter((s) => s.className === name).length,
    }),
  );
  return (
    <>
      <PageHeader
        title="Báo cáo & thống kê"
        description="Tổng quan số liệu từ dữ liệu mô phỏng, phục vụ việc dựng giao diện Dashboard."
        action={
          <Button
            icon="download"
            kind="outline"
            onClick={() => {
              csvDownload("bao-cao-sinh-vien-demo.csv", [
                ["Mã sinh viên", "Họ tên", "Lớp", "Ngành", "Trạng thái"],
                ...state.students.map((s) => [
                  s.id,
                  s.name,
                  s.className,
                  s.major,
                  studentStatusText[s.status],
                ]),
              ]);
              notify("Đã xuất CSV danh sách sinh viên demo.", "success");
            }}
          >
            Xuất CSV
          </Button>
        }
      />
      <div className="stats-grid three">
        <Stat
          icon="users"
          label="Tổng sinh viên"
          value={`${state.students.length}`}
          hint="Tất cả trạng thái"
        />
        <Stat
          icon="graduation"
          label="Đang học"
          value={`${study}`}
          hint="Đang theo học"
          tone="green"
        />
        <Stat
          icon="bookopen"
          label="Lớp học phần"
          value={`${state.sections.length}`}
          hint="Học kỳ I"
          tone="purple"
        />
      </div>
      <div className="dashboard-columns">
        <Card
          title="Xu hướng hoạt động học vụ"
          subtitle="Biểu đồ minh họa bố cục báo cáo"
        >
          <AreaChart
            values={[28, 36, 42, 37, 47, 54, 60, 58, 67, 74, 82, 87]}
          />
        </Card>
        <Card
          title="Phân bố sinh viên theo lớp"
          subtitle="Lấy từ danh sách sinh viên demo"
        >
          <div className="bar-list">
            {byClass.map((x, i) => (
              <div className="bar-row" key={x.name}>
                <div>
                  <span>{x.name}</span>
                  <b>{x.count} sinh viên</b>
                </div>
                <LevelBar
                  value={(x.count / state.students.length) * 100}
                  color={["#5878ea", "#42bdb0", "#ab87e3"][i % 3]}
                />
              </div>
            ))}
          </div>
        </Card>
      </div>
      <Card
        title="Tình trạng bảng điểm"
        subtitle="Theo quy trình giảng viên – PĐT – Ban giám hiệu"
      >
        <div className="report-status-grid">
          {Object.keys(gradeStatusText).map((status) => (
            <div key={status}>
              <Badge tone={colorByStatus(status)}>
                {gradeStatusText[status]}
              </Badge>
              <strong>
                {state.gradeSheets.filter((g) => g.status === status).length}
              </strong>
            </div>
          ))}
        </div>
      </Card>
    </>
  );
}
