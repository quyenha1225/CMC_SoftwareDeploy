import React, { useEffect, useState } from 'react';
import Icon from '../components/common/Icon.jsx';

export default function WelcomeAnimation({ children }) {
  const [visible, setVisible] = useState(() => !sessionStorage.getItem('eduportal-welcomed'));
  useEffect(() => {
    if (!visible) return;
    const timer = setTimeout(() => { sessionStorage.setItem('eduportal-welcomed', '1'); setVisible(false); }, matchMedia('(prefers-reduced-motion: reduce)').matches ? 100 : 1400);
    return () => clearTimeout(timer);
  }, [visible]);
  return <>{children}{visible && <div className="edu-welcome" role="status" aria-label="Chào mừng đến EduPortal"><div className="edu-welcome-orbit" /><span className="edu-welcome-logo"><Icon name="graduation" size={56} /></span><strong>EduPortal<span>.</span></strong><p>Kết nối tri thức · Kiến tạo tương lai</p><div className="edu-welcome-progress"><i /></div></div>}</>;
}
