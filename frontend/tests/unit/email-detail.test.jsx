import React from 'react';
import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import EmailDetail from '../../src/v6/EmailDetail.jsx';

describe('Email detail', () => {
  it('renders persisted content without substituting a template', () => {
    render(<EmailDetail email={{ recipient_email: 'student@example.org', body_text: 'Nội dung đã lưu', delivery_status: 'SENT' }} />);
    expect(screen.getByText('Nội dung đã lưu')).toBeInTheDocument();
    expect(screen.queryByText(/Bản ghi chưa lưu nội dung riêng/)).not.toBeInTheDocument();
    expect(screen.queryByText(/Email đang nằm trong hàng đợi/)).not.toBeInTheDocument();
  });
  it('shows queued demo mail and the named recipient in the fallback preview', () => {
    render(<EmailDetail email={{ recipient_name: 'Sinh viên A', recipient_email: 'student@example.test', template_code: 'ADMISSION_RECEIVED', delivery_status: 'QUEUED', application_code: 'HS001', attempt_count: 0 }} />);
    expect(screen.getByText(/Xin chào Sinh viên A/)).toHaveTextContent('Nhà trường đã tiếp nhận hồ sơ nhập học');
    expect(screen.getByText(/Địa chỉ này thuộc dữ liệu minh họa/)).toBeInTheDocument();
    expect(screen.getByText(/Email đang nằm trong hàng đợi/)).toBeInTheDocument();
    expect(screen.getByText('Hồ sơ liên quan')).toBeInTheDocument();
    expect(screen.getByText('HS001')).toBeInTheDocument();
  });
  it.each(['ADMISSION_STATUS', 'SCHOOL_MAILBOX_READY', 'UNKNOWN'])( 'renders a fallback for %s', template_code => {
    render(<EmailDetail email={{ template_code, body_text: '   ' }} />);
    expect(screen.getByText(/Xin chào,/)).toBeInTheDocument();
    expect(screen.getByText(/Bản ghi chưa lưu nội dung riêng/)).toBeInTheDocument();
    expect(screen.queryByText('Hồ sơ liên quan')).not.toBeInTheDocument();
  });
});
