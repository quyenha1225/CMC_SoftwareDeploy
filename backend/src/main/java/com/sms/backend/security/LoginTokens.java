package com.sms.backend.security;

import com.nimbusds.jose.jwk.source.ImmutableSecret;
import com.sms.backend.repository.Db;
import com.sms.backend.service.auth.PasswordRecovery;

import jakarta.servlet.http.*;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.*;
import org.springframework.stereotype.Component;

import java.time.*;
import java.util.*;

import javax.crypto.spec.SecretKeySpec;

/** Signed login cookie bound to the server session so logout revokes it immediately. */
@Component
public class LoginTokens {
    public static final String COOKIE = "SMS_ACCESS", SESSION_ID = "sms.jwt.id";
    private static final String ISSUER = "eduportal", AUDIENCE = "eduportal-web";
    private final Db db;
    private final JwtEncoder encoder;
    private final JwtDecoder decoder;
    private final boolean secure;
    private final Duration lifetime;

    public LoginTokens(
            Db db,
            @Value("${sms.jwt.secret}") String secret,
            @Value("${sms.jwt.cookie-secure}") boolean secure,
            @Value("${sms.jwt.ttl-seconds}") long seconds) {
        this.db = db;
        byte[] bytes;
        try {
            bytes = Base64.getDecoder().decode(secret);
        } catch (Exception e) {
            throw new IllegalArgumentException("SMS_JWT_SECRET must be Base64.");
        }
        if (bytes.length < 64)
            throw new IllegalArgumentException("SMS_JWT_SECRET requires at least 64 random bytes.");
        if (seconds < 60 || seconds > 3600)
            throw new IllegalArgumentException("JWT lifetime must be 60–3600 seconds.");
        var key = new SecretKeySpec(bytes, "HmacSHA512");
        this.encoder = new NimbusJwtEncoder(new ImmutableSecret<>(key));
        var nimbus = NimbusJwtDecoder.withSecretKey(key).macAlgorithm(MacAlgorithm.HS512).build();
        nimbus.setJwtValidator(JwtValidators.createDefaultWithIssuer(ISSUER));
        this.decoder = nimbus;
        this.secure = secure;
        this.lifetime = Duration.ofSeconds(seconds);
    }

    public void issue(String username, HttpServletRequest request, HttpServletResponse response) {
        String id = UUID.randomUUID().toString();
        request.getSession(true).setAttribute(SESSION_ID, id);
        Instant now = Instant.now();
        var claims =
                JwtClaimsSet.builder()
                        .issuer(ISSUER)
                        .audience(List.of(AUDIENCE))
                        .subject(username)
                        .claim("credential", credential(username))
                        .id(id)
                        .issuedAt(now)
                        .notBefore(now)
                        .expiresAt(now.plus(lifetime))
                        .build();
        String token =
                encoder.encode(
                                JwtEncoderParameters.from(
                                        JwsHeader.with(MacAlgorithm.HS512).build(), claims))
                        .getTokenValue();
        response.addHeader(
                HttpHeaders.SET_COOKIE,
                ResponseCookie.from(COOKIE, token)
                        .httpOnly(true)
                        .secure(secure)
                        .sameSite("Lax")
                        .path("/api")
                        .maxAge(lifetime)
                        .build()
                        .toString());
    }

    private String credential(String username) {
        var rows =
                db.rows(
                        "SELECT password_hash FROM users WHERE username=? AND enabled=TRUE",
                        username);
        return rows.size() == 1
                ? PasswordRecovery.digest(rows.getFirst().get("password_hash").toString())
                : "disabled";
    }

    public boolean valid(String token, HttpSession session, String username) {
        if (session == null) return false;
        try {
            var jwt = decoder.decode(token);
            return credential(username).equals(jwt.getClaimAsString("credential"))
                    && jwt.getAudience().contains(AUDIENCE)
                    && username.equals(jwt.getSubject())
                    && jwt.getId() != null
                    && jwt.getId().equals(session.getAttribute(SESSION_ID));
        } catch (JwtException | IllegalArgumentException e) {
            return false;
        }
    }
}
