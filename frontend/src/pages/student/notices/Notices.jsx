import React, { useState } from "react";
import { PageHeader, Card, Badge, Button, Empty } from "../../../components/ui.jsx";
import NoticeDetail from "./NoticeDetail.jsx";
import "./Notices.css";

export default function Notices({ state }) {
  const [selected, setSelected] = useState(null);
  const notices = state.announcements.filter(notice => notice.audience === "all" || notice.audience === "student");
  return <>
    <PageHeader title="Thông báo" description="Thông tin học vụ, đào tạo và học phí dành cho sinh viên." />
    <div className="student-notices">
      {notices.map(notice => <Card key={notice.id} title={notice.title} subtitle={notice.date}>
        <Badge tone="blue">{notice.category}</Badge>
        <p className="student-notice-content">{notice.content}</p>
        <Button kind="outline" onClick={() => setSelected(notice)}>Xem chi tiết</Button>
      </Card>)}
    </div>
    {!notices.length && <Empty title="Chưa có thông báo" />}
    <NoticeDetail notice={selected} onClose={() => setSelected(null)} />
  </>;
}
