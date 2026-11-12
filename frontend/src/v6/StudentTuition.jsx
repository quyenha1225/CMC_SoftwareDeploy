import React, { useEffect, useState } from 'react';
import { api, display } from './api.js';
import { Button, Card, Empty, Modal, PageHeader } from '../components/ui.jsx';

async function allRows(resource, signal) {
  const result = [];
  for (let page = 1; ; page++) {
    const response = await api(`/resources/${resource}?page=${page}&size=50`, {signal});
    result.push(...response.items);
    if (result.length >= response.total || !response.items.length) return result;
  }
}

export default function StudentTuition({ mode, lookups }) {
  const [data, setData] = useState(null), [error, setError] = useState(''), [semester, setSemester] = useState('');
  const [detail, setDetail] = useState(null), [busy, setBusy] = useState(false);
  useEffect(() => {
    const controller = new AbortController();
    Promise.all([allRows('invoices',controller.signal),allRows('payments',controller.signal)]).then(([invoices,payments]) => setData({invoices,payments})).catch(error => error.name !== 'AbortError' && setError(error.message));
    return () => controller.abort();
  }, []);
  const history = mode === 'payments';
  const term = id => {
    const item = lookups.semesters?.find(item => Number(item.id) === Number(id));
    const year = lookups.academic_years?.find(year => Number(year.id) === Number(item?.academic_year_id));
    return item ? `${item.code} · ${year?.name || ''}` : 'Chưa có thông tin học kỳ';
  };
  const invoices = data?.invoices.filter(row => !semester || String(row.semester_id) === semester) || [];
  const payments = data?.payments.filter(row => !semester || String(row.semester_id) === semester) || [];
  async function openInvoice(invoice) {
    setBusy(true);
    try {
      const items = await api(`/invoices/${invoice.invoice_id}/items`);
      setDetail({invoice,items});
    } catch (error) { setError(error.message); }
    finally { setBusy(false); }
  }
  return <div data-tuition-page>
    <PageHeader title={history ? 'Lịch sử thanh toán' : 'Công nợ & hóa đơn'} description={history ? 'Các khoản nhà trường đã ghi nhận, kèm ngày thu và mã chứng từ.' : 'Số tiền lấy từ hóa đơn đã phát hành và các khoản thu đã ghi nhận.'}/>
    {error && <p className="v6-error" role="alert">{error}</p>}
    {data && !history && <div className="overview-summary tuition-summary">{[['payable_amount','Phải nộp'],['paid_amount','Đã nộp'],['remaining_amount','Còn phải nộp']].map(([field,label]) => <div key={field}><span>{label}</span><strong>{display(invoices.reduce((sum,row) => sum+Number(row[field] || 0),0),'amount')}</strong></div>)}</div>}
    <Card><label className="compact-filter">Học kỳ<select className="control" value={semester} onChange={event => setSemester(event.target.value)}><option value="">Tất cả học kỳ</option>{(lookups.semesters || []).map(item => <option key={item.id} value={item.id}>{term(item.id)}</option>)}</select></label>
      {!data ? <p role="status">Đang tải thông tin học phí…</p> : <div className="table-wrap"><table className="data-table"><thead><tr>{(history ? ['Ngày thu','Số tiền','Mã chứng từ','Học kỳ',''] : ['Học kỳ','Phải nộp','Đã nộp','Còn phải nộp','Trạng thái','']).map((title,index) => <th key={index}>{title}</th>)}</tr></thead><tbody>{(history ? payments : invoices).map(row => history ? <tr key={row.id}><td>{display(row.paid_at,'paid_at')}</td><td>{display(row.amount,'amount')}</td><td>{row.reference_no}</td><td>{term(row.semester_id)}</td><td><Button small kind="outline" onClick={() => setDetail({payment:row})}>Chi tiết</Button></td></tr> : <tr key={row.invoice_id}><td>{term(row.semester_id)}</td>{['payable_amount','paid_amount','remaining_amount'].map(field => <td key={field}>{display(row[field],field)}</td>)}<td>{display(row.payment_status)}</td><td><Button small kind="outline" disabled={busy} onClick={() => openInvoice(row)}>Chi tiết</Button></td></tr>)}</tbody></table></div>}
      {data && !(history ? payments : invoices).length && <Empty title={history ? 'Chưa có khoản thanh toán được ghi nhận' : 'Chưa có hóa đơn trong học kỳ này'}/>}
    </Card>
    {detail && <Modal title={detail.payment ? 'Chi tiết khoản thanh toán' : `Học phí ${term(detail.invoice.semester_id)}`} wide onClose={() => setDetail(null)}>
      {detail.payment ? <dl className="readable-facts"><div><dt>Ngày thu</dt><dd>{display(detail.payment.paid_at,'paid_at')}</dd></div><div><dt>Số tiền</dt><dd>{display(detail.payment.amount,'amount')}</dd></div><div><dt>Mã chứng từ</dt><dd>{detail.payment.reference_no}</dd></div><div><dt>Học kỳ</dt><dd>{term(detail.payment.semester_id)}</dd></div>{detail.payment.note && <div><dt>Ghi chú</dt><dd>{detail.payment.note}</dd></div>}</dl> : <>
        <div className="table-wrap"><table className="data-table"><thead><tr><th>Học phần</th><th>Tín chỉ</th><th>Đơn giá khi phát hành</th><th>Thành tiền</th></tr></thead><tbody>{detail.items.map(item => <tr key={item.id}><td>{item.title}<small className="academic-sub">{item.section_code}</small></td><td>{item.credits_at_issue}</td><td>{display(item.unit_price_at_issue,'price')}</td><td>{display(item.amount,'amount')}</td></tr>)}</tbody></table></div>
        <dl className="readable-facts"><div><dt>Phải nộp trên hóa đơn</dt><dd>{display(detail.invoice.payable_amount,'amount')}</dd></div><div><dt>Đã ghi nhận nộp</dt><dd>{display(detail.invoice.paid_amount,'amount')}</dd></div><div><dt>Còn phải nộp</dt><dd>{display(detail.invoice.remaining_amount,'amount')}</dd></div></dl>
        <p className="v6-muted">Đơn giá và tín chỉ được giữ theo thời điểm phát hành hóa đơn. Nếu thông tin chưa đúng, gửi yêu cầu để nhà trường đối soát.</p>
      </>}
    </Modal>}
  </div>;
}
