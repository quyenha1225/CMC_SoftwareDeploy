import React, { useState } from "react";
import "./Settings.css";
import Icon from "../../components/common/Icon.jsx";
import { Badge, Button, Card, PageHeader } from "../../components/ui.jsx";
import ConfirmDialog from "../../components/common/ConfirmDialog.jsx";

export default function Settings({ resetDemo, notify }) {
  const [confirmReset, setConfirmReset] = useState(false);

  function restoreDemoData() {
    resetDemo();
    setConfirmReset(false);
    notify("Đã khôi phục dữ liệu demo.", "success");
  }

  return (
    <>
      <PageHeader
        title="Cấu hình bản demo"
        description="Quản lý dữ liệu mẫu trong trình duyệt hiện tại."
      />
      <Card
        title="Chế độ trải nghiệm"
        subtitle="Dành cho giai đoạn Frontend chưa có API Backend"
      >
        <div className="settings-item">
          <span className="settings-icon">
            <Icon name="shield" />
          </span>
          <div>
            <b>Mô phỏng phân quyền theo 5 vai trò</b>
            <p>Đổi vai trò bằng ô chọn tại góc phải; không có xác thực thật.</p>
          </div>
          <Badge tone="blue">Demo</Badge>
        </div>
        <div className="settings-item">
          <span className="settings-icon">
            <Icon name="database" />
          </span>
          <div>
            <b>Lưu dữ liệu trên trình duyệt</b>
            <p>
              Đăng ký, học phí, bảng điểm và yêu cầu được lưu bằng localStorage.
            </p>
          </div>
          <Badge tone="green">Bật</Badge>
        </div>
        <div className="settings-item">
          <span className="settings-icon">
            <Icon name="refresh" />
          </span>
          <div>
            <b>Khôi phục dữ liệu mẫu</b>
            <p>
              Xóa các thay đổi demo trên trình duyệt này và trở lại dữ liệu ban
              đầu.
            </p>
          </div>
          <Button kind="danger-outline" onClick={() => setConfirmReset(true)}>
            Đặt lại
          </Button>
        </div>
      </Card>
      {confirmReset && (
        <ConfirmDialog
          title="Khôi phục dữ liệu mẫu?"
          message="Thao tác này sẽ xóa các thay đổi demo đang lưu trên trình duyệt và đưa dữ liệu về trạng thái ban đầu."
          confirmLabel="Khôi phục dữ liệu"
          onConfirm={restoreDemoData}
          onCancel={() => setConfirmReset(false)}
        />
      )}
    </>
  );
}
