import React, { useEffect, useState } from "react";
import Icon from "./components/common/Icon.jsx";
import { ACCOUNTS, initialState, ROLE_NAMES } from "./data/portalData.js";
import { initial, ROLE_KEY, STORAGE_KEY } from "./components/ui.jsx";
import { MENU, navTitle } from "./components/layout/navigation.js";
import AppFooter from "./components/layout/AppFooter.jsx";
import AppHeader from "./components/layout/AppHeader.jsx";
import AppSidebar from "./components/layout/AppSidebar.jsx";
import Dashboard from "./pages/student/dashboard/Dashboard.jsx";
import Enrollment from "./pages/student/enrollment/Enrollment.jsx";
import Schedule from "./pages/student/schedule/Schedule.jsx";
import Results from "./pages/student/results/Results.jsx";
import Payment from "./pages/student/tuition/Payment.jsx";
import Tuition from "./pages/student/tuition/Tuition.jsx";
import Requests from "./pages/student/requests/Requests.jsx";
import Teaching from "./pages/academic/Teaching.jsx";
import GradeEntry from "./pages/academic/GradeEntry.jsx";
import ReviewGrades from "./pages/academic/ReviewGrades.jsx";
import Students from "./pages/academic/Students.jsx";
import Sections from "./pages/academic/Sections.jsx";
import Reports from "./pages/administration/Reports.jsx";
import Notices from "./pages/administration/Notices.jsx";
import StudentNotices from "./pages/student/notices/Notices.jsx";
import Profile from "./pages/student/profile/Profile.jsx";
import Accounts from "./pages/administration/Accounts.jsx";
import StudentApprovals from "./pages/administration/StudentApprovals.jsx";
import Settings from "./pages/administration/Settings.jsx";
import Landing from "./pages/public/Landing.jsx";
import Login from "./pages/public/Login.jsx";
import "./styles/portal.css";
import "./styles/theme.css";
import "./styles/refinements.css";

export default function App() {
  const [screen, setScreen] = useState("landing");
  const [role, setRole] = useState(
    () => {
      const savedRole = localStorage.getItem(ROLE_KEY);
      return savedRole === "admin" ? "training" : savedRole || "student";
    },
  );
  const [page, setPage] = useState("dashboard");
  const [scheduleView, setScheduleView] = useState("classes");
  const [state, setState] = useState(initial);
  const [toast, setToast] = useState(null);
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
  const [alertsOpen, setAlertsOpen] = useState(false);
  const [search, setSearch] = useState("");
  const [profileSection, setProfileSection] = useState(null);
  const account = ACCOUNTS.find((item) => item.role === role) || ACCOUNTS[0];
  const menu = MENU[role];

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  }, [state]);

  useEffect(() => {
    localStorage.setItem(ROLE_KEY, role);
  }, [role]);

  useEffect(() => {
    if (!toast) return undefined;
    const timer = setTimeout(() => setToast(null), 4200);
    return () => clearTimeout(timer);
  }, [toast]);

  useEffect(() => {
    if (page !== "profile" || !profileSection) return;
    document.getElementById(profileSection)?.scrollIntoView({
      behavior: "smooth",
      block: "center",
    });
  }, [page, profileSection]);

  const update = (updater) => setState((previous) => updater(previous));
  const notify = (text, kind = "success") => setToast({ text, kind });
  const navigate = (destination) => {
    const profileDestination = destination.startsWith("profile-");
    const scheduleDestination = destination.startsWith("schedule-");
    const nextPage = profileDestination ? "profile" : scheduleDestination ? "schedule" : destination;
    if (scheduleDestination) setScheduleView(destination === "schedule-exams" ? "exams" : "classes");
    else if (destination === "schedule") setScheduleView("classes");
    if (profileDestination) setProfileSection(destination);
    setPage(nextPage);
    setSidebarOpen(false);
    setAlertsOpen(false);
    if (!profileDestination) {
      setProfileSection(null);
      window.scrollTo({ top: 0, behavior: "smooth" });
    }
  };
  const showScreen = (destination) => {
    setScreen(destination);
    setSidebarOpen(false);
    setAlertsOpen(false);
    window.scrollTo({ top: 0, behavior: "smooth" });
  };
  const changeRole = (nextRole) => {
    setRole(nextRole);
    navigate("dashboard");
    notify(
      `Đang xem giao diện: ${ROLE_NAMES[nextRole]}. Dữ liệu vẫn là mô phỏng.`,
      "info",
    );
  };
  const enterPortal = (nextRole) => {
    if (nextRole) setRole(nextRole);
    setPage("dashboard");
    showScreen("portal");
  };
  const resetDemo = () => setState(structuredClone(initialState));

  function renderPage() {
    switch (page) {
      case "dashboard":
        return (
          <Dashboard
            role={role}
            state={state}
            account={account}
            navigate={navigate}
            notify={notify}
          />
        );
      case "enrollment":
        return (
          <Enrollment
            state={state}
            update={update}
            notify={notify}
            navigate={navigate}
          />
        );
      case "schedule":
        return <Schedule state={state} role={role} update={update} notify={notify} view={scheduleView} onViewChange={setScheduleView} />;
      case "grades":
        return <Results state={state} />;
      case "payment":
        return <Payment state={state} update={update} notify={notify} navigate={navigate} />;
      case "tuition":
        return (
          <Tuition state={state} role={role} update={update} notify={notify} navigate={navigate} />
        );
      case "requests":
        return (
          <Requests role={role} state={state} update={update} notify={notify} />
        );
      case "teaching":
        return <Teaching state={state} navigate={navigate} />;
      case "grade-entry":
        return <GradeEntry state={state} update={update} notify={notify} />;
      case "students":
        return <Students state={state} update={update} notify={notify} />;
      case "sections":
        return <Sections state={state} update={update} notify={notify} />;
      case "grade-approval":
        return (
          <ReviewGrades
            role="training"
            state={state}
            update={update}
            notify={notify}
          />
        );
      case "approvals":
        return (
          <ReviewGrades
            role={role}
            state={state}
            update={update}
            notify={notify}
          />
        );
      case "finance":
        return (
          <Tuition
            role="training"
            state={state}
            update={update}
            notify={notify}
          />
        );
      case "reports":
        return <Reports state={state} notify={notify} />;
      case "notices":
        if (role === "student") return <StudentNotices state={state} />;
        return (
          <Notices state={state} role={role} update={update} notify={notify} />
        );
      case "profile":
        return (
          <Profile
            state={state}
            role={role}
            update={update}
            notify={notify}
          />
        );
      case "accounts":
        return <Accounts state={state} update={update} notify={notify} />;
      case "student-approvals":
        return (
          <StudentApprovals state={state} update={update} notify={notify} />
        );
      case "settings":
        return <Settings resetDemo={resetDemo} notify={notify} />;
      default:
        return (
          <Dashboard
            role={role}
            state={state}
            account={account}
            navigate={navigate}
            notify={notify}
          />
        );
    }
  }

  if (screen === "landing")
    return <Landing onLogin={() => showScreen("login")} />;
  if (screen === "login") {
    return <Login onBack={() => showScreen("landing")} onLogin={enterPortal} />;
  }

  const visibleAnnouncements = state.announcements.filter(
    (notice) =>
      role === "training" ||
      notice.audience === "all" ||
      notice.audience === role,
  );
  const noticesCount = visibleAnnouncements.length;
  const handleSearchKeyDown = (event) => {
    if (event.key !== "Enter") return;
    const found = menu.find(([title]) =>
      title.toLowerCase().includes(search.toLowerCase()),
    );
    if (found) {
      navigate(found[1]);
      setSearch("");
    }
  };

  return (
    <div
      className={`app-layout ${sidebarCollapsed ? "sidebar-collapsed" : ""}`}
    >
      <AppSidebar
        role={role}
        page={page}
        activeProfileSection={profileSection}
        activeScheduleSection={`schedule-${scheduleView}`}
        collapsed={sidebarCollapsed}
        sidebarOpen={sidebarOpen}
        noticesCount={noticesCount}
        onNavigate={navigate}
        onExpand={() => setSidebarCollapsed(false)}
        onClose={() => setSidebarOpen(false)}
      />
      <div className="main-frame">
        <AppHeader
          pageTitle={navTitle[page]}
          account={account}
          role={role}
          sidebarCollapsed={sidebarCollapsed}
          sidebarOpen={sidebarOpen}
          search={search}
          alerts={alertsOpen}
          announcements={visibleAnnouncements}
          onSearch={(event) => setSearch(event.target.value)}
          onClearSearch={() => setSearch("")}
          onSearchKeyDown={handleSearchKeyDown}
          onRoleChange={changeRole}
          onAlertToggle={() => setAlertsOpen((open) => !open)}
          onNavigate={navigate}
          onHome={() => showScreen("landing")}
          onLogout={() => showScreen("login")}
          onMenuToggle={() => {
            if (window.matchMedia("(max-width: 740px)").matches) {
              setSidebarOpen((open) => !open);
              return;
            }
            setSidebarCollapsed((collapsed) => !collapsed);
          }}
        />
        <div className="view-area">
          <main className={`page-content page-enter page-${page}`} key={page}>
            {renderPage()}
          </main>
          <AppFooter />
        </div>
      </div>
      {toast && (
        <div className={`toast toast-${toast.kind}`}>
          <Icon
            name={toast.kind === "error" ? "alert" : "checkcircle"}
            size={20}
          />
          <span>{toast.text}</span>
          <button onClick={() => setToast(null)} aria-label="Đóng">
            <Icon name="x" size={16} />
          </button>
        </div>
      )}
    </div>
  );
}
