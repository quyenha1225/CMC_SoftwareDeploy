-- Optional additive extensions for FE features absent from the original 47 tables.
-- Run on the selected V6 database, after 01,02,03. No USE/DROP or seed credentials.
CREATE TABLE IF NOT EXISTS campus_posts (
 id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
 created_by BIGINT NOT NULL,
 title VARCHAR(180) NOT NULL,
 summary VARCHAR(400) NOT NULL,
 content TEXT NOT NULL,
 category ENUM('Sự kiện','Hội thảo','Thông báo') NOT NULL,
 starts_at DATETIME NOT NULL,
 ends_at DATETIME NOT NULL,
 venue VARCHAR(180) NOT NULL,
 organizer VARCHAR(180) NOT NULL,
 status ENUM('DRAFT','PUBLISHED') NOT NULL DEFAULT 'DRAFT',
 published_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT fk_post_user FOREIGN KEY(created_by) REFERENCES users(id),
 CONSTRAINT chk_post_times CHECK(ends_at>starts_at)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS event_follows (
 event_id BIGINT NOT NULL,
 user_id BIGINT NOT NULL,
 created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 PRIMARY KEY(event_id,user_id),
 CONSTRAINT fk_follow_event FOREIGN KEY(event_id) REFERENCES campus_posts(id),
 CONSTRAINT fk_follow_user FOREIGN KEY(user_id) REFERENCES users(id)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS exam_schedules (
 id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
 section_id BIGINT NOT NULL,
 starts_at DATETIME NOT NULL,
 ends_at DATETIME NOT NULL,
 room VARCHAR(80) NOT NULL,
 exam_type VARCHAR(80) NOT NULL,
 CONSTRAINT fk_exam_section FOREIGN KEY(section_id) REFERENCES course_sections(id),
 CONSTRAINT chk_exam_times CHECK(ends_at>starts_at)
) ENGINE=InnoDB;
