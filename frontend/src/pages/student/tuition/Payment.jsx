import React, { useState } from "react";
import { STUDENT_ID, PRICE_PER_CREDIT, getSection, getCourse, money } from "../../../data/portalData.js";
import { Button, Card, PageHeader, Field, Empty, todayVN } from "../../../components/ui.jsx";
import "./Payment.css";

export default function Payment({ state, update, notify, navigate }) {
  const [amount, setAmount] = useState("");
  const [confirmed, setConfirmed] = useState(false);
  const [receipt, setReceipt] = useState(null);
  const sections = state.enrollmentIds.map(id => getSection(state, id)).filter(Boolean);
  const total = sections.reduce((sum, section) => sum + (getCourse(section.courseId)?.credits || 0) * PRICE_PER_CREDIT, 0);
  const paid = state.payments.filter(p => p.studentId === STUDENT_ID).reduce((sum, p) => sum + p.amount, 0);
  const balance = Math.max(0, total - paid);

  function submit(event) {
    event.preventDefault();
    const value = Number(amount);
    if (!confirmed || !Number.isSafeInteger(value) || value <= 0 || value > balance) {
      notify("Nhập số tiền nguyên hợp lệ, không vượt công nợ và xác nhận thanh toán mô phỏng.", "error");
      return;
    }
    const payment = { id: `PAY-${Date.now()}`, studentId: STUDENT_ID, amount: value, date: todayVN(), method: "Thanh toán học phí (demo)", note: "Không có giao dịch thật" };
    update(previous => ({ ...previous, payments: [...previous.payments, payment] }));
    setReceipt(payment);
    setAmount("");
    setConfirmed(false);
    notify("Đã ghi nhận thanh toán mô phỏng.", "success");
  }

  return <>
    <PageHeader title="Thanh toán học phí" description="Kiểm tra học phần đã đăng ký và công nợ trước khi thanh toán." action={<Button kind="outline" onClick={() => navigate("tuition")}>Về mục học phí</Button>} />
    {receipt && <div className="soft-note" role="status">Đã ghi nhận {money(receipt.amount)} · Mã giao dịch {receipt.id} · {receipt.date}</div>}
    <div className="payment-layout">
      <Card title="Học phần đã đăng ký">
        {sections.length ? <div className="table-wrap"><table className="data-table">
          <thead><tr><th>Học phần</th><th>Tín chỉ</th><th>Học phí</th></tr></thead>
          <tbody>{sections.map(section => <tr key={section.id}><td><b>{getCourse(section.courseId)?.name}</b><small className="cell-sub">{section.code}</small></td><td>{getCourse(section.courseId)?.credits}</td><td>{money((getCourse(section.courseId)?.credits || 0) * PRICE_PER_CREDIT)}</td></tr>)}</tbody>
        </table></div> : <Empty title="Chưa đăng ký học phần" description="Đăng ký môn học để phát sinh học phí." />}
        <Button kind="outline" onClick={() => navigate("enrollment")}>Quay lại đăng ký học phần</Button>
      </Card>
      <Card title="Xác nhận thanh toán">
        <div className="invoice-total">
          <div><span>Tổng học phí</span><b>{money(total)}</b></div>
          <div><span>Đã thanh toán</span><b>{money(paid)}</b></div>
          <div className="final-total"><strong>Còn phải nộp</strong><strong>{money(balance)}</strong></div>
        </div>
        {balance > 0 ? <form className="payment-form" onSubmit={submit}>
          <p className="soft-note">Chế độ demo: xác nhận chỉ lưu dữ liệu trên trình duyệt, không chuyển tiền thật.</p>
          <Field label="Số tiền thanh toán (VND)"><input className="control" type="number" min="1" max={balance} step="1" required value={amount} onChange={event => setAmount(event.target.value)} /></Field>
          <Button kind="outline" onClick={() => setAmount(String(balance))}>Thanh toán toàn bộ công nợ</Button>
          <label className="payment-confirm"><input type="checkbox" checked={confirmed} onChange={event => setConfirmed(event.target.checked)} required />Tôi xác nhận ghi nhận thanh toán mô phỏng.</label>
          <Button type="submit" disabled={!confirmed || !amount}>Xác nhận thanh toán</Button>
        </form> : <Empty title={sections.length ? "Đã hoàn tất học phí" : "Chưa có công nợ"} />}
      </Card>
    </div>
  </>;
}
