package com.sms.infrastructure;

import org.flywaydb.core.Flyway;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Set;

/** Minimal MySQL-only Flyway runner; no comparison/cloud/.NET toolchain. */
public final class SchemaMigration {
    private SchemaMigration() {}

    public static void main(String[] args) throws Exception {
        String action = args.length == 0 ? "migrate" : args[0];
        if (!Set.of("migrate", "validate", "info").contains(action)) {
            throw new IllegalArgumentException("Only migrate, validate and info are allowed.");
        }
        boolean demo = Boolean.parseBoolean(System.getenv().getOrDefault("SMS_SEED_DEMO", "false"));
        String environment = System.getenv().getOrDefault("SMS_ENVIRONMENT", "local");
        if (demo && !Set.of("local", "test").contains(environment)) {
            throw new IllegalStateException("Demo seed is forbidden outside local/test.");
        }
        String password = Files.readString(Path.of("/run/secrets/migrator_password")).strip();
        String[] locations = demo
                ? new String[]{"filesystem:/migrations/core", "filesystem:/migrations/demo"}
                : new String[]{"filesystem:/migrations/core"};
        Flyway flyway = Flyway.configure()
                .dataSource(System.getenv("FLYWAY_URL"), System.getenv("FLYWAY_USER"), password)
                .locations(locations)
                .connectRetries(60)
                .cleanDisabled(true)
                .baselineOnMigrate(false)
                .validateMigrationNaming(true)
                .load();
        switch (action) {
            case "migrate" -> flyway.migrate();
            case "validate" -> flyway.validate();
            case "info" -> {
                for (var migration : flyway.info().all()) {
                    System.out.println(migration.getVersion() + " " + migration.getState());
                }
            }
            default -> throw new IllegalStateException("Unsupported action.");
        }
    }
}
