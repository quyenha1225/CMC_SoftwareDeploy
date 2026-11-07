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
