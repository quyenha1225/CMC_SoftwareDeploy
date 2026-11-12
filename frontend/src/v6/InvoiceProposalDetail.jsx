import React, { useEffect, useState } from 'react';
import { api, display } from './api.js';
import { Facts } from './AcademicDetails.jsx';

const actionLabels = {
  SAVE: 'Lập / cập nhật đề nghị',
  SUBMIT: 'Trình Ban giám hiệu',
  APPROVE: 'Phê duyệt',
  RETURN: 'Trả lại để bổ sung',
  REJECT: 'Từ chối',
  ISSUE: 'Phát hành hóa đơn',
};

export default function InvoiceProposalDetail({ id }) {
  const [data, setData] = useState(null);
  const [error, setError] = useState('');

  useEffect(() => {
    const controller = new AbortController();
    api(`/invoice-proposals/${id}`, { signal: controller.signal })
      .then(setData)
      .catch(error => error.name !== 'AbortError' && setError(error.message));
    return () => controller.abort();
  }, [id]);

  if (error) return <p className="v6-error" role="alert">{error}</p>;
  if (!data) return <p role="status">Đang tải đề nghị…</p>;

  return (
    <>
      <Facts
        value={data}
        fields={[
          'student_code', 'full_name', 'academic_year', 'semester_code',
          'prepared_name', 'submitted_at', 'status', 'gross_amount',
          'discount_amount', 'payable_amount', 'decision_note', 'note',
        ]}
      />
      <h3>Học phần và đơn giá đề nghị</h3>
      <div className="table-wrap">
        <table className="data-table">
          <thead>
            <tr><th>Học phần</th><th>Tín chỉ</th><th>Đơn giá</th><th>Thành tiền</th></tr>
          </thead>
          <tbody>
            {data.items.map(row => (
              <tr key={row.id}>
                <td>{row.title}<small className="academic-sub">{row.section_code}</small></td>
                <td>{row.credits_at_proposal}</td>
                <td>{display(row.unit_price_at_proposal, 'price')}</td>
                <td>{display(row.amount, 'amount')}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <h3>Lịch sử trình và xét duyệt</h3>
      <div className="student-notice-list">
        {data.reviews.map(row => (
          <div className="proposal-history-row" key={row.id}>
            <strong>{row.actor_name}</strong>
            <span>{actionLabels[row.action] || row.action} · {display(row.created_at, 'created_at')}</span>
            <p>{row.note || display(row.to_status)}</p>
          </div>
        ))}
      </div>
    </>
  );
}
