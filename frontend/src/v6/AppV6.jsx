import React,{useEffect,useState,lazy,Suspense} from 'react';
import { api,ROLE_LABELS,roleMenus } from './api.js';
import ResourcePage from './ResourcePage.jsx';
import Timetable from './Timetable.jsx';
import OverviewOrbit from './OverviewOrbit.jsx';
import PortalNavigation, {pageTitle} from './PortalNavigation.jsx';
import StudentProfilePage from './StudentProfilePage.jsx';
import StudentTuition from './StudentTuition.jsx';
import StudentNotifications from './StudentNotifications.jsx';
import StudentAcademic, { StudentOverview } from './StudentAcademic.jsx';
import ExamSchedule from './ExamSchedule.jsx';
import Auth from './Auth.jsx';
import Icon from '../components/common/Icon.jsx';
import { Button,Card,Modal,PageHeader } from '../components/ui.jsx';
import PublicHeader from '../components/landing/PublicHeader.jsx';
import Fields from './Forms.jsx';
import '../styles/portal.css';
import '../styles/theme.css';
import '../styles/refinements.css';
import '../pages/administration/dashboard/AdminDashboard.css';
import '../components/common/Pagination.css';
import '../pages/finance/Finance.css';
import '../pages/student/application/Application.css';
import './v6.css';
const Landing=lazy(()=>import('../pages/public/Landing.jsx'));
function primaryRole(roles){return ['PRINCIPAL','CTSV','TRAINING_OFFICE','LECTURER','STUDENT','APPLICANT'].find(role=>roles.includes(role));}
export default function AppV6(){
  const [screen,setScreen]=useState(location.hash.startsWith('#reset-password/')?'login':'landing'),[eventId,setEventId]=useState(location.hash.slice(7)),[user,setUser]=useState(null),[role,setRole]=useState(''),[resources,setResources]=useState([]),[lookups,setLookups]=useState({}),[page,setPage]=useState('overview'),[toast,setToast]=useState(null),[error,setError]=useState(''),[posts,setPosts]=useState([]),[menuOpen,setMenuOpen]=useState(false),[passwordForm,setPasswordForm]=useState(null),[ready,setReady]=useState(false);
  const notify=(text,kind='success')=>setToast({text,kind});
  async function session(account,enter=true){setUser(account);const role=primaryRole(account.roles);setRole(role);setPage('overview');try{const [meta,data]=await Promise.all([api('/meta'),api('/lookups')]);setResources(meta.resources);setLookups(data);if(enter)setScreen('portal');setError('');}catch(error){setError(error.message);}}
  async function refresh(){try{setLookups(await api('/lookups'));}catch(error){notify(error.message,'error');}}
  async function loadPublic(){setPosts([]);}
  useEffect(()=>{let active=true;api('/me').then(account=>active&&session(account,!location.hash.startsWith('#reset-password/'))).catch(error=>{if(error.status!==401&&active)setError('Dịch vụ dữ liệu chưa sẵn sàng. Vui lòng kiểm tra backend và database V6.');}).finally(()=>active&&setReady(true));loadPublic();const expired=()=>{setUser(null);setScreen('login');notify('Phiên đăng nhập đã hết hạn.','error');};const hash=()=>{if(location.hash.startsWith('#reset-password/')){setScreen('login');}else if(location.hash.startsWith('#event/')){setEventId(location.hash.slice(7));setScreen('event');window.scrollTo(0,0);}else if(location.hash==='#events')setScreen('landing');};window.addEventListener('session-expired',expired);window.addEventListener('hashchange',hash);return()=>{active=false;window.removeEventListener('session-expired',expired);window.removeEventListener('hashchange',hash);};},[]);
  useEffect(()=>{if(!toast)return;const timer=setTimeout(()=>setToast(null),4500);return()=>clearTimeout(timer);},[toast]);
  useEffect(()=>{if(screen==='landing')loadPublic();},[screen]);
  useEffect(()=>{document.querySelector('.v6-view')?.scrollTo(0,0);window.scrollTo(0,0);},[page,screen]);
  const login=()=>setScreen(user?'portal':'login');
  const apply=()=>{if(user){if(user.roles.includes('APPLICANT')){setRole('APPLICANT');setPage('admissions');setScreen('portal');}else notify('Vui lòng sử dụng tài khoản ứng viên để nộp hồ sơ.','error');}else setScreen('register');window.scrollTo(0,0);};
  const publicState={campusPosts:posts,eventFollows:[]};
  if(screen==='landing')return <Suspense fallback={<p className="page-loading">Đang tải…</p>}>{error&&<div className="v6-connection" role="status">{error}</div>}<Landing state={publicState} update={()=>{}} onLogin={login} onApply={apply} sqlOnly/></Suspense>;
  if(!user||screen==='login'||screen==='register')return <Auth applicant={screen==='register'} onAuthenticated={async account=>{await session(account);if(screen==='register')setPage('admissions');}} onBack={()=>setScreen('landing')}/>;
  const allowed=(roleMenus[role]||[]).filter(key=>['timetable','exams'].includes(key)||resources.some(item=>item.key===key));
  const current=resources.find(item=>item.key===page);
  const navigate=key=>{if(key!=='overview'&&!allowed.includes(key))return notify('Không có quyền truy cập chức năng này.','error');setPage(key);setMenuOpen(false);};
  return <div className={`app-layout v6-layout ${role==='PRINCIPAL'?'admin-layout':''}`}>
    <aside className={`sidebar ${menuOpen?'sidebar-open':''}`}><div className="brand"><span className="brand-logo"><Icon name="graduation" size={28}/></span><strong>EduPortal.</strong></div><div className="workspace"><Icon name={role==='STUDENT'?'user':'building'} size={22}/><div><b>{ROLE_LABELS[role]}</b><span>{user.name}</span></div></div><PortalNavigation allowed={allowed} page={page} role={role} resources={resources} navigate={navigate}/></aside>
    {menuOpen&&<button className="mobile-overlay" aria-label="Đóng menu" onClick={()=>setMenuOpen(false)}/>}
    <div className="main-frame"><header className="topbar"><div className="topbar-left"><button className="icon-button" aria-label="Mở menu" onClick={()=>setMenuOpen(!menuOpen)}><Icon name="menu"/></button><button className="portal-home-button" onClick={()=>{setScreen('landing');location.hash='top';}}>Trang chủ</button><b>{pageTitle(page,role,resources)}</b></div><div className="v6-account"><span>{user.name}</span>{user.roles.length>1?<select aria-label="Vai trò được cấp" value={role} onChange={event=>{if(user.roles.includes(event.target.value)){setRole(event.target.value);setPage('overview');}}}>{user.roles.map(item=><option key={item} value={item}>{ROLE_LABELS[item]}</option>)}</select>:<strong>{ROLE_LABELS[role]}</strong>}<button className="icon-button" aria-label="Đổi mật khẩu" onClick={()=>setPasswordForm({})}><Icon name="shield" size={18}/></button><button className="icon-button" aria-label="Đăng xuất" onClick={async()=>{try{await api('/auth/logout',{method:'POST'});setUser(null);setResources([]);setLookups({});setScreen('login');}catch(error){notify(error.message,'error');}}}><Icon name="logout"/></button></div></header>
      <div className="v6-view"><main className="page-content" key={`${role}:${page}`}>{error&&<p className="v6-error" role="alert">{error}</p>}{page==='overview'&&role==='STUDENT'?<StudentOverview user={user} navigate={navigate}/>:page==='overview'?<><section className="admin-welcome"><div><span className="admin-eyebrow">{role==='PRINCIPAL'?'KHÔNG GIAN ĐIỀU HÀNH':'CỔNG THÔNG TIN HỌC VỤ'}</span><h1>Xin chào, {user.name}</h1><p>{ROLE_LABELS[role]} · Chọn chức năng để xem dữ liệu được phân quyền.</p></div><OverviewOrbit center={role==='PRINCIPAL'?'building':'graduation'}/></section><Card title="Chức năng thường dùng"><div className="portal-quick-links">{allowed.slice(0,6).map(key=><button key={key} onClick={()=>navigate(key)}><span>{pageTitle(key,role,resources)}</span><Icon name="arrow" size={16}/></button>)}</div></Card></>:page==='timetable'?<Timetable lookups={lookups}/>:page==='exams'?<ExamSchedule role={role} lookups={lookups} notify={notify}/>:role==='STUDENT'&&['invoices','payments'].includes(page)?<StudentTuition mode={page} lookups={lookups}/>:role==='STUDENT'&&page==='notifications'?<StudentNotifications/>:role==='STUDENT'&&page==='students'?<StudentProfilePage notify={notify}/>:role==='STUDENT'&&['sections','enrollments','grades'].includes(page)?<StudentAcademic key={page} mode={page} notify={notify}/>:current&&allowed.includes(page)?<ResourcePage resource={page} meta={current} user={user} role={role} lookups={lookups} notify={notify} onUpdated={refresh}/>:<p>Chức năng không thuộc quyền truy cập.</p>}</main></div>
      <footer className="app-footer"><span>EduPortal · Dữ liệu thực hành</span><span>{ROLE_LABELS[role]}</span></footer>
    </div>
    {toast&&<div className={`toast toast-${toast.kind}`} role="status"><span>{toast.text}</span><button className="icon-button" aria-label="Đóng" onClick={()=>setToast(null)}><Icon name="x" size={16}/></button></div>}
    {passwordForm&&<Modal title="Đổi mật khẩu" onClose={()=>setPasswordForm(null)}><form onSubmit={async event=>{event.preventDefault();try{await api('/accounts/password',{method:'POST',body:passwordForm});setPasswordForm(null);notify('Đã thay đổi mật khẩu.');}catch(error){notify(error.message,'error');}}}><Fields fields={['current_password','new_password']} value={passwordForm} onChange={setPasswordForm}/><div className="modal-actions"><Button type="submit">Đổi mật khẩu</Button></div></form></Modal>}
  </div>;
}
