package com.sms.backend.security;

import static com.sms.backend.repository.Db.*;

import com.sms.backend.repository.Db;

import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

import java.util.*;

@Component
public class Actor {
    private final Db db;

    public Actor(Db db) {
        this.db = db;
    }

    public record User(
            long id,
            String name,
            String email,
            Set<String> roles,
            Long studentId,
            Long lecturerId) {
        public boolean has(String... allowed) {
            return Arrays.stream(allowed).anyMatch(roles::contains);
        }

        public void require(String... allowed) {
            if (!has(allowed)) throw error(403, "Bạn không có quyền thực hiện thao tác này.");
        }

        public long student() {
            require("STUDENT");
            if (studentId == null) throw error(403, "Tài khoản chưa liên kết sinh viên.");
            return studentId;
        }
    }

    public User current() {
        var authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null
                || !authentication.isAuthenticated()
                || "anonymousUser".equals(authentication.getName()))
            throw error(401, "Vui lòng đăng nhập.");
        var user =
                db.one(
                        "SELECT id,full_name,email,enabled FROM users WHERE username=?",
                        authentication.getName());
        if (!Boolean.parseBoolean(String.valueOf(user.get("enabled")))
                && !"1".equals(String.valueOf(user.get("enabled"))))
            throw error(401, "Tài khoản đã bị khóa.");
        long id = id(user.get("id"));
        var roles = new HashSet<String>();
        db.rows(
                        "SELECT r.code FROM roles r JOIN user_roles ur ON ur.role_id=r.id WHERE"
                                + " ur.user_id=?",
                        id)
                .forEach(row -> roles.add(row.get("code").toString()));
        var students = db.rows("SELECT id FROM students WHERE user_id=?", id);
        var teachers = db.rows("SELECT id FROM lecturers WHERE user_id=?", id);
        return new User(
                id,
                user.get("full_name").toString(),
                Objects.toString(user.get("email"), ""),
                roles,
                students.isEmpty() ? null : id(students.getFirst().get("id")),
                teachers.isEmpty() ? null : id(teachers.getFirst().get("id")));
    }

    public void audit(User user, String action, String entity, Object id) {
        db.insert(
                "audit_logs",
                map(
                        "actor_user_id",
                        user.id(),
                        "action",
                        action,
                        "entity_type",
                        entity,
                        "entity_id",
                        String.valueOf(id)));
    }
}
