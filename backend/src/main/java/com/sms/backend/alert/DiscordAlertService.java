package com.sms.backend.alert;

import tools.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Locale;

@Service
public class DiscordAlertService {

    private static final Logger log = LoggerFactory.getLogger(DiscordAlertService.class);

    private static final Map<String, Integer> COLORS = Map.of(
            "info", 0x3498db,
            "warning", 0xf1c40f,
            "error", 0xe74c3c,
            "success", 0x2ecc71);

    /** Cùng một lỗi chỉ gửi lại sau khoảng này để tránh spam / dính rate limit của Discord. */
    private static final Duration DEBOUNCE = Duration.ofMinutes(1);

    private final HttpClient client = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(5))
            .build();
    private final ObjectMapper mapper = new ObjectMapper();
    private final Map<String, Instant> lastSent = new HashMap<>();

    @Value("${discord.webhook-url:}")
    private String webhookUrl;

    public void send(String level, String title, String message) {
        if (webhookUrl == null || webhookUrl.isBlank()) {
            return; // chưa cấu hình webhook -> bỏ qua
        }
        String url = webhookUrl.trim();

        String key = level + "|" + title + "|" + message;
        Instant now = Instant.now();
        synchronized (lastSent) {
            lastSent.entrySet().removeIf(entry -> !entry.getValue().plus(DEBOUNCE).isAfter(now));
            if (lastSent.containsKey(key) || lastSent.size() >= 500) {
                return;
            }
            lastSent.put(key, now);
        }

        try {
            Map<String, Object> embed = new HashMap<>();
            embed.put("title", cut("[" + level.toUpperCase(Locale.ROOT) + "] " + title, 250));
            embed.put("description", cut(message, 4000));
            embed.put("color", COLORS.getOrDefault(level, COLORS.get("error")));
            embed.put("timestamp", now.toString());

            String json = mapper.writeValueAsString(Map.of(
                    "username", "SMS Backend",
                    "allowed_mentions", Map.of("parse", List.of()),
                    "embeds", List.of(embed)));

            HttpRequest req = HttpRequest.newBuilder(URI.create(url))
                    .timeout(Duration.ofSeconds(5))
                    .header("Content-Type", "application/json; charset=utf-8")
                    .POST(HttpRequest.BodyPublishers.ofString(json))
                    .build();

            // Gửi bất đồng bộ để không làm chậm request chính
            client.sendAsync(req, HttpResponse.BodyHandlers.discarding())
                    .thenAccept(res -> {
                        if (res.statusCode() >= 300) {
                            log.warn("Discord webhook trả về HTTP {}", res.statusCode());
                        }
                    })
                    .exceptionally(ex -> {
                        log.warn("Không gửi được cảnh báo Discord: {}", ex.getClass().getSimpleName());
                        return null;
                    });
        } catch (Exception e) {
            // Lỗi khi gửi cảnh báo không được làm sập app
            log.warn("Không gửi được cảnh báo Discord: {}", e.getClass().getSimpleName());
        }
    }

    private static String cut(String s, int max) {
        if (s == null) return "";
        return s.length() > max ? s.substring(0, max) : s;
    }
}
