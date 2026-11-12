-- Draft proposals are separate from issued invoices. Existing money/documents are untouched.
SET NAMES utf8mb4;
CREATE TABLE IF NOT EXISTS invoice_proposals (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    proposal_code VARCHAR(80) NOT NULL UNIQUE,
    student_id BIGINT NOT NULL,
    semester_id BIGINT NOT NULL,
    discount_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    prepared_by BIGINT NOT NULL,
    submitted_at DATETIME NULL,
    reviewed_by BIGINT NULL,
    reviewed_at DATETIME NULL,
    decision_note VARCHAR(700) NULL,
    note VARCHAR(700) NULL,
    invoice_id BIGINT NULL UNIQUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_proposal_student_semester(student_id,semester_id),
    CONSTRAINT fk_proposal_student FOREIGN KEY(student_id) REFERENCES students(id),
    CONSTRAINT fk_proposal_semester FOREIGN KEY(semester_id) REFERENCES semesters(id),
    CONSTRAINT fk_proposal_preparer FOREIGN KEY(prepared_by) REFERENCES users(id),
    CONSTRAINT fk_proposal_reviewer FOREIGN KEY(reviewed_by) REFERENCES users(id),
    CONSTRAINT fk_proposal_invoice FOREIGN KEY(invoice_id) REFERENCES invoices(id),
    CONSTRAINT chk_proposal_discount CHECK(discount_amount>=0),
    CONSTRAINT chk_proposal_status CHECK(status IN ('DRAFT','SUBMITTED','APPROVED','RETURNED','REJECTED','ISSUED')),
    CONSTRAINT chk_proposal_submission CHECK(status='DRAFT' OR submitted_at IS NOT NULL),
    CONSTRAINT chk_proposal_decision CHECK(status NOT IN ('APPROVED','RETURNED','REJECTED','ISSUED') OR (reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL)),
    CONSTRAINT chk_proposal_issued CHECK((status='ISSUED' AND invoice_id IS NOT NULL) OR (status<>'ISSUED' AND invoice_id IS NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS invoice_proposal_items (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    proposal_id BIGINT NOT NULL,
    enrollment_id BIGINT NOT NULL,
    credits_at_proposal SMALLINT NOT NULL,
    unit_price_at_proposal DECIMAL(14,2) NOT NULL,
    UNIQUE KEY uq_proposal_item(proposal_id,enrollment_id),
    CONSTRAINT fk_proposal_item_header FOREIGN KEY(proposal_id) REFERENCES invoice_proposals(id),
    CONSTRAINT fk_proposal_item_enrollment FOREIGN KEY(enrollment_id) REFERENCES enrollments(id),
    CONSTRAINT chk_proposal_item_credit CHECK(credits_at_proposal BETWEEN 1 AND 15),
    CONSTRAINT chk_proposal_item_price CHECK(unit_price_at_proposal>=0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS invoice_proposal_reviews (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    proposal_id BIGINT NOT NULL,
    actor_user_id BIGINT NOT NULL,
    action VARCHAR(20) NOT NULL,
    from_status VARCHAR(20) NULL,
    to_status VARCHAR(20) NOT NULL,
    note VARCHAR(700) NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_proposal_review_header FOREIGN KEY(proposal_id) REFERENCES invoice_proposals(id),
    CONSTRAINT fk_proposal_review_actor FOREIGN KEY(actor_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
