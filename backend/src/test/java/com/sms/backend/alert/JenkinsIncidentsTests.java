package com.sms.backend.alert;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;

import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.server.ResponseStatusException;
import tools.jackson.databind.ObjectMapper;

class JenkinsIncidentsTests {
    private static final String TOKEN = "test-token-with-at-least-32-characters";
    private static final String JOB = "http://localhost:8080/job/SMS-CICD";
    private final JdbcTemplate database = mock(JdbcTemplate.class);
    private final JenkinsIncidents receiver = new JenkinsIncidents(database, new ObjectMapper());

    JenkinsIncidentsTests() {
        ReflectionTestUtils.setField(receiver, "ingestToken", TOKEN);
    }

    @Test
    void ingestStoresSanitizedConsoleAndNormalizesJobUrl() throws Exception {
        var request = new MockHttpServletRequest();
        request.setContent("token=fake-secret\nERROR: Build failed".getBytes(StandardCharsets.UTF_8));

        receiver.ingest(TOKEN, JOB + "///", 48, "FAILURE", request);

        verify(database).update(anyString(), eq(JOB), eq(48L), eq("FAILURE"),
                eq("[REDACTED]\nERROR: Build failed"));
    }

    @Test
    void ingestRejectsInvalidRequestsBeforeWritingToDatabase() {
        var request = new MockHttpServletRequest();

        assertRejected(HttpStatus.UNAUTHORIZED, "wrong-token", JOB, 48, "FAILURE", request);
        assertRejected(HttpStatus.BAD_REQUEST, TOKEN, "invalid-url", 48, "FAILURE", request);
        assertRejected(HttpStatus.BAD_REQUEST, TOKEN, "http://user@localhost/job/example", 48, "FAILURE", request);
        assertRejected(HttpStatus.BAD_REQUEST, TOKEN, JOB + "?unexpected=1", 48, "FAILURE", request);
        assertRejected(HttpStatus.BAD_REQUEST, TOKEN, "http://localhost/job///", 48, "FAILURE", request);
        assertRejected(HttpStatus.BAD_REQUEST, TOKEN, JOB, 0, "FAILURE", request);
        assertRejected(HttpStatus.BAD_REQUEST, TOKEN, JOB, 48, "SUCCESS", request);
        assertRejected(HttpStatus.BAD_REQUEST, TOKEN, JOB, 48, "FAILURE", request);
        request.setContent(new byte[10 * 1024 * 1024 + 1]);
        assertRejected(HttpStatus.PAYLOAD_TOO_LARGE, TOKEN, JOB, 48, "FAILURE", request);
        verifyNoInteractions(database);
    }

    private void assertRejected(HttpStatus status, String token, String job, long build, String result,
                                MockHttpServletRequest request) {
        assertThatThrownBy(() -> receiver.ingest(token, job, build, result, request))
                .isInstanceOfSatisfying(ResponseStatusException.class,
                        error -> assertThat(error.getStatusCode()).isEqualTo(status));
    }

    @Test
    void redactsCredentialsAndPreservesBuildErrors() {
        String log = """
                Authorization: Bearer abcdefghijk
                api_key="fake api credential"
                https://discord.com/api/webhooks/123/fake-webhook
                ERROR: vite build exited with code 139
                """;

        assertThat(JenkinsIncidents.redact(log))
                .doesNotContain("abcdefghijk", "fake api credential", "fake-webhook")
                .contains("ERROR: vite build exited with code 139");
    }

    @Test
    void redactsMultilineKeysAndCredentialsAfterLongLogFields() {
        String ordinary = "x".repeat(100_000);
        String log = ordinary + " " + ordinary + "_PASSWORD=masked-value\n"
                + "https://user:private-value@example.test/resource\n"
                + "-----BEGIN PRIVATE KEY-----\nprivate-key-material\n-----END PRIVATE KEY-----\n"
                + "ERROR: build failed";

        assertThat(JenkinsIncidents.redact(log))
                .startsWith(ordinary + " [REDACTED]")
                .doesNotContain("masked-value", "private-value", "private-key-material")
                .endsWith("ERROR: build failed");
    }

    @Test
    void longConsoleKeepsEarlyErrorAndFinalSummary() {
        String log = "Building frontend\nERROR: npm run build exited with code 139\n"
                + "Regular build output\n".repeat(1000) + "Finished: FAILURE";

        assertThat(JenkinsIncidents.excerpt(log))
                .contains("Building frontend", "exited with code 139", "Finished: FAILURE")
                .hasSizeLessThan(12_000);
    }
}
