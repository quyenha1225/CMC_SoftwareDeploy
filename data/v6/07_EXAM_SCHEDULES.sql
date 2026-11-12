-- Additive migration: restore exam scheduling without changing the original V6 SQL/seed.
-- Select the target database before running this file. No fictional official exam dates.
CREATE TABLE IF NOT EXISTS exam_schedules (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    section_id BIGINT NOT NULL,
    starts_at DATETIME NOT NULL,
    ends_at DATETIME NOT NULL,
    room VARCHAR(80) NOT NULL,
    exam_type VARCHAR(80) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    note VARCHAR(1000) NULL,
    CONSTRAINT fk_exam_section FOREIGN KEY (section_id) REFERENCES course_sections(id),
    CONSTRAINT chk_exam_times CHECK (ends_at > starts_at),
    CONSTRAINT chk_exam_status CHECK (status IN ('DRAFT','PUBLISHED','CANCELLED')),
    INDEX idx_exam_section (section_id),
    INDEX idx_exam_time (starts_at, ends_at)
) ENGINE=InnoDB;
