package com.sms.backend.controller;

import static com.sms.backend.repository.Db.*;

import com.sms.backend.repository.Db;
import com.sms.backend.security.Actor;
import com.sms.backend.security.LoginTokens;
import com.sms.backend.service.auth.PasswordRecovery;

import jakarta.servlet.http.*;

import org.springframework.security.authentication.*;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.context.SecurityContextRepository;
import org.springframework.security.web.csrf.CsrfToken;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.*;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

@RestController
@RequestMapping("/api")
public class AuthController {
    private final Db db;
    private final Actor actor;
    private final AuthenticationManager manager;
    private final SecurityContextRepository repository;
    private final PasswordEncoder encoder;
    private final LoginTokens tokens;
    private final PasswordRecovery recovery;
    private final ConcurrentHashMap<String, List<Instant>> attempts = new ConcurrentHashMap<>();

    public AuthController(
            Db db,
            Actor actor,
            AuthenticationManager manager,
            SecurityContextRepository repository,
            PasswordEncoder encoder,
            LoginTokens tokens,
            PasswordRecovery recovery) {
        this.db = db;
        this.actor = actor;
        this.manager = manager;
        this.repository = repository;
        this.encoder = encoder;
        this.tokens = tokens;
        this.recovery = recovery;
    }

    @GetMapping("/auth/csrf")
    Map<String, Object> csrf(CsrfToken token) {
        return map("token", token.getToken(), "headerName", token.getHeaderName());
    }

    @PostMapping("/auth/login")
    Map<String, Object> login(
            @RequestBody Map<String, Object> body,
            HttpServletRequest request,
            HttpServletResponse response) {
        limit(request);
        var username = text(body, "username", 190);
        var password = text(body, "password", 128);
        try {
            var auth =
                    manager.authenticate(
                            UsernamePasswordAuthenticationToken.unauthenticated(
                                    username, password));
            request.getSession(true);
            request.changeSessionId();
            var context = SecurityContextHolder.createEmptyContext();
            context.setAuthentication(auth);
            SecurityContextHolder.setContext(context);
            repository.saveContext(context, request, response);
            tokens.issue(auth.getName(), request, response);
            attempts.remove(request.getRemoteAddr());
            actor.audit(actor.current(), "LOGIN", "users", actor.current().id());
            return me();
        } catch (AuthenticationException e) {
            throw error(
                    401, "Tài khoản hoặc mật khẩu không đúng, hoặc tài khoản chưa được kích hoạt.");
        }
    }

    private void limit(HttpServletRequest request) {
        var now = Instant.now();
        if (attempts.size() > 10000)
            attempts.entrySet()
                    .removeIf(
                            entry ->
                                    entry.getValue().stream()
                                            .allMatch(time -> time.isBefore(now.minusSeconds(60))));
        var list =
                attempts.computeIfAbsent(
                        request.getRemoteAddr(),
                        key -> Collections.synchronizedList(new ArrayList<>()));
        synchronized (list) {
            list.removeIf(time -> time.isBefore(now.minusSeconds(60)));
            if (list.size() >= 8)
                throw error(429, "Thử đăng nhập quá nhiều lần. Vui lòng đợi một phút.");
            list.add(now);
        }
    }

    @PostMapping("/auth/forgot-password")
    Map<String, Object> forgot(@RequestBody Map<String, Object> body, HttpServletRequest request) {
        limit(request);
        String email = text(body, "email", 190);
        if (!email.matches("[^\\s@]+@[^\\s@]+\\.[^\\s@]+")) throw error(400, "Email không hợp lệ.");
        var delivery = recovery.issue(email);
        recovery.deliver(delivery);
        return map(
                "message",
                "Nếu email trường hợp lệ và hộp thư đã hoạt động, bạn sẽ nhận được hướng dẫn khôi"
                        + " phục.");
    }

    @PostMapping("/auth/reset-password")
    Map<String, Object> reset(@RequestBody Map<String, Object> body, HttpServletRequest request) {
        limit(request);
        recovery.reset(text(body, "token", 100), text(body, "new_password", 128));
        return map("message", "Đã đổi mật khẩu. Vui lòng đăng nhập lại.");
    }

    @GetMapping("/me")
    Map<String, Object> me() {
        var user = actor.current();
        return map(
                "id",
                user.id(),
                "name",
                user.name(),
                "email",
                user.email(),
                "roles",
                user.roles(),
                "studentId",
                user.studentId(),
                "lecturerId",
                user.lecturerId());
    }

    @GetMapping("/public/admission-options")
    Map<String, Object> admissionOptions() {
        return map(
                "admission_periods",
                db.rows(
                        "SELECT id,code,title FROM admission_periods WHERE status='OPEN' AND"
                            + " opens_at<=CURRENT_TIMESTAMP AND closes_at>=CURRENT_TIMESTAMP ORDER"
                            + " BY opens_at DESC"),
                "majors",
                db.rows("SELECT id,code,name FROM majors ORDER BY code"));
    }

    @PostMapping("/public/admissions")
    @Transactional
    Map<String, Object> register(
            @RequestBody Map<String, Object> body, HttpServletRequest request) {
        limit(request);
        String username = text(body, "username", 80),
                email = text(body, "email", 190),
                password = text(body, "password", 128),
                name = text(body, "full_name", 160);
        if (!username.matches("[a-zA-Z0-9._-]{3,80}")
                || !email.matches("[^\\s@]+@[^\\s@]+\\.[^\\s@]+")
                || password.length() < 12)
            throw error(400, "Kiểm tra tên tài khoản, email và mật khẩu tối thiểu 12 ký tự.");
        if (body.containsKey("roles") || body.containsKey("role"))
            throw error(400, "Không được tự cấp vai trò khi đăng ký.");
        long period = Db.id(body.get("period_id")), major = Db.id(body.get("major_id"));
        db.one(
                "SELECT id FROM admission_periods WHERE id=? AND status='OPEN' AND"
                    + " opens_at<=CURRENT_TIMESTAMP AND closes_at>=CURRENT_TIMESTAMP FOR UPDATE",
                period);
        db.one("SELECT id FROM majors WHERE id=?", major);
        long role = db.number("SELECT id FROM roles WHERE code='APPLICANT'");
        if (db.number("SELECT COUNT(*) FROM users WHERE username=? OR email=?", username, email)
                > 0) throw error(409, "Tên tài khoản hoặc email đã được sử dụng.");
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
        db.run("INSERT INTO user_roles(user_id,role_id) VALUES (?,?)", id, role);
        long application =
                db.insert(
                        "admission_applications",
                        map(
                                "application_code",
                                "HS-" + UUID.randomUUID(),
                                "applicant_user_id",
                                id,
                                "period_id",
                                period,
                                "major_id",
                                major,
                                "legal_full_name",
                                name,
                                "personal_email",
                                email,
                                "status",
                                "DRAFT"));
        return map(
                "id",
                application,
                "message",
                "Đã mở hồ sơ nháp. Vui lòng hoàn thiện giấy tờ trước khi gửi.");
    }
}
