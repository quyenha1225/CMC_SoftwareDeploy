import React from "react";
import { Modal } from "../../../components/ui.jsx";
import "./Notices.css";

export default function NoticeDetail({ notice, onClose }) {
  if (!notice) return null;
  return <Modal title={notice.title} subtitle={`${notice.category} · ${notice.date}`} onClose={onClose}>
    <p><strong>Người đăng:</strong> {notice.author || "Phòng Đào tạo"}</p>
    <p className="student-notice-content">{notice.content}</p>
  </Modal>;
}
