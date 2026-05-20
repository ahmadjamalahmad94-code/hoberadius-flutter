$ErrorActionPreference = "Stop"

$manifest = Join-Path $PSScriptRoot "..\android\app\src\main\AndroidManifest.xml"
if (-not (Test-Path $manifest)) {
  throw "AndroidManifest.xml not found. Run: flutter create . --platforms=android"
}

$text = Get-Content $manifest -Raw
if ($text -notmatch 'android\.permission\.INTERNET') {
  $text = $text -replace '<manifest xmlns:android="http://schemas.android.com/apk/res/android">',
    "<manifest xmlns:android=`"http://schemas.android.com/apk/res/android`">`r`n    <uses-permission android:name=`"android.permission.INTERNET`" />"
}

if ($text -notmatch 'android:usesCleartextTraffic=') {
  $text = $text -replace 'android:icon="@mipmap/ic_launcher"',
    "android:icon=`"@mipmap/ic_launcher`"`r`n        android:usesCleartextTraffic=`"true`""
}

Set-Content -Path $manifest -Value $text -NoNewline
Write-Host "Android network permissions are ready."
