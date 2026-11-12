import React, { useState } from "react";
import "./Profile.css";
import Icon from "../../../components/common/Icon.jsx";
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

export default function Profile({ role, state, update, notify }) {
  const account = ACCOUNTS.find((a) => a.role === role);
  const student = state.students.find((s) => s.id === STUDENT_ID);
  const [form, setForm] = useState(state.profiles?.[role] || (role === "student" ? state.profile : { email: account?.email || "", phone: "", address: "" }));
  function save(e) {
    e.preventDefault();
    if (!form.email.includes("@"))
      return notify("Địa chỉ email chưa hợp lệ.", "error");
    update((s) => ({ ...s, profiles: { ...s.profiles, [role]: form }, ...(role === "student" ? { profile: form } : {}) }));
    notify("Đã cập nhật thông tin liên hệ.", "success");
  }
  return (
    <>
      <PageHeader
        title="Hồ sơ cá nhân"
        description="Xem thông tin tài khoản và cập nhật liên hệ của bạn."
      />
      <div className="profile-grid">
        <Card className="profile-main" id="profile-view">
          <div className="profile-banner" />
          <div className="profile-avatar">
            <Avatar name={account?.name} size="xl" />
          </div>
          <div className="profile-summary">
            <h2>{account?.name}</h2>
            <p>{ROLE_NAMES[role]}</p>
            <Badge tone="green" dot>
              Tài khoản học vụ
            </Badge>
          </div>
          <TextRows
            rows={
              role === "student"
                ? [
                    ["Mã sinh viên", STUDENT_ID],
                    ["Email trường", student?.schoolEmail || "Chưa cấp"],
                    ["Trạng thái email", student?.emailStatus === "ACTIVE" ? "Đã kích hoạt" : "Chưa kích hoạt"],
                    ["Lớp hành chính", student?.className],
                    ["Ngành học", student?.major],
                    ["Khóa", student?.year],
                    ["Trạng thái", studentStatusText[student?.status]],
                  ]
                : [
                    ["Vai trò", ROLE_NAMES[role]],
                    ["Đơn vị", "Hệ thống đào tạo"],
                    ["Loại tài khoản", ROLE_NAMES[role]],
                  ]
            }
          />
        </Card>
        <Card
          title="Thông tin liên hệ"
          subtitle="Cập nhật thông tin liên hệ"
          id="profile-registration"
        >
          <form onSubmit={save}>
            <Field label="Email">
              <input
                className="control"
                type="email"
                value={form.email}
                onChange={(e) =>
                  setForm((v) => ({ ...v, email: e.target.value }))
                }
              />
            </Field>
            <Field label="Số điện thoại">
              <input
                className="control"
                value={form.phone}
                onChange={(e) =>
                  setForm((v) => ({ ...v, phone: e.target.value }))
                }
              />
            </Field>
            <Field label="Địa chỉ">
              <textarea
                className="control textarea"
                rows="3"
                value={form.address}
                onChange={(e) =>
                  setForm((v) => ({ ...v, address: e.target.value }))
                }
              />
            </Field>
            <div className="modal-actions">
              <Button icon="check" type="submit">
                Lưu thay đổi
              </Button>
            </div>
          </form>
        </Card>
      </div>
    </>
  );
}
