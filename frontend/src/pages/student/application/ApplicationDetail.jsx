import React from "react";
import { Modal, TextRows } from "../../../components/ui.jsx";
import { APPLICATION_STATUS } from "./applicationData.js";

export default function ApplicationDetail({ application, onClose, onCheck }) {
  return <Modal title={`Hồ sơ ${application.id}`} subtitle={APPLICATION_STATUS[application.status]} onClose={onClose}>
    <TextRows rows={[["Họ tên", application.name], ["Email", application.email], ["Điện thoại", application.phone], ["Ngành đăng ký", application.major], ["Địa chỉ", application.address], ["Ngày nộp", application.submittedAt]]} />
    <TextRows rows={[["CCCD / hộ chiếu", application.identityNumber || "Chưa bổ sung"], ["Ngày cấp / nơi cấp", `${application.identityDate || "—"} · ${application.identityPlace || "—"}`], ["Trường THPT", application.highSchool || "Chưa bổ sung"], ["Năm tốt nghiệp", application.graduationYear || "—"], ["Mã sinh viên được cấp", application.assignedStudentId || "Chưa cấp"]]} />
    <h3>Giấy tờ đính kèm</h3>
    <ul className="application-documents">{application.documents.map(doc => <li key={doc.kind}><span>{doc.kind}</span><a href={doc.data} download={doc.name}>{doc.name}</a>{onCheck && application.status === "RECEIVED" ? <label className="document-check"><input type="checkbox" checked={!!application.documentChecks?.[doc.kind]} onChange={event => onCheck(doc.kind, event.target.checked)} />Đã kiểm tra, đạt yêu cầu</label> : <small> · {application.documentChecks?.[doc.kind] ? "Đã kiểm tra đạt" : "Chưa xác nhận giấy tờ"}</small>}</li>)}</ul>
    <h3>Lịch sử xử lý</h3>
    <ol className="application-timeline">{application.history.map((entry, index) => <li key={index}><strong>{APPLICATION_STATUS[entry.status]}</strong> · {entry.at}<p>{entry.note}</p></li>)}</ol>
  </Modal>;
}
