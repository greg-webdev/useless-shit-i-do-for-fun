// Master Web Controller HTML/CSS/JS with Big Screen Stream (TV UI & Webcam), Trackpad above Controller, and Interactive TV Mouse Sync
class WebControllerHtml {
  static String getHtml({
    required String tvName,
    required String serverIp,
    required int port,
    bool isHttps = false,
    int httpsPort = 9293,
  }) {
    return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
  <meta name="theme-color" content="#07090e">
  <title>$tvName - Big Screen &amp; System Controller</title>
  <style>
    :root {
      --bg: #07090e;
      --card-bg: rgba(18, 24, 38, 0.88);
      --card-border: rgba(255, 255, 255, 0.08);
      --accent-cyan: #00f2fe;
      --accent-blue: #4facfe;
      --accent-indigo: #6366f1;
      --accent-emerald: #10b981;
      --text-main: #f8fafc;
      --text-muted: #94a3b8;
      --btn-bg: rgba(255, 255, 255, 0.06);
      --btn-active: rgba(0, 242, 254, 0.25);
      --danger: #ef4444;
      --success: #10b981;
    }

    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
      -webkit-tap-highlight-color: transparent;
      user-select: none;
      -webkit-user-select: none;
    }

    body {
      background: radial-gradient(circle at 50% 0%, #151d30 0%, var(--bg) 100%);
      color: var(--text-main);
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 10px 10px 40px;
      overflow-x: hidden;
    }

    .container {
      width: 100%;
      max-width: 640px;
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    /* Top Bar Header */
    header {
      background: var(--card-bg);
      backdrop-filter: blur(16px);
      -webkit-backdrop-filter: blur(16px);
      border: 1px solid var(--card-border);
      border-radius: 16px;
      padding: 10px 14px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      box-shadow: 0 4px 20px rgba(0, 0, 0, 0.4);
    }

    .brand {
      display: flex;
      flex-direction: column;
    }

    .brand h1 {
      font-size: 1.05rem;
      font-weight: 700;
      background: linear-gradient(135deg, #ffffff 20%, var(--accent-cyan) 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      letter-spacing: 0.5px;
    }

    .brand span {
      font-size: 0.68rem;
      color: var(--text-muted);
    }

    .header-pills {
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .protocol-pill {
      font-size: 0.65rem;
      font-weight: 700;
      padding: 4px 8px;
      border-radius: 6px;
      text-decoration: none;
      transition: all 0.2s;
    }

    .protocol-pill.https {
      background: rgba(16, 185, 129, 0.2);
      border: 1px solid rgba(16, 185, 129, 0.4);
      color: #34d399;
    }

    .protocol-pill.http {
      background: rgba(234, 179, 8, 0.2);
      border: 1px solid rgba(234, 179, 8, 0.4);
      color: #facc15;
      cursor: pointer;
    }

    .protocol-pill.http:hover {
      background: rgba(234, 179, 8, 0.35);
    }

    .status-badge {
      display: flex;
      align-items: center;
      gap: 6px;
      padding: 5px 10px;
      border-radius: 999px;
      font-size: 0.7rem;
      font-weight: 600;
      background: rgba(16, 185, 129, 0.15);
      border: 1px solid rgba(16, 185, 129, 0.3);
      color: #34d399;
    }

    .status-badge.offline {
      background: rgba(239, 68, 68, 0.15);
      border-color: rgba(239, 68, 68, 0.3);
      color: #f87171;
    }

    .status-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: #10b981;
      box-shadow: 0 0 10px #10b981;
      animation: pulse 2s infinite;
    }

    .status-badge.offline .status-dot {
      background: #ef4444;
      box-shadow: none;
      animation: none;
    }

    @keyframes pulse {
      0% { opacity: 1; transform: scale(1); }
      50% { opacity: 0.4; transform: scale(1.2); }
      100% { opacity: 1; transform: scale(1); }
    }

    /* BIG SCREEN CONTAINER */
    .big-screen-card {
      position: relative;
      width: 100%;
      background: #000000;
      border-radius: 18px;
      overflow: hidden;
      border: 1.5px solid rgba(0, 242, 254, 0.5);
      box-shadow: 0 8px 30px rgba(0, 242, 254, 0.2), 0 12px 28px rgba(0, 0, 0, 0.85);
      display: flex;
      flex-direction: column;
    }

    .screen-toolbar {
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      height: 40px;
      background: linear-gradient(180deg, rgba(0,0,0,0.85) 0%, transparent 100%);
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 0 10px;
      z-index: 20;
    }

    .live-pill {
      display: flex;
      align-items: center;
      gap: 6px;
      font-size: 0.65rem;
      font-weight: 800;
      letter-spacing: 0.8px;
      color: #ffffff;
      background: rgba(16, 185, 129, 0.85);
      padding: 3px 8px;
      border-radius: 4px;
    }

    .live-pill .dot {
      width: 6px;
      height: 6px;
      border-radius: 50%;
      background: #ffffff;
      animation: pulse 1s infinite;
    }

    .screen-tools {
      display: flex;
      align-items: center;
      gap: 6px;
    }

    .screen-btn {
      background: rgba(15, 23, 42, 0.8);
      border: 1px solid rgba(255, 255, 255, 0.2);
      color: #ffffff;
      font-size: 0.7rem;
      font-weight: 600;
      padding: 4px 8px;
      border-radius: 6px;
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 4px;
      transition: all 0.15s;
    }

    .screen-btn.active {
      background: var(--accent-cyan);
      color: #000;
      border-color: var(--accent-cyan);
      box-shadow: 0 0 10px rgba(0, 242, 254, 0.5);
    }

    .screen-btn:active {
      transform: scale(0.95);
    }

    /* THE INTERACTIVE SCREEN VIEWPORT */
    .screen-viewport {
      position: relative;
      width: 100%;
      aspect-ratio: 16 / 9;
      background: #030712;
      display: flex;
      align-items: center;
      justify-content: center;
      overflow: hidden;
      cursor: crosshair;
    }

    #tvScreenImg {
      width: 100%;
      height: 100%;
      object-fit: contain;
      display: block;
      pointer-events: none;
    }

    #localVideo {
      width: 100%;
      height: 100%;
      object-fit: contain;
      display: none;
      background: #000;
      pointer-events: none;
    }

    #streamImg {
      width: 100%;
      height: 100%;
      object-fit: contain;
      display: none;
      pointer-events: none;
    }

    .screen-loader {
      position: absolute;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 8px;
      color: var(--text-muted);
      font-size: 0.75rem;
      pointer-events: none;
    }

    .spinner {
      width: 32px;
      height: 32px;
      border: 3px solid rgba(0, 242, 254, 0.2);
      border-top-color: var(--accent-cyan);
      border-radius: 50%;
      animation: spin 0.8s linear infinite;
    }

    @keyframes spin { to { transform: rotate(360deg); } }

    /* Interactive Click Ripple */
    .click-ripple {
      position: absolute;
      width: 24px;
      height: 24px;
      margin-left: -12px;
      margin-top: -12px;
      border-radius: 50%;
      background: rgba(0, 242, 254, 0.6);
      border: 2px solid #ffffff;
      pointer-events: none;
      opacity: 0;
      transform: scale(0.5);
    }

    .click-ripple.animate {
      animation: rippleEffect 0.5s ease-out forwards;
    }

    @keyframes rippleEffect {
      0% { opacity: 1; transform: scale(0.6); }
      100% { opacity: 0; transform: scale(2.6); }
    }

    /* Screen Cursor Indicator */
    .screen-cursor-dot {
      position: absolute;
      width: 12px;
      height: 12px;
      margin-left: -6px;
      margin-top: -6px;
      border-radius: 50%;
      background: var(--accent-cyan);
      border: 2px solid #ffffff;
      box-shadow: 0 0 10px var(--accent-cyan);
      pointer-events: none;
      display: none;
      z-index: 15;
    }

    /* Screen Coordinate Badge */
    .coords-badge {
      position: absolute;
      bottom: 8px;
      right: 8px;
      background: rgba(0, 0, 0, 0.75);
      border: 1px solid rgba(255, 255, 255, 0.15);
      color: var(--accent-cyan);
      font-family: monospace;
      font-size: 0.65rem;
      padding: 3px 6px;
      border-radius: 4px;
      pointer-events: none;
      z-index: 15;
    }

    /* BIG SCREEN STREAM SOURCE SELECTOR */
    .source-bar {
      display: flex;
      background: rgba(15, 23, 42, 0.95);
      border-top: 1px solid var(--card-border);
      padding: 6px;
      gap: 6px;
    }

    .source-btn {
      flex: 1;
      padding: 8px 6px;
      background: transparent;
      border: 1px solid transparent;
      border-radius: 8px;
      color: var(--text-muted);
      font-size: 0.72rem;
      font-weight: 700;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 6px;
      transition: all 0.2s;
    }

    .source-btn.active {
      background: linear-gradient(135deg, rgba(79, 172, 254, 0.25), rgba(0, 242, 254, 0.15));
      border-color: var(--accent-cyan);
      color: #ffffff;
      box-shadow: 0 2px 8px rgba(0, 242, 254, 0.2);
    }

    /* WEBCAM / CAPTURE CARD SELECTOR BAR */
    .device-bar {
      display: none;
      align-items: center;
      gap: 8px;
      background: rgba(15, 23, 42, 0.85);
      border: 1px solid var(--card-border);
      border-radius: 12px;
      padding: 8px 12px;
    }

    .device-label {
      font-size: 0.7rem;
      color: var(--text-muted);
      text-transform: uppercase;
      font-weight: 700;
      white-space: nowrap;
    }

    .device-select {
      flex: 1;
      background: #0b0f19;
      border: 1px solid rgba(255, 255, 255, 0.15);
      border-radius: 8px;
      color: #ffffff;
      font-size: 0.78rem;
      padding: 6px 10px;
      outline: none;
      cursor: pointer;
    }

    /* CARD CONTAINERS */
    .card {
      background: var(--card-bg);
      backdrop-filter: blur(16px);
      -webkit-backdrop-filter: blur(16px);
      border: 1px solid var(--card-border);
      border-radius: 18px;
      padding: 14px;
      box-shadow: 0 8px 25px rgba(0, 0, 0, 0.35);
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .card-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
    }

    .card-title {
      font-size: 0.75rem;
      text-transform: uppercase;
      letter-spacing: 1px;
      color: var(--text-muted);
      font-weight: 700;
      display: flex;
      align-items: center;
      gap: 6px;
    }

    .card-title strong {
      color: #ffffff;
    }

    /* 1. TRACKPAD (ABOVE CONTROLLER) */
    .touchpad {
      width: 100%;
      height: 180px;
      background: radial-gradient(circle at 50% 50%, rgba(30, 41, 59, 0.4) 0%, rgba(10, 14, 23, 0.95) 100%);
      border: 1.5px solid rgba(255, 255, 255, 0.12);
      border-radius: 14px;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      color: var(--text-muted);
      font-size: 0.8rem;
      touch-action: none;
      position: relative;
      cursor: grab;
      overflow: hidden;
      box-shadow: inset 0 2px 10px rgba(0, 0, 0, 0.6);
      transition: border-color 0.2s;
    }

    .touchpad:active {
      cursor: grabbing;
      border-color: var(--accent-cyan);
      box-shadow: inset 0 0 15px rgba(0, 242, 254, 0.2);
    }

    .touchpad-hud {
      pointer-events: none;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 4px;
    }

    .touchpad-hud span {
      font-size: 0.7rem;
      opacity: 0.6;
    }

    .touchpad-dot {
      position: absolute;
      width: 14px;
      height: 14px;
      margin-left: -7px;
      margin-top: -7px;
      border-radius: 50%;
      background: var(--accent-cyan);
      box-shadow: 0 0 14px var(--accent-cyan);
      pointer-events: none;
      display: none;
    }

    /* Trackpad Action Buttons Bar */
    .trackpad-buttons {
      display: flex;
      gap: 8px;
    }

    .pad-btn {
      flex: 1;
      padding: 10px 8px;
      background: var(--btn-bg);
      border: 1px solid var(--card-border);
      border-radius: 10px;
      color: #ffffff;
      font-size: 0.78rem;
      font-weight: 700;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 6px;
      transition: all 0.12s;
    }

    .pad-btn:active {
      background: var(--btn-active);
      border-color: var(--accent-cyan);
      transform: scale(0.96);
    }

    /* 2. CONTROLLER (DIRECTLY BELOW TRACKPAD) */
    .dpad-container {
      display: flex;
      justify-content: center;
      align-items: center;
      padding: 6px 0;
    }

    .dpad {
      position: relative;
      width: 190px;
      height: 190px;
      border-radius: 50%;
      background: rgba(15, 23, 42, 0.9);
      border: 2px solid rgba(255, 255, 255, 0.08);
      box-shadow: inset 0 4px 20px rgba(0, 0, 0, 0.8), 0 8px 20px rgba(0, 0, 0, 0.5);
    }

    .dpad-btn {
      position: absolute;
      background: rgba(255, 255, 255, 0.04);
      border: 1px solid rgba(255, 255, 255, 0.06);
      color: #ffffff;
      display: flex;
      justify-content: center;
      align-items: center;
      cursor: pointer;
      transition: all 0.1s ease;
      touch-action: manipulation;
    }

    .dpad-btn:active {
      background: linear-gradient(135deg, rgba(79, 172, 254, 0.4), rgba(0, 242, 254, 0.3));
      border-color: var(--accent-cyan);
      box-shadow: 0 0 15px rgba(0, 242, 254, 0.5);
      transform: scale(0.94);
    }

    .dpad-btn svg {
      width: 22px;
      height: 22px;
      fill: currentColor;
    }

    .dpad-up { top: 8px; left: 63px; width: 64px; height: 54px; border-radius: 32px 32px 10px 10px; }
    .dpad-down { bottom: 8px; left: 63px; width: 64px; height: 54px; border-radius: 10px 10px 32px 32px; }
    .dpad-left { left: 8px; top: 63px; width: 54px; height: 64px; border-radius: 32px 10px 10px 32px; }
    .dpad-right { right: 8px; top: 63px; width: 54px; height: 64px; border-radius: 10px 32px 32px 10px; }

    .dpad-center {
      top: 63px; left: 63px; width: 64px; height: 64px; border-radius: 50%;
      background: linear-gradient(135deg, #1e293b, #0f172a);
      border: 2px solid rgba(0, 242, 254, 0.35);
      box-shadow: 0 0 16px rgba(0, 0, 0, 0.6);
      font-weight: 800; font-size: 0.85rem; letter-spacing: 0.5px; color: var(--accent-cyan);
    }
    .dpad-center:active {
      background: linear-gradient(135deg, #0284c7, #0369a1);
      color: #ffffff; transform: scale(0.92); box-shadow: 0 0 20px rgba(0, 242, 254, 0.7);
    }

    /* Grids */
    .btn-grid-5 { display: grid; grid-template-columns: repeat(5, 1fr); gap: 6px; }
    .btn-grid-4 { display: grid; grid-template-columns: repeat(4, 1fr); gap: 6px; }
    .btn-grid-3 { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; }

    .control-btn {
      background: var(--btn-bg);
      border: 1px solid var(--card-border);
      border-radius: 12px;
      padding: 10px 6px;
      color: #ffffff;
      font-size: 0.75rem;
      font-weight: 600;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      gap: 4px;
      cursor: pointer;
      transition: all 0.12s ease;
      touch-action: manipulation;
    }

    .control-btn svg { width: 18px; height: 18px; fill: currentColor; }

    .control-btn:active {
      background: var(--btn-active);
      border-color: var(--accent-cyan);
      transform: scale(0.94);
      box-shadow: 0 0 10px rgba(0, 242, 254, 0.35);
    }

    .control-btn.accent {
      background: linear-gradient(135deg, rgba(99, 102, 241, 0.25), rgba(79, 172, 254, 0.25));
      border-color: rgba(99, 102, 241, 0.4);
      color: #a5b4fc;
    }

    /* Input & Send Bar */
    .input-row {
      display: flex;
      gap: 8px;
    }

    .text-input {
      flex: 1;
      background: rgba(15, 23, 42, 0.8);
      border: 1px solid var(--card-border);
      border-radius: 10px;
      padding: 9px 12px;
      color: #ffffff;
      font-size: 0.8rem;
      outline: none;
    }

    .text-input:focus {
      border-color: var(--accent-cyan);
    }

    .send-btn {
      background: linear-gradient(135deg, var(--accent-blue), var(--accent-cyan));
      border: none;
      border-radius: 10px;
      padding: 0 14px;
      font-weight: 700;
      font-size: 0.8rem;
      color: #07090e;
      cursor: pointer;
    }

    .send-btn:active {
      transform: scale(0.95);
    }

    /* Fullscreen Mode */
    .fullscreen-mode {
      position: fixed !important;
      top: 0 !important; left: 0 !important;
      width: 100vw !important; height: 100vh !important;
      max-width: none !important;
      z-index: 9999 !important;
      border-radius: 0 !important;
    }

    .fullscreen-mode .screen-viewport {
      height: calc(100vh - 86px) !important;
      aspect-ratio: auto !important;
    }

    /* Toast */
    #toast {
      position: fixed;
      bottom: 20px;
      left: 50%;
      transform: translateX(-50%) translateY(100px);
      background: rgba(15, 23, 42, 0.95);
      border: 1px solid var(--accent-cyan);
      color: #ffffff;
      padding: 8px 18px;
      border-radius: 999px;
      font-size: 0.78rem;
      font-weight: 600;
      box-shadow: 0 8px 20px rgba(0, 242, 254, 0.3);
      transition: transform 0.3s cubic-bezier(0.18, 0.89, 0.32, 1.28);
      pointer-events: none;
      z-index: 10000;
    }

    #toast.show {
      transform: translateX(-50%) translateY(0);
    }
  </style>
</head>
<body>

  <div class="container">
    <!-- Header -->
    <header>
      <div class="brand">
        <h1>$tvName</h1>
        <span>Live Stream &amp; Universal Controller</span>
      </div>
      <div class="header-pills">
        <!-- HTTPS Port 82 indicator / toggle -->
        <div id="protoBadge">
          <!-- Populated by JS -->
        </div>
        <div id="statusBadge" class="status-badge">
          <div class="status-dot"></div>
          <span id="statusText">ONLINE</span>
        </div>
      </div>
    </header>

    <!-- BIG SCREEN (TV UI / WEBCAM STREAM) -->
    <div id="screenCard" class="big-screen-card">
      <div class="screen-toolbar">
        <div class="live-pill" id="livePill">
          <div class="dot"></div>
          <span id="liveLabel">TV SYSTEM SCREEN</span>
        </div>
        <div class="screen-tools">
          <button class="screen-btn active" id="mouseSyncBtn" onclick="toggleMouseSync()" title="Sync mouse movement to TV">
            🖱️ TV Sync: ON
          </button>
          <button class="screen-btn" id="audioToggleBtn" onclick="toggleCaptureAudio()" style="display:none;">
            🔇 Audio
          </button>
          <button class="screen-btn" onclick="togglePip()">
            🗗 PiP
          </button>
          <button class="screen-btn" onclick="toggleFullscreen()">
            ⛶ Full
          </button>
        </div>
      </div>

      <!-- The Interactive Viewport: Move or Click anywhere to control the TV -->
      <div class="screen-viewport" id="screenViewport" title="Click or move mouse here to control TV">
        <!-- 1. TV Screen Mirror (Android UI) -->
        <img id="tvScreenImg" alt="TV Screen Mirror" />

        <!-- 2. Local Webcam / USB Capture Card -->
        <video id="localVideo" autoplay playsinline muted></video>

        <!-- 3. Hardware Feed (TV Capture Card MJPEG) -->
        <img id="streamImg" alt="TV Hardware MJPEG" />

        <!-- Screen Cursor indicator -->
        <div id="screenCursorDot" class="screen-cursor-dot"></div>

        <!-- Click Ripple -->
        <div id="clickRipple" class="click-ripple"></div>

        <!-- Coords Badge -->
        <div id="coordsBadge" class="coords-badge">X: 960 | Y: 540</div>

        <!-- Loader -->
        <div id="screenLoader" class="screen-loader">
          <div class="spinner"></div>
          <span id="loaderMsg">Connecting to TV Screen...</span>
        </div>
      </div>

      <!-- BIG SCREEN SOURCE SWITCHER -->
      <div class="source-bar">
        <button class="source-btn active" id="btnSrcTv" onclick="switchStreamSource('tv_screen')">
          🖥️ TV System UI
        </button>
        <button class="source-btn" id="btnSrcWebcam" onclick="switchStreamSource('webcam')">
          📷 Webcam / My Cam
        </button>
        <button class="source-btn" id="btnSrcHw" onclick="switchStreamSource('hardware')">
          📡 TV Hardware Feed
        </button>
      </div>
    </div>

    <!-- WEBCAM / USB CAPTURE CARD SELECTOR (Shown in Webcam mode) -->
    <div id="deviceBar" class="device-bar">
      <span class="device-label">CAMERA / CARD:</span>
      <select id="videoSourceSelect" class="device-select" onchange="onCameraSourceChanged()">
        <option value="">Searching for cameras...</option>
      </select>
      <button class="screen-btn" onclick="initWebcamDevices()" title="Refresh devices">↻</button>
    </div>

    <!-- 1. TRACKPAD (POSITIONED DIRECTLY ABOVE CONTROLLER AT THE BOTTOM) -->
    <div class="card">
      <div class="card-header">
        <div class="card-title">
          <span>🖱️ Trackpad</span>
          <strong>(Universal TV Mouse)</strong>
        </div>
        <span style="font-size:0.68rem; color:var(--accent-cyan);">Works in ALL apps</span>
      </div>

      <!-- Trackpad Touch Surface -->
      <div id="touchpad" class="touchpad">
        <div class="touchpad-hud">
          <strong>Touch &amp; Drag Trackpad</strong>
          <span>Slide to move cursor &bull; Left-click to select &bull; <strong style="color:var(--accent-cyan)">Right-click = Back</strong></span>
        </div>
        <div id="touchpadDot" class="touchpad-dot"></div>
      </div>

      <!-- Trackpad Action Buttons -->
      <div class="trackpad-buttons">
        <button class="pad-btn" onclick="sendPadTap()" title="Click on TV at current cursor position">
          🖱️ Click at Cursor
        </button>
        <button class="pad-btn" onclick="sendAction('SYS_SELECT')" title="Select highlighted item (OK button)">
          ✓ Select / OK
        </button>
        <button class="pad-btn" onclick="sendAction('SYS_BACK')" title="Back (or right-click anywhere)">
          ↩ Back (Right-Click)
        </button>
        <button class="pad-btn" onclick="sendAction('SYS_HOME')" title="Home">
          🏠 Home
        </button>
      </div>
    </div>

    <!-- 2. CONTROLLER (DIRECTLY BELOW TRACKPAD) -->
    <div class="card">
      <div class="card-header">
        <div class="card-title">
          <span>🎮 Controller</span>
          <strong>(D-Pad &amp; TV Actions)</strong>
        </div>
        <span style="font-size:0.68rem; color:var(--text-muted);">OS &amp; App Control</span>
      </div>

      <!-- System Quick Action Row -->
      <div class="btn-grid-5">
        <button class="control-btn" data-cmd="SYS_HOME" title="Home">
          <svg viewBox="0 0 24 24"><path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/></svg>
          Home
        </button>
        <button class="control-btn" data-cmd="SYS_BACK" title="Back">
          <svg viewBox="0 0 24 24"><path d="M20 11H7.83l5.59-5.59L12 4l-8 8 8 8 1.41-1.41L7.83 13H20v-2z"/></svg>
          Back
        </button>
        <button class="control-btn" data-cmd="SYS_RECENTS" title="Recents / App Switcher">
          <svg viewBox="0 0 24 24"><path d="M3 13h2v-2H3v2zm0 4h2v-2H3v2zm0-8h2V7H3v2zm4 4h14v-2H7v2zm0 4h14v-2H7v2zM7 7v2h14V7H7z"/></svg>
          Recents
        </button>
        <button class="control-btn" data-cmd="SYS_NOTIF" title="Notifications">
          <svg viewBox="0 0 24 24"><path d="M12 22c1.1 0 2-.9 2-2h-4c0 1.1.9 2 2 2zm6-6v-5c0-3.07-1.63-5.64-4.5-6.32V4c0-.83-.67-1.5-1.5-1.5s-1.5.67-1.5 1.5v.68C7.64 5.36 6 7.92 6 11v5l-2 2v1h16v-1l-2-2z"/></svg>
          Notifs
        </button>
        <button class="control-btn" data-cmd="SYS_POWER" title="Power Menu">
          <svg viewBox="0 0 24 24"><path d="M13 3h-2v10h2V3zm4.83 2.17l-1.42 1.42C17.99 7.86 19 9.81 19 12c0 3.87-3.13 7-7 7s-7-3.13-7-7c0-2.19 1.01-4.14 2.58-5.42L6.17 5.17C4.23 6.82 3 9.26 3 12c0 4.97 4.03 9 9 9s9-4.03 9-9c0-2.74-1.23-5.18-3.17-6.83z"/></svg>
          Power
        </button>
      </div>

      <!-- Directional D-Pad -->
      <div class="dpad-container">
        <div class="dpad">
          <button class="dpad-btn dpad-up" data-cmd="SYS_UP" aria-label="Up">
            <svg viewBox="0 0 24 24"><path d="M12 4l-8 8h6v8h4v-8h6z"/></svg>
          </button>
          <button class="dpad-btn dpad-left" data-cmd="SYS_LEFT" aria-label="Left">
            <svg viewBox="0 0 24 24"><path d="M4 12l8-8v6h8v4h-8v6z"/></svg>
          </button>
          <button class="dpad-btn dpad-center" data-cmd="SYS_SELECT" aria-label="OK">
            OK
          </button>
          <button class="dpad-btn dpad-right" data-cmd="SYS_RIGHT" aria-label="Right">
            <svg viewBox="0 0 24 24"><path d="M20 12l-8-8v6H4v4h8v6z"/></svg>
          </button>
          <button class="dpad-btn dpad-down" data-cmd="SYS_DOWN" aria-label="Down">
            <svg viewBox="0 0 24 24"><path d="M12 20l8-8h-6V4h-4v8H4z"/></svg>
          </button>
        </div>
      </div>

      <!-- Volume & Media Row -->
      <div class="btn-grid-4">
        <button class="control-btn" data-cmd="VOL_UP">
          <svg viewBox="0 0 24 24"><path d="M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z"/></svg>
          Vol +
        </button>
        <button class="control-btn" data-cmd="VOL_DOWN">
          <svg viewBox="0 0 24 24"><path d="M18.5 12c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM5 9v6h4l5 5V4L9 9H5z"/></svg>
          Vol -
        </button>
        <button class="control-btn" data-cmd="MUTE">
          <svg viewBox="0 0 24 24"><path d="M16.5 12c0-1.77-1.02-3.29-2.5-4.03v2.21l2.45 2.45c.03-.2.05-.41.05-.63zm2.5 0c0 .94-.2 1.82-.54 2.64l1.51 1.51C20.63 14.91 21 13.5 21 12c0-4.28-2.99-7.86-7-8.77v2.06c2.89.86 5 3.54 5 6.71zM4.27 3L3 4.27 7.73 9H3v6h4l5 5v-6.73l4.25 4.25c-.67.52-1.42.93-2.25 1.18v2.06c1.38-.31 2.63-.95 3.69-1.81L19.73 21 21 19.73l-9-9L4.27 3zM12 4L9.91 6.09 12 8.18V4z"/></svg>
          Mute
        </button>
        <button class="control-btn" data-cmd="PLAY_PAUSE">
          <svg viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 14.5v-9l6 4.5-6 4.5z"/></svg>
          Play / Pause
        </button>
      </div>

      <!-- Quick Action Shortcuts -->
      <div class="btn-grid-3">
        <button class="control-btn accent" onclick="sendAction('SWITCH_TO_BROWSER')">
          🌐 Dedicated TV Browser
        </button>
        <button class="control-btn" onclick="sendAction('MENU')">
          📋 Menu / Options
        </button>
        <button class="control-btn" onclick="sendAction('SWITCH_TO_CAPTURE')">
          📺 Capture Card View
        </button>
      </div>

      <!-- Keyboard Text Input for TV -->
      <div class="input-row">
        <input type="text" id="keyboardInput" class="text-input" placeholder="Type text to send to TV..." />
        <button class="send-btn" onclick="sendKeyboardText()">Send</button>
      </div>
    </div>
  </div>

  <div id="toast"></div>

  <script>
    // State
    const tvName = "$tvName";
    const serverIp = "$serverIp";
    const serverPort = $port;
    const isHttps = window.location.protocol === 'https:';
    const httpsPort = $httpsPort;

    let socket = null;
    let reconnectTimer = null;
    let isConnected = false;

    let currentSource = 'tv_screen'; // 'tv_screen' | 'webcam' | 'hardware'
    let tvScreenPolling = false;
    let localStream = null;
    let mouseSyncEnabled = true;
    let lastMoveSent = 0;

    let currentCursorX = 960;
    let currentCursorY = 540;

    // Elements
    const screenCard = document.getElementById('screenCard');
    const screenViewport = document.getElementById('screenViewport');
    const tvScreenImg = document.getElementById('tvScreenImg');
    const localVideo = document.getElementById('localVideo');
    const streamImg = document.getElementById('streamImg');
    const screenLoader = document.getElementById('screenLoader');
    const loaderMsg = document.getElementById('loaderMsg');
    const mouseSyncBtn = document.getElementById('mouseSyncBtn');
    const audioToggleBtn = document.getElementById('audioToggleBtn');
    const deviceBar = document.getElementById('deviceBar');
    const videoSourceSelect = document.getElementById('videoSourceSelect');
    const coordsBadge = document.getElementById('coordsBadge');
    const screenCursorDot = document.getElementById('screenCursorDot');
    const clickRipple = document.getElementById('clickRipple');
    const touchpad = document.getElementById('touchpad');
    const touchpadDot = document.getElementById('touchpadDot');
    const protoBadge = document.getElementById('protoBadge');
    const statusBadge = document.getElementById('statusBadge');
    const statusText = document.getElementById('statusText');
    const keyboardInput = document.getElementById('keyboardInput');

    // 1. PROTOCOL BADGE (HTTPS PORT 9293)
    function renderProtocolBadge() {
      if (isHttps) {
        protoBadge.innerHTML = '<span class="protocol-pill https">🔒 HTTPS (Port ' + window.location.port + ')</span>';
      } else {
        const targetHttpsUrl = 'https://' + window.location.hostname + ':' + (window.location.hostname === 'localhost' ? '9293' : httpsPort);
        protoBadge.innerHTML = '<a href="' + targetHttpsUrl + '" class="protocol-pill http" title="Click to switch to HTTPS on Port 9293">⚠️ HTTP &bull; Switch to HTTPS :9293</a>';
      }
    }

    // 2. WEBSOCKET CONNECTION
    function initWebSocket() {
      const wsProto = isHttps ? 'wss:' : 'ws:';
      const wsUrl = wsProto + '//' + window.location.host + '/ws';
      console.log('[WS] Connecting to ' + wsUrl);

      try {
        socket = new WebSocket(wsUrl);
        socket.binaryType = 'blob';

        socket.onopen = () => {
          console.log('[WS] Connected');
          isConnected = true;
          statusBadge.classList.remove('offline');
          statusText.innerText = 'ONLINE';
          showToast('Connected to ' + tvName);
          clearTimeout(reconnectTimer);
        };

        socket.onclose = () => {
          console.log('[WS] Disconnected');
          isConnected = false;
          statusBadge.classList.add('offline');
          statusText.innerText = 'OFFLINE';
          clearTimeout(reconnectTimer);
          reconnectTimer = setTimeout(initWebSocket, 2000);
        };

        socket.onerror = (err) => {
          console.error('[WS] Error', err);
        };

        socket.onmessage = (evt) => {
          if (typeof evt.data === 'string') {
            try {
              const data = JSON.parse(evt.data);
              handleStateMessage(data);
            } catch (e) {}
          }
        };
      } catch (e) {
        console.error('[WS] Connection exception', e);
        reconnectTimer = setTimeout(initWebSocket, 3000);
      }
    }

    function sendAction(action, payload = {}) {
      if (!socket || socket.readyState !== WebSocket.OPEN) {
        return;
      }
      socket.send(JSON.stringify({ action, payload, timestamp: Date.now() }));
    }

    function handleStateMessage(state) {
      if (state.clientCount !== undefined) {
        // Can display viewer count if desired
      }
    }

    // 3. BIG SCREEN STREAMING SOURCES
    function switchStreamSource(source) {
      currentSource = source;

      // Update buttons
      document.getElementById('btnSrcTv').classList.toggle('active', source === 'tv_screen');
      document.getElementById('btnSrcWebcam').classList.toggle('active', source === 'webcam');
      document.getElementById('btnSrcHw').classList.toggle('active', source === 'hardware');

      // Stop previous streams
      tvScreenPolling = false;
      if (localStream) {
        localStream.getTracks().forEach(t => t.stop());
        localStream = null;
      }
      streamImg.src = '';

      // Hide all viewports
      tvScreenImg.style.display = 'none';
      localVideo.style.display = 'none';
      streamImg.style.display = 'none';
      deviceBar.style.display = 'none';
      audioToggleBtn.style.display = 'none';

      if (source === 'tv_screen') {
        document.getElementById('liveLabel').innerText = 'TV SYSTEM SCREEN';
        tvScreenImg.style.display = 'block';
        screenLoader.style.display = 'flex';
        loaderMsg.innerText = 'Mirroring TV Screen...';
        tvScreenPolling = true;
        pollTvScreen();
      } else if (source === 'webcam') {
        document.getElementById('liveLabel').innerText = 'DIRECT WEBCAM / CAPTURE';
        localVideo.style.display = 'block';
        deviceBar.style.display = 'flex';
        audioToggleBtn.style.display = 'flex';
        initWebcamDevices();
      } else if (source === 'hardware') {
        document.getElementById('liveLabel').innerText = 'HARDWARE FEED';
        streamImg.style.display = 'block';
        screenLoader.style.display = 'flex';
        loaderMsg.innerText = 'Loading TV Capture Feed...';
        streamImg.src = '/stream.mjpg?t=' + Date.now();
        streamImg.onload = () => screenLoader.style.display = 'none';
      }
    }

    // TV SCREEN LIVE MIRROR LOOP
    function pollTvScreen() {
      if (!tvScreenPolling || currentSource !== 'tv_screen') return;

      const img = new Image();
      const startTime = Date.now();
      img.onload = () => {
        if (!tvScreenPolling || currentSource !== 'tv_screen') return;
        tvScreenImg.src = img.src;
        screenLoader.style.display = 'none';

        const elapsed = Date.now() - startTime;
        const delay = Math.max(30, 90 - elapsed);
        setTimeout(pollTvScreen, delay);
      };

      img.onerror = () => {
        if (!tvScreenPolling || currentSource !== 'tv_screen') return;
        setTimeout(pollTvScreen, 200);
      };

      img.src = '/tv_screen.jpg?t=' + Date.now();
    }

    // DIRECT WEBCAM / USB CAPTURE CARD VIA getUserMedia
    async function initWebcamDevices() {
      if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
        loaderMsg.innerText = 'Webcam requires HTTPS (switch to port 9293)';
        showToast('Webcam requires HTTPS: Use Port 9293');
        return;
      }

      screenLoader.style.display = 'flex';
      loaderMsg.innerText = 'Enumerating Capture Devices...';

      try {
        // Request temporary access to enumerate labels
        const tempStream = await navigator.mediaDevices.getUserMedia({ video: true, audio: false });
        tempStream.getTracks().forEach(t => t.stop());

        const devices = await navigator.mediaDevices.enumerateDevices();
        const videoDevices = devices.filter(d => d.kind === 'videoinput');

        videoSourceSelect.innerHTML = '';
        if (videoDevices.length === 0) {
          videoSourceSelect.innerHTML = '<option value="">No cameras / capture cards found</option>';
          screenLoader.style.display = 'none';
          return;
        }

        let selectedId = videoDevices[0].deviceId;
        videoDevices.forEach((dev, idx) => {
          const opt = document.createElement('option');
          opt.value = dev.deviceId;
          opt.text = dev.label || ('Camera / Capture Card ' + (idx + 1));
          // Prioritize USB Video / Capture card
          if (dev.label.toLowerCase().includes('usb video') || dev.label.toLowerCase().includes('capture') || dev.label.toLowerCase().includes('cam link')) {
            opt.selected = true;
            selectedId = dev.deviceId;
          }
          videoSourceSelect.appendChild(opt);
        });

        startWebcamStream(selectedId);
      } catch (err) {
        console.error('[Webcam] Access error', err);
        loaderMsg.innerText = 'Camera permission denied or not on HTTPS';
        showToast('Camera error: ' + err.message);
      }
    }

    async function startWebcamStream(deviceId) {
      if (localStream) {
        localStream.getTracks().forEach(t => t.stop());
      }

      screenLoader.style.display = 'flex';
      loaderMsg.innerText = 'Starting 60FPS Direct Capture...';

      const constraints = {
        video: {
          deviceId: deviceId ? { exact: deviceId } : undefined,
          width: { ideal: 1920, min: 1280 },
          height: { ideal: 1080, min: 720 },
          frameRate: { ideal: 60, min: 30 }
        },
        audio: true
      };

      try {
        localStream = await navigator.mediaDevices.getUserMedia(constraints);
        localVideo.srcObject = localStream;
        localVideo.onloadedmetadata = () => {
          screenLoader.style.display = 'none';
          localVideo.play();
        };
      } catch (err) {
        // Fallback without audio constraint
        try {
          constraints.audio = false;
          localStream = await navigator.mediaDevices.getUserMedia(constraints);
          localVideo.srcObject = localStream;
          localVideo.onloadedmetadata = () => {
            screenLoader.style.display = 'none';
            localVideo.play();
          };
        } catch (e2) {
          loaderMsg.innerText = 'Failed to open video stream: ' + e2.message;
        }
      }
    }

    function onCameraSourceChanged() {
      const selectedId = videoSourceSelect.value;
      if (selectedId) {
        startWebcamStream(selectedId);
      }
    }

    function toggleCaptureAudio() {
      if (!localStream) return;
      const audioTracks = localStream.getAudioTracks();
      if (audioTracks.length === 0) {
        showToast('No audio track available on capture card');
        return;
      }
      localVideo.muted = !localVideo.muted;
      audioToggleBtn.innerText = localVideo.muted ? '🔇 Audio' : '🔊 Audio ON';
      showToast(localVideo.muted ? 'Audio Muted' : 'Audio Unmuted');
    }

    // 4. INTERACTIVE BIG SCREEN: MOUSE MOVE & CLICK ON STREAM SENDS TO TV
    function setupInteractiveScreen() {
      function getTvCoords(e) {
        const rect = screenViewport.getBoundingClientRect();
        let clientX = e.clientX;
        let clientY = e.clientY;

        if (clientX === undefined && e.touches && e.touches.length > 0) {
          clientX = e.touches[0].clientX;
          clientY = e.touches[0].clientY;
        } else if (clientX === undefined && e.changedTouches && e.changedTouches.length > 0) {
          clientX = e.changedTouches[0].clientX;
          clientY = e.changedTouches[0].clientY;
        }
        if (clientX === undefined) clientX = rect.left + rect.width / 2;
        if (clientY === undefined) clientY = rect.top + rect.height / 2;

        let activeEl = tvScreenImg;
        if (currentSource === 'webcam') activeEl = localVideo;
        else if (currentSource === 'hardware') activeEl = streamImg;

        const natW = activeEl.videoWidth || activeEl.naturalWidth || 1920;
        const natH = activeEl.videoHeight || activeEl.naturalHeight || 1080;
        const aspect = (natW > 0 && natH > 0) ? (natW / natH) : (16 / 9);

        const contW = rect.width;
        const contH = rect.height;
        const contAspect = contW / contH;

        let renderW, renderH, offsetX, offsetY;
        if (contAspect > aspect) {
          renderH = contH;
          renderW = contH * aspect;
          offsetX = (contW - renderW) / 2;
          offsetY = 0;
        } else {
          renderW = contW;
          renderH = contW / aspect;
          offsetX = 0;
          offsetY = (contH - renderH) / 2;
        }

        const clickX = clientX - rect.left - offsetX;
        const clickY = clientY - rect.top - offsetY;

        const normX = Math.max(0, Math.min(1, clickX / renderW));
        const normY = Math.max(0, Math.min(1, clickY / renderH));

        const tvX = Math.round(normX * 1920);
        const tvY = Math.round(normY * 1080);

        return { tvX, tvY, relX: clientX - rect.left, relY: clientY - rect.top };
      }

      screenViewport.addEventListener('mousemove', (e) => {
        const coords = getTvCoords(e);
        currentCursorX = coords.tvX;
        currentCursorY = coords.tvY;

        coordsBadge.innerText = 'X: ' + coords.tvX + ' | Y: ' + coords.tvY;
        screenCursorDot.style.left = coords.relX + 'px';
        screenCursorDot.style.top = coords.relY + 'px';
        screenCursorDot.style.display = 'block';

        if (!mouseSyncEnabled) return;

        const now = Date.now();
        if (now - lastMoveSent > 35) { // ~28 Hz throttle
          lastMoveSent = now;
          sendAction('MOVE_CURSOR', { x: coords.tvX, y: coords.tvY });
        }
      });

      screenViewport.addEventListener('mouseleave', () => {
        screenCursorDot.style.display = 'none';
      });

      let viewportMouseDownTime = 0;
      let viewportMouseDownX = 0;
      let viewportMouseDownY = 0;

      screenViewport.addEventListener('mousedown', (e) => {
        if (e.button !== 0) return;
        viewportMouseDownTime = Date.now();
        viewportMouseDownX = e.clientX;
        viewportMouseDownY = e.clientY;
      });

      screenViewport.addEventListener('touchstart', (e) => {
        if (e.touches && e.touches.length > 0) {
          viewportMouseDownTime = Date.now();
          viewportMouseDownX = e.touches[0].clientX;
          viewportMouseDownY = e.touches[0].clientY;
        }
      }, { passive: true });

      screenViewport.addEventListener('click', (e) => {
        if (e.button && e.button !== 0) return;
        // Verify this was an intentional stationary click, NOT a drag, scroll, or swipe!
        const elapsed = Date.now() - viewportMouseDownTime;
        const dist = Math.hypot(e.clientX - viewportMouseDownX, e.clientY - viewportMouseDownY);
        if (elapsed > 350 || dist > 6) {
          return; // Was a drag or scroll gesture, do not tap!
        }

        const coords = getTvCoords(e);
        currentCursorX = coords.tvX;
        currentCursorY = coords.tvY;

        // Visual ripple
        clickRipple.style.left = coords.relX + 'px';
        clickRipple.style.top = coords.relY + 'px';
        clickRipple.classList.remove('animate');
        void clickRipple.offsetWidth;
        clickRipple.classList.add('animate');

        // Send System-Wide Tap to TV
        sendAction('SYS_TAP', { x: coords.tvX, y: coords.tvY });
        showToast('TV Click: (' + coords.tvX + ', ' + coords.tvY + ')');
      });

      // Right-Click on Big Screen acts as TV Back Button
      screenViewport.addEventListener('contextmenu', (e) => {
        e.preventDefault();
        e.stopPropagation();
        triggerBack('Right-Click');
      });

      // Touch for mobile / tablet
      screenViewport.addEventListener('touchmove', (e) => {
        const coords = getTvCoords(e);
        coordsBadge.innerText = 'X: ' + coords.tvX + ' | Y: ' + coords.tvY;
        if (!mouseSyncEnabled) return;
        const now = Date.now();
        if (now - lastMoveSent > 45) {
          lastMoveSent = now;
          sendAction('MOVE_CURSOR', { x: coords.tvX, y: coords.tvY });
        }
      }, { passive: true });
    }

    function toggleMouseSync() {
      mouseSyncEnabled = !mouseSyncEnabled;
      mouseSyncBtn.classList.toggle('active', mouseSyncEnabled);
      mouseSyncBtn.innerText = mouseSyncEnabled ? '🖱️ TV Sync: ON' : '🖱️ TV Sync: OFF';
      showToast(mouseSyncEnabled ? 'Mouse Sync to TV Enabled' : 'Mouse Sync Disabled');
    }

    function toggleFullscreen() {
      screenCard.classList.toggle('fullscreen-mode');
    }

    async function togglePip() {
      try {
        if (document.pictureInPictureElement) {
          await document.exitPictureInPicture();
        } else if (localVideo && localVideo.srcObject) {
          await localVideo.requestPictureInPicture();
        } else {
          showToast('PiP active when Webcam/Capture is selected');
        }
      } catch (e) {
        showToast('PiP error: ' + e.message);
      }
    }

    // 5. TRACKPAD GESTURES (TOUCH & DRAG SURFACE)
    function setupTouchpad() {
      let isTouching = false;
      let lastTouchX = 0;
      let lastTouchY = 0;
      let hasMoved = false;

      function onTouchStart(x, y) {
        isTouching = true;
        hasMoved = false;
        lastTouchX = x;
        lastTouchY = y;
        touchpadDot.style.left = x + 'px';
        touchpadDot.style.top = y + 'px';
        touchpadDot.style.display = 'block';
      }

      function onTouchMove(x, y) {
        if (!isTouching) return;
        const dx = x - lastTouchX;
        const dy = y - lastTouchY;
        lastTouchX = x;
        lastTouchY = y;

        if (Math.abs(dx) > 1 || Math.abs(dy) > 1) {
          hasMoved = true;
          touchpadDot.style.left = x + 'px';
          touchpadDot.style.top = y + 'px';

          // Keep JavaScript currentCursorX and currentCursorY synchronized with TV cursor
          currentCursorX = Math.max(0, Math.min(1920, Math.round(currentCursorX + dx * 2.2)));
          currentCursorY = Math.max(0, Math.min(1080, Math.round(currentCursorY + dy * 2.2)));

          coordsBadge.innerText = 'X: ' + currentCursorX + ' | Y: ' + currentCursorY;
          sendAction('MOVE_CURSOR', { x: currentCursorX, y: currentCursorY });
        }
      }

      function onTouchEnd() {
        if (!isTouching) return;
        isTouching = false;
        touchpadDot.style.display = 'none';
        // Note: Do NOT auto-tap on touchpad release to eliminate phantom clicks while dragging
      }

      // Mouse events on trackpad
      touchpad.addEventListener('mousedown', (e) => {
        if (e.button && e.button !== 0) return; // Ignore right-click/middle-click (handled by contextmenu)
        const rect = touchpad.getBoundingClientRect();
        onTouchStart(e.clientX - rect.left, e.clientY - rect.top);
      });

      // Right-Click on Touchpad acts as TV Back Button
      touchpad.addEventListener('contextmenu', (e) => {
        e.preventDefault();
        e.stopPropagation();
        triggerBack('Right-Click');
      });

      window.addEventListener('mousemove', (e) => {
        if (!isTouching) return;
        const rect = touchpad.getBoundingClientRect();
        onTouchMove(e.clientX - rect.left, e.clientY - rect.top);
      });

      window.addEventListener('mouseup', () => {
        onTouchEnd();
      });

      // Touch events on trackpad
      touchpad.addEventListener('touchstart', (e) => {
        e.preventDefault();
        const rect = touchpad.getBoundingClientRect();
        const touch = e.touches[0];
        onTouchStart(touch.clientX - rect.left, touch.clientY - rect.top);
      }, { passive: false });

      touchpad.addEventListener('touchmove', (e) => {
        e.preventDefault();
        const rect = touchpad.getBoundingClientRect();
        const touch = e.touches[0];
        onTouchMove(touch.clientX - rect.left, touch.clientY - rect.top);
      }, { passive: false });

      touchpad.addEventListener('touchend', (e) => {
        e.preventDefault();
        onTouchEnd();
      }, { passive: false });
    }

    function sendPadTap() {
      sendAction('SYS_TAP', { x: currentCursorX, y: currentCursorY });
      showToast('Clicking TV at (' + currentCursorX + ', ' + currentCursorY + ')');
    }

    // 6. CONTROLLER BUTTON DISPATCHER
    function setupControllerButtons() {
      document.querySelectorAll('[data-cmd]').forEach(btn => {
        btn.addEventListener('click', () => {
          const cmd = btn.getAttribute('data-cmd');
          sendAction(cmd);
          if (navigator.vibrate) navigator.vibrate(20);
          btn.blur(); // Blur button so browser Enter/Space does not re-trigger it
        });
      });
    }

    // 7. KEYBOARD INPUT TO TV
    function sendKeyboardText() {
      const text = keyboardInput.value.trim();
      if (!text) return;
      sendAction('TYPE_TEXT', { text });
      keyboardInput.value = '';
      showToast('Typed: "' + text + '"');
    }

    keyboardInput.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        sendKeyboardText();
      }
    });

    // 8. GLOBAL SHORTCUTS (RIGHT-CLICK BACK & MOUSE THUMB BUTTON ONLY)
    let lastBackTriggerTime = 0;
    function triggerBack(source) {
      const now = Date.now();
      if (now - lastBackTriggerTime < 350) return; // Debounce to prevent duplicate presses
      lastBackTriggerTime = now;
      sendAction('SYS_BACK');
      showToast('↩ Back (' + source + ')');
    }

    function setupGlobalShortcuts() {
      // Right-Click anywhere (except text input fields) acts as TV Back Button
      document.addEventListener('contextmenu', (e) => {
        if (e.target && (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA')) {
          return; // Allow native context menu for copy/paste into TV text inputs
        }
        e.preventDefault();
        triggerBack('Right-Click');
      });

      // Mouse Back Button (side thumb button / button 3)
      window.addEventListener('mouseup', (e) => {
        if (e.button === 3) {
          e.preventDefault();
          triggerBack('Mouse Button');
        }
      });
      window.addEventListener('auxclick', (e) => {
        if (e.button === 3) {
          e.preventDefault();
          triggerBack('Mouse Button');
        }
      });
    }

    // 9. TOAST NOTIFIER
    function showToast(msg) {
      const toast = document.getElementById('toast');
      toast.innerText = msg;
      toast.classList.add('show');
      setTimeout(() => toast.classList.remove('show'), 2000);
    }

    // INITIALIZATION
    window.addEventListener('DOMContentLoaded', () => {
      renderProtocolBadge();
      initWebSocket();
      setupInteractiveScreen();
      setupTouchpad();
      setupControllerButtons();
      setupGlobalShortcuts();
      switchStreamSource('tv_screen');
    });
  </script>
</body>
</html>
''';
  }
}
