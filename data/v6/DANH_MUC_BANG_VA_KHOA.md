# Danh mục 47 bảng, khóa và quan hệ của SMS V6

Đây là danh mục được sinh từ `01_SCHEMA_ALL.sql`. Các cột bổ sung qua ALTER trong V4 cũng được liệt kê.

## Hệ thống & thông báo

### `users`

- Khóa chính: `id`
- UNIQUE: (`username`), (`email`)
- Khóa ngoại: Không
- Cột: `id`, `username`, `email`, `password_hash`, `full_name`, `enabled`, `created_at`

### `roles`

- Khóa chính: `id`
- UNIQUE: (`code`)
- Khóa ngoại: Không
- Cột: `id`, `code`, `description`

### `user_roles`

- Khóa chính: `user_id`, `role_id`
- Khóa ngoại: `user_id` → `users.id`; `role_id` → `roles.id`
- Cột: `user_id`, `role_id`

### `audit_logs`

- Khóa chính: `id`
- UNIQUE: (`event_key`)
- Khóa ngoại: `actor_user_id` → `users.id`
- Cột: `id`, `actor_user_id`, `action`, `entity_type`, `entity_id`, `detail_json`, `event_key`, `created_at`

### `notifications`

- Khóa chính: `id`
- UNIQUE: (`notification_code`)
- Khóa ngoại: `created_by` → `users.id`
- Cột: `id`, `notification_code`, `created_by`, `title`, `body`, `created_at`

### `notification_recipients`

- Khóa chính: `notification_id`, `user_id`
- Khóa ngoại: `notification_id` → `notifications.id`; `user_id` → `users.id`
- Cột: `notification_id`, `user_id`, `read_at`

### `outbound_emails`

- Khóa chính: `id`
- UNIQUE: (`event_key`)
- Khóa ngoại: `admission_application_id` → `admission_applications.id`; `semester_report_id` → `ctsv_semester_reports.id`; `student_request_id` → `student_requests.id`
- Cột: `id`, `event_key`, `admission_application_id`, `semester_report_id`, `student_request_id`, `template_code`, `recipient_email`, `subject`, `delivery_status`, `attempt_count`, `last_error`, `queued_at`, `sent_at`

### `email_delivery_attempts`

- Khóa chính: `id`
- UNIQUE: (`outbound_email_id`, `attempt_no`), (`provider_message_id`)
- Khóa ngoại: `outbound_email_id` → `outbound_emails.id`
- Cột: `id`, `outbound_email_id`, `attempt_no`, `result`, `provider_message_id`, `error_code`, `error_message`, `attempted_at`

## Hồ sơ và duyệt nhập học

### `admission_periods`

- Khóa chính: `id`
- UNIQUE: (`code`)
- Khóa ngoại: `cohort_id` → `cohorts.id`
- Cột: `id`, `code`, `title`, `cohort_id`, `opens_at`, `closes_at`, `status`

### `admission_applications`

- Khóa chính: `id`
- UNIQUE: (`application_code`), (`applicant_user_id`, `period_id`), (`student_id`)
- Khóa ngoại: `applicant_user_id` → `users.id`; `period_id` → `admission_periods.id`; `major_id` → `majors.id`; `assigned_ctsv_user_id` → `users.id`; `student_id` → `students.id`
- Cột: `id`, `application_code`, `applicant_user_id`, `period_id`, `major_id`, `phone`, `address`, `date_of_birth`, `status`, `assigned_ctsv_user_id`, `student_id`, `submitted_at`, `changed_at`, `legal_full_name`, `personal_email`, `gender`, `place_of_birth`, `hometown`, `permanent_address`, `current_address`, `nationality`, `guardian_full_name`, `guardian_phone`

### `admission_document_requirements`

- Khóa chính: `period_id`, `document_type`
- Khóa ngoại: `period_id` → `admission_periods.id`
- Cột: `period_id`, `document_type`, `label`, `is_required`

### `admission_documents`

- Khóa chính: `id`
- UNIQUE: (`application_id`, `document_type`, `revision_no`), (`storage_key`)
- Khóa ngoại: `application_id` → `admission_applications.id`; `checked_by` → `users.id`
- Cột: `id`, `application_id`, `document_type`, `revision_no`, `file_name`, `storage_key`, `mime_type`, `size_bytes`, `sha256`, `status`, `checked_by`, `checked_at`, `rejection_reason`, `uploaded_at`

### `admission_review_events`

- Khóa chính: `id`
- UNIQUE: (`event_key`)
- Khóa ngoại: `application_id` → `admission_applications.id`; `actor_user_id` → `users.id`
- Cột: `id`, `application_id`, `actor_user_id`, `event_type`, `from_status`, `to_status`, `note`, `event_key`, `created_at`

### `admission_identity_records`

- Khóa chính: `id`
- UNIQUE: (`application_id`)
- Khóa ngoại: `application_id` → `admission_applications.id`; `verified_by` → `users.id`
- Cột: `id`, `application_id`, `identity_type`, `identity_last4`, `identity_number_encrypted`, `identity_number_hmac`, `issued_on`, `expires_on`, `issued_by`, `verified_at`, `verified_by`

### `admission_high_school_records`

- Khóa chính: `id`
- UNIQUE: (`application_id`)
- Khóa ngoại: `application_id` → `admission_applications.id`
- Cột: `id`, `application_id`, `school_name`, `school_province`, `graduation_year`, `graduation_status`, `transcript_average`

### `admission_high_school_scores`

- Khóa chính: `id`
- UNIQUE: (`school_record_id`, `grade_level`, `subject_code`)
- Khóa ngoại: `school_record_id` → `admission_high_school_records.id`
- Cột: `id`, `school_record_id`, `grade_level`, `subject_code`, `average_score`

### `student_school_mailboxes`

- Khóa chính: `id`
- UNIQUE: (`student_id`), (`school_email`)
- Khóa ngoại: `student_id` → `students.id`; `provisioned_by` → `users.id`
- Cột: `id`, `student_id`, `school_email`, `provisioning_status`, `reserved_at`, `activated_at`, `provisioned_by`, `note`

## Đào tạo / Lịch / Điểm

### `faculties`

- Khóa chính: `id`
- UNIQUE: (`code`)
- Khóa ngoại: Không
- Cột: `id`, `code`, `name`

### `majors`

- Khóa chính: `id`
- UNIQUE: (`code`), (`faculty_id`, `name`)
- Khóa ngoại: `faculty_id` → `faculties.id`
- Cột: `id`, `faculty_id`, `code`, `name`

### `cohorts`

- Khóa chính: `id`
- UNIQUE: (`code`)
- Khóa ngoại: Không
- Cột: `id`, `code`, `start_year`, `end_year`

### `academic_classes`

- Khóa chính: `id`
- UNIQUE: (`code`)
- Khóa ngoại: `major_id` → `majors.id`; `cohort_id` → `cohorts.id`
- Cột: `id`, `major_id`, `cohort_id`, `code`, `name`

### `students`

- Khóa chính: `id`
- UNIQUE: (`user_id`), (`student_code`)
- Khóa ngoại: `user_id` → `users.id`; `class_id` → `academic_classes.id`
- Cột: `id`, `user_id`, `student_code`, `class_id`, `date_of_birth`, `phone`, `address`, `status`, `enrolled_on`, `gender`, `place_of_birth`, `hometown`, `permanent_address`, `current_address`, `nationality`, `guardian_full_name`, `guardian_phone`

### `lecturers`

- Khóa chính: `id`
- UNIQUE: (`user_id`), (`lecturer_code`)
- Khóa ngoại: `user_id` → `users.id`; `faculty_id` → `faculties.id`
- Cột: `id`, `user_id`, `faculty_id`, `lecturer_code`

### `academic_years`

- Khóa chính: `id`
- UNIQUE: (`name`)
- Khóa ngoại: Không
- Cột: `id`, `name`, `starts_on`, `ends_on`

### `semesters`

- Khóa chính: `id`
- UNIQUE: (`academic_year_id`, `code`)
- Khóa ngoại: `academic_year_id` → `academic_years.id`
- Cột: `id`, `academic_year_id`, `code`, `starts_on`, `ends_on`, `registration_from`, `registration_to`, `status`

### `courses`

- Khóa chính: `id`
- UNIQUE: (`course_code`)
- Khóa ngoại: Không
- Cột: `id`, `course_code`, `title`, `credits`, `active`

### `curricula`

- Khóa chính: `id`
- UNIQUE: (`major_id`, `cohort_id`)
- Khóa ngoại: `major_id` → `majors.id`; `cohort_id` → `cohorts.id`
- Cột: `id`, `major_id`, `cohort_id`, `title`

### `curriculum_courses`

- Khóa chính: `curriculum_id`, `course_id`
- Khóa ngoại: `curriculum_id` → `curricula.id`; `course_id` → `courses.id`
- Cột: `curriculum_id`, `course_id`, `suggested_semester`, `required_course`

### `course_sections`

- Khóa chính: `id`
- UNIQUE: (`semester_id`, `section_code`)
- Khóa ngoại: `semester_id` → `semesters.id`; `course_id` → `courses.id`; `lecturer_id` → `lecturers.id`
- Cột: `id`, `semester_id`, `course_id`, `lecturer_id`, `section_code`, `capacity`, `attendance_weight`, `midterm_weight`, `final_weight`, `is_open`

### `section_schedules`

- Khóa chính: `id`
- UNIQUE: (`section_id`, `day_of_week`, `starts_at`, `ends_at`)
- Khóa ngoại: `section_id` → `course_sections.id`
- Cột: `id`, `section_id`, `day_of_week`, `starts_at`, `ends_at`, `room`

### `enrollments`

- Khóa chính: `id`
- UNIQUE: (`student_id`, `section_id`)
- Khóa ngoại: `student_id` → `students.id`; `section_id` → `course_sections.id`
- Cột: `id`, `student_id`, `section_id`, `status`, `registered_at`

### `grade_sheets`

- Khóa chính: `id`
- UNIQUE: (`section_id`)
- Khóa ngoại: `section_id` → `course_sections.id`
- Cột: `id`, `section_id`, `status`, `published_at`, `version_no`

### `grades`

- Khóa chính: `id`
- UNIQUE: (`enrollment_id`)
- Khóa ngoại: `enrollment_id` → `enrollments.id`
- Cột: `id`, `enrollment_id`, `attendance_score`, `midterm_score`, `final_score`, `remark`, `updated_at`

### `grade_reviews`

- Khóa chính: `id`
- UNIQUE: (`event_key`)
- Khóa ngoại: `sheet_id` → `grade_sheets.id`; `actor_user_id` → `users.id`
- Cột: `id`, `sheet_id`, `actor_user_id`, `action`, `note`, `created_at`, `event_key`

## Học phí và CTSV

### `tuition_rates`

- Khóa chính: `id`
- UNIQUE: (`semester_id`)
- Khóa ngoại: `semester_id` → `semesters.id`
- Cột: `id`, `semester_id`, `price_per_credit`

### `invoices`

- Khóa chính: `id`
- UNIQUE: (`student_id`, `semester_id`)
- Khóa ngoại: `student_id` → `students.id`; `semester_id` → `semesters.id`
- Cột: `id`, `student_id`, `semester_id`, `discount_amount`, `issued_at`

### `invoice_items`

- Khóa chính: `id`
- UNIQUE: (`enrollment_id`)
- Khóa ngoại: `invoice_id` → `invoices.id`; `enrollment_id` → `enrollments.id`
- Cột: `id`, `invoice_id`, `enrollment_id`, `credits_at_issue`, `unit_price_at_issue`, `amount`

### `payments`

- Khóa chính: `id`
- UNIQUE: (`reference_no`)
- Khóa ngoại: `invoice_id` → `invoices.id`; `recorded_by` → `users.id`; `fund_id` → `ctsv_funds.id`
- Cột: `id`, `invoice_id`, `recorded_by`, `amount`, `paid_at`, `reference_no`, `note`, `fund_id`

### `ctsv_funds`

- Khóa chính: `id`
- UNIQUE: (`code`)
- Khóa ngoại: Không
- Cột: `id`, `code`, `name`, `channel`, `active`

### `ctsv_remittances`

- Khóa chính: `id`
- UNIQUE: (`remittance_code`), (`external_reference`)
- Khóa ngoại: `semester_id` → `semesters.id`; `fund_id` → `ctsv_funds.id`; `prepared_by` → `users.id`; `reviewed_by` → `users.id`
- Cột: `id`, `remittance_code`, `semester_id`, `fund_id`, `amount`, `status`, `prepared_by`, `reviewed_by`, `remitted_at`, `reviewed_at`, `external_reference`, `note`

### `ctsv_remittance_allocations`

- Khóa chính: `remittance_id`, `payment_id`
- Khóa ngoại: `remittance_id` → `ctsv_remittances.id`; `payment_id` → `payments.id`
- Cột: `remittance_id`, `payment_id`, `allocated_amount`

### `ctsv_semester_reports`

- Khóa chính: `id`
- UNIQUE: (`report_code`), (`semester_id`)
- Khóa ngoại: `semester_id` → `semesters.id`; `prepared_by` → `users.id`; `received_by` → `users.id`
- Cột: `id`, `report_code`, `semester_id`, `prepared_by`, `status`, `received_by`, `submitted_at`, `reviewed_at`, `note`

### `ctsv_semester_report_reviews`

- Khóa chính: `id`
- UNIQUE: (`event_key`)
- Khóa ngoại: `report_id` → `ctsv_semester_reports.id`; `actor_user_id` → `users.id`
- Cột: `id`, `report_id`, `actor_user_id`, `action`, `note`, `event_key`, `created_at`

### `tuition_adjustments`

- Khóa chính: `id`
- UNIQUE: (`adjustment_code`)
- Khóa ngoại: `invoice_id` → `invoices.id`; `requested_by` → `users.id`; `approved_by` → `users.id`
- Cột: `id`, `adjustment_code`, `invoice_id`, `kind`, `amount`, `reason`, `status`, `requested_by`, `approved_by`, `created_at`, `decided_at`

### `student_requests`

- Khóa chính: `id`
- UNIQUE: (`request_code`)
- Khóa ngoại: `student_id` → `students.id`; `handled_by` → `users.id`
- Cột: `id`, `request_code`, `student_id`, `request_type`, `content`, `status`, `handled_by`, `response`, `created_at`, `handled_at`

### `student_request_attachments`

- Khóa chính: `id`
- UNIQUE: (`storage_key`)
- Khóa ngoại: `request_id` → `student_requests.id`; `uploaded_by` → `users.id`
- Cột: `id`, `request_id`, `uploaded_by`, `file_name`, `storage_key`, `mime_type`, `size_bytes`, `uploaded_at`

### `student_request_review_events`

- Khóa chính: `id`
- UNIQUE: (`event_key`)
- Khóa ngoại: `request_id` → `student_requests.id`; `reviewer_user_id` → `users.id`; `school_recipient_user_id` → `users.id`
- Cột: `id`, `request_id`, `reviewer_user_id`, `action`, `note`, `event_key`, `created_at`, `school_recipient_user_id`

## Tất cả quan hệ FK (78)

- `academic_classes.cohort_id` → `cohorts.id` (`fk_academic_classes_cohort`)
- `academic_classes.major_id` → `majors.id` (`fk_academic_classes_major`)
- `admission_applications.applicant_user_id` → `users.id` (`fk_admission_app_user`)
- `admission_applications.assigned_ctsv_user_id` → `users.id` (`fk_admission_app_ctsv`)
- `admission_applications.major_id` → `majors.id` (`fk_admission_app_major`)
- `admission_applications.period_id` → `admission_periods.id` (`fk_admission_app_period`)
- `admission_applications.student_id` → `students.id` (`fk_admission_app_student`)
- `admission_document_requirements.period_id` → `admission_periods.id` (`fk_admission_requirement_period`)
- `admission_documents.application_id` → `admission_applications.id` (`fk_admission_doc_app`)
- `admission_documents.checked_by` → `users.id` (`fk_admission_doc_checker`)
- `admission_high_school_records.application_id` → `admission_applications.id` (`fk_school_records_application`)
- `admission_high_school_scores.school_record_id` → `admission_high_school_records.id` (`fk_school_score_record`)
- `admission_identity_records.application_id` → `admission_applications.id` (`fk_identity_application`)
- `admission_identity_records.verified_by` → `users.id` (`fk_identity_verified_by`)
- `admission_periods.cohort_id` → `cohorts.id` (`fk_admission_period_cohort`)
- `admission_review_events.actor_user_id` → `users.id` (`fk_admission_review_user`)
- `admission_review_events.application_id` → `admission_applications.id` (`fk_admission_review_application`)
- `audit_logs.actor_user_id` → `users.id` (`fk_audit_logs_actor`)
- `course_sections.course_id` → `courses.id` (`fk_sections_course`)
- `course_sections.lecturer_id` → `lecturers.id` (`fk_sections_lecturer`)
- `course_sections.semester_id` → `semesters.id` (`fk_sections_semester`)
- `ctsv_remittance_allocations.payment_id` → `payments.id` (`fk_ctsv_allocation_payment`)
- `ctsv_remittance_allocations.remittance_id` → `ctsv_remittances.id` (`fk_ctsv_allocation_remittance`)
- `ctsv_remittances.fund_id` → `ctsv_funds.id` (`fk_ctsv_remittance_fund`)
- `ctsv_remittances.prepared_by` → `users.id` (`fk_ctsv_remittance_prepared`)
- `ctsv_remittances.reviewed_by` → `users.id` (`fk_ctsv_remittance_reviewed`)
- `ctsv_remittances.semester_id` → `semesters.id` (`fk_ctsv_remittance_sem`)
- `ctsv_semester_report_reviews.actor_user_id` → `users.id` (`fk_ctsv_report_review_actor`)
- `ctsv_semester_report_reviews.report_id` → `ctsv_semester_reports.id` (`fk_ctsv_report_review_report`)
- `ctsv_semester_reports.prepared_by` → `users.id` (`fk_ctsv_report_prepared`)
- `ctsv_semester_reports.received_by` → `users.id` (`fk_ctsv_report_received`)
- `ctsv_semester_reports.semester_id` → `semesters.id` (`fk_ctsv_report_sem`)
- `curricula.cohort_id` → `cohorts.id` (`fk_curricula_cohort`)
- `curricula.major_id` → `majors.id` (`fk_curricula_major`)
- `curriculum_courses.course_id` → `courses.id` (`fk_curriculum_courses_course`)
- `curriculum_courses.curriculum_id` → `curricula.id` (`fk_curriculum_courses_curriculum`)
- `email_delivery_attempts.outbound_email_id` → `outbound_emails.id` (`fk_email_delivery_outbound`)
- `enrollments.section_id` → `course_sections.id` (`fk_enrollments_section`)
- `enrollments.student_id` → `students.id` (`fk_enrollments_student`)
- `grade_reviews.actor_user_id` → `users.id` (`fk_grade_reviews_user`)
- `grade_reviews.sheet_id` → `grade_sheets.id` (`fk_grade_reviews_sheet`)
- `grade_sheets.section_id` → `course_sections.id` (`fk_grade_sheets_section`)
- `grades.enrollment_id` → `enrollments.id` (`fk_grades_enrollment`)
- `invoice_items.enrollment_id` → `enrollments.id` (`fk_invoice_items_enrollment`)
- `invoice_items.invoice_id` → `invoices.id` (`fk_invoice_items_invoice`)
- `invoices.semester_id` → `semesters.id` (`fk_invoices_semester`)
- `invoices.student_id` → `students.id` (`fk_invoices_student`)
- `lecturers.faculty_id` → `faculties.id` (`fk_lecturers_faculty`)
- `lecturers.user_id` → `users.id` (`fk_lecturers_user`)
- `majors.faculty_id` → `faculties.id` (`fk_majors_faculty`)
- `notification_recipients.notification_id` → `notifications.id` (`fk_notification_recipients_notification`)
- `notification_recipients.user_id` → `users.id` (`fk_notification_recipients_user`)
- `notifications.created_by` → `users.id` (`fk_notifications_created_by`)
- `outbound_emails.admission_application_id` → `admission_applications.id` (`fk_email_admission`)
- `outbound_emails.semester_report_id` → `ctsv_semester_reports.id` (`fk_email_report`)
- `outbound_emails.student_request_id` → `student_requests.id` (`fk_email_request`)
- `payments.fund_id` → `ctsv_funds.id` (`fk_payments_ctsv_fund`)
- `payments.invoice_id` → `invoices.id` (`fk_payments_invoice`)
- `payments.recorded_by` → `users.id` (`fk_payments_recorded_by`)
- `section_schedules.section_id` → `course_sections.id` (`fk_section_schedules_section`)
- `semesters.academic_year_id` → `academic_years.id` (`fk_semesters_year`)
- `student_request_attachments.request_id` → `student_requests.id` (`fk_student_request_file_request`)
- `student_request_attachments.uploaded_by` → `users.id` (`fk_student_request_file_uploader`)
- `student_request_review_events.request_id` → `student_requests.id` (`fk_student_request_review_request`)
- `student_request_review_events.reviewer_user_id` → `users.id` (`fk_student_request_review_reviewer`)
- `student_request_review_events.school_recipient_user_id` → `users.id` (`fk_ctsv_request_escalation_recipient`)
- `student_requests.handled_by` → `users.id` (`fk_student_requests_handler`)
- `student_requests.student_id` → `students.id` (`fk_student_requests_student`)
- `student_school_mailboxes.provisioned_by` → `users.id` (`fk_student_mailbox_provisioned_by`)
- `student_school_mailboxes.student_id` → `students.id` (`fk_student_mailbox_student`)
- `students.class_id` → `academic_classes.id` (`fk_students_class`)
- `students.user_id` → `users.id` (`fk_students_user`)
- `tuition_adjustments.approved_by` → `users.id` (`fk_tuition_adjustment_approver`)
- `tuition_adjustments.invoice_id` → `invoices.id` (`fk_tuition_adjustment_invoice`)
- `tuition_adjustments.requested_by` → `users.id` (`fk_tuition_adjustment_requester`)
- `tuition_rates.semester_id` → `semesters.id` (`fk_tuition_rates_semester`)
- `user_roles.role_id` → `roles.id` (`fk_user_roles_role`)
- `user_roles.user_id` → `users.id` (`fk_user_roles_user`)
