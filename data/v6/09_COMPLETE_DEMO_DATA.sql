-- DEMO ONLY. Fill missing values, never overwrite existing student/grade values.
-- Personal values below are fictional, not verified student identity information.
SET NAMES utf8mb4;
START TRANSACTION;

UPDATE students s JOIN users u ON u.id=s.user_id
SET s.gender=COALESCE(s.gender,'UNDISCLOSED'),
    s.nationality=COALESCE(NULLIF(s.nationality,''),'Việt Nam (dữ liệu mẫu)'),
    s.phone=COALESCE(NULLIF(s.phone,''),CONCAT('000000',LPAD(s.id,4,'0'))),
    s.address=COALESCE(NULLIF(s.address,''),CONCAT('Địa chỉ liên hệ mẫu ',s.student_code)),
    s.place_of_birth=COALESCE(NULLIF(s.place_of_birth,''),'Nơi sinh mẫu — chưa xác minh'),
    s.hometown=COALESCE(NULLIF(s.hometown,''),'Quê quán mẫu — chưa xác minh'),
    s.permanent_address=COALESCE(NULLIF(s.permanent_address,''),CONCAT('Thường trú mẫu ',s.student_code)),
    s.current_address=COALESCE(NULLIF(s.current_address,''),CONCAT('Nơi ở mẫu ',s.student_code)),
    s.guardian_full_name=COALESCE(NULLIF(s.guardian_full_name,''),CONCAT('Người giám hộ mẫu ',s.student_code)),
    s.guardian_phone=COALESCE(NULLIF(s.guardian_phone,''),CONCAT('000001',LPAD(s.id,4,'0')))
WHERE LEFT(s.student_code,4)='DEMO' AND u.username LIKE 'student\_demo\_%';

INSERT INTO grades(enrollment_id,attendance_score,midterm_score,final_score,remark)
SELECT e.id,8,7,8,'Điểm minh họa bổ sung; chỉ hiển thị cho sinh viên khi bảng điểm được công bố.'
FROM enrollments e JOIN students s ON s.id=e.student_id JOIN users u ON u.id=s.user_id
WHERE e.status<>'CANCELLED' AND LEFT(s.student_code,4)='DEMO' AND u.username LIKE 'student\_demo\_%'
AND NOT EXISTS(SELECT 1 FROM grades g WHERE g.enrollment_id=e.id);

-- One fictional exam per demo-only section, on distinct dates; never touch school exams.
INSERT INTO exam_schedules(section_id,starts_at,ends_at,room,room_id,exam_type,exam_type_id,status,data_origin,note)
SELECT x.id,TIMESTAMP(DATE_SUB(x.ends_on,INTERVAL (7+x.seq) DAY),'08:00:00'),
       TIMESTAMP(DATE_SUB(x.ends_on,INTERVAL (7+x.seq) DAY),'10:00:00'),
       r.code,r.id,t.name,t.id,'PUBLISHED','DEMO',
       'DỮ LIỆU MẪU: dùng thử giao diện; không phải lịch thi chính thức của nhà trường.'
FROM (
    SELECT cs.id,s.ends_on,ROW_NUMBER() OVER(ORDER BY cs.id) seq,
           (SELECT MIN(ss.room_id) FROM section_schedules ss WHERE ss.section_id=cs.id) room_id
    FROM course_sections cs JOIN semesters s ON s.id=cs.semester_id
    WHERE EXISTS(SELECT 1 FROM enrollments e WHERE e.section_id=cs.id)
    AND NOT EXISTS(SELECT 1 FROM enrollments e JOIN students st ON st.id=e.student_id JOIN users u ON u.id=st.user_id
                   WHERE e.section_id=cs.id AND (LEFT(st.student_code,4)<>'DEMO' OR u.username NOT LIKE 'student\_demo\_%'))
) x JOIN rooms r ON r.id=x.room_id JOIN exam_types t ON t.code='FINAL'
WHERE NOT EXISTS(SELECT 1 FROM exam_schedules ex WHERE ex.section_id=x.id);

COMMIT;
