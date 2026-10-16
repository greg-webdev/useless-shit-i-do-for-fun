@echo off
setlocal
echo =======================================================
echo   Android TV Capture Card & Remote Control Installer
echo =======================================================
echo.
set APK_PATH=build\app\outputs\flutter-apk\app-debug.apk

if not exist "%APK_PATH%" (
    echo [ERROR] APK not found at %APK_PATH%.
    echo Please run: flutter build apk --debug
    pause
    exit /b 1
)

echo Choose connection method:
echo   1. Install via USB / Already Connected ADB Device
echo   2. Connect via Wi-Fi IP (Wireless ADB)
echo.
set /p CHOICE="Enter choice (1 or 2): "

if "%CHOICE%"=="2" (
    set /p TV_IP="Enter your Android TV IP address (e.g. 192.168.1.50): "
    echo Connecting to %TV_IP%:5555...
    adb connect %TV_IP%:5555
    timeout /t 2 /nobreak >nul
)

echo.
echo Checking connected devices...
adb devices
echo.

echo Installing APK to Android TV...
adb install -r "%APK_PATH%"
if %ERRORLEVEL% equ 0 (
    echo.
    echo Enabling System-Wide Accessibility Service...
    adb shell settings put secure enabled_accessibility_services com.antigravity.tvcapture.android_tv_cam_control/.TvRemoteAccessibilityService
    adb shell settings put secure accessibility_enabled 1
    echo.
    echo Forwarding Port 82 for HTTPS...
    adb forward tcp:82 tcp:8482
    adb forward tcp:8482 tcp:8482
    adb forward tcp:8080 tcp:8080
    echo.
    echo Launching App on TV...
    adb shell am start -n com.antigravity.tvcapture.android_tv_cam_control/.MainActivity
    echo.
    echo =======================================================
    echo   SUCCESS: App installed and running on Android TV!
    echo =======================================================
    echo Open on PC: https://localhost:82  (or http://localhost:8080)
) else (
    echo.
    echo [ERROR] Installation failed.
    echo If your device shows 'unauthorized', check your TV screen
    echo and accept the 'Allow USB debugging' prompt.
)
echo.
pause
