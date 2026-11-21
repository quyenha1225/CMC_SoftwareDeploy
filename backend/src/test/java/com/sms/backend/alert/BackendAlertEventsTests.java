package com.sms.backend.alert;

import jakarta.servlet.ServletException;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.web.servlet.HandlerMapping;

import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

class BackendAlertEventsTests {
    private final DiscordAlertService alerts = mock(DiscordAlertService.class);
    private final BackendAlertEvents filter = new BackendAlertEvents(alerts, "test");

    @Test
    void reportsTheEnvironmentOnStartup() {
        filter.ready();
        verify(alerts).send("info", "Backend ready", "Environment: test");
    }

    @Test
    void usesTheRoutePatternForServerErrors() throws Exception {
        var request = new MockHttpServletRequest("GET", "/api/students/123");
        var response = new MockHttpServletResponse();
        filter.doFilter(request, response, (req, res) -> {
            req.setAttribute(HandlerMapping.BEST_MATCHING_PATTERN_ATTRIBUTE, "/api/students/{id}");
            response.setStatus(503);
        });
        verify(alerts).send("error", "Backend HTTP 503", "Environment: test\nGET /api/students/{id}");
    }

    @Test
    void leavesClientErrorsOutOfTheAlertChannel() throws Exception {
        var request = new MockHttpServletRequest("GET", "/api/students");
        var response = new MockHttpServletResponse();
        filter.doFilter(request, response, (req, res) -> response.setStatus(401));
        verifyNoInteractions(alerts);
    }

    @Test
    void reportsUnhandledFailureAndPropagatesIt() {
        var request = new MockHttpServletRequest("POST", "/api/students");
        var response = new MockHttpServletResponse();
        var failure = new ServletException("internal error");
        assertSame(failure, assertThrows(ServletException.class, () ->
                filter.doFilter(request, response, (req, res) -> { throw failure; })));
        verify(alerts).send("error", "Backend HTTP 500", "Environment: test\nPOST (unmapped route)");
    }
}
