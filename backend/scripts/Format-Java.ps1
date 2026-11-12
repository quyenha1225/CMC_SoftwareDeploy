param([switch]$Check)
$ErrorActionPreference = 'Stop'
$backendRoot = Split-Path -Parent $PSScriptRoot
$formatterVersion = '1.24.0'
$toolDirectory = Join-Path $backendRoot '.local/tools'
$formatter = Join-Path $toolDirectory "google-java-format-$formatterVersion-all-deps.jar"
$expectedHash = '812F805F58112460EDF01BF202A8E61D0FD1F35C0D4FABD54220640776EC57A1'

if (!(Test-Path -LiteralPath $formatter)) {
    New-Item -ItemType Directory -Path $toolDirectory -Force > $null
    $url = "https://repo.maven.apache.org/maven2/com/google/googlejavaformat/google-java-format/$formatterVersion/google-java-format-$formatterVersion-all-deps.jar"
    Invoke-WebRequest -Uri $url -OutFile $formatter -UseBasicParsing
}
if ((Get-FileHash -LiteralPath $formatter -Algorithm SHA256).Hash -ne $expectedHash) {
    throw 'Formatter checksum mismatch.'
}

$javaFiles = @(Get-ChildItem -LiteralPath (Join-Path $backendRoot 'src') -Recurse -Filter '*.java' -File | ForEach-Object { $_.FullName })
if ($javaFiles.Count -eq 0) { throw 'No Java source files found.' }
$formatArguments = @('-jar', $formatter, '--aosp')
if ($Check) { $formatArguments += @('--dry-run', '--set-exit-if-changed') }
else { $formatArguments += '--replace' }
& java @formatArguments @javaFiles
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Output "Java formatting OK: $($javaFiles.Count) files."
