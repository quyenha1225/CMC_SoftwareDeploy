package com.sms.backend.service.admission;

import static com.sms.backend.repository.Db.*;

import com.sms.backend.repository.Db;
import com.sms.backend.security.Actor;
import com.sms.backend.service.resource.Resources;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.*;
import java.nio.file.*;
import java.util.*;

@Service
public class Documents {
    private final Db db;
    private final Actor actor;
    private final Resources resources;
    private final Path directory;

    public Documents(
            Db db,
            Actor actor,
            Resources resources,
            @Value("${sms.files.directory}") String directory) {
        this.db = db;
        this.actor = actor;
        this.resources = resources;
        this.directory = Path.of(directory).toAbsolutePath().normalize();
    }

    @Transactional
    public void upload(long applicationId, String type, MultipartFile file) throws IOException {
        var u = actor.current();
        u.require("APPLICANT");
        resources.accessible("admissions", applicationId);
        var app =
                db.one("SELECT * FROM admission_applications WHERE id=? FOR UPDATE", applicationId);
        if (Db.id(app.get("applicant_user_id")) != u.id())
            throw error(403, "Không phải hồ sơ của bạn.");
        Admissions.expect(app.get("status").toString(), "DRAFT", "CHANGES_REQUESTED");
        if (db.number(
                        "SELECT COUNT(*) FROM admission_document_requirements WHERE period_id=? AND"
                                + " document_type=?",
                        app.get("period_id"),
                        type)
                != 1) throw error(400, "Loại giấy tờ không thuộc đợt nhập học.");
        if (file.isEmpty() || file.getSize() > 5 * 1024 * 1024)
            throw error(400, "Tệp phải có nội dung và không vượt 5 MB.");
        byte[] bytes = file.getBytes();
        String mime = magic(bytes);
        String key = UUID.randomUUID().toString();
        Files.createDirectories(directory);
        Path target = directory.resolve(key).normalize();
        Files.write(target, bytes, StandardOpenOption.CREATE_NEW);
        try {
            long revision =
                    db.number(
                            "SELECT COALESCE(MAX(revision_no),0)+1 FROM admission_documents WHERE"
                                    + " application_id=? AND document_type=?",
                            applicationId,
                            type);
            String name =
                    Objects.toString(file.getOriginalFilename(), "giay-to")
                            .replaceAll("[\\\\/\\r\\n\\x00]", "_");
            if (name.length() > 255) name = name.substring(name.length() - 255);
            db.insert(
                    "admission_documents",
                    map(
                            "application_id",
                            applicationId,
                            "document_type",
                            type,
                            "revision_no",
                            revision,
                            "file_name",
                            name,
                            "storage_key",
                            key,
                            "mime_type",
                            mime,
                            "size_bytes",
                            file.getSize(),
                            "status",
                            "PENDING"));
            actor.audit(u, "UPLOAD_DOCUMENT", "admission_applications", applicationId);
        } catch (RuntimeException e) {
            Files.deleteIfExists(target);
            throw e;
        }
    }

    private String magic(byte[] bytes) {
        if (bytes.length > 5
                && new String(bytes, 0, 5, java.nio.charset.StandardCharsets.US_ASCII)
                        .equals("%PDF-")) return "application/pdf";
        if (bytes.length > 3
                && (bytes[0] & 255) == 255
                && (bytes[1] & 255) == 216
                && (bytes[2] & 255) == 255) return "image/jpeg";
        if (bytes.length > 8
                && (bytes[0] & 255) == 137
                && bytes[1] == 80
                && bytes[2] == 78
                && bytes[3] == 71
                && bytes[4] == 13
                && bytes[5] == 10
                && bytes[6] == 26
                && bytes[7] == 10) return "image/png";
        throw error(400, "Chỉ nhận tệp PDF, JPEG hoặc PNG hợp lệ.");
    }

    public record Download(Path path, String name, String mime) {}

    @Transactional
    public void requestUpload(long requestId, MultipartFile file) throws IOException {
        var u = actor.current();
        var row = resources.accessible("requests", requestId);
        db.one("SELECT id FROM student_requests WHERE id=? FOR UPDATE", requestId);
        if (!u.has("CTSV", "TRAINING_OFFICE") && Db.id(row.get("student_id")) != u.student())
            throw error(403, "Không có quyền bổ sung tệp.");
        Admissions.expect(row.get("status").toString(), "PENDING", "PROCESSING");
        if (file.isEmpty() || file.getSize() > 5 * 1024 * 1024)
            throw error(400, "Tệp phải có nội dung và không vượt 5 MB.");
        byte[] bytes = file.getBytes();
        String mime = magic(bytes), key = UUID.randomUUID().toString();
        Files.createDirectories(directory);
        Path target = directory.resolve(key);
        Files.write(target, bytes, StandardOpenOption.CREATE_NEW);
        try {
            String name =
                    Objects.toString(file.getOriginalFilename(), "tai-lieu")
                            .replaceAll("[\\\\/\\r\\n\\x00]", "_");
            if (name.length() > 255) name = name.substring(name.length() - 255);
            db.insert(
                    "student_request_attachments",
                    map(
                            "request_id",
                            requestId,
                            "uploaded_by",
                            u.id(),
                            "file_name",
                            name,
                            "storage_key",
                            key,
                            "mime_type",
                            mime,
                            "size_bytes",
                            file.getSize()));
            actor.audit(u, "UPLOAD_ATTACHMENT", "student_requests", requestId);
        } catch (RuntimeException e) {
            Files.deleteIfExists(target);
            throw e;
        }
    }

    public Download requestDownload(long id) {
        var u = actor.current();
        var doc = db.one("SELECT * FROM student_request_attachments WHERE id=?", id);
        resources.accessible("requests", Db.id(doc.get("request_id")));
        String key = doc.get("storage_key").toString();
        if (!key.matches("[a-f0-9-]{36}")) throw error(404, "Tệp chưa có trong kho riêng.");
        Path path = directory.resolve(key).normalize();
        if (!path.startsWith(directory) || !Files.isRegularFile(path))
            throw error(404, "Không tìm thấy tệp.");
        actor.audit(u, "DOWNLOAD_ATTACHMENT", "student_request_attachments", id);
        return new Download(path, doc.get("file_name").toString(), doc.get("mime_type").toString());
    }

    public Download download(long id) {
        var u = actor.current();
        var doc = db.one("SELECT * FROM admission_documents WHERE id=?", id);
        resources.accessible("admissions", Db.id(doc.get("application_id")));
        String key = doc.get("storage_key").toString();
        if (!key.matches("[a-f0-9-]{36}"))
            throw error(404, "Tệp chưa được chuyển vào kho riêng của hệ thống.");
        Path file = directory.resolve(key).normalize();
        if (!file.startsWith(directory) || !Files.isRegularFile(file))
            throw error(404, "Không tìm thấy tệp.");
        actor.audit(u, "DOWNLOAD_DOCUMENT", "admission_documents", id);
        return new Download(file, doc.get("file_name").toString(), doc.get("mime_type").toString());
    }
}
