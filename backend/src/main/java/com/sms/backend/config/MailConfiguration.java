package com.sms.backend.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.*;
import org.springframework.mail.javamail.*;

@Configuration
@org.springframework.scheduling.annotation.EnableScheduling
public class MailConfiguration {
    @Bean
    JavaMailSender recoveryMailSender(
            @Value("${sms.mail.smtp.host}") String host,
            @Value("${sms.mail.smtp.port}") int port,
            @Value("${sms.mail.smtp.username}") String username,
            @Value("${sms.mail.smtp.password}") String password,
            @Value("${sms.mail.smtp.timeout-ms}") int timeout) {
        if (port < 1 || port > 65535 || timeout < 100)
            throw new IllegalArgumentException("Invalid SMTP port/timeout");
        var sender = new JavaMailSenderImpl();
        sender.setHost(host);
        sender.setPort(port);
        sender.setUsername(username);
        sender.setPassword(password);
        sender.setDefaultEncoding("UTF-8");
        var props = sender.getJavaMailProperties();
        props.setProperty("mail.smtp.auth", "true");
        props.setProperty("mail.smtp.starttls.enable", "true");
        props.setProperty("mail.smtp.starttls.required", "true");
        props.setProperty("mail.smtp.ssl.checkserveridentity", "true");
        props.setProperty("mail.smtp.connectiontimeout", String.valueOf(timeout));
        props.setProperty("mail.smtp.timeout", String.valueOf(timeout));
        props.setProperty("mail.smtp.writetimeout", String.valueOf(timeout));
        return sender;
    }
}
