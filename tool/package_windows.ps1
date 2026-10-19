# Builds ShiftPad for Windows (release) and zips it into dist\.
# Usage: powershell -File tool/package_windows.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$versionLine = Select-String -Path pubspec.yaml -Pattern '^version:\s*([0-9.]+)' | Select-Object -First 1
if (-not $versionLine) { throw 'No version in pubspec.yaml' }
$version = $versionLine.Matches[0].Groups[1].Value

flutter build windows --release
if ($LASTEXITCODE -ne 0) { throw "flutter build failed ($LASTEXITCODE)" }

$release = Join-Path $root 'build\windows\x64\runner\Release'
$dist = Join-Path $root 'dist'
New-Item -ItemType Directory -Force $dist | Out-Null
$zip = Join-Path $dist "ShiftPad-windows-$version.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }

# Ship the install notes and licences next to the app.
$staging = Join-Path $dist "ShiftPad-$version"
if (Test-Path $staging) { Remove-Item $staging -Recurse -Force }
Copy-Item $release $staging -Recurse
Copy-Item (Join-Path $root 'docs\INSTALL.md') $staging
Copy-Item (Join-Path $root 'THIRD_PARTY_NOTICES.md') $staging

Compress-Archive -Path (Join-Path $staging '*') -DestinationPath $zip
Remove-Item $staging -Recurse -Force
Write-Host "Created $zip"
