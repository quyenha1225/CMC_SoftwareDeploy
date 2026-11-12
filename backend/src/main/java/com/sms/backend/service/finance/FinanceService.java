package com.sms.backend.service.finance;

import static com.sms.backend.repository.Db.*;

import com.sms.backend.repository.Db;
import com.sms.backend.security.Actor;
import com.sms.backend.service.admission.Admissions;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.*;
import java.util.*;

/** Invoice/fund locks serialize writers; READ_COMMITTED refreshes sums after waiting. */
@Service
public class FinanceService {
    private final Db db;
    private final Actor actor;
    private final InvoiceProposals proposals;

    public FinanceService(Db db, Actor actor, InvoiceProposals proposals) {
        this.db = db;
        this.actor = actor;
        this.proposals = proposals;
    }

    @Transactional(isolation = Isolation.READ_COMMITTED)
    public long issue(long studentId, long semesterId) {
        var u = actor.current();
        u.require("CTSV");
        db.one("SELECT id FROM students WHERE id=? FOR UPDATE", studentId);
        if (db.number(
                        "SELECT COUNT(*) FROM invoices WHERE student_id=? AND semester_id=?",
                        studentId,
                        semesterId)
                > 0) throw error(409, "Hóa đơn học kỳ đã tồn tại.");
        var proposal = proposals.approvedForIssue(studentId, semesterId);
        long id =
                db.insert(
                        "invoices",
                        map(
                                "student_id",
                                studentId,
                                "semester_id",
                                semesterId,
                                "discount_amount",
                                proposal.get("discount_amount")));
        for (var item : (List<Map<String, Object>>) proposal.get("items")) {
            db.insert(
                    "invoice_items",
                    map(
                            "invoice_id",
                            id,
                            "enrollment_id",
                            item.get("enrollment_id"),
                            "credits_at_issue",
                            item.get("credits_at_proposal"),
                            "unit_price_at_issue",
                            item.get("unit_price_at_proposal")));
        }
        proposals.issued(Db.id(proposal.get("id")), id);
        actor.audit(u, "ISSUE_INVOICE", "invoices", id);
        return id;
    }

    @Transactional(isolation = Isolation.READ_COMMITTED)
    public long payment(Map<String, Object> input) {
        var u = actor.current();
        u.require("CTSV");
        long invoice = Db.id(input.get("invoice_id")), fund = Db.id(input.get("fund_id"));
        lockInvoice(invoice);
        db.one("SELECT id FROM ctsv_funds WHERE id=? AND active=TRUE FOR UPDATE", fund);
        BigDecimal amount = amount(input.get("amount"));
        var balance =
                db.one(
                        "SELECT remaining_amount FROM v_invoice_balances WHERE invoice_id=?",
                        invoice);
        if (amount.compareTo(new BigDecimal(balance.get("remaining_amount").toString())) > 0)
            throw error(409, "Khoản thu vượt công nợ.");
        String reference = text(input, "reference_no", 100);
        long id =
                db.insert(
                        "payments",
                        map(
                                "invoice_id",
                                invoice,
                                "fund_id",
                                fund,
                                "recorded_by",
                                u.id(),
                                "amount",
                                amount,
                                "reference_no",
                                reference,
                                "paid_at",
                                LocalDateTime.now(),
                                "note",
                                Objects.toString(input.get("note"), "")));
        actor.audit(u, "RECORD_PAYMENT", "payments", id);
        return id;
    }

    @Transactional(isolation = Isolation.READ_COMMITTED)
    public long adjustment(Map<String, Object> input) {
        var u = actor.current();
        u.require("CTSV");
        long invoice = Db.id(input.get("invoice_id"));
        lockInvoice(invoice);
        String kind = text(input, "kind", 10);
        if (!Set.of("DEBIT", "CREDIT").contains(kind))
            throw error(400, "Loại điều chỉnh không hợp lệ.");
        long id =
                db.insert(
                        "tuition_adjustments",
                        map(
                                "adjustment_code",
                                "ADJ-" + UUID.randomUUID(),
                                "invoice_id",
                                invoice,
                                "kind",
                                kind,
                                "amount",
                                amount(input.get("amount")),
                                "reason",
                                text(input, "reason", 700),
                                "requested_by",
                                u.id(),
                                "status",
                                "REQUESTED"));
        actor.audit(u, "REQUEST_ADJUSTMENT", "tuition_adjustments", id);
        return id;
    }

    @Transactional(isolation = Isolation.READ_COMMITTED)
    public void decideAdjustment(long id, boolean approve) {
        var u = actor.current();
        u.require("PRINCIPAL");
        var adjustment = db.one("SELECT * FROM tuition_adjustments WHERE id=? FOR UPDATE", id);
        Admissions.expect(adjustment.get("status").toString(), "REQUESTED");
        lockInvoice(Db.id(adjustment.get("invoice_id")));
        if (approve && "CREDIT".equals(adjustment.get("kind"))) {
            BigDecimal debt =
                    new BigDecimal(
                            db.one(
                                            "SELECT remaining_amount FROM v_invoice_balances WHERE"
                                                    + " invoice_id=?",
                                            adjustment.get("invoice_id"))
                                    .get("remaining_amount")
                                    .toString());
            if (amount(adjustment.get("amount")).compareTo(debt) > 0)
                throw error(409, "Giảm trừ vượt phần còn nợ; cần quy trình hoàn tiền riêng.");
        }
        db.run(
                "UPDATE tuition_adjustments SET status=?,approved_by=?,decided_at=CURRENT_TIMESTAMP"
                        + " WHERE id=?",
                approve ? "APPROVED" : "REJECTED",
                u.id(),
                id);
        actor.audit(u, "DECIDE_ADJUSTMENT", "tuition_adjustments", id);
    }

    @Transactional(isolation = Isolation.READ_COMMITTED)
    public long remittance(Map<String, Object> input) {
        var u = actor.current();
        u.require("CTSV");
        long fund = Db.id(input.get("fund_id")), semester = Db.id(input.get("semester_id"));
        db.one("SELECT id FROM ctsv_funds WHERE id=? AND active=TRUE FOR UPDATE", fund);
        var allocations = allocationInput(input.get("allocations"));
        BigDecimal total = BigDecimal.ZERO;
        var seen = new HashSet<Long>();
        for (var allocation : allocations) {
            long payment = Db.id(allocation.get("payment_id"));
            if (!seen.add(payment)) throw error(400, "Chứng từ bị lặp.");
            BigDecimal value = amount(allocation.get("allocated_amount"));
            var row =
                    db.one(
                            "SELECT p.*,i.semester_id FROM payments p JOIN invoices i ON"
                                    + " i.id=p.invoice_id WHERE p.id=? FOR UPDATE",
                            payment);
            if (!Objects.equals(row.get("fund_id") == null ? null : Db.id(row.get("fund_id")), fund)
                    || Db.id(row.get("semester_id")) != semester)
                throw error(400, "Chứng từ không thuộc quỹ/học kỳ đã chọn.");
            BigDecimal reserved =
                    db.jdbc.queryForObject(
                            "SELECT COALESCE(SUM(a.allocated_amount),0) FROM"
                                    + " ctsv_remittance_allocations a JOIN ctsv_remittances r ON"
                                    + " r.id=a.remittance_id WHERE a.payment_id=? AND r.status IN"
                                    + " ('SUBMITTED','CONFIRMED')",
                            BigDecimal.class,
                            payment);
            if (value.add(reserved).compareTo(new BigDecimal(row.get("amount").toString())) > 0)
                throw error(409, "Phân bổ vượt số tiền chứng từ còn lại.");
            total = total.add(value);
        }
        if (total.signum() <= 0) throw error(400, "Chọn ít nhất một khoản phân bổ.");
        long id =
                db.insert(
                        "ctsv_remittances",
                        map(
                                "remittance_code",
                                "BG-" + UUID.randomUUID(),
                                "fund_id",
                                fund,
                                "semester_id",
                                semester,
                                "amount",
                                total,
                                "status",
                                "SUBMITTED",
                                "prepared_by",
                                u.id(),
                                "note",
                                Objects.toString(input.get("note"), "")));
        for (var allocation : allocations)
            db.run(
                    "INSERT INTO"
                        + " ctsv_remittance_allocations(remittance_id,payment_id,allocated_amount)"
                        + " VALUES(?,?,?)",
                    id,
                    Db.id(allocation.get("payment_id")),
                    amount(allocation.get("allocated_amount")));
        actor.audit(u, "SUBMIT_REMITTANCE", "ctsv_remittances", id);
        return id;
    }

    @SuppressWarnings("unchecked")
    private List<Map<String, Object>> allocationInput(Object input) {
        if (!(input instanceof List<?> list)
                || list.isEmpty()
                || list.size() > 100
                || list.stream().anyMatch(item -> !(item instanceof Map)))
            throw error(400, "Danh sách phân bổ không hợp lệ.");
        return (List<Map<String, Object>>) input;
    }

    @Transactional(isolation = Isolation.READ_COMMITTED)
    public void decideRemittance(long id, boolean confirm, String note) {
        var u = actor.current();
        u.require("PRINCIPAL");
        var row = db.one("SELECT * FROM ctsv_remittances WHERE id=? FOR UPDATE", id);
        Admissions.expect(row.get("status").toString(), "SUBMITTED");
        db.one("SELECT id FROM ctsv_funds WHERE id=? FOR UPDATE", row.get("fund_id"));
        if (Db.id(row.get("prepared_by")) == u.id())
            throw error(403, "Người lập không tự xác nhận bàn giao.");
        if (!confirm && (note == null || note.isBlank())) throw error(400, "Nhập lý do từ chối.");
        db.run(
                "UPDATE ctsv_remittances SET"
                    + " status=?,reviewed_by=?,reviewed_at=CURRENT_TIMESTAMP,remitted_at=?,note=?"
                    + " WHERE id=?",
                confirm ? "CONFIRMED" : "REJECTED",
                u.id(),
                confirm ? LocalDateTime.now() : null,
                note,
                id);
        actor.audit(
                u, confirm ? "CONFIRM_REMITTANCE" : "REJECT_REMITTANCE", "ctsv_remittances", id);
    }

    @Transactional(isolation = Isolation.READ_COMMITTED)
    public long report(long semester) {
        var u = actor.current();
        u.require("CTSV");
        var term = db.one("SELECT id,ends_on FROM semesters WHERE id=? FOR UPDATE", semester);
        if (LocalDate.parse(term.get("ends_on").toString()).isAfter(LocalDate.now()))
            throw error(409, "Chỉ lập báo cáo cuối kỳ sau khi học kỳ kết thúc.");
        var old =
                db.rows(
                        "SELECT * FROM ctsv_semester_reports WHERE semester_id=? FOR UPDATE",
                        semester);
        if (!old.isEmpty()) {
            Admissions.expect(old.getFirst().get("status").toString(), "DRAFT", "RETURNED");
            long id = Db.id(old.getFirst().get("id"));
            db.run(
                    "UPDATE ctsv_semester_reports SET"
                        + " status='SUBMITTED',submitted_at=CURRENT_TIMESTAMP,prepared_by=? WHERE"
                        + " id=?",
                    u.id(),
                    id);
            reviewReport(id, u, "SUBMIT", "");
            return id;
        }
        long id =
                db.insert(
                        "ctsv_semester_reports",
                        map(
                                "report_code",
                                "BC-" + UUID.randomUUID(),
                                "semester_id",
                                semester,
                                "prepared_by",
                                u.id(),
                                "status",
                                "SUBMITTED",
                                "submitted_at",
                                LocalDateTime.now()));
        reviewReport(id, u, "SUBMIT", "");
        return id;
    }

    @Transactional(isolation = Isolation.READ_COMMITTED)
    public void decideReport(long id, boolean approve, String note) {
        var u = actor.current();
        u.require("PRINCIPAL");
        var row = db.one("SELECT * FROM ctsv_semester_reports WHERE id=? FOR UPDATE", id);
        Admissions.expect(row.get("status").toString(), "SUBMITTED");
        if (Db.id(row.get("prepared_by")) == u.id())
            throw error(403, "Người lập không tự duyệt báo cáo.");
        if (!approve && (note == null || note.isBlank())) throw error(400, "Nhập lý do trả lại.");
        db.run(
                "UPDATE ctsv_semester_reports SET"
                        + " status=?,received_by=?,reviewed_at=CURRENT_TIMESTAMP,note=? WHERE id=?",
                approve ? "APPROVED" : "RETURNED",
                u.id(),
                note,
                id);
        reviewReport(id, u, approve ? "APPROVE" : "RETURN", note);
    }

    private void reviewReport(long id, Actor.User u, String action, String note) {
        db.insert(
                "ctsv_semester_report_reviews",
                map("report_id", id, "actor_user_id", u.id(), "action", action, "note", note));
        actor.audit(u, action, "ctsv_semester_reports", id);
    }

    private void lockInvoice(long id) {
        db.one("SELECT id FROM invoices WHERE id=? FOR UPDATE", id);
    }
}
