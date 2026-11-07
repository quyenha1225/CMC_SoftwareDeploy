import React from "react";
import "./StudentApprovals.css";
import {
  Badge,
  Button,
  Card,
  Empty,
  PageHeader,
  todayVN,
} from "../../components/ui.jsx";

export default function StudentApprovals({ state, update, notify }) {
  const requests = state.studentApprovals || [];
  const pending = requests.filter((request) => request.status === "PENDING");
  const history = requests.filter((request) => request.status !== "PENDING");

  function review(request, approved) {
    if (
      approved &&
      state.students.some((student) => student.id === request.student.id)
    ) {
      notify(
        `Mã sinh viên ${request.student.id} đã tồn tại; không thể phê duyệt hồ sơ trùng.`,
        "error",
      );
      return;
    }

    update((current) => ({
      ...current,
      studentApprovals: (current.studentApprovals || []).map((item) =>
        item.id === request.id
          ? {
              ...item,
              status: approved ? "APPROVED" : "REJECTED",
              reviewedAt: todayVN(),
            }
          : item,
      ),
      students: approved
        ? [
            ...current.students,
            { ...request.student, status: "STUDYING" },
          ]
        : current.students,
    }));
    notify(
      approved
        ? `Đã phê duyệt hồ sơ ${request.student.name}.`
        : `Đã từ chối hồ sơ ${request.student.name}.`,
      approved ? "success" : "info",
    );
  }

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
                {pending.map((request) => (
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
                {history.map((request) => (
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
          </div>
        ) : (
          <Empty title="Chưa có lịch sử xử lý" />
        )}
      </Card>
    </>
  );
}
