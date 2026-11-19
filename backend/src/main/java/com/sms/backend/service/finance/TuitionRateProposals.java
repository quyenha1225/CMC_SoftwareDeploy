package com.sms.backend.service.finance;

import static com.sms.backend.repository.Db.*;

import com.sms.backend.repository.Db;
import com.sms.backend.security.Actor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.util.Map;

@Service
public class TuitionRateProposals {
    private final Db db;
    private final Actor actor;

    public TuitionRateProposals(Db db, Actor actor) { this.db = db; this.actor = actor; }

    @Transactional
    public long submit(Map<String, Object> input) {
        var user = actor.current();
        user.require("TRAINING_OFFICE");
        long semester = Db.id(input.get("semester_id"));
        BigDecimal proposed;
        try { proposed = new BigDecimal(String.valueOf(input.get("proposed_price"))); }
        catch (RuntimeException ex) { throw error(400, "Nhập đơn giá đề xuất hợp lệ."); }
        String reason = String.valueOf(input.getOrDefault("reason", "")).trim();
        if (proposed.signum() <= 0 || reason.length() < 5 || reason.length() > 1000)
            throw error(400, "Đơn giá phải lớn hơn 0; lý do cần từ 5 đến 1000 ký tự.");
        db.one("SELECT id FROM semesters WHERE id=?", semester);
        var rate = db.rows("SELECT price_per_credit FROM tuition_rates WHERE semester_id=?", semester);
        BigDecimal current = rate.isEmpty() ? BigDecimal.ZERO : new BigDecimal(String.valueOf(rate.getFirst().get("price_per_credit")));
        long id = db.insert("tuition_rate_proposals", map(
                "semester_id", semester, "current_price", current, "proposed_price", proposed,
                "reason", reason, "status", "SUBMITTED", "submitted_by", user.id()));
        actor.audit(user, "SUBMIT", "tuition_rate_proposals", id);
        return id;
    }

    @Transactional
    public void decide(long id, String decision, String note) {
        var user = actor.current();
        user.require("PRINCIPAL");
        var proposal = db.one("SELECT * FROM tuition_rate_proposals WHERE id=? FOR UPDATE", id);
        if (!"SUBMITTED".equals(proposal.get("status"))) throw error(409, "Yêu cầu này đã được xử lý.");
        if (!java.util.Set.of("APPROVE", "RETURN", "REJECT").contains(decision)) throw error(400, "Quyết định không hợp lệ.");
        long semester = Db.id(proposal.get("semester_id"));
        if ("APPROVE".equals(decision)) {
            BigDecimal expected = new BigDecimal(String.valueOf(proposal.get("current_price")));
            var now = db.rows("SELECT price_per_credit FROM tuition_rates WHERE semester_id=? FOR UPDATE", semester);
            BigDecimal actual = now.isEmpty() ? BigDecimal.ZERO : new BigDecimal(String.valueOf(now.getFirst().get("price_per_credit")));
            if (actual.compareTo(expected) != 0) throw error(409, "Đơn giá hiện tại đã thay đổi. Phòng Đào tạo cần gửi yêu cầu mới.");
            if (now.isEmpty()) db.insert("tuition_rates", map("semester_id", semester, "price_per_credit", proposal.get("proposed_price")));
            else db.run("UPDATE tuition_rates SET price_per_credit=? WHERE semester_id=?", proposal.get("proposed_price"), semester);
        }
        String status = switch (decision) { case "APPROVE" -> "APPROVED"; case "RETURN" -> "RETURNED"; default -> "REJECTED"; };
        db.run("UPDATE tuition_rate_proposals SET status=?,reviewed_by=?,reviewed_at=CURRENT_TIMESTAMP,decision_note=? WHERE id=?", status, user.id(), note == null ? "" : note.trim(), id);
        actor.audit(user, decision, "tuition_rate_proposals", id);
    }
}
