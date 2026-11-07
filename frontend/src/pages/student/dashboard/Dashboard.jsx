import React, { useEffect, useRef } from "react";
import "./Dashboard.css";
import Icon from "../../../components/common/Icon.jsx";
import {
  STUDENT_ID,
  PRICE_PER_CREDIT,
  getCourse,
  getSection,
  getGradeSheet,
  gradeTotal,
  money,
} from "../../../data/portalData.js";
import {
  Badge,
  Card,
  PageHeader,
  Stat,
  Donut,
  AreaChart,
  number,
} from "../../../components/ui.jsx";

export default function Dashboard({ role, state, account, navigate }) {
  const dashboardRef = useRef(null);
  useEffect(() => {
    if (!window.IntersectionObserver || window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const elements = dashboardRef.current.querySelectorAll(".hero-content > *, .stat-content > *, .card-head, .upcoming, .announcement-mini, .progress-legend > *, .soft-note");
    const observer = new IntersectionObserver(entries => {
      entries.forEach(({ target, isIntersecting, boundingClientRect }) => {
        if (isIntersecting) target.dataset.dashboardReveal = "visible";
        else if (boundingClientRect.bottom < 0 || boundingClientRect.top > window.innerHeight) target.dataset.dashboardReveal = "pending";
      });
    }, { threshold: 0.1 });
    elements.forEach((element, index) => {
      element.style.setProperty("--text-delay", `${(index % 3) * 65}ms`);
      element.dataset.dashboardReveal = "pending";
      observer.observe(element);
    });
    return () => {
      observer.disconnect();
      elements.forEach(element => delete element.dataset.dashboardReveal);
    };
  }, [role]);
  const chosen = state.enrollmentIds
    .map((id) => getSection(state, id))
    .filter(Boolean);
  const credits = chosen.reduce(
    (total, section) => total + (getCourse(section.courseId)?.credits || 0),
    0,
  );
  const doneGrades = state.grades.filter(
    (grade) =>
      grade.studentId === STUDENT_ID &&
      getGradeSheet(state, grade.sectionId).status === "PUBLISHED" &&
      gradeTotal(grade) !== null,
  );
  const gpa = doneGrades.length
    ? (
        doneGrades.reduce((total, grade) => total + gradeTotal(grade), 0) /
        doneGrades.length
      ).toFixed(2)
    : "—";
  const owing = Math.max(
    0,
    credits * PRICE_PER_CREDIT -
      state.payments
        .filter((payment) => payment.studentId === STUDENT_ID)
        .reduce((total, payment) => total + payment.amount, 0),
  );
  const outstandingSheets = state.gradeSheets.filter(
    (sheet) => sheet.status === "SUBMITTED" || sheet.status === "VERIFIED",
  );
  const pendingRequests = state.requests.filter(
    (request) =>
      request.status === "PENDING" || request.status === "PROCESSING",
  );
  const principal = role === "principal";
  const training = role === "training";
  const lecturer = role === "lecturer";
  const action =
    role === "student"
      ? { page: "enrollment", label: "Xem học phần" }
      : lecturer
        ? { page: "teaching", label: "Xem lớp học" }
        : principal
          ? { page: "approvals", label: "Xem phê duyệt" }
          : { page: "students", label: "Xem sinh viên" };

  return (
    <div className="dashboard-surface" ref={dashboardRef}>
      <PageHeader
        title={`Xin chào, ${account.name.split(" ").at(-1)}`}
        eyebrow="HỌC KỲ I · 2026–2027"
      />
      <section className="hero">
        <div className="hero-content">
          <h2>
            {role === "student"
              ? "Học kỳ mới, sẵn sàng chưa?"
              : "Tổng quan công việc trong học kỳ."}
          </h2>
          <p>Theo dõi lớp học, tiến độ và thông báo mới.</p>
          <button onClick={() => navigate(action.page)}>
            {action.label} <Icon name="arrow" size={17} />
          </button>
        </div>
        <div className="hero-illustration" aria-hidden="true">
          <div className="orbit orbit-one" />
          <div className="orbit orbit-two" />
          <div className="hero-orbiting-icons">
            <div className="hero-float hero-float-1">
              <Icon name="graduation" size={30} />
            </div>
            <div className="hero-float hero-float-2">
              <Icon name="bookopen" size={25} />
            </div>
            <div className="hero-float hero-float-3">
              <Icon name="checkcircle" size={28} />
            </div>
          </div>
          <div className="hero-core">
            <Icon name="building" size={77} strokeWidth={1.2} />
          </div>
        </div>
      </section>

      {role === "student" ? (
        <>
          <div className="stats-grid">
            <Stat
              icon="bookopen"
              label="Học phần đã đăng ký"
              value={chosen.length.toString().padStart(2, "0")}
              hint={`${credits} tín chỉ`}
            />
            <Stat
              icon="calendar"
              label="Buổi học mỗi tuần"
              value={`${chosen.length}`}
              hint="Theo thời khóa biểu"
              tone="purple"
            />
            <Stat
              icon="grades"
              label="Điểm trung bình"
              value={gpa}
              hint="Thang điểm 10"
              tone="green"
            />
            <Stat
              icon="wallet"
              label="Học phí dự kiến"
              value={money(owing)}
              hint="Ước tính học kỳ"
              tone="orange"
            />
          </div>
          <div className="dashboard-columns">
            <Card
              title="Lịch học sắp tới"
              extra={
                <button
                  className="text-link"
                  onClick={() => navigate("schedule")}
                >
                  Xem lịch <Icon name="chevron" size={14} />
                </button>
              }
            >
              <div className="upcoming-list">
                {chosen
                  .sort((a, b) => a.day - b.day)
                  .slice(0, 4)
                  .map((section) => (
                    <div className="upcoming" key={section.id}>
                      <div className="date-badge">
                        <strong>T{section.day + 1}</strong>
                        <span>{section.start}</span>
                      </div>
                      <div className="upcoming-info">
                        <b>{getCourse(section.courseId)?.name}</b>
                        <p>
                          {section.teacher} · Phòng {section.room}
                        </p>
                      </div>
                      <Badge tone="blue">{section.code}</Badge>
                    </div>
                  ))}
              </div>
            </Card>
            <Card title="Tiến độ học kỳ">
              <div className="progress-box">
                <Donut
                  percent={Math.round((credits / 24) * 100)}
                  label="tín chỉ"
                />
                <div className="progress-notes">
                  <div>
                    <span className="circle blue" /> Đã đăng ký{" "}
                    <b>{credits} TC</b>
                  </div>
                  <div>
                    <span className="circle gray" /> Mục tiêu <b>24 TC</b>
                  </div>
                  <div>
                    <span className="circle green" /> Có điểm{" "}
                    <b>{doneGrades.length} môn</b>
                  </div>
                </div>
              </div>
              <div className="soft-note">
                <Icon name="info" size={17} /> Điểm được cập nhật sau khi công
                bố.
              </div>
            </Card>
          </div>
        </>
      ) : (
        <>
          <div className="stats-grid">
            <Stat
              icon="users"
              label="Sinh viên"
              value={number(state.students.length)}
              hint="Hồ sơ trong hệ thống"
            />
            <Stat
              icon="bookopen"
              label="Lớp học phần"
              value={number(state.sections.length)}
              hint="Học kỳ I"
              tone="purple"
            />
            <Stat
              icon="grades"
              label="Bảng điểm chờ xử lý"
              value={number(outstandingSheets.length)}
              hint="Cần xem xét"
              tone="orange"
            />
            <Stat
              icon="file"
              label="Yêu cầu đang xử lý"
              value={number(pendingRequests.length)}
              hint="Đang tiếp nhận"
              tone="green"
            />
          </div>
          <div className="dashboard-columns">
            <Card title="Tình hình đào tạo">
              <AreaChart />
            </Card>
            <Card title="Việc cần xử lý">
              <div className="todo-list">
                <div
                  onClick={() =>
                    navigate(
                      principal
                        ? "approvals"
                        : lecturer
                          ? "grade-entry"
                          : training
                            ? "grade-approval"
                            : "students",
                    )
                  }
                >
                  <span className="todo-icon purple">
                    <Icon name="grades" size={18} />
                  </span>
                  <span>
                    <b>{outstandingSheets.length} bảng điểm</b>
                    <small>Chờ xem xét</small>
                  </span>
                  <Icon name="chevron" size={17} />
                </div>
                <div
                  onClick={() =>
                    navigate(
                      training
                        ? "requests"
                        : principal
                          ? "reports"
                          : "teaching",
                    )
                  }
                >
                  <span className="todo-icon blue">
                    <Icon name="file" size={18} />
                  </span>
                  <span>
                    <b>{pendingRequests.length} yêu cầu</b>
                    <small>Đang xử lý</small>
                  </span>
                  <Icon name="chevron" size={17} />
                </div>
                <div onClick={() => navigate("notices")}>
                  <span className="todo-icon amber">
                    <Icon name="bell" size={18} />
                  </span>
                  <span>
                    <b>{state.announcements.length} thông báo</b>
                    <small>Cập nhật mới</small>
                  </span>
                  <Icon name="chevron" size={17} />
                </div>
              </div>
            </Card>
          </div>
        </>
      )}

      <Card
        title="Thông báo mới nhất"
        extra={
          <button className="text-link" onClick={() => navigate("notices")}>
            Tất cả <Icon name="chevron" size={14} />
          </button>
        }
      >
        <div className="notice-grid">
          {state.announcements.slice(0, 3).map((notice) => (
            <div className="notice-mini" key={notice.id}>
              <div className="notice-top">
                <span
                  className="notice-mark"
                  style={{ background: notice.color }}
                />
                <span>{notice.category}</span>
                <small>{notice.date}</small>
              </div>
              <b>{notice.title}</b>
              <p>{notice.content}</p>
            </div>
          ))}
        </div>
      </Card>
    </div>
  );
}
