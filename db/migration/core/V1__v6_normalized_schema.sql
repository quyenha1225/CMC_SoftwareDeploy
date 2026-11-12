-- Frozen schema baseline V6 + extensions 05-14. Schema only; no student/payment records.

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `academic_classes` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `major_id` bigint NOT NULL,
  `cohort_id` bigint NOT NULL,
  `code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(180) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_academic_classes_code` (`code`),
  KEY `fk_academic_classes_major` (`major_id`),
  KEY `fk_academic_classes_cohort` (`cohort_id`),
  CONSTRAINT `fk_academic_classes_cohort` FOREIGN KEY (`cohort_id`) REFERENCES `cohorts` (`id`),
  CONSTRAINT `fk_academic_classes_major` FOREIGN KEY (`major_id`) REFERENCES `majors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `academic_years` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `starts_on` date NOT NULL,
  `ends_on` date NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_academic_years_name` (`name`),
  CONSTRAINT `chk_academic_year_dates` CHECK ((`ends_on` >= `starts_on`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `admission_applications` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `application_code` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `applicant_user_id` bigint NOT NULL,
  `period_id` bigint NOT NULL,
  `major_id` bigint NOT NULL,
  `phone` varchar(24) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address` varchar(400) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `date_of_birth` date DEFAULT NULL,
  `status` enum('DRAFT','SUBMITTED','IN_REVIEW','CHANGES_REQUESTED','CTSV_APPROVED','CTSV_REJECTED','SENT_TO_SCHOOL','SCHOOL_APPROVED','SCHOOL_REJECTED','PDT_VERIFIED','ENROLLED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT',
  `assigned_ctsv_user_id` bigint DEFAULT NULL,
  `student_id` bigint DEFAULT NULL,
  `submitted_at` datetime DEFAULT NULL,
  `changed_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `legal_full_name` varchar(160) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `personal_email` varchar(190) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `gender` enum('MALE','FEMALE','OTHER','UNDISCLOSED') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `place_of_birth` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `hometown` varchar(250) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `permanent_address` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `current_address` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `nationality` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `guardian_full_name` varchar(160) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `guardian_phone` varchar(24) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_admission_app_code` (`application_code`),
  UNIQUE KEY `uq_admission_app_person_period` (`applicant_user_id`,`period_id`),
  UNIQUE KEY `uq_admission_app_student` (`student_id`),
  KEY `ix_admission_app_status` (`period_id`,`status`),
  KEY `ix_admission_app_assigned` (`assigned_ctsv_user_id`,`status`),
  KEY `fk_admission_app_major` (`major_id`),
  CONSTRAINT `fk_admission_app_ctsv` FOREIGN KEY (`assigned_ctsv_user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_admission_app_major` FOREIGN KEY (`major_id`) REFERENCES `majors` (`id`),
  CONSTRAINT `fk_admission_app_period` FOREIGN KEY (`period_id`) REFERENCES `admission_periods` (`id`),
  CONSTRAINT `fk_admission_app_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`),
  CONSTRAINT `fk_admission_app_user` FOREIGN KEY (`applicant_user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `chk_admission_enrolled_link` CHECK (((`status` <> _utf8mb4'ENROLLED') or (`student_id` is not null)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `admission_document_requirements` (
  `period_id` bigint NOT NULL,
  `document_type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `label` varchar(160) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_required` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`period_id`,`document_type`),
  CONSTRAINT `fk_admission_requirement_period` FOREIGN KEY (`period_id`) REFERENCES `admission_periods` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `admission_documents` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `application_id` bigint NOT NULL,
  `document_type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `revision_no` smallint NOT NULL DEFAULT '1',
  `file_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `storage_key` varchar(400) COLLATE utf8mb4_unicode_ci NOT NULL,
  `mime_type` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `size_bytes` bigint NOT NULL,
  `sha256` char(64) CHARACTER SET ascii COLLATE ascii_bin DEFAULT NULL,
  `status` enum('PENDING','VERIFIED','REJECTED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING',
  `checked_by` bigint DEFAULT NULL,
  `checked_at` datetime DEFAULT NULL,
  `rejection_reason` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `uploaded_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_admission_doc_version` (`application_id`,`document_type`,`revision_no`),
  UNIQUE KEY `uq_admission_doc_storage_key` (`storage_key`),
  KEY `fk_admission_doc_checker` (`checked_by`),
  CONSTRAINT `fk_admission_doc_app` FOREIGN KEY (`application_id`) REFERENCES `admission_applications` (`id`),
  CONSTRAINT `fk_admission_doc_checker` FOREIGN KEY (`checked_by`) REFERENCES `users` (`id`),
  CONSTRAINT `chk_admission_doc_revision` CHECK ((`revision_no` > 0)),
  CONSTRAINT `chk_admission_doc_size` CHECK (((`size_bytes` > 0) and (`size_bytes` <= 10485760)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `admission_high_school_records` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `application_id` bigint NOT NULL,
  `school_name` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `school_province` varchar(160) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `graduation_year` smallint DEFAULT NULL,
  `graduation_status` enum('PENDING','GRADUATED','NOT_GRADUATED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING',
  `transcript_average` decimal(4,2) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_school_records_application` (`application_id`),
  CONSTRAINT `fk_school_records_application` FOREIGN KEY (`application_id`) REFERENCES `admission_applications` (`id`),
  CONSTRAINT `chk_school_records_average` CHECK (((`transcript_average` is null) or (`transcript_average` between 0 and 10))),
  CONSTRAINT `chk_school_records_year` CHECK (((`graduation_year` is null) or (`graduation_year` between 1980 and 2100)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `admission_high_school_scores` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `school_record_id` bigint NOT NULL,
  `grade_level` tinyint NOT NULL,
  `subject_code` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `average_score` decimal(4,2) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_school_score_grade_subject` (`school_record_id`,`grade_level`,`subject_code`),
  CONSTRAINT `fk_school_score_record` FOREIGN KEY (`school_record_id`) REFERENCES `admission_high_school_records` (`id`),
  CONSTRAINT `chk_high_school_grade` CHECK ((`grade_level` in (10,11,12))),
  CONSTRAINT `chk_high_school_score` CHECK ((`average_score` between 0 and 10))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `admission_identity_records` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `application_id` bigint NOT NULL,
  `identity_type` enum('CCCD','CMND','PASSPORT','OTHER') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'CCCD',
  `identity_last4` char(4) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `identity_number_encrypted` varbinary(512) DEFAULT NULL,
  `identity_number_hmac` char(64) CHARACTER SET ascii COLLATE ascii_bin DEFAULT NULL,
  `issued_on` date DEFAULT NULL,
  `expires_on` date DEFAULT NULL,
  `issued_by` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `verified_at` datetime DEFAULT NULL,
  `verified_by` bigint DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_admission_identity_application` (`application_id`),
  KEY `ix_admission_identity_hmac` (`identity_number_hmac`),
  KEY `fk_identity_verified_by` (`verified_by`),
  CONSTRAINT `fk_identity_application` FOREIGN KEY (`application_id`) REFERENCES `admission_applications` (`id`),
  CONSTRAINT `fk_identity_verified_by` FOREIGN KEY (`verified_by`) REFERENCES `users` (`id`),
  CONSTRAINT `chk_admission_identity_validity` CHECK (((`expires_on` is null) or (`issued_on` is null) or (`expires_on` >= `issued_on`)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `admission_periods` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `title` varchar(180) COLLATE utf8mb4_unicode_ci NOT NULL,
  `cohort_id` bigint NOT NULL,
  `opens_at` datetime NOT NULL,
  `closes_at` datetime NOT NULL,
  `status` enum('PLANNED','OPEN','CLOSED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PLANNED',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_admission_periods_code` (`code`),
  KEY `fk_admission_period_cohort` (`cohort_id`),
  CONSTRAINT `fk_admission_period_cohort` FOREIGN KEY (`cohort_id`) REFERENCES `cohorts` (`id`),
  CONSTRAINT `chk_admission_period_window` CHECK ((`closes_at` > `opens_at`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `admission_review_events` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `application_id` bigint NOT NULL,
  `actor_user_id` bigint NOT NULL,
  `event_type` enum('SUBMIT','START_REVIEW','REQUEST_CHANGES','APPROVE','REJECT','SUBMIT_TO_SCHOOL','SCHOOL_APPROVE','SCHOOL_REJECT','PDT_VERIFY','ENROLL') COLLATE utf8mb4_unicode_ci NOT NULL,
  `from_status` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `to_status` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `note` varchar(700) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `event_key` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_admission_review_event_key` (`event_key`),
  KEY `ix_admission_review_app_time` (`application_id`,`created_at`),
  KEY `fk_admission_review_user` (`actor_user_id`),
  CONSTRAINT `fk_admission_review_application` FOREIGN KEY (`application_id`) REFERENCES `admission_applications` (`id`),
  CONSTRAINT `fk_admission_review_user` FOREIGN KEY (`actor_user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `audit_logs` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `actor_user_id` bigint DEFAULT NULL,
  `action` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `entity_type` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `entity_id` varchar(80) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `detail_json` json DEFAULT NULL,
  `event_key` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_audit_logs_event` (`event_key`),
  KEY `ix_audit_logs_entity` (`entity_type`,`entity_id`),
  KEY `fk_audit_logs_actor` (`actor_user_id`),
  CONSTRAINT `fk_audit_logs_actor` FOREIGN KEY (`actor_user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cohorts` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `code` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `start_year` smallint NOT NULL,
  `end_year` smallint DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_cohorts_code` (`code`),
  CONSTRAINT `chk_cohorts_dates` CHECK (((`end_year` is null) or (`end_year` >= `start_year`)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `course_sections` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `semester_id` bigint NOT NULL,
  `course_id` bigint NOT NULL,
  `lecturer_id` bigint DEFAULT NULL,
  `section_code` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `capacity` int NOT NULL,
  `attendance_weight` decimal(5,2) NOT NULL DEFAULT '10.00',
  `midterm_weight` decimal(5,2) NOT NULL DEFAULT '30.00',
  `final_weight` decimal(5,2) NOT NULL DEFAULT '60.00',
  `is_open` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_course_sections_sem_code` (`semester_id`,`section_code`),
  KEY `ix_course_sections_course` (`course_id`),
  KEY `ix_course_sections_lecturer` (`lecturer_id`),
  CONSTRAINT `fk_sections_course` FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`),
  CONSTRAINT `fk_sections_lecturer` FOREIGN KEY (`lecturer_id`) REFERENCES `lecturers` (`id`),
  CONSTRAINT `fk_sections_semester` FOREIGN KEY (`semester_id`) REFERENCES `semesters` (`id`),
  CONSTRAINT `chk_course_sections_capacity` CHECK ((`capacity` > 0)),
  CONSTRAINT `chk_course_sections_weights` CHECK (((`attendance_weight` >= 0) and (`midterm_weight` >= 0) and (`final_weight` >= 0) and (((`attendance_weight` + `midterm_weight`) + `final_weight`) = 100.00)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `courses` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `course_code` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `title` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `credits` smallint NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_courses_code` (`course_code`),
  CONSTRAINT `chk_courses_credits` CHECK ((`credits` between 1 and 15))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ctsv_funds` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(180) COLLATE utf8mb4_unicode_ci NOT NULL,
  `channel` enum('CASH','BANK_TRANSFER') COLLATE utf8mb4_unicode_ci NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ctsv_fund_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ctsv_remittance_allocations` (
  `remittance_id` bigint NOT NULL,
  `payment_id` bigint NOT NULL,
  `allocated_amount` decimal(14,2) NOT NULL,
  PRIMARY KEY (`remittance_id`,`payment_id`),
  KEY `fk_ctsv_allocation_payment` (`payment_id`),
  CONSTRAINT `fk_ctsv_allocation_payment` FOREIGN KEY (`payment_id`) REFERENCES `payments` (`id`),
  CONSTRAINT `fk_ctsv_allocation_remittance` FOREIGN KEY (`remittance_id`) REFERENCES `ctsv_remittances` (`id`),
  CONSTRAINT `chk_ctsv_remittance_allocation_amount` CHECK ((`allocated_amount` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ctsv_remittances` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `remittance_code` varchar(70) COLLATE utf8mb4_unicode_ci NOT NULL,
  `semester_id` bigint NOT NULL,
  `fund_id` bigint NOT NULL,
  `amount` decimal(14,2) NOT NULL,
  `status` enum('DRAFT','SUBMITTED','CONFIRMED','REJECTED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT',
  `prepared_by` bigint NOT NULL,
  `reviewed_by` bigint DEFAULT NULL,
  `remitted_at` datetime DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `external_reference` varchar(120) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `note` varchar(700) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ctsv_remittance_code` (`remittance_code`),
  UNIQUE KEY `uq_ctsv_remittance_external_reference` (`external_reference`),
  KEY `ix_ctsv_remittance_semester_status` (`semester_id`,`status`),
  KEY `fk_ctsv_remittance_fund` (`fund_id`),
  KEY `fk_ctsv_remittance_prepared` (`prepared_by`),
  KEY `fk_ctsv_remittance_reviewed` (`reviewed_by`),
  CONSTRAINT `fk_ctsv_remittance_fund` FOREIGN KEY (`fund_id`) REFERENCES `ctsv_funds` (`id`),
  CONSTRAINT `fk_ctsv_remittance_prepared` FOREIGN KEY (`prepared_by`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_ctsv_remittance_reviewed` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_ctsv_remittance_sem` FOREIGN KEY (`semester_id`) REFERENCES `semesters` (`id`),
  CONSTRAINT `chk_ctsv_remittance_amount` CHECK ((`amount` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ctsv_semester_report_reviews` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `report_id` bigint NOT NULL,
  `actor_user_id` bigint NOT NULL,
  `action` enum('SUBMIT','RETURN','APPROVE') COLLATE utf8mb4_unicode_ci NOT NULL,
  `note` varchar(700) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `event_key` varchar(120) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ctsv_semester_report_review_event` (`event_key`),
  KEY `ix_ctsv_report_review_report` (`report_id`,`created_at`),
  KEY `fk_ctsv_report_review_actor` (`actor_user_id`),
  CONSTRAINT `fk_ctsv_report_review_actor` FOREIGN KEY (`actor_user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_ctsv_report_review_report` FOREIGN KEY (`report_id`) REFERENCES `ctsv_semester_reports` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ctsv_semester_reports` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `report_code` varchar(70) COLLATE utf8mb4_unicode_ci NOT NULL,
  `semester_id` bigint NOT NULL,
  `prepared_by` bigint NOT NULL,
  `status` enum('DRAFT','SUBMITTED','RETURNED','APPROVED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT',
  `received_by` bigint DEFAULT NULL,
  `submitted_at` datetime DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `note` varchar(700) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ctsv_report_code` (`report_code`),
  UNIQUE KEY `uq_ctsv_report_semester` (`semester_id`),
  KEY `fk_ctsv_report_prepared` (`prepared_by`),
  KEY `fk_ctsv_report_received` (`received_by`),
  CONSTRAINT `fk_ctsv_report_prepared` FOREIGN KEY (`prepared_by`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_ctsv_report_received` FOREIGN KEY (`received_by`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_ctsv_report_sem` FOREIGN KEY (`semester_id`) REFERENCES `semesters` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `curricula` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `major_id` bigint NOT NULL,
  `cohort_id` bigint NOT NULL,
  `title` varchar(180) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_curricula_major_cohort` (`major_id`,`cohort_id`),
  KEY `fk_curricula_cohort` (`cohort_id`),
  CONSTRAINT `fk_curricula_cohort` FOREIGN KEY (`cohort_id`) REFERENCES `cohorts` (`id`),
  CONSTRAINT `fk_curricula_major` FOREIGN KEY (`major_id`) REFERENCES `majors` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `curriculum_courses` (
  `curriculum_id` bigint NOT NULL,
  `course_id` bigint NOT NULL,
  `suggested_semester` smallint DEFAULT NULL,
  `required_course` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`curriculum_id`,`course_id`),
  KEY `fk_curriculum_courses_course` (`course_id`),
  CONSTRAINT `fk_curriculum_courses_course` FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`),
  CONSTRAINT `fk_curriculum_courses_curriculum` FOREIGN KEY (`curriculum_id`) REFERENCES `curricula` (`id`),
  CONSTRAINT `chk_curriculum_courses_sem` CHECK (((`suggested_semester` is null) or (`suggested_semester` between 1 and 12)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `email_delivery_attempts` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `outbound_email_id` bigint NOT NULL,
  `attempt_no` int NOT NULL,
  `result` enum('SENT','FAILED') COLLATE utf8mb4_unicode_ci NOT NULL,
  `provider_message_id` varchar(190) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `error_code` varchar(80) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `error_message` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `attempted_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_email_delivery_attempt` (`outbound_email_id`,`attempt_no`),
  UNIQUE KEY `uq_email_delivery_provider_message` (`provider_message_id`),
  CONSTRAINT `fk_email_delivery_outbound` FOREIGN KEY (`outbound_email_id`) REFERENCES `outbound_emails` (`id`),
  CONSTRAINT `chk_email_delivery_attempt_no` CHECK ((`attempt_no` >= 1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `enrollments` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `student_id` bigint NOT NULL,
  `section_id` bigint NOT NULL,
  `status` enum('REGISTERED','CANCELLED','COMPLETED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'REGISTERED',
  `registered_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_enrollments_student_section` (`student_id`,`section_id`),
  KEY `ix_enrollments_section` (`section_id`),
  CONSTRAINT `fk_enrollments_section` FOREIGN KEY (`section_id`) REFERENCES `course_sections` (`id`),
  CONSTRAINT `fk_enrollments_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `exam_schedules` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `section_id` bigint NOT NULL,
  `starts_at` datetime NOT NULL,
  `ends_at` datetime NOT NULL,
  `room` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `exam_type` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT',
  `note` varchar(1000) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `room_id` bigint DEFAULT NULL,
  `exam_type_id` bigint DEFAULT NULL,
  `data_origin` varchar(16) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'SCHOOL',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_exam_section` (`section_id`),
  KEY `idx_exam_time` (`starts_at`,`ends_at`),
  KEY `fk_exam_room` (`room_id`),
  KEY `fk_exam_type` (`exam_type_id`),
  CONSTRAINT `fk_exam_room` FOREIGN KEY (`room_id`) REFERENCES `rooms` (`id`),
  CONSTRAINT `fk_exam_section` FOREIGN KEY (`section_id`) REFERENCES `course_sections` (`id`),
  CONSTRAINT `fk_exam_type` FOREIGN KEY (`exam_type_id`) REFERENCES `exam_types` (`id`),
  CONSTRAINT `chk_exam_catalog_ids` CHECK (((`room_id` is not null) and (`exam_type_id` is not null))),
  CONSTRAINT `chk_exam_origin` CHECK ((`data_origin` in (_utf8mb4'SCHOOL',_utf8mb4'DEMO'))),
  CONSTRAINT `chk_exam_same_day` CHECK ((cast(`starts_at` as date) = cast(`ends_at` as date))),
  CONSTRAINT `chk_exam_status` CHECK ((`status` in (_utf8mb4'DRAFT',_utf8mb4'PUBLISHED',_utf8mb4'CANCELLED'))),
  CONSTRAINT `chk_exam_times` CHECK ((`ends_at` > `starts_at`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER `sms_exam_catalog_insert` BEFORE INSERT ON `exam_schedules` FOR EACH ROW BEGIN
    IF NEW.room_id IS NULL THEN SET NEW.room_id=(SELECT id FROM rooms WHERE code=TRIM(NEW.room)); END IF;
    IF NEW.exam_type_id IS NULL THEN SET NEW.exam_type_id=(SELECT id FROM exam_types WHERE name=NEW.exam_type); END IF;
    SET NEW.room=(SELECT code FROM rooms WHERE id=NEW.room_id);
    SET NEW.exam_type=(SELECT name FROM exam_types WHERE id=NEW.exam_type_id);
    IF NEW.room IS NULL OR NEW.exam_type IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Room and exam type must exist in catalogs'; END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER `sms_exam_catalog_update` BEFORE UPDATE ON `exam_schedules` FOR EACH ROW BEGIN
    IF NEW.room_id IS NULL OR (NEW.room<>OLD.room AND NEW.room_id=OLD.room_id) THEN SET NEW.room_id=(SELECT id FROM rooms WHERE code=TRIM(NEW.room)); END IF;
    IF NEW.exam_type_id IS NULL OR (NEW.exam_type<>OLD.exam_type AND NEW.exam_type_id=OLD.exam_type_id) THEN SET NEW.exam_type_id=(SELECT id FROM exam_types WHERE name=NEW.exam_type); END IF;
    SET NEW.room=(SELECT code FROM rooms WHERE id=NEW.room_id);
    SET NEW.exam_type=(SELECT name FROM exam_types WHERE id=NEW.exam_type_id);
    IF NEW.room IS NULL OR NEW.exam_type IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Room and exam type must exist in catalogs'; END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `exam_types` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `code` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_exam_types_code` (`code`),
  UNIQUE KEY `uq_exam_types_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `faculties` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `code` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(180) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_faculties_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `grade_reviews` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `sheet_id` bigint NOT NULL,
  `actor_user_id` bigint NOT NULL,
  `action` enum('SUBMIT','VERIFY','RETURN','APPROVE','PUBLISH') COLLATE utf8mb4_unicode_ci NOT NULL,
  `note` varchar(700) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `event_key` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_grade_reviews_event` (`event_key`),
  KEY `ix_grade_reviews_sheet_time` (`sheet_id`,`created_at`),
  KEY `fk_grade_reviews_user` (`actor_user_id`),
  CONSTRAINT `fk_grade_reviews_sheet` FOREIGN KEY (`sheet_id`) REFERENCES `grade_sheets` (`id`),
  CONSTRAINT `fk_grade_reviews_user` FOREIGN KEY (`actor_user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `grade_sheets` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `section_id` bigint NOT NULL,
  `status` enum('DRAFT','SUBMITTED','VERIFIED','RETURNED','APPROVED','PUBLISHED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT',
  `published_at` datetime DEFAULT NULL,
  `version_no` int NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_grade_sheets_section` (`section_id`),
  CONSTRAINT `fk_grade_sheets_section` FOREIGN KEY (`section_id`) REFERENCES `course_sections` (`id`),
  CONSTRAINT `chk_grade_sheets_version` CHECK ((`version_no` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `grades` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `enrollment_id` bigint NOT NULL,
  `attendance_score` decimal(4,2) DEFAULT NULL,
  `midterm_score` decimal(4,2) DEFAULT NULL,
  `final_score` decimal(4,2) DEFAULT NULL,
  `remark` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_grades_enrollment` (`enrollment_id`),
  CONSTRAINT `fk_grades_enrollment` FOREIGN KEY (`enrollment_id`) REFERENCES `enrollments` (`id`),
  CONSTRAINT `chk_grades_attendance` CHECK (((`attendance_score` is null) or (`attendance_score` between 0 and 10))),
  CONSTRAINT `chk_grades_final` CHECK (((`final_score` is null) or (`final_score` between 0 and 10))),
  CONSTRAINT `chk_grades_midterm` CHECK (((`midterm_score` is null) or (`midterm_score` between 0 and 10)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `invoice_items` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `invoice_id` bigint NOT NULL,
  `enrollment_id` bigint NOT NULL,
  `credits_at_issue` smallint NOT NULL,
  `unit_price_at_issue` decimal(14,2) NOT NULL,
  `amount` decimal(14,2) GENERATED ALWAYS AS ((`credits_at_issue` * `unit_price_at_issue`)) STORED,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_invoice_items_enrollment` (`enrollment_id`),
  KEY `ix_invoice_items_invoice` (`invoice_id`),
  CONSTRAINT `fk_invoice_items_enrollment` FOREIGN KEY (`enrollment_id`) REFERENCES `enrollments` (`id`),
  CONSTRAINT `fk_invoice_items_invoice` FOREIGN KEY (`invoice_id`) REFERENCES `invoices` (`id`),
  CONSTRAINT `chk_invoice_items_credits` CHECK ((`credits_at_issue` between 1 and 15)),
  CONSTRAINT `chk_invoice_items_price` CHECK ((`unit_price_at_issue` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `invoice_proposal_items` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `proposal_id` bigint NOT NULL,
  `enrollment_id` bigint NOT NULL,
  `credits_at_proposal` smallint NOT NULL,
  `unit_price_at_proposal` decimal(14,2) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_proposal_item` (`proposal_id`,`enrollment_id`),
  KEY `fk_proposal_item_enrollment` (`enrollment_id`),
  CONSTRAINT `fk_proposal_item_enrollment` FOREIGN KEY (`enrollment_id`) REFERENCES `enrollments` (`id`),
  CONSTRAINT `fk_proposal_item_header` FOREIGN KEY (`proposal_id`) REFERENCES `invoice_proposals` (`id`),
  CONSTRAINT `chk_proposal_item_credit` CHECK ((`credits_at_proposal` between 1 and 15)),
  CONSTRAINT `chk_proposal_item_price` CHECK ((`unit_price_at_proposal` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `invoice_proposal_reviews` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `proposal_id` bigint NOT NULL,
  `actor_user_id` bigint NOT NULL,
  `action` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `from_status` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `to_status` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `note` varchar(700) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_proposal_review_header` (`proposal_id`),
  KEY `fk_proposal_review_actor` (`actor_user_id`),
  CONSTRAINT `fk_proposal_review_actor` FOREIGN KEY (`actor_user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_proposal_review_header` FOREIGN KEY (`proposal_id`) REFERENCES `invoice_proposals` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `invoice_proposals` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `proposal_code` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `student_id` bigint NOT NULL,
  `semester_id` bigint NOT NULL,
  `discount_amount` decimal(14,2) NOT NULL DEFAULT '0.00',
  `status` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT',
  `prepared_by` bigint NOT NULL,
  `submitted_at` datetime DEFAULT NULL,
  `reviewed_by` bigint DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `decision_note` varchar(700) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `note` varchar(700) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `invoice_id` bigint DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `proposal_code` (`proposal_code`),
  UNIQUE KEY `uq_proposal_student_semester` (`student_id`,`semester_id`),
  UNIQUE KEY `invoice_id` (`invoice_id`),
  KEY `fk_proposal_semester` (`semester_id`),
  KEY `fk_proposal_preparer` (`prepared_by`),
  KEY `fk_proposal_reviewer` (`reviewed_by`),
  CONSTRAINT `fk_proposal_invoice` FOREIGN KEY (`invoice_id`) REFERENCES `invoices` (`id`),
  CONSTRAINT `fk_proposal_preparer` FOREIGN KEY (`prepared_by`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_proposal_reviewer` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_proposal_semester` FOREIGN KEY (`semester_id`) REFERENCES `semesters` (`id`),
  CONSTRAINT `fk_proposal_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`),
  CONSTRAINT `chk_proposal_decision` CHECK (((`status` not in (_utf8mb4'APPROVED',_utf8mb4'RETURNED',_utf8mb4'REJECTED',_utf8mb4'ISSUED')) or ((`reviewed_by` is not null) and (`reviewed_at` is not null)))),
  CONSTRAINT `chk_proposal_discount` CHECK ((`discount_amount` >= 0)),
  CONSTRAINT `chk_proposal_issued` CHECK ((((`status` = _utf8mb4'ISSUED') and (`invoice_id` is not null)) or ((`status` <> _utf8mb4'ISSUED') and (`invoice_id` is null)))),
  CONSTRAINT `chk_proposal_status` CHECK ((`status` in (_utf8mb4'DRAFT',_utf8mb4'SUBMITTED',_utf8mb4'APPROVED',_utf8mb4'RETURNED',_utf8mb4'REJECTED',_utf8mb4'ISSUED'))),
  CONSTRAINT `chk_proposal_submission` CHECK (((`status` = _utf8mb4'DRAFT') or (`submitted_at` is not null)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `invoices` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `student_id` bigint NOT NULL,
  `semester_id` bigint NOT NULL,
  `discount_amount` decimal(14,2) NOT NULL DEFAULT '0.00',
  `issued_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_invoices_student_semester` (`student_id`,`semester_id`),
  KEY `fk_invoices_semester` (`semester_id`),
  CONSTRAINT `fk_invoices_semester` FOREIGN KEY (`semester_id`) REFERENCES `semesters` (`id`),
  CONSTRAINT `fk_invoices_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`),
  CONSTRAINT `chk_invoices_discount` CHECK ((`discount_amount` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `lecturers` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL,
  `faculty_id` bigint NOT NULL,
  `lecturer_code` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_lecturers_user` (`user_id`),
  UNIQUE KEY `uq_lecturers_code` (`lecturer_code`),
  KEY `fk_lecturers_faculty` (`faculty_id`),
  CONSTRAINT `fk_lecturers_faculty` FOREIGN KEY (`faculty_id`) REFERENCES `faculties` (`id`),
  CONSTRAINT `fk_lecturers_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `majors` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `faculty_id` bigint NOT NULL,
  `code` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(180) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_majors_code` (`code`),
  UNIQUE KEY `uq_majors_faculty_name` (`faculty_id`,`name`),
  CONSTRAINT `fk_majors_faculty` FOREIGN KEY (`faculty_id`) REFERENCES `faculties` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notification_recipients` (
  `notification_id` bigint NOT NULL,
  `user_id` bigint NOT NULL,
  `read_at` datetime DEFAULT NULL,
  PRIMARY KEY (`notification_id`,`user_id`),
  KEY `fk_notification_recipients_user` (`user_id`),
  CONSTRAINT `fk_notification_recipients_notification` FOREIGN KEY (`notification_id`) REFERENCES `notifications` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_notification_recipients_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notifications` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `notification_code` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_by` bigint DEFAULT NULL,
  `title` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `body` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_notifications_code` (`notification_code`),
  KEY `fk_notifications_created_by` (`created_by`),
  CONSTRAINT `fk_notifications_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `outbound_emails` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `event_key` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `admission_application_id` bigint DEFAULT NULL,
  `semester_report_id` bigint DEFAULT NULL,
  `student_request_id` bigint DEFAULT NULL,
  `template_code` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `recipient_email` varchar(190) COLLATE utf8mb4_unicode_ci NOT NULL,
  `subject` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `delivery_status` enum('QUEUED','SENDING','SENT','FAILED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'QUEUED',
  `attempt_count` int NOT NULL DEFAULT '0',
  `last_error` varchar(700) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `queued_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `sent_at` datetime DEFAULT NULL,
  `mailbox_id` bigint DEFAULT NULL,
  `body_text` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_outbound_email_event` (`event_key`),
  KEY `ix_outbound_email_queue` (`delivery_status`,`queued_at`),
  KEY `fk_email_admission` (`admission_application_id`),
  KEY `fk_email_report` (`semester_report_id`),
  KEY `fk_email_request` (`student_request_id`),
  KEY `fk_outbound_mailbox` (`mailbox_id`),
  CONSTRAINT `fk_email_admission` FOREIGN KEY (`admission_application_id`) REFERENCES `admission_applications` (`id`),
  CONSTRAINT `fk_email_report` FOREIGN KEY (`semester_report_id`) REFERENCES `ctsv_semester_reports` (`id`),
  CONSTRAINT `fk_email_request` FOREIGN KEY (`student_request_id`) REFERENCES `student_requests` (`id`),
  CONSTRAINT `fk_outbound_mailbox` FOREIGN KEY (`mailbox_id`) REFERENCES `student_school_mailboxes` (`id`),
  CONSTRAINT `chk_outbound_email_attempt` CHECK ((`attempt_count` >= 0)),
  CONSTRAINT `chk_outbound_email_one_origin` CHECK ((((((`admission_application_id` is not null) + (`semester_report_id` is not null)) + (`student_request_id` is not null)) + (`mailbox_id` is not null)) = 1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `password_reset_tokens` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL,
  `token_hash` char(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `expires_at` datetime NOT NULL,
  `used_at` datetime DEFAULT NULL,
  `delivery_status` varchar(12) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `token_hash` (`token_hash`),
  KEY `ix_password_reset_user` (`user_id`,`expires_at`),
  CONSTRAINT `password_reset_tokens_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `chk_reset_delivery` CHECK ((`delivery_status` in (_utf8mb4'PENDING',_utf8mb4'SENT',_utf8mb4'FAILED'))),
  CONSTRAINT `chk_reset_expiry` CHECK ((`expires_at` > `created_at`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `payments` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `invoice_id` bigint NOT NULL,
  `recorded_by` bigint NOT NULL,
  `amount` decimal(14,2) NOT NULL,
  `paid_at` datetime NOT NULL,
  `reference_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `note` varchar(400) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fund_id` bigint DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_payments_reference` (`reference_no`),
  KEY `ix_payments_invoice` (`invoice_id`),
  KEY `fk_payments_recorded_by` (`recorded_by`),
  KEY `fk_payments_ctsv_fund` (`fund_id`),
  CONSTRAINT `fk_payments_ctsv_fund` FOREIGN KEY (`fund_id`) REFERENCES `ctsv_funds` (`id`),
  CONSTRAINT `fk_payments_invoice` FOREIGN KEY (`invoice_id`) REFERENCES `invoices` (`id`),
  CONSTRAINT `fk_payments_recorded_by` FOREIGN KEY (`recorded_by`) REFERENCES `users` (`id`),
  CONSTRAINT `chk_payments_amount` CHECK ((`amount` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `roles` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `code` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(160) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_roles_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rooms` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `code` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(160) COLLATE utf8mb4_unicode_ci NOT NULL,
  `capacity` int DEFAULT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_rooms_code` (`code`),
  CONSTRAINT `chk_rooms_capacity` CHECK (((`capacity` is null) or (`capacity` > 0))),
  CONSTRAINT `chk_rooms_code` CHECK ((char_length(trim(`code`)) > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `schema_migrations` (
  `version` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `checksum` char(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `applied_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `section_schedules` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `section_id` bigint NOT NULL,
  `day_of_week` tinyint NOT NULL,
  `starts_at` time NOT NULL,
  `ends_at` time NOT NULL,
  `room` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `room_id` bigint DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_section_schedules_slot` (`section_id`,`day_of_week`,`starts_at`,`ends_at`),
  KEY `ix_schedules_room_day` (`room`,`day_of_week`,`starts_at`),
  KEY `fk_schedule_room` (`room_id`),
  CONSTRAINT `fk_schedule_room` FOREIGN KEY (`room_id`) REFERENCES `rooms` (`id`),
  CONSTRAINT `fk_section_schedules_section` FOREIGN KEY (`section_id`) REFERENCES `course_sections` (`id`),
  CONSTRAINT `chk_schedule_room_id` CHECK ((`room_id` is not null)),
  CONSTRAINT `chk_section_schedules_day` CHECK ((`day_of_week` between 1 and 7)),
  CONSTRAINT `chk_section_schedules_time` CHECK ((`ends_at` > `starts_at`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER `sms_schedule_catalog_insert` BEFORE INSERT ON `section_schedules` FOR EACH ROW BEGIN
    IF NEW.room_id IS NULL THEN SET NEW.room_id=(SELECT id FROM rooms WHERE code=TRIM(NEW.room)); END IF;
    SET NEW.room=(SELECT code FROM rooms WHERE id=NEW.room_id);
    IF NEW.room IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Room must exist in rooms catalog'; END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER `sms_schedule_catalog_update` BEFORE UPDATE ON `section_schedules` FOR EACH ROW BEGIN
    IF NEW.room_id IS NULL OR (NEW.room<>OLD.room AND NEW.room_id=OLD.room_id) THEN
        SET NEW.room_id=(SELECT id FROM rooms WHERE code=TRIM(NEW.room));
    END IF;
    SET NEW.room=(SELECT code FROM rooms WHERE id=NEW.room_id);
    IF NEW.room IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Room must exist in rooms catalog'; END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `semesters` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `academic_year_id` bigint NOT NULL,
  `code` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `starts_on` date NOT NULL,
  `ends_on` date NOT NULL,
  `registration_from` datetime DEFAULT NULL,
  `registration_to` datetime DEFAULT NULL,
  `status` enum('PLANNED','OPEN','CLOSED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PLANNED',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_semesters_year_code` (`academic_year_id`,`code`),
  CONSTRAINT `fk_semesters_year` FOREIGN KEY (`academic_year_id`) REFERENCES `academic_years` (`id`),
  CONSTRAINT `chk_semesters_dates` CHECK ((`ends_on` >= `starts_on`)),
  CONSTRAINT `chk_semesters_window` CHECK (((`registration_from` is null) or (`registration_to` is null) or (`registration_to` >= `registration_from`)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student_profile_photos` (
  `student_id` bigint NOT NULL,
  `storage_key` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `mime_type` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `updated_by` bigint NOT NULL,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`student_id`),
  KEY `updated_by` (`updated_by`),
  CONSTRAINT `student_profile_photos_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`),
  CONSTRAINT `student_profile_photos_ibfk_2` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`),
  CONSTRAINT `chk_photo_mime` CHECK ((`mime_type` in (_utf8mb4'image/jpeg',_utf8mb4'image/png')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student_request_attachments` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `request_id` bigint NOT NULL,
  `uploaded_by` bigint NOT NULL,
  `file_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `storage_key` varchar(400) COLLATE utf8mb4_unicode_ci NOT NULL,
  `mime_type` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `size_bytes` bigint NOT NULL,
  `uploaded_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_student_request_file_key` (`storage_key`),
  KEY `ix_student_request_files_request` (`request_id`),
  KEY `fk_student_request_file_uploader` (`uploaded_by`),
  CONSTRAINT `fk_student_request_file_request` FOREIGN KEY (`request_id`) REFERENCES `student_requests` (`id`),
  CONSTRAINT `fk_student_request_file_uploader` FOREIGN KEY (`uploaded_by`) REFERENCES `users` (`id`),
  CONSTRAINT `chk_student_request_file_size` CHECK (((`size_bytes` > 0) and (`size_bytes` <= 10485760)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student_request_review_events` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `request_id` bigint NOT NULL,
  `reviewer_user_id` bigint NOT NULL,
  `action` enum('ASSIGN','ASK_MORE_INFO','RESOLVE','REJECT','REOPEN','ESCALATE_TO_SCHOOL','SCHOOL_FEEDBACK','RETURN_TO_CTSV') COLLATE utf8mb4_unicode_ci NOT NULL,
  `note` varchar(700) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `event_key` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `school_recipient_user_id` bigint DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_student_request_review_key` (`event_key`),
  KEY `ix_student_request_review_timeline` (`request_id`,`created_at`),
  KEY `fk_student_request_review_reviewer` (`reviewer_user_id`),
  KEY `fk_ctsv_request_escalation_recipient` (`school_recipient_user_id`),
  CONSTRAINT `fk_ctsv_request_escalation_recipient` FOREIGN KEY (`school_recipient_user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_student_request_review_request` FOREIGN KEY (`request_id`) REFERENCES `student_requests` (`id`),
  CONSTRAINT `fk_student_request_review_reviewer` FOREIGN KEY (`reviewer_user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student_requests` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `request_code` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `student_id` bigint NOT NULL,
  `request_type` enum('PROFILE_UPDATE','STUDY_STATUS','GRADE_QUESTION','TUITION_QUESTION','DOCUMENT_REQUEST','STUDENT_SUPPORT','COMPLAINT','OTHER') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PROFILE_UPDATE',
  `content` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('PENDING','PROCESSING','RESOLVED','REJECTED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING',
  `handled_by` bigint DEFAULT NULL,
  `response` text COLLATE utf8mb4_unicode_ci,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `handled_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_student_requests_code` (`request_code`),
  KEY `ix_student_requests_student_status` (`student_id`,`status`),
  KEY `fk_student_requests_handler` (`handled_by`),
  CONSTRAINT `fk_student_requests_handler` FOREIGN KEY (`handled_by`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_student_requests_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student_school_mailboxes` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `student_id` bigint NOT NULL,
  `school_email` varchar(190) COLLATE utf8mb4_unicode_ci NOT NULL,
  `provisioning_status` enum('RESERVED','PROVISIONING','ACTIVE','FAILED','DISABLED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'RESERVED',
  `reserved_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `activated_at` datetime DEFAULT NULL,
  `provisioned_by` bigint DEFAULT NULL,
  `note` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_student_mailbox_student` (`student_id`),
  UNIQUE KEY `uq_student_mailbox_email` (`school_email`),
  KEY `fk_student_mailbox_provisioned_by` (`provisioned_by`),
  CONSTRAINT `fk_student_mailbox_provisioned_by` FOREIGN KEY (`provisioned_by`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_student_mailbox_student` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `students` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL,
  `student_code` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `class_id` bigint NOT NULL,
  `date_of_birth` date DEFAULT NULL,
  `phone` varchar(24) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address` varchar(400) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('STUDYING','SUSPENDED','WITHDRAWN','GRADUATED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'STUDYING',
  `enrolled_on` date DEFAULT NULL,
  `gender` enum('MALE','FEMALE','OTHER','UNDISCLOSED') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `place_of_birth` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `hometown` varchar(250) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `permanent_address` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `current_address` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `nationality` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `guardian_full_name` varchar(160) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `guardian_phone` varchar(24) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_students_user` (`user_id`),
  UNIQUE KEY `uq_students_code` (`student_code`),
  KEY `ix_students_class` (`class_id`),
  CONSTRAINT `fk_students_class` FOREIGN KEY (`class_id`) REFERENCES `academic_classes` (`id`),
  CONSTRAINT `fk_students_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tuition_adjustments` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `adjustment_code` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `invoice_id` bigint NOT NULL,
  `kind` enum('DEBIT','CREDIT') COLLATE utf8mb4_unicode_ci NOT NULL,
  `amount` decimal(14,2) NOT NULL,
  `reason` varchar(700) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('REQUESTED','APPROVED','REJECTED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'REQUESTED',
  `requested_by` bigint NOT NULL,
  `approved_by` bigint DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `decided_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tuition_adjustment_code` (`adjustment_code`),
  KEY `ix_tuition_adjustment_invoice_status` (`invoice_id`,`status`),
  KEY `fk_tuition_adjustment_requester` (`requested_by`),
  KEY `fk_tuition_adjustment_approver` (`approved_by`),
  CONSTRAINT `fk_tuition_adjustment_approver` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_tuition_adjustment_invoice` FOREIGN KEY (`invoice_id`) REFERENCES `invoices` (`id`),
  CONSTRAINT `fk_tuition_adjustment_requester` FOREIGN KEY (`requested_by`) REFERENCES `users` (`id`),
  CONSTRAINT `chk_tuition_adjustments_amount` CHECK ((`amount` > 0)),
  CONSTRAINT `chk_tuition_adjustments_decision` CHECK ((((`status` = _utf8mb4'REQUESTED') and (`approved_by` is null) and (`decided_at` is null)) or ((`status` in (_utf8mb4'APPROVED',_utf8mb4'REJECTED')) and (`approved_by` is not null) and (`decided_at` is not null))))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tuition_rates` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `semester_id` bigint NOT NULL,
  `price_per_credit` decimal(14,2) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tuition_rates_semester` (`semester_id`),
  CONSTRAINT `fk_tuition_rates_semester` FOREIGN KEY (`semester_id`) REFERENCES `semesters` (`id`),
  CONSTRAINT `chk_tuition_rates_price` CHECK ((`price_per_credit` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_roles` (
  `user_id` bigint NOT NULL,
  `role_id` bigint NOT NULL,
  PRIMARY KEY (`user_id`,`role_id`),
  KEY `fk_user_roles_role` (`role_id`),
  CONSTRAINT `fk_user_roles_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`),
  CONSTRAINT `fk_user_roles_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `username` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(190) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `full_name` varchar(160) COLLATE utf8mb4_unicode_ci NOT NULL,
  `enabled` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_users_username` (`username`),
  UNIQUE KEY `uq_users_email` (`email`),
  CONSTRAINT `chk_user_name_not_blank` CHECK (((char_length(trim(`full_name`)) > 0) and (char_length(trim(`username`)) > 0)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_admission_document_checklist` AS SELECT 
 1 AS `application_id`,
 1 AS `application_code`,
 1 AS `document_type`,
 1 AS `label`,
 1 AS `is_required`,
 1 AS `latest_document_id`,
 1 AS `revision_no`,
 1 AS `document_status`,
 1 AS `requirement_satisfied`*/;
SET character_set_client = @saved_cs_client;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_admission_dossier_progress` AS SELECT 
 1 AS `application_id`,
 1 AS `application_code`,
 1 AS `status`,
 1 AS `documents_listed`,
 1 AS `required_count`,
 1 AS `verified_required_count`,
 1 AS `dossier_check`*/;
SET character_set_client = @saved_cs_client;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_approval_workflow_checks` AS SELECT 
 1 AS `check_name`,
 1 AS `violation_count`*/;
SET character_set_client = @saved_cs_client;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_ctsv_fund_balances` AS SELECT 
 1 AS `fund_id`,
 1 AS `fund_code`,
 1 AS `fund_name`,
 1 AS `channel`,
 1 AS `collected_amount`,
 1 AS `remitted_amount`,
 1 AS `balance_amount`*/;
SET character_set_client = @saved_cs_client;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_ctsv_remittance_tracking` AS SELECT 
 1 AS `remittance_id`,
 1 AS `remittance_code`,
 1 AS `semester_id`,
 1 AS `fund_id`,
 1 AS `status`,
 1 AS `declared_amount`,
 1 AS `allocated_amount`,
 1 AS `difference_amount`,
 1 AS `payment_count`*/;
SET character_set_client = @saved_cs_client;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_ctsv_semester_finance` AS SELECT 
 1 AS `semester_id`,
 1 AS `academic_year`,
 1 AS `semester_code`,
 1 AS `total_tuition_due`,
 1 AS `total_paid`,
 1 AS `collected_via_ctsv`,
 1 AS `legacy_unassigned_paid`,
 1 AS `total_outstanding`,
 1 AS `remitted_to_school`,
 1 AS `student_issue_count`,
 1 AS `unresolved_issue_count`,
 1 AS `escalated_issue_count`*/;
SET character_set_client = @saved_cs_client;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_email_delivery_history` AS SELECT 
 1 AS `email_id`,
 1 AS `event_key`,
 1 AS `template_code`,
 1 AS `recipient_email`,
 1 AS `delivery_status`,
 1 AS `queued_at`,
 1 AS `sent_at`,
 1 AS `logged_attempts`,
 1 AS `last_attempt_at`,
 1 AS `last_success_at`*/;
SET character_set_client = @saved_cs_client;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_grade_entry_roster` AS SELECT 
 1 AS `enrollment_id`,
 1 AS `student_id`,
 1 AS `student_code`,
 1 AS `student_name`,
 1 AS `section_id`,
 1 AS `section_code`,
 1 AS `lecturer_id`,
 1 AS `semester_id`,
 1 AS `grade_sheet_id`,
 1 AS `sheet_status`,
 1 AS `grade_id`,
 1 AS `attendance_score`,
 1 AS `midterm_score`,
 1 AS `final_score`,
 1 AS `enrollment_status`*/;
SET character_set_client = @saved_cs_client;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_invoice_balances` AS SELECT 
 1 AS `invoice_id`,
 1 AS `student_id`,
 1 AS `semester_id`,
 1 AS `issued_at`,
 1 AS `base_amount`,
 1 AS `discount_amount`,
 1 AS `debit_amount`,
 1 AS `credit_amount`,
 1 AS `payable_amount`,
 1 AS `paid_amount`,
 1 AS `remaining_amount`,
 1 AS `payment_status`*/;
SET character_set_client = @saved_cs_client;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_normalization_checks` AS SELECT 
 1 AS `check_name`,
 1 AS `violation_count`*/;
SET character_set_client = @saved_cs_client;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_school_admission_decisions` AS SELECT 
 1 AS `application_id`,
 1 AS `application_code`,
 1 AS `current_status`,
 1 AS `decision_event_id`,
 1 AS `event_type`,
 1 AS `from_status`,
 1 AS `to_status`,
 1 AS `actor_user_id`,
 1 AS `reviewer_name`,
 1 AS `note`,
 1 AS `created_at`,
 1 AS `reviewer_is_bgh`*/;
SET character_set_client = @saved_cs_client;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_school_admission_queue` AS SELECT 
 1 AS `application_id`,
 1 AS `application_code`,
 1 AS `status`,
 1 AS `legal_full_name`,
 1 AS `personal_email`,
 1 AS `phone`,
 1 AS `major_id`,
 1 AS `period_id`,
 1 AS `assigned_ctsv_user_id`,
 1 AS `submitted_at`,
 1 AS `required_count`,
 1 AS `verified_required_count`,
 1 AS `dossier_check`*/;
SET character_set_client = @saved_cs_client;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_school_ctsv_report_register` AS SELECT 
 1 AS `report_id`,
 1 AS `report_code`,
 1 AS `semester_id`,
 1 AS `status`,
 1 AS `prepared_by`,
 1 AS `received_by`,
 1 AS `submitted_at`,
 1 AS `reviewed_at`,
 1 AS `total_tuition_due`,
 1 AS `total_paid`,
 1 AS `total_outstanding`,
 1 AS `collected_via_ctsv`,
 1 AS `legacy_unassigned_paid`,
 1 AS `remitted_to_school`,
 1 AS `student_issue_count`,
 1 AS `unresolved_issue_count`,
 1 AS `escalated_issue_count`,
 1 AS `review_events`*/;
SET character_set_client = @saved_cs_client;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_school_tuition_by_semester` AS SELECT 
 1 AS `semester_id`,
 1 AS `academic_year`,
 1 AS `semester_code`,
 1 AS `invoice_count`,
 1 AS `students_billed`,
 1 AS `base_amount`,
 1 AS `discounted_amount`,
 1 AS `approved_extra_fees`,
 1 AS `approved_credits`,
 1 AS `total_receivables`,
 1 AS `collected`,
 1 AS `outstanding`,
 1 AS `unpaid_invoice_count`*/;
SET character_set_client = @saved_cs_client;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_school_tuition_total` AS SELECT 
 1 AS `scope_code`,
 1 AS `total_receivables`,
 1 AS `collected`,
 1 AS `outstanding`,
 1 AS `invoice_count`,
 1 AS `unpaid_invoice_count`*/;
SET character_set_client = @saved_cs_client;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_section_registration_counts` AS SELECT 
 1 AS `section_id`,
 1 AS `section_code`,
 1 AS `capacity`,
 1 AS `registered_count`,
 1 AS `remaining_seats`*/;
SET character_set_client = @saved_cs_client;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_student_results` AS SELECT 
 1 AS `enrollment_id`,
 1 AS `student_id`,
 1 AS `student_code`,
 1 AS `section_id`,
 1 AS `section_code`,
 1 AS `course_code`,
 1 AS `credits`,
 1 AS `grade_sheet_status`,
 1 AS `attendance_score`,
 1 AS `midterm_score`,
 1 AS `final_score`,
 1 AS `total_score`*/;
SET character_set_client = @saved_cs_client;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_student_timetable` AS SELECT 
 1 AS `enrollment_id`,
 1 AS `student_id`,
 1 AS `section_id`,
 1 AS `semester_id`,
 1 AS `course_code`,
 1 AS `course_title`,
 1 AS `section_code`,
 1 AS `day_of_week`,
 1 AS `starts_at`,
 1 AS `ends_at`,
 1 AS `room`,
 1 AS `lecturer_id`,
 1 AS `lecturer_name`,
 1 AS `enrollment_status`*/;
SET character_set_client = @saved_cs_client;
/*!50001 DROP VIEW IF EXISTS `v_admission_document_checklist`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013  SQL SECURITY INVOKER */
/*!50001 VIEW `v_admission_document_checklist` AS select `a`.`id` AS `application_id`,`a`.`application_code` AS `application_code`,`r`.`document_type` AS `document_type`,`r`.`label` AS `label`,`r`.`is_required` AS `is_required`,`d`.`id` AS `latest_document_id`,`d`.`revision_no` AS `revision_no`,`d`.`status` AS `document_status`,(case when (`r`.`is_required` = 0) then 1 when ((`d`.`id` is not null) and (`d`.`status` = 'VERIFIED')) then 1 else 0 end) AS `requirement_satisfied` from ((`admission_applications` `a` join `admission_document_requirements` `r` on((`r`.`period_id` = `a`.`period_id`))) left join `admission_documents` `d` on((`d`.`id` = (select `d2`.`id` from `admission_documents` `d2` where ((`d2`.`application_id` = `a`.`id`) and (`d2`.`document_type` = `r`.`document_type`)) order by `d2`.`revision_no` desc,`d2`.`id` desc limit 1)))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `v_admission_dossier_progress`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013  SQL SECURITY INVOKER */
/*!50001 VIEW `v_admission_dossier_progress` AS select `a`.`id` AS `application_id`,`a`.`application_code` AS `application_code`,`a`.`status` AS `status`,count(`ch`.`document_type`) AS `documents_listed`,sum((case when (`ch`.`is_required` = 1) then 1 else 0 end)) AS `required_count`,sum((case when ((`ch`.`is_required` = 1) and (`ch`.`requirement_satisfied` = 1)) then 1 else 0 end)) AS `verified_required_count`,(case when (sum((case when ((`ch`.`is_required` = 1) and (`ch`.`requirement_satisfied` = 0)) then 1 else 0 end)) = 0) then 'DOCUMENTS_OK' else 'DOCUMENTS_MISSING' end) AS `dossier_check` from (`admission_applications` `a` left join `v_admission_document_checklist` `ch` on((`ch`.`application_id` = `a`.`id`))) group by `a`.`id`,`a`.`application_code`,`a`.`status` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `v_approval_workflow_checks`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013  SQL SECURITY INVOKER */
/*!50001 VIEW `v_approval_workflow_checks` AS select 'PROPOSAL_WITHOUT_ITEMS' AS `check_name`,count(0) AS `violation_count` from `invoice_proposals` `p` where (not exists(select 1 from `invoice_proposal_items` `it` where (`it`.`proposal_id` = `p`.`id`))) union all select 'PROPOSAL_WRONG_ENROLLMENT' AS `PROPOSAL_WRONG_ENROLLMENT`,count(0) AS `COUNT(*)` from (((`invoice_proposal_items` `it` join `invoice_proposals` `p` on((`p`.`id` = `it`.`proposal_id`))) join `enrollments` `e` on((`e`.`id` = `it`.`enrollment_id`))) join `course_sections` `cs` on((`cs`.`id` = `e`.`section_id`))) where ((`e`.`student_id` <> `p`.`student_id`) or (`cs`.`semester_id` <> `p`.`semester_id`)) union all select 'PROPOSAL_MISSING_SUBMISSION' AS `PROPOSAL_MISSING_SUBMISSION`,count(0) AS `COUNT(*)` from `invoice_proposals` `p` where ((`p`.`status` = 'SUBMITTED') and (not exists(select 1 from ((`invoice_proposal_reviews` `r` join `user_roles` `ur` on((`ur`.`user_id` = `r`.`actor_user_id`))) join `roles` `ro` on((`ro`.`id` = `ur`.`role_id`))) where ((`r`.`proposal_id` = `p`.`id`) and (`r`.`action` = 'SUBMIT') and (`ro`.`code` = 'CTSV'))))) union all select 'PROPOSAL_MISSING_APPROVAL' AS `PROPOSAL_MISSING_APPROVAL`,count(0) AS `COUNT(*)` from `invoice_proposals` `p` where ((`p`.`status` in ('APPROVED','ISSUED')) and (not exists(select 1 from ((`invoice_proposal_reviews` `r` join `user_roles` `ur` on((`ur`.`user_id` = `r`.`actor_user_id`))) join `roles` `ro` on((`ro`.`id` = `ur`.`role_id`))) where ((`r`.`proposal_id` = `p`.`id`) and (`r`.`action` = 'APPROVE') and (`ro`.`code` = 'PRINCIPAL') and (`r`.`actor_user_id` <> `p`.`prepared_by`))))) union all select 'VERIFIED_SHEET_WITHOUT_PDT' AS `VERIFIED_SHEET_WITHOUT_PDT`,count(0) AS `COUNT(*)` from `grade_sheets` `gs` where ((`gs`.`status` = 'VERIFIED') and (not exists(select 1 from ((`grade_reviews` `r` join `user_roles` `ur` on((`ur`.`user_id` = `r`.`actor_user_id`))) join `roles` `ro` on((`ro`.`id` = `ur`.`role_id`))) where ((`r`.`sheet_id` = `gs`.`id`) and (`r`.`action` = 'VERIFY') and (`ro`.`code` = 'TRAINING_OFFICE'))))) union all select 'PROPOSAL_DISCOUNT_OVER_TOTAL' AS `PROPOSAL_DISCOUNT_OVER_TOTAL`,count(0) AS `COUNT(*)` from `invoice_proposals` `p` where (`p`.`discount_amount` > (select coalesce(sum((`it`.`credits_at_proposal` * `it`.`unit_price_at_proposal`)),0) from `invoice_proposal_items` `it` where (`it`.`proposal_id` = `p`.`id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `v_ctsv_fund_balances`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013  SQL SECURITY INVOKER */
/*!50001 VIEW `v_ctsv_fund_balances` AS select `f`.`id` AS `fund_id`,`f`.`code` AS `fund_code`,`f`.`name` AS `fund_name`,`f`.`channel` AS `channel`,coalesce((select sum(`p`.`amount`) from `payments` `p` where (`p`.`fund_id` = `f`.`id`)),0.00) AS `collected_amount`,coalesce((select sum(`r`.`amount`) from `ctsv_remittances` `r` where ((`r`.`fund_id` = `f`.`id`) and (`r`.`status` = 'CONFIRMED'))),0.00) AS `remitted_amount`,(coalesce((select sum(`p`.`amount`) from `payments` `p` where (`p`.`fund_id` = `f`.`id`)),0.00) - coalesce((select sum(`r`.`amount`) from `ctsv_remittances` `r` where ((`r`.`fund_id` = `f`.`id`) and (`r`.`status` = 'CONFIRMED'))),0.00)) AS `balance_amount` from `ctsv_funds` `f` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `v_ctsv_remittance_tracking`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013  SQL SECURITY INVOKER */
/*!50001 VIEW `v_ctsv_remittance_tracking` AS select `r`.`id` AS `remittance_id`,`r`.`remittance_code` AS `remittance_code`,`r`.`semester_id` AS `semester_id`,`r`.`fund_id` AS `fund_id`,`r`.`status` AS `status`,`r`.`amount` AS `declared_amount`,coalesce(`x`.`allocated_amount`,0.00) AS `allocated_amount`,(`r`.`amount` - coalesce(`x`.`allocated_amount`,0.00)) AS `difference_amount`,coalesce(`x`.`payment_count`,0) AS `payment_count` from (`ctsv_remittances` `r` left join (select `ctsv_remittance_allocations`.`remittance_id` AS `remittance_id`,sum(`ctsv_remittance_allocations`.`allocated_amount`) AS `allocated_amount`,count(0) AS `payment_count` from `ctsv_remittance_allocations` group by `ctsv_remittance_allocations`.`remittance_id`) `x` on((`x`.`remittance_id` = `r`.`id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `v_ctsv_semester_finance`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013  SQL SECURITY INVOKER */
/*!50001 VIEW `v_ctsv_semester_finance` AS select `s`.`id` AS `semester_id`,`ay`.`name` AS `academic_year`,`s`.`code` AS `semester_code`,coalesce((select sum(`v`.`payable_amount`) from `v_invoice_balances` `v` where (`v`.`semester_id` = `s`.`id`)),0.00) AS `total_tuition_due`,coalesce((select sum(`p`.`amount`) from (`payments` `p` join `invoices` `i` on((`i`.`id` = `p`.`invoice_id`))) where (`i`.`semester_id` = `s`.`id`)),0.00) AS `total_paid`,coalesce((select sum(`p`.`amount`) from (`payments` `p` join `invoices` `i` on((`i`.`id` = `p`.`invoice_id`))) where ((`i`.`semester_id` = `s`.`id`) and (`p`.`fund_id` is not null))),0.00) AS `collected_via_ctsv`,coalesce((select sum(`p`.`amount`) from (`payments` `p` join `invoices` `i` on((`i`.`id` = `p`.`invoice_id`))) where ((`i`.`semester_id` = `s`.`id`) and (`p`.`fund_id` is null))),0.00) AS `legacy_unassigned_paid`,coalesce((select sum(`v`.`remaining_amount`) from `v_invoice_balances` `v` where (`v`.`semester_id` = `s`.`id`)),0.00) AS `total_outstanding`,coalesce((select sum(`r`.`amount`) from `ctsv_remittances` `r` where ((`r`.`semester_id` = `s`.`id`) and (`r`.`status` = 'CONFIRMED'))),0.00) AS `remitted_to_school`,(select count(0) from `student_requests` `q` where ((`q`.`created_at` >= `s`.`starts_on`) and (`q`.`created_at` < (`s`.`ends_on` + interval 1 day)))) AS `student_issue_count`,(select count(0) from `student_requests` `q` where ((`q`.`created_at` >= `s`.`starts_on`) and (`q`.`created_at` < (`s`.`ends_on` + interval 1 day)) and (`q`.`status` in ('PENDING','PROCESSING')))) AS `unresolved_issue_count`,(select count(distinct `q`.`id`) from (`student_requests` `q` join `student_request_review_events` `e` on((`e`.`request_id` = `q`.`id`))) where ((`q`.`created_at` >= `s`.`starts_on`) and (`q`.`created_at` < (`s`.`ends_on` + interval 1 day)) and (`e`.`action` = 'ESCALATE_TO_SCHOOL'))) AS `escalated_issue_count` from (`semesters` `s` join `academic_years` `ay` on((`ay`.`id` = `s`.`academic_year_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `v_email_delivery_history`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013  SQL SECURITY INVOKER */
/*!50001 VIEW `v_email_delivery_history` AS select `o`.`id` AS `email_id`,`o`.`event_key` AS `event_key`,`o`.`template_code` AS `template_code`,`o`.`recipient_email` AS `recipient_email`,`o`.`delivery_status` AS `delivery_status`,`o`.`queued_at` AS `queued_at`,`o`.`sent_at` AS `sent_at`,count(`a`.`id`) AS `logged_attempts`,max(`a`.`attempted_at`) AS `last_attempt_at`,max((case when (`a`.`result` = 'SENT') then `a`.`attempted_at` else NULL end)) AS `last_success_at` from (`outbound_emails` `o` left join `email_delivery_attempts` `a` on((`a`.`outbound_email_id` = `o`.`id`))) group by `o`.`id`,`o`.`event_key`,`o`.`template_code`,`o`.`recipient_email`,`o`.`delivery_status`,`o`.`queued_at`,`o`.`sent_at` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `v_grade_entry_roster`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013  SQL SECURITY INVOKER */
/*!50001 VIEW `v_grade_entry_roster` AS select `e`.`id` AS `enrollment_id`,`e`.`student_id` AS `student_id`,`s`.`student_code` AS `student_code`,`u`.`full_name` AS `student_name`,`cs`.`id` AS `section_id`,`cs`.`section_code` AS `section_code`,`cs`.`lecturer_id` AS `lecturer_id`,`cs`.`semester_id` AS `semester_id`,`gs`.`id` AS `grade_sheet_id`,`gs`.`status` AS `sheet_status`,`g`.`id` AS `grade_id`,`g`.`attendance_score` AS `attendance_score`,`g`.`midterm_score` AS `midterm_score`,`g`.`final_score` AS `final_score`,`e`.`status` AS `enrollment_status` from (((((`enrollments` `e` join `students` `s` on((`s`.`id` = `e`.`student_id`))) join `users` `u` on((`u`.`id` = `s`.`user_id`))) join `course_sections` `cs` on((`cs`.`id` = `e`.`section_id`))) left join `grade_sheets` `gs` on((`gs`.`section_id` = `cs`.`id`))) left join `grades` `g` on((`g`.`enrollment_id` = `e`.`id`))) where (`e`.`status` in ('REGISTERED','COMPLETED')) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `v_invoice_balances`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013  SQL SECURITY INVOKER */
/*!50001 VIEW `v_invoice_balances` AS select `t`.`invoice_id` AS `invoice_id`,`t`.`student_id` AS `student_id`,`t`.`semester_id` AS `semester_id`,`t`.`issued_at` AS `issued_at`,`t`.`base_amount` AS `base_amount`,`t`.`discount_amount` AS `discount_amount`,`t`.`debit_amount` AS `debit_amount`,`t`.`credit_amount` AS `credit_amount`,greatest((((`t`.`base_amount` - `t`.`discount_amount`) + `t`.`debit_amount`) - `t`.`credit_amount`),0.00) AS `payable_amount`,`t`.`paid_amount` AS `paid_amount`,greatest(((((`t`.`base_amount` - `t`.`discount_amount`) + `t`.`debit_amount`) - `t`.`credit_amount`) - `t`.`paid_amount`),0.00) AS `remaining_amount`,(case when (((((`t`.`base_amount` - `t`.`discount_amount`) + `t`.`debit_amount`) - `t`.`credit_amount`) <= `t`.`paid_amount`) and ((`t`.`base_amount` + `t`.`debit_amount`) > 0)) then 'PAID' when (`t`.`paid_amount` > 0) then 'PARTIAL' else 'UNPAID' end) AS `payment_status` from (select `i`.`id` AS `invoice_id`,`i`.`student_id` AS `student_id`,`i`.`semester_id` AS `semester_id`,`i`.`issued_at` AS `issued_at`,coalesce(`it`.`base_amount`,0.00) AS `base_amount`,`i`.`discount_amount` AS `discount_amount`,coalesce(`ad`.`debit_amount`,0.00) AS `debit_amount`,coalesce(`ad`.`credit_amount`,0.00) AS `credit_amount`,coalesce(`p`.`paid_amount`,0.00) AS `paid_amount` from (((`invoices` `i` left join (select `invoice_items`.`invoice_id` AS `invoice_id`,sum(`invoice_items`.`amount`) AS `base_amount` from `invoice_items` group by `invoice_items`.`invoice_id`) `it` on((`it`.`invoice_id` = `i`.`id`))) left join (select `tuition_adjustments`.`invoice_id` AS `invoice_id`,sum((case when (`tuition_adjustments`.`kind` = 'DEBIT') then `tuition_adjustments`.`amount` else 0 end)) AS `debit_amount`,sum((case when (`tuition_adjustments`.`kind` = 'CREDIT') then `tuition_adjustments`.`amount` else 0 end)) AS `credit_amount` from `tuition_adjustments` where (`tuition_adjustments`.`status` = 'APPROVED') group by `tuition_adjustments`.`invoice_id`) `ad` on((`ad`.`invoice_id` = `i`.`id`))) left join (select `payments`.`invoice_id` AS `invoice_id`,sum(`payments`.`amount`) AS `paid_amount` from `payments` group by `payments`.`invoice_id`) `p` on((`p`.`invoice_id` = `i`.`id`)))) `t` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `v_normalization_checks`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013  SQL SECURITY INVOKER */
/*!50001 VIEW `v_normalization_checks` AS select 'SCHEDULE_ROOM_REFERENCE' AS `check_name`,count(0) AS `violation_count` from (`section_schedules` `ss` left join `rooms` `r` on((`r`.`id` = `ss`.`room_id`))) where ((`r`.`id` is null) or (`ss`.`room` <> `r`.`code`)) union all select 'EXAM_CATALOG_REFERENCE' AS `EXAM_CATALOG_REFERENCE`,count(0) AS `COUNT(*)` from ((`exam_schedules` `ex` left join `rooms` `r` on((`r`.`id` = `ex`.`room_id`))) left join `exam_types` `t` on((`t`.`id` = `ex`.`exam_type_id`))) where ((`r`.`id` is null) or (`t`.`id` is null) or (`ex`.`room` <> `r`.`code`) or (`ex`.`exam_type` <> `t`.`name`)) union all select 'EXAM_TIME_STATUS' AS `EXAM_TIME_STATUS`,count(0) AS `COUNT(*)` from `exam_schedules` where ((`exam_schedules`.`ends_at` <= `exam_schedules`.`starts_at`) or (cast(`exam_schedules`.`starts_at` as date) <> cast(`exam_schedules`.`ends_at` as date)) or (`exam_schedules`.`status` not in ('DRAFT','PUBLISHED','CANCELLED')) or (`exam_schedules`.`data_origin` not in ('SCHOOL','DEMO'))) union all select 'PRACTICE_STUDENT_PROFILE_MISSING' AS `PRACTICE_STUDENT_PROFILE_MISSING`,count(0) AS `COUNT(*)` from (`students` `s` join `users` `u` on((`u`.`id` = `s`.`user_id`))) where ((`u`.`username` in ('student_demo_001','student_demo_002','student_demo_003','student_demo_004','student_demo_005','student_demo_006')) and ((`s`.`gender` is null) or (`s`.`nationality` is null) or (`s`.`phone` is null) or (`s`.`address` is null) or (`s`.`guardian_full_name` is null) or (`s`.`guardian_phone` is null))) union all select 'SECTION_MISSING_GRADE_SHEET' AS `SECTION_MISSING_GRADE_SHEET`,count(0) AS `COUNT(*)` from (`course_sections` `cs` left join `grade_sheets` `gs` on((`gs`.`section_id` = `cs`.`id`))) where (`gs`.`id` is null) union all select 'ENROLLMENT_DUPLICATE_COURSE' AS `ENROLLMENT_DUPLICATE_COURSE`,count(0) AS `COUNT(*)` from (select `e`.`student_id` AS `student_id`,`cs`.`semester_id` AS `semester_id`,`cs`.`course_id` AS `course_id` from (`enrollments` `e` join `course_sections` `cs` on((`cs`.`id` = `e`.`section_id`))) where (`e`.`status` <> 'CANCELLED') group by `e`.`student_id`,`cs`.`semester_id`,`cs`.`course_id` having (count(0) > 1)) `bad` union all select 'EXAM_COLLISION' AS `EXAM_COLLISION`,count(0) AS `COUNT(*)` from (((`exam_schedules` `a` join `exam_schedules` `b` on(((`a`.`id` < `b`.`id`) and (`a`.`status` <> 'CANCELLED') and (`b`.`status` <> 'CANCELLED') and (`a`.`starts_at` < `b`.`ends_at`) and (`b`.`starts_at` < `a`.`ends_at`)))) join `course_sections` `ca` on((`ca`.`id` = `a`.`section_id`))) join `course_sections` `cb` on((`cb`.`id` = `b`.`section_id`))) where ((`a`.`room_id` = `b`.`room_id`) or (`a`.`section_id` = `b`.`section_id`) or (`ca`.`lecturer_id` = `cb`.`lecturer_id`) or exists(select 1 from (`enrollments` `ea` join `enrollments` `eb` on((`eb`.`student_id` = `ea`.`student_id`))) where ((`ea`.`section_id` = `a`.`section_id`) and (`eb`.`section_id` = `b`.`section_id`) and (`ea`.`status` <> 'CANCELLED') and (`eb`.`status` <> 'CANCELLED')))) union all select 'INVOICE_OVERPAID' AS `INVOICE_OVERPAID`,count(0) AS `COUNT(*)` from `v_invoice_balances` where (`v_invoice_balances`.`paid_amount` > `v_invoice_balances`.`payable_amount`) union all select 'REMITTANCE_ALLOCATION_MISMATCH' AS `REMITTANCE_ALLOCATION_MISMATCH`,count(0) AS `COUNT(*)` from `v_ctsv_remittance_tracking` where ((`v_ctsv_remittance_tracking`.`status` = 'CONFIRMED') and (`v_ctsv_remittance_tracking`.`difference_amount` <> 0)) union all select 'ACTIVE_MAILBOX_WITHOUT_DATE' AS `ACTIVE_MAILBOX_WITHOUT_DATE`,count(0) AS `COUNT(*)` from `student_school_mailboxes` where ((`student_school_mailboxes`.`provisioning_status` = 'ACTIVE') and (`student_school_mailboxes`.`activated_at` is null)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `v_school_admission_decisions`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013  SQL SECURITY INVOKER */
/*!50001 VIEW `v_school_admission_decisions` AS select `a`.`id` AS `application_id`,`a`.`application_code` AS `application_code`,`a`.`status` AS `current_status`,`e`.`id` AS `decision_event_id`,`e`.`event_type` AS `event_type`,`e`.`from_status` AS `from_status`,`e`.`to_status` AS `to_status`,`e`.`actor_user_id` AS `actor_user_id`,`u`.`full_name` AS `reviewer_name`,`e`.`note` AS `note`,`e`.`created_at` AS `created_at`,(case when exists(select 1 from (`user_roles` `ur` join `roles` `r` on((`r`.`id` = `ur`.`role_id`))) where ((`ur`.`user_id` = `e`.`actor_user_id`) and (`r`.`code` = 'PRINCIPAL'))) then 1 else 0 end) AS `reviewer_is_bgh` from ((`admission_review_events` `e` join `admission_applications` `a` on((`a`.`id` = `e`.`application_id`))) join `users` `u` on((`u`.`id` = `e`.`actor_user_id`))) where (`e`.`event_type` in ('SCHOOL_APPROVE','SCHOOL_REJECT')) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `v_school_admission_queue`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013  SQL SECURITY INVOKER */
/*!50001 VIEW `v_school_admission_queue` AS select `a`.`id` AS `application_id`,`a`.`application_code` AS `application_code`,`a`.`status` AS `status`,`a`.`legal_full_name` AS `legal_full_name`,`a`.`personal_email` AS `personal_email`,`a`.`phone` AS `phone`,`a`.`major_id` AS `major_id`,`a`.`period_id` AS `period_id`,`a`.`assigned_ctsv_user_id` AS `assigned_ctsv_user_id`,`a`.`submitted_at` AS `submitted_at`,`p`.`required_count` AS `required_count`,`p`.`verified_required_count` AS `verified_required_count`,`p`.`dossier_check` AS `dossier_check` from (`admission_applications` `a` left join `v_admission_dossier_progress` `p` on((`p`.`application_id` = `a`.`id`))) where (`a`.`status` = 'SENT_TO_SCHOOL') */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `v_school_ctsv_report_register`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013  SQL SECURITY INVOKER */
/*!50001 VIEW `v_school_ctsv_report_register` AS select `r`.`id` AS `report_id`,`r`.`report_code` AS `report_code`,`r`.`semester_id` AS `semester_id`,`r`.`status` AS `status`,`r`.`prepared_by` AS `prepared_by`,`r`.`received_by` AS `received_by`,`r`.`submitted_at` AS `submitted_at`,`r`.`reviewed_at` AS `reviewed_at`,`f`.`total_tuition_due` AS `total_tuition_due`,`f`.`total_paid` AS `total_paid`,`f`.`total_outstanding` AS `total_outstanding`,`f`.`collected_via_ctsv` AS `collected_via_ctsv`,`f`.`legacy_unassigned_paid` AS `legacy_unassigned_paid`,`f`.`remitted_to_school` AS `remitted_to_school`,`f`.`student_issue_count` AS `student_issue_count`,`f`.`unresolved_issue_count` AS `unresolved_issue_count`,`f`.`escalated_issue_count` AS `escalated_issue_count`,(select count(0) from `ctsv_semester_report_reviews` `ev` where (`ev`.`report_id` = `r`.`id`)) AS `review_events` from (`ctsv_semester_reports` `r` join `v_ctsv_semester_finance` `f` on((`f`.`semester_id` = `r`.`semester_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `v_school_tuition_by_semester`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013  SQL SECURITY INVOKER */
/*!50001 VIEW `v_school_tuition_by_semester` AS select `se`.`id` AS `semester_id`,`ay`.`name` AS `academic_year`,`se`.`code` AS `semester_code`,count(`b`.`invoice_id`) AS `invoice_count`,count(distinct `b`.`student_id`) AS `students_billed`,coalesce(sum(`b`.`base_amount`),0.00) AS `base_amount`,coalesce(sum(`b`.`discount_amount`),0.00) AS `discounted_amount`,coalesce(sum(`b`.`debit_amount`),0.00) AS `approved_extra_fees`,coalesce(sum(`b`.`credit_amount`),0.00) AS `approved_credits`,coalesce(sum(`b`.`payable_amount`),0.00) AS `total_receivables`,coalesce(sum(`b`.`paid_amount`),0.00) AS `collected`,coalesce(sum(`b`.`remaining_amount`),0.00) AS `outstanding`,coalesce(sum((case when (`b`.`remaining_amount` > 0) then 1 else 0 end)),0) AS `unpaid_invoice_count` from ((`semesters` `se` join `academic_years` `ay` on((`ay`.`id` = `se`.`academic_year_id`))) left join `v_invoice_balances` `b` on((`b`.`semester_id` = `se`.`id`))) group by `se`.`id`,`ay`.`name`,`se`.`code` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `v_school_tuition_total`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013  SQL SECURITY INVOKER */
/*!50001 VIEW `v_school_tuition_total` AS select 'SCHOOL' AS `scope_code`,coalesce(sum(`v_school_tuition_by_semester`.`total_receivables`),0.00) AS `total_receivables`,coalesce(sum(`v_school_tuition_by_semester`.`collected`),0.00) AS `collected`,coalesce(sum(`v_school_tuition_by_semester`.`outstanding`),0.00) AS `outstanding`,coalesce(sum(`v_school_tuition_by_semester`.`invoice_count`),0) AS `invoice_count`,coalesce(sum(`v_school_tuition_by_semester`.`unpaid_invoice_count`),0) AS `unpaid_invoice_count` from `v_school_tuition_by_semester` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `v_section_registration_counts`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013  SQL SECURITY INVOKER */
/*!50001 VIEW `v_section_registration_counts` AS select `cs`.`id` AS `section_id`,`cs`.`section_code` AS `section_code`,`cs`.`capacity` AS `capacity`,count((case when (`e`.`status` = 'REGISTERED') then 1 end)) AS `registered_count`,(`cs`.`capacity` - count((case when (`e`.`status` = 'REGISTERED') then 1 end))) AS `remaining_seats` from (`course_sections` `cs` left join `enrollments` `e` on((`e`.`section_id` = `cs`.`id`))) group by `cs`.`id`,`cs`.`section_code`,`cs`.`capacity` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `v_student_results`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013  SQL SECURITY INVOKER */
/*!50001 VIEW `v_student_results` AS select `e`.`id` AS `enrollment_id`,`s`.`id` AS `student_id`,`s`.`student_code` AS `student_code`,`cs`.`id` AS `section_id`,`cs`.`section_code` AS `section_code`,`c`.`course_code` AS `course_code`,`c`.`credits` AS `credits`,`gs`.`status` AS `grade_sheet_status`,`g`.`attendance_score` AS `attendance_score`,`g`.`midterm_score` AS `midterm_score`,`g`.`final_score` AS `final_score`,(case when ((`g`.`attendance_score` is not null) and (`g`.`midterm_score` is not null) and (`g`.`final_score` is not null)) then round(((((`g`.`attendance_score` * `cs`.`attendance_weight`) + (`g`.`midterm_score` * `cs`.`midterm_weight`)) + (`g`.`final_score` * `cs`.`final_weight`)) / 100.00),2) else NULL end) AS `total_score` from (((((`enrollments` `e` join `students` `s` on((`s`.`id` = `e`.`student_id`))) join `course_sections` `cs` on((`cs`.`id` = `e`.`section_id`))) join `courses` `c` on((`c`.`id` = `cs`.`course_id`))) left join `grades` `g` on((`g`.`enrollment_id` = `e`.`id`))) left join `grade_sheets` `gs` on((`gs`.`section_id` = `cs`.`id`))) where ((`e`.`status` <> 'CANCELLED') and (`gs`.`status` = 'PUBLISHED')) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `v_student_timetable`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013  SQL SECURITY INVOKER */
/*!50001 VIEW `v_student_timetable` AS select `e`.`id` AS `enrollment_id`,`e`.`student_id` AS `student_id`,`cs`.`id` AS `section_id`,`cs`.`semester_id` AS `semester_id`,`c`.`course_code` AS `course_code`,`c`.`title` AS `course_title`,`cs`.`section_code` AS `section_code`,`sch`.`day_of_week` AS `day_of_week`,`sch`.`starts_at` AS `starts_at`,`sch`.`ends_at` AS `ends_at`,`sch`.`room` AS `room`,`cs`.`lecturer_id` AS `lecturer_id`,`u`.`full_name` AS `lecturer_name`,`e`.`status` AS `enrollment_status` from (((((`enrollments` `e` join `course_sections` `cs` on((`cs`.`id` = `e`.`section_id`))) join `courses` `c` on((`c`.`id` = `cs`.`course_id`))) join `section_schedules` `sch` on((`sch`.`section_id` = `cs`.`id`))) left join `lecturers` `l` on((`l`.`id` = `cs`.`lecturer_id`))) left join `users` `u` on((`u`.`id` = `l`.`user_id`))) where (`e`.`status` in ('REGISTERED','COMPLETED')) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;


INSERT INTO roles(code,description) VALUES
('PRINCIPAL','Ban giám hiệu'),
('TRAINING_OFFICE','Phòng Đào tạo'),
('LECTURER','Giảng viên'),
('STUDENT','Sinh viên'),
('APPLICANT','Ứng viên'),
('CTSV','Công tác sinh viên');
INSERT INTO exam_types(code,name,active) VALUES ('MIDTERM','Giữa kỳ',TRUE),('FINAL','Cuối kỳ',TRUE);
INSERT INTO schema_migrations(version,checksum) VALUES('05_SECURITY_PROFILE.sql','18f2c06dee9e2e3be00f2eba5c84761d76527e8f4477258bfb739cc68a5707a4');
INSERT INTO schema_migrations(version,checksum) VALUES('06_COMPLETE_SEED_LINKS.sql','347658e40dc39a527639030c9cbe6b5db621445e6657a9fa12e713e4ccaa3bea');
INSERT INTO schema_migrations(version,checksum) VALUES('07_EXAM_SCHEDULES.sql','612f1a5f1acddaaa5d91deac7464f75bae97f82206a871bcd74015099e713492');
INSERT INTO schema_migrations(version,checksum) VALUES('08_NORMALIZE_ACADEMIC.sql','0410c5232b8952953e59ad136210061ced3be569e3e4ad71ef887a385802779e');
INSERT INTO schema_migrations(version,checksum) VALUES('09_COMPLETE_DEMO_DATA.sql','78af3c88b51855cc911877b54e3a0e12fdf4d6fe402e0bc57f2bd8eaf4f91dac');
INSERT INTO schema_migrations(version,checksum) VALUES('10_VERIFY_NORMALIZED.sql','16bb3483cfe8975433f8ebfcc012495da0ec7107ee82c26612f00210ccc5ef0d');
INSERT INTO schema_migrations(version,checksum) VALUES('11_MAILBOX_EMAIL_DELIVERY.sql','098a191ab00418aa83440ab9f45f956a5be7df790626524b9b4648c68cf184fd');
INSERT INTO schema_migrations(version,checksum) VALUES('12_PRACTICAL_IDENTITIES.sql','e3e6d6382f5f5ac2eb54c42fae8fa58ad33cb0a53aeeaedb85a482b8a9641d23');
INSERT INTO schema_migrations(version,checksum) VALUES('13_INVOICE_REVIEW_WORKFLOW.sql','75ef9490fb25460a8d7f05cd0e57536a36a14a9dc94af73e9e27abef8b8cb893');
INSERT INTO schema_migrations(version,checksum) VALUES('14_REVIEW_PRACTICE_DATA.sql','4210b75c28d5f5dcbde5772223124e376678f8abdfbe98b26ec08d107fe828c3');
