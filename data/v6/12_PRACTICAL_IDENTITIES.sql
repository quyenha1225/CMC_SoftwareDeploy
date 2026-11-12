-- Practical fictional dataset, requested by the project owner. Not official school records.

-- Stable numeric PK/FK, usernames, passwords, enabled flags, fee rates and financial documents are preserved.

SET NAMES utf8mb4;

START TRANSACTION;

CREATE TEMPORARY TABLE practical_students (

 username VARCHAR(80) PRIMARY KEY,student_code VARCHAR(40),full_name VARCHAR(160),gender VARCHAR(20),

 hometown VARCHAR(160),address VARCHAR(400),current_address VARCHAR(400),guardian VARCHAR(160),email VARCHAR(190),school_email VARCHAR(190)

) ENGINE=InnoDB;

INSERT INTO practical_students VALUES

 ('student_demo_001','SV260001','Lê Minh Mai','FEMALE','Hà Nội','12 Nguyễn Trãi, Thanh Xuân, Hà Nội','Ký túc xá khu A, Hà Nội','Lê Văn Thành','le.minh.mai@example.test','leminhmai.sv26@students.edu.test'),

 ('student_demo_002','SV260002','Nguyễn Hoàng Nam','MALE','Bắc Ninh','25 Lý Thái Tổ, Bắc Ninh','Ký túc xá khu A, Hà Nội','Nguyễn Văn Hùng','nguyen.hoang.nam@example.test','nguyenhoangnam.sv26@students.edu.test'),

 ('student_demo_003','SV260003','Trần Thu Hà','FEMALE','Nam Định','18 Trần Hưng Đạo, Nam Định','Ký túc xá khu B, Hà Nội','Trần Văn Phúc','tran.thu.ha@example.test','tranthuha.sv26@students.edu.test'),

 ('student_demo_004','SV260004','Phạm Quốc Bảo','MALE','Hải Phòng','32 Lạch Tray, Hải Phòng','Ký túc xá khu A, Hà Nội','Phạm Văn Quang','pham.quoc.bao@example.test','phamquocbao.sv26@students.edu.test'),

 ('student_demo_005','SV250005','Đỗ Khánh Linh','FEMALE','Hà Nam','16 Lê Lợi, Hà Nam','Ký túc xá khu B, Hà Nội','Đỗ Thị Lan','do.khanh.linh@example.test','dokhanhlinh.sv25@students.edu.test'),

 ('student_demo_006','SV260006','Vũ Đức Minh','MALE','Hưng Yên','28 Nguyễn Văn Linh, Hưng Yên','Ký túc xá khu A, Hà Nội','Vũ Văn Hải','vu.duc.minh@example.test','vuducminh.sv26@students.edu.test');

UPDATE users u JOIN practical_students p ON p.username=u.username SET u.full_name=p.full_name,u.email=p.email;

UPDATE students s JOIN users u ON u.id=s.user_id JOIN practical_students p ON p.username=u.username
SET s.student_code=p.student_code,s.gender=p.gender,s.nationality='Việt Nam',
    s.place_of_birth=p.hometown,s.hometown=p.hometown,s.address=p.address,s.permanent_address=p.address,
    s.current_address=p.current_address,s.guardian_full_name=p.guardian,
    s.phone=CONCAT('090100',LPAD(s.id,4,'0')),s.guardian_phone=CONCAT('090200',LPAD(s.id,4,'0'));
UPDATE student_school_mailboxes m JOIN students s ON s.id=m.student_id JOIN users u ON u.id=s.user_id JOIN practical_students p ON p.username=u.username
SET m.school_email=p.school_email,m.note='Địa chỉ dùng trong bộ dữ liệu thực hành; chưa cấp hộp thư tại nhà cung cấp.'
WHERE m.provisioning_status='RESERVED';

UPDATE users SET full_name='Nguyễn Thanh Hà',email='nguyen.thanh.ha@example.test' WHERE username='principal_demo';

UPDATE users SET full_name='Phạm Thị Hương',email='pham.thi.huong@example.test' WHERE username='training_demo';

UPDATE users SET full_name='Trần Quốc Huy',email='tran.quoc.huy@example.test' WHERE username='lecturer_demo_01';

UPDATE users SET full_name='Nguyễn Thị Lan',email='nguyen.thi.lan@example.test' WHERE username='lecturer_demo_02';

UPDATE users SET full_name='Lê Anh Tuấn',email='le.anh.tuan@example.test' WHERE username='lecturer_demo_03';

UPDATE users SET full_name='Đặng Thu Trang',email='dang.thu.trang@example.test' WHERE username='ctsv_demo';

UPDATE users SET full_name='Nguyễn Gia Huy',email='nguyen.gia.huy@example.test' WHERE username='applicant_demo_03';

UPDATE users SET full_name='Bùi Ngọc Anh',email='bui.ngoc.anh@example.test' WHERE username='applicant_demo_04';

UPDATE users SET full_name='Nguyễn Thanh Hà' WHERE username='principal' AND full_name='Quản trị nhà trường';

UPDATE lecturers l JOIN users u ON u.id=l.user_id SET l.lecturer_code='GV001' WHERE u.username='lecturer_demo_01';

UPDATE lecturers l JOIN users u ON u.id=l.user_id SET l.lecturer_code='GV002' WHERE u.username='lecturer_demo_02';

UPDATE lecturers l JOIN users u ON u.id=l.user_id SET l.lecturer_code='GV003' WHERE u.username='lecturer_demo_03';

UPDATE faculties SET name=REPLACE(name,' (demo)','') WHERE name LIKE '% (demo)';

UPDATE majors SET name=REPLACE(name,' (demo)','') WHERE name LIKE '% (demo)';

UPDATE curricula SET title=REPLACE(title,' (demo)','') WHERE title LIKE '% (demo)';

UPDATE ctsv_funds SET name='Quỹ tiền mặt CTSV' WHERE code='CTSV-CASH-DEMO';

UPDATE ctsv_funds SET name='Quỹ chuyển khoản CTSV' WHERE code='CTSV-BANK-DEMO';

UPDATE admission_periods SET title='Đợt tuyển sinh năm 2026' WHERE code='NH-DEMO-V4-2026';

UPDATE admission_applications a JOIN users u ON u.id=a.applicant_user_id
SET a.legal_full_name=u.full_name,a.personal_email=u.email,a.nationality='Việt Nam',
 a.place_of_birth='Hà Nội',a.hometown='Hà Nội',a.address='Hà Đông, Hà Nội',a.permanent_address='Hà Đông, Hà Nội',a.current_address='Hà Đông, Hà Nội',
 a.gender=CASE WHEN u.username='applicant_demo_03' THEN 'MALE' ELSE 'FEMALE' END,
 a.guardian_full_name=CASE WHEN u.username='applicant_demo_03' THEN 'Nguyễn Văn Sơn' ELSE 'Bùi Thị Hạnh' END,
 a.guardian_phone=CONCAT('090400',LPAD(a.id,4,'0')),
 a.phone=CONCAT('090300',LPAD(a.id,4,'0'))
WHERE u.username IN ('applicant_demo_03','applicant_demo_04');
UPDATE admission_high_school_records r JOIN admission_applications a ON a.id=r.application_id JOIN users u ON u.id=a.applicant_user_id
SET r.school_name='THPT An Hòa',r.school_province='Hà Nội' WHERE u.username IN ('applicant_demo_03','applicant_demo_04');
UPDATE notifications SET body='Xem thời gian mở đăng ký tại mục Học phần. Học kỳ đã phát hành hóa đơn cần gửi yêu cầu điều chỉnh khi thay đổi đăng ký.' WHERE notification_code='DEMO-NOTI-HK2';
UPDATE notifications SET body='Kết quả học phần SE101 đã được công bố. Sinh viên xem chi tiết tại mục Kết quả học tập.' WHERE notification_code='DEMO-NOTI-GRADE';
INSERT INTO grades(enrollment_id,attendance_score,midterm_score,final_score,remark)
SELECT e.id,8,7,8,'Theo dõi kết quả học phần trong bộ dữ liệu thực hành.'
FROM enrollments e JOIN students s ON s.id=e.student_id JOIN users u ON u.id=s.user_id JOIN practical_students p ON p.username=u.username
WHERE e.status<>'CANCELLED' AND NOT EXISTS(SELECT 1 FROM grades g WHERE g.enrollment_id=e.id);
INSERT INTO exam_schedules(section_id,starts_at,ends_at,room,room_id,exam_type,exam_type_id,status,data_origin,note)
SELECT x.id,TIMESTAMP(DATE_SUB(x.ends_on,INTERVAL (7+x.seq) DAY),'08:00:00'),TIMESTAMP(DATE_SUB(x.ends_on,INTERVAL (7+x.seq) DAY),'10:00:00'),
 r.code,r.id,t.name,t.id,'PUBLISHED','DEMO','Lịch thi thuộc bộ dữ liệu thực hành của dự án.'
FROM (
 SELECT cs.id,s.ends_on,ROW_NUMBER() OVER(ORDER BY cs.id) seq,(SELECT MIN(ss.room_id) FROM section_schedules ss WHERE ss.section_id=cs.id) room_id
 FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id
 WHERE EXISTS(SELECT 1 FROM enrollments e JOIN students st ON st.id=e.student_id JOIN users u ON u.id=st.user_id JOIN practical_students p ON p.username=u.username WHERE e.section_id=cs.id)
 AND NOT EXISTS(SELECT 1 FROM enrollments e JOIN students st ON st.id=e.student_id JOIN users u ON u.id=st.user_id WHERE e.section_id=cs.id AND u.username NOT IN ('student_demo_001','student_demo_002','student_demo_003','student_demo_004','student_demo_005','student_demo_006'))
) x JOIN rooms r ON r.id=x.room_id JOIN exam_types t ON t.code='FINAL'
WHERE NOT EXISTS(SELECT 1 FROM exam_schedules ex WHERE ex.section_id=x.id);
UPDATE exam_schedules SET note='Lịch thi thuộc bộ dữ liệu thực hành của dự án.' WHERE data_origin='DEMO';
UPDATE outbound_emails e JOIN admission_applications a ON a.id=e.admission_application_id JOIN users u ON u.id=a.applicant_user_id
SET e.recipient_email=u.email WHERE u.username IN ('applicant_demo_03','applicant_demo_04') AND e.delivery_status='QUEUED';
DROP TEMPORARY TABLE practical_students;
COMMIT;

-- Recheck practical profiles by stable user identity after replacing display codes.

SET NAMES utf8mb4;
CREATE OR REPLACE VIEW v_normalization_checks AS
SELECT 'SCHEDULE_ROOM_REFERENCE' check_name,COUNT(*) violation_count FROM section_schedules ss
LEFT JOIN rooms r ON r.id=ss.room_id WHERE r.id IS NULL OR ss.room<>r.code
UNION ALL SELECT 'EXAM_CATALOG_REFERENCE',COUNT(*) FROM exam_schedules ex
LEFT JOIN rooms r ON r.id=ex.room_id LEFT JOIN exam_types t ON t.id=ex.exam_type_id
WHERE r.id IS NULL OR t.id IS NULL OR ex.room<>r.code OR ex.exam_type<>t.name
UNION ALL SELECT 'EXAM_TIME_STATUS',COUNT(*) FROM exam_schedules
WHERE ends_at<=starts_at OR DATE(starts_at)<>DATE(ends_at) OR status NOT IN ('DRAFT','PUBLISHED','CANCELLED') OR data_origin NOT IN ('SCHOOL','DEMO')
UNION ALL SELECT 'PRACTICE_STUDENT_PROFILE_MISSING',COUNT(*) FROM students s JOIN users u ON u.id=s.user_id
WHERE u.username IN ('student_demo_001','student_demo_002','student_demo_003','student_demo_004','student_demo_005','student_demo_006')
AND (s.gender IS NULL OR s.nationality IS NULL OR s.phone IS NULL OR s.address IS NULL OR s.guardian_full_name IS NULL OR s.guardian_phone IS NULL)
UNION ALL SELECT 'SECTION_MISSING_GRADE_SHEET',COUNT(*) FROM course_sections cs LEFT JOIN grade_sheets gs ON gs.section_id=cs.id WHERE gs.id IS NULL
UNION ALL SELECT 'ENROLLMENT_DUPLICATE_COURSE',COUNT(*) FROM (
    SELECT e.student_id,cs.semester_id,cs.course_id FROM enrollments e JOIN course_sections cs ON cs.id=e.section_id
    WHERE e.status<>'CANCELLED' GROUP BY e.student_id,cs.semester_id,cs.course_id HAVING COUNT(*)>1
) bad
UNION ALL SELECT 'EXAM_COLLISION',COUNT(*) FROM exam_schedules a JOIN exam_schedules b
ON a.id<b.id AND a.status<>'CANCELLED' AND b.status<>'CANCELLED' AND a.starts_at<b.ends_at AND b.starts_at<a.ends_at
JOIN course_sections ca ON ca.id=a.section_id JOIN course_sections cb ON cb.id=b.section_id
WHERE a.room_id=b.room_id OR a.section_id=b.section_id OR ca.lecturer_id=cb.lecturer_id OR EXISTS(
    SELECT 1 FROM enrollments ea JOIN enrollments eb ON eb.student_id=ea.student_id
    WHERE ea.section_id=a.section_id AND eb.section_id=b.section_id AND ea.status<>'CANCELLED' AND eb.status<>'CANCELLED')
UNION ALL SELECT 'INVOICE_OVERPAID',COUNT(*) FROM v_invoice_balances WHERE paid_amount>payable_amount
UNION ALL SELECT 'REMITTANCE_ALLOCATION_MISMATCH',COUNT(*) FROM v_ctsv_remittance_tracking WHERE status='CONFIRMED' AND difference_amount<>0
UNION ALL SELECT 'ACTIVE_MAILBOX_WITHOUT_DATE',COUNT(*) FROM student_school_mailboxes WHERE provisioning_status='ACTIVE' AND activated_at IS NULL;

SELECT check_name,violation_count FROM v_normalization_checks ORDER BY check_name;

