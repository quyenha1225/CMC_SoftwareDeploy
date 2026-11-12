-- Incremental normalization. Original PKs/FKs and snapshot values stay unchanged.
-- Run using the MySQL client (DELIMITER supported), after 05/06/07.
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS rooms (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(80) NOT NULL,
    name VARCHAR(160) NOT NULL,
    capacity INT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE KEY uq_rooms_code (code),
    CONSTRAINT chk_rooms_capacity CHECK (capacity IS NULL OR capacity > 0),
    CONSTRAINT chk_rooms_code CHECK (CHAR_LENGTH(TRIM(code)) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS exam_types (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(40) NOT NULL,
    name VARCHAR(80) NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE KEY uq_exam_types_code (code),
    UNIQUE KEY uq_exam_types_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO rooms(code,name)
SELECT x.code,CONCAT('Phòng ',x.code) FROM (
    SELECT DISTINCT TRIM(room) code FROM section_schedules
    UNION SELECT DISTINCT TRIM(room) FROM exam_schedules
) x WHERE x.code<>'' AND NOT EXISTS(SELECT 1 FROM rooms r WHERE r.code=x.code);

INSERT INTO exam_types(code,name)
SELECT 'MIDTERM','Giữa kỳ' WHERE NOT EXISTS(SELECT 1 FROM exam_types WHERE code='MIDTERM');
INSERT INTO exam_types(code,name)
SELECT 'FINAL','Cuối kỳ' WHERE NOT EXISTS(SELECT 1 FROM exam_types WHERE code='FINAL');
INSERT INTO exam_types(code,name)
SELECT CONCAT('LEGACY_',MIN(ex.id)),ex.exam_type FROM exam_schedules ex
WHERE NOT EXISTS(SELECT 1 FROM exam_types t WHERE t.name=ex.exam_type) GROUP BY ex.exam_type;

DROP PROCEDURE IF EXISTS sms_v6_add_column;
DROP PROCEDURE IF EXISTS sms_v6_add_constraint;
DELIMITER $$
CREATE PROCEDURE sms_v6_add_column(IN tab VARCHAR(64), IN col VARCHAR(64), IN definition TEXT)
BEGIN
    IF NOT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name=tab AND column_name=col) THEN
        SET @ddl=CONCAT('ALTER TABLE `',tab,'` ADD COLUMN `',col,'` ',definition);
        PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;
    END IF;
END$$
CREATE PROCEDURE sms_v6_add_constraint(IN tab VARCHAR(64), IN constraint_name_value VARCHAR(64), IN definition TEXT)
BEGIN
    IF NOT EXISTS(SELECT 1 FROM information_schema.table_constraints WHERE constraint_schema=DATABASE() AND table_name=tab AND constraint_name=constraint_name_value) THEN
        SET @ddl=CONCAT('ALTER TABLE `',tab,'` ADD CONSTRAINT `',constraint_name_value,'` ',definition);
        PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;
    END IF;
END$$
DELIMITER ;

CALL sms_v6_add_column('section_schedules','room_id','BIGINT NULL');
CALL sms_v6_add_column('exam_schedules','status','VARCHAR(20) NOT NULL DEFAULT ''DRAFT''');
CALL sms_v6_add_column('exam_schedules','note','VARCHAR(1000) NULL');
CALL sms_v6_add_column('exam_schedules','room_id','BIGINT NULL');
CALL sms_v6_add_column('exam_schedules','exam_type_id','BIGINT NULL');
CALL sms_v6_add_column('exam_schedules','data_origin','VARCHAR(16) NOT NULL DEFAULT ''SCHOOL''');
CALL sms_v6_add_column('exam_schedules','created_at','DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP');
CALL sms_v6_add_column('exam_schedules','updated_at','DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP');

UPDATE section_schedules ss JOIN rooms r ON r.code=TRIM(ss.room)
SET ss.room_id=r.id,ss.room=r.code WHERE ss.room_id IS NULL;
UPDATE exam_schedules ex JOIN rooms r ON r.code=TRIM(ex.room) JOIN exam_types t ON t.name=ex.exam_type
SET ex.room_id=r.id,ex.room=r.code,ex.exam_type_id=t.id WHERE ex.room_id IS NULL OR ex.exam_type_id IS NULL;

CALL sms_v6_add_constraint('section_schedules','fk_schedule_room','FOREIGN KEY(room_id) REFERENCES rooms(id)');
CALL sms_v6_add_constraint('section_schedules','chk_schedule_room_id','CHECK(room_id IS NOT NULL)');
CALL sms_v6_add_constraint('exam_schedules','chk_exam_status','CHECK(status IN (''DRAFT'',''PUBLISHED'',''CANCELLED''))');
CALL sms_v6_add_constraint('exam_schedules','fk_exam_room','FOREIGN KEY(room_id) REFERENCES rooms(id)');
CALL sms_v6_add_constraint('exam_schedules','fk_exam_type','FOREIGN KEY(exam_type_id) REFERENCES exam_types(id)');
CALL sms_v6_add_constraint('exam_schedules','chk_exam_catalog_ids','CHECK(room_id IS NOT NULL AND exam_type_id IS NOT NULL)');
CALL sms_v6_add_constraint('exam_schedules','chk_exam_origin','CHECK(data_origin IN (''SCHOOL'',''DEMO''))');
CALL sms_v6_add_constraint('exam_schedules','chk_exam_same_day','CHECK(DATE(starts_at)=DATE(ends_at))');
CALL sms_v6_add_constraint('users','chk_user_name_not_blank','CHECK(CHAR_LENGTH(TRIM(full_name))>0 AND CHAR_LENGTH(TRIM(username))>0)');
CALL sms_v6_add_constraint('student_profile_photos','chk_photo_mime','CHECK(mime_type IN (''image/jpeg'',''image/png''))');
CALL sms_v6_add_constraint('password_reset_tokens','chk_reset_delivery','CHECK(delivery_status IN (''PENDING'',''SENT'',''FAILED''))');
CALL sms_v6_add_constraint('password_reset_tokens','chk_reset_expiry','CHECK(expires_at>created_at)');

DROP PROCEDURE sms_v6_add_column;
DROP PROCEDURE sms_v6_add_constraint;

-- ID is canonical. Legacy text remains an API/SQL compatibility projection.
-- Triggers keep old SQL clients consistent; no split source of truth for room/type.
DROP TRIGGER IF EXISTS sms_schedule_catalog_insert;
DROP TRIGGER IF EXISTS sms_schedule_catalog_update;
DROP TRIGGER IF EXISTS sms_exam_catalog_insert;
DROP TRIGGER IF EXISTS sms_exam_catalog_update;
DELIMITER $$
CREATE TRIGGER sms_schedule_catalog_insert BEFORE INSERT ON section_schedules FOR EACH ROW
BEGIN
    IF NEW.room_id IS NULL THEN SET NEW.room_id=(SELECT id FROM rooms WHERE code=TRIM(NEW.room)); END IF;
    SET NEW.room=(SELECT code FROM rooms WHERE id=NEW.room_id);
    IF NEW.room IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Room must exist in rooms catalog'; END IF;
END$$
CREATE TRIGGER sms_schedule_catalog_update BEFORE UPDATE ON section_schedules FOR EACH ROW
BEGIN
    IF NEW.room_id IS NULL OR (NEW.room<>OLD.room AND NEW.room_id=OLD.room_id) THEN
        SET NEW.room_id=(SELECT id FROM rooms WHERE code=TRIM(NEW.room));
    END IF;
    SET NEW.room=(SELECT code FROM rooms WHERE id=NEW.room_id);
    IF NEW.room IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Room must exist in rooms catalog'; END IF;
END$$
CREATE TRIGGER sms_exam_catalog_insert BEFORE INSERT ON exam_schedules FOR EACH ROW
BEGIN
    IF NEW.room_id IS NULL THEN SET NEW.room_id=(SELECT id FROM rooms WHERE code=TRIM(NEW.room)); END IF;
    IF NEW.exam_type_id IS NULL THEN SET NEW.exam_type_id=(SELECT id FROM exam_types WHERE name=NEW.exam_type); END IF;
    SET NEW.room=(SELECT code FROM rooms WHERE id=NEW.room_id);
    SET NEW.exam_type=(SELECT name FROM exam_types WHERE id=NEW.exam_type_id);
    IF NEW.room IS NULL OR NEW.exam_type IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Room and exam type must exist in catalogs'; END IF;
END$$
CREATE TRIGGER sms_exam_catalog_update BEFORE UPDATE ON exam_schedules FOR EACH ROW
BEGIN
    IF NEW.room_id IS NULL OR (NEW.room<>OLD.room AND NEW.room_id=OLD.room_id) THEN SET NEW.room_id=(SELECT id FROM rooms WHERE code=TRIM(NEW.room)); END IF;
    IF NEW.exam_type_id IS NULL OR (NEW.exam_type<>OLD.exam_type AND NEW.exam_type_id=OLD.exam_type_id) THEN SET NEW.exam_type_id=(SELECT id FROM exam_types WHERE name=NEW.exam_type); END IF;
    SET NEW.room=(SELECT code FROM rooms WHERE id=NEW.room_id);
    SET NEW.exam_type=(SELECT name FROM exam_types WHERE id=NEW.exam_type_id);
    IF NEW.room IS NULL OR NEW.exam_type IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Room and exam type must exist in catalogs'; END IF;
END$$
DELIMITER ;
