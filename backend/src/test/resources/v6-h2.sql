-- H2 compatibility fixture generated from V6: application tests only, NOT a MySQL migration.

CREATE TABLE IF NOT EXISTS users (
    id BIGINT NOT NULL AUTO_INCREMENT,
    username VARCHAR(80) NOT NULL,
    email VARCHAR(190) NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(160) NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE (username),
    UNIQUE (email)
);

CREATE TABLE IF NOT EXISTS roles (
    id BIGINT NOT NULL AUTO_INCREMENT,
    code VARCHAR(40) NOT NULL,
    description VARCHAR(160) NULL,
    PRIMARY KEY (id),
    UNIQUE (code)
);

CREATE TABLE IF NOT EXISTS user_roles (
    user_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,
    PRIMARY KEY (user_id, role_id),
    CONSTRAINT fk_user_roles_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_user_roles_role FOREIGN KEY (role_id) REFERENCES roles(id)
);

CREATE TABLE IF NOT EXISTS faculties (
    id BIGINT NOT NULL AUTO_INCREMENT,
    code VARCHAR(30) NOT NULL,
    name VARCHAR(180) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE (code)
);

CREATE TABLE IF NOT EXISTS majors (
    id BIGINT NOT NULL AUTO_INCREMENT,
    faculty_id BIGINT NOT NULL,
    code VARCHAR(30) NOT NULL,
    name VARCHAR(180) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE (code),
    UNIQUE (faculty_id, name),
    CONSTRAINT fk_majors_faculty FOREIGN KEY (faculty_id) REFERENCES faculties(id)
);

CREATE TABLE IF NOT EXISTS cohorts (
    id BIGINT NOT NULL AUTO_INCREMENT,
    code VARCHAR(30) NOT NULL,
    start_year SMALLINT NOT NULL,
    end_year SMALLINT NULL,
    PRIMARY KEY (id),
    UNIQUE (code),
    CONSTRAINT chk_cohorts_dates CHECK (end_year IS NULL OR end_year >= start_year)
);

CREATE TABLE IF NOT EXISTS academic_classes (
    id BIGINT NOT NULL AUTO_INCREMENT,
    major_id BIGINT NOT NULL,
    cohort_id BIGINT NOT NULL,
    code VARCHAR(50) NOT NULL,
    name VARCHAR(180) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE (code),
    CONSTRAINT fk_academic_classes_major FOREIGN KEY (major_id) REFERENCES majors(id),
    CONSTRAINT fk_academic_classes_cohort FOREIGN KEY (cohort_id) REFERENCES cohorts(id)
);

CREATE TABLE IF NOT EXISTS students (
    id BIGINT NOT NULL AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    student_code VARCHAR(40) NOT NULL,
    class_id BIGINT NOT NULL,
    date_of_birth DATE NULL,
    phone VARCHAR(24) NULL,
    address VARCHAR(400) NULL,
    status VARCHAR(40) NOT NULL DEFAULT 'STUDYING',
    enrolled_on DATE NULL,
    PRIMARY KEY (id),
    UNIQUE (user_id),
    UNIQUE (student_code),
    CONSTRAINT fk_students_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_students_class FOREIGN KEY (class_id) REFERENCES academic_classes(id)
);

CREATE TABLE IF NOT EXISTS lecturers (
    id BIGINT NOT NULL AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    faculty_id BIGINT NOT NULL,
    lecturer_code VARCHAR(40) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE (user_id),
    UNIQUE (lecturer_code),
    CONSTRAINT fk_lecturers_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_lecturers_faculty FOREIGN KEY (faculty_id) REFERENCES faculties(id)
);

CREATE TABLE IF NOT EXISTS academic_years (
    id BIGINT NOT NULL AUTO_INCREMENT,
    name VARCHAR(30) NOT NULL,
    starts_on DATE NOT NULL,
    ends_on DATE NOT NULL,
    PRIMARY KEY (id),
    UNIQUE (name),
    CONSTRAINT chk_academic_year_dates CHECK (ends_on >= starts_on)
);

CREATE TABLE IF NOT EXISTS semesters (
    id BIGINT NOT NULL AUTO_INCREMENT,
    academic_year_id BIGINT NOT NULL,
    code VARCHAR(30) NOT NULL,
    starts_on DATE NOT NULL,
    ends_on DATE NOT NULL,
    registration_from DATETIME NULL,
    registration_to DATETIME NULL,
    status VARCHAR(40) NOT NULL DEFAULT 'PLANNED',
    PRIMARY KEY (id),
    UNIQUE (academic_year_id,code),
    CONSTRAINT chk_semesters_dates CHECK (ends_on >= starts_on),
    CONSTRAINT chk_semesters_window CHECK (
      registration_from IS NULL OR registration_to IS NULL OR registration_to >= registration_from
    ),
    CONSTRAINT fk_semesters_year FOREIGN KEY (academic_year_id) REFERENCES academic_years(id)
);

CREATE TABLE IF NOT EXISTS courses (
    id BIGINT NOT NULL AUTO_INCREMENT,
    course_code VARCHAR(40) NOT NULL,
    title VARCHAR(200) NOT NULL,
    credits SMALLINT NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (id),
    UNIQUE (course_code),
    CONSTRAINT chk_courses_credits CHECK (credits BETWEEN 1 AND 15)
);

CREATE TABLE IF NOT EXISTS curricula (
    id BIGINT NOT NULL AUTO_INCREMENT,
    major_id BIGINT NOT NULL,
    cohort_id BIGINT NOT NULL,
    title VARCHAR(180) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE (major_id,cohort_id),
    CONSTRAINT fk_curricula_major FOREIGN KEY (major_id) REFERENCES majors(id),
    CONSTRAINT fk_curricula_cohort FOREIGN KEY (cohort_id) REFERENCES cohorts(id)
);

CREATE TABLE IF NOT EXISTS curriculum_courses (
    curriculum_id BIGINT NOT NULL,
    course_id BIGINT NOT NULL,
    suggested_semester SMALLINT NULL,
    required_course BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (curriculum_id,course_id),
    CONSTRAINT chk_curriculum_courses_sem CHECK (suggested_semester IS NULL OR suggested_semester BETWEEN 1 AND 12),
    CONSTRAINT fk_curriculum_courses_curriculum FOREIGN KEY (curriculum_id) REFERENCES curricula(id),
    CONSTRAINT fk_curriculum_courses_course FOREIGN KEY (course_id) REFERENCES courses(id)
);

CREATE TABLE IF NOT EXISTS course_sections (
    id BIGINT NOT NULL AUTO_INCREMENT,
    semester_id BIGINT NOT NULL,
    course_id BIGINT NOT NULL,
    lecturer_id BIGINT NULL,
    section_code VARCHAR(40) NOT NULL,
    capacity INT NOT NULL,
    attendance_weight DECIMAL(5,2) NOT NULL DEFAULT 10.00,
    midterm_weight DECIMAL(5,2) NOT NULL DEFAULT 30.00,
    final_weight DECIMAL(5,2) NOT NULL DEFAULT 60.00,
    is_open BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (id),
    UNIQUE (semester_id,section_code),
    CONSTRAINT chk_course_sections_capacity CHECK (capacity > 0),
    CONSTRAINT chk_course_sections_weights CHECK (
      attendance_weight >= 0 AND midterm_weight >= 0 AND final_weight >= 0 AND
      attendance_weight + midterm_weight + final_weight = 100.00
    ),
    CONSTRAINT fk_sections_semester FOREIGN KEY (semester_id) REFERENCES semesters(id),
    CONSTRAINT fk_sections_course FOREIGN KEY (course_id) REFERENCES courses(id),
    CONSTRAINT fk_sections_lecturer FOREIGN KEY (lecturer_id) REFERENCES lecturers(id)
);

CREATE TABLE IF NOT EXISTS section_schedules (
    id BIGINT NOT NULL AUTO_INCREMENT,
    section_id BIGINT NOT NULL,
    day_of_week TINYINT NOT NULL, -- ISO weekday 1=Mon ... 7=Sun
    starts_at TIME NOT NULL,
    ends_at TIME NOT NULL,
    room VARCHAR(80) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE (section_id,day_of_week,starts_at,ends_at),
    CONSTRAINT chk_section_schedules_day CHECK (day_of_week BETWEEN 1 AND 7),
    CONSTRAINT chk_section_schedules_time CHECK (ends_at > starts_at),
    CONSTRAINT fk_section_schedules_section FOREIGN KEY (section_id) REFERENCES course_sections(id)
);

CREATE TABLE IF NOT EXISTS enrollments (
    id BIGINT NOT NULL AUTO_INCREMENT,
    student_id BIGINT NOT NULL,
    section_id BIGINT NOT NULL,
    status VARCHAR(40) NOT NULL DEFAULT 'REGISTERED',
    registered_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE (student_id,section_id),
    CONSTRAINT fk_enrollments_student FOREIGN KEY (student_id) REFERENCES students(id),
    CONSTRAINT fk_enrollments_section FOREIGN KEY (section_id) REFERENCES course_sections(id)
);

CREATE TABLE IF NOT EXISTS grade_sheets (
    id BIGINT NOT NULL AUTO_INCREMENT,
    section_id BIGINT NOT NULL,
    status VARCHAR(40) NOT NULL DEFAULT 'DRAFT',
    published_at DATETIME NULL,
    version_no INT NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    UNIQUE (section_id),
    CONSTRAINT chk_grade_sheets_version CHECK (version_no > 0),
    CONSTRAINT fk_grade_sheets_section FOREIGN KEY (section_id) REFERENCES course_sections(id)
);

CREATE TABLE IF NOT EXISTS grades (
    id BIGINT NOT NULL AUTO_INCREMENT,
    enrollment_id BIGINT NOT NULL,
    attendance_score DECIMAL(4,2) NULL,
    midterm_score DECIMAL(4,2) NULL,
    final_score DECIMAL(4,2) NULL,
    remark VARCHAR(500) NULL,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE (enrollment_id),
    CONSTRAINT chk_grades_attendance CHECK (attendance_score IS NULL OR attendance_score BETWEEN 0 AND 10),
    CONSTRAINT chk_grades_midterm CHECK (midterm_score IS NULL OR midterm_score BETWEEN 0 AND 10),
    CONSTRAINT chk_grades_final CHECK (final_score IS NULL OR final_score BETWEEN 0 AND 10),
    CONSTRAINT fk_grades_enrollment FOREIGN KEY (enrollment_id) REFERENCES enrollments(id)
);

CREATE TABLE IF NOT EXISTS grade_reviews (
    id BIGINT NOT NULL AUTO_INCREMENT,
    sheet_id BIGINT NOT NULL,
    actor_user_id BIGINT NOT NULL,
    action VARCHAR(40) NOT NULL,
    note VARCHAR(700) NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    event_key VARCHAR(100) NULL, -- used ONLY for idempotent imported events
    PRIMARY KEY (id),
    UNIQUE (event_key),
    CONSTRAINT fk_grade_reviews_sheet FOREIGN KEY (sheet_id) REFERENCES grade_sheets(id),
    CONSTRAINT fk_grade_reviews_user FOREIGN KEY (actor_user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS tuition_rates (
    id BIGINT NOT NULL AUTO_INCREMENT,
    semester_id BIGINT NOT NULL,
    price_per_credit DECIMAL(14,2) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE (semester_id),
    CONSTRAINT chk_tuition_rates_price CHECK (price_per_credit >= 0),
    CONSTRAINT fk_tuition_rates_semester FOREIGN KEY (semester_id) REFERENCES semesters(id)
);

CREATE TABLE IF NOT EXISTS invoices (
    id BIGINT NOT NULL AUTO_INCREMENT,
    student_id BIGINT NOT NULL,
    semester_id BIGINT NOT NULL,
    discount_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    issued_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE (student_id,semester_id),
    CONSTRAINT chk_invoices_discount CHECK (discount_amount >= 0),
    CONSTRAINT fk_invoices_student FOREIGN KEY (student_id) REFERENCES students(id),
    CONSTRAINT fk_invoices_semester FOREIGN KEY (semester_id) REFERENCES semesters(id)
);

CREATE TABLE IF NOT EXISTS invoice_items (
    id BIGINT NOT NULL AUTO_INCREMENT,
    invoice_id BIGINT NOT NULL,
    enrollment_id BIGINT NOT NULL,
    credits_at_issue SMALLINT NOT NULL,
    unit_price_at_issue DECIMAL(14,2) NOT NULL,
    amount DECIMAL(14,2) GENERATED ALWAYS AS (credits_at_issue * unit_price_at_issue),
    PRIMARY KEY (id),
    UNIQUE (enrollment_id),
    CONSTRAINT chk_invoice_items_credits CHECK (credits_at_issue BETWEEN 1 AND 15),
    CONSTRAINT chk_invoice_items_price CHECK (unit_price_at_issue >= 0),
    CONSTRAINT fk_invoice_items_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id),
    CONSTRAINT fk_invoice_items_enrollment FOREIGN KEY (enrollment_id) REFERENCES enrollments(id)
);

CREATE TABLE IF NOT EXISTS payments (
    id BIGINT NOT NULL AUTO_INCREMENT,
    invoice_id BIGINT NOT NULL,
    recorded_by BIGINT NOT NULL,
    amount DECIMAL(14,2) NOT NULL,
    paid_at DATETIME NOT NULL,
    reference_no VARCHAR(100) NOT NULL,
    note VARCHAR(400) NULL,
    PRIMARY KEY (id),
    UNIQUE (reference_no),
    CONSTRAINT chk_payments_amount CHECK (amount > 0),
    CONSTRAINT fk_payments_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id),
    CONSTRAINT fk_payments_recorded_by FOREIGN KEY (recorded_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS student_requests (
    id BIGINT NOT NULL AUTO_INCREMENT,
    request_code VARCHAR(60) NOT NULL,
    student_id BIGINT NOT NULL,
    request_type VARCHAR(40) NOT NULL,
    content TEXT NOT NULL,
    status VARCHAR(40) NOT NULL DEFAULT 'PENDING',
    handled_by BIGINT NULL,
    response TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    handled_at DATETIME NULL,
    PRIMARY KEY (id),
    UNIQUE (request_code),
    CONSTRAINT fk_student_requests_student FOREIGN KEY (student_id) REFERENCES students(id),
    CONSTRAINT fk_student_requests_handler FOREIGN KEY (handled_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS notifications (
    id BIGINT NOT NULL AUTO_INCREMENT,
    notification_code VARCHAR(60) NOT NULL,
    created_by BIGINT NULL,
    title VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE (notification_code),
    CONSTRAINT fk_notifications_created_by FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS notification_recipients (
    notification_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    read_at DATETIME NULL,
    PRIMARY KEY (notification_id,user_id),
    CONSTRAINT fk_notification_recipients_notification FOREIGN KEY (notification_id) REFERENCES notifications(id) ON DELETE CASCADE,
    CONSTRAINT fk_notification_recipients_user FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS audit_logs (
    id BIGINT NOT NULL AUTO_INCREMENT,
    actor_user_id BIGINT NULL,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(80) NOT NULL,
    entity_id VARCHAR(80) NULL,
    detail_json JSON NULL,
    event_key VARCHAR(100) NULL, -- for demo/import only; application may leave NULL
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE (event_key),
    CONSTRAINT fk_audit_logs_actor FOREIGN KEY (actor_user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS admission_periods (
    id BIGINT NOT NULL AUTO_INCREMENT,
    code VARCHAR(50) NOT NULL,
    title VARCHAR(180) NOT NULL,
    cohort_id BIGINT NOT NULL,
    opens_at DATETIME NOT NULL,
    closes_at DATETIME NOT NULL,
    status VARCHAR(40) NOT NULL DEFAULT 'PLANNED',
    PRIMARY KEY (id),
    UNIQUE (code),
    CONSTRAINT chk_admission_period_window CHECK (closes_at > opens_at),
    CONSTRAINT fk_admission_period_cohort FOREIGN KEY (cohort_id) REFERENCES cohorts(id)
);

CREATE TABLE IF NOT EXISTS admission_applications (
    id BIGINT NOT NULL AUTO_INCREMENT,
    application_code VARCHAR(60) NOT NULL,
    applicant_user_id BIGINT NOT NULL,
    period_id BIGINT NOT NULL,
    major_id BIGINT NOT NULL,
    phone VARCHAR(24) NULL,
    address VARCHAR(400) NULL,
    date_of_birth DATE NULL,
    status VARCHAR(40)
      NOT NULL DEFAULT 'DRAFT',
    assigned_ctsv_user_id BIGINT NULL,
    student_id BIGINT NULL,
    submitted_at DATETIME NULL,
    changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE (application_code),
    UNIQUE (applicant_user_id, period_id),
    UNIQUE (student_id),
    CONSTRAINT fk_admission_app_user FOREIGN KEY (applicant_user_id) REFERENCES users(id),
    CONSTRAINT fk_admission_app_period FOREIGN KEY (period_id) REFERENCES admission_periods(id),
    CONSTRAINT fk_admission_app_major FOREIGN KEY (major_id) REFERENCES majors(id),
    CONSTRAINT fk_admission_app_ctsv FOREIGN KEY (assigned_ctsv_user_id) REFERENCES users(id),
    CONSTRAINT fk_admission_app_student FOREIGN KEY (student_id) REFERENCES students(id),
    CONSTRAINT chk_admission_enrolled_link CHECK (status <> 'ENROLLED' OR student_id IS NOT NULL)
);

CREATE TABLE IF NOT EXISTS admission_document_requirements (
    period_id BIGINT NOT NULL,
    document_type VARCHAR(50) NOT NULL,
    label VARCHAR(160) NOT NULL,
    is_required BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (period_id, document_type),
    CONSTRAINT fk_admission_requirement_period FOREIGN KEY (period_id)
      REFERENCES admission_periods(id)
);

CREATE TABLE IF NOT EXISTS admission_documents (
    id BIGINT NOT NULL AUTO_INCREMENT,
    application_id BIGINT NOT NULL,
    document_type VARCHAR(50) NOT NULL,
    revision_no SMALLINT NOT NULL DEFAULT 1,
    file_name VARCHAR(255) NOT NULL,
    storage_key VARCHAR(400) NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    size_bytes BIGINT NOT NULL,
    sha256 CHAR(64)  NULL,
    status VARCHAR(40) NOT NULL DEFAULT 'PENDING',
    checked_by BIGINT NULL,
    checked_at DATETIME NULL,
    rejection_reason VARCHAR(500) NULL,
    uploaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE (application_id, document_type, revision_no),
    UNIQUE (storage_key),
    CONSTRAINT chk_admission_doc_revision CHECK (revision_no > 0),
    CONSTRAINT chk_admission_doc_size CHECK (size_bytes > 0 AND size_bytes <= 10485760),
    CONSTRAINT fk_admission_doc_app FOREIGN KEY (application_id) REFERENCES admission_applications(id),
    CONSTRAINT fk_admission_doc_checker FOREIGN KEY (checked_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS admission_review_events (
    id BIGINT NOT NULL AUTO_INCREMENT,
    application_id BIGINT NOT NULL,
    actor_user_id BIGINT NOT NULL,
    event_type VARCHAR(40) NOT NULL,
    from_status VARCHAR(30) NOT NULL,
    to_status VARCHAR(30) NOT NULL,
    note VARCHAR(700) NULL,
    event_key VARCHAR(100) NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE (event_key),
    CONSTRAINT fk_admission_review_application FOREIGN KEY (application_id) REFERENCES admission_applications(id),
    CONSTRAINT fk_admission_review_user FOREIGN KEY (actor_user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS student_request_attachments (
    id BIGINT NOT NULL AUTO_INCREMENT,
    request_id BIGINT NOT NULL,
    uploaded_by BIGINT NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    storage_key VARCHAR(400) NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    size_bytes BIGINT NOT NULL,
    uploaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE (storage_key),
    CONSTRAINT chk_student_request_file_size CHECK (size_bytes > 0 AND size_bytes <= 10485760),
    CONSTRAINT fk_student_request_file_request FOREIGN KEY (request_id) REFERENCES student_requests(id),
    CONSTRAINT fk_student_request_file_uploader FOREIGN KEY (uploaded_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS student_request_review_events (
    id BIGINT NOT NULL AUTO_INCREMENT,
    request_id BIGINT NOT NULL,
    reviewer_user_id BIGINT NOT NULL,
    action VARCHAR(40) NOT NULL,
    note VARCHAR(700) NULL,
    event_key VARCHAR(100) NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE (event_key),
    CONSTRAINT fk_student_request_review_request FOREIGN KEY (request_id) REFERENCES student_requests(id),
    CONSTRAINT fk_student_request_review_reviewer FOREIGN KEY (reviewer_user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS ctsv_funds (
  id BIGINT NOT NULL AUTO_INCREMENT,
  code VARCHAR(50) NOT NULL,
  name VARCHAR(180) NOT NULL,
  channel VARCHAR(40) NOT NULL,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY(id), UNIQUE(code)
);

CREATE TABLE IF NOT EXISTS ctsv_remittances (
  id BIGINT NOT NULL AUTO_INCREMENT,
  remittance_code VARCHAR(70) NOT NULL,
  semester_id BIGINT NOT NULL,
  fund_id BIGINT NOT NULL,
  amount DECIMAL(14,2) NOT NULL,
  status VARCHAR(40) NOT NULL DEFAULT 'DRAFT',
  prepared_by BIGINT NOT NULL,
  reviewed_by BIGINT NULL,
  remitted_at DATETIME NULL,
  reviewed_at DATETIME NULL,
  external_reference VARCHAR(120) NULL,
  note VARCHAR(700) NULL,
  PRIMARY KEY(id),
  UNIQUE(remittance_code),
  UNIQUE(external_reference),
  CONSTRAINT chk_ctsv_remittance_amount CHECK (amount>0),
  CONSTRAINT fk_ctsv_remittance_sem FOREIGN KEY(semester_id) REFERENCES semesters(id),
  CONSTRAINT fk_ctsv_remittance_fund FOREIGN KEY(fund_id) REFERENCES ctsv_funds(id),
  CONSTRAINT fk_ctsv_remittance_prepared FOREIGN KEY(prepared_by) REFERENCES users(id),
  CONSTRAINT fk_ctsv_remittance_reviewed FOREIGN KEY(reviewed_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS ctsv_semester_reports (
  id BIGINT NOT NULL AUTO_INCREMENT,
  report_code VARCHAR(70) NOT NULL,
  semester_id BIGINT NOT NULL,
  prepared_by BIGINT NOT NULL,
  status VARCHAR(40) NOT NULL DEFAULT 'DRAFT',
  received_by BIGINT NULL,
  submitted_at DATETIME NULL,
  reviewed_at DATETIME NULL,
  note VARCHAR(700) NULL,
  PRIMARY KEY(id),
  UNIQUE(report_code),
  UNIQUE(semester_id),
  CONSTRAINT fk_ctsv_report_sem FOREIGN KEY(semester_id) REFERENCES semesters(id),
  CONSTRAINT fk_ctsv_report_prepared FOREIGN KEY(prepared_by) REFERENCES users(id),
  CONSTRAINT fk_ctsv_report_received FOREIGN KEY(received_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS student_school_mailboxes (
  id BIGINT NOT NULL AUTO_INCREMENT,
  student_id BIGINT NOT NULL,
  school_email VARCHAR(190) NOT NULL,
  provisioning_status VARCHAR(40) NOT NULL DEFAULT 'RESERVED',
  reserved_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  activated_at DATETIME NULL,
  provisioned_by BIGINT NULL,
  note VARCHAR(500) NULL,
  PRIMARY KEY(id),
  UNIQUE(student_id),
  UNIQUE(school_email),
  CONSTRAINT fk_student_mailbox_student FOREIGN KEY(student_id) REFERENCES students(id),
  CONSTRAINT fk_student_mailbox_provisioned_by FOREIGN KEY(provisioned_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS outbound_emails (
  id BIGINT NOT NULL AUTO_INCREMENT,
  event_key VARCHAR(120) NOT NULL,
  admission_application_id BIGINT NULL,
  semester_report_id BIGINT NULL,
  student_request_id BIGINT NULL,
  mailbox_id BIGINT NULL,
  body_text TEXT NULL,
  template_code VARCHAR(60) NOT NULL,
  recipient_email VARCHAR(190) NOT NULL,
  subject VARCHAR(200) NOT NULL,
  delivery_status VARCHAR(40) NOT NULL DEFAULT 'QUEUED',
  attempt_count INT NOT NULL DEFAULT 0,
  last_error VARCHAR(700) NULL,
  queued_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  sent_at DATETIME NULL,
  PRIMARY KEY(id),
  UNIQUE(event_key),
  CONSTRAINT chk_outbound_email_attempt CHECK(attempt_count>=0),
  CONSTRAINT chk_outbound_email_one_origin CHECK (
    (CASE WHEN admission_application_id IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN semester_report_id IS NOT NULL THEN 1 ELSE 0 END)
      + (CASE WHEN student_request_id IS NOT NULL THEN 1 ELSE 0 END) + (CASE WHEN mailbox_id IS NOT NULL THEN 1 ELSE 0 END)=1),
  CONSTRAINT fk_email_admission FOREIGN KEY(admission_application_id) REFERENCES admission_applications(id),
  CONSTRAINT fk_email_report FOREIGN KEY(semester_report_id) REFERENCES ctsv_semester_reports(id),
  CONSTRAINT fk_email_request FOREIGN KEY(student_request_id) REFERENCES student_requests(id),
  CONSTRAINT fk_outbound_mailbox FOREIGN KEY(mailbox_id) REFERENCES student_school_mailboxes(id)
);

CREATE TABLE IF NOT EXISTS admission_identity_records (
    id BIGINT NOT NULL AUTO_INCREMENT,
    application_id BIGINT NOT NULL,
    identity_type VARCHAR(40) NOT NULL DEFAULT 'CCCD',
    identity_last4 CHAR(4) NULL,
    identity_number_encrypted VARBINARY(512) NULL,
    identity_number_hmac CHAR(64)  NULL,
    issued_on DATE NULL,
    expires_on DATE NULL,
    issued_by VARCHAR(200) NULL,
    verified_at DATETIME NULL,
    verified_by BIGINT NULL,
    PRIMARY KEY (id),
    UNIQUE (application_id),
    CONSTRAINT chk_admission_identity_validity CHECK (expires_on IS NULL OR issued_on IS NULL OR expires_on >= issued_on),
    CONSTRAINT fk_identity_application FOREIGN KEY (application_id) REFERENCES admission_applications(id),
    CONSTRAINT fk_identity_verified_by FOREIGN KEY (verified_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS admission_high_school_records (
    id BIGINT NOT NULL AUTO_INCREMENT,
    application_id BIGINT NOT NULL,
    school_name VARCHAR(200) NOT NULL,
    school_province VARCHAR(160) NULL,
    graduation_year SMALLINT NULL,
    graduation_status VARCHAR(40) NOT NULL DEFAULT 'PENDING',
    transcript_average DECIMAL(4,2) NULL,
    PRIMARY KEY (id),
    UNIQUE (application_id),
    CONSTRAINT chk_school_records_year CHECK (graduation_year IS NULL OR graduation_year BETWEEN 1980 AND 2100),
    CONSTRAINT chk_school_records_average CHECK (transcript_average IS NULL OR transcript_average BETWEEN 0 AND 10),
    CONSTRAINT fk_school_records_application FOREIGN KEY (application_id) REFERENCES admission_applications(id)
);

CREATE TABLE IF NOT EXISTS admission_high_school_scores (
    id BIGINT NOT NULL AUTO_INCREMENT,
    school_record_id BIGINT NOT NULL,
    grade_level TINYINT NOT NULL,
    subject_code VARCHAR(40) NOT NULL,
    average_score DECIMAL(4,2) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE (school_record_id,grade_level,subject_code),
    CONSTRAINT chk_high_school_grade CHECK (grade_level IN (10,11,12)),
    CONSTRAINT chk_high_school_score CHECK (average_score BETWEEN 0 AND 10),
    CONSTRAINT fk_school_score_record FOREIGN KEY (school_record_id) REFERENCES admission_high_school_records(id)
);

CREATE TABLE IF NOT EXISTS tuition_adjustments (
  id BIGINT NOT NULL AUTO_INCREMENT,
  adjustment_code VARCHAR(80) NOT NULL,
  invoice_id BIGINT NOT NULL,
  kind VARCHAR(40) NOT NULL,
  amount DECIMAL(14,2) NOT NULL,
  reason VARCHAR(700) NOT NULL,
  status VARCHAR(40) NOT NULL DEFAULT 'REQUESTED',
  requested_by BIGINT NOT NULL,
  approved_by BIGINT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  decided_at DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE (adjustment_code),
  CONSTRAINT chk_tuition_adjustments_amount CHECK (amount > 0),
  CONSTRAINT chk_tuition_adjustments_decision CHECK (
    (status='REQUESTED' AND approved_by IS NULL AND decided_at IS NULL)
    OR (status IN ('APPROVED','REJECTED') AND approved_by IS NOT NULL AND decided_at IS NOT NULL)
  ),
  CONSTRAINT fk_tuition_adjustment_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id),
  CONSTRAINT fk_tuition_adjustment_requester FOREIGN KEY (requested_by) REFERENCES users(id),
  CONSTRAINT fk_tuition_adjustment_approver FOREIGN KEY (approved_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS ctsv_semester_report_reviews (
  id BIGINT NOT NULL AUTO_INCREMENT,
  report_id BIGINT NOT NULL,
  actor_user_id BIGINT NOT NULL,
  action VARCHAR(40) NOT NULL,
  note VARCHAR(700) NULL,
  event_key VARCHAR(120) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE (event_key),
  CONSTRAINT fk_ctsv_report_review_report FOREIGN KEY (report_id) REFERENCES ctsv_semester_reports(id),
  CONSTRAINT fk_ctsv_report_review_actor FOREIGN KEY (actor_user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS email_delivery_attempts (
  id BIGINT NOT NULL AUTO_INCREMENT,
  outbound_email_id BIGINT NOT NULL,
  attempt_no INT NOT NULL,
  result VARCHAR(40) NOT NULL,
  provider_message_id VARCHAR(190) NULL,
  error_code VARCHAR(80) NULL,
  error_message VARCHAR(500) NULL,
  attempted_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE (outbound_email_id,attempt_no),
  UNIQUE (provider_message_id),
  CONSTRAINT chk_email_delivery_attempt_no CHECK (attempt_no>=1),
  CONSTRAINT fk_email_delivery_outbound FOREIGN KEY (outbound_email_id) REFERENCES outbound_emails(id)
);

CREATE TABLE IF NOT EXISTS ctsv_remittance_allocations (
  remittance_id BIGINT NOT NULL,
  payment_id BIGINT NOT NULL,
  allocated_amount DECIMAL(14,2) NOT NULL,
  PRIMARY KEY (remittance_id,payment_id),
  CONSTRAINT chk_ctsv_remittance_allocation_amount CHECK (allocated_amount > 0),
  CONSTRAINT fk_ctsv_allocation_remittance FOREIGN KEY (remittance_id) REFERENCES ctsv_remittances(id),
  CONSTRAINT fk_ctsv_allocation_payment FOREIGN KEY (payment_id) REFERENCES payments(id)
);

ALTER TABLE student_request_review_events ADD COLUMN IF NOT EXISTS school_recipient_user_id BIGINT NULL;
ALTER TABLE students ADD COLUMN IF NOT EXISTS gender VARCHAR(40) NULL;
ALTER TABLE students ADD COLUMN IF NOT EXISTS place_of_birth VARCHAR(200) NULL;
ALTER TABLE students ADD COLUMN IF NOT EXISTS hometown VARCHAR(250) NULL;
ALTER TABLE students ADD COLUMN IF NOT EXISTS permanent_address VARCHAR(500) NULL;
ALTER TABLE students ADD COLUMN IF NOT EXISTS current_address VARCHAR(500) NULL;
ALTER TABLE students ADD COLUMN IF NOT EXISTS nationality VARCHAR(100) NULL;
ALTER TABLE students ADD COLUMN IF NOT EXISTS guardian_full_name VARCHAR(160) NULL;
ALTER TABLE students ADD COLUMN IF NOT EXISTS guardian_phone VARCHAR(24) NULL;
ALTER TABLE admission_applications ADD COLUMN IF NOT EXISTS legal_full_name VARCHAR(160) NULL;
ALTER TABLE admission_applications ADD COLUMN IF NOT EXISTS personal_email VARCHAR(190) NULL;
ALTER TABLE admission_applications ADD COLUMN IF NOT EXISTS gender VARCHAR(40) NULL;
ALTER TABLE admission_applications ADD COLUMN IF NOT EXISTS place_of_birth VARCHAR(200) NULL;
ALTER TABLE admission_applications ADD COLUMN IF NOT EXISTS hometown VARCHAR(250) NULL;
ALTER TABLE admission_applications ADD COLUMN IF NOT EXISTS permanent_address VARCHAR(500) NULL;
ALTER TABLE admission_applications ADD COLUMN IF NOT EXISTS current_address VARCHAR(500) NULL;
ALTER TABLE admission_applications ADD COLUMN IF NOT EXISTS nationality VARCHAR(100) NULL;
ALTER TABLE admission_applications ADD COLUMN IF NOT EXISTS guardian_full_name VARCHAR(160) NULL;
ALTER TABLE admission_applications ADD COLUMN IF NOT EXISTS guardian_phone VARCHAR(24) NULL;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS fund_id BIGINT NULL;

CREATE OR REPLACE VIEW v_invoice_balances AS
SELECT t.invoice_id,t.student_id,t.semester_id,t.issued_at,
       t.base_amount,t.discount_amount,t.debit_amount,t.credit_amount,
       GREATEST(t.base_amount-t.discount_amount+t.debit_amount-t.credit_amount,0.00) AS payable_amount,
       t.paid_amount,
       GREATEST(t.base_amount-t.discount_amount+t.debit_amount-t.credit_amount-t.paid_amount,0.00) AS remaining_amount,
       CASE
         WHEN t.base_amount-t.discount_amount+t.debit_amount-t.credit_amount <= t.paid_amount
              AND t.base_amount+t.debit_amount>0 THEN 'PAID'
         WHEN t.paid_amount>0 THEN 'PARTIAL'
         ELSE 'UNPAID' END AS payment_status
FROM (
 SELECT i.id AS invoice_id,i.student_id,i.semester_id,i.issued_at,
        COALESCE(it.base_amount,0.00) AS base_amount,i.discount_amount,
        COALESCE(ad.debit_amount,0.00) AS debit_amount,
        COALESCE(ad.credit_amount,0.00) AS credit_amount,
        COALESCE(p.paid_amount,0.00) AS paid_amount
 FROM invoices i
 LEFT JOIN (SELECT invoice_id,SUM(amount) AS base_amount
            FROM invoice_items GROUP BY invoice_id) it ON it.invoice_id=i.id
 LEFT JOIN (SELECT invoice_id,
              SUM(CASE WHEN kind='DEBIT' THEN amount ELSE 0 END) AS debit_amount,
              SUM(CASE WHEN kind='CREDIT' THEN amount ELSE 0 END) AS credit_amount
            FROM tuition_adjustments WHERE status='APPROVED'
            GROUP BY invoice_id) ad ON ad.invoice_id=i.id
 LEFT JOIN (SELECT invoice_id,SUM(amount) AS paid_amount
            FROM payments GROUP BY invoice_id) p ON p.invoice_id=i.id
) t;

CREATE OR REPLACE VIEW v_student_timetable AS
SELECT e.id AS enrollment_id,e.student_id,cs.id AS section_id,cs.semester_id,
       c.course_code,c.title AS course_title,cs.section_code,
       sch.day_of_week,sch.starts_at,sch.ends_at,sch.room,
       cs.lecturer_id,u.full_name AS lecturer_name,e.status AS enrollment_status
FROM enrollments e
JOIN course_sections cs ON cs.id=e.section_id
JOIN courses c ON c.id=cs.course_id
JOIN section_schedules sch ON sch.section_id=cs.id
LEFT JOIN lecturers l ON l.id=cs.lecturer_id
LEFT JOIN users u ON u.id=l.user_id
WHERE e.status IN ('REGISTERED','COMPLETED');

CREATE OR REPLACE VIEW v_ctsv_semester_finance AS
SELECT s.id AS semester_id, ay.name AS academic_year, s.code AS semester_code,
  COALESCE((SELECT SUM(v.payable_amount) FROM v_invoice_balances v
            WHERE v.semester_id=s.id),0.00) AS total_tuition_due,
  COALESCE((SELECT SUM(p.amount) FROM payments p JOIN invoices i ON i.id=p.invoice_id
            WHERE i.semester_id=s.id),0.00) AS total_paid,
  COALESCE((SELECT SUM(p.amount) FROM payments p JOIN invoices i ON i.id=p.invoice_id
            WHERE i.semester_id=s.id AND p.fund_id IS NOT NULL),0.00) AS collected_via_ctsv,
  COALESCE((SELECT SUM(p.amount) FROM payments p JOIN invoices i ON i.id=p.invoice_id
            WHERE i.semester_id=s.id AND p.fund_id IS NULL),0.00) AS legacy_unassigned_paid,
  COALESCE((SELECT SUM(v.remaining_amount) FROM v_invoice_balances v
            WHERE v.semester_id=s.id),0.00) AS total_outstanding,
  COALESCE((SELECT SUM(r.amount) FROM ctsv_remittances r
            WHERE r.semester_id=s.id AND r.status='CONFIRMED'),0.00) AS remitted_to_school,
  (SELECT COUNT(*) FROM student_requests q
    WHERE q.created_at >= s.starts_on
      AND q.created_at < DATEADD('DAY',1,s.ends_on)) AS student_issue_count,
  (SELECT COUNT(*) FROM student_requests q
    WHERE q.created_at >= s.starts_on AND q.created_at < DATEADD('DAY',1,s.ends_on)
      AND q.status IN ('PENDING','PROCESSING')) AS unresolved_issue_count,
  (SELECT COUNT(DISTINCT q.id) FROM student_requests q
    JOIN student_request_review_events e ON e.request_id=q.id
    WHERE q.created_at >= s.starts_on AND q.created_at < DATEADD('DAY',1,s.ends_on)
      AND e.action='ESCALATE_TO_SCHOOL') AS escalated_issue_count
FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id;
-- Optional additive extensions for FE features absent from the original 47 tables.
-- Run on the selected V6 database, after 01,02,03. No USE/DROP or seed credentials.
CREATE TABLE IF NOT EXISTS campus_posts (
 id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
 created_by BIGINT NOT NULL,
 title VARCHAR(180) NOT NULL,
 summary VARCHAR(400) NOT NULL,
 content TEXT NOT NULL,
 category VARCHAR(40) NOT NULL,
 starts_at DATETIME NOT NULL,
 ends_at DATETIME NOT NULL,
 venue VARCHAR(180) NOT NULL,
 organizer VARCHAR(180) NOT NULL,
 status VARCHAR(40) NOT NULL DEFAULT 'DRAFT',
 published_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT fk_post_user FOREIGN KEY(created_by) REFERENCES users(id),
 CONSTRAINT chk_post_times CHECK(ends_at>starts_at)
);
CREATE TABLE IF NOT EXISTS event_follows (
 event_id BIGINT NOT NULL,
 user_id BIGINT NOT NULL,
 created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 PRIMARY KEY(event_id,user_id),
 CONSTRAINT fk_follow_event FOREIGN KEY(event_id) REFERENCES campus_posts(id),
 CONSTRAINT fk_follow_user FOREIGN KEY(user_id) REFERENCES users(id)
);
CREATE TABLE IF NOT EXISTS exam_schedules (
 id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
 section_id BIGINT NOT NULL,
 starts_at DATETIME NOT NULL,
 ends_at DATETIME NOT NULL,
 room VARCHAR(80) NOT NULL,
 exam_type VARCHAR(80) NOT NULL,
 status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
 note VARCHAR(1000) NULL,
 CONSTRAINT fk_exam_section FOREIGN KEY(section_id) REFERENCES course_sections(id),
 CONSTRAINT chk_exam_times CHECK(ends_at>starts_at)
);

-- Additive migration: preserve all original V6 tables and seed rows.
CREATE TABLE IF NOT EXISTS student_profile_photos (
 student_id BIGINT PRIMARY KEY,
 storage_key VARCHAR(100) NOT NULL,
 mime_type VARCHAR(40) NOT NULL,
 updated_by BIGINT NOT NULL,
 updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY (student_id) REFERENCES students(id),
 FOREIGN KEY (updated_by) REFERENCES users(id)
) ;

CREATE TABLE IF NOT EXISTS password_reset_tokens (
 id BIGINT PRIMARY KEY AUTO_INCREMENT,
 user_id BIGINT NOT NULL,
 token_hash CHAR(64) NOT NULL UNIQUE,
 expires_at DATETIME NOT NULL,
 used_at DATETIME NULL,
 delivery_status VARCHAR(12) NOT NULL DEFAULT 'PENDING',
 created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY (user_id) REFERENCES users(id),
 INDEX ix_password_reset_user (user_id, expires_at)
) ;

-- Normalized catalog compatibility fixture; actual MySQL migration is tested on a clone.
CREATE TABLE IF NOT EXISTS rooms (
 id BIGINT AUTO_INCREMENT PRIMARY KEY, code VARCHAR(80) NOT NULL UNIQUE,
 name VARCHAR(160) NOT NULL, capacity INT NULL, active BOOLEAN NOT NULL DEFAULT TRUE,
 CONSTRAINT chk_rooms_capacity CHECK(capacity IS NULL OR capacity>0)
);
CREATE TABLE IF NOT EXISTS exam_types (
 id BIGINT AUTO_INCREMENT PRIMARY KEY, code VARCHAR(40) NOT NULL UNIQUE,
 name VARCHAR(80) NOT NULL UNIQUE, active BOOLEAN NOT NULL DEFAULT TRUE
);
ALTER TABLE section_schedules ADD COLUMN IF NOT EXISTS room_id BIGINT REFERENCES rooms(id);
ALTER TABLE exam_schedules ADD COLUMN IF NOT EXISTS room_id BIGINT REFERENCES rooms(id);
ALTER TABLE exam_schedules ADD COLUMN IF NOT EXISTS exam_type_id BIGINT REFERENCES exam_types(id);
ALTER TABLE exam_schedules ADD COLUMN IF NOT EXISTS data_origin VARCHAR(16) DEFAULT 'SCHOOL' NOT NULL;
ALTER TABLE exam_schedules ADD COLUMN IF NOT EXISTS created_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL;
ALTER TABLE exam_schedules ADD COLUMN IF NOT EXISTS updated_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL;
ALTER TABLE section_schedules ADD CONSTRAINT IF NOT EXISTS chk_schedule_room_id CHECK(room_id IS NOT NULL);
ALTER TABLE exam_schedules ADD CONSTRAINT IF NOT EXISTS chk_exam_catalog_ids CHECK(room_id IS NOT NULL AND exam_type_id IS NOT NULL);

-- Invoice review workflow compatibility fixture.
-- Draft proposals are separate from issued invoices. Existing money/documents are untouched.

CREATE TABLE IF NOT EXISTS invoice_proposals (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    proposal_code VARCHAR(80) NOT NULL UNIQUE,
    student_id BIGINT NOT NULL,
    semester_id BIGINT NOT NULL,
    discount_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    prepared_by BIGINT NOT NULL,
    submitted_at DATETIME NULL,
    reviewed_by BIGINT NULL,
    reviewed_at DATETIME NULL,
    decision_note VARCHAR(700) NULL,
    note VARCHAR(700) NULL,
    invoice_id BIGINT NULL UNIQUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (student_id,semester_id),
    CONSTRAINT fk_proposal_student FOREIGN KEY(student_id) REFERENCES students(id),
    CONSTRAINT fk_proposal_semester FOREIGN KEY(semester_id) REFERENCES semesters(id),
    CONSTRAINT fk_proposal_preparer FOREIGN KEY(prepared_by) REFERENCES users(id),
    CONSTRAINT fk_proposal_reviewer FOREIGN KEY(reviewed_by) REFERENCES users(id),
    CONSTRAINT fk_proposal_invoice FOREIGN KEY(invoice_id) REFERENCES invoices(id),
    CONSTRAINT chk_proposal_discount CHECK(discount_amount>=0),
    CONSTRAINT chk_proposal_status CHECK(status IN ('DRAFT','SUBMITTED','APPROVED','RETURNED','REJECTED','ISSUED')),
    CONSTRAINT chk_proposal_submission CHECK(status='DRAFT' OR submitted_at IS NOT NULL),
    CONSTRAINT chk_proposal_decision CHECK(status NOT IN ('APPROVED','RETURNED','REJECTED','ISSUED') OR (reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL)),
    CONSTRAINT chk_proposal_issued CHECK((status='ISSUED' AND invoice_id IS NOT NULL) OR (status<>'ISSUED' AND invoice_id IS NULL))
);

CREATE TABLE IF NOT EXISTS invoice_proposal_items (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    proposal_id BIGINT NOT NULL,
    enrollment_id BIGINT NOT NULL,
    credits_at_proposal SMALLINT NOT NULL,
    unit_price_at_proposal DECIMAL(14,2) NOT NULL,
    UNIQUE (proposal_id,enrollment_id),
    CONSTRAINT fk_proposal_item_header FOREIGN KEY(proposal_id) REFERENCES invoice_proposals(id),
    CONSTRAINT fk_proposal_item_enrollment FOREIGN KEY(enrollment_id) REFERENCES enrollments(id),
    CONSTRAINT chk_proposal_item_credit CHECK(credits_at_proposal BETWEEN 1 AND 15),
    CONSTRAINT chk_proposal_item_price CHECK(unit_price_at_proposal>=0)
);

CREATE TABLE IF NOT EXISTS invoice_proposal_reviews (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    proposal_id BIGINT NOT NULL,
    actor_user_id BIGINT NOT NULL,
    action VARCHAR(20) NOT NULL,
    from_status VARCHAR(20) NULL,
    to_status VARCHAR(20) NOT NULL,
    note VARCHAR(700) NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_proposal_review_header FOREIGN KEY(proposal_id) REFERENCES invoice_proposals(id),
    CONSTRAINT fk_proposal_review_actor FOREIGN KEY(actor_user_id) REFERENCES users(id)
);
