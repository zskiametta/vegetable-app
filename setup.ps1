$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host "[1/3] Membuat folder android & web..." -ForegroundColor Green
flutter create . --project-name vegetable_app --org id.vegetableapp --platforms=android,web

$manifest = "android\app\src\main\AndroidManifest.xml"
if (Test-Path $manifest) {
  $isi = [IO.File]::ReadAllText((Resolve-Path $manifest))
  if ($isi -notmatch "android.permission.INTERNET") {
    $isi = $isi -replace "<application", "<uses-permission android:name=`"android.permission.INTERNET`"/>`r`n    <application"
  }
  $isi = $isi -replace 'android:label="vegetable_app"', 'android:label="Vegetable App"'
  [IO.File]::WriteAllText((Resolve-Path $manifest), $isi)
  Write-Host "  Izin INTERNET ditambahkan." -ForegroundColor DarkGray
}

Write-Host "[2/3] Mengunduh package (http, shared_preferences)..." -ForegroundColor Green
flutter pub get

Write-Host "[3/3] Selesai!" -ForegroundColor Green
Write-Host "  Jalankan di HP/emulator : flutter run"
Write-Host "  Jalankan di browser     : flutter run -d chrome"
Write-Host "  Buat APK               : flutter build apk --release"
Write-Host "  Lokasi APK             : build\app\outputs\flutter-apk\app-release.apk"
