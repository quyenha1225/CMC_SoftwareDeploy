-- Notify the student's personal email when a real school mailbox is activated.
-- No account activation, email send, fee change or seed rewrite occurs here.
SET NAMES utf8mb4;
DROP PROCEDURE IF EXISTS sms_v6_mailbox_delivery;
DELIMITER $$
CREATE PROCEDURE sms_v6_mailbox_delivery()
BEGIN
    IF NOT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='outbound_emails' AND column_name='mailbox_id') THEN
        ALTER TABLE outbound_emails ADD COLUMN mailbox_id BIGINT NULL;
    END IF;
    IF NOT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='outbound_emails' AND column_name='body_text') THEN
        ALTER TABLE outbound_emails ADD COLUMN body_text TEXT NULL;
    END IF;
    IF NOT EXISTS(SELECT 1 FROM information_schema.table_constraints WHERE constraint_schema=DATABASE() AND table_name='outbound_emails' AND constraint_name='fk_outbound_mailbox') THEN
        ALTER TABLE outbound_emails ADD CONSTRAINT fk_outbound_mailbox FOREIGN KEY(mailbox_id) REFERENCES student_school_mailboxes(id);
    END IF;
    IF EXISTS(SELECT 1 FROM information_schema.check_constraints WHERE constraint_schema=DATABASE() AND constraint_name='chk_outbound_email_one_origin' AND check_clause NOT LIKE '%mailbox_id%') THEN
        ALTER TABLE outbound_emails DROP CHECK chk_outbound_email_one_origin;
    END IF;
    IF NOT EXISTS(SELECT 1 FROM information_schema.table_constraints WHERE constraint_schema=DATABASE() AND table_name='outbound_emails' AND constraint_name='chk_outbound_email_one_origin') THEN
        ALTER TABLE outbound_emails ADD CONSTRAINT chk_outbound_email_one_origin CHECK(
            (admission_application_id IS NOT NULL)+(semester_report_id IS NOT NULL)+
            (student_request_id IS NOT NULL)+(mailbox_id IS NOT NULL)=1
        );
    END IF;
END$$
DELIMITER ;
CALL sms_v6_mailbox_delivery();
DROP PROCEDURE sms_v6_mailbox_delivery;
