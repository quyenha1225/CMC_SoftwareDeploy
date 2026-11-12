package com.sms.backend.service.student;

import static com.sms.backend.repository.Db.*;

import com.sms.backend.repository.Db;
import com.sms.backend.security.Actor;
import com.sms.backend.service.admission.Documents;
import com.sms.backend.service.resource.Resources;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import org.springframework.web.multipart.MultipartFile;

import java.awt.image.BufferedImage;
import java.io.*;
import java.nio.file.*;
import java.util.*;

import javax.imageio.*;
import javax.imageio.stream.ImageInputStream;

@Service
public class StudentPhotos {
    private final Db db;
    private final Actor actor;
    private final Resources resources;
    private final Path directory;

    public StudentPhotos(
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
    public void upload(long id, MultipartFile file) throws IOException {
        var user = actor.current();
        resources.accessible("students", id);
        if (!user.has("CTSV", "TRAINING_OFFICE", "PRINCIPAL")
                && (!user.has("STUDENT") || user.student() != id))
            throw error(403, "Không có quyền đổi ảnh sinh viên này.");
        db.one("SELECT id FROM students WHERE id=? FOR UPDATE", id);
        if (file.isEmpty() || file.getSize() > 5 * 1024 * 1024)
            throw error(400, "Ảnh phải có nội dung và không vượt 5 MB.");
        BufferedImage image;
        try (ImageInputStream input = ImageIO.createImageInputStream(file.getInputStream())) {
            var readers = ImageIO.getImageReaders(input);
            if (!readers.hasNext()) throw error(400, "Chỉ nhận ảnh JPEG hoặc PNG hợp lệ.");
            var reader = readers.next();
            try {
                reader.setInput(input);
                String format = reader.getFormatName();
                if (!Set.of("JPEG", "png", "PNG", "jpeg").contains(format))
                    throw error(400, "Chỉ nhận ảnh JPEG hoặc PNG.");
                int width = reader.getWidth(0), height = reader.getHeight(0);
                if (width < 32 || height < 32 || (long) width * height > 16000000)
                    throw error(400, "Ảnh tối thiểu 32×32 và tối đa 16 triệu điểm ảnh.");
                image = reader.read(0);
            } finally {
                reader.dispose();
            }
        }
        // Re-encode to remove embedded metadata and arbitrary trailing content.
        int width = Math.min(800, image.getWidth()),
                height = Math.max(1, (int) ((long) image.getHeight() * width / image.getWidth()));
        var clean = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
        var graphics = clean.createGraphics();
        try {
            graphics.setColor(java.awt.Color.WHITE);
            graphics.fillRect(0, 0, width, height);
            graphics.drawImage(image, 0, 0, width, height, null);
        } finally {
            graphics.dispose();
        }
        Files.createDirectories(directory);
        String key = UUID.randomUUID().toString();
        Path path = directory.resolve(key);
        try (var output = Files.newOutputStream(path, StandardOpenOption.CREATE_NEW)) {
            if (!ImageIO.write(clean, "jpg", output))
                throw new IOException("Image writer unavailable");
        }
        TransactionSynchronizationManager.registerSynchronization(
                new TransactionSynchronization() {
                    public void afterCompletion(int status) {
                        if (status != STATUS_COMMITTED)
                            try {
                                Files.deleteIfExists(path);
                            } catch (IOException ignored) {
                            }
                    }
                });
        var old = db.rows("SELECT storage_key FROM student_profile_photos WHERE student_id=?", id);
        if (old.isEmpty())
            db.run(
                    "INSERT INTO"
                            + " student_profile_photos(student_id,storage_key,mime_type,updated_by)"
                            + " VALUES(?,?,'image/jpeg',?)",
                    id,
                    key,
                    user.id());
        else
            db.run(
                    "UPDATE student_profile_photos SET"
                        + " storage_key=?,mime_type='image/jpeg',updated_by=?,updated_at=CURRENT_TIMESTAMP"
                        + " WHERE student_id=?",
                    key,
                    user.id(),
                    id);
        if (!old.isEmpty()) {
            String previous = old.getFirst().get("storage_key").toString();
            if (previous.matches("[a-f0-9-]{36}"))
                TransactionSynchronizationManager.registerSynchronization(
                        new TransactionSynchronization() {
                            public void afterCommit() {
                                try {
                                    Files.deleteIfExists(directory.resolve(previous));
                                } catch (IOException ignored) {
                                }
                            }
                        });
        }
        actor.audit(user, "UPLOAD_PROFILE_PHOTO", "students", id);
    }

    public Documents.Download photo(long id) {
        resources.accessible("students", id);
        var row =
                db.one(
                        "SELECT storage_key,mime_type FROM student_profile_photos WHERE"
                                + " student_id=?",
                        id);
        String key = row.get("storage_key").toString();
        if (!key.matches("[a-f0-9-]{36}")) throw error(404, "Chưa có ảnh hồ sơ.");
        Path path = directory.resolve(key).normalize();
        if (!path.startsWith(directory) || !Files.isRegularFile(path))
            throw error(404, "Không tìm thấy ảnh.");
        return new Documents.Download(path, "portrait.jpg", row.get("mime_type").toString());
    }
}
