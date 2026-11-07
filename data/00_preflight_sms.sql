-- Preflight: inspect existing database BEFORE applying the revised schema.
-- In particular, CREATE TABLE IF NOT EXISTS does NOT alter an old table.
SELECT SCHEMA_NAME AS database_name
FROM information_schema.SCHEMATA WHERE SCHEMA_NAME = 'sms_db';

SELECT COUNT(*) AS existing_sms_tables
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'sms_db' AND TABLE_TYPE = 'BASE TABLE';

SELECT
  CASE
    WHEN (SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='sms_db' AND TABLE_TYPE='BASE TABLE')=0
      THEN 'NEW/EMPTY: run 01_schema_sms.sql, then 02_seed_demo_idempotent.sql'
    WHEN NOT EXISTS (SELECT 1 FROM information_schema.TABLES
                     WHERE TABLE_SCHEMA='sms_db' AND TABLE_NAME='grades')
      THEN 'PARTIAL/OTHER TABLES: inspect existing schema before applying v2'
    WHEN EXISTS (SELECT 1 FROM information_schema.COLUMNS
                 WHERE TABLE_SCHEMA='sms_db' AND TABLE_NAME='grades' AND COLUMN_NAME='sheet_id')
      THEN 'OLD SCHEMA DETECTED: BACKUP FIRST; a versioned ALTER migration is required'
    WHEN NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS
                     WHERE TABLE_SCHEMA='sms_db' AND TABLE_NAME='invoice_items'
                       AND COLUMN_NAME='credits_at_issue')
      THEN 'UNRECOGNIZED/OLD SCHEMA: BACKUP FIRST; do not rely on IF NOT EXISTS'
    ELSE 'V2 COLUMNS FOUND: you can rerun V2 schema/seed (review table structure if customized)'
  END AS preliminary_schema_state;
