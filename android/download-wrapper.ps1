# Gradle Wrapper JAR Download Script
# Run this to download the gradle-wrapper.jar

$ErrorActionPreference = "Stop"

$wrapperDir = "gradle\wrapper"
$wrapperJar = "$wrapperDir\gradle-wrapper.jar"
$wrapperUrl = "https://raw.githubusercontent.com/gradle/gradle/v8.2.0/gradle/wrapper/gradle-wrapper.jar"

Write-Host "Downloading Gradle Wrapper JAR..."

if (-not (Test-Path $wrapperDir)) {
    New-Item -ItemType Directory -Path $wrapperDir -Force | Out-Null
}

try {
    Invoke-WebRequest -Uri $wrapperUrl -OutFile $wrapperJar
    Write-Host "✓ Gradle wrapper downloaded successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now run: gradlew.bat assembleDebug" -ForegroundColor Cyan
} catch {
    Write-Host "✗ Failed to download wrapper. You can alternatively:" -ForegroundColor Red
    Write-Host "  1. Open the project in Android Studio (it will auto-generate)"
    Write-Host "  2. Or manually download from: https://raw.githubusercontent.com/gradle/gradle/v8.2.0/gradle/wrapper/gradle-wrapper.jar"
    exit 1
}
