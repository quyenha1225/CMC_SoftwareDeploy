package com.sms.backend.alert;

import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.net.InetSocketAddress;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;

class DiscordAlertServiceTests {
    @Test
    void sendsDiscordPayloadAndSuppressesRepeatedAlerts() throws Exception {
        var payloads = new LinkedBlockingQueue<byte[]>();
        var endpoint = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        endpoint.createContext("/webhook", exchange -> {
            try (exchange) {
                byte[] payload = exchange.getRequestBody().readAllBytes();
                exchange.sendResponseHeaders(204, -1);
                payloads.add(payload);
            }
        });
        endpoint.start();
        try {
            var service = service("  http://127.0.0.1:" + endpoint.getAddress().getPort() + "/webhook  ");
            service.send("warning", "Readiness failed", "Backend chưa sẵn sàng.");
            service.send("warning", "Readiness failed", "Backend chưa sẵn sàng.");

            var mapper = new ObjectMapper();
            JsonNode payload = receive(payloads, mapper);
            assertEquals("SMS Backend", payload.get("username").asString());
            assertEquals(0, payload.path("allowed_mentions").path("parse").size());
            JsonNode embed = payload.path("embeds").get(0);
            assertEquals("[WARNING] Readiness failed", embed.get("title").asString());
            assertEquals("Backend chưa sẵn sàng.", embed.get("description").asString());
            assertEquals(0xf1c40f, embed.get("color").asInt());

            service.send("unknown", "X".repeat(300), "Y".repeat(4_100));
            JsonNode longEmbed = receive(payloads, mapper).path("embeds").get(0);
            assertEquals(250, longEmbed.get("title").asString().length());
            assertEquals(4_000, longEmbed.get("description").asString().length());
            assertEquals(0xe74c3c, longEmbed.get("color").asInt());

            service.send("info", "Backend ready", null);
            JsonNode info = receive(payloads, mapper).path("embeds").get(0);
            assertEquals("", info.get("description").asString());
            assertNull(payloads.poll(300, TimeUnit.MILLISECONDS));
        } finally {
            endpoint.stop(0);
        }
    }

    @Test
    void missingAndInvalidConfigurationDoesNotBreakTheApplication() {
        for (String webhook : new String[] {null, "  ", "invalid URL"}) {
            assertDoesNotThrow(() -> service(webhook).send("error", "Backend down", "Check readiness"));
        }
    }

    private static JsonNode receive(LinkedBlockingQueue<byte[]> payloads, ObjectMapper mapper)
            throws InterruptedException {
        byte[] payload = payloads.poll(5, TimeUnit.SECONDS);
        assertNotNull(payload, "Expected a webhook request to the loopback test server");
        return mapper.readTree(payload);
    }

    private static DiscordAlertService service(String webhook) {
        var service = new DiscordAlertService();
        ReflectionTestUtils.setField(service, "webhookUrl", webhook);
        return service;
    }
}
