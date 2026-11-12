package com.sms.backend.controller;

import static com.sms.backend.repository.Db.*;

import com.sms.backend.repository.Db;
import com.sms.backend.security.Actor;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/accounts")
public class AccountsController {
    private final Db db;
    private final Actor actor;
    private final PasswordEncoder encoder;

    public AccountsController(Db db, Actor actor, PasswordEncoder encoder) {
        this.db = db;
        this.actor = actor;
        this.encoder = encoder;
    }

    @PostMapping
    @Transactional
    Map<String, Object> create(@RequestBody Map<String, Object> input) {
        var u = actor.current();
        u.require("PRINCIPAL");
        String username = text(input, "username", 80),
                email = text(input, "email", 190),
                name = text(input, "full_name", 160),
                password = text(input, "password", 128),
                role = text(input, "role", 40);
        if (!username.matches("[a-zA-Z0-9._-]{3,80}")
                || password.length() < 12
                || !email.matches("[^\\s@]+@[^\\s@]+\\.[^\\s@]+")
                || !Set.of("CTSV", "PRINCIPAL", "TRAINING_OFFICE", "LECTURER").contains(role))
            throw error(400, "Kiểm tra tài khoản, mật khẩu tối thiểu 12 ký tự và vai trò nhân sự.");
        long roleId = db.number("SELECT id FROM roles WHERE code=?", role);
        long id =
                db.insert(
                        "users",
                        map(
                                "username",
                                username,
                                "email",
                                email,
                                "full_name",
                                name,
                                "password_hash",
                                encoder.encode(password),
                                "enabled",
                                true));
        db.run("INSERT INTO user_roles(user_id,role_id) VALUES(?,?)", id, roleId);
        actor.audit(u, "CREATE_ACCOUNT", "users", id);
        return map("id", id);
    }

    @PostMapping("/password")
    @Transactional
    void password(@RequestBody Map<String, Object> input) {
        var u = actor.current();
        String old = text(input, "current_password", 128), next = text(input, "new_password", 128);
        var row = db.one("SELECT password_hash FROM users WHERE id=? FOR UPDATE", u.id());
        if (!encoder.matches(old, row.get("password_hash").toString()) || next.length() < 12)
            throw error(400, "Mật khẩu hiện tại không đúng hoặc mật khẩu mới quá ngắn.");
        db.run("UPDATE users SET password_hash=? WHERE id=?", encoder.encode(next), u.id());
        actor.audit(u, "CHANGE_PASSWORD", "users", u.id());
    }
}
