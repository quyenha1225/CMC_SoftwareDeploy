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
-- Can sao luu neu sms_db da co du lieu; schema cu KHAC V2/V3/V4 can migration rieng.
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

CREATE DATABASE IF NOT EXISTS sms_db
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE sms_db;

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
-- NO DROP / TRUNCATE / DELETE: back up sms_db before running.
-- CREATE TABLE IF NOT EXISTS does NOT upgrade existing table definitions;
-- targeted column/ENUM changes below cover V3 -> V4.
-- =============================================================================
USE sms_db;
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
USE sms_db;

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
