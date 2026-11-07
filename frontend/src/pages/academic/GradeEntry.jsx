import React, { useState } from "react";
import "./GradeEntry.css";
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

export default function GradeEntry({ state, update, notify }) {
  const sections = state.sections.filter((s) => s.teacher === "Trần Quốc Huy");
  const [sectionId, setSectionId] = useState(sections[0]?.id || "SEC-01");
  const [editing, setEditing] = useState(null);
  const [detailGrade, setDetailGrade] = useState(null);
  const sec = getSection(state, sectionId);
  const sheet = getGradeSheet(state, sectionId);
  const readOnly = !["DRAFT", "RETURNED"].includes(sheet.status);
  const participants =
    sectionId === "SEC-01"
      ? state.students.slice(0, 3)
      : sectionId === "SEC-03"
        ? state.students.slice(0, 2)
        : state.students.slice(1, 4);
  const grades = participants.map((st) => ({
    student: st,
    grade: state.grades.find(
      (g) => g.studentId === st.id && g.sectionId === sectionId,
    ),
  }));
  const validAll = grades.every(
    ({ grade: g }) =>
      g &&
      [g.attendance, g.midterm, g.final].every(
        (v) => v !== null && v !== undefined && v !== "",
      ),
  );
  function saveGrade() {
    const n = {
      attendance: editing.attendance === "" ? null : Number(editing.attendance),
      midterm: editing.midterm === "" ? null : Number(editing.midterm),
      final: editing.final === "" ? null : Number(editing.final),
    };
    if (
      Object.values(n).some(
        (v) => v !== null && (!Number.isFinite(v) || v < 0 || v > 10),
      )
    )
      return notify("Điểm phải nằm trong khoảng 0–10.", "error");
    update((s) => {
      const old = s.grades.filter(
        (g) =>
          !(g.studentId === editing.studentId && g.sectionId === sectionId),
      );
      return { ...s, grades: [...old, { ...editing, ...n, sectionId }] };
    });
    notify("Đã lưu điểm nháp của sinh viên.", "success");
    setEditing(null);
  }
  function submitSheet() {
    if (!validAll)
      return notify(
        "Vui lòng nhập đủ ba cột điểm cho các sinh viên hiển thị trước khi nộp.",
        "error",
      );
    update((s) => ({
      ...s,
      gradeSheets: s.gradeSheets.some((x) => x.sectionId === sectionId)
        ? s.gradeSheets.map((x) =>
            x.sectionId === sectionId
              ? { ...x, status: "SUBMITTED", updated: todayVN(), reason: "" }
              : x,
          )
        : [
            ...s.gradeSheets,
            { sectionId, status: "SUBMITTED", updated: todayVN(), reason: "" },
          ],
    }));
    notify("Đã nộp bảng điểm lên Phòng Đào tạo.", "success");
  }
  return (
    <>
      <PageHeader
        title="Nhập điểm & gửi xét duyệt"
        description="Giảng viên chỉ sửa điểm khi bảng điểm ở trạng thái nháp hoặc bị trả lại."
      />
      <div className="select-panel">
        <div>
          <span>CHỌN LỚP HỌC PHẦN</span>
          <select
            className="control"
            value={sectionId}
            onChange={(e) => setSectionId(e.target.value)}
          >
            {sections.map((s) => (
              <option key={s.id} value={s.id}>
                {s.code} – {getCourse(s.courseId)?.name}
              </option>
            ))}
          </select>
        </div>
        <div className="select-status">
          <span>TRẠNG THÁI BẢNG ĐIỂM</span>
          <Badge tone={colorByStatus(sheet.status)} dot>
            {gradeStatusText[sheet.status]}
          </Badge>
        </div>
      </div>
      {sheet.reason && (
        <div className="warning-box">
          <Icon name="alert" size={18} /> Lý do trả lại: {sheet.reason}
        </div>
      )}
      <Card
        title={`Danh sách điểm – ${sec?.code}`}
        subtitle="Tỷ trọng minh họa: 10% chuyên cần · 30% giữa kỳ · 60% cuối kỳ"
        extra={
          !readOnly && (
            <Button icon="send" onClick={submitSheet} disabled={!validAll}>
              Gửi Phòng Đào tạo
            </Button>
          )
        }
      >
        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>Mã SV</th>
                <th>Sinh viên</th>
                <th>Chuyên cần</th>
                <th>Giữa kỳ</th>
                <th>Cuối kỳ</th>
                <th>Tổng kết</th>
                <th>Chi tiết</th>
                <th>Thao tác</th>
              </tr>
            </thead>
            <tbody>
              {grades.map(({ student, grade: g }) => (
                <tr key={student.id}>
                  <td>{student.id}</td>
                  <td>
                    <div className="person-cell">
                      <Avatar name={student.name} size="sm" />
                      <b>{student.name}</b>
                    </div>
                  </td>
                  <td>{g?.attendance ?? "—"}</td>
                  <td>{g?.midterm ?? "—"}</td>
                  <td>{g?.final ?? "—"}</td>
                  <td>
                    <GradeChip score={gradeTotal(g)} />
                  </td>
                  <td>
                    <Button
                      kind="outline"
                      small
                      onClick={() =>
                        setDetailGrade({ student, grade: g })
                      }
                    >
                      Xem điểm
                    </Button>
                  </td>
                  <td>
                    <Button
                      kind="outline"
                      small
                      icon="edit"
                      disabled={readOnly}
                      onClick={() =>
                        setEditing({
                          studentId: student.id,
                          attendance: g?.attendance ?? "",
                          midterm: g?.midterm ?? "",
                          final: g?.final ?? "",
                          note: g?.note ?? "",
                        })
                      }
                    >
                      Nhập điểm
                    </Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>
      <div className="hint-line">
        <Icon name="shield" size={17} /> Khi đã nộp, giảng viên không được tự
        chỉnh sửa. PĐT có thể trả lại để cập nhật, sau đó BGH phê duyệt.
      </div>
      {editing && (
        <Modal
          title="Cập nhật điểm sinh viên"
          subtitle={`${state.students.find((s) => s.id === editing.studentId)?.name} · ${editing.studentId}`}
          onClose={() => setEditing(null)}
        >
          <div className="form-grid">
            {[
              ["attendance", "Chuyên cần (10%)"],
              ["midterm", "Giữa kỳ (30%)"],
              ["final", "Cuối kỳ (60%)"],
            ].map(([key, label]) => (
              <Field label={label} key={key}>
                <input
                  className="control"
                  type="number"
                  min="0"
                  max="10"
                  step="0.1"
                  value={editing[key]}
                  onChange={(e) =>
                    setEditing((v) => ({ ...v, [key]: e.target.value }))
                  }
                />
              </Field>
            ))}
          </div>
          <Field label="Nhận xét">
            <textarea
              className="control textarea"
              rows="3"
              value={editing.note}
              onChange={(e) =>
                setEditing((v) => ({ ...v, note: e.target.value }))
              }
            />
          </Field>
          <div className="modal-actions">
            <Button kind="outline" onClick={() => setEditing(null)}>
              Hủy
            </Button>
            <Button icon="check" onClick={saveGrade}>
              Lưu điểm
            </Button>
          </div>
        </Modal>
      )}
      {detailGrade && (
        <Modal
          title={`Chi tiết điểm · ${detailGrade.student.name}`}
          subtitle={`${sec?.code} · ${getCourse(sec?.courseId)?.name}`}
          onClose={() => setDetailGrade(null)}
        >
          <div className="grade-detail-list">
            <div><span>Chuyên cần · 10%</span><strong>{detailGrade.grade?.attendance ?? "Chưa nhập"}</strong></div>
            <div><span>Giữa kỳ · 30%</span><strong>{detailGrade.grade?.midterm ?? "Chưa nhập"}</strong></div>
            <div><span>Cuối kỳ · 60%</span><strong>{detailGrade.grade?.final ?? "Chưa nhập"}</strong></div>
            <div><span>Tổng kết</span><strong>{gradeTotal(detailGrade.grade)?.toFixed(1) ?? "Chưa đủ điểm"}</strong></div>
          </div>
          {detailGrade.grade?.note && <p className="grade-detail-note">Nhận xét: {detailGrade.grade.note}</p>}
        </Modal>
      )}
    </>
  );
}
