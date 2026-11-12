# Kiểm tra toàn bộ dữ liệu V6

Thời điểm: 2026-11-12T12:13:31. Database: `sms_v6_original`.

Phạm vi: 56 bảng, 18 view, 1017 kiểm tra dữ liệu SQL/tệp hồ sơ và 15 tài khoản. Không thay đổi bản ghi nghiệp vụ.

Lỗi dữ liệu: **0**. Cảnh báo dữ liệu: **3**. Tài khoản có lỗi kiểm tra API: **0**.

## Lỗi và cảnh báo

- WARNING: `PAYMENT_WITHOUT_FUND` — 3 bản ghi. Chứng từ cũ chưa gắn quỹ; không tự suy đoán quỹ hoặc sửa số tiền.
- WARNING: `MISSING_PRIVATE_FILE admission_documents` — 10 bản ghi. Có metadata seed nhưng chưa có tệp hợp lệ trong kho riêng; không tạo giấy tờ thay thế.
- WARNING: `STUDENT_WITHOUT_UPLOADED_PHOTO` — 6 bản ghi. Chưa tải ảnh hồ sơ; giao diện dùng ảnh đại diện chữ cái. Không phải lỗi khóa/SQL.

## Kiểm kê bảng và view

| Bảng / view | Loại | Số bản ghi |
|---|---|---:|
| academic_classes | BASE TABLE | 3 |
| academic_years | BASE TABLE | 2 |
| admission_applications | BASE TABLE | 2 |
| admission_document_requirements | BASE TABLE | 7 |
| admission_documents | BASE TABLE | 10 |
| admission_high_school_records | BASE TABLE | 2 |
| admission_high_school_scores | BASE TABLE | 9 |
| admission_identity_records | BASE TABLE | 2 |
| admission_periods | BASE TABLE | 1 |
| admission_review_events | BASE TABLE | 5 |
| audit_logs | BASE TABLE | 108 |
| cohorts | BASE TABLE | 2 |
| course_sections | BASE TABLE | 5 |
| courses | BASE TABLE | 8 |
| ctsv_funds | BASE TABLE | 2 |
| ctsv_remittance_allocations | BASE TABLE | 2 |
| ctsv_remittances | BASE TABLE | 2 |
| ctsv_semester_report_reviews | BASE TABLE | 1 |
| ctsv_semester_reports | BASE TABLE | 2 |
| curricula | BASE TABLE | 3 |
| curriculum_courses | BASE TABLE | 13 |
| email_delivery_attempts | BASE TABLE | 0 |
| enrollments | BASE TABLE | 15 |
| exam_schedules | BASE TABLE | 5 |
| exam_types | BASE TABLE | 2 |
| faculties | BASE TABLE | 2 |
| grade_reviews | BASE TABLE | 7 |
| grade_sheets | BASE TABLE | 5 |
| grades | BASE TABLE | 15 |
| invoice_items | BASE TABLE | 13 |
| invoice_proposal_items | BASE TABLE | 2 |
| invoice_proposal_reviews | BASE TABLE | 3 |
| invoice_proposals | BASE TABLE | 2 |
| invoices | BASE TABLE | 8 |
| lecturers | BASE TABLE | 3 |
| majors | BASE TABLE | 3 |
| notification_recipients | BASE TABLE | 10 |
| notifications | BASE TABLE | 2 |
| outbound_emails | BASE TABLE | 1 |
| password_reset_tokens | BASE TABLE | 0 |
| payments | BASE TABLE | 4 |
| roles | BASE TABLE | 6 |
| rooms | BASE TABLE | 5 |
| schema_migrations | BASE TABLE | 10 |
| section_schedules | BASE TABLE | 5 |
| semesters | BASE TABLE | 3 |
| student_profile_photos | BASE TABLE | 0 |
| student_request_attachments | BASE TABLE | 0 |
| student_request_review_events | BASE TABLE | 0 |
| student_requests | BASE TABLE | 2 |
| student_school_mailboxes | BASE TABLE | 6 |
| students | BASE TABLE | 6 |
| tuition_adjustments | BASE TABLE | 2 |
| tuition_rates | BASE TABLE | 2 |
| user_roles | BASE TABLE | 15 |
| users | BASE TABLE | 15 |
| v_admission_document_checklist | VIEW | 14 |
| v_admission_dossier_progress | VIEW | 2 |
| v_approval_workflow_checks | VIEW | 6 |
| v_ctsv_fund_balances | VIEW | 2 |
| v_ctsv_remittance_tracking | VIEW | 2 |
| v_ctsv_semester_finance | VIEW | 3 |
| v_email_delivery_history | VIEW | 1 |
| v_grade_entry_roster | VIEW | 15 |
| v_invoice_balances | VIEW | 8 |
| v_normalization_checks | VIEW | 10 |
| v_school_admission_decisions | VIEW | 1 |
| v_school_admission_queue | VIEW | 1 |
| v_school_ctsv_report_register | VIEW | 2 |
| v_school_tuition_by_semester | VIEW | 3 |
| v_school_tuition_total | VIEW | 1 |
| v_section_registration_counts | VIEW | 5 |
| v_student_results | VIEW | 4 |
| v_student_timetable | VIEW | 15 |

## Kiểm tra API theo tài khoản

| Tài khoản | Vai trò | Kết quả | Số kiểm tra |
|---|---|---|---:|
| principal_demo | PRINCIPAL | Đạt | 77 |
| training_demo | TRAINING_OFFICE | Đạt | 54 |
| lecturer_demo_01 | LECTURER | Đạt | 31 |
| lecturer_demo_02 | LECTURER | Đạt | 31 |
| lecturer_demo_03 | LECTURER | Đạt | 29 |
| student_demo_001 | STUDENT | Đạt | 39 |
| student_demo_002 | STUDENT | Đạt | 38 |
| student_demo_003 | STUDENT | Đạt | 38 |
| student_demo_004 | STUDENT | Đạt | 37 |
| student_demo_005 | STUDENT | Đạt | 37 |
| student_demo_006 | STUDENT | Đạt | 37 |
| ctsv_demo | CTSV | Đạt | 52 |
| applicant_demo_03 | APPLICANT | Đạt | 28 |
| applicant_demo_04 | APPLICANT | Đạt | 28 |
| principal | PRINCIPAL | Đạt | 77 |

## Chạy lại kiểm tra

```powershell
python backend/scripts/Validate-AllData.py
```

Script đọc kết nối từ `backend/.env.local` và tài khoản riêng trong `backend/.local/`; không ghi mật khẩu vào báo cáo. Dùng `--skip-api` nếu chỉ cần quét SQL/tệp hồ sơ. JSON chi tiết ở `backend/.local/validation/all-data-validation.json`.

## Cách xử lý dữ liệu còn thiếu

- Chứng từ chưa gắn quỹ: đối chiếu sổ thu để xác định quỹ chính xác; không suy đoán từ số tiền.
- Giấy tờ seed: tải lên các tệp tương ứng qua hồ sơ; không tạo giấy tờ cá nhân giả để làm đủ tệp.
- Ảnh hồ sơ: tải ảnh JPEG/PNG trong hồ sơ sinh viên; đây là trường tùy chọn.

## Giới hạn

Trường NULL hoặc bảng rỗng có thể hợp lệ theo trạng thái nghiệp vụ. Ảnh/hồ sơ tải lên, email thực tế và dữ liệu chính thức của trường cần đối chiếu nguồn; không tự tạo chứng từ hoặc thông tin cá nhân để làm đầy dữ liệu. Báo cáo JSON riêng chứa kết quả từng phép kiểm tra, không chứa mật khẩu/token.
