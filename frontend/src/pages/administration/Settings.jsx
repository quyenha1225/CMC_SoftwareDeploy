import React, { useState } from "react";
import { Button, Card, PageHeader } from "../../components/ui.jsx";
import ConfirmDialog from "../../components/common/ConfirmDialog.jsx";
import "./Settings.css";

export default function Settings({ resetDemo, notify }) {
  const [confirmReset, setConfirmReset] = useState(false);
  return <><PageHeader title="Cấu hình hệ thống" description="Quản lý thiết lập và dữ liệu hệ thống." /><Card title="Khôi phục dữ liệu ban đầu"><div className="settings-item"><div><b>Đặt lại dữ liệu</b><p>Xóa các thay đổi hiện tại và khôi phục dữ liệu ban đầu. Thao tác này không thể hoàn tác.</p></div><Button kind="danger-outline" onClick={() => setConfirmReset(true)}>Đặt lại dữ liệu</Button></div></Card>{confirmReset && <ConfirmDialog title="Khôi phục dữ liệu ban đầu?" message="Các hồ sơ, bài viết, khoản nộp và thay đổi hiện tại sẽ bị xóa. Bạn có chắc chắn tiếp tục?" confirmLabel="Khôi phục dữ liệu" onCancel={() => setConfirmReset(false)} onConfirm={() => { resetDemo(); setConfirmReset(false); notify("Đã khôi phục dữ liệu ban đầu."); }} />}</>;
}
