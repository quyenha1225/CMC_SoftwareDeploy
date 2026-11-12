package com.sms.backend.service.admission;

import static com.sms.backend.repository.Db.*;

import com.sms.backend.repository.Db;
import com.sms.backend.security.Actor;
import com.sms.backend.service.resource.Resources;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.*;
import java.util.*;

import javax.crypto.*;
import javax.crypto.spec.*;

@Service
public class IdentityRecords {
    private final Db db;
    private final Actor actor;
    private final Resources resources;
    private final String encryptionKey;

    public IdentityRecords(
            Db db, Actor actor, Resources resources, @Value("${sms.identity.key}") String key) {
        this.db = db;
        this.actor = actor;
        this.resources = resources;
        this.encryptionKey = key;
    }

    private void editable(long id) {
        var user = actor.current();
        user.require("APPLICANT");
        var app = resources.accessible("admissions", id);
        if (Db.id(app.get("applicant_user_id")) != user.id())
            throw error(403, "Không phải hồ sơ của bạn.");
        app = db.one("SELECT * FROM admission_applications WHERE id=? FOR UPDATE", id);
        Admissions.expect(app.get("status").toString(), "DRAFT", "CHANGES_REQUESTED");
    }

    @Transactional
    public void identity(long id, Map<String, Object> input) {
        editable(id);
        String number = text(input, "identity_number", 60), type = text(input, "identity_type", 20);
        if (!Set.of("CCCD", "CMND", "PASSPORT", "OTHER").contains(type))
            throw error(400, "Loại giấy tờ không hợp lệ.");
        if (number.length() < 4) throw error(400, "Số giấy tờ quá ngắn.");
        byte[] encrypted;
        String hmac;
        try {
            byte[] key = Base64.getDecoder().decode(encryptionKey);
            if (key.length != 32) throw new IllegalArgumentException();
            byte[] nonce = new byte[12];
            new SecureRandom().nextBytes(nonce);
            var cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(
                    Cipher.ENCRYPT_MODE,
                    new SecretKeySpec(key, "AES"),
                    new GCMParameterSpec(128, nonce));
            byte[] ciphertext = cipher.doFinal(number.getBytes(StandardCharsets.UTF_8));
            encrypted = new byte[nonce.length + ciphertext.length];
            System.arraycopy(nonce, 0, encrypted, 0, nonce.length);
            System.arraycopy(ciphertext, 0, encrypted, nonce.length, ciphertext.length);
            var mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(key, "HmacSHA256"));
            hmac =
                    HexFormat.of()
                            .formatHex(
                                    mac.doFinal(
                                            number.toUpperCase(Locale.ROOT)
                                                    .getBytes(StandardCharsets.UTF_8)));
        } catch (Exception e) {
            throw error(503, "Chưa cấu hình khóa mã hóa hồ sơ trên server.");
        }
        var values =
                map(
                        "identity_type",
                        type,
                        "identity_last4",
                        number.substring(number.length() - 4),
                        "identity_number_encrypted",
                        encrypted,
                        "identity_number_hmac",
                        hmac,
                        "issued_on",
                        input.get("issued_on"),
                        "issued_by",
                        input.get("issued_by"),
                        "expires_on",
                        input.get("expires_on"));
        var old = db.rows("SELECT id FROM admission_identity_records WHERE application_id=?", id);
        if (old.isEmpty()) {
            values.put("application_id", id);
            db.insert("admission_identity_records", values);
        } else db.update("admission_identity_records", Db.id(old.getFirst().get("id")), values);
        actor.audit(actor.current(), "SAVE_IDENTITY", "admission_applications", id);
    }

    @Transactional
    public void school(long id, Map<String, Object> input) {
        editable(id);
        var values =
                map(
                        "school_name",
                        text(input, "school_name", 200),
                        "school_province",
                        input.get("school_province"),
                        "graduation_year",
                        input.get("graduation_year"),
                        "graduation_status",
                        Objects.toString(input.get("graduation_status"), "PENDING"),
                        "transcript_average",
                        input.get("transcript_average"));
        var old =
                db.rows("SELECT id FROM admission_high_school_records WHERE application_id=?", id);
        long record;
        if (old.isEmpty()) {
            values.put("application_id", id);
            record = db.insert("admission_high_school_records", values);
        } else {
            record = Db.id(old.getFirst().get("id"));
            db.update("admission_high_school_records", record, values);
        }
        if (input.get("scores") instanceof List<?> scores) {
            if (scores.size() > 100) throw error(400, "Danh sách điểm quá dài.");
            db.run("DELETE FROM admission_high_school_scores WHERE school_record_id=?", record);
            for (Object raw : scores) {
                if (!(raw instanceof Map<?, ?> score))
                    throw error(400, "Điểm học bạ không hợp lệ.");
                db.insert(
                        "admission_high_school_scores",
                        map(
                                "school_record_id",
                                record,
                                "grade_level",
                                score.get("grade_level"),
                                "subject_code",
                                score.get("subject_code"),
                                "average_score",
                                score.get("average_score")));
            }
        }
        actor.audit(actor.current(), "SAVE_HIGH_SCHOOL", "admission_applications", id);
    }
}
