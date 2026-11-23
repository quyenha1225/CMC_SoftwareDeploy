package com.sms.backend.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.concurrent.ThreadPoolTaskScheduler;

@Configuration
public class JenkinsIncidentConfiguration {
    @Bean(defaultCandidate = false)
    ThreadPoolTaskScheduler jenkinsIncidentScheduler() {
        var scheduler = new ThreadPoolTaskScheduler();
        scheduler.setThreadNamePrefix("jenkins-incident-");
        return scheduler;
    }
}
