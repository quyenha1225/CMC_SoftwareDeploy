package com.sms.backend.service.academic;

import static com.sms.backend.repository.Db.*;

import com.sms.backend.repository.Db;

import org.springframework.stereotype.Service;

import java.util.Map;

/** Resolve canonical catalog IDs while accepting existing text-based API clients. */
@Service
public class AcademicCatalog {
    private final Db db;

    public AcademicCatalog(Db db) {
        this.db = db;
    }

    public Map<String, Object> room(Map<String, Object> input) {
        return room(input, true);
    }

    public Map<String, Object> room(Map<String, Object> input, boolean requireActive) {
        var rows =
                input.get("room_id") != null && !input.get("room_id").toString().isBlank()
                        ? db.rows(
                                "SELECT * FROM rooms WHERE id=? FOR UPDATE",
                                Db.id(input.get("room_id")))
                        : db.rows(
                                "SELECT * FROM rooms WHERE code=? FOR UPDATE",
                                text(input, "room", 80));
        if (rows.isEmpty())
            throw error(400, "Phòng chưa có trong danh mục. PĐT cần tạo phòng trước.");
        var room = rows.getFirst();
        if (requireActive
                && !Boolean.parseBoolean(room.get("active").toString())
                && !"1".equals(room.get("active").toString()))
            throw error(409, "Phòng đã ngừng sử dụng.");
        return room;
    }

    public Map<String, Object> examType(Map<String, Object> input) {
        return examType(input, true);
    }

    public Map<String, Object> examType(Map<String, Object> input, boolean requireActive) {
        var rows =
                input.get("exam_type_id") != null && !input.get("exam_type_id").toString().isBlank()
                        ? db.rows(
                                "SELECT * FROM exam_types WHERE id=?",
                                Db.id(input.get("exam_type_id")))
                        : db.rows(
                                "SELECT * FROM exam_types WHERE name=? OR code=?",
                                text(input, "exam_type", 80),
                                text(input, "exam_type", 80));
        if (rows.isEmpty()) throw error(400, "Loại thi chưa có trong danh mục.");
        var type = rows.getFirst();
        if (requireActive
                && !Boolean.parseBoolean(type.get("active").toString())
                && !"1".equals(type.get("active").toString()))
            throw error(409, "Loại thi đã ngừng sử dụng.");
        return type;
    }
}
