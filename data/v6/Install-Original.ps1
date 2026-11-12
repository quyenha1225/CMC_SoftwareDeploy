param(
    [string]$Database = 'sms_v6_original',
    [string]$DatabaseUser = 'root',
    [int]$DatabasePort = 3306,
    [string]$MySql = 'C:/Program Files/MySQL/MySQL Server 26.7/bin/mysql.exe',
    [switch]$StartBackend,
    [switch]$WithApplicationMigrations,
    [System.Management.Automation.PSCredential]$Credential
)
$ErrorActionPreference = 'Stop'
if ($Database -notmatch '^sms_v6_[a-zA-Z0-9_]+$') { throw 'Dùng tên database mới bắt đầu bằng sms_v6_.' }
if (!(Test-Path -LiteralPath $MySql)) { throw 'Không tìm thấy mysql.exe. Truyền đường dẫn qua -MySql.' }
if (!$Credential) { $Credential = Get-Credential -UserName $DatabaseUser -Message 'Mật khẩu MySQL: chỉ nhập trên máy' }
if (!$credential) { throw 'Chưa có thông tin kết nối.' }
$previousPassword = $env:MYSQL_PWD
$previousEncoding = $OutputEncoding
try {
    $env:MYSQL_PWD = $credential.GetNetworkCredential().Password
    $OutputEncoding = [Text.UTF8Encoding]::new($false)
    $connection = @('--host=127.0.0.1', "--port=$DatabasePort", "--user=$($credential.UserName)", '--default-character-set=utf8mb4', '--batch', '--skip-column-names')
    $existing = & $MySql @connection "--execute=SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name='$Database';"
    if ($LASTEXITCODE -ne 0) { throw 'Không kết nối được MySQL. Chưa nhập SQL.' }
    if ($existing.Trim() -ne '0') { throw "Database $Database đã tồn tại. Dừng để giữ nguyên dữ liệu; chọn một tên mới." }
    # Bản gốc không bị sửa. Bản cài chỉ đổi namespace database, không thêm bảng hoặc sửa seed.
    $parts = foreach ($name in @('01_SCHEMA_ALL.sql','02_SEED_DEMO.sql','03_QUERIES_CHECK.sql')) {
        [IO.File]::ReadAllText((Join-Path $PSScriptRoot $name)).Replace('sms_db', $Database)
    }
    $installFile = Join-Path $PSScriptRoot "install_$Database.sql"
    if (Test-Path -LiteralPath $installFile) { throw 'Bản cài đã tồn tại. Kiểm tra trước khi chạy lại.' }
    [IO.File]::WriteAllText($installFile, ($parts -join "`r`n"), [Text.UTF8Encoding]::new($false))
    [IO.File]::ReadAllText($installFile) | & $MySql @connection
    if ($LASTEXITCODE -ne 0) { throw 'Nhập SQL chưa hoàn tất. Database mới được giữ lại để kiểm tra; không tự chạy chồng.' }
    $count = & $MySql @connection "--execute=SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$Database' AND table_type='BASE TABLE';"
    if ($LASTEXITCODE -ne 0 -or $count.Trim() -ne '47') { throw "Số bảng khác 47: $count. Cần kiểm tra trước khi chạy backend." }
    Write-Host "Đã nhập SQL gốc vào ${Database}: 47 bảng. Các tài khoản seed được giữ nguyên trạng thái."
    if ($WithApplicationMigrations) {
        $registry = @'
CREATE TABLE IF NOT EXISTS schema_migrations (
    version VARCHAR(80) PRIMARY KEY,
    checksum CHAR(64) NOT NULL,
    applied_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
'@
        $registry | & $MySql @connection "--database=$Database"
        if ($LASTEXITCODE -ne 0) { throw 'Không tạo được sổ migration.' }
        foreach ($name in @('05_SECURITY_PROFILE.sql','06_COMPLETE_SEED_LINKS.sql','07_EXAM_SCHEDULES.sql','08_NORMALIZE_ACADEMIC.sql','09_COMPLETE_DEMO_DATA.sql','10_VERIFY_NORMALIZED.sql','11_MAILBOX_EMAIL_DELIVERY.sql','12_PRACTICAL_IDENTITIES.sql','13_INVOICE_REVIEW_WORKFLOW.sql','14_REVIEW_PRACTICE_DATA.sql')) {
            $migrationPath = Join-Path $PSScriptRoot $name
            [IO.File]::ReadAllText($migrationPath) | & $MySql @connection "--database=$Database"
            if ($LASTEXITCODE -ne 0) { throw "Migration $name chưa hoàn tất. Database mới được giữ để kiểm tra." }
            $checksum = (Get-FileHash -LiteralPath $migrationPath -Algorithm SHA256).Hash.ToLowerInvariant()
            & $MySql @connection "--database=$Database" "--execute=INSERT INTO schema_migrations(version,checksum) VALUES('$name','$checksum');"
            if ($LASTEXITCODE -ne 0) { throw "Không ghi được phiên bản $name." }
        }
        $violations = & $MySql @connection "--database=$Database" '--execute=SELECT (SELECT SUM(violation_count) FROM v_normalization_checks)+(SELECT SUM(violation_count) FROM v_approval_workflow_checks);'
        if ($LASTEXITCODE -ne 0 -or $violations.Trim() -ne '0') { throw 'Kiểm tra toàn vẹn chưa đạt. Không chạy backend.' }
        Write-Host 'Đã cài schema ứng dụng chuẩn hóa và seed bổ sung; kiểm tra toàn vẹn đạt.'
    }
    if ($StartBackend) {
        $env:DB_URL = "jdbc:mysql://127.0.0.1:$DatabasePort/$Database"
        $env:DB_USERNAME = $credential.UserName
        $env:DB_PASSWORD = $credential.GetNetworkCredential().Password
        Push-Location (Join-Path $PSScriptRoot '../../backend')
        try {
            $cache = Join-Path $env:USERPROFILE '.m2/repository'
            & mvn.cmd "-Dmaven.repo.local=$cache" spring-boot:run
            if ($LASTEXITCODE -ne 0) { throw 'Backend chưa chạy thành công.' }
        } finally { Pop-Location; Remove-Item Env:DB_PASSWORD -ErrorAction SilentlyContinue }
    }
} finally {
    $env:MYSQL_PWD = $previousPassword
    $OutputEncoding = $previousEncoding
}
