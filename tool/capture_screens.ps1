param(
  [string]$Device = 'emulator-5554',
  [string]$Adb = 'adb'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$app = 'com.magephoto.mage_photo_edit'
$frames = (Get-Content -Raw -LiteralPath (Join-Path $root 'docs/design/manifest.json') | ConvertFrom-Json).nodes
$destination = Join-Path $root 'docs/screenshots'
New-Item -ItemType Directory -Force -Path $destination | Out-Null

function Invoke-Adb {
  & $Adb -s $Device @args
  if ($LASTEXITCODE -ne 0) { throw "ADB failed ($LASTEXITCODE): $args" }
}

foreach ($frame in $frames) {
  $name = $frame.name
  $slug = $name.ToLowerInvariant().Replace(' ', '-')
  Invoke-Adb shell am start -n "$app/.MainActivity" --es mage_screen "'$name'" | Out-Null
  Start-Sleep -Milliseconds 1400
  Invoke-Adb shell screencap -p /data/local/tmp/mage-screen.png
  Invoke-Adb pull /data/local/tmp/mage-screen.png (Join-Path $destination "$slug.png") | Out-Null
  Write-Output $name
}
Invoke-Adb shell rm -f /data/local/tmp/mage-screen.png
