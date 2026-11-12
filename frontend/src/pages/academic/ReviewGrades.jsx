import Pagination, { usePagination } from "../../components/common/Pagination.jsx";
import React, { useState } from "react";
import "./ReviewGrades.css";
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

export default function ReviewGrades({ role, state, update, notify }) {
  const principal = role === "principal";
  const allowed = principal
    ? ["VERIFIED", "APPROVED"]
    : ["SUBMITTED", "APPROVED"];
  const relevant = state.gradeSheets.filter(
    (s) =>
      allowed.includes(s.status) ||
      s.status === "RETURNED" ||
      s.status === "PUBLISHED",
  );
  const [selected, setSelected] = useState(null),
    [reason, setReason] = useState("");
  const selectedSheet = state.gradeSheets.find((s) => s.sectionId === selected);
  function transition(newStatus) {
    const current = selectedSheet?.status;
    const ok = principal
      ? current === "VERIFIED" && ["APPROVED", "RETURNED"].includes(newStatus)
      : (current === "SUBMITTED" &&
          ["VERIFIED", "RETURNED"].includes(newStatus)) ||
        (current === "APPROVED" && newStatus === "PUBLISHED");
    if (!ok)
      return notify(
        "Trạng thái không hợp lệ theo quy trình xét duyệt.",
        "error",
      );
    if (newStatus === "RETURNED" && reason.trim().length < 5)
      return notify("Cần nhập lý do trả lại ít nhất 5 ký tự.", "error");
    update((s) => ({
      ...s,
      gradeSheets: s.gradeSheets.map((g) =>
        g.sectionId === selected
          ? {
              ...g,
              status: newStatus,
              updated: todayVN(),
              reason: newStatus === "RETURNED" ? reason : "",
            }
          : g,
      ),
    }));
    setSelected(null);
    setReason("");
    notify(
      `Đã chuyển bảng điểm sang trạng thái: ${gradeStatusText[newStatus]}.`,
      "success",
    );
  }
  const pagination = usePagination(relevant, role);
  return (
    <>
      <PageHeader
        title={
          principal ? "Phê duyệt bảng điểm" : "Kiểm tra & công bố bảng điểm"
        }
        description={
          principal
            ? "Xét duyệt bảng điểm đã qua bước kiểm tra của Phòng Đào tạo."
            : "Kiểm tra, trả lại hoặc trình cấp trên xét duyệt; công bố bảng điểm đã được duyệt."
        }
      />
      <div className="stats-grid three">
        <Stat
          icon="clock"
          label="Đang chờ xử lý"
          value={`${state.gradeSheets.filter((s) => (principal ? s.status === "VERIFIED" : s.status === "SUBMITTED" || s.status === "APPROVED")).length}`}
          hint="Đúng thẩm quyền thao tác"
        />
        <Stat
          icon="checkcircle"
          label="Bảng điểm đã duyệt"
          value={`${state.gradeSheets.filter((s) => ["APPROVED", "PUBLISHED"].includes(s.status)).length}`}
          hint="Bao gồm đã công bố"
          tone="green"
        />
        <Stat
          icon="alert"
          label="Yêu cầu chỉnh sửa"
          value={`${state.gradeSheets.filter((s) => s.status === "RETURNED").length}`}
          hint="Đã trả về giảng viên"
          tone="orange"
        />
      </div>
      <Card
        title="Danh sách bảng điểm"
        subtitle="Bấm xem chi tiết để xử lý theo vai trò"
      >
        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>Lớp học phần</th>
                <th>Giảng viên</th>
                <th>Trạng thái</th>
                <th>Cập nhật</th>
                <th>Thao tác</th>
              </tr>
            </thead>
            <tbody>
              {pagination.rows.map((g) => {
                const sec = getSection(state, g.sectionId);
                return (
                  <tr key={g.sectionId}>
                    <td>
                      <b>{getCourse(sec?.courseId, state)?.name}</b>
                      <small className="cell-sub">{sec?.code}</small>
                    </td>
                    <td>{sec?.teacher}</td>
                    <td>
                      <Badge tone={colorByStatus(g.status)} dot>
                        {gradeStatusText[g.status]}
                      </Badge>
                    </td>
                    <td>{g.updated}</td>
                    <td>
                      <Button
                        small
                        kind="outline"
                        onClick={() => {
                          setSelected(g.sectionId);
                          setReason("");
                        }}
                      >
                        Chi tiết
                      </Button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
      <Pagination {...pagination} />

          {relevant.length === 0 && (
            <Empty title="Chưa có bảng điểm cần xử lý" />
          )}
        </div>
      </Card>
      {selected && (
        <Modal
          title={`Bảng điểm ${getSection(state, selected)?.code}`}
          subtitle={gradeStatusText[selectedSheet.status]}
          wide
          onClose={() => setSelected(null)}
        >
          <div className="table-wrap">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Sinh viên</th>
                  <th>Chuyên cần</th>
                  <th>Giữa kỳ</th>
                  <th>Cuối kỳ</th>
                  <th>Tổng kết</th>
                </tr>
              </thead>
              <tbody>
                {state.grades
                  .filter((g) => g.sectionId === selected)
                  .map((g) => (
                    <tr key={g.studentId}>
                      <td>
                        {state.students.find((s) => s.id === g.studentId)
                          ?.name || g.studentId}
                      </td>
                      <td>{g.attendance ?? "—"}</td>
                      <td>{g.midterm ?? "—"}</td>
                      <td>{g.final ?? "—"}</td>
                      <td>
                        <GradeChip score={gradeTotal(g)} />
                      </td>
                    </tr>
                  ))}
              </tbody>
            </table>
          </div>
          {(principal
            ? selectedSheet.status === "VERIFIED"
            : selectedSheet.status === "SUBMITTED") && (
            <Field label="Lý do trả lại (bắt buộc khi từ chối)">
              <textarea
                className="control textarea"
                rows="2"
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                placeholder="Ghi chú để giảng viên sửa lại..."
              />
            </Field>
          )}
          <div className="modal-actions">
            <Button kind="outline" onClick={() => setSelected(null)}>
              Đóng
            </Button>
            {principal ? (
              selectedSheet.status === "VERIFIED" && (
                <>
                  <Button
                    kind="danger-outline"
                    onClick={() => transition("RETURNED")}
                  >
                    Trả lại
                  </Button>
                  <Button icon="check" onClick={() => transition("APPROVED")}>
                    Phê duyệt
                  </Button>
                </>
              )
            ) : selectedSheet.status === "SUBMITTED" ? (
              <>
                <Button
                  kind="danger-outline"
                  onClick={() => transition("RETURNED")}
                >
                  Trả lại
                </Button>
                <Button icon="check" onClick={() => transition("VERIFIED")}>
                  Trình Ban giám hiệu
                </Button>
              </>
            ) : (
              selectedSheet.status === "APPROVED" && (
                <Button
                  icon="checkcircle"
                  onClick={() => transition("PUBLISHED")}
                >
                  Công bố cho sinh viên
                </Button>
              )
            )}
          </div>
        </Modal>
      )}
    </>
  );
}
