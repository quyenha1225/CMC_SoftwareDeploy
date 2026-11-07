import React, { useState } from "react";
import "./Accounts.css";
import Icon from "../../components/common/Icon.jsx";
import {
  ROLE_NAMES,
  ACCOUNTS,
  STUDENT_ID,
  WEEKDAYS,
  COURSE_LIST,
  initialState,
  getCourse,
  getSection,
  getGradeSheet,
  gradeTotal,
  courseLabel,
  money,
  gradeStatusText,
  requestStatusText,
  studentStatusText,
  PRICE_PER_CREDIT,
} from "../../data/portalData.js";
import {
  Badge,
  Button,
  Card,
  PageHeader,
  Avatar,
  Stat,
  Empty,
  Modal,
  Field,
  LevelBar,
  GradeChip,
  TextRows,
  Donut,
  AreaChart,
  todayVN,
  number,
  displayDay,
  slot,
  colorByStatus,
  csvDownload,
} from "../../components/ui.jsx";

export default function Accounts({ state, update, notify }) {
  function toggle(id) {
    update((s) => ({
      ...s,
      users: s.users.map((u) =>
        u.id === id
          ? { ...u, status: u.status === "ACTIVE" ? "LOCKED" : "ACTIVE" }
          : u,
      ),
    }));
    notify("Đã thay đổi trạng thái tài khoản demo.", "success");
  }
  return (
    <>
      <PageHeader
        title="Tài khoản & phân quyền"
        description="Danh sách tài khoản mẫu cho 5 vai trò; không liên kết xác thực thật."
      />
      <Card
        title="Tài khoản trong hệ thống"
        subtitle="RBAC sẽ được xác thực bằng Spring Security khi triển khai Backend"
      >
        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>Người dùng</th>
                <th>Tên đăng nhập</th>
                <th>Vai trò</th>
                <th>Trạng thái</th>
                <th>Thao tác</th>
              </tr>
            </thead>
            <tbody>
              {state.users.map((u) => (
                <tr key={u.id}>
                  <td>
                    <div className="person-cell">
                      <Avatar name={u.name} size="sm" />
                      <b>{u.name}</b>
                    </div>
                  </td>
                  <td>{u.login}</td>
                  <td>{ROLE_NAMES[u.role]}</td>
                  <td>
                    <Badge tone={u.status === "ACTIVE" ? "green" : "red"} dot>
                      {u.status === "ACTIVE" ? "Hoạt động" : "Đã khóa"}
                    </Badge>
                  </td>
                  <td>
                    <Button small kind="outline" onClick={() => toggle(u.id)}>
                      {u.status === "ACTIVE" ? "Khóa demo" : "Mở khóa demo"}
                    </Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>
      <div className="warning-box">
        <Icon name="alert" size={18} /> Chuyển vai trò ở thanh trên chỉ dùng để
        xem demo giao diện; chưa phải đăng nhập hoặc phân quyền bảo mật thực tế.
      </div>
    </>
  );
}
