param(
    [string]$Database = 'sms_v6_original',
    [string]$DatabaseUser = 'root',
    [int]$DatabasePort = 3306
)
$ErrorActionPreference = 'Stop'
if ($Database -notmatch '^[a-zA-Z0-9_]+$') { throw 'Tên database không hợp lệ.' }
# Dùng cấu hình đã lưu khi không yêu cầu kết nối khác.
$useLocalConfig = (Test-Path -LiteralPath (Join-Path $PSScriptRoot '.env.local')) -and $PSBoundParameters.Count -eq 0
$previousDbUrl = $env:DB_URL
$previousDbUser = $env:DB_USERNAME
$previousDbPassword = $env:DB_PASSWORD
if (!$useLocalConfig) {
    $credential = Get-Credential -UserName $DatabaseUser -Message 'Nhập mật khẩu MySQL trên máy (không gửi vào chat)'
    if (!$credential) { throw 'Chưa có thông tin kết nối.' }
    $env:DB_URL = "jdbc:mysql://127.0.0.1:$DatabasePort/$Database"
    $env:DB_USERNAME = $credential.UserName
    $env:DB_PASSWORD = $credential.GetNetworkCredential().Password
}
try {
    Push-Location $PSScriptRoot
    $cache = Join-Path $env:USERPROFILE '.m2/repository'
    & mvn.cmd "-Dmaven.repo.local=$cache" spring-boot:run
    if ($LASTEXITCODE -ne 0) { throw 'Backend chưa chạy được. Kiểm tra database V6 và thông tin đăng nhập MySQL.' }
} finally {
    Pop-Location
    $env:DB_URL = $previousDbUrl
    $env:DB_USERNAME = $previousDbUser
    $env:DB_PASSWORD = $previousDbPassword
}
