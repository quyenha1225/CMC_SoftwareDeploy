import Pagination, { usePagination } from "../../../components/common/Pagination.jsx";
import React, { useState } from "react";
import "./Requests.css";
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

export default function Requests({ role, state, update, notify }) {
  const [open, setOpen] = useState(false),
    [type, setType] = useState("Cập nhật hồ sơ"),
    [subject, setSubject] = useState(""),
    [description, setDescription] = useState(""),
    [selected, setSelected] = useState(null),
    [reply, setReply] = useState("");
  const list =
    role === "student"
      ? state.requests.filter((r) => r.studentId === STUDENT_ID)
      : state.requests;
  function submit(e) {
    e.preventDefault();
    if (subject.trim().length < 5 || description.trim().length < 10)
      return notify(
        "Vui lòng nhập tiêu đề từ 5 ký tự và nội dung từ 10 ký tự.",
        "error",
      );
    update((s) => ({
      ...s,
      requests: [
        {
          id: `REQ-${Date.now()}`,
          studentId: STUDENT_ID,
          type,
          subject: subject.trim(),
          description: description.trim(),
          status: "PENDING",
          date: todayVN(),
          response: "",
        },
        ...s.requests,
      ],
    }));
    setOpen(false);
    setSubject("");
    setDescription("");
    notify("Đã ghi nhận yêu cầu hỗ trợ.", "success");
  }
  function changeStatus(status) {
    update((s) => ({
      ...s,
      requests: s.requests.map((r) =>
        r.id === selected.id ? { ...r, status, response: reply.trim() } : r,
      ),
    }));
    notify("Đã cập nhật trạng thái yêu cầu.", "success");
    setSelected(null);
    setReply("");
  }
  const pagination = usePagination(list, role);
  return (
    <>
      <PageHeader
        title={
          role === "student" ? "Yêu cầu hỗ trợ" : "Tiếp nhận yêu cầu sinh viên"
        }
        description={
          role === "student"
            ? "Gửi yêu cầu và theo dõi kết quả xử lý từ nhà trường."
            : "Theo dõi, phản hồi và cập nhật các yêu cầu của sinh viên."
        }
        action={
          role === "student" && (
            <Button icon="plus" onClick={() => setOpen(true)}>
              Tạo yêu cầu mới
            </Button>
          )
        }
      />
      <Card
        title="Danh sách yêu cầu"
        subtitle={`${list.length} yêu cầu`}
      >
        <div className="request-list">
          {pagination.rows.map((r) => (
            <button
              key={r.id}
              className="request-item"
              onClick={() => {
                setSelected(r);
                setReply(r.response || "");
              }}
            >
              <div className="request-icon">
                <Icon name="file" size={20} />
              </div>
              <div className="request-item-main">
                <div className="request-title">
                  <b>{r.subject}</b>
                  <Badge tone={colorByStatus(r.status)} dot>
                    {requestStatusText[r.status]}
                  </Badge>
                </div>
                <p>{r.description}</p>
                <span>
                  {r.id} · {r.type} · {r.date}
                  {role !== "student" ? ` · ${r.studentId}` : ""}
                </span>
              </div>
              <Icon name="chevron" size={18} />
            </button>
          ))}
          {list.length === 0 && <Empty title="Chưa có yêu cầu" />}
        </div>

      <Pagination {...pagination} />
</Card>
      {open && (
        <Modal
          title="Gửi yêu cầu hỗ trợ"
          subtitle="Nhập nội dung và thông tin cần hỗ trợ"
          onClose={() => setOpen(false)}
        >
          <form onSubmit={submit}>
            <Field label="Loại yêu cầu">
              <select
                className="control"
                value={type}
                onChange={(e) => setType(e.target.value)}
              >
                <option>Cập nhật hồ sơ</option>
                <option>Xác nhận sinh viên</option>
                <option>Phúc khảo điểm</option>
                <option>Học phí</option>
                <option>Vấn đề khác</option>
              </select>
            </Field>
            <Field label="Tiêu đề">
              <input
                className="control"
                value={subject}
                onChange={(e) => setSubject(e.target.value)}
                maxLength={120}
                placeholder="Ví dụ: Điều chỉnh thông tin liên hệ"
              />
            </Field>
            <Field label="Nội dung yêu cầu">
              <textarea
                className="control textarea"
                rows="5"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="Mô tả rõ yêu cầu của bạn..."
              />
            </Field>
            <div className="modal-actions">
              <Button kind="outline" onClick={() => setOpen(false)}>
                Hủy
              </Button>
              <Button type="submit" icon="send">
                Gửi yêu cầu
              </Button>
            </div>
          </form>
        </Modal>
      )}
      {selected && (
        <Modal
          title={selected.subject}
          subtitle={`${selected.id} · ${selected.studentId} · ${selected.date}`}
          onClose={() => setSelected(null)}
        >
          <div className="request-detail">
            <Badge tone={colorByStatus(selected.status)}>
              {requestStatusText[selected.status]}
            </Badge>
            <p>{selected.description}</p>
            {selected.response && (
              <div className="soft-note">
                <Icon name="checkcircle" size={17} />
                {selected.response}
              </div>
            )}
          </div>
          {role === "training" && (
            <>
              <Field label="Phản hồi từ Phòng Đào tạo">
                <textarea
                  rows="3"
                  className="control textarea"
                  value={reply}
                  onChange={(e) => setReply(e.target.value)}
                  placeholder="Nội dung phản hồi cho sinh viên..."
                />
              </Field>
              <div className="modal-actions">
                <Button
                  kind="outline"
                  onClick={() => changeStatus("PROCESSING")}
                >
                  Đang xử lý
                </Button>
                <Button
                  kind="danger-outline"
                  onClick={() => changeStatus("REJECTED")}
                >
                  Từ chối
                </Button>
                <Button onClick={() => changeStatus("DONE")}>Hoàn thành</Button>
              </div>
            </>
          )}
        </Modal>
      )}
    </>
  );
}
