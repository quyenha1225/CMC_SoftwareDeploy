package com.sms.backend;

import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.cookie;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;
import tools.jackson.databind.ObjectMapper;

@SpringBootTest
@ActiveProfiles("test")
class OperationsSecurityTests {
    @Autowired private WebApplicationContext context;
    private MockMvc mvc;

    @BeforeEach
    void configure() {
        mvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();
    }

    @Test
    void healthIsAvailableWithoutOpeningProtectedBusinessApis() throws Exception {
        mvc.perform(get("/actuator/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("UP"))
                .andExpect(jsonPath("$.components").doesNotExist());
        mvc.perform(get("/api/hello")).andExpect(status().isUnauthorized());
    }

    @Test
    void metricsAreNotPublicOnTheApplicationPort() throws Exception {
        mvc.perform(get("/actuator/prometheus")).andExpect(status().isUnauthorized());
    }

    @Test
    void jenkinsIngestionRequiresCsrfAndItsOwnToken() throws Exception {
        var request = post("/api/ops/jenkins-incidents")
                .contentType("text/plain")
                .header("X-Jenkins-Job", "http://localhost:8080/job/SMS-CICD")
                .header("X-Jenkins-Build", "48")
                .header("X-Jenkins-Result", "FAILURE")
                .content("Build failed");
        mvc.perform(request).andExpect(status().isForbidden());
        var response = mvc.perform(get("/api/auth/csrf")).andExpect(status().isOk())
                .andReturn().getResponse();
        var csrf = new ObjectMapper().readTree(response.getContentAsString());
        mvc.perform(request.cookie(response.getCookie("XSRF-TOKEN"))
                .header(csrf.path("headerName").asText(), csrf.path("token").asText()))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void csrfEndpointReturnsTokenAndKeepsCookieHttpOnly() throws Exception {
        mvc.perform(get("/api/auth/csrf"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.headerName").value("X-XSRF-TOKEN"))
                .andExpect(jsonPath("$.token").isNotEmpty())
                .andExpect(cookie().httpOnly("XSRF-TOKEN", true));
    }
}
