import React, { useState } from "react";
import "./Notices.css";
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

export default function Notices({ state, role, update, notify }) {
  const [open, setOpen] = useState(false),
    [selected, setSelected] = useState(null),
    [form, setForm] = useState({
      category: "Đào tạo",
      title: "",
      content: "",
      audience: "all",
    });
  function submit(e) {
    e.preventDefault();
    if (form.title.trim().length < 5 || form.content.trim().length < 10)
      return notify("Nội dung thông báo chưa đủ thông tin.", "error");
    update((s) => ({
      ...s,
      announcements: [
        {
          ...form,
          id: `N${Date.now()}`,
          date: todayVN(),
          color: "#287568",
          author: ROLE_NAMES[role],
        },
        ...s.announcements,
      ],
    }));
    notify("Đã đăng thông báo.", "success");
    setOpen(false);
    setForm({ category: "Đào tạo", title: "", content: "", audience: "all" });
  }
  const visibleAnnouncements = state.announcements.filter(
    (notice) =>
      role === "training" ||
      notice.audience === "all" ||
      notice.audience === role,
  );
  return (
    <>
      <PageHeader
        title="Thông báo"
        description="Cập nhật các tin tức và thông tin về hoạt động đào tạo."
        action={
          role === "training" && (
            <Button icon="plus" onClick={() => setOpen(true)}>
              Tạo thông báo
            </Button>
          )
        }
      />
      <div className="announcements">
        {visibleAnnouncements.map((n) => (
          <Card key={n.id} className="announcement">
            <div className="announcement-body">
              <div
                className="announcement-icon"
                style={{ background: n.color + "19", color: n.color }}
              >
                <Icon name="bell" size={23} />
              </div>
              <div>
                <div className="announcement-meta">
                  <Badge tone="blue">{n.category}</Badge>
                  <span>
                    <Icon name="calendar" size={14} />
                    {n.date}
                  </span>
                </div>
                <h3>{n.title}</h3>
                <p>{n.content}</p>
                <Button small kind="outline" onClick={() => setSelected(n)}>
                  Xem chi tiết
                </Button>
              </div>
            </div>
          </Card>
        ))}
      </div>
      {open && (
        <Modal title="Tạo thông báo" onClose={() => setOpen(false)}>
          <form onSubmit={submit}>
            <Field label="Loại thông báo">
              <select
                className="control"
                value={form.category}
                onChange={(e) =>
                  setForm((v) => ({ ...v, category: e.target.value }))
                }
              >
                <option>Đào tạo</option>
                <option>Học vụ</option>
                <option>Học phí</option>
                <option>Hoạt động sinh viên</option>
                <option>Thông tin chung</option>
              </select>
            </Field>
            <Field label="Đối tượng nhận">
              <select
                className="control"
                value={form.audience}
                onChange={(e) =>
                  setForm((v) => ({ ...v, audience: e.target.value }))
                }
              >
                <option value="all">Toàn trường</option>
                <option value="student">Sinh viên</option>
                <option value="lecturer">Giảng viên</option>
              </select>
            </Field>
            <Field label="Tiêu đề">
              <input
                className="control"
                value={form.title}
                onChange={(e) =>
                  setForm((v) => ({ ...v, title: e.target.value }))
                }
              />
            </Field>
            <Field label="Nội dung">
              <textarea
                className="control textarea"
                rows="5"
                value={form.content}
                onChange={(e) =>
                  setForm((v) => ({ ...v, content: e.target.value }))
                }
              />
            </Field>
            <div className="modal-actions">
              <Button kind="outline" onClick={() => setOpen(false)}>
                Đóng
              </Button>
              <Button type="submit">Đăng thông báo</Button>
            </div>
          </form>
        </Modal>
      )}
      {selected && (
        <Modal
          title={selected.title}
          subtitle={`${selected.category} · ${selected.date}`}
          onClose={() => setSelected(null)}
        >
          <div className="notice-detail-meta">
            <span>Người đăng</span>
            <strong>{selected.author || "Phòng Đào tạo"}</strong>
            <span>Đối tượng</span>
            <strong>
              {selected.audience === "student"
                ? "Sinh viên"
                : selected.audience === "lecturer"
                  ? "Giảng viên"
                  : "Toàn trường"}
            </strong>
          </div>
          <p className="notice-detail-content">{selected.content}</p>
        </Modal>
      )}
    </>
  );
}
