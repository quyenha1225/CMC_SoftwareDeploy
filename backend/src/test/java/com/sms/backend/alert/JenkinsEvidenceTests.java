package com.sms.backend.alert;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

class JenkinsEvidenceTests {
    @ParameterizedTest
    @CsvSource(delimiter = '|', value = {
        "CODE_ERROR|[ERROR] /src/Billing.java:[29,12] cannot find symbol",
        "CODE_ERROR|5:12 error unexpected token",
        "CODE_ERROR|ESLint found too many warnings (maximum: 0)",
        "TEST_FAILURE|Tests run: 12, Failures: 1, Errors: 0",
        "TEST_FAILURE|CI test failure: Frontend JUnit Checkout.test.jsx",
        "DOCKER_ERROR|Error response from daemon: mount Access is denied",
        "DOCKER_ERROR|ERROR: failed to solve: Dockerfile:27",
        "DATABASE_ERROR|FlywayException: Migration V7 failed",
        "DATABASE_ERROR|Restore row mismatch: payments",
        "SONARQUBE_ERROR|SonarQube Quality Gate ERROR: new_coverage actual=72.1; fails when LT 80",
        "SECURITY_FAILURE|CI security finding: image CVE-TEST 1.2 CRITICAL 1.3",
        "SECURITY_FAILURE|Scanner did not produce a complete JSON report",
        "DEPLOYMENT_ERROR|Host key verification failed",
        "DEPLOYMENT_ERROR|Smoke failed: /healthz",
        "DEPENDENCY_ERROR|Could not resolve dependencies for project",
        "CONFIGURATION_ERROR|configuration invalid",
        "ENVIRONMENT_ERROR|node: command not found",
        "TIMEOUT|Cancelling nested steps due to timeout"
    })
    void preservesObservedTechnologySpecificDetails(String category, String line) {
        var evidence = JenkinsEvidence.from(line + "\nERROR: script returned exit code 1", "FAILURE");
        assertThat(evidence.category()).isEqualTo(category);
        assertThat(evidence.rootEvidence()).isEqualTo(line);
    }

    @Test
    void preservesDockerMountFailureInLongConsoleAndIgnoresWarningsAndCleanup() {
        String original = "Error response from daemon: CreateFile mysql_root_password: Access is denied.";
        String console = "CI stage started: Prepare\n[ERROR] COMPILATION ERROR (fixture)\n"
                + "CI stage passed: Prepare\n"
                + "344 ESLint warnings\n".repeat(1500)
                + "SonarQube Quality Gate: OK\n"
                + "CI stage started: MySQL Integration Tests\n"
                + "CI check: Start database containers\n" + original + "\n"
                + "CI stage failed: MySQL Integration Tests\n"
                + "Stage \"Security Scan\" skipped due to earlier failure(s)\n"
                + "Stage \"Deploy Server SSH\" skipped due to when conditional\n"
                + "CI evidence limitation: console exceeded budget\n"
                + "FlywayException: cleanup failed\n"
                + "Cleanup output\n".repeat(1500);
        var evidence = JenkinsEvidence.from(console, "FAILURE");
        assertThat(evidence.rootEvidence()).isEqualTo(original);
        assertThat(evidence.facts()).contains("CI check: Start database containers");
        assertThat(evidence.stageSummary()).contains("PASS", "NOT RUN", "SKIPPED");
        assertThat(evidence.affectedStages()).contains("MySQL Integration Tests").doesNotContain("Security Scan");
        assertThat(evidence.limitations()).isNotBlank();
    }

    @Test
    void preservesFailuresFromBothParallelStages() {
        var evidence = JenkinsEvidence.from("""
                CI stage started: Backend Test
                CI stage started: Frontend Test
                [ERROR] Checkout.java:[5,7] cannot find symbol
                FAIL checkout.test.jsx
                CI stage failed: Frontend Test
                CI stage failed: Backend Test
                """, "FAILURE");
        assertThat(evidence.affectedStages()).contains("Backend Test", "Frontend Test");
        assertThat(evidence.facts()).contains("FAIL checkout.test.jsx", "[ERROR] Checkout.java:[5,7] cannot find symbol");
    }

    @ParameterizedTest
    @CsvSource({"SUCCESS,UNKNOWN", "FAILURE,UNKNOWN", "UNSTABLE,UNKNOWN", "ABORTED,ABORTED", "NOT_BUILT,UNKNOWN"})
    void genericOutputNeverInventsACause(String result, String category) {
        var evidence = JenkinsEvidence.from("Only inconclusive output\n344 ESLint warnings", result);
        assertThat(evidence.category()).isEqualTo(category);
        assertThat(evidence.facts()).isEmpty();
        assertThat(evidence.warnings()).containsExactly("344 ESLint warnings");
        assertThat(evidence.limitations()).isNotBlank();
    }
}
