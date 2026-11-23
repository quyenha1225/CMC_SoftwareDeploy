package com.sms.backend.alert;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.sql.ResultSet;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
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

    @Test
    void longConsolePrioritizesExactQualityGateConditions() {
        String condition = "SonarQube Quality Gate ERROR: new_coverage actual=72.1; fails when LT 80";
        String console = "Warning: zero errors in unit test output\n".repeat(500)
                + condition + "\n" + "Pipeline cleanup output\n".repeat(500);

        assertThat(JenkinsIncidents.excerpt(console)).startsWith("501 | " + condition);
    }

    @Test
    void workerAnalyzesThenDeliversTheClaimedBuild() throws Exception {
        HttpClient http = configureWorker();
        queueIncident(null, 1);
        when(database.queryForObject(anyString(), eq(String.class), eq(1L)))
                .thenReturn("ERROR: Build failed");
        var aiResponse = response(200, """
                {"choices":[{"message":{"content":"Build failed at compilation."}}]}
                """);
        var discordResponse = response(204, "");
        when(http.send(any(HttpRequest.class), anyBodyHandler())).thenReturn(aiResponse, discordResponse);

        receiver.process();

        var updates = inOrder(database);
        updates.verify(database).update(anyString(), eq(120), eq(1L), eq(0));
        updates.verify(database).update(anyString(), eq("Build failed at compilation."), eq(1L));
        updates.verify(database).update(org.mockito.ArgumentMatchers.contains("delivered_at"), eq(1L));
        var requests = ArgumentCaptor.forClass(HttpRequest.class);
        verify(http, org.mockito.Mockito.times(2)).send(requests.capture(), anyBodyHandler());
        assertThat(requests.getAllValues().getFirst().headers().firstValue("Authorization"))
                .contains("Bearer test-ai-key");
        assertThat(requests.getAllValues().getLast().uri().getHost()).isEqualTo("discord.example.test");
    }

    @Test
    void workerKeepsSavedAnalysisWhenDiscordFails() throws Exception {
        HttpClient http = configureWorker();
        queueIncident("Previously analyzed", 1);
        var unavailable = response(503, "");
        when(http.send(any(HttpRequest.class), anyBodyHandler())).thenReturn(unavailable);

        receiver.process();

        verify(http).send(any(HttpRequest.class), anyBodyHandler());
        verify(database, org.mockito.Mockito.never()).update(
                org.mockito.ArgumentMatchers.contains("SET delivered_at"), eq(1L));
    }

    @Test
    void workerDoesNotCallUpstreamWhenAnotherWorkerClaimsTheJob() throws Exception {
        HttpClient http = configureWorker();
        queueIncident(null, 0);

        receiver.process();

        verifyNoInteractions(http);
    }

    private HttpClient configureWorker() {
        var http = mock(HttpClient.class);
        ReflectionTestUtils.setField(receiver, "http", http);
        ReflectionTestUtils.setField(receiver, "aiUrl", "https://ai.example.test/chat/completions");
        ReflectionTestUtils.setField(receiver, "aiKey", "test-ai-key");
        ReflectionTestUtils.setField(receiver, "model", "test-model");
        ReflectionTestUtils.setField(receiver, "webhook", "https://discord.example.test/webhook");
        return http;
    }

    @SuppressWarnings("unchecked")
    private void queueIncident(String analysis, int claimed) throws Exception {
        var row = mock(ResultSet.class);
        when(row.getLong("id")).thenReturn(1L);
        when(row.getString("job_url")).thenReturn(JOB);
        when(row.getLong("build_number")).thenReturn(48L);
        when(row.getString("build_result")).thenReturn("FAILURE");
        when(row.getString("analysis")).thenReturn(analysis);
        when(database.query(anyString(), any(RowMapper.class)))
                .thenAnswer(call -> List.of(call.<RowMapper<?>>getArgument(1).mapRow(row, 0)));
        when(database.update(anyString(), eq(120), eq(1L), eq(0))).thenReturn(claimed);
    }

    @SuppressWarnings("unchecked")
    private static HttpResponse<String> response(int status, String body) {
        HttpResponse<String> response = mock(HttpResponse.class);
        when(response.statusCode()).thenReturn(status);
        when(response.body()).thenReturn(body);
        return response;
    }

    private static HttpResponse.BodyHandler<String> anyBodyHandler() {
        return any();
    }
}
