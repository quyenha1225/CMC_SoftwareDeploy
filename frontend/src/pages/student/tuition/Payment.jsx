import React, { useState } from "react";
import { STUDENT_ID, PRICE_PER_CREDIT, getSection, getCourse, money } from "../../../data/portalData.js";
import { Button, Card, PageHeader, Field, Empty, todayVN } from "../../../components/ui.jsx";
import "./Payment.css";
import "./Tuition.css";
import { invoices, recordPayment } from "../../../data/workflows.js";

export default function Payment({ state, update, notify, navigate }) {
  const [amount, setAmount] = useState("");
  const [confirmed, setConfirmed] = useState(false);
  const [receipt, setReceipt] = useState(null);
  const mine = invoices(state).filter(item => item.studentId === STUDENT_ID);
  const [invoiceId, setInvoiceId] = useState(mine.find(item => item.balance > 0)?.id || mine[0]?.id || "");
  const invoice = mine.find(item => item.id === invoiceId);
  const sections = invoice?.items.map(item => item.section) || [];
  const total = invoice?.total || 0, paid = invoice?.paid || 0, balance = invoice?.balance || 0;

  function submit(event) {
    event.preventDefault();
    const value = Number(amount);
    if (!confirmed || !Number.isSafeInteger(value) || value <= 0 || value > balance) {
      notify("Nhập số tiền nguyên hợp lệ, không vượt công nợ và xác nhận khoản nộp.", "error");
      return;
    }
    try {
      const next = recordPayment(state, invoiceId, value);
      update(() => next);
      setReceipt(next.payments.at(-1));
    } catch (error) { notify(error.message, "error"); return; }
    setAmount("");
    setConfirmed(false);
    notify("Đã ghi nhận khoản nộp học phí.", "success");
  }

  return <>
    <PageHeader title="Thanh toán học phí" description="Kiểm tra học phần đã đăng ký và công nợ trước khi thanh toán." action={<Button kind="outline" onClick={() => navigate("tuition")}>Về mục học phí</Button>} />
    <Field label="Hóa đơn học kỳ"><select className="control" value={invoiceId} onChange={event => { setInvoiceId(event.target.value); setAmount(""); setConfirmed(false); }}>{!mine.length && <option value="">Chưa có hóa đơn</option>}{mine.map(item => <option key={item.id} value={item.id}>{item.id} · Còn nợ {money(item.balance)}</option>)}</select></Field>
    {receipt && <div className="soft-note" role="status">Đã ghi nhận {money(receipt.amount)} · Mã giao dịch {receipt.id} · {receipt.date}</div>}
    <div className="payment-layout">
      <Card title="Học phần đã đăng ký">
        {sections.length ? <div className="table-wrap"><table className="data-table">
          <thead><tr><th>Học phần</th><th>Tín chỉ</th><th>Học phí</th></tr></thead>
          <tbody>{sections.map(section => <tr key={section.id}><td><b>{getCourse(section.courseId, state)?.name}</b><small className="cell-sub">{section.code}</small></td><td>{getCourse(section.courseId, state)?.credits}</td><td>{money((getCourse(section.courseId, state)?.credits || 0) * PRICE_PER_CREDIT)}</td></tr>)}</tbody>
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
          <Field label="Số tiền thanh toán (VND)"><input className="control" type="number" min="1" max={balance} step="1" required value={amount} onChange={event => setAmount(event.target.value)} /></Field>
          <Button kind="outline" onClick={() => setAmount(String(balance))}>Thanh toán toàn bộ công nợ</Button>
          <label className="payment-confirm"><input type="checkbox" checked={confirmed} onChange={event => setConfirmed(event.target.checked)} required />Tôi xác nhận thông tin khoản nộp học phí.</label>
          <Button type="submit" disabled={!confirmed || !amount}>Xác nhận thanh toán</Button>
        </form> : <Empty title={sections.length ? "Đã hoàn tất học phí" : "Chưa có công nợ"} />}
      </Card>
    </div>
  </>;
}
