import React from 'react';
import { Facts } from './AcademicDetails.jsx';

const templates = {
  ADMISSION_RECEIVED: 'Xác nhận đã tiếp nhận hồ sơ nhập học',
  ADMISSION_STATUS: 'Cập nhật trạng thái hồ sơ nhập học',
  SCHOOL_MAILBOX_READY: 'Thông báo cấp email trường',
};

function preview(email) {
  if (email.body_text?.trim()) return { text: email.body_text, fallback: false };
  const body = {
    ADMISSION_RECEIVED: 'Nhà trường đã tiếp nhận hồ sơ nhập học của bạn. Bạn có thể đăng nhập cổng thông tin để theo dõi trạng thái và các cập nhật tiếp theo.',
    ADMISSION_STATUS: 'Hồ sơ nhập học của bạn vừa được cập nhật. Vui lòng đăng nhập cổng thông tin để xem trạng thái và hướng dẫn tiếp theo.',
    SCHOOL_MAILBOX_READY: 'Hộp thư điện tử do nhà trường cấp đã sẵn sàng. Vui lòng đăng nhập cổng thông tin để xem địa chỉ và hướng dẫn sử dụng.',
  }[email.template_code] || 'Bạn có một cập nhật mới từ nhà trường. Vui lòng đăng nhập cổng thông tin sinh viên để xem thông tin chi tiết.';
  return { text: `Xin chào${email.recipient_name ? ` ${email.recipient_name}` : ''},\n\n${body}\n\nTrân trọng,\nNhà trường`, fallback: true };
}

export default function EmailDetail({ email }) {
  const content = preview(email);
  const isDemo = /\.(test|example)$/i.test(email.recipient_email || '');
  const main = {
    ...email,
    template_name: templates[email.template_code] || email.template_code || 'Email thông báo',
  };
  const relatedFields = ['application_code', 'report_code', 'request_code', 'student_code', 'school_email'].filter(key => main[key] != null && main[key] !== '');
  const technicalFields = ['id', 'event_key', 'template_code', 'admission_application_id', 'semester_report_id', 'student_request_id', 'mailbox_id', 'attempt_count', 'last_error'].filter(key => main[key] != null && main[key] !== '');

  return <div className="email-detail">
    <p className="email-detail-intro">Thông báo được gửi tới email cá nhân trong hồ sơ sinh viên. Email trường là hộp thư riêng được cấp để sử dụng trong học tập.</p>
    {isDemo && <p className="email-detail-notice">Địa chỉ này thuộc dữ liệu minh họa (.test/.example), không nhận được email thật.</p>}
    {email.delivery_status === 'QUEUED' && <p className="email-detail-notice">Email đang nằm trong hàng đợi; chưa có thời điểm gửi thành công.</p>}
    <h3>Thông tin người nhận và gửi</h3>
    <Facts value={main} fields={['recipient_name', 'recipient_email', 'student_code', 'template_name', 'subject', 'delivery_status', 'queued_at', 'sent_at']} />
    {relatedFields.length > 0 && <><h3>Hồ sơ liên quan</h3><Facts value={main} fields={relatedFields} /></>}
    <h3>Nội dung email</h3>
    {content.fallback && <p className="email-detail-caption">Bản ghi chưa lưu nội dung riêng. Đây là nội dung mẫu theo mẫu email sẽ dùng khi gửi.</p>}
    <pre className="email-message-preview">{content.text}</pre>
    <details className="email-detail-technical"><summary>Thông tin kỹ thuật</summary><Facts value={main} fields={technicalFields} /></details>
  </div>;
}
