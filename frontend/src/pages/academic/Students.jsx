import React, { useState } from "react";
import "./Students.css";
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

export default function Students({ state, update, notify }) {
  const [q, setQ] = useState(""),
    [filter, setFilter] = useState("all"),
    [edit, setEdit] = useState(null);
  const list = state.students.filter(
    (s) =>
      (filter === "all" || s.status === filter) &&
      `${s.id} ${s.name} ${s.className}`
        .toLowerCase()
        .includes(q.toLowerCase()),
  );
  const approvalRequests = (state.studentApprovals || []).filter(
    (request) => request.status === "PENDING",
  );
  function save() {
    if (
      !edit.name.trim() ||
      !edit.id.trim() ||
      !edit.className.trim() ||
      !edit.major.trim() ||
      !edit.year.trim()
    )
      return notify("Vui lòng nhập đủ mã, họ tên, lớp, ngành và khóa.", "error");
    if (state.students.some((s) => s.id === edit.id && s.id !== edit.originalId))
      return notify("Mã sinh viên đã tồn tại.", "error");
    if (
      !edit.originalId &&
      (state.studentApprovals || []).some(
        (request) =>
          request.student.id === edit.id && request.status === "PENDING",
      )
    )
      return notify("Mã sinh viên này đang chờ Ban Giám hiệu phê duyệt.", "error");
    if (edit.originalId) {
      update((s) => ({
        ...s,
        students: s.students.map((student) =>
          student.id === edit.originalId
            ? { ...edit, name: edit.name.trim() }
            : student,
        ),
      }));
      notify("Đã cập nhật hồ sơ sinh viên trong dữ liệu demo.", "success");
    } else {
      const student = {
        ...edit,
        name: edit.name.trim(),
        id: edit.id.trim(),
        status: "STUDYING",
      };
      update((s) => ({
        ...s,
        studentApprovals: [
          ...(s.studentApprovals || []),
          {
            id: `STU-REQ-${Date.now()}`,
            student,
            status: "PENDING",
            submittedAt: todayVN(),
          },
        ],
      }));
      notify("Đã ghi nhận và gửi hồ sơ lên Ban Giám hiệu phê duyệt.", "success");
    }
    setEdit(null);
  }
  return (
    <>
      <PageHeader
        title="Ghi nhận sinh viên"
        description="Phòng Đào tạo lập hồ sơ; Ban Giám hiệu xem xét trước khi ghi nhận chính thức."
        action={
          <Button
            icon="plus"
            onClick={() =>
              setEdit({
                id: `SV${Date.now().toString().slice(-6)}`,
                name: "",
                className: "CNTT24A",
                major: "Công nghệ phần mềm",
                status: "STUDYING",
                year: "K2024",
                email: "",
                phone: "",
                address: "",
                dob: "",
                originalId: "",
              })
            }
          >
            Ghi nhận sinh viên
          </Button>
        }
      />
      <div className="stats-grid">
        <Stat
          icon="users"
          label="Tổng hồ sơ"
          value={number(state.students.length)}
          hint="Dữ liệu demo"
        />
        <Stat
          icon="checkcircle"
          label="Đang học"
          value={number(
            state.students.filter((s) => s.status === "STUDYING").length,
          )}
          hint="Trạng thái hoạt động"
          tone="green"
        />
        <Stat
          icon="clock"
          label="Bảo lưu"
          value={number(
            state.students.filter((s) => s.status === "SUSPENDED").length,
          )}
          hint="Theo dõi học vụ"
          tone="orange"
        />
        <Stat
          icon="shield"
          label="Chờ Ban Giám hiệu"
          value={number(approvalRequests.length)}
          hint="Hồ sơ chờ phê duyệt"
          tone="purple"
        />
      </div>
      <Card
        title="Hồ sơ đang chờ Ban Giám hiệu phê duyệt"
        subtitle={`${approvalRequests.length} hồ sơ chờ xử lý`}
      >
        {approvalRequests.length > 0 ? (
          <div className="table-wrap">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Mã sinh viên</th>
                  <th>Họ tên</th>
                  <th>Lớp / ngành</th>
                  <th>Ngày gửi</th>
                  <th>Trạng thái</th>
                </tr>
              </thead>
              <tbody>
                {approvalRequests.map((request) => (
                  <tr key={request.id}>
                    <td>{request.student.id}</td>
                    <td>{request.student.name}</td>
                    <td>
                      {request.student.className} · {request.student.major}
                    </td>
                    <td>{request.submittedAt}</td>
                    <td>
                      <Badge tone="amber" dot>
                        Chờ Ban Giám hiệu phê duyệt
                      </Badge>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <Empty
            icon="checkcircle"
            title="Không có hồ sơ chờ duyệt"
            description="Hồ sơ mới sẽ hiển thị tại đây sau khi gửi Ban Giám hiệu."
          />
        )}
      </Card>
      <Card
        title="Danh sách sinh viên"
        subtitle="Thông tin mô phỏng dùng để xây dựng giao diện"
        extra={
          <div className="table-tools">
            <div className="searchbox">
              <Icon name="search" size={17} />
              <input
                placeholder="Tìm tên hoặc mã sinh viên"
                value={q}
                onChange={(e) => setQ(e.target.value)}
              />
            </div>
            <select
              className="control compact"
              value={filter}
              onChange={(e) => setFilter(e.target.value)}
            >
              <option value="all">Tất cả</option>
              <option value="STUDYING">Đang học</option>
              <option value="SUSPENDED">Bảo lưu</option>
              <option value="GRADUATED">Tốt nghiệp</option>
            </select>
          </div>
        }
      >
        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>Sinh viên</th>
                <th>Mã sinh viên</th>
                <th>Lớp</th>
                <th>Ngành học</th>
                <th>Khóa</th>
                <th>Trạng thái</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {list.map((s) => (
                <tr key={s.id}>
                  <td>
                    <div className="person-cell">
                      <Avatar name={s.name} size="sm" />
                      <b>{s.name}</b>
                    </div>
                  </td>
                  <td>{s.id}</td>
                  <td>{s.className}</td>
                  <td>{s.major}</td>
                  <td>{s.year}</td>
                  <td>
                    <Badge tone={colorByStatus(s.status)}>
                      {studentStatusText[s.status]}
                    </Badge>
                  </td>
                  <td>
                    <Button
                      small
                      kind="outline"
                      icon="edit"
                      onClick={() => setEdit({ ...s, originalId: s.id })}
                    >
                      Sửa
                    </Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {list.length === 0 && <Empty title="Không tìm thấy sinh viên" />}
        </div>
      </Card>
      {edit && (
        <Modal
          title={edit.originalId ? "Cập nhật hồ sơ" : "Ghi nhận sinh viên mới"}
          subtitle={
            edit.originalId
              ? "Cập nhật dữ liệu demo."
              : "Hồ sơ sẽ được gửi Ban Giám hiệu phê duyệt trước khi thêm vào danh sách chính thức."
          }
          onClose={() => setEdit(null)}
        >
          <div className="form-grid">
            <Field label="Mã sinh viên">
              <input
                className="control"
                value={edit.id}
                disabled={!!edit.originalId}
                onChange={(e) => setEdit((s) => ({ ...s, id: e.target.value }))}
              />
            </Field>
            <Field label="Họ tên">
              <input
                className="control"
                value={edit.name}
                onChange={(e) =>
                  setEdit((s) => ({ ...s, name: e.target.value }))
                }
              />
            </Field>
            <Field label="Lớp hành chính">
              <input
                className="control"
                value={edit.className}
                onChange={(e) =>
                  setEdit((s) => ({ ...s, className: e.target.value }))
                }
              />
            </Field>
            <Field label="Ngành học">
              <input
                className="control"
                value={edit.major}
                onChange={(e) =>
                  setEdit((s) => ({ ...s, major: e.target.value }))
                }
              />
            </Field>
            {edit.originalId && (
              <Field label="Trạng thái">
                <select
                  className="control"
                  value={edit.status}
                  onChange={(e) =>
                    setEdit((s) => ({ ...s, status: e.target.value }))
                  }
                >
                  {Object.entries(studentStatusText).map(([v, t]) => (
                    <option key={v} value={v}>
                      {t}
                    </option>
                  ))}
                </select>
              </Field>
            )}
            <Field label="Khóa">
              <input
                className="control"
                value={edit.year}
                onChange={(e) =>
                  setEdit((s) => ({ ...s, year: e.target.value }))
                }
              />
            </Field>
            <Field label="Email">
              <input
                className="control"
                value={edit.email}
                onChange={(e) =>
                  setEdit((s) => ({ ...s, email: e.target.value }))
                }
              />
            </Field>
            <Field label="Số điện thoại">
              <input
                className="control"
                value={edit.phone}
                onChange={(e) =>
                  setEdit((s) => ({ ...s, phone: e.target.value }))
                }
              />
            </Field>
          </div>
          <div className="modal-actions">
            <Button kind="outline" onClick={() => setEdit(null)}>
              Hủy
            </Button>
            <Button icon="check" onClick={save}>
              {edit.originalId ? "Lưu thay đổi" : "Gửi Ban Giám hiệu phê duyệt"}
            </Button>
          </div>
        </Modal>
      )}
    </>
  );
}
