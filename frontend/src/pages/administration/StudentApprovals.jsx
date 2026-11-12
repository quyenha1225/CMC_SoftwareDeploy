import Pagination, { usePagination } from "../../components/common/Pagination.jsx";
import { approveStudent } from "../../data/workflows.js";
import { useState } from "react";
import React from "react";
import ApplicationDetail from "../student/application/ApplicationDetail.jsx";
import "./StudentApprovals.css";
import {
  Badge,
  Button,
  Card,
  Empty,
  PageHeader,
  todayVN,
  Modal,
  Field,
} from "../../components/ui.jsx";

export default function StudentApprovals({ state, update, notify }) {
  const [rejection, setRejection] = useState(null), [reason, setReason] = useState("");
  const [detail, setDetail] = useState(null);
  const requests = state.studentApprovals || [];
  const pending = requests.filter((request) => request.status === "PENDING");
  const history = requests.filter((request) => request.status !== "PENDING");

  function review(request, approved) {
    if (!approved) { setRejection(request); setReason(""); return; }
    try { const next = approveStudent(state, request.id, true); update(() => next); notify("?? duy?t, ??ng b? sinh vi?n v? t?i kho?n/email tr??ng."); }
    catch (error) { notify(error.message, "error"); }
  }

  const pendingPage = usePagination(pending);
  const historyPage = usePagination(history);
  return (
    <>
      <PageHeader
        title="Phê duyệt hồ sơ sinh viên"
        description="Ban Giám hiệu xem xét hồ sơ do Phòng Đào tạo ghi nhận trước khi thêm vào danh sách sinh viên chính thức."
      />
      <Card
        title="Hồ sơ chờ phê duyệt"
        subtitle={`${pending.length} hồ sơ cần xử lý`}
      >
        {pending.length > 0 ? (
          <div className="table-wrap">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Mã sinh viên</th>
                  <th>Họ tên</th>
                  <th>Lớp / ngành</th>
                  <th>Khóa</th>
                  <th>Email / điện thoại</th>
                  <th>Ngày gửi</th>
                  <th>Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {pendingPage.rows.map((request) => (
                  <tr key={request.id}>
                    <td>{request.student.id}</td>
                    <td>{request.student.name}</td>
                    <td>
                      {request.student.className} · {request.student.major}
                    </td>
                    <td>{request.student.year}</td>
                    <td>
                      {request.student.email || "—"}
                      <small className="cell-sub">
                        {request.student.phone || "—"}
                      </small>
                    </td>
                    <td>{request.submittedAt}</td>
                    <td>
                      <div className="approval-actions">
                        {request.applicationId && <Button small kind="outline" onClick={() => setDetail(state.applications.find(item => item.id === request.applicationId))}>Xem hồ sơ gốc</Button>}
                        <Button
                          small
                          onClick={() => review(request, true)}
                        >
                          Phê duyệt
                        </Button>
                        <Button
                          small
                          kind="danger-outline"
                          onClick={() => review(request, false)}
                        >
                          Từ chối
                        </Button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
<Pagination {...pendingPage} />
          </div>
        ) : (
          <Empty
            icon="checkcircle"
            title="Không có hồ sơ chờ duyệt"
            description="Hồ sơ mới từ Phòng Đào tạo sẽ xuất hiện tại đây."
          />
        )}
      </Card>
      <Card
        title="Lịch sử phê duyệt"
        subtitle={`${history.length} hồ sơ đã được xử lý`}
      >
        {history.length > 0 ? (
          <div className="table-wrap">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Mã sinh viên</th>
                  <th>Họ tên</th>
                  <th>Lớp / ngành</th>
                  <th>Ngày gửi</th>
                  <th>Ngày xử lý</th>
                  <th>Kết quả</th>
                </tr>
              </thead>
              <tbody>
                {historyPage.rows.map((request) => (
                  <tr key={request.id}>
                    <td>{request.student.id}</td>
                    <td>{request.student.name}</td>
                    <td>
                      {request.student.className} · {request.student.major}
                    </td>
                    <td>{request.submittedAt}</td>
                    <td>{request.reviewedAt || "—"}</td>
                    <td>
                      <Badge
                        tone={request.status === "APPROVED" ? "green" : "red"}
                        dot
                      >
                        {request.status === "APPROVED"
                          ? "Đã phê duyệt"
                          : "Đã từ chối"}
                      </Badge>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
<Pagination {...historyPage} />
          </div>
        ) : (
          <Empty title="Chưa có lịch sử xử lý" />
        )}
      </Card>
      {detail && <ApplicationDetail application={detail} onClose={() => setDetail(null)} />}
      {rejection && <Modal title="Từ chối hồ sơ" onClose={() => setRejection(null)}><form onSubmit={event => { event.preventDefault(); try { const next = approveStudent(state, rejection.id, false, reason); update(() => next); setRejection(null); notify("Đã lưu kết quả xét duyệt."); } catch(error) { notify(error.message, "error"); } }}><Field label="Lý do từ chối"><textarea className="control textarea" required value={reason} onChange={event => setReason(event.target.value)} /></Field><div className="modal-actions"><Button kind="outline" onClick={() => setRejection(null)}>Hủy</Button><Button type="submit">Xác nhận</Button></div></form></Modal>}
    </>
  );
}
