import React, { useState } from "react";
import "./Tuition.css";
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

export default function Tuition({ state, role, update, notify }) {
  const selected = state.enrollmentIds
    .map((id) => getSection(state, id))
    .filter(Boolean);
  const sum = selected.reduce(
    (a, s) => a + (getCourse(s.courseId)?.credits || 0) * PRICE_PER_CREDIT,
    0,
  );
  const paid = state.payments
    .filter((p) => p.studentId === STUDENT_ID)
    .reduce((a, p) => a + p.amount, 0);
  const balance = Math.max(0, sum - paid);
  const [showPayment, setShowPayment] = useState(false),
    [amount, setAmount] = useState("");
  function pay() {
    const n = Number(amount);
    if (!Number.isFinite(n) || n <= 0 || n > balance)
      return notify("Số tiền phải lớn hơn 0 và không vượt công nợ.", "error");
    update((s) => ({
      ...s,
      payments: [
        ...s.payments,
        {
          id: `PAY-${Date.now()}`,
          studentId: STUDENT_ID,
          amount: n,
          date: todayVN(),
          method: "Ghi nhận thủ công (demo)",
          note: "Không có giao dịch thật",
        },
      ],
    }));
    setShowPayment(false);
    setAmount("");
    notify("Đã ghi nhận khoản thanh toán mô phỏng.", "success");
  }
  return (
    <>
      <PageHeader
        title={role === "training" ? "Quản lý học phí" : "Học phí & thanh toán"}
        description="Theo dõi học phí phát sinh từ lớp học phần đã đăng ký · Dữ liệu demo."
        action={
          role === "training" ? (
            <Button icon="plus" onClick={() => setShowPayment(true)}>
              Ghi nhận thu (demo)
            </Button>
          ) : (
            <Badge tone="amber">Không tích hợp thanh toán thật</Badge>
          )
        }
      />
      <div className="stats-grid three">
        <Stat
          icon="wallet"
          label="Tổng học phí dự kiến"
          value={money(sum)}
          hint="Cộng theo tín chỉ đăng ký"
        />
        <Stat
          icon="checkcircle"
          label="Đã ghi nhận thu"
          value={money(paid)}
          hint="Dữ liệu mô phỏng"
          tone="green"
        />
        <Stat
          icon="alert"
          label="Công nợ dự kiến"
          value={money(balance)}
          hint="Chưa bao gồm điều chỉnh"
          tone="orange"
        />
      </div>
      <div className="dashboard-columns">
        <Card
          title="Chi tiết học phí học kỳ I"
          subtitle="Đơn giá demo: 780.000đ / tín chỉ"
        >
          <div className="table-wrap">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Học phần</th>
                  <th>Tín chỉ</th>
                  <th>Đơn giá</th>
                  <th>Thành tiền</th>
                </tr>
              </thead>
              <tbody>
                {selected.map((s) => (
                  <tr key={s.id}>
                    <td>
                      <b>{getCourse(s.courseId)?.name}</b>
                      <small className="cell-sub">{s.code}</small>
                    </td>
                    <td>{getCourse(s.courseId)?.credits}</td>
                    <td>{money(PRICE_PER_CREDIT)}</td>
                    <td>
                      <b>
                        {money(
                          (getCourse(s.courseId)?.credits || 0) *
                            PRICE_PER_CREDIT,
                        )}
                      </b>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <div className="invoice-total">
            <div>
              <span>Tổng học phí dự kiến</span>
              <b>{money(sum)}</b>
            </div>
            <div>
              <span>Đã thu (demo)</span>
              <b className="green-text">− {money(paid)}</b>
            </div>
            <div className="final-total">
              <strong>Còn cần thanh toán</strong>
              <strong>{money(balance)}</strong>
            </div>
          </div>
        </Card>
        <Card
          title="Lịch sử ghi nhận thanh toán"
          subtitle="Không phát sinh giao dịch ngân hàng"
        >
          <div className="payment-list">
            {state.payments
              .filter((p) => p.studentId === STUDENT_ID)
              .map((p) => (
                <div className="payment-row" key={p.id}>
                  <div className="payment-icon">
                    <Icon name="checkcircle" size={20} />
                  </div>
                  <div>
                    <b>{money(p.amount)}</b>
                    <p>{p.method}</p>
                    <small>{p.date}</small>
                  </div>
                  <Badge tone="green">Đã ghi nhận</Badge>
                </div>
              ))}
          </div>
          <div className="soft-note">
            <Icon name="info" size={18} /> Việc đăng ký/hủy lớp làm thay đổi số
            học phí <strong>dự kiến</strong>; khi có backend sẽ chốt hóa đơn và
            lưu lịch sử theo schema.
          </div>
        </Card>
      </div>
      {showPayment && (
        <Modal
          title="Ghi nhận thanh toán mô phỏng"
          subtitle="Chỉ dùng để thử giao diện, không thu tiền thật"
          onClose={() => setShowPayment(false)}
        >
          <Field label="Số tiền (VND)">
            <input
              className="control"
              type="number"
              min="1"
              max={balance}
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              placeholder="Nhập số tiền"
            />
          </Field>
          <div className="modal-actions">
            <Button kind="outline" onClick={() => setShowPayment(false)}>
              Hủy
            </Button>
            <Button onClick={pay}>Xác nhận ghi nhận</Button>
          </div>
        </Modal>
      )}
    </>
  );
}
