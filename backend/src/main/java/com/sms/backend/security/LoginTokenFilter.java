package com.sms.backend.security;

import jakarta.servlet.*;
import jakarta.servlet.http.*;

import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/** Complements session/CSRF protection; never grants privileges from client claims. */
public class LoginTokenFilter extends OncePerRequestFilter {
    private final LoginTokens tokens;

    public LoginTokenFilter(LoginTokens tokens) {
        this.tokens = tokens;
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String path = request.getServletPath();
        if (path.equals("/api/auth/login")
                || path.equals("/api/auth/csrf")
                || path.equals("/api/auth/forgot-password")
                || path.equals("/api/auth/reset-password")
                || path.startsWith("/api/public/")) {
            chain.doFilter(request, response);
            return;
        }
        String token = null;
        if (request.getCookies() != null)
            for (var cookie : request.getCookies())
                if (LoginTokens.COOKIE.equals(cookie.getName())) token = cookie.getValue();
        var session = request.getSession(false);
        var authentication = SecurityContextHolder.getContext().getAuthentication();
        boolean bound = session != null && session.getAttribute(LoginTokens.SESSION_ID) != null;
        if ((token != null || bound)
                && (authentication == null
                        || !tokens.valid(
                                token == null ? "" : token, session, authentication.getName()))) {
            SecurityContextHolder.clearContext();
            response.setStatus(401);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter()
                    .write("{\"message\":\"Phiên đăng nhập không hợp lệ hoặc đã hết hạn.\"}");
            return;
        }
        chain.doFilter(request, response);
    }
}
