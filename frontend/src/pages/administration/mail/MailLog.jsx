import React, { useState } from "react";
import { Badge, Card, Empty, Field, PageHeader } from "../../../components/ui.jsx";
import Pagination, { usePagination } from "../../../components/common/Pagination.jsx";

export default function MailLog({ state }) {
  const [search, setSearch] = useState("");
  const rows = state.mailLog.filter(item => `${item.to} ${item.subject}`.toLowerCase().includes(search.toLowerCase()));
  const page = usePagination(rows, search);
  return <><PageHeader title="Lịch sử email thông báo" description="Theo dõi thông báo liên quan đến quá trình xử lý hồ sơ." /><Card title="Email nghiệp vụ"><Field label="Tìm email / nội dung"><input className="control" value={search} onChange={event => setSearch(event.target.value)} /></Field><div className="table-wrap"><table className="data-table"><thead><tr><th>Người nhận</th><th>Tiêu đề</th><th>Thời gian</th><th>Trạng thái</th></tr></thead><tbody>{page.rows.map(item => <tr key={item.id}><td>{item.to}</td><td>{item.subject}</td><td>{item.date}</td><td><Badge tone="amber">Chưa gửi</Badge></td></tr>)}</tbody></table></div>{!rows.length && <Empty title="Chưa có email thông báo" />}<Pagination {...page} /></Card></>;
}
