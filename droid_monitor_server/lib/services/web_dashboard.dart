class WebDashboard {
  static const String html = r'''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>DroidMonitor • HTTPS Telemetry & File Server</title>
<style>
  :root {
    --bg-base: #0a0e17;
    --bg-card: rgba(18, 24, 38, 0.7);
    --bg-card-hover: rgba(26, 35, 56, 0.85);
    --border: rgba(0, 242, 254, 0.15);
    --border-bright: rgba(0, 242, 254, 0.4);
    --cyan: #00f2fe;
    --blue: #4facfe;
    --emerald: #00f5a0;
    --amber: #f6d365;
    --crimson: #ff5858;
    --purple: #c471ed;
    --text: #e6edf3;
    --text-muted: #8b949e;
    --text-dim: #6e7681;
    --radius: 14px;
    --font-mono: 'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, monospace;
    --font-sans: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
  }

  * { box-sizing: border-box; margin: 0; padding: 0; }

  body {
    background: radial-gradient(circle at 50% 0%, #111a2e 0%, var(--bg-base) 70%);
    color: var(--text);
    font-family: var(--font-sans);
    min-height: 100vh;
    padding-bottom: 60px;
    overflow-x: hidden;
  }

  /* Header */
  header {
    background: rgba(10, 14, 23, 0.8);
    backdrop-filter: blur(16px);
    -webkit-backdrop-filter: blur(16px);
    border-bottom: 1px solid var(--border);
    position: sticky;
    top: 0;
    z-index: 100;
    padding: 14px 24px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    flex-wrap: wrap;
    gap: 12px;
  }

  .brand {
    display: flex;
    align-items: center;
    gap: 12px;
  }

  .logo-icon {
    width: 38px;
    height: 38px;
    background: linear-gradient(135deg, var(--cyan), var(--blue));
    border-radius: 10px;
    display: flex;
    align-items: center;
    justify-content: center;
    box-shadow: 0 0 20px rgba(0, 242, 254, 0.35);
  }

  .brand-title {
    font-size: 1.25rem;
    font-weight: 700;
    background: linear-gradient(120deg, #fff, #bbf2f6);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    letter-spacing: -0.5px;
  }

  .brand-badge {
    background: rgba(0, 242, 254, 0.12);
    border: 1px solid var(--border);
    color: var(--cyan);
    font-size: 0.72rem;
    font-weight: 600;
    padding: 3px 8px;
    border-radius: 6px;
    font-family: var(--font-mono);
  }

  .header-actions {
    display: flex;
    align-items: center;
    gap: 12px;
  }

  .status-pill {
    display: flex;
    align-items: center;
    gap: 8px;
    background: rgba(0, 245, 160, 0.1);
    border: 1px solid rgba(0, 245, 160, 0.3);
    color: var(--emerald);
    padding: 6px 14px;
    border-radius: 20px;
    font-size: 0.8rem;
    font-weight: 600;
  }

  .pulse-dot {
    width: 8px;
    height: 8px;
    background: var(--emerald);
    border-radius: 50%;
    box-shadow: 0 0 8px var(--emerald);
    animation: pulse 2s infinite;
  }

  @keyframes pulse {
    0% { transform: scale(0.95); opacity: 0.8; }
    50% { transform: scale(1.3); opacity: 1; }
    100% { transform: scale(0.95); opacity: 0.8; }
  }

  /* Navigation Tabs */
  .nav-bar {
    max-width: 1280px;
    margin: 20px auto 0;
    padding: 0 20px;
    display: flex;
    gap: 10px;
    border-bottom: 1px solid rgba(255,255,255,0.06);
    overflow-x: auto;
  }

  .nav-tab {
    background: none;
    border: none;
    outline: none;
    color: var(--text-muted);
    font-size: 0.95rem;
    font-weight: 600;
    padding: 12px 18px;
    cursor: pointer;
    border-bottom: 2px solid transparent;
    display: flex;
    align-items: center;
    gap: 8px;
    transition: all 0.2s ease;
    white-space: nowrap;
  }

  .nav-tab:hover {
    color: var(--text);
  }

  .nav-tab.active {
    color: var(--cyan);
    border-bottom-color: var(--cyan);
  }

  /* Layout Container */
  .container {
    max-width: 1280px;
    margin: 24px auto;
    padding: 0 20px;
  }

  .tab-pane {
    display: none;
    animation: fadeIn 0.3s ease;
  }

  .tab-pane.active {
    display: block;
  }

  @keyframes fadeIn {
    from { opacity: 0; transform: translateY(6px); }
    to { opacity: 1; transform: translateY(0); }
  }

  /* Telemetry Grid */
  .stats-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
    gap: 20px;
    margin-bottom: 24px;
  }

  .card {
    background: var(--bg-card);
    backdrop-filter: blur(12px);
    -webkit-backdrop-filter: blur(12px);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    padding: 20px;
    transition: transform 0.2s ease, border-color 0.2s ease;
    position: relative;
    overflow: hidden;
  }

  .card:hover {
    border-color: var(--border-bright);
    background: var(--bg-card-hover);
  }

  .card-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 16px;
  }

  .card-title {
    font-size: 0.9rem;
    font-weight: 600;
    color: var(--text-muted);
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  .gauge-wrap {
    display: flex;
    align-items: center;
    justify-content: center;
    position: relative;
    margin: 10px 0;
  }

  .gauge-svg {
    transform: rotate(-90deg);
  }

  .gauge-bg {
    fill: none;
    stroke: rgba(255, 255, 255, 0.08);
    stroke-width: 9;
  }

  .gauge-fill {
    fill: none;
    stroke-width: 9;
    stroke-linecap: round;
    transition: stroke-dashoffset 0.6s cubic-bezier(0.4, 0, 0.2, 1), stroke 0.3s ease;
  }

  .gauge-value {
    position: absolute;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
  }

  .gauge-num {
    font-size: 1.8rem;
    font-weight: 800;
    font-family: var(--font-mono);
  }

  .gauge-sub {
    font-size: 0.75rem;
    color: var(--text-muted);
  }

  .card-footer {
    display: flex;
    align-items: center;
    justify-content: space-between;
    font-size: 0.82rem;
    color: var(--text-muted);
    border-top: 1px solid rgba(255,255,255,0.06);
    padding-top: 12px;
    margin-top: 12px;
  }

  .highlight-val {
    color: var(--text);
    font-weight: 600;
    font-family: var(--font-mono);
  }

  /* Mini Sparkline */
  .sparkline-box {
    width: 100%;
    height: 48px;
    margin-top: 12px;
  }

  /* Task Manager Section */
  .task-header-bar {
    display: flex;
    align-items: center;
    justify-content: space-between;
    flex-wrap: wrap;
    gap: 12px;
    margin-bottom: 16px;
  }

  .search-box {
    background: rgba(14, 20, 32, 0.8);
    border: 1px solid var(--border);
    border-radius: 8px;
    padding: 8px 14px;
    color: var(--text);
    font-size: 0.9rem;
    outline: none;
    width: 300px;
    max-width: 100%;
    transition: border-color 0.2s;
  }

  .search-box:focus {
    border-color: var(--cyan);
  }

  .filter-group {
    display: flex;
    gap: 8px;
  }

  .btn {
    background: rgba(0, 242, 254, 0.1);
    border: 1px solid var(--border);
    color: var(--cyan);
    padding: 8px 16px;
    border-radius: 8px;
    cursor: pointer;
    font-size: 0.85rem;
    font-weight: 600;
    display: inline-flex;
    align-items: center;
    gap: 6px;
    transition: all 0.2s ease;
  }

  .btn:hover {
    background: rgba(0, 242, 254, 0.2);
    border-color: var(--cyan);
    color: #fff;
  }

  .btn-danger {
    background: rgba(255, 88, 88, 0.1);
    border-color: rgba(255, 88, 88, 0.3);
    color: var(--crimson);
  }

  .btn-danger:hover {
    background: rgba(255, 88, 88, 0.25);
    border-color: var(--crimson);
    color: #fff;
  }

  .btn-primary {
    background: linear-gradient(135deg, var(--cyan), var(--blue));
    color: #05101a;
    border: none;
    font-weight: 700;
  }

  .btn-primary:hover {
    opacity: 0.92;
    box-shadow: 0 0 15px rgba(0, 242, 254, 0.4);
  }

  .table-card {
    background: var(--bg-card);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    overflow: hidden;
  }

  .table-responsive {
    overflow-x: auto;
  }

  table {
    width: 100%;
    border-collapse: collapse;
    text-align: left;
    font-size: 0.88rem;
  }

  th {
    background: rgba(255,255,255,0.03);
    color: var(--text-muted);
    font-weight: 600;
    padding: 12px 16px;
    border-bottom: 1px solid rgba(255,255,255,0.08);
    text-transform: uppercase;
    font-size: 0.75rem;
    letter-spacing: 0.5px;
  }

  td {
    padding: 12px 16px;
    border-bottom: 1px solid rgba(255,255,255,0.04);
  }

  tr:hover td {
    background: rgba(0, 242, 254, 0.03);
  }

  .badge {
    padding: 3px 8px;
    border-radius: 4px;
    font-size: 0.75rem;
    font-weight: 600;
    font-family: var(--font-mono);
  }

  .badge-system {
    background: rgba(196, 113, 237, 0.15);
    color: var(--purple);
    border: 1px solid rgba(196, 113, 237, 0.3);
  }

  .badge-app {
    background: rgba(79, 172, 254, 0.15);
    color: var(--blue);
    border: 1px solid rgba(79, 172, 254, 0.3);
  }

  .badge-state {
    background: rgba(0, 245, 160, 0.12);
    color: var(--emerald);
  }

  /* File Hosting Section */
  .upload-dropzone {
    border: 2px dashed rgba(0, 242, 254, 0.3);
    background: rgba(0, 242, 254, 0.02);
    border-radius: var(--radius);
    padding: 40px 20px;
    text-align: center;
    cursor: pointer;
    transition: all 0.2s ease;
    margin-bottom: 24px;
  }

  .upload-dropzone.dragover {
    background: rgba(0, 242, 254, 0.08);
    border-color: var(--cyan);
    transform: scale(1.01);
  }

  .drop-icon {
    font-size: 2.8rem;
    margin-bottom: 12px;
    color: var(--cyan);
  }

  .drop-text {
    font-size: 1.1rem;
    font-weight: 600;
    margin-bottom: 6px;
  }

  .drop-sub {
    font-size: 0.85rem;
    color: var(--text-muted);
  }

  .progress-wrap {
    margin: 16px 0;
    display: none;
  }

  .progress-bar-bg {
    background: rgba(255,255,255,0.08);
    height: 8px;
    border-radius: 4px;
    overflow: hidden;
  }

  .progress-bar-fill {
    height: 100%;
    width: 0%;
    background: linear-gradient(90deg, var(--cyan), var(--emerald));
    transition: width 0.2s ease;
  }

  .progress-meta {
    display: flex;
    justify-content: space-between;
    font-size: 0.8rem;
    color: var(--text-muted);
    margin-top: 6px;
  }

  .files-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
    gap: 16px;
  }

  .file-card {
    background: var(--bg-card);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    padding: 16px;
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    transition: all 0.2s ease;
  }

  .file-card:hover {
    border-color: var(--cyan);
    background: var(--bg-card-hover);
    transform: translateY(-2px);
  }

  .file-info {
    display: flex;
    align-items: flex-start;
    gap: 12px;
    margin-bottom: 14px;
  }

  .file-icon {
    width: 42px;
    height: 42px;
    border-radius: 8px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 1.4rem;
    flex-shrink: 0;
    background: rgba(79, 172, 254, 0.15);
    border: 1px solid rgba(79, 172, 254, 0.3);
  }

  .file-name {
    font-weight: 600;
    font-size: 0.92rem;
    word-break: break-all;
    line-height: 1.3;
    margin-bottom: 4px;
  }

  .file-meta {
    font-size: 0.78rem;
    color: var(--text-muted);
    font-family: var(--font-mono);
  }

  .file-actions {
    display: flex;
    gap: 8px;
    border-top: 1px solid rgba(255,255,255,0.06);
    padding-top: 12px;
  }

  /* Modal Preview */
  .modal-backdrop {
    position: fixed;
    top: 0; left: 0; right: 0; bottom: 0;
    background: rgba(0,0,0,0.85);
    backdrop-filter: blur(8px);
    display: none;
    align-items: center;
    justify-content: center;
    z-index: 1000;
    padding: 20px;
  }

  .modal-backdrop.active {
    display: flex;
  }

  .modal-box {
    background: #111726;
    border: 1px solid var(--border-bright);
    border-radius: var(--radius);
    max-width: 900px;
    width: 100%;
    max-height: 85vh;
    display: flex;
    flex-direction: column;
    overflow: hidden;
  }

  .modal-head {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 16px 20px;
    border-bottom: 1px solid rgba(255,255,255,0.08);
  }

  .modal-title {
    font-size: 1rem;
    font-weight: 600;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .modal-body {
    padding: 20px;
    overflow: auto;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .modal-body img, .modal-body video {
    max-width: 100%;
    max-height: 60vh;
    border-radius: 8px;
  }

  .toast {
    position: fixed;
    bottom: 24px;
    right: 24px;
    background: #162035;
    border: 1px solid var(--cyan);
    color: #fff;
    padding: 12px 20px;
    border-radius: 8px;
    font-size: 0.88rem;
    box-shadow: 0 8px 24px rgba(0,0,0,0.4);
    z-index: 2000;
    display: none;
  }
</style>
</head>
<body>

<header>
  <div class="brand">
    <div class="logo-icon">
      <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#05101a" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
        <rect x="2" y="3" width="20" height="14" rx="2" ry="2"></rect>
        <line x1="8" y1="21" x2="16" y2="21"></line>
        <line x1="12" y1="17" x2="12" y2="21"></line>
      </svg>
    </div>
    <div>
      <div style="display: flex; align-items: center; gap: 8px;">
        <span class="brand-title">DroidMonitor</span>
        <span class="brand-badge">HTTPS :1212</span>
      </div>
      <div style="font-size: 0.75rem; color: var(--text-muted);" id="device-model-header">Android System Telemetry</div>
    </div>
  </div>

  <div class="header-actions">
    <div class="status-pill">
      <div class="pulse-dot"></div>
      <span id="conn-status">ONLINE</span>
    </div>
    <button class="btn" onclick="fetchStats(true)">
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21.5 2v6h-6M21.34 15.57a10 10 0 1 1-.57-8.38l5.67-5.67"/></svg>
      Sync
    </button>
  </div>
</header>

<div class="nav-bar">
  <button class="nav-tab active" onclick="switchTab('overview')">
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/></svg>
    Overview
  </button>
  <button class="nav-tab" onclick="switchTab('tasks')">
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="8" y1="6" x2="21" y2="6"/><line x1="8" y1="12" x2="21" y2="12"/><line x1="8" y1="18" x2="21" y2="18"/><line x1="3" y1="6" x2="3.01" y2="6"/><line x1="3" y1="12" x2="3.01" y2="12"/><line x1="3" y1="18" x2="3.01" y2="18"/></svg>
    Task Manager (<span id="task-count-badge">0</span>)
  </button>
  <button class="nav-tab" onclick="switchTab('files')">
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/></svg>
    File Hosting & Serving (<span id="file-count-badge">0</span>)
  </button>
  <button class="nav-tab" onclick="switchTab('screen')">
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="3" width="20" height="14" rx="2" ry="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>
    Screen Capture 📸
  </button>
  <button class="nav-tab" onclick="switchTab('demos')">
    <span style="font-size: 1rem;">🎮</span>
    Interactive Demos ✨
  </button>
  <button class="nav-tab" onclick="switchTab('sysinfo')">
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>
    Hardware Specs
  </button>
</div>

<div class="container">

  <!-- OVERVIEW TAB -->
  <div id="tab-overview" class="tab-pane active">
    <div class="stats-grid">
      <!-- CPU Card -->
      <div class="card">
        <div class="card-header">
          <span class="card-title">CPU Utilization</span>
          <span class="badge badge-app" id="cpu-cores-text">8 Cores</span>
        </div>
        <div class="gauge-wrap">
          <svg class="gauge-svg" width="130" height="130">
            <circle class="gauge-bg" cx="65" cy="65" r="52"></circle>
            <circle class="gauge-fill" id="cpu-gauge-circle" cx="65" cy="65" r="52" stroke="var(--cyan)" stroke-dasharray="326.7" stroke-dashoffset="250"></circle>
          </svg>
          <div class="gauge-value">
            <span class="gauge-num" id="cpu-percent-text">--%</span>
            <span class="gauge-sub">LOAD</span>
          </div>
        </div>
        <!-- Sparkline Chart -->
        <svg class="sparkline-box" id="cpu-sparkline" preserveAspectRatio="none" viewBox="0 0 100 40">
          <defs>
            <linearGradient id="sparkGrad" x1="0%" y1="0%" x2="0%" y2="100%">
              <stop offset="0%" stop-color="rgba(0, 242, 254, 0.4)"/>
              <stop offset="100%" stop-color="rgba(0, 242, 254, 0.0)"/>
            </linearGradient>
          </defs>
          <polygon id="sparkline-fill" points="0,40 100,40" fill="url(#sparkGrad)"/>
          <path id="sparkline-path" d="M0,40 L100,40" fill="none" stroke="var(--cyan)" stroke-width="2"/>
        </svg>
        <div class="card-footer">
          <span>Processor:</span>
          <span class="highlight-val" id="cpu-hw-text">Loading...</span>
        </div>
      </div>

      <!-- RAM Card -->
      <div class="card">
        <div class="card-header">
          <span class="card-title">RAM Usage</span>
          <span class="badge badge-app" id="ram-status-badge">Normal</span>
        </div>
        <div class="gauge-wrap">
          <svg class="gauge-svg" width="130" height="130">
            <circle class="gauge-bg" cx="65" cy="65" r="52"></circle>
            <circle class="gauge-fill" id="ram-gauge-circle" cx="65" cy="65" r="52" stroke="var(--blue)" stroke-dasharray="326.7" stroke-dashoffset="160"></circle>
          </svg>
          <div class="gauge-value">
            <span class="gauge-num" id="ram-percent-text">--%</span>
            <span class="gauge-sub">USED</span>
          </div>
        </div>
        <div style="margin-top: 18px;">
          <div style="display: flex; justify-content: space-between; font-size: 0.85rem; margin-bottom: 6px;">
            <span style="color: var(--text-muted);">Used Memory:</span>
            <span class="highlight-val" id="ram-used-text">-- GB</span>
          </div>
          <div style="display: flex; justify-content: space-between; font-size: 0.85rem; margin-bottom: 6px;">
            <span style="color: var(--text-muted);">Available:</span>
            <span class="highlight-val" id="ram-avail-text">-- GB</span>
          </div>
        </div>
        <div class="card-footer">
          <span>Total Memory:</span>
          <span class="highlight-val" id="ram-total-text">-- GB</span>
        </div>
      </div>

      <!-- Temperatures Card -->
      <div class="card">
        <div class="card-header">
          <span class="card-title">Temperatures</span>
          <span class="badge badge-state" id="thermal-state-badge">Normal</span>
        </div>
        <div style="display: flex; justify-content: space-around; align-items: center; margin: 15px 0;">
          <div style="text-align: center;">
            <div style="font-size: 2.1rem; font-weight: 800; font-family: var(--font-mono);" id="cpu-temp-text">-- °C</div>
            <div style="font-size: 0.75rem; color: var(--text-muted); text-transform: uppercase;">CPU / SoC</div>
          </div>
          <div style="width: 1px; height: 50px; background: rgba(255,255,255,0.1);"></div>
          <div style="text-align: center;">
            <div style="font-size: 2.1rem; font-weight: 800; font-family: var(--font-mono); color: var(--emerald);" id="battery-temp-text">-- °C</div>
            <div style="font-size: 0.75rem; color: var(--text-muted); text-transform: uppercase;">Battery</div>
          </div>
        </div>
        <div style="margin-top: 14px;">
          <div style="display: flex; justify-content: space-between; font-size: 0.85rem; margin-bottom: 6px;">
            <span style="color: var(--text-muted);">Battery Charge:</span>
            <span class="highlight-val" id="battery-pct-text">--%</span>
          </div>
          <div style="display: flex; justify-content: space-between; font-size: 0.85rem; margin-bottom: 6px;">
            <span style="color: var(--text-muted);">Battery State:</span>
            <span class="highlight-val" id="battery-status-text">--</span>
          </div>
        </div>
        <div class="card-footer">
          <span>Battery Health:</span>
          <span class="highlight-val" id="battery-health-text">Good</span>
        </div>
      </div>

      <!-- Storage Card -->
      <div class="card">
        <div class="card-header">
          <span class="card-title">Storage Used</span>
          <span class="badge badge-app" id="storage-status-badge" style="background: rgba(196, 113, 237, 0.15); color: var(--purple); border: 1px solid rgba(196, 113, 237, 0.3);">Device</span>
        </div>
        <div class="gauge-wrap">
          <svg class="gauge-svg" width="130" height="130">
            <circle class="gauge-bg" cx="65" cy="65" r="52"></circle>
            <circle class="gauge-fill" id="storage-gauge-circle" cx="65" cy="65" r="52" stroke="var(--purple)" stroke-dasharray="326.7" stroke-dashoffset="160"></circle>
          </svg>
          <div class="gauge-value">
            <span class="gauge-num" id="storage-percent-text" style="color: var(--purple);">--%</span>
            <span class="gauge-sub">USED</span>
          </div>
        </div>
        <div style="margin-top: 18px;">
          <div style="display: flex; justify-content: space-between; font-size: 0.85rem; margin-bottom: 6px;">
            <span style="color: var(--text-muted);">Used Space:</span>
            <span class="highlight-val" id="storage-used-text">-- GB</span>
          </div>
          <div style="display: flex; justify-content: space-between; font-size: 0.85rem; margin-bottom: 6px;">
            <span style="color: var(--text-muted);">Free Space:</span>
            <span class="highlight-val" id="storage-free-text" style="color: var(--emerald);">-- GB</span>
          </div>
          <div style="display: flex; justify-content: space-between; font-size: 0.85rem; margin-bottom: 6px;">
            <span style="color: var(--text-muted);">Hosted Files Size:</span>
            <span class="highlight-val" id="storage-hosted-text" style="color: var(--cyan);">0 B</span>
          </div>
        </div>
        <div class="card-footer">
          <span>Total Storage:</span>
          <span class="highlight-val" id="storage-total-text">-- GB</span>
        </div>
      </div>

      <!-- Server & Storage Status Card -->
      <div class="card">
        <div class="card-header">
          <span class="card-title">Device & Server</span>
          <span class="badge badge-system">HTTPS 1212</span>
        </div>
        <div style="margin: 10px 0;">
          <div style="display: flex; justify-content: space-between; font-size: 0.85rem; margin-bottom: 8px;">
            <span style="color: var(--text-muted);">Device Model:</span>
            <span class="highlight-val" id="overview-model-text">Android</span>
          </div>
          <div style="display: flex; justify-content: space-between; font-size: 0.85rem; margin-bottom: 8px;">
            <span style="color: var(--text-muted);">OS Version:</span>
            <span class="highlight-val" id="overview-os-text">Android 14</span>
          </div>
          <div style="display: flex; justify-content: space-between; font-size: 0.85rem; margin-bottom: 8px;">
            <span style="color: var(--text-muted);">System Uptime:</span>
            <span class="highlight-val" id="overview-uptime-text">--</span>
          </div>
          <div style="display: flex; justify-content: space-between; font-size: 0.85rem; margin-bottom: 8px;">
            <span style="color: var(--text-muted);">Hosted Files:</span>
            <span class="highlight-val" id="overview-files-count">0 files</span>
          </div>
        </div>
        <div class="card-footer">
          <span>TLS Encryption:</span>
          <span class="highlight-val" style="color: var(--emerald);">Active (TLS 1.3/2048)</span>
        </div>
      </div>
    </div>

    <!-- Thermal Zones Detailed Card -->
    <div class="card" id="thermal-zones-card" style="display: none;">
      <div class="card-header">
        <span class="card-title">Active Thermal Zones</span>
      </div>
      <div id="thermal-zones-list" style="display: flex; flex-wrap: wrap; gap: 10px;"></div>
    </div>
  </div>

  <!-- TASK MANAGER TAB -->
  <div id="tab-tasks" class="tab-pane">
    <div class="task-header-bar">
      <input type="text" class="search-box" id="task-search-input" placeholder="Search tasks, apps, PID..." oninput="renderTasks()">
      <div class="filter-group">
        <button class="btn active" id="btn-filter-all" onclick="setTaskFilter('all')">All</button>
        <button class="btn" id="btn-filter-apps" onclick="setTaskFilter('apps')">Apps</button>
        <button class="btn" id="btn-filter-system" onclick="setTaskFilter('system')">System</button>
        <button class="btn" onclick="fetchTasks()">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21.5 2v6h-6M21.34 15.57a10 10 0 1 1-.57-8.38l5.67-5.67"/></svg>
          Refresh
        </button>
      </div>
    </div>

    <div class="table-card">
      <div class="table-responsive">
        <table>
          <thead>
            <tr>
              <th>PID</th>
              <th>Task / Process Name</th>
              <th>User</th>
              <th>Memory (RSS)</th>
              <th>Status</th>
              <th style="text-align: right;">Action</th>
            </tr>
          </thead>
          <tbody id="task-table-body">
            <tr><td colspan="6" style="text-align: center; color: var(--text-muted); padding: 30px;">Loading task manager data...</td></tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>

  <!-- FILE HOSTING & SERVING TAB -->
  <div id="tab-files" class="tab-pane">
    <!-- Storage Capacity & Footprint Banner -->
    <div class="card" style="margin-bottom: 20px; background: rgba(18, 24, 38, 0.7); border-color: rgba(0, 242, 254, 0.25);">
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; flex-wrap: wrap; gap: 8px;">
        <div style="display: flex; align-items: center; gap: 10px;">
          <div style="width: 36px; height: 36px; border-radius: 8px; background: rgba(196, 113, 237, 0.15); border: 1px solid rgba(196, 113, 237, 0.3); display: flex; align-items: center; justify-content: center; font-size: 1.2rem;">💾</div>
          <div>
            <div style="font-weight: 700; font-size: 1rem; color: #fff;">Device & Hosted Storage</div>
            <div style="font-size: 0.78rem; color: var(--text-muted);">Real-time device disk usage and uploaded file footprint</div>
          </div>
        </div>
        <div style="text-align: right;">
          <div style="font-size: 1.15rem; font-weight: 800; font-family: var(--font-mono); color: var(--cyan);" id="banner-hosted-size">0 B</div>
          <div style="font-size: 0.76rem; color: var(--text-muted);" id="banner-hosted-sub">Used by 0 hosted files</div>
        </div>
      </div>
      <div class="progress-bar-bg" style="height: 10px; margin-bottom: 8px;">
        <div class="progress-bar-fill" id="storage-capacity-bar" style="width: 0%; background: linear-gradient(90deg, var(--cyan), var(--purple));"></div>
      </div>
      <div style="display: flex; justify-content: space-between; font-size: 0.82rem; color: var(--text-muted); font-family: var(--font-mono);">
        <span>Used: <b style="color: var(--text);" id="banner-used-storage">-- GB</b> (<span id="banner-used-pct">--%</span>)</span>
        <span>Free: <b style="color: var(--emerald);" id="banner-free-storage">-- GB</b></span>
        <span>Total: <b style="color: var(--text);" id="banner-total-storage">-- GB</b></span>
      </div>
    </div>

    <!-- Drag & Drop Uploader -->
    <div class="upload-dropzone" id="dropzone" onclick="document.getElementById('file-input').click()">
      <input type="file" id="file-input" multiple style="display: none;" onchange="handleFileSelect(event)">
      <div class="drop-icon">☁️</div>
      <div class="drop-text">Drag & Drop Files Here to Host</div>
      <div class="drop-sub">or click to browse from your computer / phone (Any file type supported)</div>
      <div class="progress-wrap" id="progress-container">
        <div class="progress-bar-bg">
          <div class="progress-bar-fill" id="upload-progress-bar"></div>
        </div>
        <div class="progress-meta">
          <span id="upload-filename">Uploading...</span>
          <span id="upload-percentage">0%</span>
        </div>
      </div>
    </div>

    <!-- File Controls Bar -->
    <div class="task-header-bar">
      <input type="text" class="search-box" id="file-search-input" placeholder="Search hosted files..." oninput="renderFiles()">
      <div class="filter-group">
        <button class="btn btn-primary" onclick="document.getElementById('file-input').click()">+ Upload Files</button>
        <button class="btn" onclick="fetchFiles()">Refresh</button>
      </div>
    </div>

    <!-- Files Grid -->
    <div class="files-grid" id="files-grid-container">
      <div style="grid-column: 1/-1; text-align: center; color: var(--text-muted); padding: 40px;">No files hosted yet. Upload one above!</div>
    </div>
  </div>

  <!-- HARDWARE SPECS TAB -->
  <div id="tab-sysinfo" class="tab-pane">
    <div class="card">
      <div class="card-header">
        <span class="card-title">Complete Hardware & Software Specifications</span>
      </div>
      <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 16px;">
        <div class="card" style="background: rgba(255,255,255,0.02); border-color: rgba(255,255,255,0.06);">
          <div style="color: var(--cyan); font-weight: 600; margin-bottom: 8px;">DEVICE INFO</div>
          <div style="font-size: 0.88rem; line-height: 1.8;">
            <div>Model: <b id="spec-model">--</b></div>
            <div>Manufacturer: <b id="spec-mfg">--</b></div>
            <div>Hardware: <b id="spec-hw">--</b></div>
            <div>Android Version: <b id="spec-os">--</b></div>
          </div>
        </div>
        <div class="card" style="background: rgba(255,255,255,0.02); border-color: rgba(255,255,255,0.06);">
          <div style="color: var(--blue); font-weight: 600; margin-bottom: 8px;">CPU ARCHITECTURE</div>
          <div style="font-size: 0.88rem; line-height: 1.8;">
            <div>Cores: <b id="spec-cores">--</b></div>
            <div>Current Utilization: <b id="spec-usage">--%</b></div>
            <div>Frequencies: <b id="spec-freqs">--</b></div>
          </div>
        </div>
        <div class="card" style="background: rgba(255,255,255,0.02); border-color: rgba(255,255,255,0.06);">
          <div style="color: var(--emerald); font-weight: 600; margin-bottom: 8px;">SECURITY & SERVER</div>
          <div style="font-size: 0.88rem; line-height: 1.8;">
            <div>Port: <b>1212</b></div>
            <div>Protocol: <b>HTTPS (TLS Encrypted)</b></div>
            <div>Endpoints: <b>/api/stats, /api/tasks, /api/files</b></div>
            <div>File Streaming: <b>HTTP 206 Partial Content</b></div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- SCREEN CAPTURE TAB -->
  <div id="tab-screen" class="tab-pane">
    <div class="task-header-bar">
      <div style="display: flex; align-items: center; gap: 10px; flex-wrap: wrap;">
        <button class="btn btn-primary" id="btn-take-screenshot" onclick="captureLiveScreenshot()">
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"/><circle cx="12" cy="13" r="4"/></svg>
          Capture Screenshot
        </button>
        <button class="btn" id="btn-auto-refresh-screen" onclick="toggleScreenAutoRefresh()">
          ⏱️ Auto-Refresh: <span id="auto-refresh-state">OFF</span>
        </button>
      </div>
      <div class="filter-group">
        <a id="btn-download-screen" href="/api/screenshot?download=1" download="screen_capture.png" class="btn">
          📥 Download Image
        </a>
        <a id="btn-view-screen" href="/api/screenshot" target="_blank" class="btn">
          ↗️ Open Raw in Tab
        </a>
      </div>
    </div>

    <!-- Screen Preview Card -->
    <div class="card" style="padding: 18px; text-align: center; background: rgba(10, 14, 23, 0.95); border-color: rgba(0, 242, 254, 0.3);">
      <div style="display: flex; justify-content: space-between; font-size: 0.82rem; color: var(--text-muted); margin-bottom: 12px; padding: 0 4px; font-family: var(--font-mono);">
        <span>Status: <b id="screen-status" style="color: var(--emerald);">Display Live</b></span>
        <span id="screen-meta">Click "Capture Screenshot" to view latest display snapshot</span>
      </div>

      <div style="position: relative; min-height: 360px; display: flex; align-items: center; justify-content: center; background: #000; border-radius: 12px; overflow: hidden; border: 1px solid rgba(255,255,255,0.08); box-shadow: 0 0 30px rgba(0,0,0,0.8);">
        <img id="live-screen-img" src="/api/screenshot" alt="Device Screen Snapshot" style="max-width: 100%; max-height: 72vh; border-radius: 8px; object-fit: contain;" onload="onScreenLoaded()" onerror="onScreenError()">
        <div id="screen-loading-overlay" style="position: absolute; top:0; left:0; right:0; bottom:0; background: rgba(0,0,0,0.75); backdrop-filter: blur(4px); display: none; align-items: center; justify-content: center; flex-direction: column; gap: 12px;">
          <div class="pulse-dot" style="width: 16px; height: 16px; background: var(--cyan); box-shadow: 0 0 16px var(--cyan);"></div>
          <span style="font-size: 0.95rem; font-weight: 600; color: var(--cyan); font-family: var(--font-mono);">Capturing Entire Screen...</span>
        </div>
      </div>
    </div>
  </div>

  <!-- INTERACTIVE DEMOS TAB -->
  <div id="tab-demos" class="tab-pane">
    <div style="margin-bottom: 24px; display: flex; justify-content: space-between; align-items: flex-end; flex-wrap: wrap; gap: 12px;">
      <div>
        <h2 style="font-size: 1.4rem; font-weight: 800; margin-bottom: 6px; background: linear-gradient(135deg, var(--cyan), var(--purple)); -webkit-background-clip: text; -webkit-text-fill-color: transparent;">
          🎮 Embedded Web Experiments & Demos
        </h2>
        <p style="color: var(--text-muted); font-size: 0.88rem;">
          High-performance multiplayer web applications hosted directly from your device storage. Click any demo to launch it full-screen in a new tab!
        </p>
      </div>
      <button class="btn" onclick="restoreOptionalDemos()" style="padding: 8px 16px; font-weight: 700; background: rgba(168, 85, 247, 0.2); border-color: rgba(168, 85, 247, 0.4); color: #c084fc;">
        ⚡ Reinstall / Restore Optional Demos
      </button>
    </div>

    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 20px;">
      <!-- Demo 1: Multiplayer Canvas (Protected) -->
      <div class="card" style="background: rgba(18, 24, 38, 0.9); border-color: rgba(0, 242, 254, 0.3); display: flex; flex-direction: column; justify-content: space-between;">
        <div>
          <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px;">
            <div style="display: flex; align-items: center; gap: 10px;">
              <div style="width: 44px; height: 44px; border-radius: 12px; background: linear-gradient(135deg, #00f3ff, #ff0077); display: flex; align-items: center; justify-content: center; font-size: 1.5rem; box-shadow: 0 0 20px rgba(0, 243, 255, 0.4);">🎨</div>
              <div>
                <div style="font-weight: 800; font-size: 1.15rem; color: #fff;">DroidCanvas</div>
                <div style="font-size: 0.75rem; color: var(--cyan); font-family: var(--font-mono);">canvasdemo.html • WebSocket</div>
              </div>
            </div>
            <span class="badge" style="background: rgba(0, 255, 136, 0.15); color: #00ff88; border: 1px solid rgba(0, 255, 136, 0.3);">Multiplayer</span>
          </div>
          <p style="font-size: 0.86rem; color: var(--text-muted); line-height: 1.6; margin-bottom: 16px;">
            Draw collaboratively with other users in real-time over <b>WebSockets (<code style="color: var(--cyan);">/ws/canvas</code>)</b>. Features multi-user live cursors, smooth Bézier strokes, color palettes, brush sizes, and PNG export.
          </p>
        </div>
        <div style="display: flex; gap: 10px;">
          <a href="/files/canvasdemo.html" target="_blank" class="btn btn-primary" style="flex: 1; padding: 10px; text-decoration: none; text-align: center; font-weight: 700;">
            🚀 Open Canvas Demo
          </a>
          <a href="/files/canvasdemo.html" download class="btn" style="padding: 10px 14px; text-decoration: none;" title="Download HTML">📥</a>
        </div>
      </div>

      <!-- Demo 2: Sand Physics Sandbox (Protected) -->
      <div class="card" style="background: rgba(18, 24, 38, 0.9); border-color: rgba(234, 179, 8, 0.3); display: flex; flex-direction: column; justify-content: space-between;">
        <div>
          <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px;">
            <div style="display: flex; align-items: center; gap: 10px;">
              <div style="width: 44px; height: 44px; border-radius: 12px; background: linear-gradient(135deg, #eab308, #ef4444); display: flex; align-items: center; justify-content: center; font-size: 1.5rem; box-shadow: 0 0 20px rgba(234, 179, 8, 0.4);">🧪</div>
              <div>
                <div style="font-weight: 800; font-size: 1.15rem; color: #fff;">DroidSand</div>
                <div style="font-size: 0.75rem; color: #eab308; font-family: var(--font-mono);">sanddemo.html • 60 FPS Engine</div>
              </div>
            </div>
            <span class="badge" style="background: rgba(234, 179, 8, 0.15); color: #eab308; border: 1px solid rgba(234, 179, 8, 0.3);">Cellular Automata</span>
          </div>
          <p style="font-size: 0.86rem; color: var(--text-muted); line-height: 1.6; margin-bottom: 16px;">
            Full-fledged falling-sand physics simulation over <b>WebSockets (<code style="color: #eab308;">/ws/sand</code>)</b>. Experiment with <b>water, sand, fire, wood, liquid nitrogen, radioactive plutonium, C4 explosives, fuse lines, lava, ice, acid, and oil</b> with collaborative chain reactions!
          </p>
        </div>
        <div style="display: flex; gap: 10px;">
          <a href="/files/sanddemo.html" target="_blank" class="btn btn-primary" style="flex: 1; padding: 10px; text-decoration: none; text-align: center; font-weight: 700; background: rgba(234, 179, 8, 0.2); border-color: #eab308; color: #eab308;">
            🚀 Open Sandbox Physics
          </a>
          <a href="/files/sanddemo.html" download class="btn" style="padding: 10px 14px; text-decoration: none;" title="Download HTML">📥</a>
        </div>
      </div>

      <!-- Demo 3: Neon Particle Vortex (Protected) -->
      <div class="card" style="background: rgba(18, 24, 38, 0.9); border-color: rgba(255, 0, 119, 0.3); display: flex; flex-direction: column; justify-content: space-between;">
        <div>
          <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px;">
            <div style="display: flex; align-items: center; gap: 10px;">
              <div style="width: 44px; height: 44px; border-radius: 12px; background: linear-gradient(135deg, #ff0077, #7928ca); display: flex; align-items: center; justify-content: center; font-size: 1.5rem; box-shadow: 0 0 20px rgba(255, 0, 119, 0.4);">✨</div>
              <div>
                <div style="font-weight: 800; font-size: 1.15rem; color: #fff;">DroidVortex</div>
                <div style="font-size: 0.75rem; color: #ff0077; font-family: var(--font-mono);">particledemo.html • Physics</div>
              </div>
            </div>
            <span class="badge" style="background: rgba(255, 0, 119, 0.15); color: #ff0077; border: 1px solid rgba(255, 0, 119, 0.3);">Vortex Gravity</span>
          </div>
          <p style="font-size: 0.86rem; color: var(--text-muted); line-height: 1.6; margin-bottom: 16px;">
            Hardware-accelerated luminous particles over <b>WebSockets (<code style="color: #ff0077;">/ws/particles</code>)</b>. Spray glowing particle streams, and hold <kbd style="background: rgba(255,255,255,0.15); padding: 2px 6px; border-radius: 4px; font-family: var(--font-mono); color: #fff;">SPACE</kbd> to activate multi-singularity black holes that suck particles in multi-body orbital mechanics!
          </p>
        </div>
        <div style="display: flex; gap: 10px;">
          <a href="/files/particledemo.html" target="_blank" class="btn btn-primary" style="flex: 1; padding: 10px; text-decoration: none; text-align: center; font-weight: 700; background: rgba(255, 0, 119, 0.2); border-color: #ff0077; color: #ff0077;">
            🚀 Open Particle Vortex
          </a>
          <a href="/files/particledemo.html" download class="btn" style="padding: 10px 14px; text-decoration: none;" title="Download HTML">📥</a>
        </div>
      </div>

      <!-- Demo 4: DroidSpace (Multiplayer Vector Dogfight - Optional) -->
      <div class="card" style="background: rgba(18, 24, 38, 0.9); border-color: rgba(56, 189, 248, 0.3); display: flex; flex-direction: column; justify-content: space-between;">
        <div>
          <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px;">
            <div style="display: flex; align-items: center; gap: 10px;">
              <div style="width: 44px; height: 44px; border-radius: 12px; background: linear-gradient(135deg, #00f3ff, #3b82f6); display: flex; align-items: center; justify-content: center; font-size: 1.5rem; box-shadow: 0 0 20px rgba(0, 243, 255, 0.4);">🚀</div>
              <div>
                <div style="font-weight: 800; font-size: 1.15rem; color: #fff;">DroidSpace</div>
                <div style="font-size: 0.75rem; color: #38bdf8; font-family: var(--font-mono);">spacedemo.html • Optional</div>
              </div>
            </div>
            <span class="badge" style="background: rgba(56, 189, 248, 0.15); color: #38bdf8; border: 1px solid rgba(56, 189, 248, 0.3);">Dogfight Arena</span>
          </div>
          <p style="font-size: 0.86rem; color: var(--text-muted); line-height: 1.6; margin-bottom: 16px;">
            Retro-neon 2D vector space combat. Fly with realistic thruster inertia, blast drifting asteroids, dodge cosmic debris, and dogfight other pilots across the stars over <b>WebSockets (<code style="color: #38bdf8;">/ws/space</code>)</b>!
          </p>
        </div>
        <div style="display: flex; gap: 10px;">
          <a href="/files/spacedemo.html" target="_blank" class="btn btn-primary" style="flex: 1; padding: 10px; text-decoration: none; text-align: center; font-weight: 700; background: rgba(56, 189, 248, 0.2); border-color: #38bdf8; color: #38bdf8;">
            🚀 Open Space Dogfight
          </a>
          <a href="/files/spacedemo.html" download class="btn" style="padding: 10px 14px; text-decoration: none;" title="Download HTML">📥</a>
        </div>
      </div>

      <!-- Demo 5: DroidSynth (Cyber Audio Matrix - Optional) -->
      <div class="card" style="background: rgba(18, 24, 38, 0.9); border-color: rgba(168, 85, 247, 0.3); display: flex; flex-direction: column; justify-content: space-between;">
        <div>
          <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px;">
            <div style="display: flex; align-items: center; gap: 10px;">
              <div style="width: 44px; height: 44px; border-radius: 12px; background: linear-gradient(135deg, #a855f7, #ec4899); display: flex; align-items: center; justify-content: center; font-size: 1.5rem; box-shadow: 0 0 20px rgba(168, 85, 247, 0.4);">🎵</div>
              <div>
                <div style="font-weight: 800; font-size: 1.15rem; color: #fff;">DroidSynth</div>
                <div style="font-size: 0.75rem; color: #c084fc; font-family: var(--font-mono);">synthdemo.html • Optional</div>
              </div>
            </div>
            <span class="badge" style="background: rgba(168, 85, 247, 0.15); color: #c084fc; border: 1px solid rgba(168, 85, 247, 0.3);">Web Audio Matrix</span>
          </div>
          <p style="font-size: 0.86rem; color: var(--text-muted); line-height: 1.6; margin-bottom: 16px;">
            16-step collaborative drum machine & polyphonic synthesizer. Features real-time neon oscilloscope waveforms, live piano keyboard, and synchronized multiplayer jam sessions over <b>WebSockets (<code style="color: #c084fc;">/ws/synth</code>)</b>!
          </p>
        </div>
        <div style="display: flex; gap: 10px;">
          <a href="/files/synthdemo.html" target="_blank" class="btn btn-primary" style="flex: 1; padding: 10px; text-decoration: none; text-align: center; font-weight: 700; background: rgba(168, 85, 247, 0.2); border-color: #a855f7; color: #c084fc;">
            🚀 Open Audio Synth
          </a>
          <a href="/files/synthdemo.html" download class="btn" style="padding: 10px 14px; text-decoration: none;" title="Download HTML">📥</a>
        </div>
      </div>

      <!-- Demo 6: DroidMaze (3D Neon Raycaster - Optional) -->
      <div class="card" style="background: rgba(18, 24, 38, 0.9); border-color: rgba(16, 185, 129, 0.3); display: flex; flex-direction: column; justify-content: space-between;">
        <div>
          <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px;">
            <div style="display: flex; align-items: center; gap: 10px;">
              <div style="width: 44px; height: 44px; border-radius: 12px; background: linear-gradient(135deg, #10b981, #06b6d4); display: flex; align-items: center; justify-content: center; font-size: 1.5rem; box-shadow: 0 0 20px rgba(16, 185, 129, 0.4);">🕹️</div>
              <div>
                <div style="font-weight: 800; font-size: 1.15rem; color: #fff;">DroidMaze</div>
                <div style="font-size: 0.75rem; color: #34d399; font-family: var(--font-mono);">mazedemo.html • Optional</div>
              </div>
            </div>
            <span class="badge" style="background: rgba(16, 185, 129, 0.15); color: #34d399; border: 1px solid rgba(16, 185, 129, 0.3);">3D Raycaster</span>
          </div>
          <p style="font-size: 0.86rem; color: var(--text-muted); line-height: 1.6; margin-bottom: 16px;">
            60 FPS first-person 3D raycasting cyber labyrinth. Navigate neon corridors, collect glowing energy orbs, and locate other players in real-time in 3D and on the radar scanner over <b>WebSockets (<code style="color: #34d399;">/ws/maze</code>)</b>!
          </p>
        </div>
        <div style="display: flex; gap: 10px;">
          <a href="/files/mazedemo.html" target="_blank" class="btn btn-primary" style="flex: 1; padding: 10px; text-decoration: none; text-align: center; font-weight: 700; background: rgba(16, 185, 129, 0.2); border-color: #10b981; color: #34d399;">
            🚀 Open 3D Labyrinth
          </a>
          <a href="/files/mazedemo.html" download class="btn" style="padding: 10px 14px; text-decoration: none;" title="Download HTML">📥</a>
        </div>
      </div>
    </div>
  </div>

</div>

<!-- Media Preview Modal -->
<div class="modal-backdrop" id="preview-modal" onclick="closePreviewModal(event)">
  <div class="modal-box">
    <div class="modal-head">
      <div class="modal-title" id="modal-preview-title">File Preview</div>
      <button class="btn" style="padding: 4px 10px;" onclick="closePreviewModalDirect()">✕</button>
    </div>
    <div class="modal-body" id="modal-preview-content">
      <!-- Media dynamically injected -->
    </div>
  </div>
</div>

<div class="toast" id="toast">Copied link to clipboard!</div>

<script>
  let activeTab = 'overview';
  let taskFilter = 'all';
  let cachedTasks = [];
  let cachedFiles = [];
  let cpuHistory = [10, 15, 12, 20, 18, 25, 22, 18, 15, 20];
  const CIRCLE_CIRCUMFERENCE = 326.7;

  function switchTab(tab) {
    activeTab = tab;
    document.querySelectorAll('.nav-tab').forEach(b => b.classList.remove('active'));
    document.querySelectorAll('.tab-pane').forEach(p => p.classList.remove('active'));

    event.currentTarget.classList.add('active');
    document.getElementById('tab-' + tab).classList.add('active');

    if (tab === 'tasks') fetchTasks();
    if (tab === 'files') fetchFiles();
    if (tab === 'screen') captureLiveScreenshot();
  }

  // Live Screen Capture logic
  let screenAutoRefreshTimer = null;

  function captureLiveScreenshot() {
    const overlay = document.getElementById('screen-loading-overlay');
    if (overlay) overlay.style.display = 'flex';
    const statusEl = document.getElementById('screen-status');
    if (statusEl) {
      statusEl.textContent = 'Capturing...';
      statusEl.style.color = 'var(--amber)';
    }

    const img = document.getElementById('live-screen-img');
    if (img) {
      const ts = Date.now();
      img.src = '/api/screenshot?t=' + ts;
      const dlBtn = document.getElementById('btn-download-screen');
      if (dlBtn) dlBtn.href = '/api/screenshot?download=1&t=' + ts;
      const viewBtn = document.getElementById('btn-view-screen');
      if (viewBtn) viewBtn.href = '/api/screenshot?t=' + ts;
    }
  }

  function onScreenLoaded() {
    const overlay = document.getElementById('screen-loading-overlay');
    if (overlay) overlay.style.display = 'none';
    const statusEl = document.getElementById('screen-status');
    if (statusEl) {
      statusEl.textContent = 'Live Capture Success';
      statusEl.style.color = 'var(--emerald)';
    }
    const metaEl = document.getElementById('screen-meta');
    if (metaEl) {
      const now = new Date();
      metaEl.textContent = `Last Snapshot: ${now.toLocaleTimeString()}`;
    }
  }

  function onScreenError() {
    const overlay = document.getElementById('screen-loading-overlay');
    if (overlay) overlay.style.display = 'none';
    const statusEl = document.getElementById('screen-status');
    if (statusEl) {
      statusEl.textContent = 'Capture Unavailable';
      statusEl.style.color = 'var(--crimson)';
    }
    const metaEl = document.getElementById('screen-meta');
    if (metaEl) {
      metaEl.textContent = 'Failed to capture frame. Retrying...';
    }
  }

  function toggleScreenAutoRefresh() {
    const stateEl = document.getElementById('auto-refresh-state');
    const btn = document.getElementById('btn-auto-refresh-screen');
    if (screenAutoRefreshTimer) {
      clearInterval(screenAutoRefreshTimer);
      screenAutoRefreshTimer = null;
      if (stateEl) stateEl.textContent = 'OFF';
      if (btn) btn.classList.remove('active');
    } else {
      captureLiveScreenshot();
      screenAutoRefreshTimer = setInterval(() => {
        if (activeTab === 'screen') {
          captureLiveScreenshot();
        }
      }, 3000);
      if (stateEl) stateEl.textContent = '3s';
      if (btn) btn.classList.add('active');
    }
  }

  function setTaskFilter(filter) {
    taskFilter = filter;
    ['all', 'apps', 'system'].forEach(f => {
      const el = document.getElementById('btn-filter-' + f);
      if (el) el.classList.toggle('active', f === filter);
    });
    renderTasks();
  }

  // Fetch Stats API
  async function fetchStats(showToast = false) {
    try {
      const res = await fetch('/api/stats');
      if (!res.ok) throw new Error('Status ' + res.status);
      const data = await res.json();
      updateDashboardUI(data);
      if (showToast) showNotification('Telemetry synced');
    } catch (e) {
      console.warn('Sync failed:', e);
      document.getElementById('conn-status').textContent = 'RETRYING...';
      document.getElementById('conn-status').style.color = 'var(--amber)';
    }
  }

  function updateDashboardUI(data) {
    document.getElementById('conn-status').textContent = 'ONLINE';
    document.getElementById('conn-status').style.color = 'var(--emerald)';

    // CPU
    const cpuPct = Math.round(data.cpu.usagePercent);
    document.getElementById('cpu-percent-text').textContent = cpuPct + '%';
    document.getElementById('cpu-cores-text').textContent = data.cpu.cores + ' Cores';
    document.getElementById('cpu-hw-text').textContent = data.cpu.hardware || data.cpu.model;
    document.getElementById('device-model-header').textContent = (data.cpu.manufacturer || '') + ' ' + (data.cpu.model || 'Android Device');

    // CPU Gauge color & stroke
    const cpuOffset = CIRCLE_CIRCUMFERENCE - (cpuPct / 100 * CIRCLE_CIRCUMFERENCE);
    const cpuCircle = document.getElementById('cpu-gauge-circle');
    cpuCircle.style.strokeDashoffset = cpuOffset;
    cpuCircle.style.stroke = cpuPct > 80 ? 'var(--crimson)' : (cpuPct > 50 ? 'var(--amber)' : 'var(--cyan)');

    // CPU Sparkline
    cpuHistory.push(cpuPct);
    if (cpuHistory.length > 20) cpuHistory.shift();
    renderSparkline();

    // RAM
    const ramTotalGb = (data.memory.totalBytes / (1024*1024*1024)).toFixed(1);
    const ramUsedGb = (data.memory.usedBytes / (1024*1024*1024)).toFixed(1);
    const ramAvailGb = (data.memory.availBytes / (1024*1024*1024)).toFixed(1);
    const ramPct = Math.round(data.memory.usedPercent);

    document.getElementById('ram-percent-text').textContent = ramPct + '%';
    document.getElementById('ram-total-text').textContent = ramTotalGb + ' GB';
    document.getElementById('ram-used-text').textContent = ramUsedGb + ' GB';
    document.getElementById('ram-avail-text').textContent = ramAvailGb + ' GB';

    const ramOffset = CIRCLE_CIRCUMFERENCE - (ramPct / 100 * CIRCLE_CIRCUMFERENCE);
    const ramCircle = document.getElementById('ram-gauge-circle');
    ramCircle.style.strokeDashoffset = ramOffset;
    ramCircle.style.stroke = ramPct > 85 ? 'var(--crimson)' : 'var(--blue)';

    // Temperatures
    const bTemp = data.thermal.batteryTemp ? data.thermal.batteryTemp.toFixed(1) : '--';
    const cTemp = data.thermal.cpuTemp ? data.thermal.cpuTemp.toFixed(1) : bTemp;
    document.getElementById('cpu-temp-text').textContent = cTemp + ' °C';
    document.getElementById('battery-temp-text').textContent = bTemp + ' °C';
    document.getElementById('battery-pct-text').textContent = (data.thermal.batteryLevel || '--') + '%';
    document.getElementById('battery-status-text').textContent = data.thermal.batteryStatus || 'Normal';
    document.getElementById('battery-health-text').textContent = data.thermal.batteryHealth || 'Good';

    const maxTemp = Math.max(parseFloat(cTemp) || 30, parseFloat(bTemp) || 30);
    const tBadge = document.getElementById('thermal-state-badge');
    if (maxTemp > 50) {
      tBadge.textContent = 'HOT';
      tBadge.style.color = 'var(--crimson)';
    } else if (maxTemp > 42) {
      tBadge.textContent = 'WARM';
      tBadge.style.color = 'var(--amber)';
    } else {
      tBadge.textContent = 'OPTIMAL';
      tBadge.style.color = 'var(--emerald)';
    }

    // Storage
    if (data.storage) {
      const storageTotalGb = (data.storage.totalBytes / (1024*1024*1024)).toFixed(1);
      const storageUsedGb = (data.storage.usedBytes / (1024*1024*1024)).toFixed(1);
      const storageFreeGb = (data.storage.freeBytes / (1024*1024*1024)).toFixed(1);
      const storagePct = Math.round(data.storage.usedPercent || 0);
      const hostedFormatted = data.storage.hostedFormatted || '0 B';
      const hostedCount = data.storage.hostedCount || 0;

      // Overview Card
      const sPctEl = document.getElementById('storage-percent-text');
      if (sPctEl) sPctEl.textContent = storagePct + '%';
      const sTotalEl = document.getElementById('storage-total-text');
      if (sTotalEl) sTotalEl.textContent = storageTotalGb + ' GB';
      const sUsedEl = document.getElementById('storage-used-text');
      if (sUsedEl) sUsedEl.textContent = storageUsedGb + ' GB';
      const sFreeEl = document.getElementById('storage-free-text');
      if (sFreeEl) sFreeEl.textContent = storageFreeGb + ' GB';
      const sHostedEl = document.getElementById('storage-hosted-text');
      if (sHostedEl) sHostedEl.textContent = `${hostedFormatted} (${hostedCount} files)`;

      const storageOffset = CIRCLE_CIRCUMFERENCE - (storagePct / 100 * CIRCLE_CIRCUMFERENCE);
      const storageCircle = document.getElementById('storage-gauge-circle');
      if (storageCircle) {
        storageCircle.style.strokeDashoffset = storageOffset;
        storageCircle.style.stroke = storagePct > 90 ? 'var(--crimson)' : (storagePct > 75 ? 'var(--amber)' : 'var(--purple)');
      }

      // File Tab Banner
      const bHostedSize = document.getElementById('banner-hosted-size');
      if (bHostedSize) bHostedSize.textContent = hostedFormatted;
      const bHostedSub = document.getElementById('banner-hosted-sub');
      if (bHostedSub) bHostedSub.textContent = `Used by ${hostedCount} hosted files`;
      const bCapBar = document.getElementById('storage-capacity-bar');
      if (bCapBar) bCapBar.style.width = storagePct + '%';
      const bUsed = document.getElementById('banner-used-storage');
      if (bUsed) bUsed.textContent = storageUsedGb + ' GB';
      const bUsedPct = document.getElementById('banner-used-pct');
      if (bUsedPct) bUsedPct.textContent = storagePct + '%';
      const bFree = document.getElementById('banner-free-storage');
      if (bFree) bFree.textContent = storageFreeGb + ' GB';
      const bTotal = document.getElementById('banner-total-storage');
      if (bTotal) bTotal.textContent = storageTotalGb + ' GB';
    }

    // Thermal zones
    if (data.thermal.zones && data.thermal.zones.length > 0) {
      const zCard = document.getElementById('thermal-zones-card');
      const zList = document.getElementById('thermal-zones-list');
      zCard.style.display = 'block';
      zList.innerHTML = data.thermal.zones.map(z => `
        <span class="badge" style="background: rgba(255,255,255,0.06); padding: 6px 10px;">
          ${escapeHtml(z.type)}: <b style="color: var(--cyan);">${z.temp}°C</b>
        </span>
      `).join('');
    }

    // Hardware Specs Tab
    document.getElementById('overview-model-text').textContent = data.cpu.model || 'Android Device';
    document.getElementById('overview-os-text').textContent = 'Android ' + (data.cpu.androidVersion || '14');
    document.getElementById('overview-uptime-text').textContent = formatUptime(data.cpu.uptimeMs || 0);

    document.getElementById('spec-model').textContent = data.cpu.model;
    document.getElementById('spec-mfg').textContent = data.cpu.manufacturer;
    document.getElementById('spec-hw').textContent = data.cpu.hardware;
    document.getElementById('spec-os').textContent = 'Android ' + data.cpu.androidVersion;
    document.getElementById('spec-cores').textContent = data.cpu.cores + ' CPU Cores';
    document.getElementById('spec-usage').textContent = cpuPct + '%';
    if (data.cpu.frequencies && data.cpu.frequencies.length) {
      document.getElementById('spec-freqs').textContent = data.cpu.frequencies.map(f => (f > 0 ? (f/1000).toFixed(0) + 'MHz' : 'offline')).join(', ');
    }
  }

  function renderSparkline() {
    const points = cpuHistory.map((val, idx) => {
      const x = (idx / (cpuHistory.length - 1)) * 100;
      const y = 40 - (val / 100 * 36);
      return `${x.toFixed(1)},${y.toFixed(1)}`;
    });
    const dStr = 'M ' + points.join(' L ');
    const fillStr = `0,40 ${points.join(' ')} 100,40`;
    document.getElementById('sparkline-path').setAttribute('d', dStr);
    document.getElementById('sparkline-fill').setAttribute('points', fillStr);
  }

  function formatUptime(ms) {
    const sec = Math.floor(ms / 1000);
    const hrs = Math.floor(sec / 3600);
    const min = Math.floor((sec % 3600) / 60);
    return `${hrs}h ${min}m`;
  }

  // Task Manager API
  async function fetchTasks() {
    try {
      const res = await fetch('/api/tasks');
      if (!res.ok) throw new Error('Status ' + res.status);
      cachedTasks = await res.json();
      document.getElementById('task-count-badge').textContent = cachedTasks.length;
      renderTasks();
    } catch (e) {
      console.warn('Failed to fetch tasks:', e);
    }
  }

  function renderTasks() {
    const q = (document.getElementById('task-search-input').value || '').toLowerCase();
    const tbody = document.getElementById('task-table-body');

    const filtered = cachedTasks.filter(t => {
      if (taskFilter === 'apps' && t.isSystem) return false;
      if (taskFilter === 'system' && !t.isSystem) return false;
      if (!q) return true;
      return (t.name && t.name.toLowerCase().includes(q)) ||
             (t.label && t.label.toLowerCase().includes(q)) ||
             String(t.pid).includes(q) ||
             (t.user && t.user.toLowerCase().includes(q));
    });

    if (filtered.length === 0) {
      tbody.innerHTML = '<tr><td colspan="6" style="text-align: center; color: var(--text-muted); padding: 24px;">No matching tasks found</td></tr>';
      return;
    }

    tbody.innerHTML = filtered.map(t => {
      const memMb = (t.memoryRssKb / 1024).toFixed(1);
      const isSys = t.isSystem;
      return `
        <tr>
          <td style="font-family: var(--font-mono); color: var(--cyan); font-weight: 600;">#${t.pid}</td>
          <td>
            <div style="font-weight: 600;">${escapeHtml(t.label || t.name)}</div>
            <div style="font-size: 0.76rem; color: var(--text-dim); font-family: var(--font-mono);">${escapeHtml(t.name)}</div>
          </td>
          <td><span class="badge ${isSys ? 'badge-system' : 'badge-app'}">${escapeHtml(t.user || 'app')}</span></td>
          <td style="font-family: var(--font-mono);">${memMb} MB</td>
          <td><span class="badge badge-state">${escapeHtml(t.state || 'Active')}</span></td>
          <td style="text-align: right;">
            <button class="btn btn-danger" style="padding: 4px 10px; font-size: 0.78rem;" onclick="killTask(${t.pid}, '${escapeHtml(t.label || t.name)}')">End Task</button>
          </td>
        </tr>
      `;
    }).join('');
  }

  async function killTask(pid, name) {
    if (!confirm(`Are you sure you want to end task ${name} (PID ${pid})?`)) return;
    try {
      const res = await fetch(`/api/tasks/${pid}`, { method: 'DELETE' });
      const data = await res.json();
      if (data.success) {
        showNotification(`Terminated process ${pid}`);
        fetchTasks();
      } else {
        alert('Process termination denied by Android security sandbox.');
      }
    } catch (e) {
      alert('Failed to kill process: ' + e);
    }
  }

  // File Hosting & Serving API
  async function fetchFiles() {
    try {
      const res = await fetch('/api/files');
      if (!res.ok) throw new Error('Status ' + res.status);
      cachedFiles = await res.json();
      document.getElementById('file-count-badge').textContent = cachedFiles.length;
      document.getElementById('overview-files-count').textContent = cachedFiles.length + ' files';
      renderFiles();
    } catch (e) {
      console.warn('Failed to fetch files:', e);
    }
  }

  function renderFiles() {
    const q = (document.getElementById('file-search-input').value || '').toLowerCase();
    const container = document.getElementById('files-grid-container');

    const filtered = cachedFiles.filter(f => !q || f.name.toLowerCase().includes(q));

    if (filtered.length === 0) {
      container.innerHTML = '<div style="grid-column: 1/-1; text-align: center; color: var(--text-muted); padding: 40px;">No files found.</div>';
      return;
    }

    container.innerHTML = filtered.map(f => {
      const isProtected = f.isProtected || (f.name === 'canvasdemo.html' || f.name === 'sanddemo.html' || f.name === 'particledemo.html');
      const isOptional = f.isOptional || (f.name === 'spacedemo.html' || f.name === 'synthdemo.html' || f.name === 'mazedemo.html');
      const isAnyDemo = isProtected || isOptional;

      let icon = '📄';
      if (f.name === 'canvasdemo.html') icon = '🎨';
      else if (f.name === 'sanddemo.html') icon = '🧪';
      else if (f.name === 'particledemo.html') icon = '✨';
      else if (f.name === 'spacedemo.html') icon = '🚀';
      else if (f.name === 'synthdemo.html') icon = '🎵';
      else if (f.name === 'mazedemo.html') icon = '🕹️';
      else if (f.isImage) icon = '🖼️';
      else if (f.isVideo) icon = '🎬';
      else if (f.isAudio) icon = '🎵';
      else if (f.isText) icon = '📝';
      else if (f.name.endsWith('.zip') || f.name.endsWith('.rar') || f.name.endsWith('.tar.gz') || f.name.endsWith('.apk')) icon = '📦';

      const fileUrl = f.downloadUrl;
      const fullUrl = window.location.origin + fileUrl;

      return `
        <div class="file-card" style="${isProtected ? 'border-color: rgba(0, 242, 254, 0.4);' : (isOptional ? 'border-color: rgba(168, 85, 247, 0.35);' : '')}">
          <div class="file-info">
            <div class="file-icon" style="${isProtected ? 'background: rgba(0, 242, 254, 0.2); box-shadow: 0 0 12px rgba(0, 242, 254, 0.3);' : (isOptional ? 'background: rgba(168, 85, 247, 0.2); box-shadow: 0 0 12px rgba(168, 85, 247, 0.3);' : '')}">${icon}</div>
            <div style="overflow: hidden;">
              <div class="file-name" title="${escapeHtml(f.name)}">
                ${escapeHtml(f.name)}
                ${isProtected ? '<span class="badge" style="background: rgba(0, 242, 254, 0.15); color: var(--cyan); border: 1px solid var(--border); font-size: 0.68rem; margin-left: 6px;">Protected</span>' : (isOptional ? '<span class="badge" style="background: rgba(168, 85, 247, 0.15); color: #c084fc; border: 1px solid rgba(168, 85, 247, 0.3); font-size: 0.68rem; margin-left: 6px;">Optional</span>' : '')}
              </div>
              <div class="file-meta">${f.sizeFormatted} • ${new Date(f.modified).toLocaleDateString()}</div>
            </div>
          </div>
          <div class="file-actions">
            ${isAnyDemo ? `
              <a href="${fileUrl}" target="_blank" class="btn btn-primary" style="flex: 1; padding: 6px; text-decoration: none; text-align: center; font-weight: 700; ${isOptional ? 'background: rgba(168, 85, 247, 0.2); border-color: #a855f7; color: #c084fc;' : ''}">🚀 Launch Demo</a>
            ` : `
              ${(f.isImage || f.isVideo || f.isAudio || f.isText) ? `
                <button class="btn" style="flex: 1; padding: 6px;" onclick="previewFile('${escapeHtml(f.name)}', '${fileUrl}', ${f.isImage}, ${f.isVideo}, ${f.isAudio}, ${f.isText})">👁️ Preview</button>
              ` : ''}
            `}
            <a href="${fileUrl}" download class="btn" style="padding: 6px 12px; text-decoration: none;" title="Download">📥</a>
            <button class="btn" style="padding: 6px 10px;" title="Copy direct HTTPS link" onclick="copyFileLink('${fullUrl}')">🔗</button>
            ${!isProtected ? `
              <button class="btn btn-danger" style="padding: 6px 10px;" title="Delete file" onclick="deleteFile('${escapeHtml(f.name)}')">🗑️</button>
            ` : ''}
          </div>
        </div>
      `;
    }).join('');
  }

  // Upload Logic
  const dropzone = document.getElementById('dropzone');
  ['dragenter', 'dragover'].forEach(n => dropzone.addEventListener(n, (e) => { e.preventDefault(); dropzone.classList.add('dragover'); }, false));
  ['dragleave', 'drop'].forEach(n => dropzone.addEventListener(n, (e) => { e.preventDefault(); dropzone.classList.remove('dragover'); }, false));

  dropzone.addEventListener('drop', (e) => {
    const files = e.dataTransfer.files;
    if (files.length) uploadFiles(files);
  });

  function handleFileSelect(event) {
    const files = event.target.files;
    if (files.length) uploadFiles(files);
  }

  async function uploadFiles(files) {
    const pContainer = document.getElementById('progress-container');
    const pBar = document.getElementById('upload-progress-bar');
    const pMetaName = document.getElementById('upload-filename');
    const pMetaPct = document.getElementById('upload-percentage');

    pContainer.style.display = 'block';

    for (let i = 0; i < files.length; i++) {
      const file = files[i];
      pMetaName.textContent = `Uploading (${i + 1}/${files.length}): ${file.name}`;
      pBar.style.width = '0%';
      pMetaPct.textContent = '0%';

      await new Promise((resolve, reject) => {
        const xhr = new XMLHttpRequest();
        xhr.open('POST', '/api/upload?filename=' + encodeURIComponent(file.name), true);
        xhr.setRequestHeader('Content-Type', file.type || 'application/octet-stream');

        xhr.upload.onprogress = (e) => {
          if (e.lengthComputable) {
            const pct = Math.round((e.loaded / e.total) * 100);
            pBar.style.width = pct + '%';
            pMetaPct.textContent = pct + '%';
          }
        };

        xhr.onload = () => {
          if (xhr.status >= 200 && xhr.status < 300) {
            resolve();
          } else {
            alert('Upload error for ' + file.name + ': ' + xhr.responseText);
            resolve();
          }
        };

        xhr.onerror = () => {
          alert('Network upload failure for ' + file.name);
          resolve();
        };

        xhr.send(file);
      });
    }

    pContainer.style.display = 'none';
    showNotification('File upload completed successfully!');
    fetchFiles();
  }

  async function deleteFile(name) {
    if (name === 'canvasdemo.html' || name === 'sanddemo.html' || name === 'particledemo.html') {
      alert('This is a protected system demo file and cannot be deleted.');
      return;
    }
    if (!confirm('Permanently delete file: ' + name + '?')) return;
    try {
      const res = await fetch('/api/files/' + encodeURIComponent(name), { method: 'DELETE' });
      if (res.ok) {
        showNotification('File deleted');
        fetchFiles();
      } else {
        const err = await res.json().catch(() => ({}));
        alert(err.error || 'Delete failed: file is protected');
      }
    } catch (e) {
      alert('Delete failed: ' + e);
    }
  }

  async function restoreOptionalDemos() {
    try {
      showNotification('Restoring optional demos...');
      const res = await fetch('/api/demos/restore', { method: 'POST' });
      if (res.ok) {
        showNotification('Optional demos successfully restored!');
        fetchFiles();
      } else {
        alert('Failed to restore optional demos.');
      }
    } catch (e) {
      alert('Error: ' + e);
    }
  }

  function previewFile(name, url, isImg, isVid, isAud, isTxt) {
    const modal = document.getElementById('preview-modal');
    const title = document.getElementById('modal-preview-title');
    const body = document.getElementById('modal-preview-content');

    title.textContent = name;
    if (isImg) {
      body.innerHTML = `<img src="${url}" alt="${name}">`;
    } else if (isVid) {
      body.innerHTML = `<video controls autoplay style="width: 100%;"><source src="${url}">Your browser does not support HTML5 video.</video>`;
    } else if (isAud) {
      body.innerHTML = `<audio controls autoplay style="width: 100%;"><source src="${url}">Your browser does not support HTML5 audio.</audio>`;
    } else {
      body.innerHTML = `<iframe src="${url}" style="width: 100%; height: 50vh; border: none; background: #fff;"></iframe>`;
    }

    modal.classList.add('active');
  }

  function closePreviewModal(e) {
    if (e.target.id === 'preview-modal') closePreviewModalDirect();
  }

  function closePreviewModalDirect() {
    const modal = document.getElementById('preview-modal');
    modal.classList.remove('active');
    document.getElementById('modal-preview-content').innerHTML = '';
  }

  function copyFileLink(url) {
    navigator.clipboard.writeText(url).then(() => {
      showNotification('Direct HTTPS link copied to clipboard!');
    }).catch(() => {
      prompt('Direct file URL:', url);
    });
  }

  function showNotification(msg) {
    const toast = document.getElementById('toast');
    toast.textContent = msg;
    toast.style.display = 'block';
    setTimeout(() => { toast.style.display = 'none'; }, 3000);
  }

  function escapeHtml(str) {
    if (!str) return '';
    return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }

  // Periodic Telemetry Loop
  fetchStats();
  setInterval(() => {
    if (activeTab === 'overview' || activeTab === 'sysinfo') {
      fetchStats();
    }
  }, 1500);
</script>

</body>
</html>
''';
}
