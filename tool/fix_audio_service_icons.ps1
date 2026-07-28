# Fixes corrupted audio_service notification PNGs in the pub cache.
# Some Windows installs end up with zero-filled icon files that break
# `flutter build apk --release` during AAPT compilation.
#
# Usage (from project root):
#   powershell -ExecutionPolicy Bypass -File tool\fix_audio_service_icons.ps1

$ErrorActionPreference = "Stop"

$pubCache = Join-Path $env:LOCALAPPDATA "Pub\Cache\hosted\pub.dev"
$pkg = Get-ChildItem $pubCache -Directory -Filter "audio_service-*" |
  Sort-Object Name -Descending |
  Select-Object -First 1

if (-not $pkg) {
  Write-Error "audio_service package not found in pub cache. Run 'flutter pub get' first."
}

$res = Join-Path $pkg.FullName "android\src\main\res"
$fixDir = Join-Path $PSScriptRoot "audio_service_icon_fixes"
$stopFix = Join-Path $fixDir "audio_service_stop.png"
$pauseFix = Join-Path $fixDir "audio_service_pause.png"

if (-not (Test-Path $stopFix) -or -not (Test-Path $pauseFix)) {
  Write-Error "Missing fix icons under tool/audio_service_icon_fixes"
}

function Test-IsValidPng([string]$path) {
  if (-not (Test-Path $path)) { return $false }
  $bytes = [System.IO.File]::ReadAllBytes($path)
  return ($bytes.Length -ge 8 -and
    $bytes[0] -eq 0x89 -and $bytes[1] -eq 0x50 -and
    $bytes[2] -eq 0x4E -and $bytes[3] -eq 0x47)
}

$targets = @(
  @{ Path = Join-Path $res "drawable-hdpi\audio_service_stop.png"; Source = $stopFix },
  @{ Path = Join-Path $res "drawable-xxxhdpi\audio_service_stop.png"; Source = $stopFix },
  @{ Path = Join-Path $res "drawable-xxxhdpi\audio_service_pause.png"; Source = $pauseFix }
)

$fixed = 0
foreach ($t in $targets) {
  if (-not (Test-IsValidPng $t.Path)) {
    $dir = Split-Path $t.Path -Parent
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    Copy-Item $t.Source $t.Path -Force
    Write-Host "Fixed: $($t.Path)"
    $fixed++
  } else {
    Write-Host "OK: $($t.Path)"
  }
}

Write-Host "Done. Repaired $fixed file(s) in $($pkg.Name)."
