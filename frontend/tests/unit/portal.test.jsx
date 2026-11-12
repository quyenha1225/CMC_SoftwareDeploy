import React from 'react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import Auth from '../../src/v6/Auth.jsx';
import Fields from '../../src/v6/Forms.jsx';
import PortalNavigation from '../../src/v6/PortalNavigation.jsx';
import StudentTuition from '../../src/v6/StudentTuition.jsx';
import { api } from '../../src/v6/api.js';
vi.mock('../../src/v6/api.js', async importOriginal => ({ ...await importOriginal(), api: vi.fn() }));
vi.mock('../../src/components/landing/PublicHeader.jsx', () => ({ default: () => <header>EduPortal</header> }));
vi.mock('../../src/components/landing/SiteFooter.jsx', () => ({ default: () => <footer/> }));
beforeEach(() => { vi.clearAllMocks(); window.location.hash=''; });

describe('Login and applicant forms', () => {
  it('sends credentials and uses the authenticated server account', async () => {
    const account={id:7,roles:['STUDENT']}; api.mockResolvedValue(account);
    const authenticated=vi.fn();render(<Auth onBack={vi.fn()} onAuthenticated={authenticated}/>);
    fireEvent.change(screen.getByLabelText('Tên đăng nhập'), {target:{value:'student'}});
    fireEvent.change(screen.getByLabelText('Mật khẩu (từ 12 ký tự)'), {target:{value:'ExamplePassword!'}});
    fireEvent.submit(screen.getByRole('button',{name:/Đăng nhập/}).closest('form'));
    await waitFor(() => expect(authenticated).toHaveBeenCalledWith(account));
    expect(api).toHaveBeenCalledWith('/auth/login', expect.objectContaining({body:{username:'student',password:'ExamplePassword!'}}));
  });
  it('does not allow opening an admission when there is no active period', async () => {
    api.mockResolvedValue({admission_periods:[],majors:[]});
    render(<Auth applicant onBack={vi.fn()} onAuthenticated={vi.fn()}/>);
    expect(await screen.findByText('Hiện chưa có đợt nhận hồ sơ đang mở.')).toBeInTheDocument();
    expect(screen.getByRole('button',{name:/Bắt đầu hồ sơ nhập học/})).toBeDisabled();
  });
  it('makes configured required fields mandatory and preserves optional fields', () => {
    render(<Fields fields={['full_name','email','phone']} optional={['phone']} value={{}} onChange={vi.fn()}/>);
    expect(screen.getByLabelText('Họ tên')).toBeRequired();
    expect(screen.getByLabelText('Email')).toHaveAttribute('type','email');
    expect(screen.getByLabelText('Điện thoại')).not.toBeRequired();
  });
});

it('renders only the server-permitted navigation and expands the timetable group', () => {
  const navigate=vi.fn();render(<PortalNavigation allowed={['students','timetable','exams']} page="overview" role="STUDENT" resources={[]} navigate={navigate}/>);
  expect(screen.queryByRole('button',{name:'Tài khoản'})).not.toBeInTheDocument();
  const toggle=screen.getByRole('button',{name:'Thời khóa biểu'});
  expect(toggle).toHaveAttribute('aria-expanded','false');fireEvent.click(toggle);
  expect(toggle).toHaveAttribute('aria-expanded','true');
  fireEvent.click(screen.getByRole('button',{name:'Lịch thi'}));expect(navigate).toHaveBeenCalledWith('exams');
});

it('shows invoice balances from the API without creating a payment action', async () => {
  api.mockImplementation(path => Promise.resolve(path.includes('/invoices') ? {items:[{invoice_id:1,semester_id:1,payable_amount:2700000,paid_amount:900000,remaining_amount:1800000,payment_status:'PARTIAL'}],total:1} : {items:[],total:0}));
  render(<StudentTuition mode="invoices" lookups={{semesters:[{id:1,code:'HK2',academic_year_id:1}],academic_years:[{id:1,name:'2026-2027'}]}}/>);
  await screen.findByText('Nộp một phần');
  expect(screen.getAllByText('Còn phải nộp')).toHaveLength(2);
  expect(screen.queryByRole('button',{name:/Xác nhận nộp|Tự ghi nhận/})).not.toBeInTheDocument();
  expect(api).toHaveBeenCalledWith('/resources/invoices?page=1&size=50', expect.any(Object));
});
