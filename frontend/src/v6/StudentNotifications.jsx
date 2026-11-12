import React, { useEffect, useState } from 'react';
import { api, display } from './api.js';
import { Card, Empty, Modal, PageHeader } from '../components/ui.jsx';

export default function StudentNotifications() {
  const [rows, setRows] = useState([]), [error, setError] = useState(''), [detail, setDetail] = useState(null);
  const [page, setPage] = useState(1), [total, setTotal] = useState(0), [loaded, setLoaded] = useState(false);
  useEffect(() => {
    const controller = new AbortController();
    setLoaded(false);
    api(`/resources/notifications?page=${page}&size=10`, {signal:controller.signal}).then(result => { setRows(result.items); setTotal(result.total); setError(''); setLoaded(true); }).catch(error => { if (error.name !== 'AbortError') { setError(error.message); setLoaded(true); } });
    return () => controller.abort();
  }, [page]);
  async function read(row) {
    setDetail(row);
    try { await api(`/notifications/${row.id}/read`, {method:'POST',body:{}}); }
    catch (error) { setError(error.message); }
  }
  return <div data-notifications-page={loaded ? "ready" : "loading"}><PageHeader title="Thông báo" description="Thông tin học vụ nhà trường gửi đến bạn."/>{error && <p className="v6-error" role="alert">{error}</p>}<Card>{!loaded&&<p role="status">Đang tải thông báo…</p>}<div className="student-notice-list">{rows.map(row => <button key={row.id} onClick={() => read(row)}><span><strong>{row.title}</strong><small>{display(row.created_at,'created_at')}</small></span><span>Đọc →</span></button>)}</div>{loaded && !rows.length && !error && <Empty title="Chưa có thông báo"/>}{total>10&&<nav className="pagination"><span>Trang {page}/{Math.ceil(total/10)}</span><div className="pagination-controls"><button disabled={page===1} onClick={()=>setPage(page-1)}>Trang trước</button><button disabled={page*10>=total} onClick={()=>setPage(page+1)}>Trang sau</button></div></nav>}</Card>
    {detail && <Modal title={detail.title} onClose={() => setDetail(null)}><p className="v6-muted">{display(detail.created_at,'created_at')}</p><div className="notice-reading-body">{detail.body}</div></Modal>}
  </div>;
}
