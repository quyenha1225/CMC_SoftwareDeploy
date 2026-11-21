package com.sms.backend.alert;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.servlet.HandlerMapping;

import java.io.IOException;

@Component
public class BackendAlertEvents extends OncePerRequestFilter {

    private final DiscordAlertService alerts;
    private final String environment;

    public BackendAlertEvents(DiscordAlertService alerts,
                              @Value("${SMS_ENVIRONMENT:local}") String environment) {
        this.alerts = alerts;
        this.environment = environment;
    }

    @EventListener(ApplicationReadyEvent.class)
    public void ready() {
        alerts.send("info", "Backend ready", "Environment: " + environment);
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        try {
            chain.doFilter(request, response);
        } catch (ServletException | RuntimeException failure) {
            report(request, 500);
            throw failure;
        }
        if (response.getStatus() >= 500) {
            report(request, response.getStatus());
        }
    }

    private void report(HttpServletRequest request, int status) {
        Object route = request.getAttribute(HandlerMapping.BEST_MATCHING_PATTERN_ATTRIBUTE);
        alerts.send("error", "Backend HTTP " + status,
                "Environment: " + environment + "\n" + request.getMethod()
                        + " " + (route == null ? "(unmapped route)" : route));
    }
}
