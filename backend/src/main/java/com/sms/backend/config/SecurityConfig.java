package com.sms.backend.config;

import com.sms.backend.repository.Db;
import com.sms.backend.security.LoginTokenFilter;
import com.sms.backend.security.LoginTokens;

import org.springframework.context.annotation.*;
import org.springframework.security.authentication.*;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.core.userdetails.*;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.context.HttpSessionSecurityContextRepository;
import org.springframework.security.web.context.SecurityContextRepository;
import org.springframework.security.web.csrf.CookieCsrfTokenRepository;

@Configuration
public class SecurityConfig {
    @Bean
    PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder(12);
    }

    @Bean
    UserDetailsService userDetailsService(Db db) {
        return username -> {
            var users =
                    db.rows(
                            "SELECT id,username,password_hash,enabled FROM users WHERE username=?"
                                    + " OR email=?",
                            username,
                            username);
            if (users.size() != 1) throw new UsernameNotFoundException("Invalid credentials");
            var user = users.getFirst();
            var roles =
                    db
                            .rows(
                                    "SELECT r.code FROM roles r JOIN user_roles ur ON"
                                            + " ur.role_id=r.id WHERE ur.user_id=?",
                                    user.get("id"))
                            .stream()
                            .map(row -> "ROLE_" + row.get("code"))
                            .toArray(String[]::new);
            return User.withUsername(user.get("username").toString())
                    .password(user.get("password_hash").toString())
                    .authorities(roles)
                    .disabled(
                            !Boolean.parseBoolean(String.valueOf(user.get("enabled")))
                                    && !"1".equals(String.valueOf(user.get("enabled"))))
                    .build();
        };
    }

    @Bean
    AuthenticationManager authenticationManager(
            UserDetailsService service, PasswordEncoder encoder) {
        var provider = new DaoAuthenticationProvider(service);
        provider.setPasswordEncoder(encoder);
        return new ProviderManager(provider);
    }

    @Bean
    SecurityContextRepository securityContextRepository() {
        return new HttpSessionSecurityContextRepository();
    }

    @Bean
    SecurityFilterChain securityFilterChain(
            HttpSecurity http, SecurityContextRepository repository, LoginTokens tokens)
            throws Exception {
        http.csrf(csrf -> csrf.csrfTokenRepository(CookieCsrfTokenRepository.withHttpOnlyFalse()))
                .securityContext(context -> context.securityContextRepository(repository))
                .addFilterAfter(
                        new LoginTokenFilter(tokens),
                        org.springframework.security.web.context.SecurityContextHolderFilter.class)
                .authorizeHttpRequests(
                        auth ->
                                auth.requestMatchers("/actuator/health", "/actuator/health/**")
                                        .permitAll()
                                        .requestMatchers(
                                                request ->
                                                        request.getLocalPort() == 9092
                                                                && request.getRequestURI()
                                                                        .equals(
                                                                                "/actuator/prometheus"))
                                        .permitAll()
                                        .requestMatchers(
                                                "/api/auth/csrf",
                                                "/api/auth/login",
                                                "/api/auth/forgot-password",
                                                "/api/auth/reset-password",
                                                "/api/public/**")
                                        .permitAll()
                                        .requestMatchers("/api/**")
                                        .authenticated()
                                        .anyRequest()
                                        .denyAll())
                .exceptionHandling(
                        errors ->
                                errors.authenticationEntryPoint(
                                                (request, response, error) -> {
                                                    response.setStatus(401);
                                                    response.setContentType(
                                                            "application/json;charset=UTF-8");
                                                    response.getWriter()
                                                            .write(
                                                                    "{\"message\":\"Vui lòng đăng"
                                                                            + " nhập.\"}");
                                                })
                                        .accessDeniedHandler(
                                                (request, response, error) -> {
                                                    response.setStatus(403);
                                                    response.setContentType(
                                                            "application/json;charset=UTF-8");
                                                    response.getWriter()
                                                            .write(
                                                                    "{\"message\":\"Không có quyền"
                                                                        + " hoặc phiên bảo vệ đã"
                                                                        + " hết hạn.\"}");
                                                }))
                .logout(
                        logout ->
                                logout.logoutUrl("/api/auth/logout")
                                        .invalidateHttpSession(true)
                                        .deleteCookies("JSESSIONID", "XSRF-TOKEN")
                                        .addLogoutHandler(
                                                (request, response, auth) ->
                                                        response.addHeader(
                                                                "Set-Cookie",
                                                                org.springframework.http
                                                                        .ResponseCookie.from(
                                                                                LoginTokens.COOKIE,
                                                                                "")
                                                                        .httpOnly(true)
                                                                        .secure(request.isSecure())
                                                                        .sameSite("Lax")
                                                                        .path("/api")
                                                                        .maxAge(0)
                                                                        .build()
                                                                        .toString()))
                                        .logoutSuccessHandler(
                                                (request, response, auth) ->
                                                        response.setStatus(204)))
                .headers(
                        headers ->
                                headers.contentSecurityPolicy(
                                        csp ->
                                                csp.policyDirectives(
                                                        "default-src 'none'; frame-ancestors"
                                                                + " 'none'")));
        return http.build();
    }
}
