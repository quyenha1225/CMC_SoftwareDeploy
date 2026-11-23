CREATE TABLE jenkins_incidents (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    job_url VARCHAR(500) NOT NULL,
    build_number BIGINT NOT NULL,
    build_result VARCHAR(20) NOT NULL,
    console_log MEDIUMTEXT NOT NULL,
    analysis TEXT NULL,
    attempts INT NOT NULL DEFAULT 0,
    next_attempt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    delivered_at TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY jenkins_incidents_build (job_url, build_number),
    KEY jenkins_incidents_queue (delivered_at, next_attempt)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
