package com.sms.backend.exception;

import org.springframework.dao.*;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.Map;

@RestControllerAdvice
public class ApiErrors {
    @ExceptionHandler(ResponseStatusException.class)
    ResponseEntity<?> status(ResponseStatusException error) {
        return ResponseEntity.status(error.getStatusCode())
                .body(
                        Map.of(
                                "message",
                                error.getReason() == null
                                        ? "Yêu cầu không hợp lệ."
                                        : error.getReason()));
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    ResponseEntity<?> integrity() {
        return ResponseEntity.status(409)
                .body(
                        Map.of(
                                "message",
                                "Dữ liệu trùng mã, thiếu liên kết hoặc không thỏa ràng buộc V6."));
    }

    @ExceptionHandler(DataAccessException.class)
    ResponseEntity<?> database() {
        return ResponseEntity.status(503)
                .body(
                        Map.of(
                                "message",
                                "Database chưa sẵn sàng. Kiểm tra kết nối và cài đặt SQL V6."));
    }

    @ExceptionHandler(IllegalArgumentException.class)
    ResponseEntity<?> invalid() {
        return ResponseEntity.badRequest().body(Map.of("message", "Dữ liệu đầu vào không hợp lệ."));
    }
}
