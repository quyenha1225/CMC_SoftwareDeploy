param([string]$Database = 'sms_v6')
$ErrorActionPreference = 'Stop'
if ($Database -notmatch '^sms_v6(?:_[a-zA-Z0-9]+)*$') {
    throw 'Chỉ tạo script cho database mới có tên sms_v6 hoặc sms_v6_<tên>.'
}
$outputFile = Join-Path $PSScriptRoot ('install_' + $Database + '.sql')
if (Test-Path -LiteralPath $outputFile) { throw 'File đích đã tồn tại. Chọn tên database mới hoặc kiểm tra file đã tạo.' }
$parts = @('-- Generated for a NEW, EMPTY V6 database. Review before running.')
foreach ($name in @('01_SCHEMA_ALL.sql','02_SEED_DEMO.sql','03_QUERIES_CHECK.sql')) {
    $source = [IO.File]::ReadAllText((Join-Path $PSScriptRoot $name))
    $parts += $source.Replace('sms_db', $Database)
}
$parts += ('USE `' + $Database + '`;').Replace('\`','`')
[IO.File]::WriteAllText($outputFile, ($parts -join "`r`n"), [Text.UTF8Encoding]::new($false))
Write-Output "Đã tạo: $outputFile"
Write-Output 'Chưa thực thi SQL. Chỉ chạy file này trên database mới, không nhập chồng schema v2.'
