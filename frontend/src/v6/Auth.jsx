import React,{useEffect,useState} from 'react';
import PublicHeader from '../components/landing/PublicHeader.jsx';
import SiteFooter from '../components/landing/SiteFooter.jsx';
import Icon from '../components/common/Icon.jsx';
import campusPhoto from '../assets/campus.jpg';
import { api } from './api.js';
import Fields from './Forms.jsx';
import Recovery from './Recovery.jsx';
import '../styles/public-site.css';
import '../pages/public/Login.css';
export default function Auth({onBack,onAuthenticated,applicant=false}){
  const [value,setValue]=useState({username:'',password:'',email:'',full_name:''}),[error,setError]=useState(''),[opened,setOpened]=useState(false),[recover,setRecover]=useState(location.hash.startsWith('#reset-password/')),[resetToken,setResetToken]=useState(location.hash.startsWith('#reset-password/')?location.hash.slice(16):null),[busy,setBusy]=useState(false),[lookups,setLookups]=useState({});
  useEffect(()=>{if(applicant)api('/public/admission-options').then(setLookups).catch(error=>setError(error.message));},[applicant]);
  useEffect(()=>{const update=()=>{if(location.hash.startsWith('#reset-password/')){setResetToken(location.hash.slice(16));setRecover(true);}};window.addEventListener('hashchange',update);return()=>window.removeEventListener('hashchange',update);},[]);
  async function submit(event){event.preventDefault();setError('');setBusy(true);try{
    if(applicant&&!opened){await api('/public/admissions',{method:'POST',body:value});setOpened(true);}
    const user=await api('/auth/login',{method:'POST',body:{username:value.username,password:value.password}});
    await onAuthenticated(user);
  }catch(error){setError(error.message);}finally{setBusy(false);}}
  return <div className="public-site login-site"><PublicHeader onBack={onBack}/><main className="login-main v6-login-main"><section className="login-card">{recover?<Recovery token={resetToken} onBack={()=>{history.replaceState(null,'',location.pathname);setResetToken(null);setRecover(false);}}/>:<><span className="section-kicker">EDUPORTAL · CỔNG THÔNG TIN ĐÀO TẠO</span><h1>{applicant?'Nộp hồ sơ nhập học':'Chào mừng trở lại'}</h1><p className="login-intro">{applicant?'Chọn đợt và ngành để bắt đầu hồ sơ. Thông tin truy cập giúp bạn hoàn thiện giấy tờ và theo dõi kết quả. Tài khoản sinh viên chỉ được cấp sau khi hồ sơ được duyệt.':'Đăng nhập bằng tài khoản được nhà trường cấp hoặc thông tin theo dõi hồ sơ.'}</p><form onSubmit={submit}><Fields fields={applicant?['period_id','major_id','full_name','email','username','password']:['username','password']} lookups={lookups} value={value} onChange={setValue}/>{error&&<p className="v6-error" role="alert">{error}</p>}{applicant&&lookups.admission_periods?.length===0&&<p role="status">Hiện chưa có đợt nhận hồ sơ đang mở.</p>}<button className="button-solid login-submit" disabled={busy||(applicant&&!lookups.admission_periods?.length)} type="submit">{busy?'Đang xử lý…':applicant?'Bắt đầu hồ sơ nhập học':'Đăng nhập'} <Icon name="arrow" size={17}/></button></form><p className="v6-muted">{applicant?'Đã có hồ sơ? Quay về trang chủ và chọn đăng nhập để tiếp tục.':'Sinh viên có thể khôi phục mật khẩu qua email trường đã được kích hoạt.'}</p>{!applicant&&<button className="auth-text-button" onClick={()=>setRecover(true)}>Quên mật khẩu?</button>}</>}</section><aside className="login-side"><img className="login-campus-photo" src={campusPhoto} alt="Khuôn viên trường đại học giữa những hàng cây xanh"/><div className="login-visual-content"><div className="login-eduportal-brand"><span className="login-brand-symbol"><Icon name="graduation" size={42}/></span><div><strong>EduPortal<span>.</span></strong><small>CỔNG THÔNG TIN ĐÀO TẠO</small></div></div><div className="login-visual-message"><span className="section-kicker">KẾT NỐI TRI THỨC · KIẾN TẠO TƯƠNG LAI</span><h2>Một điểm đến<br/>cho hành trình học tập.</h2><p>Thông tin học vụ, lịch học và kết quả học tập luôn trong tầm tay.</p><div className="login-side-rule"/><span>ĐỒNG HÀNH CÙNG BẠN MỖI NGÀY</span></div></div></aside></main><SiteFooter/></div>;
}
