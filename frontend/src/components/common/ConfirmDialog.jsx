import React from "react";
import Icon from "./Icon.jsx";
import { Button, Modal } from "../ui.jsx";

export default function ConfirmDialog({
  title,
  message,
  confirmLabel,
  onConfirm,
  onCancel,
}) {
  return (
    <Modal title={title} onClose={onCancel}>
      <div className="confirm-dialog">
        <span className="confirm-icon">
          <Icon name="alert" size={22} />
        </span>
        <p>{message}</p>
      </div>
      <div className="modal-actions">
        <Button kind="outline" onClick={onCancel}>
          Quay lại
        </Button>
        <Button kind="danger-outline" onClick={onConfirm}>
          {confirmLabel}
        </Button>
      </div>
    </Modal>
  );
}
