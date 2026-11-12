-- Additive migration: preserve all original V6 tables and seed rows.
CREATE TABLE IF NOT EXISTS student_profile_photos (
 student_id BIGINT PRIMARY KEY,
 storage_key VARCHAR(100) NOT NULL,
 mime_type VARCHAR(40) NOT NULL,
 updated_by BIGINT NOT NULL,
 updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY (student_id) REFERENCES students(id),
 FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS password_reset_tokens (
 id BIGINT PRIMARY KEY AUTO_INCREMENT,
 user_id BIGINT NOT NULL,
 token_hash CHAR(64) NOT NULL UNIQUE,
 expires_at DATETIME NOT NULL,
 used_at DATETIME NULL,
 delivery_status VARCHAR(12) NOT NULL DEFAULT 'PENDING',
 created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY (user_id) REFERENCES users(id),
 INDEX ix_password_reset_user (user_id, expires_at)
) ENGINE=InnoDB;
