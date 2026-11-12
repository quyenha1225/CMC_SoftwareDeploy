# Danh mục cột và liên kết schema chuẩn hóa

Ngày xuất: 12/11/2026. Nguồn: metadata schema nền 05–10 và phần bổ sung 13–14 ở cuối tài liệu; không xuất dữ liệu cá nhân hoặc thông tin đăng nhập.

56 bảng hiện tại (53 bảng nền và 3 bảng đề nghị học phí); PK = khóa chính, UNI = unique, MUL = cột có chỉ mục (không thay thế danh sách chỉ mục ghép). Cột tương thích phòng/loại thi được đồng bộ bởi trigger. Xem [luồng và giới hạn chuẩn hóa](CHUAN_HOA_SQL_2026_11_12.md).


## academic_classes

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| major_id | bigint | NO | — | MUL | majors.id |
| cohort_id | bigint | NO | — | MUL | cohorts.id |
| code | varchar(50) | NO | — | UNI | — |
| name | varchar(180) | NO | — | — | — |

## academic_years

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| name | varchar(30) | NO | — | UNI | — |
| starts_on | date | NO | — | — | — |
| ends_on | date | NO | — | — | — |

## admission_applications

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| application_code | varchar(60) | NO | — | UNI | — |
| applicant_user_id | bigint | NO | — | MUL | users.id |
| period_id | bigint | NO | — | MUL | admission_periods.id |
| major_id | bigint | NO | — | MUL | majors.id |
| phone | varchar(24) | YES | — | — | — |
| address | varchar(400) | YES | — | — | — |
| date_of_birth | date | YES | — | — | — |
| status | enum('DRAFT','SUBMITTED','IN_REVIEW','CHANGES_REQUESTED','CTSV_APPROVED','CTSV_REJECTED','SENT_TO_SCHOOL','SCHOOL_APPROVED','SCHOOL_REJECTED','PDT_VERIFIED','ENROLLED') | NO | DRAFT | — | — |
| assigned_ctsv_user_id | bigint | YES | — | MUL | users.id |
| student_id | bigint | YES | — | UNI | students.id |
| submitted_at | datetime | YES | — | — | — |
| changed_at | datetime | NO | CURRENT_TIMESTAMP | — | — |
| legal_full_name | varchar(160) | YES | — | — | — |
| personal_email | varchar(190) | YES | — | — | — |
| gender | enum('MALE','FEMALE','OTHER','UNDISCLOSED') | YES | — | — | — |
| place_of_birth | varchar(200) | YES | — | — | — |
| hometown | varchar(250) | YES | — | — | — |
| permanent_address | varchar(500) | YES | — | — | — |
| current_address | varchar(500) | YES | — | — | — |
| nationality | varchar(100) | YES | — | — | — |
| guardian_full_name | varchar(160) | YES | — | — | — |
| guardian_phone | varchar(24) | YES | — | — | — |

## admission_document_requirements

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| period_id | bigint | NO | — | PRI | admission_periods.id |
| document_type | varchar(50) | NO | — | PRI | — |
| label | varchar(160) | NO | — | — | — |
| is_required | tinyint(1) | NO | 1 | — | — |

## admission_documents

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| application_id | bigint | NO | — | MUL | admission_applications.id |
| document_type | varchar(50) | NO | — | — | — |
| revision_no | smallint | NO | 1 | — | — |
| file_name | varchar(255) | NO | — | — | — |
| storage_key | varchar(400) | NO | — | UNI | — |
| mime_type | varchar(100) | NO | — | — | — |
| size_bytes | bigint | NO | — | — | — |
| sha256 | char(64) | YES | — | — | — |
| status | enum('PENDING','VERIFIED','REJECTED') | NO | PENDING | — | — |
| checked_by | bigint | YES | — | MUL | users.id |
| checked_at | datetime | YES | — | — | — |
| rejection_reason | varchar(500) | YES | — | — | — |
| uploaded_at | datetime | NO | CURRENT_TIMESTAMP | — | — |

## admission_high_school_records

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| application_id | bigint | NO | — | UNI | admission_applications.id |
| school_name | varchar(200) | NO | — | — | — |
| school_province | varchar(160) | YES | — | — | — |
| graduation_year | smallint | YES | — | — | — |
| graduation_status | enum('PENDING','GRADUATED','NOT_GRADUATED') | NO | PENDING | — | — |
| transcript_average | decimal(4,2) | YES | — | — | — |

## admission_high_school_scores

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| school_record_id | bigint | NO | — | MUL | admission_high_school_records.id |
| grade_level | tinyint | NO | — | — | — |
| subject_code | varchar(40) | NO | — | — | — |
| average_score | decimal(4,2) | NO | — | — | — |

## admission_identity_records

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| application_id | bigint | NO | — | UNI | admission_applications.id |
| identity_type | enum('CCCD','CMND','PASSPORT','OTHER') | NO | CCCD | — | — |
| identity_last4 | char(4) | YES | — | — | — |
| identity_number_encrypted | varbinary(512) | YES | — | — | — |
| identity_number_hmac | char(64) | YES | — | MUL | — |
| issued_on | date | YES | — | — | — |
| expires_on | date | YES | — | — | — |
| issued_by | varchar(200) | YES | — | — | — |
| verified_at | datetime | YES | — | — | — |
| verified_by | bigint | YES | — | MUL | users.id |

## admission_periods

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| code | varchar(50) | NO | — | UNI | — |
| title | varchar(180) | NO | — | — | — |
| cohort_id | bigint | NO | — | MUL | cohorts.id |
| opens_at | datetime | NO | — | — | — |
| closes_at | datetime | NO | — | — | — |
| status | enum('PLANNED','OPEN','CLOSED') | NO | PLANNED | — | — |

## admission_review_events

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| application_id | bigint | NO | — | MUL | admission_applications.id |
| actor_user_id | bigint | NO | — | MUL | users.id |
| event_type | enum('SUBMIT','START_REVIEW','REQUEST_CHANGES','APPROVE','REJECT','SUBMIT_TO_SCHOOL','SCHOOL_APPROVE','SCHOOL_REJECT','PDT_VERIFY','ENROLL') | NO | — | — | — |
| from_status | varchar(30) | NO | — | — | — |
| to_status | varchar(30) | NO | — | — | — |
| note | varchar(700) | YES | — | — | — |
| event_key | varchar(100) | YES | — | UNI | — |
| created_at | datetime | NO | CURRENT_TIMESTAMP | — | — |

## audit_logs

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| actor_user_id | bigint | YES | — | MUL | users.id |
| action | varchar(100) | NO | — | — | — |
| entity_type | varchar(80) | NO | — | MUL | — |
| entity_id | varchar(80) | YES | — | — | — |
| detail_json | json | YES | — | — | — |
| event_key | varchar(100) | YES | — | UNI | — |
| created_at | datetime | NO | CURRENT_TIMESTAMP | — | — |

## cohorts

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| code | varchar(30) | NO | — | UNI | — |
| start_year | smallint | NO | — | — | — |
| end_year | smallint | YES | — | — | — |

## course_sections

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| semester_id | bigint | NO | — | MUL | semesters.id |
| course_id | bigint | NO | — | MUL | courses.id |
| lecturer_id | bigint | YES | — | MUL | lecturers.id |
| section_code | varchar(40) | NO | — | — | — |
| capacity | int | NO | — | — | — |
| attendance_weight | decimal(5,2) | NO | 10.00 | — | — |
| midterm_weight | decimal(5,2) | NO | 30.00 | — | — |
| final_weight | decimal(5,2) | NO | 60.00 | — | — |
| is_open | tinyint(1) | NO | 1 | — | — |

## courses

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| course_code | varchar(40) | NO | — | UNI | — |
| title | varchar(200) | NO | — | — | — |
| credits | smallint | NO | — | — | — |
| active | tinyint(1) | NO | 1 | — | — |

## ctsv_funds

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| code | varchar(50) | NO | — | UNI | — |
| name | varchar(180) | NO | — | — | — |
| channel | enum('CASH','BANK_TRANSFER') | NO | — | — | — |
| active | tinyint(1) | NO | 1 | — | — |

## ctsv_remittance_allocations

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| remittance_id | bigint | NO | — | PRI | ctsv_remittances.id |
| payment_id | bigint | NO | — | PRI | payments.id |
| allocated_amount | decimal(14,2) | NO | — | — | — |

## ctsv_remittances

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| remittance_code | varchar(70) | NO | — | UNI | — |
| semester_id | bigint | NO | — | MUL | semesters.id |
| fund_id | bigint | NO | — | MUL | ctsv_funds.id |
| amount | decimal(14,2) | NO | — | — | — |
| status | enum('DRAFT','SUBMITTED','CONFIRMED','REJECTED') | NO | DRAFT | — | — |
| prepared_by | bigint | NO | — | MUL | users.id |
| reviewed_by | bigint | YES | — | MUL | users.id |
| remitted_at | datetime | YES | — | — | — |
| reviewed_at | datetime | YES | — | — | — |
| external_reference | varchar(120) | YES | — | UNI | — |
| note | varchar(700) | YES | — | — | — |

## ctsv_semester_report_reviews

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| report_id | bigint | NO | — | MUL | ctsv_semester_reports.id |
| actor_user_id | bigint | NO | — | MUL | users.id |
| action | enum('SUBMIT','RETURN','APPROVE') | NO | — | — | — |
| note | varchar(700) | YES | — | — | — |
| event_key | varchar(120) | YES | — | UNI | — |
| created_at | datetime | NO | CURRENT_TIMESTAMP | — | — |

## ctsv_semester_reports

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| report_code | varchar(70) | NO | — | UNI | — |
| semester_id | bigint | NO | — | UNI | semesters.id |
| prepared_by | bigint | NO | — | MUL | users.id |
| status | enum('DRAFT','SUBMITTED','RETURNED','APPROVED') | NO | DRAFT | — | — |
| received_by | bigint | YES | — | MUL | users.id |
| submitted_at | datetime | YES | — | — | — |
| reviewed_at | datetime | YES | — | — | — |
| note | varchar(700) | YES | — | — | — |

## curricula

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| major_id | bigint | NO | — | MUL | majors.id |
| cohort_id | bigint | NO | — | MUL | cohorts.id |
| title | varchar(180) | NO | — | — | — |

## curriculum_courses

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| curriculum_id | bigint | NO | — | PRI | curricula.id |
| course_id | bigint | NO | — | PRI | courses.id |
| suggested_semester | smallint | YES | — | — | — |
| required_course | tinyint(1) | NO | 1 | — | — |

## email_delivery_attempts

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| outbound_email_id | bigint | NO | — | MUL | outbound_emails.id |
| attempt_no | int | NO | — | — | — |
| result | enum('SENT','FAILED') | NO | — | — | — |
| provider_message_id | varchar(190) | YES | — | UNI | — |
| error_code | varchar(80) | YES | — | — | — |
| error_message | varchar(500) | YES | — | — | — |
| attempted_at | datetime | NO | CURRENT_TIMESTAMP | — | — |

## enrollments

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| student_id | bigint | NO | — | MUL | students.id |
| section_id | bigint | NO | — | MUL | course_sections.id |
| status | enum('REGISTERED','CANCELLED','COMPLETED') | NO | REGISTERED | — | — |
| registered_at | datetime | NO | CURRENT_TIMESTAMP | — | — |

## exam_schedules

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| section_id | bigint | NO | — | MUL | course_sections.id |
| starts_at | datetime | NO | — | MUL | — |
| ends_at | datetime | NO | — | — | — |
| room | varchar(80) | NO | — | — | — |
| exam_type | varchar(80) | NO | — | — | — |
| status | varchar(20) | NO | DRAFT | — | — |
| note | varchar(1000) | YES | — | — | — |
| room_id | bigint | YES | — | MUL | rooms.id |
| exam_type_id | bigint | YES | — | MUL | exam_types.id |
| data_origin | varchar(16) | NO | SCHOOL | — | — |
| created_at | datetime | NO | CURRENT_TIMESTAMP | — | — |
| updated_at | datetime | NO | CURRENT_TIMESTAMP | — | — |

## exam_types

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| code | varchar(40) | NO | — | UNI | — |
| name | varchar(80) | NO | — | UNI | — |
| active | tinyint(1) | NO | 1 | — | — |

## faculties

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| code | varchar(30) | NO | — | UNI | — |
| name | varchar(180) | NO | — | — | — |

## grade_reviews

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| sheet_id | bigint | NO | — | MUL | grade_sheets.id |
| actor_user_id | bigint | NO | — | MUL | users.id |
| action | enum('SUBMIT','VERIFY','RETURN','APPROVE','PUBLISH') | NO | — | — | — |
| note | varchar(700) | YES | — | — | — |
| created_at | datetime | NO | CURRENT_TIMESTAMP | — | — |
| event_key | varchar(100) | YES | — | UNI | — |

## grade_sheets

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| section_id | bigint | NO | — | UNI | course_sections.id |
| status | enum('DRAFT','SUBMITTED','VERIFIED','RETURNED','APPROVED','PUBLISHED') | NO | DRAFT | — | — |
| published_at | datetime | YES | — | — | — |
| version_no | int | NO | 1 | — | — |

## grades

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| enrollment_id | bigint | NO | — | UNI | enrollments.id |
| attendance_score | decimal(4,2) | YES | — | — | — |
| midterm_score | decimal(4,2) | YES | — | — | — |
| final_score | decimal(4,2) | YES | — | — | — |
| remark | varchar(500) | YES | — | — | — |
| updated_at | datetime | NO | CURRENT_TIMESTAMP | — | — |

## invoice_items

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| invoice_id | bigint | NO | — | MUL | invoices.id |
| enrollment_id | bigint | NO | — | UNI | enrollments.id |
| credits_at_issue | smallint | NO | — | — | — |
| unit_price_at_issue | decimal(14,2) | NO | — | — | — |
| amount | decimal(14,2) | YES | — | — | — |

## invoices

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| student_id | bigint | NO | — | MUL | students.id |
| semester_id | bigint | NO | — | MUL | semesters.id |
| discount_amount | decimal(14,2) | NO | 0.00 | — | — |
| issued_at | datetime | NO | CURRENT_TIMESTAMP | — | — |

## lecturers

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| user_id | bigint | NO | — | UNI | users.id |
| faculty_id | bigint | NO | — | MUL | faculties.id |
| lecturer_code | varchar(40) | NO | — | UNI | — |

## majors

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| faculty_id | bigint | NO | — | MUL | faculties.id |
| code | varchar(30) | NO | — | UNI | — |
| name | varchar(180) | NO | — | — | — |

## notification_recipients

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| notification_id | bigint | NO | — | PRI | notifications.id |
| user_id | bigint | NO | — | PRI | users.id |
| read_at | datetime | YES | — | — | — |

## notifications

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| notification_code | varchar(60) | NO | — | UNI | — |
| created_by | bigint | YES | — | MUL | users.id |
| title | varchar(200) | NO | — | — | — |
| body | text | NO | — | — | — |
| created_at | datetime | NO | CURRENT_TIMESTAMP | — | — |

## outbound_emails

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| event_key | varchar(120) | NO | — | UNI | — |
| admission_application_id | bigint | YES | — | MUL | admission_applications.id |
| semester_report_id | bigint | YES | — | MUL | ctsv_semester_reports.id |
| student_request_id | bigint | YES | — | MUL | student_requests.id |
| template_code | varchar(60) | NO | — | — | — |
| recipient_email | varchar(190) | NO | — | — | — |
| subject | varchar(200) | NO | — | — | — |
| delivery_status | enum('QUEUED','SENDING','SENT','FAILED') | NO | QUEUED | MUL | — |
| attempt_count | int | NO | 0 | — | — |
| last_error | varchar(700) | YES | — | — | — |
| queued_at | datetime | NO | CURRENT_TIMESTAMP | — | — |
| sent_at | datetime | YES | — | — | — |
| mailbox_id | bigint | YES | — | MUL | student_school_mailboxes.id |
| body_text | text | YES | — | — | — |

## password_reset_tokens

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| user_id | bigint | NO | — | MUL | users.id |
| token_hash | char(64) | NO | — | UNI | — |
| expires_at | datetime | NO | — | — | — |
| used_at | datetime | YES | — | — | — |
| delivery_status | varchar(12) | NO | PENDING | — | — |
| created_at | datetime | NO | CURRENT_TIMESTAMP | — | — |

## payments

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| invoice_id | bigint | NO | — | MUL | invoices.id |
| recorded_by | bigint | NO | — | MUL | users.id |
| amount | decimal(14,2) | NO | — | — | — |
| paid_at | datetime | NO | — | — | — |
| reference_no | varchar(100) | NO | — | UNI | — |
| note | varchar(400) | YES | — | — | — |
| fund_id | bigint | YES | — | MUL | ctsv_funds.id |

## roles

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| code | varchar(40) | NO | — | UNI | — |
| description | varchar(160) | YES | — | — | — |

## rooms

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| code | varchar(80) | NO | — | UNI | — |
| name | varchar(160) | NO | — | — | — |
| capacity | int | YES | — | — | — |
| active | tinyint(1) | NO | 1 | — | — |

## schema_migrations

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| version | varchar(80) | NO | — | PRI | — |
| checksum | char(64) | NO | — | — | — |
| applied_at | datetime | NO | CURRENT_TIMESTAMP | — | — |

## section_schedules

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| section_id | bigint | NO | — | MUL | course_sections.id |
| day_of_week | tinyint | NO | — | — | — |
| starts_at | time | NO | — | — | — |
| ends_at | time | NO | — | — | — |
| room | varchar(80) | NO | — | MUL | — |
| room_id | bigint | YES | — | MUL | rooms.id |

## semesters

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| academic_year_id | bigint | NO | — | MUL | academic_years.id |
| code | varchar(30) | NO | — | — | — |
| starts_on | date | NO | — | — | — |
| ends_on | date | NO | — | — | — |
| registration_from | datetime | YES | — | — | — |
| registration_to | datetime | YES | — | — | — |
| status | enum('PLANNED','OPEN','CLOSED') | NO | PLANNED | — | — |

## student_profile_photos

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| student_id | bigint | NO | — | PRI | students.id |
| storage_key | varchar(100) | NO | — | — | — |
| mime_type | varchar(40) | NO | — | — | — |
| updated_by | bigint | NO | — | MUL | users.id |
| updated_at | datetime | NO | CURRENT_TIMESTAMP | — | — |

## student_request_attachments

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| request_id | bigint | NO | — | MUL | student_requests.id |
| uploaded_by | bigint | NO | — | MUL | users.id |
| file_name | varchar(255) | NO | — | — | — |
| storage_key | varchar(400) | NO | — | UNI | — |
| mime_type | varchar(100) | NO | — | — | — |
| size_bytes | bigint | NO | — | — | — |
| uploaded_at | datetime | NO | CURRENT_TIMESTAMP | — | — |

## student_request_review_events

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| request_id | bigint | NO | — | MUL | student_requests.id |
| reviewer_user_id | bigint | NO | — | MUL | users.id |
| action | enum('ASSIGN','ASK_MORE_INFO','RESOLVE','REJECT','REOPEN','ESCALATE_TO_SCHOOL','SCHOOL_FEEDBACK','RETURN_TO_CTSV') | NO | — | — | — |
| note | varchar(700) | YES | — | — | — |
| event_key | varchar(100) | YES | — | UNI | — |
| created_at | datetime | NO | CURRENT_TIMESTAMP | — | — |
| school_recipient_user_id | bigint | YES | — | MUL | users.id |

## student_requests

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| request_code | varchar(60) | NO | — | UNI | — |
| student_id | bigint | NO | — | MUL | students.id |
| request_type | enum('PROFILE_UPDATE','STUDY_STATUS','GRADE_QUESTION','TUITION_QUESTION','DOCUMENT_REQUEST','STUDENT_SUPPORT','COMPLAINT','OTHER') | NO | PROFILE_UPDATE | — | — |
| content | text | NO | — | — | — |
| status | enum('PENDING','PROCESSING','RESOLVED','REJECTED') | NO | PENDING | — | — |
| handled_by | bigint | YES | — | MUL | users.id |
| response | text | YES | — | — | — |
| created_at | datetime | NO | CURRENT_TIMESTAMP | — | — |
| handled_at | datetime | YES | — | — | — |

## student_school_mailboxes

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| student_id | bigint | NO | — | UNI | students.id |
| school_email | varchar(190) | NO | — | UNI | — |
| provisioning_status | enum('RESERVED','PROVISIONING','ACTIVE','FAILED','DISABLED') | NO | RESERVED | — | — |
| reserved_at | datetime | NO | CURRENT_TIMESTAMP | — | — |
| activated_at | datetime | YES | — | — | — |
| provisioned_by | bigint | YES | — | MUL | users.id |
| note | varchar(500) | YES | — | — | — |

## students

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| user_id | bigint | NO | — | UNI | users.id |
| student_code | varchar(40) | NO | — | UNI | — |
| class_id | bigint | NO | — | MUL | academic_classes.id |
| date_of_birth | date | YES | — | — | — |
| phone | varchar(24) | YES | — | — | — |
| address | varchar(400) | YES | — | — | — |
| status | enum('STUDYING','SUSPENDED','WITHDRAWN','GRADUATED') | NO | STUDYING | — | — |
| enrolled_on | date | YES | — | — | — |
| gender | enum('MALE','FEMALE','OTHER','UNDISCLOSED') | YES | — | — | — |
| place_of_birth | varchar(200) | YES | — | — | — |
| hometown | varchar(250) | YES | — | — | — |
| permanent_address | varchar(500) | YES | — | — | — |
| current_address | varchar(500) | YES | — | — | — |
| nationality | varchar(100) | YES | — | — | — |
| guardian_full_name | varchar(160) | YES | — | — | — |
| guardian_phone | varchar(24) | YES | — | — | — |

## tuition_adjustments

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| adjustment_code | varchar(80) | NO | — | UNI | — |
| invoice_id | bigint | NO | — | MUL | invoices.id |
| kind | enum('DEBIT','CREDIT') | NO | — | — | — |
| amount | decimal(14,2) | NO | — | — | — |
| reason | varchar(700) | NO | — | — | — |
| status | enum('REQUESTED','APPROVED','REJECTED') | NO | REQUESTED | — | — |
| requested_by | bigint | NO | — | MUL | users.id |
| approved_by | bigint | YES | — | MUL | users.id |
| created_at | datetime | NO | CURRENT_TIMESTAMP | — | — |
| decided_at | datetime | YES | — | — | — |

## tuition_rates

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| semester_id | bigint | NO | — | UNI | semesters.id |
| price_per_credit | decimal(14,2) | NO | — | — | — |

## user_roles

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| user_id | bigint | NO | — | PRI | users.id |
| role_id | bigint | NO | — | PRI | roles.id |

## users

| Cột | Kiểu | Cho phép NULL | Mặc định | Khóa/chỉ mục | Tham chiếu |
|---|---|---|---|---|---|
| id | bigint | NO | — | PRI | — |
| username | varchar(80) | NO | — | UNI | — |
| email | varchar(190) | YES | — | UNI | — |
| password_hash | varchar(255) | NO | — | — | — |
| full_name | varchar(160) | NO | — | — | — |
| enabled | tinyint(1) | NO | 0 | — | — |
| created_at | datetime | NO | CURRENT_TIMESTAMP | — | — |



## Bổ sung luồng xét duyệt học phí (migration 13–14)

Schema ứng dụng hiện có 56 bảng, gồm bảng quản lý migration. Chi tiết DDL, kiểu cột, UNIQUE, CHECK và FK: [13_INVOICE_REVIEW_WORKFLOW.sql](../data/v6/13_INVOICE_REVIEW_WORKFLOW.sql).

| Bảng | Cột nghiệp vụ | Liên kết |
|---|---|---|
| invoice_proposals | proposal_code, student_id, semester_id, discount_amount, status, prepared_by, submitted_at, reviewed_by, reviewed_at, decision_note, note, invoice_id, created_at | students, semesters, users (người lập/duyệt), invoices; UNIQUE sinh viên/học kỳ và invoice_id |
| invoice_proposal_items | proposal_id, enrollment_id, credits_at_proposal, unit_price_at_proposal | invoice_proposals, enrollments; UNIQUE đề nghị/đăng ký |
| invoice_proposal_reviews | proposal_id, actor_user_id, action, from_status, to_status, note, created_at | invoice_proposals, users |

Cả ba bảng có PK `id` BIGINT tự tăng. View `v_approval_workflow_checks` kiểm tra 6 điều kiện về chi tiết đề nghị, khớp sinh viên/học kỳ, lịch sử trình/duyệt, PĐT trình bảng điểm và miễn giảm không vượt tổng.
