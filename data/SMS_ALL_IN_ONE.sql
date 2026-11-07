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


-- ============================================================================
-- STUDENT MANAGEMENT SYSTEM (SMS) | 02 - IDEMPOTENT DEMO SEED
-- Run AFTER 01_schema_sms.sql; may run repeatedly without duplicate demo rows.
-- Fictional demo records only; all accounts DISABLED, with random unknown hashes.
-- No real personal data, no real payments, no usable default credentials.
-- Entries are INSERT-IF-NOT-EXISTS: rerun does not overwrite changed live data.
-- ============================================================================
USE sms_db;
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


-- ============================================================================
-- SMS database integrity and idempotency verification (READ ONLY)
-- A healthy result has all violation_count values = 0.
-- Run this script after the seed, repeat the seed, then rerun this verification.
-- ============================================================================
USE sms_db;

SELECT 'TABLE_COUNT' AS metric, COUNT(*) AS metric_value
FROM information_schema.TABLES
WHERE TABLE_SCHEMA='sms_db' AND TABLE_TYPE='BASE TABLE';

SELECT 'VIEW_COUNT' AS metric, COUNT(*) AS metric_value
FROM information_schema.VIEWS
WHERE TABLE_SCHEMA='sms_db' AND TABLE_NAME IN
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
