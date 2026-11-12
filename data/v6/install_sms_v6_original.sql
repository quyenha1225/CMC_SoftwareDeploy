-- =============================================================================
-- STUDENT MANAGEMENT SYSTEM | 01_SCHEMA_ALL.sql (V6)
-- 1 FILE CHO TOAN BO CREATE TABLE, PK, UNIQUE, FK, CHECK (47 BANG), KHONG CO ADMIN RIENG
-- MySQL 8.0.16+ (InnoDB). Muc tieu 47 bang voi CSDL moi, khong co Google OAuth.
--
-- CACH CHAY: 01_SCHEMA_ALL.sql -> 02_SEED_DEMO.sql -> 03_QUERIES_CHECK.sql
-- KHONG CO DROP TABLE / TRUNCATE / DELETE. DDL khong rollback nhu transaction DML.
-- CHAY LAI: CREATE TABLE IF NOT EXISTS + ALTER co kiem tra metadata.
-- ROLE PRINCIPAL = BAN GIAM HIEU (quan tri cao nhat), KHONG TAO role SYS_ADMIN.
-- HO SO GOC admission_applications + admission_review_events, KHONG CO bang studentApprovals rieng.
-- Can sao luu neu sms_v6_original da co du lieu; schema cu KHAC V2/V3/V4 can migration rieng.
-- IF NOT EXISTS khong tu sua bang cu co cot/loai du lieu sai.
-- TEP TAI LIEU: metadata (storage_key) trong CSDL, file that luu private storage.
-- CAC QUY TAC QUYEN + CHUYEN TRANG THAI VAN PHAI KIEM TRA TAI BACKEND.
-- =============================================================================
SET NAMES utf8mb4;

-- 1. 28 BANG CHUC NANG GOC
-- ============================================================================
-- STUDENT MANAGEMENT SYSTEM (SMS) | 01 - DATABASE SCHEMA
-- MySQL 8.0.16+ / MySQL Community compatible, InnoDB, UTF-8.
-- Designed for a NEW database or repeated runs on THIS exact schema version.
-- Non-destructive: NO DROP TABLE / DROP DATABASE / TRUNCATE.
-- NOTE: CREATE TABLE IF NOT EXISTS does NOT migrate an incompatible old table.
-- ============================================================================

CREATE DATABASE IF NOT EXISTS sms_v6_original
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE sms_v6_original;

-- ======================= Identity and access ================================
CREATE TABLE IF NOT EXISTS users (
    id BIGINT NOT NULL AUTO_INCREMENT,
    username VARCHAR(80) NOT NULL,
    email VARCHAR(190) NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(160) NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_users_username (username),
    UNIQUE KEY uq_users_email (email)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS roles (
    id BIGINT NOT NULL AUTO_INCREMENT,
    code VARCHAR(40) NOT NULL,
    description VARCHAR(160) NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_roles_code (code)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS user_roles (
    user_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,
    PRIMARY KEY (user_id, role_id),
    CONSTRAINT fk_user_roles_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_user_roles_role FOREIGN KEY (role_id) REFERENCES roles(id)
) ENGINE=InnoDB;

-- ======================= Education organization =============================
CREATE TABLE IF NOT EXISTS faculties (
    id BIGINT NOT NULL AUTO_INCREMENT,
    code VARCHAR(30) NOT NULL,
    name VARCHAR(180) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_faculties_code (code)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS majors (
    id BIGINT NOT NULL AUTO_INCREMENT,
    faculty_id BIGINT NOT NULL,
    code VARCHAR(30) NOT NULL,
    name VARCHAR(180) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_majors_code (code),
    UNIQUE KEY uq_majors_faculty_name (faculty_id, name),
    CONSTRAINT fk_majors_faculty FOREIGN KEY (faculty_id) REFERENCES faculties(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS cohorts (
    id BIGINT NOT NULL AUTO_INCREMENT,
    code VARCHAR(30) NOT NULL,
    start_year SMALLINT NOT NULL,
    end_year SMALLINT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_cohorts_code (code),
    CONSTRAINT chk_cohorts_dates CHECK (end_year IS NULL OR end_year >= start_year)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS academic_classes (
    id BIGINT NOT NULL AUTO_INCREMENT,
    major_id BIGINT NOT NULL,
    cohort_id BIGINT NOT NULL,
    code VARCHAR(50) NOT NULL,
    name VARCHAR(180) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_academic_classes_code (code),
    CONSTRAINT fk_academic_classes_major FOREIGN KEY (major_id) REFERENCES majors(id),
    CONSTRAINT fk_academic_classes_cohort FOREIGN KEY (cohort_id) REFERENCES cohorts(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS students (
    id BIGINT NOT NULL AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    student_code VARCHAR(40) NOT NULL,
    class_id BIGINT NOT NULL,
    date_of_birth DATE NULL,
    phone VARCHAR(24) NULL,
    address VARCHAR(400) NULL,
    status ENUM('STUDYING','SUSPENDED','WITHDRAWN','GRADUATED') NOT NULL DEFAULT 'STUDYING',
    enrolled_on DATE NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_students_user (user_id),
    UNIQUE KEY uq_students_code (student_code),
    KEY ix_students_class (class_id),
    CONSTRAINT fk_students_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_students_class FOREIGN KEY (class_id) REFERENCES academic_classes(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS lecturers (
    id BIGINT NOT NULL AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    faculty_id BIGINT NOT NULL,
    lecturer_code VARCHAR(40) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_lecturers_user (user_id),
    UNIQUE KEY uq_lecturers_code (lecturer_code),
    CONSTRAINT fk_lecturers_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_lecturers_faculty FOREIGN KEY (faculty_id) REFERENCES faculties(id)
) ENGINE=InnoDB;

-- ======================= Academic catalog ===================================
CREATE TABLE IF NOT EXISTS academic_years (
    id BIGINT NOT NULL AUTO_INCREMENT,
    name VARCHAR(30) NOT NULL,
    starts_on DATE NOT NULL,
    ends_on DATE NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_academic_years_name (name),
    CONSTRAINT chk_academic_year_dates CHECK (ends_on >= starts_on)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS semesters (
    id BIGINT NOT NULL AUTO_INCREMENT,
    academic_year_id BIGINT NOT NULL,
    code VARCHAR(30) NOT NULL,
    starts_on DATE NOT NULL,
    ends_on DATE NOT NULL,
    registration_from DATETIME NULL,
    registration_to DATETIME NULL,
    status ENUM('PLANNED','OPEN','CLOSED') NOT NULL DEFAULT 'PLANNED',
    PRIMARY KEY (id),
    UNIQUE KEY uq_semesters_year_code (academic_year_id,code),
    CONSTRAINT chk_semesters_dates CHECK (ends_on >= starts_on),
    CONSTRAINT chk_semesters_window CHECK (
      registration_from IS NULL OR registration_to IS NULL OR registration_to >= registration_from
    ),
    CONSTRAINT fk_semesters_year FOREIGN KEY (academic_year_id) REFERENCES academic_years(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS courses (
    id BIGINT NOT NULL AUTO_INCREMENT,
    course_code VARCHAR(40) NOT NULL,
    title VARCHAR(200) NOT NULL,
    credits SMALLINT NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (id),
    UNIQUE KEY uq_courses_code (course_code),
    CONSTRAINT chk_courses_credits CHECK (credits BETWEEN 1 AND 15)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS curricula (
    id BIGINT NOT NULL AUTO_INCREMENT,
    major_id BIGINT NOT NULL,
    cohort_id BIGINT NOT NULL,
    title VARCHAR(180) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_curricula_major_cohort (major_id,cohort_id),
    CONSTRAINT fk_curricula_major FOREIGN KEY (major_id) REFERENCES majors(id),
    CONSTRAINT fk_curricula_cohort FOREIGN KEY (cohort_id) REFERENCES cohorts(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS curriculum_courses (
    curriculum_id BIGINT NOT NULL,
    course_id BIGINT NOT NULL,
    suggested_semester SMALLINT NULL,
    required_course BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (curriculum_id,course_id),
    CONSTRAINT chk_curriculum_courses_sem CHECK (suggested_semester IS NULL OR suggested_semester BETWEEN 1 AND 12),
    CONSTRAINT fk_curriculum_courses_curriculum FOREIGN KEY (curriculum_id) REFERENCES curricula(id),
    CONSTRAINT fk_curriculum_courses_course FOREIGN KEY (course_id) REFERENCES courses(id)
) ENGINE=InnoDB;

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
    UNIQUE KEY uq_course_sections_sem_code (semester_id,section_code),
    KEY ix_course_sections_course (course_id),
    KEY ix_course_sections_lecturer (lecturer_id),
    CONSTRAINT chk_course_sections_capacity CHECK (capacity > 0),
    CONSTRAINT chk_course_sections_weights CHECK (
      attendance_weight >= 0 AND midterm_weight >= 0 AND final_weight >= 0 AND
      attendance_weight + midterm_weight + final_weight = 100.00
    ),
    CONSTRAINT fk_sections_semester FOREIGN KEY (semester_id) REFERENCES semesters(id),
    CONSTRAINT fk_sections_course FOREIGN KEY (course_id) REFERENCES courses(id),
    CONSTRAINT fk_sections_lecturer FOREIGN KEY (lecturer_id) REFERENCES lecturers(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS section_schedules (
    id BIGINT NOT NULL AUTO_INCREMENT,
    section_id BIGINT NOT NULL,
    day_of_week TINYINT NOT NULL, -- ISO weekday 1=Mon ... 7=Sun
    starts_at TIME NOT NULL,
    ends_at TIME NOT NULL,
    room VARCHAR(80) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_section_schedules_slot (section_id,day_of_week,starts_at,ends_at),
    KEY ix_schedules_room_day (room,day_of_week,starts_at),
    CONSTRAINT chk_section_schedules_day CHECK (day_of_week BETWEEN 1 AND 7),
    CONSTRAINT chk_section_schedules_time CHECK (ends_at > starts_at),
    CONSTRAINT fk_section_schedules_section FOREIGN KEY (section_id) REFERENCES course_sections(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS enrollments (
    id BIGINT NOT NULL AUTO_INCREMENT,
    student_id BIGINT NOT NULL,
    section_id BIGINT NOT NULL,
    status ENUM('REGISTERED','CANCELLED','COMPLETED') NOT NULL DEFAULT 'REGISTERED',
    registered_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_enrollments_student_section (student_id,section_id),
    KEY ix_enrollments_section (section_id),
    CONSTRAINT fk_enrollments_student FOREIGN KEY (student_id) REFERENCES students(id),
    CONSTRAINT fk_enrollments_section FOREIGN KEY (section_id) REFERENCES course_sections(id)
) ENGINE=InnoDB;

-- ======================= Grading workflow ===================================
CREATE TABLE IF NOT EXISTS grade_sheets (
    id BIGINT NOT NULL AUTO_INCREMENT,
    section_id BIGINT NOT NULL,
    status ENUM('DRAFT','SUBMITTED','VERIFIED','RETURNED','APPROVED','PUBLISHED') NOT NULL DEFAULT 'DRAFT',
    published_at DATETIME NULL,
    version_no INT NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    UNIQUE KEY uq_grade_sheets_section (section_id),
    CONSTRAINT chk_grade_sheets_version CHECK (version_no > 0),
    CONSTRAINT fk_grade_sheets_section FOREIGN KEY (section_id) REFERENCES course_sections(id)
) ENGINE=InnoDB;

-- One score record per enrollment. Grade sheet is reached through enrollment.section_id,
-- avoiding duplicate sheet_id on each grade record and inconsistent cross-references.
-- Weighted total is computed in VIEW v_student_results (not redundantly stored).
-- The view exposes PUBLISHED grades only; staff draft access is through protected APIs.
CREATE TABLE IF NOT EXISTS grades (
    id BIGINT NOT NULL AUTO_INCREMENT,
    enrollment_id BIGINT NOT NULL,
    attendance_score DECIMAL(4,2) NULL,
    midterm_score DECIMAL(4,2) NULL,
    final_score DECIMAL(4,2) NULL,
    remark VARCHAR(500) NULL,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_grades_enrollment (enrollment_id),
    CONSTRAINT chk_grades_attendance CHECK (attendance_score IS NULL OR attendance_score BETWEEN 0 AND 10),
    CONSTRAINT chk_grades_midterm CHECK (midterm_score IS NULL OR midterm_score BETWEEN 0 AND 10),
    CONSTRAINT chk_grades_final CHECK (final_score IS NULL OR final_score BETWEEN 0 AND 10),
    CONSTRAINT fk_grades_enrollment FOREIGN KEY (enrollment_id) REFERENCES enrollments(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS grade_reviews (
    id BIGINT NOT NULL AUTO_INCREMENT,
    sheet_id BIGINT NOT NULL,
    actor_user_id BIGINT NOT NULL,
    action ENUM('SUBMIT','VERIFY','RETURN','APPROVE','PUBLISH') NOT NULL,
    note VARCHAR(700) NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    event_key VARCHAR(100) NULL, -- used ONLY for idempotent imported events
    PRIMARY KEY (id),
    UNIQUE KEY uq_grade_reviews_event (event_key),
    KEY ix_grade_reviews_sheet_time (sheet_id,created_at),
    CONSTRAINT fk_grade_reviews_sheet FOREIGN KEY (sheet_id) REFERENCES grade_sheets(id),
    CONSTRAINT fk_grade_reviews_user FOREIGN KEY (actor_user_id) REFERENCES users(id)
) ENGINE=InnoDB;

-- ======================= Tuition and payment ================================
CREATE TABLE IF NOT EXISTS tuition_rates (
    id BIGINT NOT NULL AUTO_INCREMENT,
    semester_id BIGINT NOT NULL,
    price_per_credit DECIMAL(14,2) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_tuition_rates_semester (semester_id),
    CONSTRAINT chk_tuition_rates_price CHECK (price_per_credit >= 0),
    CONSTRAINT fk_tuition_rates_semester FOREIGN KEY (semester_id) REFERENCES semesters(id)
) ENGINE=InnoDB;

-- Invoice total and paid/unpaid status are NOT stored redundantly; see v_invoice_balances.
CREATE TABLE IF NOT EXISTS invoices (
    id BIGINT NOT NULL AUTO_INCREMENT,
    student_id BIGINT NOT NULL,
    semester_id BIGINT NOT NULL,
    discount_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    issued_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_invoices_student_semester (student_id,semester_id),
    CONSTRAINT chk_invoices_discount CHECK (discount_amount >= 0),
    CONSTRAINT fk_invoices_student FOREIGN KEY (student_id) REFERENCES students(id),
    CONSTRAINT fk_invoices_semester FOREIGN KEY (semester_id) REFERENCES semesters(id)
) ENGINE=InnoDB;

-- Credits and unit price are an intentional INVOICE SNAPSHOT: when course credits
-- or tuition rates change later, old invoices must keep original historical values.
CREATE TABLE IF NOT EXISTS invoice_items (
    id BIGINT NOT NULL AUTO_INCREMENT,
    invoice_id BIGINT NOT NULL,
    enrollment_id BIGINT NOT NULL,
    credits_at_issue SMALLINT NOT NULL,
    unit_price_at_issue DECIMAL(14,2) NOT NULL,
    amount DECIMAL(14,2) GENERATED ALWAYS AS (credits_at_issue * unit_price_at_issue) STORED,
    PRIMARY KEY (id),
    UNIQUE KEY uq_invoice_items_enrollment (enrollment_id),
    KEY ix_invoice_items_invoice (invoice_id),
    CONSTRAINT chk_invoice_items_credits CHECK (credits_at_issue BETWEEN 1 AND 15),
    CONSTRAINT chk_invoice_items_price CHECK (unit_price_at_issue >= 0),
    CONSTRAINT fk_invoice_items_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id),
    CONSTRAINT fk_invoice_items_enrollment FOREIGN KEY (enrollment_id) REFERENCES enrollments(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS payments (
    id BIGINT NOT NULL AUTO_INCREMENT,
    invoice_id BIGINT NOT NULL,
    recorded_by BIGINT NOT NULL,
    amount DECIMAL(14,2) NOT NULL,
    paid_at DATETIME NOT NULL,
    reference_no VARCHAR(100) NOT NULL,
    note VARCHAR(400) NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_payments_reference (reference_no),
    KEY ix_payments_invoice (invoice_id),
    CONSTRAINT chk_payments_amount CHECK (amount > 0),
    CONSTRAINT fk_payments_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id),
    CONSTRAINT fk_payments_recorded_by FOREIGN KEY (recorded_by) REFERENCES users(id)
) ENGINE=InnoDB;

-- ======================= Requests, notices, audit ===========================
CREATE TABLE IF NOT EXISTS student_requests (
    id BIGINT NOT NULL AUTO_INCREMENT,
    request_code VARCHAR(60) NOT NULL,
    student_id BIGINT NOT NULL,
    request_type ENUM('PROFILE_UPDATE','STUDY_STATUS','GRADE_QUESTION') NOT NULL,
    content TEXT NOT NULL,
    status ENUM('PENDING','PROCESSING','RESOLVED','REJECTED') NOT NULL DEFAULT 'PENDING',
    handled_by BIGINT NULL,
    response TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    handled_at DATETIME NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_student_requests_code (request_code),
    KEY ix_student_requests_student_status (student_id,status),
    CONSTRAINT fk_student_requests_student FOREIGN KEY (student_id) REFERENCES students(id),
    CONSTRAINT fk_student_requests_handler FOREIGN KEY (handled_by) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS notifications (
    id BIGINT NOT NULL AUTO_INCREMENT,
    notification_code VARCHAR(60) NOT NULL,
    created_by BIGINT NULL,
    title VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_notifications_code (notification_code),
    CONSTRAINT fk_notifications_created_by FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS notification_recipients (
    notification_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    read_at DATETIME NULL,
    PRIMARY KEY (notification_id,user_id),
    CONSTRAINT fk_notification_recipients_notification FOREIGN KEY (notification_id) REFERENCES notifications(id) ON DELETE CASCADE,
    CONSTRAINT fk_notification_recipients_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB;

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
    UNIQUE KEY uq_audit_logs_event (event_key),
    KEY ix_audit_logs_entity (entity_type,entity_id),
    CONSTRAINT fk_audit_logs_actor FOREIGN KEY (actor_user_id) REFERENCES users(id)
) ENGINE=InnoDB;

-- ======================= Derived/read-only views ============================
-- Re-running views replaces definitions; does not duplicate rows or delete tables.






-- CRITICAL APPLICATION-SERVICE TRANSACTION RULES (not all expressible via FK/CHECK):
-- 1. Check permissions (RBAC), enrollment period, capacity and schedule collisions.
-- 2. Do not register a student twice for the same course+semester via different sections.
-- 3. A grade belongs only to an enrollment in the lecturer's assigned section.
-- 4. Enforce grade-sheet state transitions: DRAFT->SUBMITTED->VERIFIED->APPROVED->PUBLISHED,
--    RETURNED -> DRAFT; grades must not be edited after SUBMITTED without returning.
-- 5. Check invoice line's enrollment.student_id and semester match parent invoice.
-- 6. Check discount <= invoice sum and prevent overpayments unless refunds/credit modeled.
-- 7. For POST operations use transactions and concurrency controls in Spring Boot.


-- 2. 12 BANG BO SUNG CTSV + QUY + EMAIL TRUONG (V4)
-- =============================================================================
-- SMS V4 | HO SO TRUC TUYEN -> CTSV -> NHA TRUONG -> MA SV + EMAIL TRUONG
-- CTSV thu hoc phi -> quy CTSV -> ban giao/bao cao hoc ky
-- MySQL 8.0.16+ (CHECK constraints). Run AFTER 01_schema_sms_V2_goc.sql.
-- Can run with V2 (28 tables), or V3 (36 tables) as starting point.
-- No Google login, no Google identity table is created by this migration.
-- NO DROP / TRUNCATE / DELETE: back up sms_v6_original before running.
-- CREATE TABLE IF NOT EXISTS does NOT upgrade existing table definitions;
-- targeted column/ENUM changes below cover V3 -> V4.
-- =============================================================================
USE sms_v6_original;
SET NAMES utf8mb4;

-- A) Legacy V3 admissions tables (NOT auth_identities/Google OAuth).
-- On a V3 database these CREATE commands are no-ops; definitions are upgraded below.
CREATE TABLE IF NOT EXISTS admission_periods (
    id BIGINT NOT NULL AUTO_INCREMENT,
    code VARCHAR(50) NOT NULL,
    title VARCHAR(180) NOT NULL,
    cohort_id BIGINT NOT NULL,
    opens_at DATETIME NOT NULL,
    closes_at DATETIME NOT NULL,
    status ENUM('PLANNED','OPEN','CLOSED') NOT NULL DEFAULT 'PLANNED',
    PRIMARY KEY (id),
    UNIQUE KEY uq_admission_periods_code (code),
    CONSTRAINT chk_admission_period_window CHECK (closes_at > opens_at),
    CONSTRAINT fk_admission_period_cohort FOREIGN KEY (cohort_id) REFERENCES cohorts(id)
) ENGINE=InnoDB;

-- Status: DRAFT -> SUBMITTED -> IN_REVIEW -> CTSV_APPROVED -> SENT_TO_SCHOOL -> SCHOOL_APPROVED -> PDT_VERIFIED -> ENROLLED
-- Correction: IN_REVIEW -> CHANGES_REQUESTED -> SUBMITTED; school can return a dossier to CTSV
-- Rejection: IN_REVIEW -> CTSV_REJECTED
-- Role permissions/transitions must be enforced by a Spring Boot service.
CREATE TABLE IF NOT EXISTS admission_applications (
    id BIGINT NOT NULL AUTO_INCREMENT,
    application_code VARCHAR(60) NOT NULL,
    applicant_user_id BIGINT NOT NULL,
    period_id BIGINT NOT NULL,
    major_id BIGINT NOT NULL,
    phone VARCHAR(24) NULL,
    address VARCHAR(400) NULL,
    date_of_birth DATE NULL,
    status ENUM('DRAFT','SUBMITTED','IN_REVIEW','CHANGES_REQUESTED',
                'CTSV_APPROVED','CTSV_REJECTED','SENT_TO_SCHOOL','SCHOOL_APPROVED',
                'SCHOOL_REJECTED','PDT_VERIFIED','ENROLLED')
      NOT NULL DEFAULT 'DRAFT',
    assigned_ctsv_user_id BIGINT NULL,
    student_id BIGINT NULL,
    submitted_at DATETIME NULL,
    changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_admission_app_code (application_code),
    UNIQUE KEY uq_admission_app_person_period (applicant_user_id, period_id),
    UNIQUE KEY uq_admission_app_student (student_id),
    KEY ix_admission_app_status (period_id, status),
    KEY ix_admission_app_assigned (assigned_ctsv_user_id, status),
    CONSTRAINT fk_admission_app_user FOREIGN KEY (applicant_user_id) REFERENCES users(id),
    CONSTRAINT fk_admission_app_period FOREIGN KEY (period_id) REFERENCES admission_periods(id),
    CONSTRAINT fk_admission_app_major FOREIGN KEY (major_id) REFERENCES majors(id),
    CONSTRAINT fk_admission_app_ctsv FOREIGN KEY (assigned_ctsv_user_id) REFERENCES users(id),
    CONSTRAINT fk_admission_app_student FOREIGN KEY (student_id) REFERENCES students(id),
    CONSTRAINT chk_admission_enrolled_link CHECK (status <> 'ENROLLED' OR student_id IS NOT NULL)
) ENGINE=InnoDB;

-- Configurable checklist per admission period; prevents hardcoding required PDFs.
CREATE TABLE IF NOT EXISTS admission_document_requirements (
    period_id BIGINT NOT NULL,
    document_type VARCHAR(50) NOT NULL,
    label VARCHAR(160) NOT NULL,
    is_required BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (period_id, document_type),
    CONSTRAINT fk_admission_requirement_period FOREIGN KEY (period_id)
      REFERENCES admission_periods(id)
) ENGINE=InnoDB;

-- Store metadata and a PRIVATE storage key only. Files live outside MySQL.
-- Revisions allow re-upload without overwriting the prior version.
CREATE TABLE IF NOT EXISTS admission_documents (
    id BIGINT NOT NULL AUTO_INCREMENT,
    application_id BIGINT NOT NULL,
    document_type VARCHAR(50) NOT NULL,
    revision_no SMALLINT NOT NULL DEFAULT 1,
    file_name VARCHAR(255) NOT NULL,
    storage_key VARCHAR(400) NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    size_bytes BIGINT NOT NULL,
    sha256 CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NULL,
    status ENUM('PENDING','VERIFIED','REJECTED') NOT NULL DEFAULT 'PENDING',
    checked_by BIGINT NULL,
    checked_at DATETIME NULL,
    rejection_reason VARCHAR(500) NULL,
    uploaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_admission_doc_version (application_id, document_type, revision_no),
    UNIQUE KEY uq_admission_doc_storage_key (storage_key),
    CONSTRAINT chk_admission_doc_revision CHECK (revision_no > 0),
    CONSTRAINT chk_admission_doc_size CHECK (size_bytes > 0 AND size_bytes <= 10485760),
    CONSTRAINT fk_admission_doc_app FOREIGN KEY (application_id) REFERENCES admission_applications(id),
    CONSTRAINT fk_admission_doc_checker FOREIGN KEY (checked_by) REFERENCES users(id)
) ENGINE=InnoDB;

-- Immutable review trail; status column in admissions is the current snapshot.
CREATE TABLE IF NOT EXISTS admission_review_events (
    id BIGINT NOT NULL AUTO_INCREMENT,
    application_id BIGINT NOT NULL,
    actor_user_id BIGINT NOT NULL,
    event_type ENUM('SUBMIT','START_REVIEW','REQUEST_CHANGES',
                    'APPROVE','REJECT','SUBMIT_TO_SCHOOL','SCHOOL_APPROVE','SCHOOL_REJECT',
                    'PDT_VERIFY','ENROLL') NOT NULL,
    from_status VARCHAR(30) NOT NULL,
    to_status VARCHAR(30) NOT NULL,
    note VARCHAR(700) NULL,
    event_key VARCHAR(100) NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_admission_review_event_key (event_key),
    KEY ix_admission_review_app_time (application_id, created_at),
    CONSTRAINT fk_admission_review_application FOREIGN KEY (application_id) REFERENCES admission_applications(id),
    CONSTRAINT fk_admission_review_user FOREIGN KEY (actor_user_id) REFERENCES users(id)
) ENGINE=InnoDB;

-- Existing students can submit supporting documents to CTSV for their requests.
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
    UNIQUE KEY uq_student_request_file_key (storage_key),
    KEY ix_student_request_files_request (request_id),
    CONSTRAINT chk_student_request_file_size CHECK (size_bytes > 0 AND size_bytes <= 10485760),
    CONSTRAINT fk_student_request_file_request FOREIGN KEY (request_id) REFERENCES student_requests(id),
    CONSTRAINT fk_student_request_file_uploader FOREIGN KEY (uploaded_by) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS student_request_review_events (
    id BIGINT NOT NULL AUTO_INCREMENT,
    request_id BIGINT NOT NULL,
    reviewer_user_id BIGINT NOT NULL,
    action ENUM('ASSIGN','ASK_MORE_INFO','RESOLVE','REJECT','REOPEN',
                'ESCALATE_TO_SCHOOL','SCHOOL_FEEDBACK','RETURN_TO_CTSV') NOT NULL,
    note VARCHAR(700) NULL,
    event_key VARCHAR(100) NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_student_request_review_key (event_key),
    KEY ix_student_request_review_timeline (request_id, created_at),
    CONSTRAINT fk_student_request_review_request FOREIGN KEY (request_id) REFERENCES student_requests(id),
    CONSTRAINT fk_student_request_review_reviewer FOREIGN KEY (reviewer_user_id) REFERENCES users(id)
) ENGINE=InnoDB;

-- Useful read-only view: counts latest uploaded revision per required document type.
-- A dossier is only complete when every required type has a latest VERIFIED revision.




-- Extend admission_applications.status if the additional V4 value is missing (V3 migration support)
SET @sql := (SELECT IF(COUNT(*)=1 AND SUM(COLUMN_TYPE LIKE '%''SENT_TO_SCHOOL''%')=0,
  'ALTER TABLE `admission_applications` MODIFY COLUMN `status` ENUM(''DRAFT'',''SUBMITTED'',''IN_REVIEW'',''CHANGES_REQUESTED'',''CTSV_APPROVED'',''CTSV_REJECTED'',''SENT_TO_SCHOOL'',''SCHOOL_APPROVED'',''SCHOOL_REJECTED'',''PDT_VERIFIED'',''ENROLLED'') NOT NULL DEFAULT ''DRAFT''',
  'SELECT ''admission_applications.status already V4'' AS info')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='admission_applications' AND COLUMN_NAME='status');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
-- Extend admission_review_events.event_type if the additional V4 value is missing (V3 migration support)
SET @sql := (SELECT IF(COUNT(*)=1 AND SUM(COLUMN_TYPE LIKE '%''SUBMIT_TO_SCHOOL''%')=0,
  'ALTER TABLE `admission_review_events` MODIFY COLUMN `event_type` ENUM(''SUBMIT'',''START_REVIEW'',''REQUEST_CHANGES'',''APPROVE'',''REJECT'',''SUBMIT_TO_SCHOOL'',''SCHOOL_APPROVE'',''SCHOOL_REJECT'',''PDT_VERIFY'',''ENROLL'') NOT NULL DEFAULT ''SUBMIT''',
  'SELECT ''admission_review_events.event_type already V4'' AS info')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='admission_review_events' AND COLUMN_NAME='event_type');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
-- Extend student_requests.request_type if the additional V4 value is missing (V3 migration support)
SET @sql := (SELECT IF(COUNT(*)=1 AND SUM(COLUMN_TYPE LIKE '%''TUITION_QUESTION''%')=0,
  'ALTER TABLE `student_requests` MODIFY COLUMN `request_type` ENUM(''PROFILE_UPDATE'',''STUDY_STATUS'',''GRADE_QUESTION'',''TUITION_QUESTION'',''DOCUMENT_REQUEST'',''STUDENT_SUPPORT'',''COMPLAINT'',''OTHER'') NOT NULL DEFAULT ''PROFILE_UPDATE''',
  'SELECT ''student_requests.request_type already V4'' AS info')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='student_requests' AND COLUMN_NAME='request_type');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
-- Extend student_request_review_events.action if the additional V4 value is missing (V3 migration support)
SET @sql := (SELECT IF(COUNT(*)=1 AND SUM(COLUMN_TYPE LIKE '%''ESCALATE_TO_SCHOOL''%')=0,
  'ALTER TABLE `student_request_review_events` MODIFY COLUMN `action` ENUM(''ASSIGN'',''ASK_MORE_INFO'',''RESOLVE'',''REJECT'',''REOPEN'',''ESCALATE_TO_SCHOOL'',''SCHOOL_FEEDBACK'',''RETURN_TO_CTSV'') NOT NULL',
  'SELECT ''student_request_review_events.action already V4'' AS info')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='student_request_review_events' AND COLUMN_NAME='action');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
-- student_request_review_events.school_recipient_user_id
SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `student_request_review_events` ADD COLUMN `school_recipient_user_id` BIGINT NULL',
  'SELECT ''student_request_review_events.school_recipient_user_id already exists'' AS info')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='student_request_review_events' AND COLUMN_NAME='school_recipient_user_id');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := (SELECT IF(COUNT(*)=0,
 'ALTER TABLE `student_request_review_events` ADD CONSTRAINT `fk_ctsv_request_escalation_recipient` FOREIGN KEY (`school_recipient_user_id`) REFERENCES `users`(`id`)',
 'SELECT ''CTSV escalation recipient FK already exists'' AS info')
 FROM information_schema.TABLE_CONSTRAINTS
 WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME='student_request_review_events'
   AND CONSTRAINT_NAME='fk_ctsv_request_escalation_recipient');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- B) Supplement student personal details without duplicating users.full_name/email,
-- or existing students.phone/date_of_birth/address. Addresses in admissions are
-- an immutable submission snapshot; student details are current confirmed values.
-- students.gender
SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `students` ADD COLUMN `gender` ENUM(''MALE'',''FEMALE'',''OTHER'',''UNDISCLOSED'') NULL',
  'SELECT ''students.gender already exists'' AS info')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='students' AND COLUMN_NAME='gender');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- students.place_of_birth
SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `students` ADD COLUMN `place_of_birth` VARCHAR(200) NULL',
  'SELECT ''students.place_of_birth already exists'' AS info')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='students' AND COLUMN_NAME='place_of_birth');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- students.hometown
SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `students` ADD COLUMN `hometown` VARCHAR(250) NULL',
  'SELECT ''students.hometown already exists'' AS info')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='students' AND COLUMN_NAME='hometown');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- students.permanent_address
SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `students` ADD COLUMN `permanent_address` VARCHAR(500) NULL',
  'SELECT ''students.permanent_address already exists'' AS info')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='students' AND COLUMN_NAME='permanent_address');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- students.current_address
SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `students` ADD COLUMN `current_address` VARCHAR(500) NULL',
  'SELECT ''students.current_address already exists'' AS info')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='students' AND COLUMN_NAME='current_address');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- students.nationality
SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `students` ADD COLUMN `nationality` VARCHAR(100) NULL',
  'SELECT ''students.nationality already exists'' AS info')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='students' AND COLUMN_NAME='nationality');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- students.guardian_full_name
SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `students` ADD COLUMN `guardian_full_name` VARCHAR(160) NULL',
  'SELECT ''students.guardian_full_name already exists'' AS info')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='students' AND COLUMN_NAME='guardian_full_name');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- students.guardian_phone
SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `students` ADD COLUMN `guardian_phone` VARCHAR(24) NULL',
  'SELECT ''students.guardian_phone already exists'' AS info')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='students' AND COLUMN_NAME='guardian_phone');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- admission_applications.legal_full_name
SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `admission_applications` ADD COLUMN `legal_full_name` VARCHAR(160) NULL',
  'SELECT ''admission_applications.legal_full_name already exists'' AS info')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='admission_applications' AND COLUMN_NAME='legal_full_name');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- admission_applications.personal_email
SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `admission_applications` ADD COLUMN `personal_email` VARCHAR(190) NULL',
  'SELECT ''admission_applications.personal_email already exists'' AS info')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='admission_applications' AND COLUMN_NAME='personal_email');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- admission_applications.gender
SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `admission_applications` ADD COLUMN `gender` ENUM(''MALE'',''FEMALE'',''OTHER'',''UNDISCLOSED'') NULL',
  'SELECT ''admission_applications.gender already exists'' AS info')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='admission_applications' AND COLUMN_NAME='gender');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- admission_applications.place_of_birth
SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `admission_applications` ADD COLUMN `place_of_birth` VARCHAR(200) NULL',
  'SELECT ''admission_applications.place_of_birth already exists'' AS info')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='admission_applications' AND COLUMN_NAME='place_of_birth');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- admission_applications.hometown
SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `admission_applications` ADD COLUMN `hometown` VARCHAR(250) NULL',
  'SELECT ''admission_applications.hometown already exists'' AS info')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='admission_applications' AND COLUMN_NAME='hometown');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- admission_applications.permanent_address
SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `admission_applications` ADD COLUMN `permanent_address` VARCHAR(500) NULL',
  'SELECT ''admission_applications.permanent_address already exists'' AS info')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='admission_applications' AND COLUMN_NAME='permanent_address');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- admission_applications.current_address
SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `admission_applications` ADD COLUMN `current_address` VARCHAR(500) NULL',
  'SELECT ''admission_applications.current_address already exists'' AS info')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='admission_applications' AND COLUMN_NAME='current_address');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- admission_applications.nationality
SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `admission_applications` ADD COLUMN `nationality` VARCHAR(100) NULL',
  'SELECT ''admission_applications.nationality already exists'' AS info')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='admission_applications' AND COLUMN_NAME='nationality');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- admission_applications.guardian_full_name
SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `admission_applications` ADD COLUMN `guardian_full_name` VARCHAR(160) NULL',
  'SELECT ''admission_applications.guardian_full_name already exists'' AS info')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='admission_applications' AND COLUMN_NAME='guardian_full_name');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- admission_applications.guardian_phone
SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `admission_applications` ADD COLUMN `guardian_phone` VARCHAR(24) NULL',
  'SELECT ''admission_applications.guardian_phone already exists'' AS info')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='admission_applications' AND COLUMN_NAME='guardian_phone');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;


-- C) CTSV fund boxes. No bank credentials and no balance cache stored.
CREATE TABLE IF NOT EXISTS ctsv_funds (
  id BIGINT NOT NULL AUTO_INCREMENT,
  code VARCHAR(50) NOT NULL,
  name VARCHAR(180) NOT NULL,
  channel ENUM('CASH','BANK_TRANSFER') NOT NULL,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY(id), UNIQUE KEY uq_ctsv_fund_code(code)
) ENGINE=InnoDB;

-- payments already stores amount, invoice_id, recorded_by and reference_no.
-- Add a CTSV fund link. Historical payments remain unassigned for reconciliation.
-- payments.fund_id
SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `payments` ADD COLUMN `fund_id` BIGINT NULL',
  'SELECT ''payments.fund_id already exists'' AS info')
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='payments' AND COLUMN_NAME='fund_id');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @sql := (SELECT IF(COUNT(*)=0,
  'ALTER TABLE `payments` ADD CONSTRAINT `fk_payments_ctsv_fund` FOREIGN KEY (`fund_id`) REFERENCES `ctsv_funds`(`id`)',
  'SELECT ''payments.ctsv_fund FK already exists'' AS info')
  FROM information_schema.TABLE_CONSTRAINTS
  WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME='payments'
    AND CONSTRAINT_NAME='fk_payments_ctsv_fund');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Tuition funds paid/transferred to school: separate event from student payment.
-- CONFIRMED is counted against CTSV cash-on-hand; no duplicate total is persisted.
CREATE TABLE IF NOT EXISTS ctsv_remittances (
  id BIGINT NOT NULL AUTO_INCREMENT,
  remittance_code VARCHAR(70) NOT NULL,
  semester_id BIGINT NOT NULL,
  fund_id BIGINT NOT NULL,
  amount DECIMAL(14,2) NOT NULL,
  status ENUM('DRAFT','SUBMITTED','CONFIRMED','REJECTED') NOT NULL DEFAULT 'DRAFT',
  prepared_by BIGINT NOT NULL,
  reviewed_by BIGINT NULL,
  remitted_at DATETIME NULL,
  reviewed_at DATETIME NULL,
  external_reference VARCHAR(120) NULL,
  note VARCHAR(700) NULL,
  PRIMARY KEY(id),
  UNIQUE KEY uq_ctsv_remittance_code(remittance_code),
  UNIQUE KEY uq_ctsv_remittance_external_reference(external_reference),
  KEY ix_ctsv_remittance_semester_status(semester_id,status),
  CONSTRAINT chk_ctsv_remittance_amount CHECK (amount>0),
  CONSTRAINT fk_ctsv_remittance_sem FOREIGN KEY(semester_id) REFERENCES semesters(id),
  CONSTRAINT fk_ctsv_remittance_fund FOREIGN KEY(fund_id) REFERENCES ctsv_funds(id),
  CONSTRAINT fk_ctsv_remittance_prepared FOREIGN KEY(prepared_by) REFERENCES users(id),
  CONSTRAINT fk_ctsv_remittance_reviewed FOREIGN KEY(reviewed_by) REFERENCES users(id)
) ENGINE=InnoDB;

-- One submission/report per semester (amounts derived from live payment ledger).
-- Report should be submitted after term close; interim DRAFT allowed.
CREATE TABLE IF NOT EXISTS ctsv_semester_reports (
  id BIGINT NOT NULL AUTO_INCREMENT,
  report_code VARCHAR(70) NOT NULL,
  semester_id BIGINT NOT NULL,
  prepared_by BIGINT NOT NULL,
  status ENUM('DRAFT','SUBMITTED','RETURNED','APPROVED') NOT NULL DEFAULT 'DRAFT',
  received_by BIGINT NULL,
  submitted_at DATETIME NULL,
  reviewed_at DATETIME NULL,
  note VARCHAR(700) NULL,
  PRIMARY KEY(id),
  UNIQUE KEY uq_ctsv_report_code(report_code),
  UNIQUE KEY uq_ctsv_report_semester(semester_id),
  CONSTRAINT fk_ctsv_report_sem FOREIGN KEY(semester_id) REFERENCES semesters(id),
  CONSTRAINT fk_ctsv_report_prepared FOREIGN KEY(prepared_by) REFERENCES users(id),
  CONSTRAINT fk_ctsv_report_received FOREIGN KEY(received_by) REFERENCES users(id)
) ENGINE=InnoDB;

-- D) Student institutional email allocation; not a Google/OAuth login.
-- RESERVED means just a planned address. ACTIVE requires a real mail-system provision.
CREATE TABLE IF NOT EXISTS student_school_mailboxes (
  id BIGINT NOT NULL AUTO_INCREMENT,
  student_id BIGINT NOT NULL,
  school_email VARCHAR(190) NOT NULL,
  provisioning_status ENUM('RESERVED','PROVISIONING','ACTIVE','FAILED','DISABLED') NOT NULL DEFAULT 'RESERVED',
  reserved_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  activated_at DATETIME NULL,
  provisioned_by BIGINT NULL,
  note VARCHAR(500) NULL,
  PRIMARY KEY(id),
  UNIQUE KEY uq_student_mailbox_student(student_id),
  UNIQUE KEY uq_student_mailbox_email(school_email),
  CONSTRAINT fk_student_mailbox_student FOREIGN KEY(student_id) REFERENCES students(id),
  CONSTRAINT fk_student_mailbox_provisioned_by FOREIGN KEY(provisioned_by) REFERENCES users(id)
) ENGINE=InnoDB;

-- Email outbox provides retries/idempotency; no passwords, tokens or attachments.
-- Send enrollment notification to applicant PERSONAL email, not a mailbox not yet active.
CREATE TABLE IF NOT EXISTS outbound_emails (
  id BIGINT NOT NULL AUTO_INCREMENT,
  event_key VARCHAR(120) NOT NULL,
  admission_application_id BIGINT NULL,
  semester_report_id BIGINT NULL,
  student_request_id BIGINT NULL,
  template_code VARCHAR(60) NOT NULL,
  recipient_email VARCHAR(190) NOT NULL,
  subject VARCHAR(200) NOT NULL,
  delivery_status ENUM('QUEUED','SENDING','SENT','FAILED') NOT NULL DEFAULT 'QUEUED',
  attempt_count INT NOT NULL DEFAULT 0,
  last_error VARCHAR(700) NULL,
  queued_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  sent_at DATETIME NULL,
  PRIMARY KEY(id),
  UNIQUE KEY uq_outbound_email_event(event_key),
  KEY ix_outbound_email_queue(delivery_status,queued_at),
  CONSTRAINT chk_outbound_email_attempt CHECK(attempt_count>=0),
  CONSTRAINT chk_outbound_email_one_origin CHECK (
    (admission_application_id IS NOT NULL) + (semester_report_id IS NOT NULL)
      + (student_request_id IS NOT NULL)=1),
  CONSTRAINT fk_email_admission FOREIGN KEY(admission_application_id) REFERENCES admission_applications(id),
  CONSTRAINT fk_email_report FOREIGN KEY(semester_report_id) REFERENCES ctsv_semester_reports(id),
  CONSTRAINT fk_email_request FOREIGN KEY(student_request_id) REFERENCES student_requests(id)
) ENGINE=InnoDB;

-- E) Derived reporting. No stored balances/totals that may diverge.




-- Rules enforced in Spring Service transactions, not purely by DB constraints:
-- * Only CTSV may verify submission documents and record payments in CTSV funds.
-- * School approval event required before creating students/student_code.
-- * student_mailbox ACTIVE ONLY after the real mailbox is provisioned by an administrator.
-- * Email sender uses outbox idempotency; never sends plaintext login passwords.
-- * Prevent double collection using payments.reference_no UNIQUE; verify invoice/overpayment.
-- * Disbursements cannot exceed CTSV fund balance; no delete/edit of posted payments.
-- * Report submission is allowed after semester closes and is reviewed by school.
-- * Do NOT add Google OAuth login. Pre-existing V3 auth_identities stays dormant; remove
--   only after a separate reviewed data migration/backup, not automatically here.


-- 3. BA BANG GIAY TO DINH DANH/HOC BA THPT
USE sms_v6_original;

-- --------------------------------------------------------------------------
-- F. BO SUNG HO SO: CCCD/HO CHIEU + HOC BA THPT
--  * Ban chup: admission_documents (ID_CARD, SCHOOL_TRANSCRIPT, ...)
--  * Thong tin co cau truc: ba bang ben duoi, 1 nguon du lieu cho moi nhom.
--  * So giay to day du: MA HOA tai Backend, khoa ma hoa NGOAI CSDL.
--  * Khong luu anh/tep PDF truc tiep trong MySQL.
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS admission_identity_records (
    id BIGINT NOT NULL AUTO_INCREMENT,
    application_id BIGINT NOT NULL,
    identity_type ENUM('CCCD','CMND','PASSPORT','OTHER') NOT NULL DEFAULT 'CCCD',
    identity_last4 CHAR(4) NULL,
    identity_number_encrypted VARBINARY(512) NULL,
    identity_number_hmac CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NULL,
    issued_on DATE NULL,
    expires_on DATE NULL,
    issued_by VARCHAR(200) NULL,
    verified_at DATETIME NULL,
    verified_by BIGINT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_admission_identity_application (application_id),
    KEY ix_admission_identity_hmac (identity_number_hmac),
    CONSTRAINT chk_admission_identity_validity CHECK (expires_on IS NULL OR issued_on IS NULL OR expires_on >= issued_on),
    CONSTRAINT fk_identity_application FOREIGN KEY (application_id) REFERENCES admission_applications(id),
    CONSTRAINT fk_identity_verified_by FOREIGN KEY (verified_by) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS admission_high_school_records (
    id BIGINT NOT NULL AUTO_INCREMENT,
    application_id BIGINT NOT NULL,
    school_name VARCHAR(200) NOT NULL,
    school_province VARCHAR(160) NULL,
    graduation_year SMALLINT NULL,
    graduation_status ENUM('PENDING','GRADUATED','NOT_GRADUATED') NOT NULL DEFAULT 'PENDING',
    transcript_average DECIMAL(4,2) NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_school_records_application (application_id),
    CONSTRAINT chk_school_records_year CHECK (graduation_year IS NULL OR graduation_year BETWEEN 1980 AND 2100),
    CONSTRAINT chk_school_records_average CHECK (transcript_average IS NULL OR transcript_average BETWEEN 0 AND 10),
    CONSTRAINT fk_school_records_application FOREIGN KEY (application_id) REFERENCES admission_applications(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS admission_high_school_scores (
    id BIGINT NOT NULL AUTO_INCREMENT,
    school_record_id BIGINT NOT NULL,
    grade_level TINYINT NOT NULL,
    subject_code VARCHAR(40) NOT NULL,
    average_score DECIMAL(4,2) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_school_score_grade_subject (school_record_id,grade_level,subject_code),
    CONSTRAINT chk_high_school_grade CHECK (grade_level IN (10,11,12)),
    CONSTRAINT chk_high_school_score CHECK (average_score BETWEEN 0 AND 10),
    CONSTRAINT fk_school_score_record FOREIGN KEY (school_record_id) REFERENCES admission_high_school_records(id)
) ENGINE=InnoDB;



-- =============================================================================
-- 4. V6 - BA BANG BO SUNG: DIEU CHINH HOC PHI / LICH SU BAO CAO / LICH SU EMAIL
-- KHONG DUPLICATE CONG NO; MOI KHOAN DIEU CHINH PHAI DUOC PHE DUYET.
-- =============================================================================

-- Hoc phi phat sinh/hoan-giam thu them duoc ghi nhan nhu chung tu, khong sua lai
-- chi tiet hoa don goc. Chi cac dieu chinh APPROVED duoc tinh vao cong no.
CREATE TABLE IF NOT EXISTS tuition_adjustments (
  id BIGINT NOT NULL AUTO_INCREMENT,
  adjustment_code VARCHAR(80) NOT NULL,
  invoice_id BIGINT NOT NULL,
  kind ENUM('DEBIT','CREDIT') NOT NULL,
  amount DECIMAL(14,2) NOT NULL,
  reason VARCHAR(700) NOT NULL,
  status ENUM('REQUESTED','APPROVED','REJECTED') NOT NULL DEFAULT 'REQUESTED',
  requested_by BIGINT NOT NULL,
  approved_by BIGINT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  decided_at DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_tuition_adjustment_code (adjustment_code),
  KEY ix_tuition_adjustment_invoice_status (invoice_id,status),
  CONSTRAINT chk_tuition_adjustments_amount CHECK (amount > 0),
  CONSTRAINT chk_tuition_adjustments_decision CHECK (
    (status='REQUESTED' AND approved_by IS NULL AND decided_at IS NULL)
    OR (status IN ('APPROVED','REJECTED') AND approved_by IS NOT NULL AND decided_at IS NOT NULL)
  ),
  CONSTRAINT fk_tuition_adjustment_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id),
  CONSTRAINT fk_tuition_adjustment_requester FOREIGN KEY (requested_by) REFERENCES users(id),
  CONSTRAINT fk_tuition_adjustment_approver FOREIGN KEY (approved_by) REFERENCES users(id)
) ENGINE=InnoDB;

-- Lich su nop/tra lai/phe duyet bao cao CTSV cho BGH.
CREATE TABLE IF NOT EXISTS ctsv_semester_report_reviews (
  id BIGINT NOT NULL AUTO_INCREMENT,
  report_id BIGINT NOT NULL,
  actor_user_id BIGINT NOT NULL,
  action ENUM('SUBMIT','RETURN','APPROVE') NOT NULL,
  note VARCHAR(700) NULL,
  event_key VARCHAR(120) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_ctsv_semester_report_review_event (event_key),
  KEY ix_ctsv_report_review_report (report_id,created_at),
  CONSTRAINT fk_ctsv_report_review_report FOREIGN KEY (report_id) REFERENCES ctsv_semester_reports(id),
  CONSTRAINT fk_ctsv_report_review_actor FOREIGN KEY (actor_user_id) REFERENCES users(id)
) ENGINE=InnoDB;

-- Ghi chi tiet tung lan worker thu gui email; KHONG co mat khau/token/SMTP secret.
CREATE TABLE IF NOT EXISTS email_delivery_attempts (
  id BIGINT NOT NULL AUTO_INCREMENT,
  outbound_email_id BIGINT NOT NULL,
  attempt_no INT NOT NULL,
  result ENUM('SENT','FAILED') NOT NULL,
  provider_message_id VARCHAR(190) NULL,
  error_code VARCHAR(80) NULL,
  error_message VARCHAR(500) NULL,
  attempted_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_email_delivery_attempt (outbound_email_id,attempt_no),
  UNIQUE KEY uq_email_delivery_provider_message (provider_message_id),
  CONSTRAINT chk_email_delivery_attempt_no CHECK (attempt_no>=1),
  CONSTRAINT fk_email_delivery_outbound FOREIGN KEY (outbound_email_id) REFERENCES outbound_emails(id)
) ENGINE=InnoDB;

-- Nguon du lieu chinh cho duyet ho so la admission_applications (trang thai)
-- va admission_review_events (lich su); UI BGH su dung v_school_admission_queue.
-- Quy tac phan quyen, chuyen trang thai, kiem tra du tien, email send
-- phai duoc THUC THI bang transaction va authorization o Spring Boot.

-- =============================================================================
-- V6 - DOI SOAT TIEN BAN GIAO THEO TUNG CHUNG TU THU
-- 1 dot ban giao co the chua nhieu khoan thu; mot payment co the duoc ban giao
-- theo nhieu dot. Dung amount PHAN BO, khong danh dau la da ban giao 2 lan.
-- =============================================================================
CREATE TABLE IF NOT EXISTS ctsv_remittance_allocations (
  remittance_id BIGINT NOT NULL,
  payment_id BIGINT NOT NULL,
  allocated_amount DECIMAL(14,2) NOT NULL,
  PRIMARY KEY (remittance_id,payment_id),
  CONSTRAINT chk_ctsv_remittance_allocation_amount CHECK (allocated_amount > 0),
  CONSTRAINT fk_ctsv_allocation_remittance FOREIGN KEY (remittance_id) REFERENCES ctsv_remittances(id),
  CONSTRAINT fk_ctsv_allocation_payment FOREIGN KEY (payment_id) REFERENCES payments(id)
) ENGINE=InnoDB;
-- Can kiem tra trong Backend: payment va remittance cung fund_id, semester_id;
-- tong allocation trong moi remittance bang r.amount khi CONFIRMED;
-- tong allocated_amount cua mot payment khong vuot p.amount.

-- =============================================================================
-- STUDENT MANAGEMENT SYSTEM | 02_SEED_DEMO.sql - V6
-- DU LIEU GIA LAP; CO THE CHAY LAI NHIEU LAN KHONG TAO TRUNG BAN GHI DEMO.
-- CHAY SAU 01_SCHEMA_ALL.sql. KHONG CO MAT KHAU HOAT DONG.
-- TAI KHOAN DEMO enabled=FALSE; KHONG CHUA GIAO DICH TIEN THUC.
-- =============================================================================
-- ============================================================================
-- STUDENT MANAGEMENT SYSTEM (SMS) | 02 - IDEMPOTENT DEMO SEED
-- Run AFTER 01_schema_sms.sql; may run repeatedly without duplicate demo rows.
-- Fictional demo records only; all accounts DISABLED, with random unknown hashes.
-- No real personal data, no real payments, no usable default admin credentials.
-- Entries are INSERT-IF-NOT-EXISTS: rerun does not overwrite changed live data.
-- ============================================================================
USE sms_v6_original;
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO roles (code, description)
SELECT 'PRINCIPAL', 'Ban giám hiệu / người duyệt được ủy quyền'
WHERE NOT EXISTS (SELECT 1 FROM roles x WHERE x.code='PRINCIPAL');

INSERT INTO roles (code, description)
SELECT 'TRAINING_OFFICE', 'Phòng đào tạo'
WHERE NOT EXISTS (SELECT 1 FROM roles x WHERE x.code='TRAINING_OFFICE');

INSERT INTO roles (code, description)
SELECT 'LECTURER', 'Giảng viên'
WHERE NOT EXISTS (SELECT 1 FROM roles x WHERE x.code='LECTURER');

INSERT INTO roles (code, description)
SELECT 'STUDENT', 'Sinh viên'
WHERE NOT EXISTS (SELECT 1 FROM roles x WHERE x.code='STUDENT');

INSERT INTO users (username, email, password_hash, full_name, enabled)
SELECT 'principal_demo', 'principal_demo@example.test', '$2a$12$PPLg2JpIqF/i8uD3f./c/OGMiyvCe41EPTMEO.dv1YiHl4vDmyCrq', 'Ban giám hiệu mẫu', FALSE
WHERE NOT EXISTS (SELECT 1 FROM users x WHERE x.username='principal_demo');

INSERT INTO user_roles (user_id, role_id)
SELECT (SELECT id FROM users WHERE username='principal_demo'), (SELECT id FROM roles WHERE code='PRINCIPAL')
WHERE NOT EXISTS (SELECT 1 FROM user_roles x WHERE x.user_id=(SELECT id FROM users WHERE username='principal_demo') AND x.role_id=(SELECT id FROM roles WHERE code='PRINCIPAL'));

INSERT INTO users (username, email, password_hash, full_name, enabled)
SELECT 'training_demo', 'training_demo@example.test', '$2a$12$H4Q9k5WMeYU8CH41jA5Wiu8zcLrZdX8sQDNOEhtburyaXDmGk4odS', 'Phòng đào tạo mẫu', FALSE
WHERE NOT EXISTS (SELECT 1 FROM users x WHERE x.username='training_demo');

INSERT INTO user_roles (user_id, role_id)
SELECT (SELECT id FROM users WHERE username='training_demo'), (SELECT id FROM roles WHERE code='TRAINING_OFFICE')
WHERE NOT EXISTS (SELECT 1 FROM user_roles x WHERE x.user_id=(SELECT id FROM users WHERE username='training_demo') AND x.role_id=(SELECT id FROM roles WHERE code='TRAINING_OFFICE'));

INSERT INTO users (username, email, password_hash, full_name, enabled)
SELECT 'lecturer_demo_01', 'lecturer_demo_01@example.test', '$2a$12$hKhjq7XPqPuYouPULY.1MukAtJ7A4YfqcwlBxVRuO44pKXzBv6fFi', 'Giảng viên mẫu 01', FALSE
WHERE NOT EXISTS (SELECT 1 FROM users x WHERE x.username='lecturer_demo_01');

INSERT INTO user_roles (user_id, role_id)
SELECT (SELECT id FROM users WHERE username='lecturer_demo_01'), (SELECT id FROM roles WHERE code='LECTURER')
WHERE NOT EXISTS (SELECT 1 FROM user_roles x WHERE x.user_id=(SELECT id FROM users WHERE username='lecturer_demo_01') AND x.role_id=(SELECT id FROM roles WHERE code='LECTURER'));

INSERT INTO users (username, email, password_hash, full_name, enabled)
SELECT 'lecturer_demo_02', 'lecturer_demo_02@example.test', '$2a$12$jjif502I6evD0LSRnqS3b.RM0YzuxEipNz/6rAsl3JWkZpw.Sm.4q', 'Giảng viên mẫu 02', FALSE
WHERE NOT EXISTS (SELECT 1 FROM users x WHERE x.username='lecturer_demo_02');

INSERT INTO user_roles (user_id, role_id)
SELECT (SELECT id FROM users WHERE username='lecturer_demo_02'), (SELECT id FROM roles WHERE code='LECTURER')
WHERE NOT EXISTS (SELECT 1 FROM user_roles x WHERE x.user_id=(SELECT id FROM users WHERE username='lecturer_demo_02') AND x.role_id=(SELECT id FROM roles WHERE code='LECTURER'));

INSERT INTO users (username, email, password_hash, full_name, enabled)
SELECT 'lecturer_demo_03', 'lecturer_demo_03@example.test', '$2a$12$Z0DqJ.PQ0WCmzZyCXjJwAeWkSl2C.HsAs2K06NZsecWPhTx1Kzff.', 'Giảng viên mẫu 03', FALSE
WHERE NOT EXISTS (SELECT 1 FROM users x WHERE x.username='lecturer_demo_03');

INSERT INTO user_roles (user_id, role_id)
SELECT (SELECT id FROM users WHERE username='lecturer_demo_03'), (SELECT id FROM roles WHERE code='LECTURER')
WHERE NOT EXISTS (SELECT 1 FROM user_roles x WHERE x.user_id=(SELECT id FROM users WHERE username='lecturer_demo_03') AND x.role_id=(SELECT id FROM roles WHERE code='LECTURER'));

INSERT INTO users (username, email, password_hash, full_name, enabled)
SELECT 'student_demo_001', 'student_demo_001@example.test', '$2a$12$WB/jAHTw2ENa0vnNC.xVmOT2flWz2/Iv5N3Zn5KnVTUop/cimjQ.K', 'Sinh viên mẫu 001', FALSE
WHERE NOT EXISTS (SELECT 1 FROM users x WHERE x.username='student_demo_001');

INSERT INTO user_roles (user_id, role_id)
SELECT (SELECT id FROM users WHERE username='student_demo_001'), (SELECT id FROM roles WHERE code='STUDENT')
WHERE NOT EXISTS (SELECT 1 FROM user_roles x WHERE x.user_id=(SELECT id FROM users WHERE username='student_demo_001') AND x.role_id=(SELECT id FROM roles WHERE code='STUDENT'));

INSERT INTO users (username, email, password_hash, full_name, enabled)
SELECT 'student_demo_002', 'student_demo_002@example.test', '$2a$12$Tg9Jo96w2K7kdz9LzVDHf.AnimqanhFurXSr/U0DWq8VZ5Xaitya.', 'Sinh viên mẫu 002', FALSE
WHERE NOT EXISTS (SELECT 1 FROM users x WHERE x.username='student_demo_002');

INSERT INTO user_roles (user_id, role_id)
SELECT (SELECT id FROM users WHERE username='student_demo_002'), (SELECT id FROM roles WHERE code='STUDENT')
WHERE NOT EXISTS (SELECT 1 FROM user_roles x WHERE x.user_id=(SELECT id FROM users WHERE username='student_demo_002') AND x.role_id=(SELECT id FROM roles WHERE code='STUDENT'));

INSERT INTO users (username, email, password_hash, full_name, enabled)
SELECT 'student_demo_003', 'student_demo_003@example.test', '$2a$12$ENdpuKHgvJkgeU1aGXBPx.mkKsjlvPfOuuWSQOpwxU2je5KZgkjse', 'Sinh viên mẫu 003', FALSE
WHERE NOT EXISTS (SELECT 1 FROM users x WHERE x.username='student_demo_003');

INSERT INTO user_roles (user_id, role_id)
SELECT (SELECT id FROM users WHERE username='student_demo_003'), (SELECT id FROM roles WHERE code='STUDENT')
WHERE NOT EXISTS (SELECT 1 FROM user_roles x WHERE x.user_id=(SELECT id FROM users WHERE username='student_demo_003') AND x.role_id=(SELECT id FROM roles WHERE code='STUDENT'));

INSERT INTO users (username, email, password_hash, full_name, enabled)
SELECT 'student_demo_004', 'student_demo_004@example.test', '$2a$12$OZQwkC2ynwhTnlxGuI0Fbu/lP3RyfwmC0iKomBwEIUCAijZOR7eri', 'Sinh viên mẫu 004', FALSE
WHERE NOT EXISTS (SELECT 1 FROM users x WHERE x.username='student_demo_004');

INSERT INTO user_roles (user_id, role_id)
SELECT (SELECT id FROM users WHERE username='student_demo_004'), (SELECT id FROM roles WHERE code='STUDENT')
WHERE NOT EXISTS (SELECT 1 FROM user_roles x WHERE x.user_id=(SELECT id FROM users WHERE username='student_demo_004') AND x.role_id=(SELECT id FROM roles WHERE code='STUDENT'));

INSERT INTO users (username, email, password_hash, full_name, enabled)
SELECT 'student_demo_005', 'student_demo_005@example.test', '$2a$12$3Cm74ibG.6AmcbKr1la6SueEBvbq4H2ZDGwBgsKVWM7k55mhYp.6O', 'Sinh viên mẫu 005', FALSE
WHERE NOT EXISTS (SELECT 1 FROM users x WHERE x.username='student_demo_005');

INSERT INTO user_roles (user_id, role_id)
SELECT (SELECT id FROM users WHERE username='student_demo_005'), (SELECT id FROM roles WHERE code='STUDENT')
WHERE NOT EXISTS (SELECT 1 FROM user_roles x WHERE x.user_id=(SELECT id FROM users WHERE username='student_demo_005') AND x.role_id=(SELECT id FROM roles WHERE code='STUDENT'));

INSERT INTO users (username, email, password_hash, full_name, enabled)
SELECT 'student_demo_006', 'student_demo_006@example.test', '$2a$12$if.fXzUgpA.sXbMOXXt.EO.nMpzutTfTuwegBbcMw67VXTQkb04QO', 'Sinh viên mẫu 006', FALSE
WHERE NOT EXISTS (SELECT 1 FROM users x WHERE x.username='student_demo_006');

INSERT INTO user_roles (user_id, role_id)
SELECT (SELECT id FROM users WHERE username='student_demo_006'), (SELECT id FROM roles WHERE code='STUDENT')
WHERE NOT EXISTS (SELECT 1 FROM user_roles x WHERE x.user_id=(SELECT id FROM users WHERE username='student_demo_006') AND x.role_id=(SELECT id FROM roles WHERE code='STUDENT'));

INSERT INTO faculties (code, name)
SELECT 'CNTT', 'Khoa Công nghệ thông tin (demo)'
WHERE NOT EXISTS (SELECT 1 FROM faculties x WHERE x.code='CNTT');

INSERT INTO faculties (code, name)
SELECT 'KT', 'Khoa Kinh tế (demo)'
WHERE NOT EXISTS (SELECT 1 FROM faculties x WHERE x.code='KT');

INSERT INTO majors (faculty_id, code, name)
SELECT (SELECT id FROM faculties WHERE code='CNTT'), 'KTPM', 'Kỹ thuật phần mềm (demo)'
WHERE NOT EXISTS (SELECT 1 FROM majors x WHERE x.code='KTPM');

INSERT INTO majors (faculty_id, code, name)
SELECT (SELECT id FROM faculties WHERE code='CNTT'), 'HTTT', 'Hệ thống thông tin (demo)'
WHERE NOT EXISTS (SELECT 1 FROM majors x WHERE x.code='HTTT');

INSERT INTO majors (faculty_id, code, name)
SELECT (SELECT id FROM faculties WHERE code='KT'), 'QTKD', 'Quản trị kinh doanh (demo)'
WHERE NOT EXISTS (SELECT 1 FROM majors x WHERE x.code='QTKD');

INSERT INTO cohorts (code, start_year, end_year)
SELECT 'K2025', 2025, 2029
WHERE NOT EXISTS (SELECT 1 FROM cohorts x WHERE x.code='K2025');

INSERT INTO cohorts (code, start_year, end_year)
SELECT 'K2026', 2026, 2030
WHERE NOT EXISTS (SELECT 1 FROM cohorts x WHERE x.code='K2026');

INSERT INTO academic_classes (major_id, cohort_id, code, name)
SELECT (SELECT id FROM majors WHERE code='KTPM'), (SELECT id FROM cohorts WHERE code='K2026'), 'KTPM26-A', 'Kỹ thuật phần mềm K2026 - A'
WHERE NOT EXISTS (SELECT 1 FROM academic_classes x WHERE x.code='KTPM26-A');

INSERT INTO academic_classes (major_id, cohort_id, code, name)
SELECT (SELECT id FROM majors WHERE code='HTTT'), (SELECT id FROM cohorts WHERE code='K2025'), 'HTTT25-A', 'Hệ thống thông tin K2025 - A'
WHERE NOT EXISTS (SELECT 1 FROM academic_classes x WHERE x.code='HTTT25-A');

INSERT INTO academic_classes (major_id, cohort_id, code, name)
SELECT (SELECT id FROM majors WHERE code='QTKD'), (SELECT id FROM cohorts WHERE code='K2026'), 'QTKD26-A', 'Quản trị kinh doanh K2026 - A'
WHERE NOT EXISTS (SELECT 1 FROM academic_classes x WHERE x.code='QTKD26-A');

INSERT INTO students (user_id, student_code, class_id, date_of_birth, status, enrolled_on)
SELECT (SELECT id FROM users WHERE username='student_demo_001'), 'DEMO26001', (SELECT id FROM academic_classes WHERE code='KTPM26-A'), '2008-01-20', 'STUDYING', '2026-09-05'
WHERE NOT EXISTS (SELECT 1 FROM students x WHERE x.student_code='DEMO26001');

INSERT INTO students (user_id, student_code, class_id, date_of_birth, status, enrolled_on)
SELECT (SELECT id FROM users WHERE username='student_demo_002'), 'DEMO26002', (SELECT id FROM academic_classes WHERE code='KTPM26-A'), '2008-03-12', 'STUDYING', '2026-09-05'
WHERE NOT EXISTS (SELECT 1 FROM students x WHERE x.student_code='DEMO26002');

INSERT INTO students (user_id, student_code, class_id, date_of_birth, status, enrolled_on)
SELECT (SELECT id FROM users WHERE username='student_demo_003'), 'DEMO26003', (SELECT id FROM academic_classes WHERE code='KTPM26-A'), '2008-04-11', 'STUDYING', '2026-09-05'
WHERE NOT EXISTS (SELECT 1 FROM students x WHERE x.student_code='DEMO26003');

INSERT INTO students (user_id, student_code, class_id, date_of_birth, status, enrolled_on)
SELECT (SELECT id FROM users WHERE username='student_demo_004'), 'DEMO26004', (SELECT id FROM academic_classes WHERE code='KTPM26-A'), '2008-07-25', 'STUDYING', '2026-09-05'
WHERE NOT EXISTS (SELECT 1 FROM students x WHERE x.student_code='DEMO26004');

INSERT INTO students (user_id, student_code, class_id, date_of_birth, status, enrolled_on)
SELECT (SELECT id FROM users WHERE username='student_demo_005'), 'DEMO25005', (SELECT id FROM academic_classes WHERE code='HTTT25-A'), '2007-09-01', 'STUDYING', '2025-09-05'
WHERE NOT EXISTS (SELECT 1 FROM students x WHERE x.student_code='DEMO25005');

INSERT INTO students (user_id, student_code, class_id, date_of_birth, status, enrolled_on)
SELECT (SELECT id FROM users WHERE username='student_demo_006'), 'DEMO26006', (SELECT id FROM academic_classes WHERE code='QTKD26-A'), '2008-11-06', 'STUDYING', '2026-09-05'
WHERE NOT EXISTS (SELECT 1 FROM students x WHERE x.student_code='DEMO26006');

INSERT INTO lecturers (user_id, faculty_id, lecturer_code)
SELECT (SELECT id FROM users WHERE username='lecturer_demo_01'), (SELECT id FROM faculties WHERE code='CNTT'), 'GV-DEMO-01'
WHERE NOT EXISTS (SELECT 1 FROM lecturers x WHERE x.lecturer_code='GV-DEMO-01');

INSERT INTO lecturers (user_id, faculty_id, lecturer_code)
SELECT (SELECT id FROM users WHERE username='lecturer_demo_02'), (SELECT id FROM faculties WHERE code='CNTT'), 'GV-DEMO-02'
WHERE NOT EXISTS (SELECT 1 FROM lecturers x WHERE x.lecturer_code='GV-DEMO-02');

INSERT INTO lecturers (user_id, faculty_id, lecturer_code)
SELECT (SELECT id FROM users WHERE username='lecturer_demo_03'), (SELECT id FROM faculties WHERE code='KT'), 'GV-DEMO-03'
WHERE NOT EXISTS (SELECT 1 FROM lecturers x WHERE x.lecturer_code='GV-DEMO-03');

INSERT INTO academic_years (name, starts_on, ends_on)
SELECT '2026-2027', '2026-09-01', '2027-08-31'
WHERE NOT EXISTS (SELECT 1 FROM academic_years x WHERE x.name='2026-2027');

INSERT INTO semesters (academic_year_id, code, starts_on, ends_on, registration_from, registration_to, status)
SELECT (SELECT id FROM academic_years WHERE name='2026-2027'), 'HK1', '2026-09-05', '2027-01-15', '2026-08-01 08:00:00', '2026-09-15 17:00:00', 'CLOSED'
WHERE NOT EXISTS (SELECT 1 FROM semesters x WHERE x.academic_year_id=(SELECT id FROM academic_years WHERE name='2026-2027') AND x.code='HK1');

INSERT INTO semesters (academic_year_id, code, starts_on, ends_on, registration_from, registration_to, status)
SELECT (SELECT id FROM academic_years WHERE name='2026-2027'), 'HK2', '2027-02-01', '2027-06-25', '2026-11-01 08:00:00', '2027-01-15 17:00:00', 'OPEN'
WHERE NOT EXISTS (SELECT 1 FROM semesters x WHERE x.academic_year_id=(SELECT id FROM academic_years WHERE name='2026-2027') AND x.code='HK2');

INSERT INTO courses (course_code, title, credits, active)
SELECT 'SE101', 'Nhập môn công nghệ phần mềm', 3, TRUE
WHERE NOT EXISTS (SELECT 1 FROM courses x WHERE x.course_code='SE101');

INSERT INTO courses (course_code, title, credits, active)
SELECT 'DB102', 'Cơ sở dữ liệu', 3, TRUE
WHERE NOT EXISTS (SELECT 1 FROM courses x WHERE x.course_code='DB102');

INSERT INTO courses (course_code, title, credits, active)
SELECT 'NW103', 'Mạng máy tính', 2, TRUE
WHERE NOT EXISTS (SELECT 1 FROM courses x WHERE x.course_code='NW103');

INSERT INTO courses (course_code, title, credits, active)
SELECT 'WD104', 'Phát triển ứng dụng Web', 3, TRUE
WHERE NOT EXISTS (SELECT 1 FROM courses x WHERE x.course_code='WD104');

INSERT INTO courses (course_code, title, credits, active)
SELECT 'CS105', 'Cấu trúc dữ liệu', 3, TRUE
WHERE NOT EXISTS (SELECT 1 FROM courses x WHERE x.course_code='CS105');

INSERT INTO courses (course_code, title, credits, active)
SELECT 'ST106', 'Xác suất thống kê', 2, TRUE
WHERE NOT EXISTS (SELECT 1 FROM courses x WHERE x.course_code='ST106');

INSERT INTO courses (course_code, title, credits, active)
SELECT 'BA101', 'Nhập môn quản trị kinh doanh', 3, TRUE
WHERE NOT EXISTS (SELECT 1 FROM courses x WHERE x.course_code='BA101');

INSERT INTO courses (course_code, title, credits, active)
SELECT 'EC102', 'Kinh tế vi mô', 3, TRUE
WHERE NOT EXISTS (SELECT 1 FROM courses x WHERE x.course_code='EC102');

INSERT INTO curricula (major_id, cohort_id, title)
SELECT (SELECT id FROM majors WHERE code='KTPM'), (SELECT id FROM cohorts WHERE code='K2026'), 'CTĐT Kỹ thuật phần mềm K2026 (demo)'
WHERE NOT EXISTS (SELECT 1 FROM curricula x WHERE x.major_id=(SELECT id FROM majors WHERE code='KTPM') AND x.cohort_id=(SELECT id FROM cohorts WHERE code='K2026'));

INSERT INTO curricula (major_id, cohort_id, title)
SELECT (SELECT id FROM majors WHERE code='HTTT'), (SELECT id FROM cohorts WHERE code='K2025'), 'CTĐT Hệ thống thông tin K2025 (demo)'
WHERE NOT EXISTS (SELECT 1 FROM curricula x WHERE x.major_id=(SELECT id FROM majors WHERE code='HTTT') AND x.cohort_id=(SELECT id FROM cohorts WHERE code='K2025'));

INSERT INTO curricula (major_id, cohort_id, title)
SELECT (SELECT id FROM majors WHERE code='QTKD'), (SELECT id FROM cohorts WHERE code='K2026'), 'CTĐT Quản trị kinh doanh K2026 (demo)'
WHERE NOT EXISTS (SELECT 1 FROM curricula x WHERE x.major_id=(SELECT id FROM majors WHERE code='QTKD') AND x.cohort_id=(SELECT id FROM cohorts WHERE code='K2026'));

INSERT INTO curriculum_courses (curriculum_id, course_id, suggested_semester, required_course)
SELECT (SELECT cr.id FROM curricula cr WHERE cr.major_id=(SELECT id FROM majors WHERE code='KTPM') AND cr.cohort_id=(SELECT id FROM cohorts WHERE code='K2026')), (SELECT id FROM courses WHERE course_code='SE101'), 1, TRUE
WHERE NOT EXISTS (SELECT 1 FROM curriculum_courses x WHERE x.curriculum_id=(SELECT cr.id FROM curricula cr WHERE cr.major_id=(SELECT id FROM majors WHERE code='KTPM') AND cr.cohort_id=(SELECT id FROM cohorts WHERE code='K2026')) AND x.course_id=(SELECT id FROM courses WHERE course_code='SE101'));

INSERT INTO curriculum_courses (curriculum_id, course_id, suggested_semester, required_course)
SELECT (SELECT cr.id FROM curricula cr WHERE cr.major_id=(SELECT id FROM majors WHERE code='KTPM') AND cr.cohort_id=(SELECT id FROM cohorts WHERE code='K2026')), (SELECT id FROM courses WHERE course_code='DB102'), 1, TRUE
WHERE NOT EXISTS (SELECT 1 FROM curriculum_courses x WHERE x.curriculum_id=(SELECT cr.id FROM curricula cr WHERE cr.major_id=(SELECT id FROM majors WHERE code='KTPM') AND cr.cohort_id=(SELECT id FROM cohorts WHERE code='K2026')) AND x.course_id=(SELECT id FROM courses WHERE course_code='DB102'));

INSERT INTO curriculum_courses (curriculum_id, course_id, suggested_semester, required_course)
SELECT (SELECT cr.id FROM curricula cr WHERE cr.major_id=(SELECT id FROM majors WHERE code='KTPM') AND cr.cohort_id=(SELECT id FROM cohorts WHERE code='K2026')), (SELECT id FROM courses WHERE course_code='NW103'), 1, TRUE
WHERE NOT EXISTS (SELECT 1 FROM curriculum_courses x WHERE x.curriculum_id=(SELECT cr.id FROM curricula cr WHERE cr.major_id=(SELECT id FROM majors WHERE code='KTPM') AND cr.cohort_id=(SELECT id FROM cohorts WHERE code='K2026')) AND x.course_id=(SELECT id FROM courses WHERE course_code='NW103'));

INSERT INTO curriculum_courses (curriculum_id, course_id, suggested_semester, required_course)
SELECT (SELECT cr.id FROM curricula cr WHERE cr.major_id=(SELECT id FROM majors WHERE code='KTPM') AND cr.cohort_id=(SELECT id FROM cohorts WHERE code='K2026')), (SELECT id FROM courses WHERE course_code='WD104'), 2, TRUE
WHERE NOT EXISTS (SELECT 1 FROM curriculum_courses x WHERE x.curriculum_id=(SELECT cr.id FROM curricula cr WHERE cr.major_id=(SELECT id FROM majors WHERE code='KTPM') AND cr.cohort_id=(SELECT id FROM cohorts WHERE code='K2026')) AND x.course_id=(SELECT id FROM courses WHERE course_code='WD104'));

INSERT INTO curriculum_courses (curriculum_id, course_id, suggested_semester, required_course)
SELECT (SELECT cr.id FROM curricula cr WHERE cr.major_id=(SELECT id FROM majors WHERE code='KTPM') AND cr.cohort_id=(SELECT id FROM cohorts WHERE code='K2026')), (SELECT id FROM courses WHERE course_code='CS105'), 2, TRUE
WHERE NOT EXISTS (SELECT 1 FROM curriculum_courses x WHERE x.curriculum_id=(SELECT cr.id FROM curricula cr WHERE cr.major_id=(SELECT id FROM majors WHERE code='KTPM') AND cr.cohort_id=(SELECT id FROM cohorts WHERE code='K2026')) AND x.course_id=(SELECT id FROM courses WHERE course_code='CS105'));

INSERT INTO curriculum_courses (curriculum_id, course_id, suggested_semester, required_course)
SELECT (SELECT cr.id FROM curricula cr WHERE cr.major_id=(SELECT id FROM majors WHERE code='KTPM') AND cr.cohort_id=(SELECT id FROM cohorts WHERE code='K2026')), (SELECT id FROM courses WHERE course_code='ST106'), 1, TRUE
WHERE NOT EXISTS (SELECT 1 FROM curriculum_courses x WHERE x.curriculum_id=(SELECT cr.id FROM curricula cr WHERE cr.major_id=(SELECT id FROM majors WHERE code='KTPM') AND cr.cohort_id=(SELECT id FROM cohorts WHERE code='K2026')) AND x.course_id=(SELECT id FROM courses WHERE course_code='ST106'));

INSERT INTO curriculum_courses (curriculum_id, course_id, suggested_semester, required_course)
SELECT (SELECT cr.id FROM curricula cr WHERE cr.major_id=(SELECT id FROM majors WHERE code='HTTT') AND cr.cohort_id=(SELECT id FROM cohorts WHERE code='K2025')), (SELECT id FROM courses WHERE course_code='DB102'), 1, TRUE
WHERE NOT EXISTS (SELECT 1 FROM curriculum_courses x WHERE x.curriculum_id=(SELECT cr.id FROM curricula cr WHERE cr.major_id=(SELECT id FROM majors WHERE code='HTTT') AND cr.cohort_id=(SELECT id FROM cohorts WHERE code='K2025')) AND x.course_id=(SELECT id FROM courses WHERE course_code='DB102'));

INSERT INTO curriculum_courses (curriculum_id, course_id, suggested_semester, required_course)
SELECT (SELECT cr.id FROM curricula cr WHERE cr.major_id=(SELECT id FROM majors WHERE code='HTTT') AND cr.cohort_id=(SELECT id FROM cohorts WHERE code='K2025')), (SELECT id FROM courses WHERE course_code='NW103'), 1, TRUE
WHERE NOT EXISTS (SELECT 1 FROM curriculum_courses x WHERE x.curriculum_id=(SELECT cr.id FROM curricula cr WHERE cr.major_id=(SELECT id FROM majors WHERE code='HTTT') AND cr.cohort_id=(SELECT id FROM cohorts WHERE code='K2025')) AND x.course_id=(SELECT id FROM courses WHERE course_code='NW103'));

INSERT INTO curriculum_courses (curriculum_id, course_id, suggested_semester, required_course)
SELECT (SELECT cr.id FROM curricula cr WHERE cr.major_id=(SELECT id FROM majors WHERE code='HTTT') AND cr.cohort_id=(SELECT id FROM cohorts WHERE code='K2025')), (SELECT id FROM courses WHERE course_code='ST106'), 1, TRUE
WHERE NOT EXISTS (SELECT 1 FROM curriculum_courses x WHERE x.curriculum_id=(SELECT cr.id FROM curricula cr WHERE cr.major_id=(SELECT id FROM majors WHERE code='HTTT') AND cr.cohort_id=(SELECT id FROM cohorts WHERE code='K2025')) AND x.course_id=(SELECT id FROM courses WHERE course_code='ST106'));

INSERT INTO curriculum_courses (curriculum_id, course_id, suggested_semester, required_course)
SELECT (SELECT cr.id FROM curricula cr WHERE cr.major_id=(SELECT id FROM majors WHERE code='HTTT') AND cr.cohort_id=(SELECT id FROM cohorts WHERE code='K2025')), (SELECT id FROM courses WHERE course_code='WD104'), 2, TRUE
WHERE NOT EXISTS (SELECT 1 FROM curriculum_courses x WHERE x.curriculum_id=(SELECT cr.id FROM curricula cr WHERE cr.major_id=(SELECT id FROM majors WHERE code='HTTT') AND cr.cohort_id=(SELECT id FROM cohorts WHERE code='K2025')) AND x.course_id=(SELECT id FROM courses WHERE course_code='WD104'));

INSERT INTO curriculum_courses (curriculum_id, course_id, suggested_semester, required_course)
SELECT (SELECT cr.id FROM curricula cr WHERE cr.major_id=(SELECT id FROM majors WHERE code='QTKD') AND cr.cohort_id=(SELECT id FROM cohorts WHERE code='K2026')), (SELECT id FROM courses WHERE course_code='BA101'), 1, TRUE
WHERE NOT EXISTS (SELECT 1 FROM curriculum_courses x WHERE x.curriculum_id=(SELECT cr.id FROM curricula cr WHERE cr.major_id=(SELECT id FROM majors WHERE code='QTKD') AND cr.cohort_id=(SELECT id FROM cohorts WHERE code='K2026')) AND x.course_id=(SELECT id FROM courses WHERE course_code='BA101'));

INSERT INTO curriculum_courses (curriculum_id, course_id, suggested_semester, required_course)
SELECT (SELECT cr.id FROM curricula cr WHERE cr.major_id=(SELECT id FROM majors WHERE code='QTKD') AND cr.cohort_id=(SELECT id FROM cohorts WHERE code='K2026')), (SELECT id FROM courses WHERE course_code='EC102'), 1, TRUE
WHERE NOT EXISTS (SELECT 1 FROM curriculum_courses x WHERE x.curriculum_id=(SELECT cr.id FROM curricula cr WHERE cr.major_id=(SELECT id FROM majors WHERE code='QTKD') AND cr.cohort_id=(SELECT id FROM cohorts WHERE code='K2026')) AND x.course_id=(SELECT id FROM courses WHERE course_code='EC102'));

INSERT INTO curriculum_courses (curriculum_id, course_id, suggested_semester, required_course)
SELECT (SELECT cr.id FROM curricula cr WHERE cr.major_id=(SELECT id FROM majors WHERE code='QTKD') AND cr.cohort_id=(SELECT id FROM cohorts WHERE code='K2026')), (SELECT id FROM courses WHERE course_code='ST106'), 2, TRUE
WHERE NOT EXISTS (SELECT 1 FROM curriculum_courses x WHERE x.curriculum_id=(SELECT cr.id FROM curricula cr WHERE cr.major_id=(SELECT id FROM majors WHERE code='QTKD') AND cr.cohort_id=(SELECT id FROM cohorts WHERE code='K2026')) AND x.course_id=(SELECT id FROM courses WHERE course_code='ST106'));

INSERT INTO course_sections (semester_id, course_id, lecturer_id, section_code, capacity, attendance_weight, midterm_weight, final_weight, is_open)
SELECT (SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'), (SELECT id FROM courses WHERE course_code='SE101'), (SELECT id FROM lecturers WHERE lecturer_code='GV-DEMO-01'), 'SE101-01', 40, 10.00, 30.00, 60.00, TRUE
WHERE NOT EXISTS (SELECT 1 FROM course_sections x WHERE x.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1') AND x.section_code='SE101-01');

INSERT INTO course_sections (semester_id, course_id, lecturer_id, section_code, capacity, attendance_weight, midterm_weight, final_weight, is_open)
SELECT (SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'), (SELECT id FROM courses WHERE course_code='DB102'), (SELECT id FROM lecturers WHERE lecturer_code='GV-DEMO-02'), 'DB102-01', 40, 10.00, 30.00, 60.00, TRUE
WHERE NOT EXISTS (SELECT 1 FROM course_sections x WHERE x.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1') AND x.section_code='DB102-01');

INSERT INTO course_sections (semester_id, course_id, lecturer_id, section_code, capacity, attendance_weight, midterm_weight, final_weight, is_open)
SELECT (SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'), (SELECT id FROM courses WHERE course_code='NW103'), (SELECT id FROM lecturers WHERE lecturer_code='GV-DEMO-01'), 'NW103-01', 40, 10.00, 30.00, 60.00, TRUE
WHERE NOT EXISTS (SELECT 1 FROM course_sections x WHERE x.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1') AND x.section_code='NW103-01');

INSERT INTO course_sections (semester_id, course_id, lecturer_id, section_code, capacity, attendance_weight, midterm_weight, final_weight, is_open)
SELECT (SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'), (SELECT id FROM courses WHERE course_code='BA101'), (SELECT id FROM lecturers WHERE lecturer_code='GV-DEMO-03'), 'BA101-01', 35, 10.00, 30.00, 60.00, TRUE
WHERE NOT EXISTS (SELECT 1 FROM course_sections x WHERE x.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1') AND x.section_code='BA101-01');

INSERT INTO course_sections (semester_id, course_id, lecturer_id, section_code, capacity, attendance_weight, midterm_weight, final_weight, is_open)
SELECT (SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2'), (SELECT id FROM courses WHERE course_code='WD104'), (SELECT id FROM lecturers WHERE lecturer_code='GV-DEMO-02'), 'WD104-01', 30, 10.00, 30.00, 60.00, TRUE
WHERE NOT EXISTS (SELECT 1 FROM course_sections x WHERE x.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2') AND x.section_code='WD104-01');

INSERT INTO section_schedules (section_id, day_of_week, starts_at, ends_at, room)
SELECT (SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01'), 1, '08:00:00', '10:00:00', 'A201'
WHERE NOT EXISTS (SELECT 1 FROM section_schedules x WHERE x.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01') AND x.day_of_week=1 AND x.starts_at='08:00:00' AND x.ends_at='10:00:00');

INSERT INTO section_schedules (section_id, day_of_week, starts_at, ends_at, room)
SELECT (SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01'), 2, '08:00:00', '10:00:00', 'B302'
WHERE NOT EXISTS (SELECT 1 FROM section_schedules x WHERE x.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01') AND x.day_of_week=2 AND x.starts_at='08:00:00' AND x.ends_at='10:00:00');

INSERT INTO section_schedules (section_id, day_of_week, starts_at, ends_at, room)
SELECT (SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='NW103-01'), 3, '13:00:00', '15:00:00', 'A202'
WHERE NOT EXISTS (SELECT 1 FROM section_schedules x WHERE x.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='NW103-01') AND x.day_of_week=3 AND x.starts_at='13:00:00' AND x.ends_at='15:00:00');

INSERT INTO section_schedules (section_id, day_of_week, starts_at, ends_at, room)
SELECT (SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='BA101-01'), 4, '08:00:00', '10:00:00', 'C101'
WHERE NOT EXISTS (SELECT 1 FROM section_schedules x WHERE x.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='BA101-01') AND x.day_of_week=4 AND x.starts_at='08:00:00' AND x.ends_at='10:00:00');

INSERT INTO section_schedules (section_id, day_of_week, starts_at, ends_at, room)
SELECT (SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2' AND cs.section_code='WD104-01'), 1, '08:00:00', '10:00:00', 'A203'
WHERE NOT EXISTS (SELECT 1 FROM section_schedules x WHERE x.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2' AND cs.section_code='WD104-01') AND x.day_of_week=1 AND x.starts_at='08:00:00' AND x.ends_at='10:00:00');

INSERT INTO enrollments (student_id, section_id, status, registered_at)
SELECT (SELECT id FROM students WHERE student_code='DEMO26001'), (SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01'), 'REGISTERED', '2026-08-30 09:00:00'
WHERE NOT EXISTS (SELECT 1 FROM enrollments x WHERE x.student_id=(SELECT id FROM students WHERE student_code='DEMO26001') AND x.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01'));

INSERT INTO enrollments (student_id, section_id, status, registered_at)
SELECT (SELECT id FROM students WHERE student_code='DEMO26001'), (SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01'), 'REGISTERED', '2026-08-30 09:00:00'
WHERE NOT EXISTS (SELECT 1 FROM enrollments x WHERE x.student_id=(SELECT id FROM students WHERE student_code='DEMO26001') AND x.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01'));

INSERT INTO enrollments (student_id, section_id, status, registered_at)
SELECT (SELECT id FROM students WHERE student_code='DEMO26001'), (SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='NW103-01'), 'REGISTERED', '2026-08-30 09:00:00'
WHERE NOT EXISTS (SELECT 1 FROM enrollments x WHERE x.student_id=(SELECT id FROM students WHERE student_code='DEMO26001') AND x.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='NW103-01'));

INSERT INTO enrollments (student_id, section_id, status, registered_at)
SELECT (SELECT id FROM students WHERE student_code='DEMO26002'), (SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01'), 'REGISTERED', '2026-08-30 09:00:00'
WHERE NOT EXISTS (SELECT 1 FROM enrollments x WHERE x.student_id=(SELECT id FROM students WHERE student_code='DEMO26002') AND x.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01'));

INSERT INTO enrollments (student_id, section_id, status, registered_at)
SELECT (SELECT id FROM students WHERE student_code='DEMO26002'), (SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01'), 'REGISTERED', '2026-08-30 09:00:00'
WHERE NOT EXISTS (SELECT 1 FROM enrollments x WHERE x.student_id=(SELECT id FROM students WHERE student_code='DEMO26002') AND x.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01'));

INSERT INTO enrollments (student_id, section_id, status, registered_at)
SELECT (SELECT id FROM students WHERE student_code='DEMO26003'), (SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01'), 'REGISTERED', '2026-08-30 09:00:00'
WHERE NOT EXISTS (SELECT 1 FROM enrollments x WHERE x.student_id=(SELECT id FROM students WHERE student_code='DEMO26003') AND x.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01'));

INSERT INTO enrollments (student_id, section_id, status, registered_at)
SELECT (SELECT id FROM students WHERE student_code='DEMO26003'), (SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='NW103-01'), 'REGISTERED', '2026-08-30 09:00:00'
WHERE NOT EXISTS (SELECT 1 FROM enrollments x WHERE x.student_id=(SELECT id FROM students WHERE student_code='DEMO26003') AND x.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='NW103-01'));

INSERT INTO enrollments (student_id, section_id, status, registered_at)
SELECT (SELECT id FROM students WHERE student_code='DEMO26004'), (SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01'), 'REGISTERED', '2026-08-30 09:00:00'
WHERE NOT EXISTS (SELECT 1 FROM enrollments x WHERE x.student_id=(SELECT id FROM students WHERE student_code='DEMO26004') AND x.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01'));

INSERT INTO enrollments (student_id, section_id, status, registered_at)
SELECT (SELECT id FROM students WHERE student_code='DEMO25005'), (SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01'), 'REGISTERED', '2026-08-30 09:00:00'
WHERE NOT EXISTS (SELECT 1 FROM enrollments x WHERE x.student_id=(SELECT id FROM students WHERE student_code='DEMO25005') AND x.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01'));

INSERT INTO enrollments (student_id, section_id, status, registered_at)
SELECT (SELECT id FROM students WHERE student_code='DEMO25005'), (SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='NW103-01'), 'REGISTERED', '2026-08-30 09:00:00'
WHERE NOT EXISTS (SELECT 1 FROM enrollments x WHERE x.student_id=(SELECT id FROM students WHERE student_code='DEMO25005') AND x.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='NW103-01'));

INSERT INTO enrollments (student_id, section_id, status, registered_at)
SELECT (SELECT id FROM students WHERE student_code='DEMO26006'), (SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='BA101-01'), 'REGISTERED', '2026-08-30 09:00:00'
WHERE NOT EXISTS (SELECT 1 FROM enrollments x WHERE x.student_id=(SELECT id FROM students WHERE student_code='DEMO26006') AND x.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='BA101-01'));

INSERT INTO enrollments (student_id, section_id, status, registered_at)
SELECT (SELECT id FROM students WHERE student_code='DEMO26001'), (SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2' AND cs.section_code='WD104-01'), 'REGISTERED', '2026-11-03 09:00:00'
WHERE NOT EXISTS (SELECT 1 FROM enrollments x WHERE x.student_id=(SELECT id FROM students WHERE student_code='DEMO26001') AND x.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2' AND cs.section_code='WD104-01'));

INSERT INTO enrollments (student_id, section_id, status, registered_at)
SELECT (SELECT id FROM students WHERE student_code='DEMO26002'), (SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2' AND cs.section_code='WD104-01'), 'REGISTERED', '2026-11-03 09:00:00'
WHERE NOT EXISTS (SELECT 1 FROM enrollments x WHERE x.student_id=(SELECT id FROM students WHERE student_code='DEMO26002') AND x.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2' AND cs.section_code='WD104-01'));

INSERT INTO grade_sheets (section_id, status, published_at)
SELECT (SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01'), 'PUBLISHED', '2026-10-28 15:00:00'
WHERE NOT EXISTS (SELECT 1 FROM grade_sheets x WHERE x.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01'));

INSERT INTO grade_sheets (section_id, status, published_at)
SELECT (SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01'), 'DRAFT', NULL
WHERE NOT EXISTS (SELECT 1 FROM grade_sheets x WHERE x.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01'));

INSERT INTO grade_sheets (section_id, status, published_at)
SELECT (SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='NW103-01'), 'DRAFT', NULL
WHERE NOT EXISTS (SELECT 1 FROM grade_sheets x WHERE x.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='NW103-01'));

INSERT INTO grade_sheets (section_id, status, published_at)
SELECT (SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='BA101-01'), 'VERIFIED', NULL
WHERE NOT EXISTS (SELECT 1 FROM grade_sheets x WHERE x.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='BA101-01'));

INSERT INTO grades (enrollment_id, attendance_score, midterm_score, final_score, remark)
SELECT (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26001') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')), 8.5, 8, 9, 'Kết quả tốt'
WHERE NOT EXISTS (SELECT 1 FROM grades x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26001') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')));

INSERT INTO grades (enrollment_id, attendance_score, midterm_score, final_score, remark)
SELECT (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26002') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')), 7, 7.5, 8, 'Đạt yêu cầu'
WHERE NOT EXISTS (SELECT 1 FROM grades x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26002') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')));

INSERT INTO grades (enrollment_id, attendance_score, midterm_score, final_score, remark)
SELECT (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26003') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')), 9, 8, 9, 'Kết quả tốt'
WHERE NOT EXISTS (SELECT 1 FROM grades x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26003') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')));

INSERT INTO grades (enrollment_id, attendance_score, midterm_score, final_score, remark)
SELECT (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26004') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')), 6, 6.5, 7, 'Cần luyện tập thêm'
WHERE NOT EXISTS (SELECT 1 FROM grades x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26004') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')));

INSERT INTO grades (enrollment_id, attendance_score, midterm_score, final_score, remark)
SELECT (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26001') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01')), 8, 7.5, NULL, 'Đang chờ thi cuối kỳ'
WHERE NOT EXISTS (SELECT 1 FROM grades x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26001') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01')));

INSERT INTO grades (enrollment_id, attendance_score, midterm_score, final_score, remark)
SELECT (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26002') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01')), 7, 7, NULL, 'Đang nhập điểm'
WHERE NOT EXISTS (SELECT 1 FROM grades x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26002') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01')));

INSERT INTO grades (enrollment_id, attendance_score, midterm_score, final_score, remark)
SELECT (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26006') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='BA101-01')), 8, 8, 8.5, 'Chờ duyệt cuối'
WHERE NOT EXISTS (SELECT 1 FROM grades x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26006') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='BA101-01')));

INSERT INTO grade_reviews (sheet_id, actor_user_id, action, note, created_at, event_key)
SELECT (SELECT gs.id FROM grade_sheets gs WHERE gs.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')), (SELECT id FROM users WHERE username='lecturer_demo_01'), 'SUBMIT', 'Giảng viên gửi bảng điểm', '2026-10-27 09:00:00', 'DEMO-GRADE-SE101-SUBMIT'
WHERE NOT EXISTS (SELECT 1 FROM grade_reviews x WHERE x.event_key='DEMO-GRADE-SE101-SUBMIT');

INSERT INTO grade_reviews (sheet_id, actor_user_id, action, note, created_at, event_key)
SELECT (SELECT gs.id FROM grade_sheets gs WHERE gs.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')), (SELECT id FROM users WHERE username='training_demo'), 'VERIFY', 'Phòng đào tạo kiểm tra', '2026-10-27 14:00:00', 'DEMO-GRADE-SE101-VERIFY'
WHERE NOT EXISTS (SELECT 1 FROM grade_reviews x WHERE x.event_key='DEMO-GRADE-SE101-VERIFY');

INSERT INTO grade_reviews (sheet_id, actor_user_id, action, note, created_at, event_key)
SELECT (SELECT gs.id FROM grade_sheets gs WHERE gs.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')), (SELECT id FROM users WHERE username='principal_demo'), 'APPROVE', 'Cấp trên phê duyệt', '2026-10-28 09:00:00', 'DEMO-GRADE-SE101-APPROVE'
WHERE NOT EXISTS (SELECT 1 FROM grade_reviews x WHERE x.event_key='DEMO-GRADE-SE101-APPROVE');

INSERT INTO grade_reviews (sheet_id, actor_user_id, action, note, created_at, event_key)
SELECT (SELECT gs.id FROM grade_sheets gs WHERE gs.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')), (SELECT id FROM users WHERE username='training_demo'), 'PUBLISH', 'Đã công bố chính thức', '2026-10-28 15:00:00', 'DEMO-GRADE-SE101-PUBLISH'
WHERE NOT EXISTS (SELECT 1 FROM grade_reviews x WHERE x.event_key='DEMO-GRADE-SE101-PUBLISH');

INSERT INTO grade_reviews (sheet_id, actor_user_id, action, note, created_at, event_key)
SELECT (SELECT gs.id FROM grade_sheets gs WHERE gs.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='BA101-01')), (SELECT id FROM users WHERE username='lecturer_demo_03'), 'SUBMIT', 'Giảng viên gửi', '2026-10-30 09:00:00', 'DEMO-GRADE-BA101-SUBMIT'
WHERE NOT EXISTS (SELECT 1 FROM grade_reviews x WHERE x.event_key='DEMO-GRADE-BA101-SUBMIT');

INSERT INTO grade_reviews (sheet_id, actor_user_id, action, note, created_at, event_key)
SELECT (SELECT gs.id FROM grade_sheets gs WHERE gs.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='BA101-01')), (SELECT id FROM users WHERE username='training_demo'), 'VERIFY', 'Phòng đào tạo đã kiểm tra', '2026-10-31 11:00:00', 'DEMO-GRADE-BA101-VERIFY'
WHERE NOT EXISTS (SELECT 1 FROM grade_reviews x WHERE x.event_key='DEMO-GRADE-BA101-VERIFY');

INSERT INTO tuition_rates (semester_id, price_per_credit)
SELECT (SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'), 850000.00
WHERE NOT EXISTS (SELECT 1 FROM tuition_rates x WHERE x.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'));

INSERT INTO tuition_rates (semester_id, price_per_credit)
SELECT (SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2'), 900000.00
WHERE NOT EXISTS (SELECT 1 FROM tuition_rates x WHERE x.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2'));

INSERT INTO invoices (student_id, semester_id, discount_amount, issued_at)
SELECT (SELECT id FROM students WHERE student_code='DEMO26001'), (SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'), 0, '2026-09-20 08:00:00'
WHERE NOT EXISTS (SELECT 1 FROM invoices x WHERE x.student_id=(SELECT id FROM students WHERE student_code='DEMO26001') AND x.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'));

INSERT INTO invoices (student_id, semester_id, discount_amount, issued_at)
SELECT (SELECT id FROM students WHERE student_code='DEMO26002'), (SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'), 500000, '2026-09-20 08:00:00'
WHERE NOT EXISTS (SELECT 1 FROM invoices x WHERE x.student_id=(SELECT id FROM students WHERE student_code='DEMO26002') AND x.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'));

INSERT INTO invoices (student_id, semester_id, discount_amount, issued_at)
SELECT (SELECT id FROM students WHERE student_code='DEMO26003'), (SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'), 0, '2026-09-20 08:00:00'
WHERE NOT EXISTS (SELECT 1 FROM invoices x WHERE x.student_id=(SELECT id FROM students WHERE student_code='DEMO26003') AND x.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'));

INSERT INTO invoices (student_id, semester_id, discount_amount, issued_at)
SELECT (SELECT id FROM students WHERE student_code='DEMO26004'), (SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'), 0, '2026-09-20 08:00:00'
WHERE NOT EXISTS (SELECT 1 FROM invoices x WHERE x.student_id=(SELECT id FROM students WHERE student_code='DEMO26004') AND x.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'));

INSERT INTO invoices (student_id, semester_id, discount_amount, issued_at)
SELECT (SELECT id FROM students WHERE student_code='DEMO25005'), (SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'), 0, '2026-09-20 08:00:00'
WHERE NOT EXISTS (SELECT 1 FROM invoices x WHERE x.student_id=(SELECT id FROM students WHERE student_code='DEMO25005') AND x.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'));

INSERT INTO invoices (student_id, semester_id, discount_amount, issued_at)
SELECT (SELECT id FROM students WHERE student_code='DEMO26006'), (SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'), 0, '2026-09-20 08:00:00'
WHERE NOT EXISTS (SELECT 1 FROM invoices x WHERE x.student_id=(SELECT id FROM students WHERE student_code='DEMO26006') AND x.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'));

INSERT INTO invoices (student_id, semester_id, discount_amount, issued_at)
SELECT (SELECT id FROM students WHERE student_code='DEMO26001'), (SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2'), 0, '2026-11-04 08:00:00'
WHERE NOT EXISTS (SELECT 1 FROM invoices x WHERE x.student_id=(SELECT id FROM students WHERE student_code='DEMO26001') AND x.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2'));

INSERT INTO invoices (student_id, semester_id, discount_amount, issued_at)
SELECT (SELECT id FROM students WHERE student_code='DEMO26002'), (SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2'), 0, '2026-11-04 08:00:00'
WHERE NOT EXISTS (SELECT 1 FROM invoices x WHERE x.student_id=(SELECT id FROM students WHERE student_code='DEMO26002') AND x.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2'));

INSERT INTO invoice_items (invoice_id, enrollment_id, credits_at_issue, unit_price_at_issue)
SELECT (SELECT i.id FROM invoices i WHERE i.student_id=(SELECT id FROM students WHERE student_code='DEMO26001') AND i.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1')), (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26001') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')), (SELECT c.credits FROM enrollments e JOIN course_sections cs ON cs.id=e.section_id JOIN courses c ON c.id=cs.course_id WHERE e.id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26001') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01'))), (SELECT tr.price_per_credit FROM tuition_rates tr WHERE tr.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'))
WHERE NOT EXISTS (SELECT 1 FROM invoice_items x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26001') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')));

INSERT INTO invoice_items (invoice_id, enrollment_id, credits_at_issue, unit_price_at_issue)
SELECT (SELECT i.id FROM invoices i WHERE i.student_id=(SELECT id FROM students WHERE student_code='DEMO26001') AND i.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1')), (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26001') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01')), (SELECT c.credits FROM enrollments e JOIN course_sections cs ON cs.id=e.section_id JOIN courses c ON c.id=cs.course_id WHERE e.id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26001') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01'))), (SELECT tr.price_per_credit FROM tuition_rates tr WHERE tr.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'))
WHERE NOT EXISTS (SELECT 1 FROM invoice_items x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26001') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01')));

INSERT INTO invoice_items (invoice_id, enrollment_id, credits_at_issue, unit_price_at_issue)
SELECT (SELECT i.id FROM invoices i WHERE i.student_id=(SELECT id FROM students WHERE student_code='DEMO26001') AND i.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1')), (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26001') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='NW103-01')), (SELECT c.credits FROM enrollments e JOIN course_sections cs ON cs.id=e.section_id JOIN courses c ON c.id=cs.course_id WHERE e.id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26001') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='NW103-01'))), (SELECT tr.price_per_credit FROM tuition_rates tr WHERE tr.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'))
WHERE NOT EXISTS (SELECT 1 FROM invoice_items x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26001') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='NW103-01')));

INSERT INTO invoice_items (invoice_id, enrollment_id, credits_at_issue, unit_price_at_issue)
SELECT (SELECT i.id FROM invoices i WHERE i.student_id=(SELECT id FROM students WHERE student_code='DEMO26002') AND i.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1')), (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26002') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')), (SELECT c.credits FROM enrollments e JOIN course_sections cs ON cs.id=e.section_id JOIN courses c ON c.id=cs.course_id WHERE e.id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26002') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01'))), (SELECT tr.price_per_credit FROM tuition_rates tr WHERE tr.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'))
WHERE NOT EXISTS (SELECT 1 FROM invoice_items x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26002') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')));

INSERT INTO invoice_items (invoice_id, enrollment_id, credits_at_issue, unit_price_at_issue)
SELECT (SELECT i.id FROM invoices i WHERE i.student_id=(SELECT id FROM students WHERE student_code='DEMO26002') AND i.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1')), (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26002') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01')), (SELECT c.credits FROM enrollments e JOIN course_sections cs ON cs.id=e.section_id JOIN courses c ON c.id=cs.course_id WHERE e.id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26002') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01'))), (SELECT tr.price_per_credit FROM tuition_rates tr WHERE tr.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'))
WHERE NOT EXISTS (SELECT 1 FROM invoice_items x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26002') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01')));

INSERT INTO invoice_items (invoice_id, enrollment_id, credits_at_issue, unit_price_at_issue)
SELECT (SELECT i.id FROM invoices i WHERE i.student_id=(SELECT id FROM students WHERE student_code='DEMO26003') AND i.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1')), (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26003') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')), (SELECT c.credits FROM enrollments e JOIN course_sections cs ON cs.id=e.section_id JOIN courses c ON c.id=cs.course_id WHERE e.id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26003') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01'))), (SELECT tr.price_per_credit FROM tuition_rates tr WHERE tr.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'))
WHERE NOT EXISTS (SELECT 1 FROM invoice_items x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26003') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')));

INSERT INTO invoice_items (invoice_id, enrollment_id, credits_at_issue, unit_price_at_issue)
SELECT (SELECT i.id FROM invoices i WHERE i.student_id=(SELECT id FROM students WHERE student_code='DEMO26003') AND i.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1')), (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26003') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='NW103-01')), (SELECT c.credits FROM enrollments e JOIN course_sections cs ON cs.id=e.section_id JOIN courses c ON c.id=cs.course_id WHERE e.id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26003') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='NW103-01'))), (SELECT tr.price_per_credit FROM tuition_rates tr WHERE tr.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'))
WHERE NOT EXISTS (SELECT 1 FROM invoice_items x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26003') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='NW103-01')));

INSERT INTO invoice_items (invoice_id, enrollment_id, credits_at_issue, unit_price_at_issue)
SELECT (SELECT i.id FROM invoices i WHERE i.student_id=(SELECT id FROM students WHERE student_code='DEMO26004') AND i.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1')), (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26004') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')), (SELECT c.credits FROM enrollments e JOIN course_sections cs ON cs.id=e.section_id JOIN courses c ON c.id=cs.course_id WHERE e.id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26004') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01'))), (SELECT tr.price_per_credit FROM tuition_rates tr WHERE tr.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'))
WHERE NOT EXISTS (SELECT 1 FROM invoice_items x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26004') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')));

INSERT INTO invoice_items (invoice_id, enrollment_id, credits_at_issue, unit_price_at_issue)
SELECT (SELECT i.id FROM invoices i WHERE i.student_id=(SELECT id FROM students WHERE student_code='DEMO25005') AND i.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1')), (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO25005') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01')), (SELECT c.credits FROM enrollments e JOIN course_sections cs ON cs.id=e.section_id JOIN courses c ON c.id=cs.course_id WHERE e.id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO25005') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01'))), (SELECT tr.price_per_credit FROM tuition_rates tr WHERE tr.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'))
WHERE NOT EXISTS (SELECT 1 FROM invoice_items x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO25005') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01')));

INSERT INTO invoice_items (invoice_id, enrollment_id, credits_at_issue, unit_price_at_issue)
SELECT (SELECT i.id FROM invoices i WHERE i.student_id=(SELECT id FROM students WHERE student_code='DEMO25005') AND i.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1')), (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO25005') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='NW103-01')), (SELECT c.credits FROM enrollments e JOIN course_sections cs ON cs.id=e.section_id JOIN courses c ON c.id=cs.course_id WHERE e.id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO25005') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='NW103-01'))), (SELECT tr.price_per_credit FROM tuition_rates tr WHERE tr.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'))
WHERE NOT EXISTS (SELECT 1 FROM invoice_items x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO25005') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='NW103-01')));

INSERT INTO invoice_items (invoice_id, enrollment_id, credits_at_issue, unit_price_at_issue)
SELECT (SELECT i.id FROM invoices i WHERE i.student_id=(SELECT id FROM students WHERE student_code='DEMO26006') AND i.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1')), (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26006') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='BA101-01')), (SELECT c.credits FROM enrollments e JOIN course_sections cs ON cs.id=e.section_id JOIN courses c ON c.id=cs.course_id WHERE e.id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26006') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='BA101-01'))), (SELECT tr.price_per_credit FROM tuition_rates tr WHERE tr.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'))
WHERE NOT EXISTS (SELECT 1 FROM invoice_items x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26006') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='BA101-01')));

INSERT INTO invoice_items (invoice_id, enrollment_id, credits_at_issue, unit_price_at_issue)
SELECT (SELECT i.id FROM invoices i WHERE i.student_id=(SELECT id FROM students WHERE student_code='DEMO26001') AND i.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2')), (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26001') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2' AND cs.section_code='WD104-01')), (SELECT c.credits FROM enrollments e JOIN course_sections cs ON cs.id=e.section_id JOIN courses c ON c.id=cs.course_id WHERE e.id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26001') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2' AND cs.section_code='WD104-01'))), (SELECT tr.price_per_credit FROM tuition_rates tr WHERE tr.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2'))
WHERE NOT EXISTS (SELECT 1 FROM invoice_items x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26001') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2' AND cs.section_code='WD104-01')));

INSERT INTO invoice_items (invoice_id, enrollment_id, credits_at_issue, unit_price_at_issue)
SELECT (SELECT i.id FROM invoices i WHERE i.student_id=(SELECT id FROM students WHERE student_code='DEMO26002') AND i.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2')), (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26002') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2' AND cs.section_code='WD104-01')), (SELECT c.credits FROM enrollments e JOIN course_sections cs ON cs.id=e.section_id JOIN courses c ON c.id=cs.course_id WHERE e.id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26002') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2' AND cs.section_code='WD104-01'))), (SELECT tr.price_per_credit FROM tuition_rates tr WHERE tr.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2'))
WHERE NOT EXISTS (SELECT 1 FROM invoice_items x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='DEMO26002') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2' AND cs.section_code='WD104-01')));

INSERT INTO payments (invoice_id, recorded_by, amount, paid_at, reference_no, note)
SELECT (SELECT i.id FROM invoices i WHERE i.student_id=(SELECT id FROM students WHERE student_code='DEMO26001') AND i.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1')), (SELECT id FROM users WHERE username='training_demo'), 6800000.00, '2026-09-25 10:00:00', 'DEMO-PAY-001', 'Giao dịch giả lập - không phải thu tiền thật'
WHERE NOT EXISTS (SELECT 1 FROM payments x WHERE x.reference_no='DEMO-PAY-001');

INSERT INTO payments (invoice_id, recorded_by, amount, paid_at, reference_no, note)
SELECT (SELECT i.id FROM invoices i WHERE i.student_id=(SELECT id FROM students WHERE student_code='DEMO26002') AND i.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1')), (SELECT id FROM users WHERE username='training_demo'), 1000000.00, '2026-10-01 10:00:00', 'DEMO-PAY-002', 'Giao dịch giả lập - không phải thu tiền thật'
WHERE NOT EXISTS (SELECT 1 FROM payments x WHERE x.reference_no='DEMO-PAY-002');

INSERT INTO payments (invoice_id, recorded_by, amount, paid_at, reference_no, note)
SELECT (SELECT i.id FROM invoices i WHERE i.student_id=(SELECT id FROM students WHERE student_code='DEMO26006') AND i.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1')), (SELECT id FROM users WHERE username='training_demo'), 2550000.00, '2026-10-02 10:00:00', 'DEMO-PAY-003', 'Giao dịch giả lập - không phải thu tiền thật'
WHERE NOT EXISTS (SELECT 1 FROM payments x WHERE x.reference_no='DEMO-PAY-003');

INSERT INTO student_requests (request_code, student_id, request_type, content, status, handled_by, response, created_at, handled_at)
SELECT 'DEMO-REQ-001', (SELECT id FROM students WHERE student_code='DEMO26001'), 'PROFILE_UPDATE', 'Yêu cầu chỉnh sửa số điện thoại demo', 'RESOLVED', (SELECT id FROM users WHERE username='training_demo'), 'Đã đối chiếu thông tin demo', '2026-10-20 09:00:00', '2026-10-21 09:00:00'
WHERE NOT EXISTS (SELECT 1 FROM student_requests x WHERE x.request_code='DEMO-REQ-001');

INSERT INTO student_requests (request_code, student_id, request_type, content, status, handled_by, response, created_at, handled_at)
SELECT 'DEMO-REQ-002', (SELECT id FROM students WHERE student_code='DEMO26003'), 'GRADE_QUESTION', 'Yêu cầu giải thích điểm chuyên cần demo', 'PENDING', NULL, NULL, '2026-11-04 14:00:00', NULL
WHERE NOT EXISTS (SELECT 1 FROM student_requests x WHERE x.request_code='DEMO-REQ-002');

INSERT INTO notifications (notification_code, created_by, title, body, created_at)
SELECT 'DEMO-NOTI-HK2', (SELECT id FROM users WHERE username='training_demo'), 'Mở đăng ký HK2', 'Thông báo minh họa: lịch đăng ký học phần HK2', '2026-11-01 08:00:00'
WHERE NOT EXISTS (SELECT 1 FROM notifications x WHERE x.notification_code='DEMO-NOTI-HK2');

INSERT INTO notifications (notification_code, created_by, title, body, created_at)
SELECT 'DEMO-NOTI-GRADE', (SELECT id FROM users WHERE username='training_demo'), 'Công bố điểm SE101', 'Thông báo minh họa: bảng điểm SE101 đã công bố', '2026-10-28 15:00:00'
WHERE NOT EXISTS (SELECT 1 FROM notifications x WHERE x.notification_code='DEMO-NOTI-GRADE');

INSERT INTO notification_recipients (notification_id, user_id)
SELECT (SELECT id FROM notifications WHERE notification_code='DEMO-NOTI-HK2'), (SELECT id FROM users WHERE username='student_demo_001')
WHERE NOT EXISTS (SELECT 1 FROM notification_recipients x WHERE x.notification_id=(SELECT id FROM notifications WHERE notification_code='DEMO-NOTI-HK2') AND x.user_id=(SELECT id FROM users WHERE username='student_demo_001'));

INSERT INTO notification_recipients (notification_id, user_id)
SELECT (SELECT id FROM notifications WHERE notification_code='DEMO-NOTI-HK2'), (SELECT id FROM users WHERE username='student_demo_002')
WHERE NOT EXISTS (SELECT 1 FROM notification_recipients x WHERE x.notification_id=(SELECT id FROM notifications WHERE notification_code='DEMO-NOTI-HK2') AND x.user_id=(SELECT id FROM users WHERE username='student_demo_002'));

INSERT INTO notification_recipients (notification_id, user_id)
SELECT (SELECT id FROM notifications WHERE notification_code='DEMO-NOTI-HK2'), (SELECT id FROM users WHERE username='student_demo_003')
WHERE NOT EXISTS (SELECT 1 FROM notification_recipients x WHERE x.notification_id=(SELECT id FROM notifications WHERE notification_code='DEMO-NOTI-HK2') AND x.user_id=(SELECT id FROM users WHERE username='student_demo_003'));

INSERT INTO notification_recipients (notification_id, user_id)
SELECT (SELECT id FROM notifications WHERE notification_code='DEMO-NOTI-HK2'), (SELECT id FROM users WHERE username='student_demo_004')
WHERE NOT EXISTS (SELECT 1 FROM notification_recipients x WHERE x.notification_id=(SELECT id FROM notifications WHERE notification_code='DEMO-NOTI-HK2') AND x.user_id=(SELECT id FROM users WHERE username='student_demo_004'));

INSERT INTO notification_recipients (notification_id, user_id)
SELECT (SELECT id FROM notifications WHERE notification_code='DEMO-NOTI-HK2'), (SELECT id FROM users WHERE username='student_demo_005')
WHERE NOT EXISTS (SELECT 1 FROM notification_recipients x WHERE x.notification_id=(SELECT id FROM notifications WHERE notification_code='DEMO-NOTI-HK2') AND x.user_id=(SELECT id FROM users WHERE username='student_demo_005'));

INSERT INTO notification_recipients (notification_id, user_id)
SELECT (SELECT id FROM notifications WHERE notification_code='DEMO-NOTI-HK2'), (SELECT id FROM users WHERE username='student_demo_006')
WHERE NOT EXISTS (SELECT 1 FROM notification_recipients x WHERE x.notification_id=(SELECT id FROM notifications WHERE notification_code='DEMO-NOTI-HK2') AND x.user_id=(SELECT id FROM users WHERE username='student_demo_006'));

INSERT INTO notification_recipients (notification_id, user_id)
SELECT (SELECT id FROM notifications WHERE notification_code='DEMO-NOTI-GRADE'), (SELECT id FROM users WHERE username='student_demo_001')
WHERE NOT EXISTS (SELECT 1 FROM notification_recipients x WHERE x.notification_id=(SELECT id FROM notifications WHERE notification_code='DEMO-NOTI-GRADE') AND x.user_id=(SELECT id FROM users WHERE username='student_demo_001'));

INSERT INTO notification_recipients (notification_id, user_id)
SELECT (SELECT id FROM notifications WHERE notification_code='DEMO-NOTI-GRADE'), (SELECT id FROM users WHERE username='student_demo_002')
WHERE NOT EXISTS (SELECT 1 FROM notification_recipients x WHERE x.notification_id=(SELECT id FROM notifications WHERE notification_code='DEMO-NOTI-GRADE') AND x.user_id=(SELECT id FROM users WHERE username='student_demo_002'));

INSERT INTO notification_recipients (notification_id, user_id)
SELECT (SELECT id FROM notifications WHERE notification_code='DEMO-NOTI-GRADE'), (SELECT id FROM users WHERE username='student_demo_003')
WHERE NOT EXISTS (SELECT 1 FROM notification_recipients x WHERE x.notification_id=(SELECT id FROM notifications WHERE notification_code='DEMO-NOTI-GRADE') AND x.user_id=(SELECT id FROM users WHERE username='student_demo_003'));

INSERT INTO notification_recipients (notification_id, user_id)
SELECT (SELECT id FROM notifications WHERE notification_code='DEMO-NOTI-GRADE'), (SELECT id FROM users WHERE username='student_demo_004')
WHERE NOT EXISTS (SELECT 1 FROM notification_recipients x WHERE x.notification_id=(SELECT id FROM notifications WHERE notification_code='DEMO-NOTI-GRADE') AND x.user_id=(SELECT id FROM users WHERE username='student_demo_004'));

INSERT INTO audit_logs (actor_user_id, action, entity_type, entity_id, detail_json, event_key, created_at)
SELECT (SELECT id FROM users WHERE username='training_demo'), 'PUBLISH_GRADE_SHEET', 'grade_sheets', 'SE101-01', CAST('{"demo": true, "result": "PUBLISHED"}' AS JSON), 'DEMO-AUDIT-GRADE', '2026-10-28 15:00:00'
WHERE NOT EXISTS (SELECT 1 FROM audit_logs x WHERE x.event_key='DEMO-AUDIT-GRADE');

INSERT INTO audit_logs (actor_user_id, action, entity_type, entity_id, detail_json, event_key, created_at)
SELECT (SELECT id FROM users WHERE username='training_demo'), 'RECORD_PAYMENT', 'payments', 'DEMO-PAY-001', CAST('{"demo": true, "amount": 6800000}' AS JSON), 'DEMO-AUDIT-PAY', '2026-09-25 10:00:00'
WHERE NOT EXISTS (SELECT 1 FROM audit_logs x WHERE x.event_key='DEMO-AUDIT-PAY');

INSERT INTO audit_logs (actor_user_id, action, entity_type, entity_id, detail_json, event_key, created_at)
SELECT (SELECT id FROM users WHERE username='training_demo'), 'RESOLVE_REQUEST', 'student_requests', 'DEMO-REQ-001', CAST('{"demo": true, "result": "RESOLVED"}' AS JSON), 'DEMO-AUDIT-REQUEST', '2026-10-21 09:00:00'
WHERE NOT EXISTS (SELECT 1 FROM audit_logs x WHERE x.event_key='DEMO-AUDIT-REQUEST');

COMMIT;
-- Done. Run 03_validate_sms.sql. Re-running this script only adds missing demo keys.
-- Do NOT use this seed as real university or financial records.


-- =============================================================================
-- SMS V4 demo: fictional identities only; safe to execute repeatedly.
-- Run 01 -> 02 -> 04 -> 05. All users remain disabled, all emails .test.
-- No real mailbox or money transfer occurs by executing SQL.
-- =============================================================================
USE sms_v6_original;
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO roles(code,description) SELECT 'CTSV','Phòng Công tác sinh viên: hồ sơ, hỗ trợ, thu học phí'
WHERE NOT EXISTS(SELECT 1 FROM roles WHERE code='CTSV');
INSERT INTO roles(code,description) SELECT 'APPLICANT','Người nộp hồ sơ trực tuyến chưa có MSSV'
WHERE NOT EXISTS(SELECT 1 FROM roles WHERE code='APPLICANT');

INSERT INTO users(username,email,password_hash,full_name,enabled)
SELECT 'ctsv_demo','ctsv_demo@example.test','!ACCOUNT_DISABLED','Cán bộ CTSV mô phỏng',FALSE
WHERE NOT EXISTS(SELECT 1 FROM users WHERE username='ctsv_demo');
INSERT INTO users(username,email,password_hash,full_name,enabled)
SELECT 'applicant_demo_03','applicant_demo_03@example.test','!ACCOUNT_DISABLED','Người nộp hồ sơ mẫu 03',FALSE
WHERE NOT EXISTS(SELECT 1 FROM users WHERE username='applicant_demo_03');

INSERT INTO user_roles(user_id,role_id)
SELECT u.id,r.id FROM users u JOIN roles r ON r.code='CTSV'
WHERE u.username='ctsv_demo' AND NOT EXISTS(
 SELECT 1 FROM user_roles x WHERE x.user_id=u.id AND x.role_id=r.id);
INSERT INTO user_roles(user_id,role_id)
SELECT u.id,r.id FROM users u JOIN roles r ON r.code='APPLICANT'
WHERE u.username='applicant_demo_03' AND NOT EXISTS(
 SELECT 1 FROM user_roles x WHERE x.user_id=u.id AND x.role_id=r.id);

INSERT INTO admission_periods(code,title,cohort_id,opens_at,closes_at,status)
SELECT 'NH-DEMO-V4-2026','Tiếp nhận hồ sơ thử nghiệm',c.id,
 '2026-07-01 08:00:00','2026-12-31 17:00:00','OPEN'
FROM cohorts c WHERE c.code='K2026'
 AND NOT EXISTS(SELECT 1 FROM admission_periods p WHERE p.code='NH-DEMO-V4-2026');

INSERT INTO admission_document_requirements(period_id,document_type,label,is_required)
SELECT p.id,x.document_type,x.label,TRUE FROM admission_periods p JOIN (
 SELECT 'ID_CARD' AS document_type,'Giấy tờ định danh' AS label
 UNION ALL SELECT 'SCHOOL_TRANSCRIPT','Học bạ / bảng điểm'
 UNION ALL SELECT 'PORTRAIT','Ảnh chân dung'
) x WHERE p.code='NH-DEMO-V4-2026' AND NOT EXISTS(
 SELECT 1 FROM admission_document_requirements req
 WHERE req.period_id=p.id AND req.document_type=x.document_type);

INSERT INTO admission_applications
(application_code,applicant_user_id,period_id,major_id,phone,date_of_birth,status,submitted_at,
 legal_full_name,personal_email,place_of_birth,hometown,permanent_address,current_address)
SELECT 'APP-DEMO-V4-003',u.id,p.id,m.id,'0000000000','2008-04-12',
 'SENT_TO_SCHOOL','2026-11-05 09:00:00',u.full_name,u.email,
 'Địa điểm giả lập','Quê quán giả lập','Địa chỉ giả lập A','Địa chỉ giả lập B'
FROM users u JOIN admission_periods p ON p.code='NH-DEMO-V4-2026'
JOIN majors m ON m.code='KTPM' WHERE u.username='applicant_demo_03'
AND NOT EXISTS(SELECT 1 FROM admission_applications a WHERE a.application_code='APP-DEMO-V4-003');

-- Uploaded file metadata here are fictional pointers; no real file is created.
INSERT INTO admission_documents
(application_id,document_type,revision_no,file_name,storage_key,mime_type,size_bytes,status,checked_by,checked_at)
SELECT a.id,x.document_type,1,x.file_name,x.storage_key,x.mime_type,2048,'VERIFIED',
  (SELECT id FROM users WHERE username='ctsv_demo'),'2026-11-06 08:30:00'
FROM admission_applications a JOIN (
 SELECT 'ID_CARD' AS document_type,'id_demo.pdf' AS file_name,
 'demo-only/v4/003/id.pdf' AS storage_key,'application/pdf' AS mime_type
 UNION ALL SELECT 'SCHOOL_TRANSCRIPT','transcript_demo.pdf','demo-only/v4/003/transcript.pdf','application/pdf'
 UNION ALL SELECT 'PORTRAIT','photo_demo.png','demo-only/v4/003/photo.png','image/png'
) x WHERE a.application_code='APP-DEMO-V4-003' AND NOT EXISTS(
 SELECT 1 FROM admission_documents d WHERE d.application_id=a.id
 AND d.document_type=x.document_type AND d.revision_no=1);

INSERT INTO admission_review_events(application_id,actor_user_id,event_type,from_status,to_status,note,event_key,created_at)
SELECT a.id,u.id,'APPROVE','IN_REVIEW','CTSV_APPROVED',
 'CTSV xác minh đủ giấy tờ giả lập','V4-APP-003-CTSV-APPROVE','2026-11-06 09:00:00'
FROM admission_applications a JOIN users u ON u.username='ctsv_demo'
WHERE a.application_code='APP-DEMO-V4-003' AND NOT EXISTS(
 SELECT 1 FROM admission_review_events e WHERE e.event_key='V4-APP-003-CTSV-APPROVE');
INSERT INTO admission_review_events(application_id,actor_user_id,event_type,from_status,to_status,note,event_key,created_at)
SELECT a.id,u.id,'SUBMIT_TO_SCHOOL','CTSV_APPROVED','SENT_TO_SCHOOL',
 'Chuyển hồ sơ nhà trường xem xét','V4-APP-003-TO-SCHOOL','2026-11-06 09:10:00'
FROM admission_applications a JOIN users u ON u.username='ctsv_demo'
WHERE a.application_code='APP-DEMO-V4-003' AND NOT EXISTS(
 SELECT 1 FROM admission_review_events e WHERE e.event_key='V4-APP-003-TO-SCHOOL');

-- Demo record for a currently enrolled student, with fictional personal fields.
UPDATE students SET
 place_of_birth=COALESCE(place_of_birth,'Địa điểm mẫu'),
 hometown=COALESCE(hometown,'Quê quán mẫu'),
 permanent_address=COALESCE(permanent_address,'Thường trú mẫu'),
 current_address=COALESCE(current_address,'Nơi ở hiện tại mẫu')
WHERE student_code='DEMO26001';

INSERT INTO student_school_mailboxes(student_id,school_email,provisioning_status,note)
SELECT s.id,'student001@st.example.test','RESERVED',
 'Chỉ đặt trước địa chỉ demo. Chưa tạo mailbox thật hay gửi thư.'
FROM students s WHERE s.student_code='DEMO26001' AND NOT EXISTS(
 SELECT 1 FROM student_school_mailboxes m WHERE m.student_id=s.id);

INSERT INTO ctsv_funds(code,name,channel)
SELECT 'CTSV-CASH-DEMO','Quỹ tiền mặt CTSV mô phỏng','CASH'
WHERE NOT EXISTS(SELECT 1 FROM ctsv_funds WHERE code='CTSV-CASH-DEMO');
INSERT INTO ctsv_funds(code,name,channel)
SELECT 'CTSV-BANK-DEMO','Khoản thu chuyển khoản CTSV mô phỏng','BANK_TRANSFER'
WHERE NOT EXISTS(SELECT 1 FROM ctsv_funds WHERE code='CTSV-BANK-DEMO');

-- A new CTSV-received demo payment; old payments remain untouched/unassigned.
INSERT INTO payments(invoice_id,recorded_by,amount,paid_at,reference_no,note,fund_id)
SELECT i.id,u.id,1000000.00,'2026-11-06 10:00:00','CTSV-V4-DEMO-PAY-001',
 'Giao dịch demo: không có tiền thật',f.id
FROM invoices i JOIN students s ON s.id=i.student_id
JOIN semesters se ON se.id=i.semester_id JOIN academic_years ay ON ay.id=se.academic_year_id
JOIN users u ON u.username='ctsv_demo'
JOIN ctsv_funds f ON f.code='CTSV-CASH-DEMO'
WHERE s.student_code='DEMO26003' AND se.code='HK1' AND ay.name='2026-2027'
AND NOT EXISTS(SELECT 1 FROM payments p WHERE p.reference_no='CTSV-V4-DEMO-PAY-001');

INSERT INTO ctsv_remittances(remittance_code,semester_id,fund_id,amount,status,prepared_by,
 reviewed_by,remitted_at,reviewed_at,external_reference,note)
SELECT 'CTSV-V4-DEMO-REMIT-001',se.id,f.id,600000.00,'CONFIRMED',u.id,adminu.id,
 '2026-11-06 15:00:00','2026-11-06 16:00:00',NULL,
 'Biên bản bàn giao demo (không phải chuyển tiền thật)'
FROM semesters se JOIN academic_years ay ON ay.id=se.academic_year_id
JOIN ctsv_funds f ON f.code='CTSV-CASH-DEMO'
JOIN users u ON u.username='ctsv_demo' JOIN users adminu ON adminu.username='principal_demo'
WHERE se.code='HK1' AND ay.name='2026-2027'
AND EXISTS(SELECT 1 FROM payments p WHERE p.reference_no='CTSV-V4-DEMO-PAY-001')
AND NOT EXISTS(SELECT 1 FROM ctsv_remittances r WHERE r.remittance_code='CTSV-V4-DEMO-REMIT-001');

-- Term not yet finished in demo dates: report stays DRAFT, not submitted early.
INSERT INTO ctsv_semester_reports(report_code,semester_id,prepared_by,status,note)
SELECT 'CTSV-V4-DEMO-REPORT-HK1',se.id,u.id,'DRAFT',
 'Báo cáo thử nghiệm, chưa nộp cuối kỳ'
FROM semesters se JOIN academic_years ay ON ay.id=se.academic_year_id
JOIN users u ON u.username='ctsv_demo'
WHERE se.code='HK1' AND ay.name='2026-2027'
AND NOT EXISTS(SELECT 1 FROM ctsv_semester_reports r WHERE r.report_code='CTSV-V4-DEMO-REPORT-HK1');

-- Queue an admission acknowledgement only to the registered contact email.
INSERT INTO outbound_emails(event_key,admission_application_id,template_code,recipient_email,subject,delivery_status)
SELECT 'CTSV-V4-APP003-ACK',a.id,'ADMISSION_RECEIVED',u.email,'Đã tiếp nhận hồ sơ trực tuyến','QUEUED'
FROM admission_applications a JOIN users u ON u.id=a.applicant_user_id
WHERE a.application_code='APP-DEMO-V4-003' AND u.email IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM outbound_emails x WHERE x.event_key='CTSV-V4-APP003-ACK');

COMMIT;


-- --------------------------------------------------------------------------
-- DEMO V5: HO SO CCCD / HOC BA + DANH MUC GIAY TO BAT BUOC
-- Chung tu mau KHONG CHUA FILE THAT; dung de test quan he va mock UI.
-- Lop danh muc la cau hinh theo dot tiep nhan, khong tao bang rieng trung lap.
-- --------------------------------------------------------------------------
USE sms_v6_original;
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO admission_document_requirements (period_id,document_type,label,is_required)
SELECT p.id,t.document_type,t.label,t.is_required
FROM admission_periods p
JOIN (
    SELECT 'BIRTH_CERTIFICATE' AS document_type,'Giấy khai sinh (bản sao)' AS label,TRUE AS is_required
    UNION ALL SELECT 'GRADUATION_CERTIFICATE','Bằng/giấy chứng nhận tốt nghiệp THPT',TRUE
    UNION ALL SELECT 'PRIORITY_DOCUMENT','Giấy tờ ưu tiên (nếu có)',FALSE
    UNION ALL SELECT 'HEALTH_RECORD','Giấy khám sức khỏe (nếu nhà trường yêu cầu)',FALSE
) t
WHERE p.code='NH-DEMO-V4-2026'
  AND NOT EXISTS (SELECT 1 FROM admission_document_requirements r
                  WHERE r.period_id=p.id AND r.document_type=t.document_type);

-- Ban scan DEMO cho 2 loai giay to moi, vi ho so demo da duoc CTSV chuyen len truong.
-- Trien khai that: chi VERIFIED sau khi can bo xem file va kiem tra do trung khop.
INSERT INTO admission_documents
  (application_id,document_type,revision_no,file_name,storage_key,mime_type,size_bytes,status,checked_by,checked_at)
SELECT a.id,t.document_type,1,t.file_name,t.storage_key,'application/pdf',1024,'VERIFIED',
       (SELECT u.id FROM users u WHERE u.username='ctsv_demo'),'2026-11-06 08:30:00'
FROM admission_applications a
JOIN (
    SELECT 'BIRTH_CERTIFICATE' AS document_type,'birth_demo.pdf' AS file_name,'demo-only/v5/003/birth.pdf' AS storage_key
    UNION ALL SELECT 'GRADUATION_CERTIFICATE','graduation_demo.pdf','demo-only/v5/003/graduation.pdf'
) t
WHERE a.application_code='APP-DEMO-V4-003'
  AND NOT EXISTS (SELECT 1 FROM admission_documents d
                  WHERE d.application_id=a.id AND d.document_type=t.document_type AND d.revision_no=1);

INSERT INTO admission_identity_records
  (application_id,identity_type,identity_last4,issued_on,issued_by)
SELECT a.id,'CCCD','0000','2024-01-01','Cơ quan cấp giả lập'
FROM admission_applications a
WHERE a.application_code='APP-DEMO-V4-003'
AND NOT EXISTS (SELECT 1 FROM admission_identity_records x WHERE x.application_id=a.id);

INSERT INTO admission_high_school_records
  (application_id,school_name,school_province,graduation_year,graduation_status,transcript_average)
SELECT a.id,'THPT DEMO (không có thật)','Tỉnh mô phỏng',2026,'GRADUATED',8.10
FROM admission_applications a
WHERE a.application_code='APP-DEMO-V4-003'
AND NOT EXISTS (SELECT 1 FROM admission_high_school_records x WHERE x.application_id=a.id);

INSERT INTO admission_high_school_scores
  (school_record_id,grade_level,subject_code,average_score)
SELECT hr.id, t.grade_level,t.subject_code,t.average_score
FROM admission_high_school_records hr
JOIN admission_applications a ON a.id=hr.application_id
JOIN (
    SELECT 10 AS grade_level,'TOAN' AS subject_code,7.80 AS average_score
    UNION ALL SELECT 11,'TOAN',8.10
    UNION ALL SELECT 12,'TOAN',8.60
    UNION ALL SELECT 10,'NGU_VAN',8.00
    UNION ALL SELECT 11,'NGU_VAN',8.20
    UNION ALL SELECT 12,'NGU_VAN',8.00
    UNION ALL SELECT 10,'TIENG_ANH',8.10
    UNION ALL SELECT 11,'TIENG_ANH',8.30
    UNION ALL SELECT 12,'TIENG_ANH',8.40
) t
WHERE a.application_code='APP-DEMO-V4-003'
AND NOT EXISTS (SELECT 1 FROM admission_high_school_scores x
                WHERE x.school_record_id=hr.id AND x.grade_level=t.grade_level AND x.subject_code=t.subject_code);
COMMIT;


-- =============================================================================
-- V6 DEMO: HO SO CTSV DA CHUYEN VA BGH DA DUYET, CHUA CAP MSSV
-- Dung chung admission_applications; KHONG co bang studentApprovals doc lap.
-- Mac dinh ENABLED=FALSE, khong co tai khoan dang nhap su dung duoc.
-- =============================================================================
START TRANSACTION;

INSERT INTO users(username,email,password_hash,full_name,enabled)
SELECT 'applicant_demo_04','applicant_demo_04@example.test','!ACCOUNT_DISABLED','Ứng viên mẫu 04',FALSE
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username='applicant_demo_04');

INSERT INTO user_roles(user_id,role_id)
SELECT u.id,r.id FROM users u JOIN roles r ON r.code='APPLICANT'
WHERE u.username='applicant_demo_04'
AND NOT EXISTS (SELECT 1 FROM user_roles ur WHERE ur.user_id=u.id AND ur.role_id=r.id);

INSERT INTO admission_applications
(application_code,applicant_user_id,period_id,major_id,phone,date_of_birth,status,submitted_at,
 legal_full_name,personal_email,place_of_birth,hometown,permanent_address,current_address)
SELECT 'APP-DEMO-V6-004',u.id,p.id,m.id,'0000000000','2008-09-11',
 'SCHOOL_APPROVED','2026-11-06 08:00:00',u.full_name,u.email,
 'Nơi sinh giả lập','Quê quán giả lập','Thường trú giả lập','Nơi ở giả lập'
FROM users u
JOIN admission_periods p ON p.code='NH-DEMO-V4-2026'
JOIN majors m ON m.code='KTPM'
WHERE u.username='applicant_demo_04'
AND NOT EXISTS (SELECT 1 FROM admission_applications a WHERE a.application_code='APP-DEMO-V6-004');

-- Sao chep DANH MUC GIAY TO DA DUOC XAC MINH tu ho so mau, doi storage_key
-- sang nhom gia lap moi; chua co tep vat ly, khong chua thong tin ca nhan that.
INSERT INTO admission_documents
(application_id,document_type,revision_no,file_name,storage_key,mime_type,size_bytes,status,checked_by,checked_at)
SELECT dst.id,src.document_type,1,src.file_name,
       CONCAT('demo-only/v6/004/',src.document_type,
              CASE WHEN src.mime_type='image/png' THEN '.png' ELSE '.pdf' END),
       src.mime_type,src.size_bytes,'VERIFIED',
       (SELECT u.id FROM users u WHERE u.username='ctsv_demo'),'2026-11-06 09:30:00'
FROM admission_applications dst
JOIN admission_applications origin ON origin.application_code='APP-DEMO-V4-003'
JOIN admission_documents src ON src.application_id=origin.id AND src.revision_no=1
WHERE dst.application_code='APP-DEMO-V6-004'
AND NOT EXISTS (SELECT 1 FROM admission_documents d WHERE d.application_id=dst.id AND d.document_type=src.document_type AND d.revision_no=1);

INSERT INTO admission_identity_records(application_id,identity_type,identity_last4)
SELECT a.id,'CCCD','0000' FROM admission_applications a
WHERE a.application_code='APP-DEMO-V6-004'
AND NOT EXISTS (SELECT 1 FROM admission_identity_records i WHERE i.application_id=a.id);

INSERT INTO admission_high_school_records
(application_id,school_name,school_province,graduation_year,graduation_status,transcript_average)
SELECT a.id,'THPT DEMO 04','Tỉnh giả lập',2026,'GRADUATED',8.25
FROM admission_applications a WHERE a.application_code='APP-DEMO-V6-004'
AND NOT EXISTS (SELECT 1 FROM admission_high_school_records h WHERE h.application_id=a.id);

INSERT INTO admission_review_events
(application_id,actor_user_id,event_type,from_status,to_status,note,event_key,created_at)
SELECT a.id,u.id,'APPROVE','IN_REVIEW','CTSV_APPROVED',
 'CTSV xác nhận đủ giấy tờ mô phỏng','V6-APP-004-CTSV-APPROVED','2026-11-06 10:00:00'
FROM admission_applications a JOIN users u ON u.username='ctsv_demo'
WHERE a.application_code='APP-DEMO-V6-004'
AND NOT EXISTS (SELECT 1 FROM admission_review_events e WHERE e.event_key='V6-APP-004-CTSV-APPROVED');

INSERT INTO admission_review_events
(application_id,actor_user_id,event_type,from_status,to_status,note,event_key,created_at)
SELECT a.id,u.id,'SUBMIT_TO_SCHOOL','CTSV_APPROVED','SENT_TO_SCHOOL',
 'CTSV chuyển hồ sơ lên BGH','V6-APP-004-TO-SCHOOL','2026-11-06 10:10:00'
FROM admission_applications a JOIN users u ON u.username='ctsv_demo'
WHERE a.application_code='APP-DEMO-V6-004'
AND NOT EXISTS (SELECT 1 FROM admission_review_events e WHERE e.event_key='V6-APP-004-TO-SCHOOL');

INSERT INTO admission_review_events
(application_id,actor_user_id,event_type,from_status,to_status,note,event_key,created_at)
SELECT a.id,u.id,'SCHOOL_APPROVE','SENT_TO_SCHOOL','SCHOOL_APPROVED',
 'BGH phê duyệt hồ sơ; chờ Phòng Đào tạo cấp MSSV','V6-APP-004-BGH-APPROVE','2026-11-06 14:00:00'
FROM admission_applications a JOIN users u ON u.username='principal_demo'
WHERE a.application_code='APP-DEMO-V6-004'
AND NOT EXISTS (SELECT 1 FROM admission_review_events e WHERE e.event_key='V6-APP-004-BGH-APPROVE');

-- Demo phat sinh hoc phi dang CHO DUYET: CHUA duoc cong cong no.
INSERT INTO tuition_adjustments(adjustment_code,invoice_id,kind,amount,reason,status,requested_by)
SELECT 'ADJ-V6-PENDING-001',i.id,'CREDIT',100000.00,
 'Đề nghị hỗ trợ học phí mô phỏng, chưa được BGH duyệt','REQUESTED',u.id
FROM invoices i
JOIN students s ON s.id=i.student_id
JOIN semesters se ON se.id=i.semester_id
JOIN academic_years ay ON ay.id=se.academic_year_id
JOIN users u ON u.username='ctsv_demo'
WHERE s.student_code='DEMO26003' AND se.code='HK1' AND ay.name='2026-2027'
AND NOT EXISTS (SELECT 1 FROM tuition_adjustments t WHERE t.adjustment_code='ADJ-V6-PENDING-001');
COMMIT;


-- V6: doi soat CHUNG TU THU -> DOT BAN GIAO demo, khong tao lai neu da co.
START TRANSACTION;
INSERT INTO ctsv_remittance_allocations(remittance_id,payment_id,allocated_amount)
SELECT r.id,p.id,600000.00
FROM ctsv_remittances r JOIN payments p ON p.reference_no='CTSV-V4-DEMO-PAY-001'
WHERE r.remittance_code='CTSV-V4-DEMO-REMIT-001'
  AND NOT EXISTS(SELECT 1 FROM ctsv_remittance_allocations x
                 WHERE x.remittance_id=r.id AND x.payment_id=p.id);
COMMIT;

-- =============================================================================
-- STUDENT MANAGEMENT SYSTEM | 03_QUERIES_CHECK.sql - V6
-- CHAY SAU 01_SCHEMA_ALL.sql & 02_SEED_DEMO.sql.
-- TAP TRUNG TOAN BO VIEW, QUERY TRA CUU, KIEM TRA TRUNG VA TOAN VEN.
-- CHAY LAI AN TOAN: CREATE OR REPLACE VIEW VA SELECT (KHONG CHINH SUA DATA).
-- KHI CSDL TRONG, DU KIEN 47 BANG + cac VIEW bao cao truong. Neu co V3 Google: co the co
-- them bang auth_identities cu (KHONG TU XOA DU LIEU).
-- =============================================================================
USE sms_v6_original;
SET NAMES utf8mb4;

-- =============== CAC VIEW PHUC VU API / BAO CAO ===========================
-- VIEW: v_student_results
CREATE OR REPLACE VIEW v_student_results AS
SELECT e.id AS enrollment_id, s.id AS student_id, s.student_code,
       cs.id AS section_id, cs.section_code,
       c.course_code, c.credits,
       gs.status AS grade_sheet_status,
       g.attendance_score, g.midterm_score, g.final_score,
       CASE WHEN g.attendance_score IS NOT NULL
                  AND g.midterm_score IS NOT NULL AND g.final_score IS NOT NULL
            THEN ROUND((g.attendance_score * cs.attendance_weight
                      + g.midterm_score * cs.midterm_weight
                      + g.final_score * cs.final_weight) / 100.00, 2)
            ELSE NULL END AS total_score
FROM enrollments e
JOIN students s ON s.id = e.student_id
JOIN course_sections cs ON cs.id = e.section_id
JOIN courses c ON c.id = cs.course_id
LEFT JOIN grades g ON g.enrollment_id = e.id
LEFT JOIN grade_sheets gs ON gs.section_id = cs.id
WHERE e.status <> 'CANCELLED' AND gs.status = 'PUBLISHED';

-- VIEW: v_invoice_balances | debt is derived, not a stored per-student cache.
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

-- VIEW: v_section_registration_counts
CREATE OR REPLACE VIEW v_section_registration_counts AS
SELECT cs.id AS section_id, cs.section_code, cs.capacity,
       COUNT(CASE WHEN e.status = 'REGISTERED' THEN 1 END) AS registered_count,
       cs.capacity - COUNT(CASE WHEN e.status = 'REGISTERED' THEN 1 END) AS remaining_seats
FROM course_sections cs
LEFT JOIN enrollments e ON e.section_id = cs.id
GROUP BY cs.id,cs.section_code,cs.capacity;

-- VIEW: v_admission_document_checklist
CREATE OR REPLACE VIEW v_admission_document_checklist AS
SELECT a.id AS application_id, a.application_code,
       r.document_type, r.label, r.is_required,
       d.id AS latest_document_id, d.revision_no, d.status AS document_status,
       CASE WHEN r.is_required = 0 THEN 1
            WHEN d.id IS NOT NULL AND d.status = 'VERIFIED' THEN 1
            ELSE 0 END AS requirement_satisfied
FROM admission_applications a
JOIN admission_document_requirements r ON r.period_id = a.period_id
LEFT JOIN admission_documents d ON d.id = (
    SELECT d2.id FROM admission_documents d2
    WHERE d2.application_id = a.id AND d2.document_type = r.document_type
    ORDER BY d2.revision_no DESC, d2.id DESC LIMIT 1
);

-- VIEW: v_ctsv_fund_balances
CREATE OR REPLACE VIEW v_ctsv_fund_balances AS
SELECT f.id AS fund_id, f.code AS fund_code, f.name AS fund_name, f.channel,
  COALESCE((SELECT SUM(p.amount) FROM payments p WHERE p.fund_id=f.id),0.00) AS collected_amount,
  COALESCE((SELECT SUM(r.amount) FROM ctsv_remittances r
            WHERE r.fund_id=f.id AND r.status='CONFIRMED'),0.00) AS remitted_amount,
  COALESCE((SELECT SUM(p.amount) FROM payments p WHERE p.fund_id=f.id),0.00)
  - COALESCE((SELECT SUM(r.amount) FROM ctsv_remittances r
              WHERE r.fund_id=f.id AND r.status='CONFIRMED'),0.00) AS balance_amount
FROM ctsv_funds f;

-- VIEW: v_ctsv_semester_finance
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
      AND q.created_at < DATE_ADD(s.ends_on,INTERVAL 1 DAY)) AS student_issue_count,
  (SELECT COUNT(*) FROM student_requests q
    WHERE q.created_at >= s.starts_on AND q.created_at < DATE_ADD(s.ends_on,INTERVAL 1 DAY)
      AND q.status IN ('PENDING','PROCESSING')) AS unresolved_issue_count,
  (SELECT COUNT(DISTINCT q.id) FROM student_requests q
    JOIN student_request_review_events e ON e.request_id=q.id
    WHERE q.created_at >= s.starts_on AND q.created_at < DATE_ADD(s.ends_on,INTERVAL 1 DAY)
      AND e.action='ESCALATE_TO_SCHOOL') AS escalated_issue_count
FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id;

-- VIEW: v_admission_dossier_progress

CREATE OR REPLACE VIEW v_admission_dossier_progress AS
SELECT a.id AS application_id, a.application_code, a.status,
       COUNT(ch.document_type) AS documents_listed,
       SUM(CASE WHEN ch.is_required=1 THEN 1 ELSE 0 END) AS required_count,
       SUM(CASE WHEN ch.is_required=1 AND ch.requirement_satisfied=1 THEN 1 ELSE 0 END) AS verified_required_count,
       CASE WHEN SUM(CASE WHEN ch.is_required=1 AND ch.requirement_satisfied=0 THEN 1 ELSE 0 END)=0
            THEN 'DOCUMENTS_OK' ELSE 'DOCUMENTS_MISSING' END AS dossier_check
FROM admission_applications a
LEFT JOIN v_admission_document_checklist ch ON ch.application_id=a.id
GROUP BY a.id,a.application_code,a.status;

-- =============== KIEM TRA CU BAN 28 BANG / DU LIEU CO BAN =============
-- ============================================================================
-- SMS database integrity and idempotency verification (READ ONLY)
-- A healthy result has all violation_count values = 0.
-- Run this script after the seed, repeat the seed, then rerun this verification.
-- ============================================================================
USE sms_v6_original;

SELECT 'TABLE_COUNT' AS metric, COUNT(*) AS metric_value
FROM information_schema.TABLES
WHERE TABLE_SCHEMA='sms_v6_original' AND TABLE_TYPE='BASE TABLE';

SELECT 'VIEW_COUNT' AS metric, COUNT(*) AS metric_value
FROM information_schema.VIEWS
WHERE TABLE_SCHEMA='sms_v6_original' AND TABLE_NAME IN
 ('v_student_results','v_invoice_balances','v_section_registration_counts');

-- Counts: save these values; they must be unchanged after running the seed again.
SELECT 'roles' AS table_name, COUNT(*) AS row_count FROM roles
UNION ALL SELECT 'users_demo', COUNT(*) FROM users WHERE username IN ('principal_demo','training_demo','lecturer_demo_01','lecturer_demo_02','lecturer_demo_03','student_demo_001','student_demo_002','student_demo_003','student_demo_004','student_demo_005','student_demo_006')
UNION ALL SELECT 'user_roles', COUNT(*) FROM user_roles
UNION ALL SELECT 'faculties', COUNT(*) FROM faculties
UNION ALL SELECT 'majors', COUNT(*) FROM majors
UNION ALL SELECT 'cohorts', COUNT(*) FROM cohorts
UNION ALL SELECT 'academic_classes', COUNT(*) FROM academic_classes
UNION ALL SELECT 'students', COUNT(*) FROM students
UNION ALL SELECT 'lecturers', COUNT(*) FROM lecturers
UNION ALL SELECT 'academic_years', COUNT(*) FROM academic_years
UNION ALL SELECT 'semesters', COUNT(*) FROM semesters
UNION ALL SELECT 'courses', COUNT(*) FROM courses
UNION ALL SELECT 'curricula', COUNT(*) FROM curricula
UNION ALL SELECT 'curriculum_courses', COUNT(*) FROM curriculum_courses
UNION ALL SELECT 'course_sections', COUNT(*) FROM course_sections
UNION ALL SELECT 'section_schedules', COUNT(*) FROM section_schedules
UNION ALL SELECT 'enrollments', COUNT(*) FROM enrollments
UNION ALL SELECT 'grade_sheets', COUNT(*) FROM grade_sheets
UNION ALL SELECT 'grades', COUNT(*) FROM grades
UNION ALL SELECT 'grade_reviews', COUNT(*) FROM grade_reviews
UNION ALL SELECT 'tuition_rates', COUNT(*) FROM tuition_rates
UNION ALL SELECT 'invoices', COUNT(*) FROM invoices
UNION ALL SELECT 'invoice_items', COUNT(*) FROM invoice_items
UNION ALL SELECT 'payments', COUNT(*) FROM payments
UNION ALL SELECT 'student_requests', COUNT(*) FROM student_requests
UNION ALL SELECT 'notifications', COUNT(*) FROM notifications
UNION ALL SELECT 'notification_recipients', COUNT(*) FROM notification_recipients
UNION ALL SELECT 'audit_logs', COUNT(*) FROM audit_logs;

-- Business integrity checks, NOT a replacement for service-layer transactions.
SELECT 'DUPLICATE_STUDENT_CODES' AS check_name, COUNT(*) AS violation_count FROM (
  SELECT student_code FROM students GROUP BY student_code HAVING COUNT(*)>1
) t
UNION ALL SELECT 'DUPLICATE_ENROLLMENTS', COUNT(*) FROM (
  SELECT student_id, section_id FROM enrollments GROUP BY student_id,section_id HAVING COUNT(*)>1
) t
UNION ALL SELECT 'DUPLICATE_INVOICES', COUNT(*) FROM (
  SELECT student_id,semester_id FROM invoices GROUP BY student_id,semester_id HAVING COUNT(*)>1
) t
UNION ALL SELECT 'DUPLICATE_PAYMENT_REFERENCES', COUNT(*) FROM (
  SELECT reference_no FROM payments GROUP BY reference_no HAVING COUNT(*)>1
) t
UNION ALL SELECT 'INVOICE_ENROLLMENT_MISMATCH', COUNT(*)
  FROM invoice_items ii
  JOIN invoices i ON i.id=ii.invoice_id
  JOIN enrollments e ON e.id=ii.enrollment_id
  JOIN course_sections cs ON cs.id=e.section_id
  WHERE i.student_id<>e.student_id OR i.semester_id<>cs.semester_id
UNION ALL SELECT 'CANCELLED_ENROLLMENT_BILLED', COUNT(*)
  FROM invoice_items ii JOIN enrollments e ON e.id=ii.enrollment_id
  WHERE e.status='CANCELLED'
UNION ALL SELECT 'OVERPAYMENT', COUNT(*)
  FROM v_invoice_balances WHERE paid_amount > payable_amount
UNION ALL SELECT 'DISCOUNT_EXCEEDS_BASE', COUNT(*)
  FROM v_invoice_balances WHERE discount_amount > base_amount
UNION ALL SELECT 'OVERCAPACITY', COUNT(*)
  FROM v_section_registration_counts WHERE registered_count > capacity
UNION ALL SELECT 'DUPLICATE_COURSE_SAME_SEMESTER', COUNT(*) FROM (
  SELECT e.student_id, cs.semester_id, cs.course_id
  FROM enrollments e JOIN course_sections cs ON cs.id=e.section_id
  WHERE e.status='REGISTERED'
  GROUP BY e.student_id,cs.semester_id,cs.course_id HAVING COUNT(*)>1
) t
UNION ALL SELECT 'PUBLISHED_WITH_MISSING_GRADES', COUNT(*)
  FROM grade_sheets gs
  JOIN course_sections cs ON cs.id=gs.section_id
  JOIN enrollments e ON e.section_id=cs.id AND e.status<>'CANCELLED'
  LEFT JOIN grades g ON g.enrollment_id=e.id
  WHERE gs.status='PUBLISHED' AND
     (g.id IS NULL OR g.attendance_score IS NULL OR g.midterm_score IS NULL OR g.final_score IS NULL)
UNION ALL SELECT 'WEIGHTS_NOT_100', COUNT(*)
  FROM course_sections
  WHERE attendance_weight+midterm_weight+final_weight <> 100.00;

-- Helpful views for manual inspection.
SELECT * FROM v_section_registration_counts ORDER BY section_code;
SELECT invoice_id,student_id,base_amount,discount_amount,payable_amount,
       paid_amount,remaining_amount,payment_status
FROM v_invoice_balances ORDER BY invoice_id;
SELECT student_code,section_code,grade_sheet_status,total_score
FROM v_student_results ORDER BY student_code,section_code;

-- =============== KIEM TRA NGHIEP VU CTSV / QUY / EMAIL ===============
-- SMS V4 non-mutating validation. Run seed twice; counts must stay the same.
USE sms_v6_original;
SELECT 'BASE_TABLE_COUNT' metric, COUNT(*) value FROM information_schema.TABLES
 WHERE TABLE_SCHEMA=DATABASE() AND TABLE_TYPE='BASE TABLE';
SELECT 'BASE_VIEWS' metric, COUNT(*) value FROM information_schema.VIEWS
 WHERE TABLE_SCHEMA=DATABASE();
SELECT 'CTSV' entity,COUNT(*) records FROM ctsv_funds
UNION ALL SELECT 'MAILBOX',COUNT(*) FROM student_school_mailboxes
UNION ALL SELECT 'ADMISSIONS',COUNT(*) FROM admission_applications
UNION ALL SELECT 'DOCUMENTS',COUNT(*) FROM admission_documents
UNION ALL SELECT 'REVIEWS',COUNT(*) FROM admission_review_events
UNION ALL SELECT 'CTSV_REMITTANCES',COUNT(*) FROM ctsv_remittances
UNION ALL SELECT 'CTSV_REPORTS',COUNT(*) FROM ctsv_semester_reports
UNION ALL SELECT 'OUTBOUND_EMAILS',COUNT(*) FROM outbound_emails
UNION ALL SELECT 'PAYMENTS',COUNT(*) FROM payments;

-- Each violation_count should be zero. Legacy payments/fund_id NULL are separately listed.
SELECT 'DUPLICATE_SCHOOL_EMAIL' check_name,COUNT(*) violation_count FROM (
 SELECT school_email FROM student_school_mailboxes GROUP BY school_email HAVING COUNT(*)>1) x
UNION ALL SELECT 'DUPLICATE_SCHOOL_MAILBOX_STUDENT',COUNT(*) FROM (
 SELECT student_id FROM student_school_mailboxes GROUP BY student_id HAVING COUNT(*)>1) x
UNION ALL SELECT 'DUPLICATE_ADMISSION_CODE',COUNT(*) FROM (
 SELECT application_code FROM admission_applications GROUP BY application_code HAVING COUNT(*)>1) x
UNION ALL SELECT 'DUPLICATE_PAYMENT_REFERENCE',COUNT(*) FROM (
 SELECT reference_no FROM payments GROUP BY reference_no HAVING COUNT(*)>1) x
UNION ALL SELECT 'DUPLICATE_REMITTANCE_CODE',COUNT(*) FROM (
 SELECT remittance_code FROM ctsv_remittances GROUP BY remittance_code HAVING COUNT(*)>1) x
UNION ALL SELECT 'DUPLICATE_EMAIL_EVENT',COUNT(*) FROM (
 SELECT event_key FROM outbound_emails GROUP BY event_key HAVING COUNT(*)>1) x
UNION ALL SELECT 'ENROLLED_BUT_MISSING_STUDENT',COUNT(*)
 FROM admission_applications a WHERE a.status='ENROLLED' AND a.student_id IS NULL
UNION ALL SELECT 'ENROLLED_WRONG_APPLICANT',COUNT(*)
 FROM admission_applications a JOIN students s ON s.id=a.student_id
 WHERE s.user_id<>a.applicant_user_id
UNION ALL SELECT 'CTSV_FUND_NEGATIVE',COUNT(*) FROM v_ctsv_fund_balances WHERE balance_amount < 0
UNION ALL SELECT 'MAILBOX_ACTIVE_NO_ACTIVATION_DATE',COUNT(*)
 FROM student_school_mailboxes WHERE provisioning_status='ACTIVE' AND activated_at IS NULL
UNION ALL SELECT 'PAYMENT_OVERPAID_INVOICE',COUNT(*)
 FROM v_invoice_balances WHERE paid_amount>payable_amount
UNION ALL SELECT 'REQUESTS_HANDLED_BY_MISSING_CTSV',COUNT(*) FROM (
 SELECT q.id FROM student_requests q
 JOIN users u ON u.id=q.handled_by
 LEFT JOIN user_roles ur ON ur.user_id=u.id
 LEFT JOIN roles r ON r.id=ur.role_id AND r.code='CTSV'
 WHERE q.handled_by IS NOT NULL AND q.request_code LIKE 'CTSV-V4-%'
 GROUP BY q.id HAVING SUM(CASE WHEN r.id IS NOT NULL THEN 1 ELSE 0 END)=0
) x;

-- Legacy data: do NOT automatically assign to CTSV fund without proof of collection.
SELECT 'UNASSIGNED_OLD_PAYMENTS' info,COUNT(*) payments_count
FROM payments WHERE fund_id IS NULL;

SELECT * FROM v_ctsv_fund_balances ORDER BY fund_code;
SELECT * FROM v_ctsv_semester_finance ORDER BY academic_year,semester_code;
SELECT a.application_code,a.status,u.email AS applicant_contact_email
FROM admission_applications a JOIN users u ON u.id=a.applicant_user_id
ORDER BY a.application_code;


-- =============== KIEM TRA HO SO THPT + GIAY TO DINH DANH =================
SELECT 'TOTAL_TABLES_V5' AS metric,COUNT(*) AS value
FROM information_schema.TABLES
WHERE TABLE_SCHEMA=DATABASE() AND TABLE_TYPE='BASE TABLE';
SELECT 'VIEWS_V5' AS metric,COUNT(*) AS value
FROM information_schema.VIEWS WHERE TABLE_SCHEMA=DATABASE();

SELECT 'DUPLICATE_PERSONAL_IDENTITY_APP' AS check_name,COUNT(*) AS violation_count
FROM (SELECT application_id FROM admission_identity_records
      GROUP BY application_id HAVING COUNT(*)>1) d
UNION ALL SELECT 'DUPLICATE_TRANSCRIPT_APP',COUNT(*) FROM
 (SELECT application_id FROM admission_high_school_records
  GROUP BY application_id HAVING COUNT(*)>1) d
UNION ALL SELECT 'DUPLICATE_SUBJECT_GRADE',COUNT(*) FROM
 (SELECT school_record_id,grade_level,subject_code FROM admission_high_school_scores
  GROUP BY school_record_id,grade_level,subject_code HAVING COUNT(*)>1) d
UNION ALL SELECT 'INVALID_SUBJECT_GRADE',COUNT(*) FROM admission_high_school_scores
 WHERE grade_level NOT IN (10,11,12) OR average_score NOT BETWEEN 0 AND 10
UNION ALL SELECT 'INCOMPLETE_SUBMITTED_APPLICATION',COUNT(*) FROM
 v_admission_dossier_progress
 WHERE status IN ('CTSV_APPROVED','SENT_TO_SCHOOL','SCHOOL_APPROVED','PDT_VERIFIED','ENROLLED')
   AND dossier_check='DOCUMENTS_MISSING';

-- HO SO CTSV: chi xem tiet do giay to, khong doc duong dan file public
SELECT a.application_code,a.status, p.documents_listed,p.required_count,
       p.verified_required_count,p.dossier_check
FROM admission_applications a JOIN v_admission_dossier_progress p
ON p.application_id=a.id
ORDER BY a.id DESC;

-- DANH SACH HO SO VA HOC BA, CCCD CHI HIEN 4 SO CUOI (KHONG DOC SO GOC)
SELECT a.application_code,a.status,
       i.identity_type, i.identity_last4,
       hs.school_name,hs.graduation_year,hs.graduation_status,hs.transcript_average
FROM admission_applications a
LEFT JOIN admission_identity_records i ON i.application_id=a.id
LEFT JOIN admission_high_school_records hs ON hs.application_id=a.id
ORDER BY a.application_code;

-- DIEM HOC BA THEO KHOI, THEO MON
SELECT a.application_code,g.grade_level,g.subject_code,g.average_score
FROM admission_high_school_scores g
JOIN admission_high_school_records hs ON hs.id=g.school_record_id
JOIN admission_applications a ON a.id=hs.application_id
ORDER BY a.application_code,g.grade_level,g.subject_code;

-- DANH SACH NHUNG GIAY TO CON THIEU/CHUA DUOC XAC MINH
SELECT a.application_code,c.document_type,c.label,c.document_status,c.revision_no
FROM v_admission_document_checklist c
JOIN admission_applications a ON a.id=c.application_id
WHERE c.is_required=1 AND c.requirement_satisfied=0
ORDER BY a.application_code,c.document_type;

-- CHI TIET CAC KHOA NGOAI TOAN CSDL DE KIEM TRA ERD
SELECT TABLE_NAME,COLUMN_NAME,REFERENCED_TABLE_NAME,REFERENCED_COLUMN_NAME,CONSTRAINT_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA=DATABASE() AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME,CONSTRAINT_NAME,ORDINAL_POSITION;


-- =============================================================================
-- V6 - TONG HOP TOAN TRUONG, LICH HOC, NHAP DIEM, DUYET HO SO BGH, BAO CAO
-- Tat ca la VIEW/SELECT. Khong luu lai tong cong no de tranh lech so lieu.
-- =============================================================================

-- Hang doi BGH la MOT tap con cua admission_applications, khong can bang rieng.
CREATE OR REPLACE VIEW v_school_admission_queue AS
SELECT a.id AS application_id,a.application_code,a.status,
       a.legal_full_name,a.personal_email,a.phone,
       a.major_id,a.period_id,a.assigned_ctsv_user_id,a.submitted_at,
       p.required_count,p.verified_required_count,p.dossier_check
FROM admission_applications a
LEFT JOIN v_admission_dossier_progress p ON p.application_id=a.id
WHERE a.status='SENT_TO_SCHOOL';

-- Mot su kien duyet/trai lai phai tham chieu ho so; viewer co the filter theo role.
CREATE OR REPLACE VIEW v_school_admission_decisions AS
SELECT a.id AS application_id,a.application_code,a.status AS current_status,
       e.id AS decision_event_id,e.event_type,e.from_status,e.to_status,
       e.actor_user_id,u.full_name AS reviewer_name,e.note,e.created_at,
       CASE WHEN EXISTS (SELECT 1 FROM user_roles ur JOIN roles r ON r.id=ur.role_id
                         WHERE ur.user_id=e.actor_user_id AND r.code='PRINCIPAL')
            THEN 1 ELSE 0 END AS reviewer_is_bgh
FROM admission_review_events e
JOIN admission_applications a ON a.id=e.application_id
JOIN users u ON u.id=e.actor_user_id
WHERE e.event_type IN ('SCHOOL_APPROVE','SCHOOL_REJECT');

-- Danh sach hoc phan da dang ky la NGUON DUY NHAT cho thoi khoa bieu va nhap diem.
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

CREATE OR REPLACE VIEW v_grade_entry_roster AS
SELECT e.id AS enrollment_id,e.student_id,s.student_code,u.full_name AS student_name,
       cs.id AS section_id,cs.section_code,cs.lecturer_id,cs.semester_id,
       gs.id AS grade_sheet_id,gs.status AS sheet_status,
       g.id AS grade_id,g.attendance_score,g.midterm_score,g.final_score,e.status AS enrollment_status
FROM enrollments e
JOIN students s ON s.id=e.student_id
JOIN users u ON u.id=s.user_id
JOIN course_sections cs ON cs.id=e.section_id
LEFT JOIN grade_sheets gs ON gs.section_id=cs.id
LEFT JOIN grades g ON g.enrollment_id=e.id
WHERE e.status IN ('REGISTERED','COMPLETED');

-- CONG NO CA TRUONG THEO HOC KY; bao gom tat ca sinh vien, khong chi mot ho so.
CREATE OR REPLACE VIEW v_school_tuition_by_semester AS
SELECT se.id AS semester_id,ay.name AS academic_year,se.code AS semester_code,
       COUNT(b.invoice_id) AS invoice_count,
       COUNT(DISTINCT b.student_id) AS students_billed,
       COALESCE(SUM(b.base_amount),0.00) AS base_amount,
       COALESCE(SUM(b.discount_amount),0.00) AS discounted_amount,
       COALESCE(SUM(b.debit_amount),0.00) AS approved_extra_fees,
       COALESCE(SUM(b.credit_amount),0.00) AS approved_credits,
       COALESCE(SUM(b.payable_amount),0.00) AS total_receivables,
       COALESCE(SUM(b.paid_amount),0.00) AS collected,
       COALESCE(SUM(b.remaining_amount),0.00) AS outstanding,
       COALESCE(SUM(CASE WHEN b.remaining_amount>0 THEN 1 ELSE 0 END),0) AS unpaid_invoice_count
FROM semesters se
JOIN academic_years ay ON ay.id=se.academic_year_id
LEFT JOIN v_invoice_balances b ON b.semester_id=se.id
GROUP BY se.id,ay.name,se.code;

-- Tong so CA TRUONG qua tat ca hoc ky; truong co mot ma so quy uoc SCHOOL.
CREATE OR REPLACE VIEW v_school_tuition_total AS
SELECT 'SCHOOL' AS scope_code,
       COALESCE(SUM(total_receivables),0.00) AS total_receivables,
       COALESCE(SUM(collected),0.00) AS collected,
       COALESCE(SUM(outstanding),0.00) AS outstanding,
       COALESCE(SUM(invoice_count),0) AS invoice_count,
       COALESCE(SUM(unpaid_invoice_count),0) AS unpaid_invoice_count
FROM v_school_tuition_by_semester;

-- Bao cao CTSV duoc BGH doc tu cung 1 report_id, khong nhan ban bang thong ke.
CREATE OR REPLACE VIEW v_school_ctsv_report_register AS
SELECT r.id AS report_id,r.report_code,r.semester_id,r.status,r.prepared_by,
       r.received_by,r.submitted_at,r.reviewed_at,
       f.total_tuition_due,f.total_paid,f.total_outstanding,
       f.collected_via_ctsv,f.legacy_unassigned_paid,f.remitted_to_school,
       f.student_issue_count,f.unresolved_issue_count,f.escalated_issue_count,
       (SELECT COUNT(*) FROM ctsv_semester_report_reviews ev WHERE ev.report_id=r.id) AS review_events
FROM ctsv_semester_reports r
JOIN v_ctsv_semester_finance f ON f.semester_id=r.semester_id;

CREATE OR REPLACE VIEW v_email_delivery_history AS
SELECT o.id AS email_id,o.event_key,o.template_code,o.recipient_email,
       o.delivery_status,o.queued_at,o.sent_at,
       COUNT(a.id) AS logged_attempts,
       MAX(a.attempted_at) AS last_attempt_at,
       MAX(CASE WHEN a.result='SENT' THEN a.attempted_at ELSE NULL END) AS last_success_at
FROM outbound_emails o
LEFT JOIN email_delivery_attempts a ON a.outbound_email_id=o.id
GROUP BY o.id,o.event_key,o.template_code,o.recipient_email,
         o.delivery_status,o.queued_at,o.sent_at;

-- Bao cao cong no truong - dong hoc phi qua quy CTSV - ban giao theo ky.
SELECT * FROM v_school_tuition_total;
SELECT * FROM v_school_tuition_by_semester ORDER BY academic_year,semester_code;
SELECT * FROM v_ctsv_semester_finance ORDER BY academic_year,semester_code;
SELECT * FROM v_school_ctsv_report_register ORDER BY semester_id;

-- Ho so CTSV chuyen BGH + lich su BGH duyet chung 1 application_id.
SELECT * FROM v_school_admission_queue ORDER BY application_code;
SELECT * FROM v_school_admission_decisions ORDER BY created_at DESC;

-- Du lieu sinh vien - dang ky - lich - diem dung chung enrollment_id.
SELECT enrollment_id,student_id,section_id,course_code,day_of_week,starts_at,room
  FROM v_student_timetable ORDER BY student_id,day_of_week,starts_at;
SELECT enrollment_id,student_code,section_code,sheet_status,attendance_score,midterm_score,final_score
  FROM v_grade_entry_roster ORDER BY section_code,student_code;

-- NGHIEM THU V6: cac vi pham phai la 0 (neu du lieu goc da sach)
SELECT 'SCHOOL_APPROVED_WITHOUT_BGH_EVENT' AS check_name,COUNT(*) AS violation_count
FROM admission_applications a
WHERE a.status IN ('SCHOOL_APPROVED','PDT_VERIFIED','ENROLLED')
  AND NOT EXISTS (SELECT 1 FROM admission_review_events e
    WHERE e.application_id=a.id AND e.event_type='SCHOOL_APPROVE')
UNION ALL
SELECT 'SCHOOL_EVENT_ACTOR_NOT_PRINCIPAL',COUNT(*) FROM v_school_admission_decisions
WHERE reviewer_is_bgh=0
UNION ALL
SELECT 'SCHOOL_APPROVED_WITHOUT_CTSV_FORWARD',COUNT(*)
FROM admission_applications a
WHERE a.status IN ('SCHOOL_APPROVED','PDT_VERIFIED','ENROLLED')
AND NOT EXISTS(SELECT 1 FROM admission_review_events e
  WHERE e.application_id=a.id AND e.event_type='SUBMIT_TO_SCHOOL')
UNION ALL
SELECT 'INVOICE_OVERPAID_AFTER_ADJUSTMENT',COUNT(*) FROM v_invoice_balances
WHERE paid_amount>payable_amount
UNION ALL
SELECT 'CTSV_REPORT_APPROVED_WITHOUT_EVENT',COUNT(*)
FROM ctsv_semester_reports r
WHERE r.status='APPROVED'
  AND NOT EXISTS (SELECT 1 FROM ctsv_semester_report_reviews rv
    WHERE rv.report_id=r.id AND rv.action='APPROVE')
UNION ALL
SELECT 'ACTIVE_MAILBOX_WITHOUT_DATE',COUNT(*)
FROM student_school_mailboxes
WHERE provisioning_status='ACTIVE' AND activated_at IS NULL;

SELECT 'TABLES' AS entity_type,COUNT(*) AS total FROM information_schema.TABLES
 WHERE TABLE_SCHEMA=DATABASE() AND TABLE_TYPE='BASE TABLE'
UNION ALL SELECT 'VIEWS',COUNT(*) FROM information_schema.VIEWS
 WHERE TABLE_SCHEMA=DATABASE();

-- Viec doi trang thai CTSV/BGH, tinh va ghi cong no, tinh so du quy, cap MSSV,
-- gui email va phan quyen la nghiep vu phai viet trong Backend transaction.
-- DB KHONG phai co che bao mat cho nguoi dung neu app su dung 1 user MySQL.


-- V6: KHOP DOI SOAT CHI TIET TIEN BAN GIAO - GHI THEO CHUNG TU THANH TOAN
CREATE OR REPLACE VIEW v_ctsv_remittance_tracking AS
SELECT r.id AS remittance_id,r.remittance_code,r.semester_id,r.fund_id,
       r.status,r.amount AS declared_amount,
       COALESCE(x.allocated_amount,0.00) AS allocated_amount,
       r.amount - COALESCE(x.allocated_amount,0.00) AS difference_amount,
       COALESCE(x.payment_count,0) AS payment_count
FROM ctsv_remittances r
LEFT JOIN (SELECT remittance_id,SUM(allocated_amount) AS allocated_amount,
                  COUNT(*) AS payment_count
           FROM ctsv_remittance_allocations GROUP BY remittance_id) x
ON x.remittance_id=r.id;

SELECT * FROM v_ctsv_remittance_tracking ORDER BY remittance_code;

SELECT 'CONFIRMED_REMITTANCE_ALLOCATION_MISMATCH' AS check_name,
       COUNT(*) AS violation_count FROM v_ctsv_remittance_tracking
WHERE status='CONFIRMED' AND difference_amount<>0
UNION ALL
SELECT 'PAYMENT_ALLOCATED_MORE_THAN_COLLECTED',COUNT(*) FROM (
 SELECT p.id FROM payments p
 JOIN ctsv_remittance_allocations a ON a.payment_id=p.id
 GROUP BY p.id,p.amount HAVING SUM(a.allocated_amount)>p.amount
) bad
UNION ALL
SELECT 'REMITTANCE_ALLOCATION_WRONG_FUND_OR_SEMESTER',COUNT(*)
FROM ctsv_remittance_allocations a
JOIN ctsv_remittances r ON r.id=a.remittance_id
JOIN payments p ON p.id=a.payment_id
JOIN invoices i ON i.id=p.invoice_id
WHERE p.fund_id<>r.fund_id OR i.semester_id<>r.semester_id OR p.fund_id IS NULL;
