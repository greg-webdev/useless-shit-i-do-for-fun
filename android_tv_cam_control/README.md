# Android TV Capture Card Display & Remote Control

A modern, high-performance Flutter application designed for **Android TV** that displays video from a **USB HDMI Capture Card or Webcam** full-screen with ultra-low latency, and hosts an embedded **HTTP & WebSocket Remote Control Server** allowing anyone on the local Wi-Fi to connect, monitor, and control it from their smartphone or PC browser.

---

## Key Features

1. **USB Capture Card / Webcam Display**:
   - Plug any USB HDMI capture card (Cam Link, generic USB 2.0 / 3.0 HDMI capture dongles) into your Android TV's USB port.
   - Automatically detects external UVC video input devices.
   - Multiple display modes:
     - **16:9 Fit**: Pixel-perfect aspect ratio with zero distortion.
     - **Full / Fill**: Borderless edge-to-edge television screen fill.
     - **4:3 Retro**: Formatted for classic retro game consoles.
   - Animated **SMPTE Color Bar Test Pattern** with millisecond timecode fallback when no capture card is connected.

2. **Zero-Install Web Remote Controller**:
   - The TV app hosts its own local Web & WebSocket server on port `8080`.
   - The TV screen displays a scannable **QR Code** and the local IP address (`http://<tv-ip>:8080`).
   - Open the web controller from any phone, tablet, or laptop browser:
     - **Virtual D-Pad & Navigation**: Up, Down, Left, Right, OK/Select, Back, Home, Menu.
     - **Volume & Media**: Vol +, Vol -, Mute, Play/Pause.
     - **Capture Controls**: Switch input source, toggle aspect ratio, reconnect stream, snapshot frame.
     - **Gamepad & Touchpad**: Trackpad swipe navigation and tactile ABXY buttons.
     - **Quick Text Sender**: Type text directly to the TV.
     - **Live Telemetry**: Real-time broadcast of resolution, FPS, active input, and connected client count.

3. **Android TV Native Optimization**:
   - Android TV banner and Leanback launcher support.
   - D-Pad navigation support using the physical TV remote (Center/Select opens the Quick Settings HUD; Back dismisses).
   - Auto-hiding OSD: The HUD automatically disappears after 5 seconds of inactivity so the video stream is 100% unobstructed.
   - WakeLock enabled to prevent the TV from dimming or going into screensaver mode.

---

## Project Structure

```
android_tv_cam_control/
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml       # Leanback launcher, banner, UVC camera & network permissions
│       └── res/drawable/tv_banner.png # Android TV 320x180 launcher banner
├── lib/
│   ├── main.dart                     # App entry point, TV dark theme & wakelock
│   ├── screens/
│   │   └── tv_home_screen.dart       # Fullscreen video viewport, auto-hiding OSD, TV remote handler
│   ├── services/
│   │   ├── camera_service.dart       # Capture card / webcam enumeration & display management
│   │   ├── remote_server.dart        # Embedded HTTP & WebSocket server
│   │   └── web_controller_html.dart  # Offline glassmorphic web remote interface
│   └── widgets/
│       └── test_card_view.dart       # SMPTE color bar generator & standby timecode
├── test/
│   └── widget_test.dart              # Automated tests
├── install_to_tv.bat                 # One-click TV installer
└── pubspec.yaml                      # Dependencies (camera, qr_flutter, wakelock_plus, network_info_plus)
```

---

## Installation & Running

### Option 1: One-Click Install to Android TV (Recommended)

1. Make sure **Developer Options** and **USB Debugging** (or **Network Debugging**) are enabled on your Android TV (under Settings > Device Preferences > About > click 'Build' 7 times).
2. Double click or run:
   ```cmd
   install_to_tv.bat
   ```
3. If your Android TV shows a prompt saying **"Allow USB debugging?"**, select **Always allow from this computer** and choose **OK**.

### Option 2: Manual ADB Install

Over USB:
```bash
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

Over Wi-Fi:
```bash
adb connect <YOUR_TV_IP>:5555
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

### Option 3: Run directly from Flutter

```bash
cd android_tv_cam_control
flutter run -d <device-id>
```
