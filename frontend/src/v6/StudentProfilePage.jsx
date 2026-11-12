import React, { useEffect, useState } from 'react';
import { api } from './api.js';
import { Card, PageHeader } from '../components/ui.jsx';
import StudentProfile from './StudentProfile.jsx';

export default function StudentProfilePage({ notify }) {
  const [profile, setProfile] = useState(null), [error, setError] = useState('');
  useEffect(() => {
    const controller = new AbortController();
    api('/student/profile', {signal:controller.signal}).then(setProfile).catch(error => error.name !== 'AbortError' && setError(error.message));
    return () => controller.abort();
  }, []);
  return <div className="student-profile-page" data-profile-page>
    <PageHeader title="Hồ sơ cá nhân" description="Thông tin cá nhân, liên hệ và email trường được lưu tại đây."/>
    {error && <p className="v6-error" role="alert">{error}</p>}
    {profile ? <Card><StudentProfile student={profile} role="STUDENT" notify={notify}/></Card> : !error && <p role="status">Đang tải hồ sơ…</p>}
  </div>;
}
