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

CREATE OR REPLACE VIEW v_invoice_balances AS
SELECT i.id AS invoice_id, i.student_id, i.semester_id, i.issued_at,
       COALESCE(it.base_amount,0.00) AS base_amount,
       i.discount_amount,
       GREATEST(COALESCE(it.base_amount,0.00) - i.discount_amount,0.00) AS payable_amount,
       COALESCE(p.paid_amount,0.00) AS paid_amount,
       GREATEST(COALESCE(it.base_amount,0.00) - i.discount_amount - COALESCE(p.paid_amount,0.00),0.00) AS remaining_amount,
       CASE WHEN COALESCE(it.base_amount,0.00) - i.discount_amount <= COALESCE(p.paid_amount,0.00)
              AND COALESCE(it.base_amount,0.00) > 0 THEN 'PAID'
            WHEN COALESCE(p.paid_amount,0.00) > 0 THEN 'PARTIAL'
            ELSE 'UNPAID' END AS payment_status
FROM invoices i
LEFT JOIN (SELECT invoice_id, SUM(amount) AS base_amount FROM invoice_items GROUP BY invoice_id) it
  ON it.invoice_id = i.id
LEFT JOIN (SELECT invoice_id, SUM(amount) AS paid_amount FROM payments GROUP BY invoice_id) p
  ON p.invoice_id = i.id;

CREATE OR REPLACE VIEW v_section_registration_counts AS
SELECT cs.id AS section_id, cs.section_code, cs.capacity,
       COUNT(CASE WHEN e.status = 'REGISTERED' THEN 1 END) AS registered_count,
       cs.capacity - COUNT(CASE WHEN e.status = 'REGISTERED' THEN 1 END) AS remaining_seats
FROM course_sections cs
LEFT JOIN enrollments e ON e.section_id = cs.id
GROUP BY cs.id,cs.section_code,cs.capacity;

-- CRITICAL APPLICATION-SERVICE TRANSACTION RULES (not all expressible via FK/CHECK):
-- 1. Check permissions (RBAC), enrollment period, capacity and schedule collisions.
-- 2. Do not register a student twice for the same course+semester via different sections.
-- 3. A grade belongs only to an enrollment in the lecturer's assigned section.
-- 4. Enforce grade-sheet state transitions: DRAFT->SUBMITTED->VERIFIED->APPROVED->PUBLISHED,
--    RETURNED -> DRAFT; grades must not be edited after SUBMITTED without returning.
-- 5. Check invoice line's enrollment.student_id and semester match parent invoice.
-- 6. Check discount <= invoice sum and prevent overpayments unless refunds/credit modeled.
-- 7. For POST operations use transactions and concurrency controls in Spring Boot.
