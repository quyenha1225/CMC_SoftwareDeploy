-- Updated practical names by request. Fictional dataset; run application migrations 05-12 for complete profiles/schedules.
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
SELECT 'principal_demo', 'nguyen.thanh.ha@example.test', '$2a$12$PPLg2JpIqF/i8uD3f./c/OGMiyvCe41EPTMEO.dv1YiHl4vDmyCrq', 'Nguyễn Thanh Hà', FALSE
WHERE NOT EXISTS (SELECT 1 FROM users x WHERE x.username='principal_demo');

INSERT INTO user_roles (user_id, role_id)
SELECT (SELECT id FROM users WHERE username='principal_demo'), (SELECT id FROM roles WHERE code='PRINCIPAL')
WHERE NOT EXISTS (SELECT 1 FROM user_roles x WHERE x.user_id=(SELECT id FROM users WHERE username='principal_demo') AND x.role_id=(SELECT id FROM roles WHERE code='PRINCIPAL'));

INSERT INTO users (username, email, password_hash, full_name, enabled)
SELECT 'training_demo', 'pham.thi.huong@example.test', '$2a$12$H4Q9k5WMeYU8CH41jA5Wiu8zcLrZdX8sQDNOEhtburyaXDmGk4odS', 'Phạm Thị Hương', FALSE
WHERE NOT EXISTS (SELECT 1 FROM users x WHERE x.username='training_demo');

INSERT INTO user_roles (user_id, role_id)
SELECT (SELECT id FROM users WHERE username='training_demo'), (SELECT id FROM roles WHERE code='TRAINING_OFFICE')
WHERE NOT EXISTS (SELECT 1 FROM user_roles x WHERE x.user_id=(SELECT id FROM users WHERE username='training_demo') AND x.role_id=(SELECT id FROM roles WHERE code='TRAINING_OFFICE'));

INSERT INTO users (username, email, password_hash, full_name, enabled)
SELECT 'lecturer_demo_01', 'tran.quoc.huy@example.test', '$2a$12$hKhjq7XPqPuYouPULY.1MukAtJ7A4YfqcwlBxVRuO44pKXzBv6fFi', 'Trần Quốc Huy', FALSE
WHERE NOT EXISTS (SELECT 1 FROM users x WHERE x.username='lecturer_demo_01');

INSERT INTO user_roles (user_id, role_id)
SELECT (SELECT id FROM users WHERE username='lecturer_demo_01'), (SELECT id FROM roles WHERE code='LECTURER')
WHERE NOT EXISTS (SELECT 1 FROM user_roles x WHERE x.user_id=(SELECT id FROM users WHERE username='lecturer_demo_01') AND x.role_id=(SELECT id FROM roles WHERE code='LECTURER'));

INSERT INTO users (username, email, password_hash, full_name, enabled)
SELECT 'lecturer_demo_02', 'nguyen.thi.lan@example.test', '$2a$12$jjif502I6evD0LSRnqS3b.RM0YzuxEipNz/6rAsl3JWkZpw.Sm.4q', 'Nguyễn Thị Lan', FALSE
WHERE NOT EXISTS (SELECT 1 FROM users x WHERE x.username='lecturer_demo_02');

INSERT INTO user_roles (user_id, role_id)
SELECT (SELECT id FROM users WHERE username='lecturer_demo_02'), (SELECT id FROM roles WHERE code='LECTURER')
WHERE NOT EXISTS (SELECT 1 FROM user_roles x WHERE x.user_id=(SELECT id FROM users WHERE username='lecturer_demo_02') AND x.role_id=(SELECT id FROM roles WHERE code='LECTURER'));

INSERT INTO users (username, email, password_hash, full_name, enabled)
SELECT 'lecturer_demo_03', 'le.anh.tuan@example.test', '$2a$12$Z0DqJ.PQ0WCmzZyCXjJwAeWkSl2C.HsAs2K06NZsecWPhTx1Kzff.', 'Lê Anh Tuấn', FALSE
WHERE NOT EXISTS (SELECT 1 FROM users x WHERE x.username='lecturer_demo_03');

INSERT INTO user_roles (user_id, role_id)
SELECT (SELECT id FROM users WHERE username='lecturer_demo_03'), (SELECT id FROM roles WHERE code='LECTURER')
WHERE NOT EXISTS (SELECT 1 FROM user_roles x WHERE x.user_id=(SELECT id FROM users WHERE username='lecturer_demo_03') AND x.role_id=(SELECT id FROM roles WHERE code='LECTURER'));

INSERT INTO users (username, email, password_hash, full_name, enabled)
SELECT 'student_demo_001', 'le.minh.mai@example.test', '$2a$12$WB/jAHTw2ENa0vnNC.xVmOT2flWz2/Iv5N3Zn5KnVTUop/cimjQ.K', 'Lê Minh Mai', FALSE
WHERE NOT EXISTS (SELECT 1 FROM users x WHERE x.username='student_demo_001');

INSERT INTO user_roles (user_id, role_id)
SELECT (SELECT id FROM users WHERE username='student_demo_001'), (SELECT id FROM roles WHERE code='STUDENT')
WHERE NOT EXISTS (SELECT 1 FROM user_roles x WHERE x.user_id=(SELECT id FROM users WHERE username='student_demo_001') AND x.role_id=(SELECT id FROM roles WHERE code='STUDENT'));

INSERT INTO users (username, email, password_hash, full_name, enabled)
SELECT 'student_demo_002', 'nguyen.hoang.nam@example.test', '$2a$12$Tg9Jo96w2K7kdz9LzVDHf.AnimqanhFurXSr/U0DWq8VZ5Xaitya.', 'Nguyễn Hoàng Nam', FALSE
WHERE NOT EXISTS (SELECT 1 FROM users x WHERE x.username='student_demo_002');

INSERT INTO user_roles (user_id, role_id)
SELECT (SELECT id FROM users WHERE username='student_demo_002'), (SELECT id FROM roles WHERE code='STUDENT')
WHERE NOT EXISTS (SELECT 1 FROM user_roles x WHERE x.user_id=(SELECT id FROM users WHERE username='student_demo_002') AND x.role_id=(SELECT id FROM roles WHERE code='STUDENT'));

INSERT INTO users (username, email, password_hash, full_name, enabled)
SELECT 'student_demo_003', 'tran.thu.ha@example.test', '$2a$12$ENdpuKHgvJkgeU1aGXBPx.mkKsjlvPfOuuWSQOpwxU2je5KZgkjse', 'Trần Thu Hà', FALSE
WHERE NOT EXISTS (SELECT 1 FROM users x WHERE x.username='student_demo_003');

INSERT INTO user_roles (user_id, role_id)
SELECT (SELECT id FROM users WHERE username='student_demo_003'), (SELECT id FROM roles WHERE code='STUDENT')
WHERE NOT EXISTS (SELECT 1 FROM user_roles x WHERE x.user_id=(SELECT id FROM users WHERE username='student_demo_003') AND x.role_id=(SELECT id FROM roles WHERE code='STUDENT'));

INSERT INTO users (username, email, password_hash, full_name, enabled)
SELECT 'student_demo_004', 'pham.quoc.bao@example.test', '$2a$12$OZQwkC2ynwhTnlxGuI0Fbu/lP3RyfwmC0iKomBwEIUCAijZOR7eri', 'Phạm Quốc Bảo', FALSE
WHERE NOT EXISTS (SELECT 1 FROM users x WHERE x.username='student_demo_004');

INSERT INTO user_roles (user_id, role_id)
SELECT (SELECT id FROM users WHERE username='student_demo_004'), (SELECT id FROM roles WHERE code='STUDENT')
WHERE NOT EXISTS (SELECT 1 FROM user_roles x WHERE x.user_id=(SELECT id FROM users WHERE username='student_demo_004') AND x.role_id=(SELECT id FROM roles WHERE code='STUDENT'));

INSERT INTO users (username, email, password_hash, full_name, enabled)
SELECT 'student_demo_005', 'do.khanh.linh@example.test', '$2a$12$3Cm74ibG.6AmcbKr1la6SueEBvbq4H2ZDGwBgsKVWM7k55mhYp.6O', 'Đỗ Khánh Linh', FALSE
WHERE NOT EXISTS (SELECT 1 FROM users x WHERE x.username='student_demo_005');

INSERT INTO user_roles (user_id, role_id)
SELECT (SELECT id FROM users WHERE username='student_demo_005'), (SELECT id FROM roles WHERE code='STUDENT')
WHERE NOT EXISTS (SELECT 1 FROM user_roles x WHERE x.user_id=(SELECT id FROM users WHERE username='student_demo_005') AND x.role_id=(SELECT id FROM roles WHERE code='STUDENT'));

INSERT INTO users (username, email, password_hash, full_name, enabled)
SELECT 'student_demo_006', 'vu.duc.minh@example.test', '$2a$12$if.fXzUgpA.sXbMOXXt.EO.nMpzutTfTuwegBbcMw67VXTQkb04QO', 'Vũ Đức Minh', FALSE
WHERE NOT EXISTS (SELECT 1 FROM users x WHERE x.username='student_demo_006');

INSERT INTO user_roles (user_id, role_id)
SELECT (SELECT id FROM users WHERE username='student_demo_006'), (SELECT id FROM roles WHERE code='STUDENT')
WHERE NOT EXISTS (SELECT 1 FROM user_roles x WHERE x.user_id=(SELECT id FROM users WHERE username='student_demo_006') AND x.role_id=(SELECT id FROM roles WHERE code='STUDENT'));

INSERT INTO faculties (code, name)
SELECT 'CNTT', 'Khoa Công nghệ thông tin'
WHERE NOT EXISTS (SELECT 1 FROM faculties x WHERE x.code='CNTT');

INSERT INTO faculties (code, name)
SELECT 'KT', 'Khoa Kinh tế'
WHERE NOT EXISTS (SELECT 1 FROM faculties x WHERE x.code='KT');

INSERT INTO majors (faculty_id, code, name)
SELECT (SELECT id FROM faculties WHERE code='CNTT'), 'KTPM', 'Kỹ thuật phần mềm'
WHERE NOT EXISTS (SELECT 1 FROM majors x WHERE x.code='KTPM');

INSERT INTO majors (faculty_id, code, name)
SELECT (SELECT id FROM faculties WHERE code='CNTT'), 'HTTT', 'Hệ thống thông tin'
WHERE NOT EXISTS (SELECT 1 FROM majors x WHERE x.code='HTTT');

INSERT INTO majors (faculty_id, code, name)
SELECT (SELECT id FROM faculties WHERE code='KT'), 'QTKD', 'Quản trị kinh doanh'
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
SELECT (SELECT id FROM users WHERE username='student_demo_001'), 'SV260001', (SELECT id FROM academic_classes WHERE code='KTPM26-A'), '2008-01-20', 'STUDYING', '2026-09-05'
WHERE NOT EXISTS (SELECT 1 FROM students x WHERE x.student_code='SV260001');

INSERT INTO students (user_id, student_code, class_id, date_of_birth, status, enrolled_on)
SELECT (SELECT id FROM users WHERE username='student_demo_002'), 'SV260002', (SELECT id FROM academic_classes WHERE code='KTPM26-A'), '2008-03-12', 'STUDYING', '2026-09-05'
WHERE NOT EXISTS (SELECT 1 FROM students x WHERE x.student_code='SV260002');

INSERT INTO students (user_id, student_code, class_id, date_of_birth, status, enrolled_on)
SELECT (SELECT id FROM users WHERE username='student_demo_003'), 'SV260003', (SELECT id FROM academic_classes WHERE code='KTPM26-A'), '2008-04-11', 'STUDYING', '2026-09-05'
WHERE NOT EXISTS (SELECT 1 FROM students x WHERE x.student_code='SV260003');

INSERT INTO students (user_id, student_code, class_id, date_of_birth, status, enrolled_on)
SELECT (SELECT id FROM users WHERE username='student_demo_004'), 'SV260004', (SELECT id FROM academic_classes WHERE code='KTPM26-A'), '2008-07-25', 'STUDYING', '2026-09-05'
WHERE NOT EXISTS (SELECT 1 FROM students x WHERE x.student_code='SV260004');

INSERT INTO students (user_id, student_code, class_id, date_of_birth, status, enrolled_on)
SELECT (SELECT id FROM users WHERE username='student_demo_005'), 'SV250005', (SELECT id FROM academic_classes WHERE code='HTTT25-A'), '2007-09-01', 'STUDYING', '2025-09-05'
WHERE NOT EXISTS (SELECT 1 FROM students x WHERE x.student_code='SV250005');

INSERT INTO students (user_id, student_code, class_id, date_of_birth, status, enrolled_on)
SELECT (SELECT id FROM users WHERE username='student_demo_006'), 'SV260006', (SELECT id FROM academic_classes WHERE code='QTKD26-A'), '2008-11-06', 'STUDYING', '2026-09-05'
WHERE NOT EXISTS (SELECT 1 FROM students x WHERE x.student_code='SV260006');

INSERT INTO lecturers (user_id, faculty_id, lecturer_code)
SELECT (SELECT id FROM users WHERE username='lecturer_demo_01'), (SELECT id FROM faculties WHERE code='CNTT'), 'GV001'
WHERE NOT EXISTS (SELECT 1 FROM lecturers x WHERE x.lecturer_code='GV001');

INSERT INTO lecturers (user_id, faculty_id, lecturer_code)
SELECT (SELECT id FROM users WHERE username='lecturer_demo_02'), (SELECT id FROM faculties WHERE code='CNTT'), 'GV002'
WHERE NOT EXISTS (SELECT 1 FROM lecturers x WHERE x.lecturer_code='GV002');

INSERT INTO lecturers (user_id, faculty_id, lecturer_code)
SELECT (SELECT id FROM users WHERE username='lecturer_demo_03'), (SELECT id FROM faculties WHERE code='KT'), 'GV003'
WHERE NOT EXISTS (SELECT 1 FROM lecturers x WHERE x.lecturer_code='GV003');

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
SELECT (SELECT id FROM majors WHERE code='KTPM'), (SELECT id FROM cohorts WHERE code='K2026'), 'CTĐT Kỹ thuật phần mềm K2026'
WHERE NOT EXISTS (SELECT 1 FROM curricula x WHERE x.major_id=(SELECT id FROM majors WHERE code='KTPM') AND x.cohort_id=(SELECT id FROM cohorts WHERE code='K2026'));

INSERT INTO curricula (major_id, cohort_id, title)
SELECT (SELECT id FROM majors WHERE code='HTTT'), (SELECT id FROM cohorts WHERE code='K2025'), 'CTĐT Hệ thống thông tin K2025'
WHERE NOT EXISTS (SELECT 1 FROM curricula x WHERE x.major_id=(SELECT id FROM majors WHERE code='HTTT') AND x.cohort_id=(SELECT id FROM cohorts WHERE code='K2025'));

INSERT INTO curricula (major_id, cohort_id, title)
SELECT (SELECT id FROM majors WHERE code='QTKD'), (SELECT id FROM cohorts WHERE code='K2026'), 'CTĐT Quản trị kinh doanh K2026'
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
SELECT (SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'), (SELECT id FROM courses WHERE course_code='SE101'), (SELECT id FROM lecturers WHERE lecturer_code='GV001'), 'SE101-01', 40, 10.00, 30.00, 60.00, TRUE
WHERE NOT EXISTS (SELECT 1 FROM course_sections x WHERE x.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1') AND x.section_code='SE101-01');

INSERT INTO course_sections (semester_id, course_id, lecturer_id, section_code, capacity, attendance_weight, midterm_weight, final_weight, is_open)
SELECT (SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'), (SELECT id FROM courses WHERE course_code='DB102'), (SELECT id FROM lecturers WHERE lecturer_code='GV002'), 'DB102-01', 40, 10.00, 30.00, 60.00, TRUE
WHERE NOT EXISTS (SELECT 1 FROM course_sections x WHERE x.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1') AND x.section_code='DB102-01');

INSERT INTO course_sections (semester_id, course_id, lecturer_id, section_code, capacity, attendance_weight, midterm_weight, final_weight, is_open)
SELECT (SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'), (SELECT id FROM courses WHERE course_code='NW103'), (SELECT id FROM lecturers WHERE lecturer_code='GV001'), 'NW103-01', 40, 10.00, 30.00, 60.00, TRUE
WHERE NOT EXISTS (SELECT 1 FROM course_sections x WHERE x.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1') AND x.section_code='NW103-01');

INSERT INTO course_sections (semester_id, course_id, lecturer_id, section_code, capacity, attendance_weight, midterm_weight, final_weight, is_open)
SELECT (SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'), (SELECT id FROM courses WHERE course_code='BA101'), (SELECT id FROM lecturers WHERE lecturer_code='GV003'), 'BA101-01', 35, 10.00, 30.00, 60.00, TRUE
WHERE NOT EXISTS (SELECT 1 FROM course_sections x WHERE x.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1') AND x.section_code='BA101-01');

INSERT INTO course_sections (semester_id, course_id, lecturer_id, section_code, capacity, attendance_weight, midterm_weight, final_weight, is_open)
SELECT (SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2'), (SELECT id FROM courses WHERE course_code='WD104'), (SELECT id FROM lecturers WHERE lecturer_code='GV002'), 'WD104-01', 30, 10.00, 30.00, 60.00, TRUE
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
SELECT (SELECT id FROM students WHERE student_code='SV260001'), (SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01'), 'REGISTERED', '2026-08-30 09:00:00'
WHERE NOT EXISTS (SELECT 1 FROM enrollments x WHERE x.student_id=(SELECT id FROM students WHERE student_code='SV260001') AND x.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01'));

INSERT INTO enrollments (student_id, section_id, status, registered_at)
SELECT (SELECT id FROM students WHERE student_code='SV260001'), (SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01'), 'REGISTERED', '2026-08-30 09:00:00'
WHERE NOT EXISTS (SELECT 1 FROM enrollments x WHERE x.student_id=(SELECT id FROM students WHERE student_code='SV260001') AND x.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01'));

INSERT INTO enrollments (student_id, section_id, status, registered_at)
SELECT (SELECT id FROM students WHERE student_code='SV260001'), (SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='NW103-01'), 'REGISTERED', '2026-08-30 09:00:00'
WHERE NOT EXISTS (SELECT 1 FROM enrollments x WHERE x.student_id=(SELECT id FROM students WHERE student_code='SV260001') AND x.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='NW103-01'));

INSERT INTO enrollments (student_id, section_id, status, registered_at)
SELECT (SELECT id FROM students WHERE student_code='SV260002'), (SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01'), 'REGISTERED', '2026-08-30 09:00:00'
WHERE NOT EXISTS (SELECT 1 FROM enrollments x WHERE x.student_id=(SELECT id FROM students WHERE student_code='SV260002') AND x.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01'));

INSERT INTO enrollments (student_id, section_id, status, registered_at)
SELECT (SELECT id FROM students WHERE student_code='SV260002'), (SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01'), 'REGISTERED', '2026-08-30 09:00:00'
WHERE NOT EXISTS (SELECT 1 FROM enrollments x WHERE x.student_id=(SELECT id FROM students WHERE student_code='SV260002') AND x.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01'));

INSERT INTO enrollments (student_id, section_id, status, registered_at)
SELECT (SELECT id FROM students WHERE student_code='SV260003'), (SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01'), 'REGISTERED', '2026-08-30 09:00:00'
WHERE NOT EXISTS (SELECT 1 FROM enrollments x WHERE x.student_id=(SELECT id FROM students WHERE student_code='SV260003') AND x.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01'));

INSERT INTO enrollments (student_id, section_id, status, registered_at)
SELECT (SELECT id FROM students WHERE student_code='SV260003'), (SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='NW103-01'), 'REGISTERED', '2026-08-30 09:00:00'
WHERE NOT EXISTS (SELECT 1 FROM enrollments x WHERE x.student_id=(SELECT id FROM students WHERE student_code='SV260003') AND x.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='NW103-01'));

INSERT INTO enrollments (student_id, section_id, status, registered_at)
SELECT (SELECT id FROM students WHERE student_code='SV260004'), (SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01'), 'REGISTERED', '2026-08-30 09:00:00'
WHERE NOT EXISTS (SELECT 1 FROM enrollments x WHERE x.student_id=(SELECT id FROM students WHERE student_code='SV260004') AND x.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01'));

INSERT INTO enrollments (student_id, section_id, status, registered_at)
SELECT (SELECT id FROM students WHERE student_code='SV250005'), (SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01'), 'REGISTERED', '2026-08-30 09:00:00'
WHERE NOT EXISTS (SELECT 1 FROM enrollments x WHERE x.student_id=(SELECT id FROM students WHERE student_code='SV250005') AND x.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01'));

INSERT INTO enrollments (student_id, section_id, status, registered_at)
SELECT (SELECT id FROM students WHERE student_code='SV250005'), (SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='NW103-01'), 'REGISTERED', '2026-08-30 09:00:00'
WHERE NOT EXISTS (SELECT 1 FROM enrollments x WHERE x.student_id=(SELECT id FROM students WHERE student_code='SV250005') AND x.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='NW103-01'));

INSERT INTO enrollments (student_id, section_id, status, registered_at)
SELECT (SELECT id FROM students WHERE student_code='SV260006'), (SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='BA101-01'), 'REGISTERED', '2026-08-30 09:00:00'
WHERE NOT EXISTS (SELECT 1 FROM enrollments x WHERE x.student_id=(SELECT id FROM students WHERE student_code='SV260006') AND x.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='BA101-01'));

INSERT INTO enrollments (student_id, section_id, status, registered_at)
SELECT (SELECT id FROM students WHERE student_code='SV260001'), (SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2' AND cs.section_code='WD104-01'), 'REGISTERED', '2026-11-03 09:00:00'
WHERE NOT EXISTS (SELECT 1 FROM enrollments x WHERE x.student_id=(SELECT id FROM students WHERE student_code='SV260001') AND x.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2' AND cs.section_code='WD104-01'));

INSERT INTO enrollments (student_id, section_id, status, registered_at)
SELECT (SELECT id FROM students WHERE student_code='SV260002'), (SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2' AND cs.section_code='WD104-01'), 'REGISTERED', '2026-11-03 09:00:00'
WHERE NOT EXISTS (SELECT 1 FROM enrollments x WHERE x.student_id=(SELECT id FROM students WHERE student_code='SV260002') AND x.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2' AND cs.section_code='WD104-01'));

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
SELECT (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260001') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')), 8.5, 8, 9, 'Kết quả tốt'
WHERE NOT EXISTS (SELECT 1 FROM grades x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260001') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')));

INSERT INTO grades (enrollment_id, attendance_score, midterm_score, final_score, remark)
SELECT (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260002') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')), 7, 7.5, 8, 'Đạt yêu cầu'
WHERE NOT EXISTS (SELECT 1 FROM grades x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260002') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')));

INSERT INTO grades (enrollment_id, attendance_score, midterm_score, final_score, remark)
SELECT (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260003') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')), 9, 8, 9, 'Kết quả tốt'
WHERE NOT EXISTS (SELECT 1 FROM grades x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260003') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')));

INSERT INTO grades (enrollment_id, attendance_score, midterm_score, final_score, remark)
SELECT (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260004') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')), 6, 6.5, 7, 'Cần luyện tập thêm'
WHERE NOT EXISTS (SELECT 1 FROM grades x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260004') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')));

INSERT INTO grades (enrollment_id, attendance_score, midterm_score, final_score, remark)
SELECT (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260001') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01')), 8, 7.5, NULL, 'Đang chờ thi cuối kỳ'
WHERE NOT EXISTS (SELECT 1 FROM grades x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260001') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01')));

INSERT INTO grades (enrollment_id, attendance_score, midterm_score, final_score, remark)
SELECT (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260002') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01')), 7, 7, NULL, 'Đang nhập điểm'
WHERE NOT EXISTS (SELECT 1 FROM grades x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260002') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01')));

INSERT INTO grades (enrollment_id, attendance_score, midterm_score, final_score, remark)
SELECT (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260006') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='BA101-01')), 8, 8, 8.5, 'Chờ duyệt cuối'
WHERE NOT EXISTS (SELECT 1 FROM grades x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260006') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='BA101-01')));

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
SELECT (SELECT id FROM students WHERE student_code='SV260001'), (SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'), 0, '2026-09-20 08:00:00'
WHERE NOT EXISTS (SELECT 1 FROM invoices x WHERE x.student_id=(SELECT id FROM students WHERE student_code='SV260001') AND x.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'));

INSERT INTO invoices (student_id, semester_id, discount_amount, issued_at)
SELECT (SELECT id FROM students WHERE student_code='SV260002'), (SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'), 500000, '2026-09-20 08:00:00'
WHERE NOT EXISTS (SELECT 1 FROM invoices x WHERE x.student_id=(SELECT id FROM students WHERE student_code='SV260002') AND x.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'));

INSERT INTO invoices (student_id, semester_id, discount_amount, issued_at)
SELECT (SELECT id FROM students WHERE student_code='SV260003'), (SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'), 0, '2026-09-20 08:00:00'
WHERE NOT EXISTS (SELECT 1 FROM invoices x WHERE x.student_id=(SELECT id FROM students WHERE student_code='SV260003') AND x.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'));

INSERT INTO invoices (student_id, semester_id, discount_amount, issued_at)
SELECT (SELECT id FROM students WHERE student_code='SV260004'), (SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'), 0, '2026-09-20 08:00:00'
WHERE NOT EXISTS (SELECT 1 FROM invoices x WHERE x.student_id=(SELECT id FROM students WHERE student_code='SV260004') AND x.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'));

INSERT INTO invoices (student_id, semester_id, discount_amount, issued_at)
SELECT (SELECT id FROM students WHERE student_code='SV250005'), (SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'), 0, '2026-09-20 08:00:00'
WHERE NOT EXISTS (SELECT 1 FROM invoices x WHERE x.student_id=(SELECT id FROM students WHERE student_code='SV250005') AND x.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'));

INSERT INTO invoices (student_id, semester_id, discount_amount, issued_at)
SELECT (SELECT id FROM students WHERE student_code='SV260006'), (SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'), 0, '2026-09-20 08:00:00'
WHERE NOT EXISTS (SELECT 1 FROM invoices x WHERE x.student_id=(SELECT id FROM students WHERE student_code='SV260006') AND x.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'));

INSERT INTO invoices (student_id, semester_id, discount_amount, issued_at)
SELECT (SELECT id FROM students WHERE student_code='SV260001'), (SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2'), 0, '2026-11-04 08:00:00'
WHERE NOT EXISTS (SELECT 1 FROM invoices x WHERE x.student_id=(SELECT id FROM students WHERE student_code='SV260001') AND x.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2'));

INSERT INTO invoices (student_id, semester_id, discount_amount, issued_at)
SELECT (SELECT id FROM students WHERE student_code='SV260002'), (SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2'), 0, '2026-11-04 08:00:00'
WHERE NOT EXISTS (SELECT 1 FROM invoices x WHERE x.student_id=(SELECT id FROM students WHERE student_code='SV260002') AND x.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2'));

INSERT INTO invoice_items (invoice_id, enrollment_id, credits_at_issue, unit_price_at_issue)
SELECT (SELECT i.id FROM invoices i WHERE i.student_id=(SELECT id FROM students WHERE student_code='SV260001') AND i.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1')), (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260001') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')), (SELECT c.credits FROM enrollments e JOIN course_sections cs ON cs.id=e.section_id JOIN courses c ON c.id=cs.course_id WHERE e.id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260001') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01'))), (SELECT tr.price_per_credit FROM tuition_rates tr WHERE tr.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'))
WHERE NOT EXISTS (SELECT 1 FROM invoice_items x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260001') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')));

INSERT INTO invoice_items (invoice_id, enrollment_id, credits_at_issue, unit_price_at_issue)
SELECT (SELECT i.id FROM invoices i WHERE i.student_id=(SELECT id FROM students WHERE student_code='SV260001') AND i.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1')), (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260001') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01')), (SELECT c.credits FROM enrollments e JOIN course_sections cs ON cs.id=e.section_id JOIN courses c ON c.id=cs.course_id WHERE e.id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260001') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01'))), (SELECT tr.price_per_credit FROM tuition_rates tr WHERE tr.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'))
WHERE NOT EXISTS (SELECT 1 FROM invoice_items x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260001') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01')));

INSERT INTO invoice_items (invoice_id, enrollment_id, credits_at_issue, unit_price_at_issue)
SELECT (SELECT i.id FROM invoices i WHERE i.student_id=(SELECT id FROM students WHERE student_code='SV260001') AND i.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1')), (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260001') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='NW103-01')), (SELECT c.credits FROM enrollments e JOIN course_sections cs ON cs.id=e.section_id JOIN courses c ON c.id=cs.course_id WHERE e.id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260001') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='NW103-01'))), (SELECT tr.price_per_credit FROM tuition_rates tr WHERE tr.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'))
WHERE NOT EXISTS (SELECT 1 FROM invoice_items x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260001') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='NW103-01')));

INSERT INTO invoice_items (invoice_id, enrollment_id, credits_at_issue, unit_price_at_issue)
SELECT (SELECT i.id FROM invoices i WHERE i.student_id=(SELECT id FROM students WHERE student_code='SV260002') AND i.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1')), (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260002') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')), (SELECT c.credits FROM enrollments e JOIN course_sections cs ON cs.id=e.section_id JOIN courses c ON c.id=cs.course_id WHERE e.id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260002') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01'))), (SELECT tr.price_per_credit FROM tuition_rates tr WHERE tr.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'))
WHERE NOT EXISTS (SELECT 1 FROM invoice_items x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260002') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')));

INSERT INTO invoice_items (invoice_id, enrollment_id, credits_at_issue, unit_price_at_issue)
SELECT (SELECT i.id FROM invoices i WHERE i.student_id=(SELECT id FROM students WHERE student_code='SV260002') AND i.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1')), (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260002') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01')), (SELECT c.credits FROM enrollments e JOIN course_sections cs ON cs.id=e.section_id JOIN courses c ON c.id=cs.course_id WHERE e.id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260002') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01'))), (SELECT tr.price_per_credit FROM tuition_rates tr WHERE tr.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'))
WHERE NOT EXISTS (SELECT 1 FROM invoice_items x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260002') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01')));

INSERT INTO invoice_items (invoice_id, enrollment_id, credits_at_issue, unit_price_at_issue)
SELECT (SELECT i.id FROM invoices i WHERE i.student_id=(SELECT id FROM students WHERE student_code='SV260003') AND i.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1')), (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260003') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')), (SELECT c.credits FROM enrollments e JOIN course_sections cs ON cs.id=e.section_id JOIN courses c ON c.id=cs.course_id WHERE e.id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260003') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01'))), (SELECT tr.price_per_credit FROM tuition_rates tr WHERE tr.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'))
WHERE NOT EXISTS (SELECT 1 FROM invoice_items x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260003') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')));

INSERT INTO invoice_items (invoice_id, enrollment_id, credits_at_issue, unit_price_at_issue)
SELECT (SELECT i.id FROM invoices i WHERE i.student_id=(SELECT id FROM students WHERE student_code='SV260003') AND i.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1')), (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260003') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='NW103-01')), (SELECT c.credits FROM enrollments e JOIN course_sections cs ON cs.id=e.section_id JOIN courses c ON c.id=cs.course_id WHERE e.id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260003') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='NW103-01'))), (SELECT tr.price_per_credit FROM tuition_rates tr WHERE tr.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'))
WHERE NOT EXISTS (SELECT 1 FROM invoice_items x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260003') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='NW103-01')));

INSERT INTO invoice_items (invoice_id, enrollment_id, credits_at_issue, unit_price_at_issue)
SELECT (SELECT i.id FROM invoices i WHERE i.student_id=(SELECT id FROM students WHERE student_code='SV260004') AND i.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1')), (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260004') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')), (SELECT c.credits FROM enrollments e JOIN course_sections cs ON cs.id=e.section_id JOIN courses c ON c.id=cs.course_id WHERE e.id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260004') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01'))), (SELECT tr.price_per_credit FROM tuition_rates tr WHERE tr.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'))
WHERE NOT EXISTS (SELECT 1 FROM invoice_items x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260004') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='SE101-01')));

INSERT INTO invoice_items (invoice_id, enrollment_id, credits_at_issue, unit_price_at_issue)
SELECT (SELECT i.id FROM invoices i WHERE i.student_id=(SELECT id FROM students WHERE student_code='SV250005') AND i.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1')), (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV250005') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01')), (SELECT c.credits FROM enrollments e JOIN course_sections cs ON cs.id=e.section_id JOIN courses c ON c.id=cs.course_id WHERE e.id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV250005') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01'))), (SELECT tr.price_per_credit FROM tuition_rates tr WHERE tr.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'))
WHERE NOT EXISTS (SELECT 1 FROM invoice_items x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV250005') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='DB102-01')));

INSERT INTO invoice_items (invoice_id, enrollment_id, credits_at_issue, unit_price_at_issue)
SELECT (SELECT i.id FROM invoices i WHERE i.student_id=(SELECT id FROM students WHERE student_code='SV250005') AND i.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1')), (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV250005') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='NW103-01')), (SELECT c.credits FROM enrollments e JOIN course_sections cs ON cs.id=e.section_id JOIN courses c ON c.id=cs.course_id WHERE e.id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV250005') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='NW103-01'))), (SELECT tr.price_per_credit FROM tuition_rates tr WHERE tr.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'))
WHERE NOT EXISTS (SELECT 1 FROM invoice_items x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV250005') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='NW103-01')));

INSERT INTO invoice_items (invoice_id, enrollment_id, credits_at_issue, unit_price_at_issue)
SELECT (SELECT i.id FROM invoices i WHERE i.student_id=(SELECT id FROM students WHERE student_code='SV260006') AND i.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1')), (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260006') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='BA101-01')), (SELECT c.credits FROM enrollments e JOIN course_sections cs ON cs.id=e.section_id JOIN courses c ON c.id=cs.course_id WHERE e.id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260006') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='BA101-01'))), (SELECT tr.price_per_credit FROM tuition_rates tr WHERE tr.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1'))
WHERE NOT EXISTS (SELECT 1 FROM invoice_items x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260006') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1' AND cs.section_code='BA101-01')));

INSERT INTO invoice_items (invoice_id, enrollment_id, credits_at_issue, unit_price_at_issue)
SELECT (SELECT i.id FROM invoices i WHERE i.student_id=(SELECT id FROM students WHERE student_code='SV260001') AND i.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2')), (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260001') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2' AND cs.section_code='WD104-01')), (SELECT c.credits FROM enrollments e JOIN course_sections cs ON cs.id=e.section_id JOIN courses c ON c.id=cs.course_id WHERE e.id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260001') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2' AND cs.section_code='WD104-01'))), (SELECT tr.price_per_credit FROM tuition_rates tr WHERE tr.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2'))
WHERE NOT EXISTS (SELECT 1 FROM invoice_items x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260001') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2' AND cs.section_code='WD104-01')));

INSERT INTO invoice_items (invoice_id, enrollment_id, credits_at_issue, unit_price_at_issue)
SELECT (SELECT i.id FROM invoices i WHERE i.student_id=(SELECT id FROM students WHERE student_code='SV260002') AND i.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2')), (SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260002') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2' AND cs.section_code='WD104-01')), (SELECT c.credits FROM enrollments e JOIN course_sections cs ON cs.id=e.section_id JOIN courses c ON c.id=cs.course_id WHERE e.id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260002') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2' AND cs.section_code='WD104-01'))), (SELECT tr.price_per_credit FROM tuition_rates tr WHERE tr.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2'))
WHERE NOT EXISTS (SELECT 1 FROM invoice_items x WHERE x.enrollment_id=(SELECT e.id FROM enrollments e WHERE e.student_id=(SELECT id FROM students WHERE student_code='SV260002') AND e.section_id=(SELECT cs.id FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK2' AND cs.section_code='WD104-01')));

INSERT INTO payments (invoice_id, recorded_by, amount, paid_at, reference_no, note)
SELECT (SELECT i.id FROM invoices i WHERE i.student_id=(SELECT id FROM students WHERE student_code='SV260001') AND i.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1')), (SELECT id FROM users WHERE username='training_demo'), 6800000.00, '2026-09-25 10:00:00', 'DEMO-PAY-001', 'Giao dịch giả lập - không phải thu tiền thật'
WHERE NOT EXISTS (SELECT 1 FROM payments x WHERE x.reference_no='DEMO-PAY-001');

INSERT INTO payments (invoice_id, recorded_by, amount, paid_at, reference_no, note)
SELECT (SELECT i.id FROM invoices i WHERE i.student_id=(SELECT id FROM students WHERE student_code='SV260002') AND i.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1')), (SELECT id FROM users WHERE username='training_demo'), 1000000.00, '2026-10-01 10:00:00', 'DEMO-PAY-002', 'Giao dịch giả lập - không phải thu tiền thật'
WHERE NOT EXISTS (SELECT 1 FROM payments x WHERE x.reference_no='DEMO-PAY-002');

INSERT INTO payments (invoice_id, recorded_by, amount, paid_at, reference_no, note)
SELECT (SELECT i.id FROM invoices i WHERE i.student_id=(SELECT id FROM students WHERE student_code='SV260006') AND i.semester_id=(SELECT s.id FROM semesters s JOIN academic_years ay ON ay.id=s.academic_year_id WHERE ay.name='2026-2027' AND s.code='HK1')), (SELECT id FROM users WHERE username='training_demo'), 2550000.00, '2026-10-02 10:00:00', 'DEMO-PAY-003', 'Giao dịch giả lập - không phải thu tiền thật'
WHERE NOT EXISTS (SELECT 1 FROM payments x WHERE x.reference_no='DEMO-PAY-003');

INSERT INTO student_requests (request_code, student_id, request_type, content, status, handled_by, response, created_at, handled_at)
SELECT 'DEMO-REQ-001', (SELECT id FROM students WHERE student_code='SV260001'), 'PROFILE_UPDATE', 'Yêu cầu chỉnh sửa số điện thoại demo', 'RESOLVED', (SELECT id FROM users WHERE username='training_demo'), 'Đã đối chiếu thông tin demo', '2026-10-20 09:00:00', '2026-10-21 09:00:00'
WHERE NOT EXISTS (SELECT 1 FROM student_requests x WHERE x.request_code='DEMO-REQ-001');

INSERT INTO student_requests (request_code, student_id, request_type, content, status, handled_by, response, created_at, handled_at)
SELECT 'DEMO-REQ-002', (SELECT id FROM students WHERE student_code='SV260003'), 'GRADE_QUESTION', 'Yêu cầu giải thích điểm chuyên cần demo', 'PENDING', NULL, NULL, '2026-11-04 14:00:00', NULL
WHERE NOT EXISTS (SELECT 1 FROM student_requests x WHERE x.request_code='DEMO-REQ-002');

INSERT INTO notifications (notification_code, created_by, title, body, created_at)
SELECT 'DEMO-NOTI-HK2', (SELECT id FROM users WHERE username='training_demo'), 'Mở đăng ký HK2', 'Xem thời gian mở đăng ký tại mục Học phần. Học kỳ đã phát hành hóa đơn cần gửi yêu cầu điều chỉnh khi thay đổi đăng ký.', '2026-11-01 08:00:00'
WHERE NOT EXISTS (SELECT 1 FROM notifications x WHERE x.notification_code='DEMO-NOTI-HK2');

INSERT INTO notifications (notification_code, created_by, title, body, created_at)
SELECT 'DEMO-NOTI-GRADE', (SELECT id FROM users WHERE username='training_demo'), 'Công bố điểm SE101', 'Kết quả học phần SE101 đã được công bố. Sinh viên xem chi tiết tại mục Kết quả học tập.', '2026-10-28 15:00:00'
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
USE sms_db;
SET NAMES utf8mb4;
START TRANSACTION;

INSERT INTO roles(code,description) SELECT 'CTSV','Phòng Công tác sinh viên: hồ sơ, hỗ trợ, thu học phí'
WHERE NOT EXISTS(SELECT 1 FROM roles WHERE code='CTSV');
INSERT INTO roles(code,description) SELECT 'APPLICANT','Người nộp hồ sơ trực tuyến chưa có MSSV'
WHERE NOT EXISTS(SELECT 1 FROM roles WHERE code='APPLICANT');

INSERT INTO users(username,email,password_hash,full_name,enabled)
SELECT 'ctsv_demo','dang.thu.trang@example.test','!ACCOUNT_DISABLED','Đặng Thu Trang',FALSE
WHERE NOT EXISTS(SELECT 1 FROM users WHERE username='ctsv_demo');
INSERT INTO users(username,email,password_hash,full_name,enabled)
SELECT 'applicant_demo_03','nguyen.gia.huy@example.test','!ACCOUNT_DISABLED','Nguyễn Gia Huy',FALSE
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
 'Hà Nội','Hà Nội','Hà Đông, Hà Nội','Hà Đông, Hà Nội'
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
 place_of_birth=COALESCE(place_of_birth,'Hà Nội'),
 hometown=COALESCE(hometown,'Hà Nội'),
 permanent_address=COALESCE(permanent_address,'Thanh Xuân, Hà Nội'),
 current_address=COALESCE(current_address,'Ký túc xá khu A, Hà Nội')
WHERE student_code='SV260001';

INSERT INTO student_school_mailboxes(student_id,school_email,provisioning_status,note)
SELECT s.id,'leminhmai.sv26@students.edu.test','RESERVED',
 'Chỉ đặt trước địa chỉ demo. Chưa tạo mailbox thật hay gửi thư.'
FROM students s WHERE s.student_code='SV260001' AND NOT EXISTS(
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
WHERE s.student_code='SV260003' AND se.code='HK1' AND ay.name='2026-2027'
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
USE sms_db;
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
SELECT a.id,'THPT An Hòa','Hà Nội',2026,'GRADUATED',8.10
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
SELECT 'applicant_demo_04','bui.ngoc.anh@example.test','!ACCOUNT_DISABLED','Bùi Ngọc Anh',FALSE
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
 'Hà Nội','Hà Nội','Hà Đông, Hà Nội','Hà Đông, Hà Nội'
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
SELECT a.id,'THPT An Hòa','Hà Nội',2026,'GRADUATED',8.25
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
WHERE s.student_code='SV260003' AND se.code='HK1' AND ay.name='2026-2027'
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
