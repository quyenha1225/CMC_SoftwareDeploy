package com.sms.backend.service.finance;

import static com.sms.backend.repository.Db.*;

import com.sms.backend.repository.Db;
import com.sms.backend.security.Actor;
import com.sms.backend.service.admission.Admissions;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;

@Service
public class InvoiceProposals {
    private final Db db;
    private final Actor actor;

    public InvoiceProposals(Db db, Actor actor) {
        this.db = db;
        this.actor = actor;
    }

    private List<Map<String, Object>> current(long student, long semester) {
        return db.rows(
                "SELECT e.id enrollment_id,c.credits credits_at_proposal,tr.price_per_credit"
                    + " unit_price_at_proposal FROM enrollments e JOIN course_sections cs ON"
                    + " cs.id=e.section_id JOIN courses c ON c.id=cs.course_id JOIN tuition_rates"
                    + " tr ON tr.semester_id=cs.semester_id WHERE e.student_id=? AND"
                    + " cs.semester_id=? AND e.status<>'CANCELLED' ORDER BY e.id",
                student,
                semester);
    }

    private List<Map<String, Object>> items(long id) {
        return db.rows(
                "SELECT"
                    + " it.*,cs.section_code,c.title,it.credits_at_proposal*it.unit_price_at_proposal"
                    + " amount FROM invoice_proposal_items it JOIN enrollments e ON"
                    + " e.id=it.enrollment_id JOIN course_sections cs ON cs.id=e.section_id JOIN"
                    + " courses c ON c.id=cs.course_id WHERE it.proposal_id=? ORDER BY"
                    + " it.enrollment_id",
                id);
    }

    private Map<String, Object> lock(long id) {
        var row = db.one("SELECT * FROM invoice_proposals WHERE id=?", id);
        db.one("SELECT id FROM students WHERE id=? FOR UPDATE", row.get("student_id"));
        return db.one("SELECT * FROM invoice_proposals WHERE id=? FOR UPDATE", id);
    }

    private void unissued(long student, long semester) {
        if (db.number(
                        "SELECT COUNT(*) FROM invoices WHERE student_id=? AND semester_id=?",
                        student,
                        semester)
                > 0) throw error(409, "Học kỳ đã có hóa đơn; sử dụng đề nghị điều chỉnh học phí.");
    }

    private BigDecimal decimal(Object value) {
        return new BigDecimal(String.valueOf(value));
    }

    private void validateSnapshot(Map<String, Object> row, boolean prices) {
        var existing = items(Db.id(row.get("id")));
        var now = current(Db.id(row.get("student_id")), Db.id(row.get("semester_id")));
        if (existing.isEmpty() || existing.size() != now.size())
            throw error(
                    409,
                    "Danh sách đăng ký đã thay đổi. CTSV cần cập nhật đề nghị trước khi trình"
                            + " duyệt.");
        BigDecimal gross = BigDecimal.ZERO;
        for (int index = 0; index < existing.size(); index++) {
            var old = existing.get(index);
            var next = now.get(index);
            if (Db.id(old.get("enrollment_id")) != Db.id(next.get("enrollment_id"))
                    || prices
                            && (Db.id(old.get("credits_at_proposal"))
                                            != Db.id(next.get("credits_at_proposal"))
                                    || decimal(old.get("unit_price_at_proposal"))
                                                    .compareTo(
                                                            decimal(
                                                                    next.get(
                                                                            "unit_price_at_proposal")))
                                            != 0))
                throw error(
                        409,
                        "Học phần hoặc đơn giá đã thay đổi; cần cập nhật và trình lại đề nghị.");
            gross = gross.add(decimal(old.get("amount")));
        }
        if (decimal(row.get("discount_amount")).compareTo(gross) > 0)
            throw error(400, "Miễn giảm vượt tổng học phí đề nghị.");
    }

    private void event(long id, String action, String from, String to, String note) {
        db.insert(
                "invoice_proposal_reviews",
                map(
                        "proposal_id",
                        id,
                        "actor_user_id",
                        actor.current().id(),
                        "action",
                        action,
                        "from_status",
                        from,
                        "to_status",
                        to,
                        "note",
                        note));
        actor.audit(actor.current(), action, "invoice_proposals", id);
    }

    @Transactional
    public long save(Long id, Map<String, Object> body) {
        var user = actor.current();
        user.require("CTSV");
        long student, semester;
        String from = null;
        if (id == null) {
            student = Db.id(body.get("student_id"));
            semester = Db.id(body.get("semester_id"));
            db.one("SELECT id FROM students WHERE id=? FOR UPDATE", student);
        } else {
            var old = lock(id);
            Admissions.expect(old.get("status").toString(), "DRAFT", "RETURNED");
            student = Db.id(old.get("student_id"));
            semester = Db.id(old.get("semester_id"));
            from = old.get("status").toString();
        }
        unissued(student, semester);
        var source = current(student, semester);
        if (source.isEmpty()) throw error(409, "Chưa có đăng ký học phần hoặc đơn giá học kỳ.");
        BigDecimal discount = decimal(body.getOrDefault("discount_amount", 0));
        if (discount.signum() < 0 || discount.scale() > 2 || discount.precision() > 14)
            throw error(400, "Miễn giảm không hợp lệ.");
        String note = Objects.toString(body.get("note"), "");
        if (note.length() > 700) throw error(400, "Ghi chú quá dài.");
        if (id == null)
            id =
                    db.insert(
                            "invoice_proposals",
                            map(
                                    "proposal_code",
                                    "DHP-" + UUID.randomUUID(),
                                    "student_id",
                                    student,
                                    "semester_id",
                                    semester,
                                    "prepared_by",
                                    user.id(),
                                    "status",
                                    "DRAFT",
                                    "discount_amount",
                                    discount,
                                    "note",
                                    note));
        else {
            db.update(
                    "invoice_proposals",
                    id,
                    map("status", "DRAFT", "discount_amount", discount, "note", note));
            db.run("DELETE FROM invoice_proposal_items WHERE proposal_id=?", id);
        }
        for (var item : source)
            db.insert(
                    "invoice_proposal_items",
                    map(
                            "proposal_id",
                            id,
                            "enrollment_id",
                            item.get("enrollment_id"),
                            "credits_at_proposal",
                            item.get("credits_at_proposal"),
                            "unit_price_at_proposal",
                            item.get("unit_price_at_proposal")));
        validateSnapshot(db.one("SELECT * FROM invoice_proposals WHERE id=?", id), true);
        event(id, "SAVE", from, "DRAFT", note);
        return id;
    }

    @Transactional
    public void action(long id, String action, String note) {
        var user = actor.current();
        var row = lock(id);
        String from = row.get("status").toString(), to;
        if (note != null && note.length() > 700) throw error(400, "Ghi chú quá dài.");
        if (action.equals("SUBMIT")) {
            user.require("CTSV");
            Admissions.expect(from, "DRAFT");
            unissued(Db.id(row.get("student_id")), Db.id(row.get("semester_id")));
            validateSnapshot(row, true);
            to = "SUBMITTED";
            db.run(
                    "UPDATE invoice_proposals SET"
                        + " status=?,submitted_at=CURRENT_TIMESTAMP,reviewed_by=NULL,reviewed_at=NULL,decision_note=NULL"
                        + " WHERE id=?",
                    to,
                    id);
        } else {
            user.require("PRINCIPAL");
            Admissions.expect(from, "SUBMITTED");
            if (db.number(
                            "SELECT COUNT(*) FROM invoice_proposal_reviews WHERE proposal_id=? AND"
                                    + " action='SUBMIT'",
                            id)
                    == 0) throw error(409, "Đề nghị chưa có lịch sử CTSV trình BGH.");
            if (user.id() == Db.id(row.get("prepared_by")))
                throw error(409, "Người lập không được tự xét duyệt đề nghị của mình.");
            if (action.equals("APPROVE")) {
                unissued(Db.id(row.get("student_id")), Db.id(row.get("semester_id")));
                validateSnapshot(row, true);
                to = "APPROVED";
            } else if (Set.of("RETURN", "REJECT").contains(action)) {
                if (note == null || note.isBlank()) throw error(400, "Nhập lý do trả lại/từ chối.");
                to = action.equals("RETURN") ? "RETURNED" : "REJECTED";
            } else throw error(400, "Thao tác không hợp lệ.");
            db.update(
                    "invoice_proposals",
                    id,
                    map(
                            "status",
                            to,
                            "reviewed_by",
                            user.id(),
                            "reviewed_at",
                            LocalDateTime.now(),
                            "decision_note",
                            note));
        }
        event(id, action, from, to, note);
    }

    public Map<String, Object> detail(long id) {
        actor.current().require("CTSV", "PRINCIPAL", "TRAINING_OFFICE");
        var row =
                db.one(
                        "SELECT p.*,s.student_code,u.full_name,se.code semester_code,ay.name"
                            + " academic_year,prep.full_name prepared_name FROM invoice_proposals p"
                            + " JOIN students s ON s.id=p.student_id JOIN users u ON u.id=s.user_id"
                            + " JOIN semesters se ON se.id=p.semester_id JOIN academic_years ay ON"
                            + " ay.id=se.academic_year_id JOIN users prep ON prep.id=p.prepared_by"
                            + " WHERE p.id=?",
                        id);
        var snapshot = items(id);
        BigDecimal gross =
                snapshot.stream()
                        .map(item -> decimal(item.get("amount")))
                        .reduce(BigDecimal.ZERO, BigDecimal::add);
        row.put("gross_amount", gross);
        row.put("payable_amount", gross.subtract(decimal(row.get("discount_amount"))));
        row.put("items", snapshot);
        row.put(
                "reviews",
                db.rows(
                        "SELECT r.*,u.full_name actor_name FROM invoice_proposal_reviews r JOIN"
                            + " users u ON u.id=r.actor_user_id WHERE proposal_id=? ORDER BY r.id",
                        id));
        return row;
    }

    public Map<String, Object> approvedForIssue(long student, long semester) {
        var rows =
                db.rows(
                        "SELECT * FROM invoice_proposals WHERE student_id=? AND semester_id=? AND"
                                + " status='APPROVED' FOR UPDATE",
                        student,
                        semester);
        if (rows.isEmpty())
            throw error(
                    409,
                    "Cần lập đề nghị học phí và được BGH phê duyệt trước khi phát hành hóa đơn.");
        var row = rows.getFirst();
        validateSnapshot(row, false);
        row.put("items", items(Db.id(row.get("id"))));
        return row;
    }

    public void issued(long id, long invoice) {
        db.update("invoice_proposals", id, map("status", "ISSUED", "invoice_id", invoice));
        event(id, "ISSUE", "APPROVED", "ISSUED", "Phát hành theo nội dung đã được BGH duyệt.");
    }
}
