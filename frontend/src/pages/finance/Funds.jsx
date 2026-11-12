import React, { useState } from "react";
import { money } from "../../data/portalData.js";
import { Button, Card, Empty, Field, Modal, PageHeader, Stat, Badge } from "../../components/ui.jsx";
import Pagination, { usePagination } from "../../components/common/Pagination.jsx";
import { allocateToFund, createHandover, confirmHandover } from "../../data/workflows.js";
import "./Finance.css";

export default function Funds({ state, update, notify }) {
  const [selected, setSelected] = useState([]), [recipient, setRecipient] = useState(""), [open, setOpen] = useState(false);
  const allocated = new Set(state.fundReceipts.map(item => item.paymentId));
  const available = state.payments.filter(item => !allocated.has(item.id));
  const pending = usePagination(available);
  const reserved = new Set(state.handovers.flatMap(item => item.receiptIds));
  const receipts = state.fundReceipts.filter(item => !reserved.has(item.id));
  const receiptPage = usePagination(receipts);
  const handoverPage = usePagination([...state.handovers].reverse());
  function allocate(payment) {
    if (state.fundReceipts.some(item => item.paymentId === payment.id)) return notify("Khoản thu đã được đưa vào quỹ.", "error");
    try { const next = allocateToFund(state, payment.id); update(() => next); } catch(error) { notify(error.message, "error"); return; }
    notify("Đã liên kết khoản thu vào sổ quỹ CTSV.");
  }
  function create(event) {
    event.preventDefault();
    const chosen = receipts.filter(item => selected.includes(item.id));
    if (!recipient.trim() || chosen.length !== selected.length || !chosen.length) return notify("Chọn khoản quỹ chưa bàn giao và nhập người nhận.", "error");
    try { const next = createHandover(state, selected, recipient); update(() => next); } catch(error) { notify(error.message, "error"); return; }
    setSelected([]); setRecipient(""); setOpen(false); notify("Đã lập biên bản chờ xác nhận bàn giao.");
  }
  return <>
    <PageHeader title="Quỹ CTSV & bàn giao tiền" description="Liên kết khoản thu, theo dõi sổ quỹ và xác nhận biên bản bàn giao." />
    <div className="stats-grid three"><Stat icon="wallet" label="Đã vào quỹ" value={money(state.fundReceipts.reduce((sum, item) => sum + item.amount, 0))} /><Stat icon="clock" label="Chưa lập bàn giao" value={money(receipts.reduce((sum, item) => sum + item.amount, 0))} /><Stat icon="checkcircle" label="Đã xác nhận bàn giao" value={money(state.handovers.filter(item => item.status === "CONFIRMED").reduce((sum, item) => sum + item.amount, 0))} tone="green" /></div>
    <Card title="Khoản thu chưa liên kết quỹ"><div className="table-wrap"><table className="data-table"><thead><tr><th>Khoản thu</th><th>Hóa đơn</th><th>Số tiền</th><th>Thao tác</th></tr></thead><tbody>{pending.rows.map(item => <tr key={item.id}><td>{item.id}</td><td>{item.invoiceId}</td><td>{money(item.amount)}</td><td><Button small onClick={() => allocate(item)}>Đưa vào quỹ CTSV</Button></td></tr>)}</tbody></table></div>{!available.length && <Empty title="Không còn khoản thu chưa liên kết" />}<Pagination {...pending} /></Card>
    <Card title="Sổ quỹ chưa bàn giao" extra={<Button disabled={!selected.length} onClick={() => setOpen(true)}>Lập biên bản ({selected.length})</Button>}>
      {receiptPage.rows.map(item => <label className="fund-selection" key={item.id}><input type="checkbox" checked={selected.includes(item.id)} onChange={event => setSelected(previous => event.target.checked ? [...previous, item.id] : previous.filter(id => id !== item.id))} /><span>{item.id} · {item.paymentId}</span><strong>{money(item.amount)}</strong></label>)}
      {!receipts.length && <Empty title="Chưa có khoản quỹ để bàn giao" />}<Pagination {...receiptPage} />
    </Card>
    <Card title="Biên bản bàn giao"><div className="table-wrap"><table className="data-table"><thead><tr><th>Biên bản</th><th>Người nhận</th><th>Số khoản</th><th>Số tiền</th><th>Ngày lập</th><th>Trạng thái</th><th>Thao tác</th></tr></thead><tbody>{handoverPage.rows.map(item => <tr key={item.id}><td>{item.id}</td><td>{item.recipient}</td><td>{item.receiptIds.length}</td><td>{money(item.amount)}</td><td>{item.date}</td><td><Badge tone={item.status === "CONFIRMED" ? "green" : "amber"}>{item.status === "CONFIRMED" ? "Đã bàn giao" : "Chờ xác nhận"}</Badge></td><td>{item.status === "PENDING" ? <Button small onClick={() => { try { const next = confirmHandover(state, item.id); update(() => next); } catch(error) { notify(error.message, "error"); return; } notify("Đã xác nhận bàn giao."); }}>Xác nhận đã bàn giao</Button> : item.confirmedAt}</td></tr>)}</tbody></table></div><Pagination {...handoverPage} /></Card>
    {open && <Modal title="Lập biên bản bàn giao" onClose={() => setOpen(false)}><form onSubmit={create}><p>Đã chọn {selected.length} khoản · {money(receipts.filter(item => selected.includes(item.id)).reduce((sum, item) => sum + item.amount, 0))}</p><Field label="Người / đơn vị nhận"><input className="control" required maxLength={160} value={recipient} onChange={event => setRecipient(event.target.value)} /></Field><div className="modal-actions"><Button kind="outline" onClick={() => setOpen(false)}>Hủy</Button><Button type="submit">Lập biên bản</Button></div></form></Modal>}
  </>;
}
