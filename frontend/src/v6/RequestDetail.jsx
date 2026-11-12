import React,{useEffect,useState} from 'react';
import { api,display,labels } from './api.js';
export default function RequestDetail({id,notify}){
  const [detail,setDetail]=useState(null),[error,setError]=useState(''),[busy,setBusy]=useState(false);
  async function load(){try{setDetail(await api(`/requests/${id}/detail`));}catch(error){setError(error.message);}}
  useEffect(()=>{load();},[id]);
  if(error)return <p role="alert" className="v6-error">{error}</p>;
  if(!detail)return <p role="status">Đang tải yêu cầu…</p>;
  return <div><p>{detail.request.content}</p><p><b>Phản hồi:</b> {detail.request.response||'Chưa có phản hồi'}</p><h3>Tài liệu đính kèm</h3>{detail.attachments.map(file=><p key={file.id}><a href={`/api/request-attachments/${file.id}/download`}>{file.file_name}</a></p>)}{['PENDING','PROCESSING'].includes(detail.request.status)&&<label className="field"><span>Bổ sung tài liệu · PDF, PNG, JPEG · tối đa 5 MB</span><input type="file" accept=".pdf,.png,.jpg,.jpeg" disabled={busy} onChange={async event=>{const file=event.target.files?.[0];if(!file)return;setBusy(true);try{const body=new FormData();body.append('file',file);await api(`/requests/${id}/attachments`,{method:'POST',body});await load();notify('Đã bổ sung tài liệu.');}catch(error){notify(error.message,'error');}finally{setBusy(false);}}}/></label>}<h3>Lịch sử xử lý</h3>{detail.events.length?detail.events.map(event=><article className="v6-history" key={event.id}><b>{event.full_name}</b><p>{display(event.action)} · {display(event.created_at)}</p><p>{event.note}</p></article>):<p>Yêu cầu đã được tiếp nhận, đang chờ xử lý.</p>}</div>;
}
