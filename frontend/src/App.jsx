import { normalizeState } from "./data/workflows.js";
import { canViewPage } from "./data/accessPolicy.js";
import React, { lazy, Suspense, useEffect, useState } from "react";
const ForgotPassword = lazy(() => import("./pages/public/forgot-password/ForgotPassword.jsx"));
const Application = lazy(() => import("./pages/student/application/Application.jsx"));
const Applications = lazy(() => import("./pages/affairs/applications/Applications.jsx"));
import PublicHeader from "./components/landing/PublicHeader.jsx";
const Catalog = lazy(() => import("./pages/academic/catalog/Catalog.jsx"));
const Finance = lazy(() => import("./pages/finance/Finance.jsx"));
const Funds = lazy(() => import("./pages/finance/Funds.jsx"));
const MailLog = lazy(() => import("./pages/administration/mail/MailLog.jsx"));
const Events = lazy(() => import("./pages/events/Events.jsx"));
const ManageEvents = lazy(() => import("./pages/events/ManageEvents.jsx"));
const CampusArticle = lazy(() => import("./pages/events/CampusArticle.jsx"));
import Icon from "./components/common/Icon.jsx";
import { ACCOUNTS, initialState, ROLE_NAMES } from "./data/portalData.js";
import { initial, ROLE_KEY, STORAGE_KEY } from "./components/ui.jsx";
import { MENU, navTitle } from "./components/layout/navigation.js";
import AppFooter from "./components/layout/AppFooter.jsx";
import AppHeader from "./components/layout/AppHeader.jsx";
import AppSidebar from "./components/layout/AppSidebar.jsx";
const Dashboard = lazy(() => import("./pages/student/dashboard/Dashboard.jsx"));
const Enrollment = lazy(() => import("./pages/student/enrollment/Enrollment.jsx"));
const Schedule = lazy(() => import("./pages/student/schedule/Schedule.jsx"));
const Results = lazy(() => import("./pages/student/results/Results.jsx"));
const Payment = lazy(() => import("./pages/student/tuition/Payment.jsx"));
const Requests = lazy(() => import("./pages/student/requests/Requests.jsx"));
const Teaching = lazy(() => import("./pages/academic/Teaching.jsx"));
const GradeEntry = lazy(() => import("./pages/academic/GradeEntry.jsx"));
const ReviewGrades = lazy(() => import("./pages/academic/ReviewGrades.jsx"));
const Students = lazy(() => import("./pages/academic/Students.jsx"));
const Sections = lazy(() => import("./pages/academic/Sections.jsx"));
const Reports = lazy(() => import("./pages/administration/Reports.jsx"));
const Notices = lazy(() => import("./pages/administration/Notices.jsx"));
const StudentNotices = lazy(() => import("./pages/student/notices/Notices.jsx"));
const Profile = lazy(() => import("./pages/student/profile/Profile.jsx"));
const Accounts = lazy(() => import("./pages/administration/Accounts.jsx"));
const StudentApprovals = lazy(() => import("./pages/administration/StudentApprovals.jsx"));
const Settings = lazy(() => import("./pages/administration/Settings.jsx"));
const AdminDashboard = lazy(() => import("./pages/administration/dashboard/AdminDashboard.jsx"));
const Landing = lazy(() => import("./pages/public/Landing.jsx"));
const Login = lazy(() => import("./pages/public/Login.jsx"));
import "./styles/portal.css";
import "./styles/theme.css";
import "./styles/refinements.css";

function AppContent() {
  const [screen, setScreen] = useState(() => window.location.hash.startsWith("#event/") ? "event" : "landing");
  const [eventId, setEventId] = useState(() => window.location.hash.slice(7));
  useEffect(() => {
    const handleHash = () => {
      if (window.location.hash.startsWith("#event/")) { setEventId(window.location.hash.slice(7)); setScreen("event"); window.scrollTo(0, 0); }
      else if (window.location.hash === "#events") setScreen("landing");
    };
    window.addEventListener("hashchange", handleHash);
    return () => window.removeEventListener("hashchange", handleHash);
  }, []);
  const [role, setRole] = useState(
    () => {
      const savedRole = localStorage.getItem(ROLE_KEY);
      return savedRole === "admin" ? "principal" : Object.hasOwn(ROLE_NAMES, savedRole) ? savedRole : "student";
    },
  );
  const [page, setPage] = useState("dashboard");
  const [scheduleView, setScheduleView] = useState("classes");
  const [teachingSection, setTeachingSection] = useState(null);
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
    const timer = setTimeout(() => {
      try { localStorage.setItem(STORAGE_KEY, JSON.stringify(state)); }
      catch { setToast({ text: "Kh?ng ?? dung l??ng l?u d? li?u. H?y gi?m dung l??ng t?p h? s?.", kind: "error" }); }
    }, 250);
    return () => clearTimeout(timer);
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

  const update = (updater) => setState((previous) => normalizeState(updater(previous)));
  const notify = (text, kind = "success") => setToast({ text, kind });
  const navigate = (destination, options = {}) => {
    if (destination === "grade-entry") setTeachingSection(options.sectionId || null);
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
    if (destination === "landing" && window.location.hash.startsWith("#event/")) window.history.replaceState(null, "", "#top");
    setScreen(destination);
    setSidebarOpen(false);
    setAlertsOpen(false);
    window.scrollTo({ top: 0, behavior: "smooth" });
  };
  const changeRole = (nextRole) => {
    setRole(nextRole);
    navigate(nextRole === "affairs" ? "applications" : "dashboard");
    notify(
      `Đang xem giao diện: ${ROLE_NAMES[nextRole]}.`,
      "info",
    );
  };
  const enterPortal = (nextRole) => {
    if (nextRole) setRole(nextRole);
    setPage(nextRole === "affairs" ? "applications" : "dashboard");
    showScreen("portal");
  };
  const resetDemo = () => setState(normalizeState(structuredClone(initialState)));

  function renderPage() {
    if (!canViewPage(role, page)) return <div className="warning-box" role="alert">Trang này không thuộc vai trò hiện tại. Hãy chọn chức năng trong menu bên trái.</div>;
    switch (page) {
      case "mail-log":
        return <MailLog state={state} />;
      case "catalog":
        return <Catalog state={state} update={update} notify={notify} />;
      case "funds":
        return <Funds state={state} update={update} notify={notify} />;
      case "events":
        return <Events state={state} update={update} />;
      case "manage-events":
        return ["affairs", "training", "principal"].includes(role) ? <ManageEvents state={state} update={update} notify={notify} /> : null;
      case "applications":
        return role === "affairs" ? <Applications state={state} update={update} notify={notify} /> : null;
      case "dashboard":
        if (role === "principal") return <AdminDashboard state={state} account={account} navigate={navigate} />;
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
          <Finance state={state} role={role} update={update} notify={notify} navigate={navigate} />
        );
      case "requests":
        return (
          <Requests role={role} state={state} update={update} notify={notify} />
        );
      case "teaching":
        return <Teaching state={state} navigate={navigate} />;
      case "grade-entry":
        return <GradeEntry state={state} update={update} notify={notify} selectedSectionId={teachingSection} />;
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
          <Finance
            role="training"
            state={state}
            update={update}
            notify={notify}
          />
        );
      case "reports":
        return <Reports state={state} update={update} notify={notify} />;
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
    return <Landing state={state} update={update} onOpenEvent={id => { setEventId(id); showScreen("event"); window.location.hash = `event/${id}`; }} onLogin={() => showScreen("login")} onApply={() => showScreen("application")} />;
  if (screen === "event") {
    const post = state.campusPosts.find(item => item.id === eventId && item.status === "PUBLISHED");
    return <div className="public-site"><PublicHeader onBack={() => { window.location.hash = "events"; }} /><main className="campus-article-page"><button className="button-text" onClick={() => { window.location.hash = "events"; }}>← Về Tin tức & Sự kiện</button>{post ? <CampusArticle post={post} onFollow={() => showScreen("login")} /> : <p role="status">Bài viết chưa được đăng hoặc đã được ẩn.</p>}</main></div>;
  }
  if (screen === "forgot-password") return <ForgotPassword onBack={() => showScreen("landing")} onLogin={() => showScreen("login")} />;
  if (screen === "application") return <div className="public-site"><PublicHeader onBack={() => showScreen("landing")} /><main className="application-public"><Application state={state} update={update} /></main></div>;
  if (screen === "login") {
    return <Login onBack={() => showScreen("landing")} onLogin={enterPortal} onForgotPassword={() => showScreen("forgot-password")} />;
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
      className={`app-layout ${role === "principal" ? "admin-layout" : ""} ${sidebarCollapsed ? "sidebar-collapsed" : ""}`}
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
            <Suspense fallback={<div className="page-loading" role="status"><span />Đang tải nội dung…</div>}>{renderPage()}</Suspense>
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

export default function App() {
  return <Suspense fallback={<div className="page-loading" role="status"><span />Đang tải giao diện…</div>}><AppContent /></Suspense>;
}
