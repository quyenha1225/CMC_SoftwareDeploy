package com.sms.backend.alert;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Pattern;

record JenkinsEvidence(Map<String, Set<String>> stages, List<String> facts, List<String> warnings,
                       List<String> metadata, String category, String root, String limitations) {
    private static final Pattern STAGE = Pattern.compile(
            "CI stage (started|passed|failed|unstable|aborted): (.+)|Stage \"([^\"]+)\" skipped (.+)");
    private static final Pattern WRAPPER = Pattern.compile(
            "(?i)script returned exit code|CI failure: Operation failed: docker|CI command failed|Process completed with exit code");
    private static final Pattern WARNING = Pattern.compile("(?i)\\bwarning[s]?\\b|\\[warn| \\| warn ");
    private static final Pattern TIMESTAMP = Pattern.compile("^\\[[0-9T:.+Z-]+]\\s*");
    private static final Pattern COMMAND_EXIT = Pattern.compile("CI finish: .* exit=(?!0$)-?[0-9]+$");
    private static final Map<String, Pattern> RULES = new LinkedHashMap<>();
    static {
        rule("SONARQUBE_ERROR", "SonarQube Quality Gate(?: ERROR:|: (?!OK))|Quality gate.*(?:ERROR|FAILED)");
        rule("SECURITY_FAILURE", "Security gate failed|CI security finding|Scanner did not produce|Dependency audit failed|Sensitive runtime files");
        rule("DOCKER_ERROR", "Error response from daemon|Cannot connect to the Docker daemon|failed to solve|port is already allocated|container .* (?:unhealthy|exited)");
        rule("DATABASE_ERROR", "FlywayException|Migration .* failed|SQLState|SQL State\\s*:|SQLSyntaxErrorException|Core test schema already exists|Restore (?:row mismatch|integrity failed)|Persistence check failed|MySQL business workflow failed");
        rule("DEPENDENCY_ERROR", "Could not resolve (?:dependencies|artifact)|npm (?:ERR!|error) code (?:ERESOLVE|E404|EAI_AGAIN)|Failed to collect dependencies");
        rule("TEST_FAILURE", "CI test failure:|Tests run:.*(?:Failures|Errors): [1-9]|AssertionError|FAIL\\s+\\S+\\.(?:test|spec)\\.|Browser integration failed");
        rule("CODE_ERROR", "COMPILATION ERROR|cannot find symbol|\\.java:\\[\\d+,\\d+\\]|\\d+:\\d+\\s+error\\s|ESLint found too many warnings|Transform failed|SyntaxError|RollupError");
        rule("DEPLOYMENT_ERROR", "Host key verification failed|Permission denied \\(publickey\\)|Smoke failed|rollback failed|deployment failed");
        rule("CONFIGURATION_ERROR", "config(?:uration)? (?:is )?invalid|no configuration file provided|yaml: line|credential.*(?:not found|missing)");
        rule("ENVIRONMENT_ERROR", "is required|command not found|is not recognized as|no space left on device|OutOfMemoryError");
        rule("TIMEOUT", "TimeoutExpired|timed out|timeout has been exceeded|Cancelling nested steps due to timeout");
    }

    private static void rule(String category, String pattern) {
        RULES.put(category, Pattern.compile(pattern, Pattern.CASE_INSENSITIVE));
    }

    static JenkinsEvidence from(String console, String result) {
        var stages = new LinkedHashMap<String, Set<String>>();
        var facts = new LinkedHashSet<String>();
        var warnings = new LinkedHashSet<String>();
        var metadata = new ArrayList<String>();
        var detail = new LinkedHashSet<String>();
        String category = "UNKNOWN";
        var candidates = new ArrayList<Candidate>();
        var active = new LinkedHashSet<String>();
        boolean truncated = false;
        String previous = "";
        var checks = new LinkedHashMap<String, String>();
        for (String raw : (console == null ? "" : console).split("\\R")) {
            String line = TIMESTAMP.matcher(raw).replaceFirst("").strip();
            var stage = STAGE.matcher(line);
            if (stage.matches()) {
                String name = stage.group(2) == null ? stage.group(3) : stage.group(2);
                String status = stage.group(1) == null
                        ? (stage.group(4).contains("earlier failure") ? "NOT RUN" : "SKIPPED")
                        : switch (stage.group(1)) {
                            case "passed" -> "PASS";
                            case "failed" -> "FAIL";
                            case "unstable" -> "UNSTABLE";
                            case "aborted" -> "ABORTED";
                            default -> "STARTED";
                        };
                if ("STARTED".equals(status)) active.add(name);
                else active.remove(name);
                if (stages.size() < 60 || stages.containsKey(name)) {
                    var entries = stages.computeIfAbsent(cut(name, 100), ignored -> new LinkedHashSet<>());
                    if (!"STARTED".equals(status)) {
                        entries.remove("STARTED");
                        entries.add(status);
                    } else if (entries.isEmpty()) {
                        entries.add(status);
                    }
                }
            } else if (line.startsWith("CI build metadata:") && metadata.isEmpty()) {
                metadata.add(cut(line.substring("CI build metadata:".length()).strip(), 650));
            } else if (line.startsWith("CI evidence limitation:")) {
                truncated = true;
            } else if (line.startsWith("CI check:")) {
                if (active.size() == 1) checks.put(active.getFirst(), cut(line, 550));
            } else if (line.startsWith("CI report:") || line.startsWith("CI test failure:")
                    || line.startsWith("CI security finding:")) {
                add(detail, line, 12);
            }
            String lower = line.toLowerCase(java.util.Locale.ROOT);
            boolean warning = WARNING.matcher(line).find() && !line.contains("ESLint found too many warnings");
            if (warning && !lower.startsWith("ci test failure:") && !lower.startsWith("ci security finding:")) {
                add(warnings, line, 5);
            } else if (!line.startsWith("CI stage ") && !line.startsWith("CI incident")
                    && !line.startsWith("AI incident") && !line.startsWith("CI build metadata:")) {
                for (var rule : RULES.entrySet()) {
                    if (rule.getValue().matcher(line).find()) {
                        if (candidates.size() < 250) {
                            String stageName = active.size() == 1 ? active.getFirst() : "";
                            candidates.add(new Candidate(rule.getKey(), cut(line, 550), stageName,
                                    checks.getOrDefault(stageName, "")));
                        }
                        add(facts, line, 18);
                        break;
                    }
                }
                if (line.startsWith("Caused by:") || line.contains("Caused by:")
                        || line.startsWith("[ERROR]") || line.startsWith("CI failure:")
                        || WRAPPER.matcher(line).find() || COMMAND_EXIT.matcher(line).matches()
                        || lower.contains("failed in branch") || lower.startsWith("aborted by ")) {
                    if (!previous.isBlank() && !previous.startsWith("[Pipeline]") && facts.size() < 12) {
                        add(facts, previous, 18);
                    }
                    add(facts, line, 18);
                }
            }
            previous = line;
        }
        var relevant = candidates.stream().filter(candidate -> {
            var states = stages.get(candidate.stage());
            return states == null || !states.contains("PASS");
        }).toList();
        var root = relevant.stream().filter(candidate -> stages.getOrDefault(candidate.stage(), Set.of())
                .contains("FAIL")).findFirst().orElse(relevant.isEmpty() ? null : relevant.getFirst());
        if (root != null && root.line().contains("COMPILATION ERROR")) {
            var origin = root;
            root = relevant.stream().filter(candidate -> candidate.stage().equals(origin.stage())
                    && candidate.category().equals("CODE_ERROR") && !candidate.line().contains("COMPILATION ERROR"))
                    .findFirst().orElse(origin);
        }
        if (root != null) category = root.category();
        if ("ABORTED".equals(result) && !"TIMEOUT".equals(category)) {
            category = "ABORTED";
        } else if ("NOT_BUILT".equals(result)) {
            category = "UNKNOWN";
        }
        boolean identified = root != null && !"NOT_BUILT".equals(result) && !"ABORTED".equals(category);
        var evidence = new LinkedHashSet<String>();
        if (identified) {
            evidence.add(root.line());
            if (!root.check().isBlank() && !root.stage().isBlank()) evidence.add(root.check());
        }
        var coveredStages = new LinkedHashSet<String>();
        for (var candidate : relevant) {
            if (!candidate.stage().isBlank() && coveredStages.add(candidate.stage()) && evidence.size() < 6) {
                evidence.add(candidate.line());
            }
        }
        evidence.addAll(detail);
        evidence.addAll(facts);
        var limitations = new ArrayList<String>();
        if (!identified) limitations.add("Chưa xác định được nguyên nhân gốc từ bằng chứng hiện có.");
        if (truncated || facts.size() == 18 || detail.size() == 12) {
            limitations.add("Bằng chứng đã được giới hạn dung lượng.");
        }
        if (stages.isEmpty()) limitations.add("Thiếu dữ liệu trạng thái stage.");
        return new JenkinsEvidence(stages, List.copyOf(evidence), List.copyOf(warnings),
                List.copyOf(metadata), category, identified ? root.line() : "", String.join(" ", limitations));
    }

    String affectedStages() {
        return stages.entrySet().stream()
                .filter(entry -> entry.getValue().stream().anyMatch(Set.of("FAIL", "UNSTABLE", "ABORTED")::contains))
                .map(entry -> String.join("/", entry.getValue()) + " · " + entry.getKey())
                .collect(java.util.stream.Collectors.joining("\n"));
    }

    String stageSummary() {
        var lines = new ArrayList<String>();
        stages.forEach((stage, statuses) -> lines.add(String.join("/", statuses) + " · " + stage));
        return lines.isEmpty() ? "Chưa có dữ liệu." : String.join("\n", lines);
    }

    String rootEvidence() {
        return root.isBlank() ? "Chưa có dòng lỗi cụ thể." : root;
    }

    String confidence() {
        return switch (category) {
            case "UNKNOWN", "ABORTED" -> "LOW · thiếu bằng chứng xác định nguyên nhân kỹ thuật.";
            default -> "MEDIUM · có dấu hiệu cụ thể trong log, cần xác nhận nguyên nhân.";
        };
    }

    String remediation() {
        return switch (category) {
            case "DOCKER_ERROR" -> "1. Kiểm tra lỗi Docker trong trích đoạn trên agent Jenkins.\n2. Nếu lỗi là Access is denied, kiểm tra quyền đọc đường dẫn mount bằng tài khoản Docker Desktop.\n3. Chạy lại bước Docker/MySQL bị lỗi và xác nhận container healthy.";
            case "TEST_FAILURE" -> "1. Mở báo cáo JUnit và tìm test được nêu.\n2. Sửa lỗi từ assertion hoặc stack trace đầu tiên.\n3. Chạy lại test liên quan và toàn bộ stage.";
            case "SONARQUBE_ERROR" -> "1. Mở Quality Gate của build và đối chiếu điều kiện đã báo.\n2. Sửa mã hoặc bổ sung test để đạt ngưỡng hiện hành.\n3. Chạy lại phân tích.";
            case "DATABASE_ERROR" -> "1. Kiểm tra migration, SQL hoặc bước restore được nêu.\n2. Xác nhận bằng cơ sở dữ liệu CI mới và chạy lại bước thất bại.";
            case "CODE_ERROR" -> "1. Mở file và vị trí được nêu trong trích đoạn.\n2. Sửa lỗi biên dịch, lint hoặc build đầu tiên.\n3. Chạy lại công cụ đã báo lỗi.";
            case "DEPENDENCY_ERROR" -> "1. Đối chiếu tên gói, phiên bản và lỗi registry trong console.\n2. Kiểm tra manifest, lockfile hoặc kết nối được nêu.\n3. Chạy lại bước tải dependency.";
            case "SECURITY_FAILURE" -> "1. Mở báo cáo scanner của build để xác định finding hay scanner lỗi.\n2. Sửa finding hoặc lỗi thực thi đã ghi.\n3. Chạy lại security gate.";
            case "DEPLOYMENT_ERROR" -> "1. Đối chiếu bước deploy hoặc smoke check trong console.\n2. Kiểm tra đích và kết quả rollback nếu có.\n3. Xác minh health trước khi thử lại theo quy trình deploy.";
            case "ABORTED" -> "Kiểm tra lý do hủy trong console Jenkins trước khi chạy lại.";
            default -> "1. Mở Console và đối chiếu dòng lỗi với stage và báo cáo đã ghi.\n2. Chạy lại bước liên quan sau khi kiểm tra nguyên nhân.";
        };
    }

    private record Candidate(String category, String line, String stage, String check) {}

    private static void add(Set<String> items, String line, int max) {
        if (items.size() < max) items.add(cut(line, 550));
    }

    static String cut(String value, int limit) {
        if (value.length() <= limit) return value;
        int end = limit - 1;
        if (Character.isHighSurrogate(value.charAt(end - 1))) end--;
        return value.substring(0, end) + "…";
    }
}
