param([string]$SenderEmail, [string]$PublicUrl='http://127.0.0.1:5173')
$ErrorActionPreference='Stop'
if (!$SenderEmail) { $SenderEmail=Read-Host 'Email Gmail/Google Workspace dùng để gửi thư' }
if ($SenderEmail -notmatch '^[^\s@]+@[^\s@]+\.[^\s@]+$') { throw 'Email không hợp lệ.' }
if ($PublicUrl -notmatch '^https?://[^\s#?]+$') { throw 'PublicUrl phải là địa chỉ web tuyệt đối, không có query hoặc fragment.' }
$configFile=Join-Path $PSScriptRoot '.env.local'
if (!(Test-Path -LiteralPath $configFile)) { throw 'Chưa có .env.local chứa khóa bảo mật. Không tự ghi đè khóa cũ.' }
$credential=Get-Credential -UserName $SenderEmail -Message 'Nhập mật khẩu ứng dụng Google (không dùng mật khẩu đăng nhập Gmail)'
if (!$credential) { throw 'Chưa nhập cấu hình gửi thư.' }
$secret=$credential.GetNetworkCredential().Password.Replace(' ','')
if ($secret -notmatch '^[a-zA-Z0-9]{16}$') { throw 'Kiểm tra mật khẩu ứng dụng Google gồm 16 ký tự.' }
$lines=[IO.File]::ReadAllLines($configFile)
$values=@{SMS_SMTP_HOST='smtp.gmail.com';SMS_SMTP_PORT='587';SMS_SMTP_USERNAME=$SenderEmail;SMS_SMTP_PASSWORD=$secret;SMS_PUBLIC_URL=$PublicUrl.TrimEnd('/');SMS_MAIL_ENABLED='true'}
# Không tự bật outbox cũ: có thể chứa địa chỉ demo chưa được thay thế.
foreach ($key in $values.Keys) {
    $matched = $false
    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match ('^' + [regex]::Escape($key) + '=')) {
            $lines[$index] = $key + '=' + $values[$key]
            $matched = $true
        }
    }
    if (!$matched) { $lines += ($key + '=' + $values[$key]) }
}
[IO.File]::WriteAllLines($configFile,$lines,[Text.UTF8Encoding]::new($false))
Write-Host 'Đã lưu cấu hình Gmail cục bộ. Khởi động lại backend để dùng; chưa gửi thư thử.'
