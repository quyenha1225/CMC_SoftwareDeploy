package com.sms.backend.alert;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class JenkinsIncidentsTests {
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
    void longConsoleKeepsEarlyErrorAndFinalSummary() {
        String log = "Building frontend\nERROR: npm run build exited with code 139\n"
                + "Regular build output\n".repeat(1000) + "Finished: FAILURE";

        assertThat(JenkinsIncidents.excerpt(log))
                .contains("Building frontend", "exited with code 139", "Finished: FAILURE")
                .hasSizeLessThan(12_000);
    }
}
