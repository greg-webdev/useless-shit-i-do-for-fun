class DemoFiles {
  static const String canvasDemoHtml = r'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>DroidCanvas — Multiplayer Collaborative Whiteboard</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg: #090d16;
      --panel-bg: rgba(15, 23, 42, 0.85);
      --border: rgba(56, 189, 248, 0.2);
      --accent: #00f3ff;
      --accent-pink: #ff0077;
      --accent-green: #00ff88;
      --text: #f8fafc;
      --text-muted: #94a3b8;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; user-select: none; -webkit-user-select: none; }
    body {
      background: var(--bg);
      color: var(--text);
      font-family: 'Outfit', sans-serif;
      overflow: hidden;
      width: 100vw;
      height: 100vh;
      display: flex;
      flex-direction: column;
    }
    header {
      height: 60px;
      background: var(--panel-bg);
      backdrop-filter: blur(16px);
      border-bottom: 1px solid var(--border);
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 0 16px;
      z-index: 50;
      gap: 12px;
    }
    .brand {
      display: flex;
      align-items: center;
      gap: 10px;
      font-weight: 800;
      font-size: 1.25rem;
      letter-spacing: -0.5px;
    }
    .brand-icon {
      width: 32px;
      height: 32px;
      background: linear-gradient(135deg, var(--accent), var(--accent-pink));
      border-radius: 8px;
      display: flex;
      align-items: center;
      justify-content: center;
      box-shadow: 0 0 15px rgba(0, 243, 255, 0.4);
    }
    .status-badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 4px 10px;
      border-radius: 9999px;
      font-size: 0.75rem;
      font-weight: 600;
      background: rgba(255,255,255,0.05);
      border: 1px solid rgba(255,255,255,0.1);
      font-family: 'JetBrains Mono', monospace;
    }
    .status-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: #eab308;
    }
    .status-dot.connected {
      background: var(--accent-green);
      box-shadow: 0 0 8px var(--accent-green);
    }
    .status-dot.error { background: #ef4444; box-shadow: 0 0 8px #ef4444; }
    .user-pill {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 4px 12px;
      background: rgba(0, 243, 255, 0.08);
      border: 1px solid rgba(0, 243, 255, 0.2);
      border-radius: 9999px;
      font-size: 0.85rem;
    }
    .user-color-indicator {
      width: 14px;
      height: 14px;
      border-radius: 50%;
      border: 2px solid #fff;
    }
    .user-name-input {
      background: transparent;
      border: none;
      color: #fff;
      font-family: inherit;
      font-weight: 600;
      width: 100px;
      outline: none;
    }
    .user-name-input:focus {
      border-bottom: 1px solid var(--accent);
    }
    .online-count {
      display: flex;
      align-items: center;
      gap: 6px;
      font-size: 0.85rem;
      color: var(--text-muted);
      font-family: 'JetBrains Mono', monospace;
    }
    .workspace {
      flex: 1;
      position: relative;
      overflow: hidden;
      background-image: 
        radial-gradient(circle at 1px 1px, rgba(255,255,255,0.05) 1px, transparent 0);
      background-size: 24px 24px;
    }
    #canvas {
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      touch-action: none;
      cursor: crosshair;
    }
    .toolbar-container {
      position: absolute;
      left: 16px;
      top: 16px;
      background: var(--panel-bg);
      backdrop-filter: blur(16px);
      border: 1px solid var(--border);
      border-radius: 16px;
      padding: 10px;
      display: flex;
      flex-direction: column;
      gap: 12px;
      box-shadow: 0 10px 30px rgba(0,0,0,0.5);
      z-index: 40;
    }
    .tool-btn {
      width: 42px;
      height: 42px;
      border-radius: 10px;
      border: 1px solid transparent;
      background: rgba(255,255,255,0.05);
      color: var(--text);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 1.2rem;
      cursor: pointer;
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
    }
    .tool-btn:hover {
      background: rgba(255,255,255,0.12);
      transform: scale(1.05);
    }
    .tool-btn.active {
      background: var(--accent);
      color: #000;
      box-shadow: 0 0 15px rgba(0, 243, 255, 0.5);
      border-color: #fff;
    }
    .tool-divider {
      height: 1px;
      background: rgba(255,255,255,0.1);
      margin: 2px 0;
    }
    .palette {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 6px;
    }
    .color-swatch {
      width: 20px;
      height: 20px;
      border-radius: 6px;
      cursor: pointer;
      border: 2px solid transparent;
      transition: transform 0.15s;
    }
    .color-swatch:hover { transform: scale(1.2); }
    .color-swatch.active { border-color: #fff; transform: scale(1.15); box-shadow: 0 0 8px rgba(255,255,255,0.8); }
    #customColorInput {
      width: 42px;
      height: 28px;
      border: none;
      background: transparent;
      cursor: pointer;
      border-radius: 6px;
    }
    .size-popover {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 4px;
      padding: 4px 0;
    }
    .size-slider {
      writing-mode: vertical-lr;
      direction: rtl;
      height: 80px;
      width: 12px;
      accent-color: var(--accent);
      cursor: pointer;
    }
    .size-preview {
      width: 24px;
      height: 24px;
      border-radius: 50%;
      background: var(--accent);
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .top-actions {
      position: absolute;
      right: 16px;
      top: 16px;
      display: flex;
      gap: 8px;
      z-index: 40;
    }
    .action-btn {
      padding: 8px 14px;
      background: var(--panel-bg);
      backdrop-filter: blur(12px);
      border: 1px solid var(--border);
      border-radius: 10px;
      color: var(--text);
      font-size: 0.85rem;
      font-weight: 600;
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 6px;
      transition: all 0.2s;
    }
    .action-btn:hover {
      background: rgba(255,255,255,0.15);
      border-color: var(--accent);
    }
    .action-btn.danger:hover {
      background: rgba(239, 68, 68, 0.2);
      border-color: #ef4444;
      color: #fca5a5;
    }
    /* Peer cursor markers */
    .remote-cursor {
      position: absolute;
      pointer-events: none;
      transition: transform 0.05s linear;
      z-index: 30;
      transform: translate(-2px, -2px);
    }
    .remote-cursor-icon {
      width: 14px;
      height: 14px;
      border-radius: 50%;
      border: 2px solid #fff;
      box-shadow: 0 0 8px rgba(0,0,0,0.8);
    }
    .remote-cursor-tag {
      position: absolute;
      left: 18px;
      top: -4px;
      padding: 2px 8px;
      border-radius: 6px;
      font-size: 0.72rem;
      font-weight: 600;
      white-space: nowrap;
      color: #000;
      box-shadow: 0 2px 8px rgba(0,0,0,0.5);
    }
    @media (max-width: 640px) {
      .toolbar-container {
        left: 8px;
        top: 8px;
        padding: 6px;
        border-radius: 12px;
      }
      .tool-btn { width: 36px; height: 36px; font-size: 1rem; }
      .brand-title { display: none; }
      .size-slider { height: 60px; }
    }
  </style>
</head>
<body>
  <header>
    <div class="brand">
      <div class="brand-icon">🎨</div>
      <span class="brand-title">DroidCanvas</span>
      <div class="status-badge" id="statusBadge">
        <span class="status-dot" id="statusDot"></span>
        <span id="statusText">Connecting...</span>
      </div>
    </div>

    <div style="display: flex; align-items: center; gap: 12px;">
      <div class="online-count">
        <span>👥</span>
        <span id="userCount">1 online</span>
      </div>

      <div class="user-pill">
        <div class="user-color-indicator" id="userColorIndicator"></div>
        <input type="text" class="user-name-input" id="userNameInput" value="Artist" title="Click to rename">
      </div>
    </div>
  </header>

  <div class="workspace" id="workspace">
    <canvas id="canvas"></canvas>

    <!-- Floating Tool Panel -->
    <div class="toolbar-container">
      <button class="tool-btn active" data-tool="pen" title="Freehand Pen">✏️</button>
      <button class="tool-btn" data-tool="highlighter" title="Highlighter (Translucent)">🖍️</button>
      <button class="tool-btn" data-tool="eraser" title="Eraser">🧹</button>
      <button class="tool-btn" data-tool="line" title="Straight Line">📏</button>
      <button class="tool-btn" data-tool="rect" title="Rectangle">⬜</button>
      <button class="tool-btn" data-tool="circle" title="Circle">⭕</button>

      <div class="tool-divider"></div>

      <!-- Color Swatches -->
      <div class="palette">
        <div class="color-swatch active" style="background: #00f3ff;" data-color="#00f3ff"></div>
        <div class="color-swatch" style="background: #ff0077;" data-color="#ff0077"></div>
        <div class="color-swatch" style="background: #00ff88;" data-color="#00ff88"></div>
        <div class="color-swatch" style="background: #ffaa00;" data-color="#ffaa00"></div>
        <div class="color-swatch" style="background: #a855f7;" data-color="#a855f7"></div>
        <div class="color-swatch" style="background: #ffffff;" data-color="#ffffff"></div>
      </div>
      <input type="color" id="customColorInput" value="#00f3ff" title="Pick custom color">

      <div class="tool-divider"></div>

      <!-- Brush Size Slider -->
      <div class="size-popover">
        <div class="size-preview" id="sizePreview">
          <div style="width: 5px; height: 5px; border-radius: 50%; background: #000;"></div>
        </div>
        <input type="range" class="size-slider" id="sizeSlider" min="2" max="60" value="5" title="Brush Size">
      </div>
    </div>

    <!-- Top Right Actions -->
    <div class="top-actions">
      <button class="action-btn danger" id="clearBtn">
        <span>🗑️</span> Clear Board
      </button>
      <button class="action-btn" id="saveBtn">
        <span>💾</span> Export PNG
      </button>
    </div>

    <!-- Peer Cursors Container -->
    <div id="cursorsOverlay"></div>
  </div>

  <script>
    (function() {
      const canvas = document.getElementById('canvas');
      const ctx = canvas.getContext('2d');
      const workspace = document.getElementById('workspace');
      const cursorsOverlay = document.getElementById('cursorsOverlay');
      const statusBadge = document.getElementById('statusBadge');
      const statusDot = document.getElementById('statusDot');
      const statusText = document.getElementById('statusText');
      const userCount = document.getElementById('userCount');
      const userNameInput = document.getElementById('userNameInput');
      const userColorIndicator = document.getElementById('userColorIndicator');
      const sizeSlider = document.getElementById('sizeSlider');
      const sizePreview = document.getElementById('sizePreview');
      const customColorInput = document.getElementById('customColorInput');
      const clearBtn = document.getElementById('clearBtn');
      const saveBtn = document.getElementById('saveBtn');

      // Generate unique user credentials
      const myId = 'usr_' + Math.random().toString(36).substr(2, 9);
      const palette = ['#00f3ff', '#ff0077', '#00ff88', '#ffaa00', '#a855f7', '#38bdf8', '#fb7185', '#34d399'];
      let myColor = palette[Math.floor(Math.random() * palette.length)];
      let myName = 'Artist ' + Math.floor(100 + Math.random() * 900);

      // Restore saved username if available
      try {
        const saved = localStorage.getItem('droidcanvas_username');
        if (saved) myName = saved;
      } catch(_) {}
      userNameInput.value = myName;
      userColorIndicator.style.background = myColor;

      userNameInput.addEventListener('change', () => {
        myName = userNameInput.value.trim() || 'Artist';
        try { localStorage.setItem('droidcanvas_username', myName); } catch(_) {}
        broadcastCursor();
      });

      // Canvas state
      let currentTool = 'pen';
      let brushColor = '#00f3ff';
      let brushSize = 5;
      let isDrawing = false;
      let lastX = 0, lastY = 0;
      let startX = 0, startY = 0;
      let snapshot = null;
      const remoteCursors = new Map();

      // Tool selection
      document.querySelectorAll('.tool-btn').forEach(btn => {
        btn.addEventListener('click', () => {
          document.querySelectorAll('.tool-btn').forEach(b => b.classList.remove('active'));
          btn.classList.add('active');
          currentTool = btn.dataset.tool;
        });
      });

      // Color swatches
      document.querySelectorAll('.color-swatch').forEach(sw => {
        sw.addEventListener('click', () => {
          document.querySelectorAll('.color-swatch').forEach(s => s.classList.remove('active'));
          sw.classList.add('active');
          brushColor = sw.dataset.color;
          customColorInput.value = brushColor;
          updateBrushPreview();
        });
      });

      customColorInput.addEventListener('input', (e) => {
        brushColor = e.target.value;
        document.querySelectorAll('.color-swatch').forEach(s => s.classList.remove('active'));
        updateBrushPreview();
      });

      sizeSlider.addEventListener('input', (e) => {
        brushSize = parseInt(e.target.value, 10);
        updateBrushPreview();
      });

      function updateBrushPreview() {
        sizePreview.style.background = brushColor;
        const inner = sizePreview.firstElementChild;
        if (inner) {
          const sz = Math.min(20, Math.max(3, brushSize * 0.4));
          inner.style.width = sz + 'px';
          inner.style.height = sz + 'px';
        }
      }
      updateBrushPreview();

      // High-DPI canvas resizing preserving drawn content
      function resizeCanvas() {
        const rect = workspace.getBoundingClientRect();
        const dpr = window.devicePixelRatio || 1;
        
        // Temp canvas to hold existing image
        const tempCanvas = document.createElement('canvas');
        tempCanvas.width = canvas.width;
        tempCanvas.height = canvas.height;
        const tempCtx = tempCanvas.getContext('2d');
        if (canvas.width > 0 && canvas.height > 0) {
          tempCtx.drawImage(canvas, 0, 0);
        }

        canvas.width = rect.width * dpr;
        canvas.height = rect.height * dpr;
        ctx.scale(dpr, dpr);

        if (tempCanvas.width > 0 && tempCanvas.height > 0) {
          ctx.drawImage(tempCanvas, 0, 0, tempCanvas.width / dpr, tempCanvas.height / dpr);
        }
      }
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();

      // WebSocket Connection
      let ws = null;
      let reconnectTimer = null;

      function connectWebSocket() {
        if (reconnectTimer) clearTimeout(reconnectTimer);
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const wsUrl = `${protocol}//${window.location.host}/ws/canvas`;

        statusText.textContent = 'Connecting...';
        statusDot.className = 'status-dot';

        try {
          ws = new WebSocket(wsUrl);

          ws.onopen = () => {
            statusText.textContent = 'Live Sync';
            statusDot.className = 'status-dot connected';
            broadcastCursor();
          };

          ws.onmessage = (event) => {
            try {
              const msg = JSON.parse(event.data);
              handleRemoteMessage(msg);
            } catch (e) {
              console.error('WS Parse error:', e);
            }
          };

          ws.onclose = () => {
            statusText.textContent = 'Reconnecting...';
            statusDot.className = 'status-dot error';
            removeRemoteCursors();
            reconnectTimer = setTimeout(connectWebSocket, 2000);
          };

          ws.onerror = () => {
            ws.close();
          };
        } catch (e) {
          statusText.textContent = 'Offline';
          statusDot.className = 'status-dot error';
          reconnectTimer = setTimeout(connectWebSocket, 3000);
        }
      }

      function sendWs(data) {
        if (ws && ws.readyState === WebSocket.OPEN) {
          ws.send(JSON.stringify(data));
        }
      }

      // Handle drawing events from other connected peers
      function handleRemoteMessage(msg) {
        if (msg.type === 'user_count') {
          userCount.textContent = `${msg.count} online`;
          return;
        }

        if (msg.type === 'presence') {
          userCount.textContent = `${msg.count} online`;
          return;
        }

        if (msg.type === 'cursor') {
          updateRemoteCursor(msg);
          return;
        }

        if (msg.type === 'clear') {
          ctx.clearRect(0, 0, canvas.width, canvas.height);
          return;
        }

        if (msg.type === 'stroke') {
          drawRemoteStroke(msg);
          return;
        }
      }

      function updateRemoteCursor(msg) {
        if (msg.id === myId) return;
        let cursorEl = remoteCursors.get(msg.id);
        if (!cursorEl) {
          cursorEl = document.createElement('div');
          cursorEl.className = 'remote-cursor';
          cursorEl.innerHTML = `
            <div class="remote-cursor-icon" style="background: ${msg.color};"></div>
            <div class="remote-cursor-tag" style="background: ${msg.color};">${escapeHtml(msg.name || 'Artist')}</div>
          `;
          cursorsOverlay.appendChild(cursorEl);
          remoteCursors.set(msg.id, cursorEl);
        }
        cursorEl.style.transform = `translate(${msg.x}px, ${msg.y}px)`;
      }

      function removeRemoteCursors() {
        remoteCursors.forEach(el => el.remove());
        remoteCursors.clear();
      }

      function escapeHtml(str) {
        return str.replace(/[&<>"']/g, m => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[m]);
      }

      // Drawing Logic
      function getCanvasCoords(e) {
        const rect = canvas.getBoundingClientRect();
        return {
          x: e.clientX - rect.left,
          y: e.clientY - rect.top
        };
      }

      let lastBroadcastTime = 0;
      function broadcastCursor(x = lastX, y = lastY) {
        const now = Date.now();
        if (now - lastBroadcastTime > 40) { // Limit cursor throttle to 25 Hz
          lastBroadcastTime = now;
          sendWs({
            type: 'cursor',
            id: myId,
            name: myName,
            color: myColor,
            x: Math.round(x),
            y: Math.round(y)
          });
        }
      }

      function startDrawing(e) {
        isDrawing = true;
        const coords = getCanvasCoords(e);
        lastX = coords.x;
        lastY = coords.y;
        startX = coords.x;
        startY = coords.y;

        if (currentTool === 'line' || currentTool === 'rect' || currentTool === 'circle') {
          snapshot = ctx.getImageData(0, 0, canvas.width, canvas.height);
        } else {
          drawPoint(coords.x, coords.y);
        }
        broadcastCursor(coords.x, coords.y);
      }

      function drawPoint(x, y) {
        ctx.save();
        ctx.beginPath();
        ctx.arc(x, y, brushSize / 2, 0, Math.PI * 2);
        if (currentTool === 'eraser') {
          ctx.globalCompositeOperation = 'destination-out';
          ctx.fill();
        } else if (currentTool === 'highlighter') {
          ctx.globalAlpha = 0.35;
          ctx.fillStyle = brushColor;
          ctx.fill();
        } else {
          ctx.fillStyle = brushColor;
          ctx.fill();
        }
        ctx.restore();

        sendWs({
          type: 'stroke',
          action: 'point',
          tool: currentTool,
          x: Math.round(x),
          y: Math.round(y),
          size: brushSize,
          color: brushColor
        });
      }

      function draw(e) {
        const coords = getCanvasCoords(e);
        broadcastCursor(coords.x, coords.y);

        if (!isDrawing) return;

        if (currentTool === 'line' || currentTool === 'rect' || currentTool === 'circle') {
          if (snapshot) ctx.putImageData(snapshot, 0, 0);
          drawShapePreview(coords.x, coords.y);
          return;
        }

        // Smooth line drawing
        ctx.save();
        ctx.beginPath();
        ctx.moveTo(lastX, lastY);
        ctx.lineTo(coords.x, coords.y);
        ctx.lineCap = 'round';
        ctx.lineJoin = 'round';
        ctx.lineWidth = brushSize;

        if (currentTool === 'eraser') {
          ctx.globalCompositeOperation = 'destination-out';
          ctx.stroke();
        } else if (currentTool === 'highlighter') {
          ctx.globalAlpha = 0.35;
          ctx.strokeStyle = brushColor;
          ctx.stroke();
        } else {
          ctx.strokeStyle = brushColor;
          ctx.stroke();
        }
        ctx.restore();

        sendWs({
          type: 'stroke',
          action: 'line',
          tool: currentTool,
          x1: Math.round(lastX),
          y1: Math.round(lastY),
          x2: Math.round(coords.x),
          y2: Math.round(coords.y),
          size: brushSize,
          color: brushColor
        });

        lastX = coords.x;
        lastY = coords.y;
      }

      function drawShapePreview(x, y) {
        ctx.save();
        ctx.beginPath();
        ctx.lineWidth = brushSize;
        ctx.strokeStyle = brushColor;

        if (currentTool === 'line') {
          ctx.moveTo(startX, startY);
          ctx.lineTo(x, y);
        } else if (currentTool === 'rect') {
          ctx.strokeRect(startX, startY, x - startX, y - startY);
        } else if (currentTool === 'circle') {
          const rx = Math.abs(x - startX) / 2;
          const ry = Math.abs(y - startY) / 2;
          const cx = startX + (x - startX) / 2;
          const cy = startY + (y - startY) / 2;
          ctx.ellipse(cx, cy, Math.max(1, rx), Math.max(1, ry), 0, 0, Math.PI * 2);
        }
        ctx.stroke();
        ctx.restore();
      }

      function stopDrawing(e) {
        if (!isDrawing) return;
        isDrawing = false;
        const coords = getCanvasCoords(e);

        if (currentTool === 'line' || currentTool === 'rect' || currentTool === 'circle') {
          if (snapshot) ctx.putImageData(snapshot, 0, 0);
          drawShapePreview(coords.x, coords.y);

          sendWs({
            type: 'stroke',
            action: 'shape',
            tool: currentTool,
            x1: Math.round(startX),
            y1: Math.round(startY),
            x2: Math.round(coords.x),
            y2: Math.round(coords.y),
            size: brushSize,
            color: brushColor
          });
          snapshot = null;
        }
      }

      // Render remote stroke
      function drawRemoteStroke(msg) {
        ctx.save();
        ctx.lineWidth = msg.size;
        ctx.lineCap = 'round';
        ctx.lineJoin = 'round';

        if (msg.tool === 'eraser') {
          ctx.globalCompositeOperation = 'destination-out';
        } else if (msg.tool === 'highlighter') {
          ctx.globalAlpha = 0.35;
          ctx.strokeStyle = msg.color;
          ctx.fillStyle = msg.color;
        } else {
          ctx.strokeStyle = msg.color;
          ctx.fillStyle = msg.color;
        }

        if (msg.action === 'point') {
          ctx.beginPath();
          ctx.arc(msg.x, msg.y, msg.size / 2, 0, Math.PI * 2);
          ctx.fill();
        } else if (msg.action === 'line') {
          ctx.beginPath();
          ctx.moveTo(msg.x1, msg.y1);
          ctx.lineTo(msg.x2, msg.y2);
          ctx.stroke();
        } else if (msg.action === 'shape') {
          ctx.beginPath();
          if (msg.tool === 'line') {
            ctx.moveTo(msg.x1, msg.y1);
            ctx.lineTo(msg.x2, msg.y2);
          } else if (msg.tool === 'rect') {
            ctx.strokeRect(msg.x1, msg.y1, msg.x2 - msg.x1, msg.y2 - msg.y1);
          } else if (msg.tool === 'circle') {
            const rx = Math.abs(msg.x2 - msg.x1) / 2;
            const ry = Math.abs(msg.y2 - msg.y1) / 2;
            const cx = msg.x1 + (msg.x2 - msg.x1) / 2;
            const cy = msg.y1 + (msg.y2 - msg.y1) / 2;
            ctx.ellipse(cx, cy, Math.max(1, rx), Math.max(1, ry), 0, 0, Math.PI * 2);
          }
          ctx.stroke();
        }
        ctx.restore();
      }

      // Pointer event listeners (supports touch, mouse, stylus)
      canvas.addEventListener('pointerdown', startDrawing);
      window.addEventListener('pointermove', draw);
      window.addEventListener('pointerup', stopDrawing);
      window.addEventListener('pointercancel', stopDrawing);

      // Actions
      clearBtn.addEventListener('click', () => {
        if (confirm('Clear the canvas for everyone?')) {
          ctx.clearRect(0, 0, canvas.width, canvas.height);
          sendWs({ type: 'clear', user: myName });
        }
      });

      saveBtn.addEventListener('click', () => {
        // Create export canvas with solid dark background
        const expCanvas = document.createElement('canvas');
        expCanvas.width = canvas.width;
        expCanvas.height = canvas.height;
        const expCtx = expCanvas.getContext('2d');
        expCtx.fillStyle = '#090d16';
        expCtx.fillRect(0, 0, expCanvas.width, expCanvas.height);
        expCtx.drawImage(canvas, 0, 0);

        const a = document.createElement('a');
        a.download = `droidcanvas_${Date.now()}.png`;
        a.href = expCanvas.toDataURL('image/png');
        a.click();
      });

      // Start WebSocket
      connectWebSocket();
    })();
  </script>
</body>
</html>
''';


  static const String sandDemoHtml = r'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>DroidSand — Multiplayer Element Physics Sandbox</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;700;800&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg: #0b0f19;
      --card-bg: rgba(17, 24, 39, 0.85);
      --border: rgba(56, 189, 248, 0.2);
      --accent: #00f3ff;
      --accent-green: #00ff88;
      --text: #f3f4f6;
      --text-muted: #9ca3af;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; user-select: none; -webkit-user-select: none; }
    body {
      background: var(--bg);
      color: var(--text);
      font-family: 'Outfit', sans-serif;
      height: 100vh;
      width: 100vw;
      overflow: hidden;
      display: flex;
      flex-direction: column;
    }
    header {
      height: 56px;
      background: var(--card-bg);
      border-bottom: 1px solid var(--border);
      backdrop-filter: blur(16px);
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 0 16px;
      z-index: 50;
      gap: 12px;
    }
    .brand {
      display: flex;
      align-items: center;
      gap: 10px;
      font-weight: 800;
      font-size: 1.2rem;
    }
    .brand-icon {
      width: 32px;
      height: 32px;
      background: linear-gradient(135deg, #eab308, #ef4444);
      border-radius: 8px;
      display: flex;
      align-items: center;
      justify-content: center;
      box-shadow: 0 0 12px rgba(234, 179, 8, 0.4);
    }
    .header-right {
      display: flex;
      align-items: center;
      gap: 12px;
    }
    .stats-bar {
      display: flex;
      align-items: center;
      gap: 14px;
      font-family: 'JetBrains Mono', monospace;
      font-size: 0.8rem;
      color: var(--text-muted);
    }
    .stat-val { color: var(--accent); font-weight: 600; }
    .status-badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 4px 10px;
      border-radius: 9999px;
      font-size: 0.75rem;
      font-weight: 600;
      background: rgba(255,255,255,0.05);
      border: 1px solid rgba(255,255,255,0.1);
      font-family: 'JetBrains Mono', monospace;
    }
    .status-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: #eab308;
    }
    .status-dot.connected {
      background: var(--accent-green);
      box-shadow: 0 0 8px var(--accent-green);
    }
    .status-dot.error { background: #ef4444; }
    .user-pill {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 4px 10px;
      background: rgba(0, 243, 255, 0.08);
      border: 1px solid rgba(0, 243, 255, 0.2);
      border-radius: 9999px;
      font-size: 0.8rem;
    }
    .user-color-indicator {
      width: 12px;
      height: 12px;
      border-radius: 50%;
      border: 2px solid #fff;
    }
    .online-count {
      display: flex;
      align-items: center;
      gap: 6px;
      font-size: 0.8rem;
      color: var(--text-muted);
      font-family: 'JetBrains Mono', monospace;
    }
    .main-layout {
      flex: 1;
      display: flex;
      position: relative;
      overflow: hidden;
    }
    .canvas-container {
      flex: 1;
      position: relative;
      background: #000;
      display: flex;
      align-items: center;
      justify-content: center;
      overflow: hidden;
    }
    #simCanvas {
      width: 100%;
      height: 100%;
      object-fit: contain;
      image-rendering: pixelated;
      image-rendering: crisp-edges;
      cursor: crosshair;
      touch-action: none;
    }
    .cursor-layer {
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      pointer-events: none;
      overflow: hidden;
      z-index: 30;
    }
    .remote-cursor {
      position: absolute;
      pointer-events: none;
      transform: translate(-50%, -50%);
      transition: left 0.04s linear, top 0.04s linear;
      display: flex;
      flex-direction: column;
      align-items: center;
      z-index: 35;
    }
    .remote-cursor-ring {
      width: 16px;
      height: 16px;
      border-radius: 50%;
      border: 2px solid #00f3ff;
      box-shadow: 0 0 10px #00f3ff;
    }
    .remote-cursor-tag {
      margin-top: 4px;
      background: rgba(15, 23, 42, 0.9);
      border: 1px solid rgba(255,255,255,0.2);
      border-radius: 6px;
      padding: 2px 6px;
      font-size: 0.68rem;
      font-family: 'JetBrains Mono', monospace;
      color: #fff;
      white-space: nowrap;
      display: flex;
      align-items: center;
      gap: 4px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.5);
    }
    .sidebar {
      width: 280px;
      background: var(--card-bg);
      border-left: 1px solid var(--border);
      backdrop-filter: blur(16px);
      display: flex;
      flex-direction: column;
      gap: 14px;
      padding: 16px;
      overflow-y: auto;
      z-index: 40;
    }
    .section-title {
      font-size: 0.75rem;
      text-transform: uppercase;
      letter-spacing: 1px;
      color: var(--text-muted);
      font-weight: 700;
    }
    .elements-grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 8px;
    }
    .elem-btn {
      padding: 8px 10px;
      border-radius: 8px;
      border: 1px solid rgba(255,255,255,0.08);
      background: rgba(255,255,255,0.03);
      color: var(--text);
      font-family: inherit;
      font-weight: 600;
      font-size: 0.8rem;
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 8px;
      transition: all 0.15s ease;
    }
    .elem-btn:hover {
      background: rgba(255,255,255,0.08);
      border-color: rgba(255,255,255,0.2);
    }
    .elem-btn.active {
      background: rgba(0, 243, 255, 0.15);
      border-color: var(--accent);
      color: var(--accent);
      box-shadow: 0 0 10px rgba(0, 243, 255, 0.2);
    }
    .elem-dot {
      width: 10px;
      height: 10px;
      border-radius: 50%;
      flex-shrink: 0;
    }
    .slider-container {
      display: flex;
      flex-direction: column;
      gap: 6px;
    }
    .slider-label {
      display: flex;
      justify-content: space-between;
      font-size: 0.8rem;
      color: var(--text-muted);
    }
    .slider {
      -webkit-appearance: none;
      width: 100%;
      height: 6px;
      background: rgba(255,255,255,0.1);
      border-radius: 3px;
      outline: none;
    }
    .slider::-webkit-slider-thumb {
      -webkit-appearance: none;
      width: 16px;
      height: 16px;
      border-radius: 50%;
      background: var(--accent);
      cursor: pointer;
      box-shadow: 0 0 8px var(--accent);
    }
    .action-group {
      display: flex;
      gap: 8px;
    }
    .action-btn {
      flex: 1;
      padding: 10px;
      border-radius: 8px;
      border: 1px solid rgba(255,255,255,0.1);
      background: rgba(255,255,255,0.05);
      color: var(--text);
      font-weight: 600;
      font-size: 0.8rem;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 6px;
      transition: all 0.15s ease;
    }
    .action-btn:hover {
      background: rgba(255,255,255,0.1);
    }
    .danger-btn {
      background: rgba(239, 68, 68, 0.15);
      border-color: rgba(239, 68, 68, 0.3);
      color: #f87171;
    }
    .danger-btn:hover {
      background: rgba(239, 68, 68, 0.25);
    }
    .preset-list {
      display: flex;
      flex-direction: column;
      gap: 6px;
    }
    .preset-btn {
      padding: 8px 12px;
      border-radius: 8px;
      border: 1px solid rgba(255,255,255,0.08);
      background: rgba(255,255,255,0.03);
      color: var(--text-muted);
      font-size: 0.8rem;
      text-align: left;
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 8px;
      transition: all 0.15s;
    }
    .preset-btn:hover {
      background: rgba(255,255,255,0.08);
      color: #fff;
    }
    @media (max-width: 768px) {
      .sidebar { width: 220px; padding: 10px; }
      .header-right .stats-bar { display: none; }
    }
  </style>
</head>
<body>
  <header>
    <div class="brand">
      <div class="brand-icon">🧪</div>
      <span>DroidSand</span>
    </div>
    <div class="header-right">
      <div class="stats-bar">
        <div>FPS: <span class="stat-val" id="fpsCounter">60</span></div>
        <div>ELEMENTS: <span class="stat-val" id="particleCounter">0</span></div>
      </div>
      <div class="status-badge" id="wsStatus">
        <div class="status-dot" id="statusDot"></div>
        <span id="statusText">Connecting...</span>
      </div>
      <div class="user-pill">
        <div class="user-color-indicator" id="userColorIndicator"></div>
        <span id="userNameDisplay">Alchemist</span>
      </div>
      <div class="online-count">
        <span>👥</span>
        <span id="onlineCount">1</span>
      </div>
    </div>
  </header>

  <div class="main-layout">
    <div class="canvas-container" id="canvasContainer">
      <canvas id="simCanvas" width="240" height="160"></canvas>
      <div class="cursor-layer" id="cursorLayer"></div>
    </div>

    <div class="sidebar">
      <div class="section-title">Elements Palette</div>
      <div class="elements-grid" id="elementsPalette"></div>

      <div class="slider-container">
        <div class="slider-label">
          <span>Brush Size</span>
          <span id="brushSizeVal">3px</span>
        </div>
        <input type="range" class="slider" id="brushSlider" min="1" max="10" value="3">
      </div>

      <div class="section-title">Controls</div>
      <div class="action-group">
        <button class="action-btn" id="pauseBtn">⏸️ Pause</button>
        <button class="action-btn" id="stepBtn">⏭️ Step</button>
      </div>
      <button class="action-btn danger-btn" id="clearBtn">💥 Clear Universe</button>

      <div class="section-title">Collaborative Presets</div>
      <div class="preset-list">
        <button class="preset-btn" data-preset="demolition">💣 Demolition Lab (C4 + Fuse)</button>
        <button class="preset-btn" data-preset="cryo">❄️ Cryo & Magma Clash</button>
        <button class="preset-btn" data-preset="reactor">☢️ Plutonium Reactor Core</button>
      </div>
    </div>
  </div>

  <script>
    (function() {
      const canvas = document.getElementById('simCanvas');
      const ctx = canvas.getContext('2d');
      const cursorLayer = document.getElementById('cursorLayer');
      const canvasContainer = document.getElementById('canvasContainer');
      const fpsCounter = document.getElementById('fpsCounter');
      const particleCounter = document.getElementById('particleCounter');
      const statusDot = document.getElementById('statusDot');
      const statusText = document.getElementById('statusText');
      const userNameDisplay = document.getElementById('userNameDisplay');
      const userColorIndicator = document.getElementById('userColorIndicator');
      const onlineCount = document.getElementById('onlineCount');
      const brushSlider = document.getElementById('brushSlider');
      const brushSizeVal = document.getElementById('brushSizeVal');
      const pauseBtn = document.getElementById('pauseBtn');
      const stepBtn = document.getElementById('stepBtn');
      const clearBtn = document.getElementById('clearBtn');

      const W = 240, H = 160;
      const size = W * H;

      // Element definitions
      const ELEMENTS = {
        EMPTY: 0,
        WALL: 1,
        SAND: 2,
        WATER: 3,
        FIRE: 4,
        WOOD: 5,
        NITROGEN: 6,
        PLUTONIUM: 7,
        C4: 8,
        FUSE: 9,
        ACID: 10,
        LAVA: 11,
        OIL: 12,
        ICE: 13,
        SMOKE: 14,
        STEAM: 15,
        SPARK: 16
      };

      const ELEM_CONFIG = [
        { id: ELEMENTS.SAND, name: 'Sand', color: '#eab308', dot: '#eab308' },
        { id: ELEMENTS.WATER, name: 'Water', color: '#38bdf8', dot: '#38bdf8' },
        { id: ELEMENTS.FIRE, name: 'Fire', color: '#ef4444', dot: '#ef4444' },
        { id: ELEMENTS.WOOD, name: 'Wood', color: '#854d0e', dot: '#854d0e' },
        { id: ELEMENTS.NITROGEN, name: 'Liq. Nitrogen', color: '#a7f3d0', dot: '#a7f3d0' },
        { id: ELEMENTS.PLUTONIUM, name: 'Plutonium', color: '#22c55e', dot: '#22c55e' },
        { id: ELEMENTS.C4, name: 'C4 Explosive', color: '#f97316', dot: '#f97316' },
        { id: ELEMENTS.FUSE, name: 'Fuse', color: '#d97706', dot: '#d97706' },
        { id: ELEMENTS.ACID, name: 'Acid', color: '#84cc16', dot: '#84cc16' },
        { id: ELEMENTS.LAVA, name: 'Lava', color: '#ff4500', dot: '#ff4500' },
        { id: ELEMENTS.OIL, name: 'Oil', color: '#475569', dot: '#475569' },
        { id: ELEMENTS.ICE, name: 'Ice', color: '#bae6fd', dot: '#bae6fd' },
        { id: ELEMENTS.WALL, name: 'Stone Wall', color: '#64748b', dot: '#64748b' },
        { id: ELEMENTS.EMPTY, name: 'Eraser', color: '#000000', dot: '#334155' }
      ];

      function hexToABGR(hex) {
        let c = hex.replace('#', '');
        if (c.length === 3) c = c.split('').map(x => x + x).join('');
        const num = parseInt(c, 16);
        const r = (num >> 16) & 255;
        const g = (num >> 8) & 255;
        const b = num & 255;
        return (255 << 24) | (b << 16) | (g << 8) | r;
      }

      const colorLookup = new Uint32Array(32);
      colorLookup[ELEMENTS.EMPTY] = 0xFF000000;
      colorLookup[ELEMENTS.WALL] = hexToABGR('#64748b');
      colorLookup[ELEMENTS.SAND] = hexToABGR('#eab308');
      colorLookup[ELEMENTS.WATER] = hexToABGR('#38bdf8');
      colorLookup[ELEMENTS.FIRE] = hexToABGR('#ef4444');
      colorLookup[ELEMENTS.WOOD] = hexToABGR('#854d0e');
      colorLookup[ELEMENTS.NITROGEN] = hexToABGR('#a7f3d0');
      colorLookup[ELEMENTS.PLUTONIUM] = hexToABGR('#22c55e');
      colorLookup[ELEMENTS.C4] = hexToABGR('#f97316');
      colorLookup[ELEMENTS.FUSE] = hexToABGR('#d97706');
      colorLookup[ELEMENTS.ACID] = hexToABGR('#84cc16');
      colorLookup[ELEMENTS.LAVA] = hexToABGR('#ff4500');
      colorLookup[ELEMENTS.OIL] = hexToABGR('#475569');
      colorLookup[ELEMENTS.ICE] = hexToABGR('#bae6fd');
      colorLookup[ELEMENTS.SMOKE] = hexToABGR('#6b7280');
      colorLookup[ELEMENTS.STEAM] = hexToABGR('#cbd5e1');
      colorLookup[ELEMENTS.SPARK] = hexToABGR('#ffffff');

      // Grid state
      const grid = new Uint8Array(size);
      const life = new Uint8Array(size);
      const updated = new Uint8Array(size);

      let selectedElement = ELEMENTS.SAND;
      let brushRadius = 3;
      let isPaused = false;
      let stepOnce = false;

      // Palette UI
      const paletteContainer = document.getElementById('elementsPalette');
      ELEM_CONFIG.forEach(item => {
        const btn = document.createElement('button');
        btn.className = `elem-btn ${item.id === selectedElement ? 'active' : ''}`;
        btn.innerHTML = `<div class="elem-dot" style="background: ${item.dot}"></div><span>${item.name}</span>`;
        btn.onclick = () => {
          document.querySelectorAll('.elem-btn').forEach(b => b.classList.remove('active'));
          btn.classList.add('active');
          selectedElement = item.id;
        };
        paletteContainer.appendChild(btn);
      });

      brushSlider.oninput = (e) => {
        brushRadius = parseInt(e.target.value, 10);
        brushSizeVal.textContent = `${brushRadius}px`;
      };

      pauseBtn.onclick = () => {
        isPaused = !isPaused;
        pauseBtn.innerHTML = isPaused ? '▶️ Resume' : '⏸️ Pause';
      };

      stepBtn.onclick = () => {
        isPaused = true;
        stepOnce = true;
        pauseBtn.innerHTML = '▶️ Resume';
      };

      clearBtn.onclick = () => {
        clearGrid(false);
      };

      function clearGrid(isRemote = false) {
        grid.fill(ELEMENTS.EMPTY);
        life.fill(0);
        if (!isRemote) sendWs({ type: 'clear' });
      }

      // Multiplayer & WebSocket setup
      const myId = 'alc_' + Math.random().toString(36).substr(2, 7);
      const ALCH_COLORS = ['#00f3ff', '#ff0077', '#00ff88', '#eab308', '#a855f7', '#f97316', '#38bdf8'];
      const myColor = ALCH_COLORS[Math.floor(Math.random() * ALCH_COLORS.length)];
      const myName = 'Alchemist #' + Math.floor(1000 + Math.random() * 9000);

      userNameDisplay.textContent = myName;
      userColorIndicator.style.background = myColor;

      let ws = null;
      let reconnectTimer = null;
      const remoteCursors = new Map(); // id -> { elem, tag, lastSeen }

      function connectWs() {
        if (reconnectTimer) clearTimeout(reconnectTimer);
        const protocol = location.protocol === 'https:' ? 'wss:' : 'ws:';
        const url = `${protocol}//${location.host}/ws/sand`;

        statusText.textContent = 'Connecting...';
        statusDot.className = 'status-dot';

        try {
          ws = new WebSocket(url);
          ws.onopen = () => {
            statusText.textContent = 'Live Sync';
            statusDot.className = 'status-dot connected';
          };
          ws.onmessage = (e) => {
            try {
              const msg = JSON.parse(e.data);
              handleRemoteMessage(msg);
            } catch (_) {}
          };
          ws.onclose = () => {
            statusText.textContent = 'Disconnected';
            statusDot.className = 'status-dot error';
            reconnectTimer = setTimeout(connectWs, 2500);
          };
          ws.onerror = () => ws.close();
        } catch (_) {
          reconnectTimer = setTimeout(connectWs, 3000);
        }
      }
      connectWs();

      function sendWs(data) {
        if (ws && ws.readyState === WebSocket.OPEN) {
          ws.send(JSON.stringify(data));
        }
      }

      function handleRemoteMessage(msg) {
        if (msg.type === 'presence' || msg.type === 'user_count') {
          onlineCount.textContent = msg.count || 1;
        } else if (msg.type === 'paint') {
          applyBrush(msg.x, msg.y, msg.radius, msg.element, true);
        } else if (msg.type === 'cursor') {
          updateRemoteCursor(msg);
        } else if (msg.type === 'clear') {
          clearGrid(true);
        } else if (msg.type === 'preset') {
          applyPreset(msg.preset, true);
        }
      }

      function updateRemoteCursor(data) {
        let cursorData = remoteCursors.get(data.id);
        if (!cursorData) {
          const el = document.createElement('div');
          el.className = 'remote-cursor';
          el.innerHTML = `
            <div class="remote-cursor-ring" style="border-color: ${data.color}; box-shadow: 0 0 10px ${data.color};"></div>
            <div class="remote-cursor-tag">
              <span style="color: ${data.color}; font-weight: 700;">● ${data.name}</span>
              <span id="tag_elem_${data.id}" style="color: #94a3b8;">[${data.elementName || ''}]</span>
            </div>
          `;
          cursorLayer.appendChild(el);
          cursorData = { el, lastSeen: performance.now() };
          remoteCursors.set(data.id, cursorData);
        }
        cursorData.lastSeen = performance.now();
        const tagElem = document.getElementById(`tag_elem_${data.id}`);
        if (tagElem && data.elementName) tagElem.textContent = `[${data.elementName}]`;

        const rect = canvas.getBoundingClientRect();
        const containerRect = canvasContainer.getBoundingClientRect();
        const screenX = rect.left - containerRect.left + (data.x / W) * rect.width;
        const screenY = rect.top - containerRect.top + (data.y / H) * rect.height;

        cursorData.el.style.left = `${screenX}px`;
        cursorData.el.style.top = `${screenY}px`;
      }

      // Cleanup stale cursors
      setInterval(() => {
        const now = performance.now();
        for (const [id, c] of remoteCursors.entries()) {
          if (now - c.lastSeen > 4000) {
            c.el.remove();
            remoteCursors.delete(id);
          }
        }
      }, 1000);

      function applyBrush(cx, cy, r, elem, isRemote = false) {
        for (let dy = -r; dy <= r; dy++) {
          for (let dx = -r; dx <= r; dx++) {
            if (dx * dx + dy * dy <= r * r) {
              const x = cx + dx;
              const y = cy + dy;
              if (x >= 0 && x < W && y >= 0 && y < H) {
                const idx = y * W + x;
                grid[idx] = elem;
                life[idx] = 0;
              }
            }
          }
        }
        if (!isRemote) {
          sendWs({ type: 'paint', x: cx, y: cy, radius: r, element: elem });
        }
      }

      function getGridPos(e) {
        const rect = canvas.getBoundingClientRect();
        const scaleX = W / rect.width;
        const scaleY = H / rect.height;
        return {
          x: Math.floor((e.clientX - rect.left) * scaleX),
          y: Math.floor((e.clientY - rect.top) * scaleY)
        };
      }

      let isPointerDown = false;
      let lastCursorSend = 0;

      canvas.addEventListener('pointerdown', (e) => {
        isPointerDown = true;
        const p = getGridPos(e);
        applyBrush(p.x, p.y, brushRadius, selectedElement, false);
        sendCursor(p.x, p.y);
      });

      window.addEventListener('pointermove', (e) => {
        const p = getGridPos(e);
        if (p.x >= 0 && p.x < W && p.y >= 0 && p.y < H) {
          const now = performance.now();
          if (now - lastCursorSend > 30) {
            sendCursor(p.x, p.y);
            lastCursorSend = now;
          }
        }
        if (isPointerDown) {
          applyBrush(p.x, p.y, brushRadius, selectedElement, false);
        }
      });

      window.addEventListener('pointerup', () => isPointerDown = false);
      window.addEventListener('pointercancel', () => isPointerDown = false);

      function sendCursor(gx, gy) {
        const elemObj = ELEM_CONFIG.find(item => item.id === selectedElement);
        sendWs({
          type: 'cursor',
          id: myId,
          name: myName,
          color: myColor,
          x: gx,
          y: gy,
          elementName: elemObj ? elemObj.name : ''
        });
      }

      // Presets
      document.querySelectorAll('.preset-btn').forEach(btn => {
        btn.addEventListener('click', () => {
          const preset = btn.dataset.preset;
          applyPreset(preset, false);
        });
      });

      function applyPreset(preset, isRemote = false) {
        grid.fill(ELEMENTS.EMPTY);
        life.fill(0);

        if (preset === 'demolition') {
          for (let x = 30; x < 210; x++) grid[140 * W + x] = ELEMENTS.WALL;
          for (let x = 60; x < 180; x++) {
            for (let y = 100; y < 140; y++) {
              grid[y * W + x] = (x === 60 || x === 179 || y === 100) ? ELEMENTS.WOOD : ELEMENTS.EMPTY;
            }
          }
          for (let x = 100; x < 140; x++) {
            for (let y = 125; y < 138; y++) grid[y * W + x] = ELEMENTS.C4;
          }
          for (let x = 40; x <= 100; x++) grid[90 * W + x] = ELEMENTS.FUSE;
          for (let y = 90; y <= 125; y++) grid[y * W + 100] = ELEMENTS.FUSE;
          grid[90 * W + 40] = ELEMENTS.FIRE;
        } else if (preset === 'cryo') {
          for (let x = 20; x < 100; x++) {
            for (let y = 40; y < 130; y++) grid[y * W + x] = Math.random() < 0.7 ? ELEMENTS.ICE : ELEMENTS.NITROGEN;
          }
          for (let x = 140; x < 220; x++) {
            for (let y = 40; y < 130; y++) grid[y * W + x] = Math.random() < 0.6 ? ELEMENTS.LAVA : ELEMENTS.WALL;
          }
        } else if (preset === 'reactor') {
          for (let x = 100; x < 140; x++) {
            for (let y = 80; y < 120; y++) grid[y * W + x] = ELEMENTS.PLUTONIUM;
          }
          for (let x = 80; x < 160; x++) {
            for (let y = 60; y < 140; y++) {
              const idx = y * W + x;
              if (grid[idx] === ELEMENTS.EMPTY) grid[idx] = ELEMENTS.WATER;
            }
          }
          for (let x = 60; x < 180; x++) {
            for (let y = 40; y < 155; y++) {
              const idx = y * W + x;
              if (grid[idx] === ELEMENTS.EMPTY) grid[idx] = ELEMENTS.NITROGEN;
            }
          }
        }

        if (!isRemote) {
          sendWs({ type: 'preset', preset });
        }
      }

      // Physics Engine
      function updatePhysics() {
        updated.fill(0);

        for (let y = H - 1; y >= 0; y--) {
          const rowOffset = y * W;
          const leftToRight = (y % 2 === 0);

          for (let col = 0; col < W; col++) {
            const x = leftToRight ? col : (W - 1 - col);
            const idx = rowOffset + x;
            const elem = grid[idx];

            if (elem === ELEMENTS.EMPTY || elem === ELEMENTS.WALL || updated[idx]) continue;

            const below = idx + W;
            const belowLeft = below - 1;
            const belowRight = below + 1;
            const above = idx - W;

            // SAND
            if (elem === ELEMENTS.SAND) {
              if (y < H - 1) {
                if (grid[below] === ELEMENTS.EMPTY || grid[below] === ELEMENTS.WATER || grid[below] === ELEMENTS.OIL) {
                  swap(idx, below);
                } else {
                  const leftFree = x > 0 && (grid[belowLeft] === ELEMENTS.EMPTY || grid[belowLeft] === ELEMENTS.WATER);
                  const rightFree = x < W - 1 && (grid[belowRight] === ELEMENTS.EMPTY || grid[belowRight] === ELEMENTS.WATER);
                  if (leftFree && rightFree) swap(idx, Math.random() < 0.5 ? belowLeft : belowRight);
                  else if (leftFree) swap(idx, belowLeft);
                  else if (rightFree) swap(idx, belowRight);
                }
              }
            }

            // WATER & NITROGEN & ACID & OIL
            else if (elem === ELEMENTS.WATER || elem === ELEMENTS.NITROGEN || elem === ELEMENTS.ACID || elem === ELEMENTS.OIL) {
              if (elem === ELEMENTS.NITROGEN) checkColdReaction(x, y, idx);
              if (elem === ELEMENTS.ACID && checkAcidReaction(x, y, idx)) continue;

              if (y < H - 1 && (grid[below] === ELEMENTS.EMPTY || (elem === ELEMENTS.WATER && grid[below] === ELEMENTS.OIL))) {
                swap(idx, below);
              } else {
                const dl = x > 0 && grid[below - 1] === ELEMENTS.EMPTY;
                const dr = x < W - 1 && grid[below + 1] === ELEMENTS.EMPTY;
                if (dl && dr) swap(idx, Math.random() < 0.5 ? below - 1 : below + 1);
                else if (dl) swap(idx, below - 1);
                else if (dr) swap(idx, below + 1);
                else {
                  const l = x > 0 && grid[idx - 1] === ELEMENTS.EMPTY;
                  const r = x < W - 1 && grid[idx + 1] === ELEMENTS.EMPTY;
                  if (l && r) swap(idx, Math.random() < 0.5 ? idx - 1 : idx + 1);
                  else if (l) swap(idx, idx - 1);
                  else if (r) swap(idx, idx + 1);
                }
              }
            }

            // FIRE
            else if (elem === ELEMENTS.FIRE) {
              life[idx]++;
              igniteNeighbors(x, y);
              if (life[idx] > 18 || Math.random() < 0.12) {
                grid[idx] = Math.random() < 0.4 ? ELEMENTS.SMOKE : ELEMENTS.EMPTY;
                life[idx] = 0;
                continue;
              }
              const upIdx = above + (Math.random() < 0.33 ? -1 : Math.random() < 0.5 ? 1 : 0);
              if (upIdx >= 0 && grid[upIdx] === ELEMENTS.EMPTY) swap(idx, upIdx);
            }

            // WOOD & FUSE burning
            else if (elem === ELEMENTS.WOOD && life[idx] > 0) {
              life[idx]++;
              igniteNeighbors(x, y);
              if (life[idx] > 40) {
                grid[idx] = Math.random() < 0.6 ? ELEMENTS.FIRE : ELEMENTS.SMOKE;
                life[idx] = 0;
              }
            }
            else if (elem === ELEMENTS.FUSE && life[idx] > 0) {
              life[idx]++;
              igniteFuse(x, y);
              if (life[idx] > 6) {
                grid[idx] = ELEMENTS.FIRE;
                life[idx] = 0;
              }
            }

            // C4
            else if (elem === ELEMENTS.C4 && life[idx] > 0) {
              explode(x, y, 22);
            }

            // PLUTONIUM
            else if (elem === ELEMENTS.PLUTONIUM) {
              if (Math.random() < 0.05) emitRadiation(x, y);
            }

            // LAVA
            else if (elem === ELEMENTS.LAVA) {
              lavaReaction(x, y, idx);
              if (y < H - 1 && (grid[below] === ELEMENTS.EMPTY || grid[below] === ELEMENTS.WATER)) {
                swap(idx, below);
              } else if (Math.random() < 0.4) {
                const dl = x > 0 && grid[belowLeft] === ELEMENTS.EMPTY;
                const dr = x < W - 1 && grid[belowRight] === ELEMENTS.EMPTY;
                if (dl && dr) swap(idx, Math.random() < 0.5 ? belowLeft : belowRight);
                else if (dl) swap(idx, belowLeft);
                else if (dr) swap(idx, belowRight);
              }
            }

            // SMOKE & STEAM
            else if (elem === ELEMENTS.SMOKE || elem === ELEMENTS.STEAM) {
              life[idx]++;
              if (life[idx] > 45 || y === 0 || Math.random() < 0.05) {
                grid[idx] = ELEMENTS.EMPTY;
                life[idx] = 0;
                continue;
              }
              const upIdx = above + (Math.random() < 0.33 ? -1 : Math.random() < 0.5 ? 1 : 0);
              if (upIdx >= 0 && grid[upIdx] === ELEMENTS.EMPTY) swap(idx, upIdx);
            }
          }
        }
      }

      function swap(a, b) {
        const tg = grid[a]; grid[a] = grid[b]; grid[b] = tg;
        const tl = life[a]; life[a] = life[b]; life[b] = tl;
        updated[a] = 1; updated[b] = 1;
      }

      function checkColdReaction(x, y, idx) {
        const neighbors = [idx - 1, idx + 1, idx - W, idx + W];
        for (const n of neighbors) {
          if (n >= 0 && n < size) {
            if (grid[n] === ELEMENTS.WATER) grid[n] = ELEMENTS.ICE;
            else if (grid[n] === ELEMENTS.FIRE || grid[n] === ELEMENTS.LAVA) {
              grid[n] = ELEMENTS.WALL;
              grid[idx] = ELEMENTS.STEAM;
            }
          }
        }
      }

      function checkAcidReaction(x, y, idx) {
        const neighbors = [idx - 1, idx + 1, idx + W, idx - W];
        for (const n of neighbors) {
          if (n >= 0 && n < size) {
            const target = grid[n];
            if (target !== ELEMENTS.EMPTY && target !== ELEMENTS.WALL && target !== ELEMENTS.ACID) {
              grid[n] = ELEMENTS.EMPTY;
              if (Math.random() < 0.4) grid[idx] = ELEMENTS.SMOKE;
              return true;
            }
          }
        }
        return false;
      }

      function igniteNeighbors(x, y) {
        for (let dy = -1; dy <= 1; dy++) {
          for (let dx = -1; dx <= 1; dx++) {
            const nx = x + dx, ny = y + dy;
            if (nx >= 0 && nx < W && ny >= 0 && ny < H) {
              const nIdx = ny * W + nx;
              const elem = grid[nIdx];
              if (elem === ELEMENTS.WOOD && life[nIdx] === 0) life[nIdx] = 1;
              else if (elem === ELEMENTS.FUSE && life[nIdx] === 0) life[nIdx] = 1;
              else if (elem === ELEMENTS.OIL) grid[nIdx] = ELEMENTS.FIRE;
              else if (elem === ELEMENTS.C4) life[nIdx] = 1;
              else if (elem === ELEMENTS.ICE) grid[nIdx] = ELEMENTS.WATER;
            }
          }
        }
      }

      function igniteFuse(x, y) {
        for (let dy = -1; dy <= 1; dy++) {
          for (let dx = -1; dx <= 1; dx++) {
            const nx = x + dx, ny = y + dy;
            if (nx >= 0 && nx < W && ny >= 0 && ny < H) {
              const nIdx = ny * W + nx;
              if ((grid[nIdx] === ELEMENTS.FUSE && life[nIdx] === 0) || grid[nIdx] === ELEMENTS.C4) {
                life[nIdx] = 1;
              }
            }
          }
        }
      }

      function explode(cx, cy, radius) {
        for (let dy = -radius; dy <= radius; dy++) {
          for (let dx = -radius; dx <= radius; dx++) {
            const distSq = dx * dx + dy * dy;
            if (distSq <= radius * radius) {
              const nx = cx + dx, ny = cy + dy;
              if (nx >= 0 && nx < W && ny >= 0 && ny < H) {
                const idx = ny * W + nx;
                if (grid[idx] !== ELEMENTS.WALL) {
                  if (distSq < radius * radius * 0.45) {
                    grid[idx] = Math.random() < 0.7 ? ELEMENTS.FIRE : ELEMENTS.EMPTY;
                    life[idx] = 1;
                  } else {
                    grid[idx] = Math.random() < 0.35 ? ELEMENTS.SMOKE : ELEMENTS.EMPTY;
                  }
                }
              }
            }
          }
        }
      }

      function emitRadiation(x, y) {
        const angle = Math.random() * Math.PI * 2;
        const dist = Math.random() * 8 + 2;
        const tx = Math.floor(x + Math.cos(angle) * dist);
        const ty = Math.floor(y + Math.sin(angle) * dist);
        if (tx >= 0 && tx < W && ty >= 0 && ty < H) {
          const idx = ty * W + tx;
          if (grid[idx] === ELEMENTS.C4 || grid[idx] === ELEMENTS.WOOD) life[idx] = 1;
          else if (grid[idx] === ELEMENTS.WATER) grid[idx] = ELEMENTS.STEAM;
          else if (grid[idx] === ELEMENTS.EMPTY && Math.random() < 0.2) {
            grid[idx] = ELEMENTS.SPARK;
            life[idx] = 10;
          }
        }
      }

      function lavaReaction(x, y, idx) {
        const neighbors = [idx - 1, idx + 1, idx - W, idx + W];
        for (const n of neighbors) {
          if (n >= 0 && n < size) {
            if (grid[n] === ELEMENTS.WATER || grid[n] === ELEMENTS.NITROGEN) {
              grid[n] = ELEMENTS.STEAM;
              grid[idx] = ELEMENTS.WALL;
              return;
            } else if (grid[n] === ELEMENTS.WOOD || grid[n] === ELEMENTS.OIL || grid[n] === ELEMENTS.C4) {
              grid[n] = ELEMENTS.FIRE;
            }
          }
        }
      }

      // Render Loop
      const imgData = ctx.createImageData(W, H);
      const buf32 = new Uint32Array(imgData.data.buffer);
      let lastFpsTime = performance.now();
      let frames = 0;

      function loop(now) {
        requestAnimationFrame(loop);

        if (!isPaused || stepOnce) {
          updatePhysics();
          stepOnce = false;
        }

        let count = 0;
        for (let i = 0; i < size; i++) {
          const elem = grid[i];
          if (elem !== ELEMENTS.EMPTY) count++;

          if (elem === ELEMENTS.FIRE) {
            const f = Math.random();
            buf32[i] = f < 0.33 ? hexToABGR('#f59e0b') : f < 0.66 ? hexToABGR('#ef4444') : hexToABGR('#dc2626');
          } else if (elem === ELEMENTS.PLUTONIUM) {
            buf32[i] = Math.random() < 0.1 ? hexToABGR('#86efac') : colorLookup[elem];
          } else {
            buf32[i] = colorLookup[elem];
          }
        }
        ctx.putImageData(imgData, 0, 0);

        frames++;
        if (now - lastFpsTime >= 500) {
          const fps = Math.round((frames * 1000) / (now - lastFpsTime));
          fpsCounter.textContent = fps;
          particleCounter.textContent = count.toLocaleString();
          frames = 0;
          lastFpsTime = now;
        }
      }
      requestAnimationFrame(loop);
    })();
  </script>
</body>
</html>''';

  static const String particleDemoHtml = r'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>DroidVortex — Multiplayer Luminous Particles & Gravity Vortex</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;700;800&family=JetBrains+Mono:wght@400;600;700&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg: #04060d;
      --card-bg: rgba(13, 19, 36, 0.85);
      --border: rgba(56, 189, 248, 0.25);
      --accent: #00f3ff;
      --accent-pink: #ff0077;
      --accent-green: #00ff88;
      --text: #f8fafc;
      --text-muted: #94a3b8;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; user-select: none; -webkit-user-select: none; }
    body {
      background: var(--bg);
      color: var(--text);
      font-family: 'Outfit', sans-serif;
      width: 100vw;
      height: 100vh;
      overflow: hidden;
      position: relative;
    }
    #canvas {
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      display: block;
      cursor: crosshair;
    }
    .header-hud {
      position: absolute;
      top: 16px;
      left: 16px;
      right: 16px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      pointer-events: none;
      z-index: 50;
    }
    .brand-glass {
      pointer-events: auto;
      background: var(--card-bg);
      backdrop-filter: blur(16px);
      border: 1px solid var(--border);
      border-radius: 14px;
      padding: 8px 16px;
      display: flex;
      align-items: center;
      gap: 12px;
      box-shadow: 0 8px 32px rgba(0,0,0,0.5);
    }
    .brand-icon {
      width: 28px;
      height: 28px;
      border-radius: 8px;
      background: linear-gradient(135deg, var(--accent), var(--accent-pink));
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 1rem;
      box-shadow: 0 0 12px rgba(0, 243, 255, 0.5);
    }
    .brand-title {
      font-weight: 800;
      font-size: 1.1rem;
      letter-spacing: -0.5px;
    }
    .stats-pill {
      display: flex;
      align-items: center;
      gap: 14px;
      font-family: 'JetBrains Mono', monospace;
      font-size: 0.8rem;
      color: var(--text-muted);
    }
    .stat-val { color: var(--accent); font-weight: 700; }
    .status-badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 4px 10px;
      border-radius: 9999px;
      font-size: 0.75rem;
      font-weight: 600;
      background: rgba(255,255,255,0.05);
      border: 1px solid rgba(255,255,255,0.1);
      font-family: 'JetBrains Mono', monospace;
    }
    .status-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: #eab308;
    }
    .status-dot.connected {
      background: var(--accent-green);
      box-shadow: 0 0 8px var(--accent-green);
    }
    .user-pill {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 4px 10px;
      background: rgba(0, 243, 255, 0.08);
      border: 1px solid rgba(0, 243, 255, 0.2);
      border-radius: 9999px;
      font-size: 0.8rem;
    }
    .user-color-indicator {
      width: 12px;
      height: 12px;
      border-radius: 50%;
      border: 2px solid #fff;
    }
    .vortex-badge {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 6px 14px;
      background: rgba(255, 0, 119, 0.15);
      border: 1px solid rgba(255, 0, 119, 0.4);
      border-radius: 9999px;
      font-family: 'JetBrains Mono', monospace;
      font-size: 0.8rem;
      font-weight: 700;
      color: #ff3399;
      opacity: 0.5;
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
      pointer-events: auto;
    }
    .vortex-badge.active {
      opacity: 1;
      background: rgba(255, 0, 119, 0.3);
      border-color: #ff0077;
      color: #fff;
      box-shadow: 0 0 20px rgba(255, 0, 119, 0.8);
      transform: scale(1.05);
    }
    .vortex-pulse {
      width: 10px;
      height: 10px;
      border-radius: 50%;
      background: #ff0077;
      box-shadow: 0 0 8px #ff0077;
    }
    .remote-cursor-layer {
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      pointer-events: none;
      z-index: 30;
      overflow: hidden;
    }
    .remote-voyager-cursor {
      position: absolute;
      pointer-events: none;
      transform: translate(-50%, -50%);
      transition: left 0.04s linear, top 0.04s linear;
      display: flex;
      flex-direction: column;
      align-items: center;
      z-index: 35;
    }
    .remote-cursor-dot {
      width: 14px;
      height: 14px;
      border-radius: 50%;
      border: 2px solid #fff;
      box-shadow: 0 0 12px currentColor;
    }
    .remote-cursor-label {
      margin-top: 4px;
      background: rgba(13, 19, 36, 0.9);
      border: 1px solid rgba(255,255,255,0.2);
      border-radius: 6px;
      padding: 2px 6px;
      font-size: 0.7rem;
      font-family: 'JetBrains Mono', monospace;
      color: #fff;
      white-space: nowrap;
      box-shadow: 0 4px 12px rgba(0,0,0,0.5);
    }
    .controls-panel {
      position: absolute;
      bottom: 24px;
      right: 24px;
      background: var(--card-bg);
      backdrop-filter: blur(16px);
      border: 1px solid var(--border);
      border-radius: 18px;
      padding: 16px;
      width: 280px;
      display: flex;
      flex-direction: column;
      gap: 16px;
      box-shadow: 0 12px 40px rgba(0,0,0,0.6);
      z-index: 50;
    }
    .control-row {
      display: flex;
      flex-direction: column;
      gap: 8px;
    }
    .control-label {
      display: flex;
      justify-content: space-between;
      font-size: 0.8rem;
      color: var(--text-muted);
      font-weight: 600;
    }
    .palette-row {
      display: flex;
      gap: 8px;
    }
    .palette-btn {
      flex: 1;
      height: 32px;
      border-radius: 8px;
      border: 2px solid transparent;
      cursor: pointer;
      transition: transform 0.15s, border-color 0.15s;
    }
    .palette-btn:hover { transform: scale(1.05); }
    .palette-btn.active {
      border-color: #fff;
      transform: scale(1.08);
      box-shadow: 0 0 14px rgba(255,255,255,0.6);
    }
    .slider {
      -webkit-appearance: none;
      width: 100%;
      height: 6px;
      background: rgba(255,255,255,0.1);
      border-radius: 3px;
      outline: none;
    }
    .slider::-webkit-slider-thumb {
      -webkit-appearance: none;
      width: 16px;
      height: 16px;
      border-radius: 50%;
      background: var(--accent);
      cursor: pointer;
      box-shadow: 0 0 10px var(--accent);
    }
    .action-btn {
      padding: 10px;
      border-radius: 10px;
      border: 1px solid rgba(255,255,255,0.1);
      background: rgba(255, 0, 119, 0.15);
      color: #ff3399;
      font-weight: 700;
      font-size: 0.85rem;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      transition: all 0.2s;
    }
    .action-btn:hover {
      background: rgba(255, 0, 119, 0.3);
      color: #fff;
      box-shadow: 0 0 15px rgba(255, 0, 119, 0.5);
    }
    .mobile-vortex-btn {
      display: none;
      position: absolute;
      bottom: 24px;
      left: 24px;
      width: 64px;
      height: 64px;
      border-radius: 50%;
      background: linear-gradient(135deg, #ff0077, #7928ca);
      border: 2px solid #fff;
      box-shadow: 0 0 25px rgba(255, 0, 119, 0.6);
      align-items: center;
      justify-content: center;
      font-size: 1.8rem;
      cursor: pointer;
      z-index: 50;
      touch-action: none;
      transition: transform 0.1s;
    }
    .guide-banner {
      position: absolute;
      bottom: 24px;
      left: 50%;
      transform: translateX(-50%);
      background: rgba(15, 23, 42, 0.8);
      border: 1px solid rgba(255,255,255,0.1);
      backdrop-filter: blur(12px);
      border-radius: 9999px;
      padding: 8px 20px;
      display: flex;
      align-items: center;
      gap: 16px;
      font-size: 0.82rem;
      pointer-events: none;
      z-index: 40;
    }
    .guide-pill {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      color: var(--accent);
      font-weight: 600;
    }
    .kbd {
      background: rgba(255,255,255,0.15);
      border-radius: 4px;
      padding: 2px 6px;
      font-family: 'JetBrains Mono', monospace;
      font-size: 0.75rem;
      color: #fff;
      border: 1px solid rgba(255,255,255,0.2);
    }
    @media (max-width: 768px) {
      .controls-panel {
        bottom: 10px;
        right: 10px;
        width: 230px;
        padding: 12px;
      }
      .mobile-vortex-btn { display: flex; }
      .guide-banner { display: none; }
    }
  </style>
</head>
<body>
  <canvas id="canvas"></canvas>
  <div class="remote-cursor-layer" id="remoteCursorLayer"></div>

  <div class="header-hud">
    <div class="brand-glass">
      <div class="brand-icon">✨</div>
      <span class="brand-title">DroidVortex</span>
      <div class="stats-pill">
        <div>PARTICLES: <span class="stat-val" id="particleCount">0</span></div>
        <div>FPS: <span class="stat-val" id="fpsDisplay">60</span></div>
      </div>
      <div class="status-badge" id="wsStatus">
        <div class="status-dot" id="statusDot"></div>
        <span id="statusText">Connecting...</span>
      </div>
      <div class="user-pill">
        <div class="user-color-indicator" id="userColorIndicator"></div>
        <span id="userNameDisplay">Voyager</span>
      </div>
      <div class="stats-pill">
        <div>ONLINE: <span class="stat-val" id="onlineCount">1</span></div>
      </div>
    </div>

    <div class="vortex-badge" id="vortexBadge">
      <div class="vortex-pulse"></div>
      <span>GRAVITY VORTEX [SPACE]</span>
    </div>
  </div>

  <div class="controls-panel">
    <div class="control-row">
      <div class="control-label">
        <span>Color Theme</span>
      </div>
      <div class="palette-row">
        <button class="palette-btn active" data-theme="cyber" style="background: linear-gradient(135deg, #00f3ff, #ff0077);" title="Neon Cyber"></button>
        <button class="palette-btn" data-theme="solar" style="background: linear-gradient(135deg, #ffaa00, #ef4444);" title="Solar Flare"></button>
        <button class="palette-btn" data-theme="toxic" style="background: linear-gradient(135deg, #00ff88, #00f3ff);" title="Toxic Aurora"></button>
        <button class="palette-btn" data-theme="cosmic" style="background: linear-gradient(135deg, #a855f7, #3b82f6);" title="Cosmic Deep"></button>
      </div>
    </div>

    <div class="control-row">
      <div class="control-label">
        <span>Vortex Gravity</span>
        <span id="gravityVal">Normal</span>
      </div>
      <input type="range" class="slider" id="gravitySlider" min="1" max="5" value="2">
    </div>

    <div class="control-row">
      <div class="control-label">
        <span>Emission Rate</span>
        <span id="rateVal">Fast</span>
      </div>
      <input type="range" class="slider" id="rateSlider" min="1" max="5" value="3">
    </div>

    <button class="action-btn" id="clearBtn">
      <span>💥</span> Clear Universe
    </button>
  </div>

  <div class="mobile-vortex-btn" id="mobileVortexBtn" title="Hold to Suck Particles">
    🌀
  </div>

  <div class="guide-banner">
    <div class="guide-pill">
      <span>🖱️ Click / Hold / Drag:</span>
      <span>Spawn Glowing Particles</span>
    </div>
    <div style="color: rgba(255,255,255,0.2);">|</div>
    <div class="guide-pill" style="color: #ff3399;">
      <span><span class="kbd">SPACE</span> Press / Hold / Move:</span>
      <span>Suck Particles In (Gravity Vortex)</span>
    </div>
  </div>

  <script>
    (function() {
      const canvas = document.getElementById('canvas');
      const ctx = canvas.getContext('2d');
      const remoteCursorLayer = document.getElementById('remoteCursorLayer');
      const particleCountEl = document.getElementById('particleCount');
      const fpsDisplay = document.getElementById('fpsDisplay');
      const statusDot = document.getElementById('statusDot');
      const statusText = document.getElementById('statusText');
      const userNameDisplay = document.getElementById('userNameDisplay');
      const userColorIndicator = document.getElementById('userColorIndicator');
      const onlineCount = document.getElementById('onlineCount');
      const vortexBadge = document.getElementById('vortexBadge');
      const gravitySlider = document.getElementById('gravitySlider');
      const rateSlider = document.getElementById('rateSlider');
      const clearBtn = document.getElementById('clearBtn');
      const mobileVortexBtn = document.getElementById('mobileVortexBtn');

      let width = 0, height = 0;
      function resize() {
        width = canvas.width = window.innerWidth;
        height = canvas.height = window.innerHeight;
      }
      window.addEventListener('resize', resize);
      resize();

      // Theme Palettes
      const THEMES = {
        cyber: ['#00f3ff', '#ff0077', '#a855f7', '#ffffff'],
        solar: ['#ffea00', '#ff8800', '#ff2200', '#ffffff'],
        toxic: ['#00ff88', '#10b981', '#00f3ff', '#a3e635'],
        cosmic: ['#a855f7', '#6366f1', '#3b82f6', '#f43f5e']
      };
      let currentTheme = 'cyber';

      document.querySelectorAll('.palette-btn').forEach(btn => {
        btn.addEventListener('click', () => {
          document.querySelectorAll('.palette-btn').forEach(b => b.classList.remove('active'));
          btn.classList.add('active');
          currentTheme = btn.dataset.theme;
        });
      });

      // Ultra-Fast Pre-rendered Glow Sprites (Hardware-Accelerated Glow without shadowBlur!)
      const glowSprites = {};
      function getGlowSprite(color) {
        if (glowSprites[color]) return glowSprites[color];
        const offCanvas = document.createElement('canvas');
        offCanvas.width = 48;
        offCanvas.height = 48;
        const gctx = offCanvas.getContext('2d');
        const grad = gctx.createRadialGradient(24, 24, 2, 24, 24, 22);
        grad.addColorStop(0, '#ffffff');
        grad.addColorStop(0.25, color);
        grad.addColorStop(0.7, color);
        grad.addColorStop(1, 'rgba(0,0,0,0)');
        gctx.fillStyle = grad;
        gctx.beginPath();
        gctx.arc(24, 24, 22, 0, Math.PI * 2);
        gctx.fill();
        glowSprites[color] = offCanvas;
        return offCanvas;
      }

      // Pre-warm sprites for current themes
      for (const theme in THEMES) {
        THEMES[theme].forEach(color => getGlowSprite(color));
      }

      // Particle Class with Object Pool
      class Particle {
        constructor() {
          this.reset(0, 0, 0, 0, '#00f3ff', 2, 60);
        }

        reset(x, y, vx, vy, color, size, life) {
          this.x = x;
          this.y = y;
          this.vx = vx;
          this.vy = vy;
          this.color = color;
          this.size = size;
          this.maxLife = life;
          this.life = life;
          this.sprite = getGlowSprite(color);
        }

        update(vortices) {
          if (vortices.length > 0) {
            for (let i = 0; i < vortices.length; i++) {
              const v = vortices[i];
              const dx = v.x - this.x;
              const dy = v.y - this.y;
              const distSq = dx * dx + dy * dy;
              const dist = Math.sqrt(distSq);

              if (dist > 8) {
                const force = (v.pull * 850) / (distSq + 220);
                const ax = (dx / dist) * force;
                const ay = (dy / dist) * force;

                const swirl = force * 0.75;
                const tx = -(dy / dist) * swirl;
                const ty = (dx / dist) * swirl;

                this.vx = (this.vx + ax + tx) * 0.96;
                this.vy = (this.vy + ay + ty) * 0.96;
              } else {
                this.life = 0;
                break;
              }
            }
          } else {
            this.vx *= 0.985;
            this.vy *= 0.985;
          }

          this.x += this.vx;
          this.y += this.vy;
          this.life--;
        }

        draw(ctx) {
          const progress = this.life / this.maxLife;
          const drawSize = Math.max(3, this.size * progress * 4.5);
          ctx.globalAlpha = Math.max(0, Math.min(1, progress));
          ctx.drawImage(this.sprite, this.x - drawSize / 2, this.y - drawSize / 2, drawSize, drawSize);
        }
      }

      // Memory & Pool State
      const particles = [];
      const particlePool = [];
      const MAX_PARTICLES = 2500;

      let cursorX = width / 2;
      let cursorY = height / 2;
      let isMouseDown = false;
      let isSpaceDown = false;
      let lastMoveX = cursorX, lastMoveY = cursorY;
      let moveVx = 0, moveVy = 0;

      // Multiplayer & WebSocket setup
      const myId = 'vort_' + Math.random().toString(36).substr(2, 7);
      const VORT_COLORS = ['#00f3ff', '#ff0077', '#00ff88', '#a855f7', '#ffea00', '#f43f5e', '#38bdf8'];
      const myColor = VORT_COLORS[Math.floor(Math.random() * VORT_COLORS.length)];
      const myName = 'Voyager #' + Math.floor(1000 + Math.random() * 9000);

      userNameDisplay.textContent = myName;
      userColorIndicator.style.background = myColor;

      let ws = null;
      let reconnectTimer = null;
      const remoteVoyagers = new Map(); // id -> { x, y, name, color, isVortex, pull, lastSeen, el }

      function connectWs() {
        if (reconnectTimer) clearTimeout(reconnectTimer);
        const protocol = location.protocol === 'https:' ? 'wss:' : 'ws:';
        const url = `${protocol}//${location.host}/ws/particles`;

        statusText.textContent = 'Connecting...';
        statusDot.className = 'status-dot';

        try {
          ws = new WebSocket(url);
          ws.onopen = () => {
            statusText.textContent = 'Live Sync';
            statusDot.className = 'status-dot connected';
          };
          ws.onmessage = (e) => {
            try {
              const msg = JSON.parse(e.data);
              handleRemoteMessage(msg);
            } catch (_) {}
          };
          ws.onclose = () => {
            statusText.textContent = 'Disconnected';
            statusDot.className = 'status-dot error';
            reconnectTimer = setTimeout(connectWs, 2500);
          };
          ws.onerror = () => ws.close();
        } catch (_) {
          reconnectTimer = setTimeout(connectWs, 3000);
        }
      }
      connectWs();

      function sendWs(data) {
        if (ws && ws.readyState === WebSocket.OPEN) {
          ws.send(JSON.stringify(data));
        }
      }

      function handleRemoteMessage(msg) {
        if (msg.type === 'presence' || msg.type === 'user_count') {
          onlineCount.textContent = msg.count || 1;
        } else if (msg.type === 'emit') {
          spawnBurst(msg.x, msg.y, msg.count, msg.vx, msg.vy, msg.theme, true);
        } else if (msg.type === 'cursor') {
          updateRemoteVoyager(msg);
        } else if (msg.type === 'vortex') {
          let v = remoteVoyagers.get(msg.id);
          if (v) {
            v.isVortex = msg.active;
            v.x = msg.x;
            v.y = msg.y;
            v.pull = msg.pull;
            v.lastSeen = performance.now();
          }
        } else if (msg.type === 'clear') {
          clearUniverse(true);
        }
      }

      function updateRemoteVoyager(data) {
        let v = remoteVoyagers.get(data.id);
        if (!v) {
          const el = document.createElement('div');
          el.className = 'remote-voyager-cursor';
          el.innerHTML = `
            <div class="remote-cursor-dot" style="color: ${data.color}; background: ${data.color};"></div>
            <div class="remote-cursor-label" style="color: ${data.color};">● ${data.name}</div>
          `;
          remoteCursorLayer.appendChild(el);
          v = { el, x: data.x, y: data.y, name: data.name, color: data.color, isVortex: false, pull: 2, lastSeen: performance.now() };
          remoteVoyagers.set(data.id, v);
        }
        v.x = data.x;
        v.y = data.y;
        v.lastSeen = performance.now();
        v.el.style.left = `${data.x}px`;
        v.el.style.top = `${data.y}px`;
      }

      // Cleanup stale remote voyagers
      setInterval(() => {
        const now = performance.now();
        for (const [id, v] of remoteVoyagers.entries()) {
          if (now - v.lastSeen > 4000) {
            v.el.remove();
            remoteVoyagers.delete(id);
          }
        }
      }, 1000);

      // Local Interactions
      window.addEventListener('pointerdown', (e) => {
        if (e.target.closest('.controls-panel') || e.target.closest('.header-hud') || e.target.closest('.mobile-vortex-btn')) return;
        isMouseDown = true;
        cursorX = e.clientX;
        cursorY = e.clientY;
        lastMoveX = cursorX;
        lastMoveY = cursorY;
        spawnBurst(cursorX, cursorY, 25, 0, 0, currentTheme, false);
      });

      let lastCursorSend = 0;
      window.addEventListener('pointermove', (e) => {
        cursorX = e.clientX;
        cursorY = e.clientY;
        moveVx = (cursorX - lastMoveX) * 0.3;
        moveVy = (cursorY - lastMoveY) * 0.3;
        lastMoveX = cursorX;
        lastMoveY = cursorY;

        const now = performance.now();
        if (now - lastCursorSend > 35) {
          sendWs({ type: 'cursor', id: myId, name: myName, color: myColor, x: cursorX, y: cursorY });
          if (isSpaceDown) {
            sendWs({ type: 'vortex', id: myId, active: true, x: cursorX, y: cursorY, pull: parseFloat(gravitySlider.value), color: myColor, name: myName });
          }
          lastCursorSend = now;
        }
      });

      window.addEventListener('pointerup', () => isMouseDown = false);
      window.addEventListener('pointercancel', () => isMouseDown = false);

      function setVortexActive(active) {
        if (isSpaceDown === active) return;
        isSpaceDown = active;
        if (active) vortexBadge.classList.add('active');
        else vortexBadge.classList.remove('active');

        sendWs({
          type: 'vortex',
          id: myId,
          active: active,
          x: cursorX,
          y: cursorY,
          pull: parseFloat(gravitySlider.value),
          color: myColor,
          name: myName
        });
      }

      window.addEventListener('keydown', (e) => {
        if (e.code === 'Space' && !e.repeat) {
          setVortexActive(true);
          e.preventDefault();
        }
      });

      window.addEventListener('keyup', (e) => {
        if (e.code === 'Space') setVortexActive(false);
      });

      mobileVortexBtn.addEventListener('pointerdown', (e) => {
        setVortexActive(true);
        e.preventDefault();
      });
      window.addEventListener('pointerup', () => {
        if (isSpaceDown) setVortexActive(false);
      });

      clearBtn.addEventListener('click', () => clearUniverse(false));

      function clearUniverse(isRemote = false) {
        while (particles.length > 0) {
          const p = particles.pop();
          if (particlePool.length < MAX_PARTICLES) particlePool.push(p);
        }
        if (!isRemote) sendWs({ type: 'clear' });
      }

      function spawnBurst(x, y, count, inheritedVx = 0, inheritedVy = 0, theme = currentTheme, isRemote = false) {
        const palette = THEMES[theme] || THEMES.cyber;
        for (let i = 0; i < count; i++) {
          if (particles.length >= MAX_PARTICLES) {
            const old = particles[0];
            particles[0] = particles[particles.length - 1];
            particles.pop();
            if (particlePool.length < MAX_PARTICLES) particlePool.push(old);
          }

          const angle = Math.random() * Math.PI * 2;
          const speed = Math.random() * 6.5 + 1.2;
          const vx = Math.cos(angle) * speed + inheritedVx;
          const vy = Math.sin(angle) * speed + inheritedVy;
          const color = palette[Math.floor(Math.random() * palette.length)];
          const size = Math.random() * 3 + 1.5;
          const life = Math.floor(Math.random() * 70 + 60);

          let p;
          if (particlePool.length > 0) {
            p = particlePool.pop();
            p.reset(x, y, vx, vy, color, size, life);
          } else {
            p = new Particle();
            p.reset(x, y, vx, vy, color, size, life);
          }
          particles.push(p);
        }

        if (!isRemote) {
          sendWs({
            type: 'emit',
            x: Math.round(x),
            y: Math.round(y),
            count: count,
            vx: Math.round(inheritedVx * 10) / 10,
            vy: Math.round(inheritedVy * 10) / 10,
            theme: theme
          });
        }
      }

      // Draw Gravity Vortex Accretion Disk Graphic
      let vortexAngle = 0;
      function drawVortexAura(x, y, color = '#ff0077', name = null) {
        ctx.save();
        vortexAngle += 0.08;

        const grad = ctx.createRadialGradient(x, y, 10, x, y, 130);
        grad.addColorStop(0, color);
        grad.addColorStop(0.5, 'rgba(121, 40, 202, 0.25)');
        grad.addColorStop(1, 'rgba(0, 0, 0, 0)');
        ctx.fillStyle = grad;
        ctx.beginPath();
        ctx.arc(x, y, 130, 0, Math.PI * 2);
        ctx.fill();

        ctx.strokeStyle = color;
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.arc(x, y, 35 + Math.sin(vortexAngle * 2) * 5, 0, Math.PI * 2);
        ctx.stroke();

        ctx.strokeStyle = 'rgba(0, 243, 255, 0.6)';
        ctx.lineWidth = 1.5;
        ctx.beginPath();
        ctx.arc(x, y, 60 + Math.cos(vortexAngle * 2) * 8, 0, Math.PI * 2);
        ctx.stroke();

        ctx.fillStyle = '#000000';
        ctx.beginPath();
        ctx.arc(x, y, 16, 0, Math.PI * 2);
        ctx.fill();
        ctx.strokeStyle = '#ffffff';
        ctx.lineWidth = 1.5;
        ctx.stroke();

        ctx.restore();
      }

      // Main Animation Loop (Silky 60 FPS)
      let lastFpsTime = performance.now();
      let frameCount = 0;
      let lastContinuousEmit = 0;

      function render(now) {
        requestAnimationFrame(render);

        // Motion blur fade (source-over)
        ctx.globalCompositeOperation = 'source-over';
        ctx.fillStyle = 'rgba(4, 6, 13, 0.25)';
        ctx.fillRect(0, 0, width, height);

        const pullMult = parseFloat(gravitySlider.value);
        const spawnMult = parseInt(rateSlider.value, 10);

        // Continuous particle emission when holding mouse/touch
        if (isMouseDown && now - lastContinuousEmit > 35) {
          spawnBurst(cursorX, cursorY, spawnMult * 3, moveVx, moveVy, currentTheme, false);
          lastContinuousEmit = now;
        }

        // Active vortices collection (local + remote)
        const activeVortices = [];
        if (isSpaceDown) {
          activeVortices.push({ x: cursorX, y: cursorY, pull: pullMult, color: myColor, name: myName });
          drawVortexAura(cursorX, cursorY, myColor, myName);
        }

        for (const [id, v] of remoteVoyagers.entries()) {
          if (v.isVortex) {
            activeVortices.push({ x: v.x, y: v.y, pull: v.pull || 2, color: v.color, name: v.name });
            drawVortexAura(v.x, v.y, v.color, v.name);
          }
        }

        // Additive blending for all particles (Instantaneous GPU Glow)
        ctx.globalCompositeOperation = 'lighter';

        // Update and draw particles with O(1) swap-and-pop removal
        for (let i = particles.length - 1; i >= 0; i--) {
          const p = particles[i];
          p.update(activeVortices);
          if (p.life <= 0) {
            particles[i] = particles[particles.length - 1];
            particles.pop();
            if (particlePool.length < MAX_PARTICLES) particlePool.push(p);
          } else {
            p.draw(ctx);
          }
        }

        ctx.globalCompositeOperation = 'source-over';

        // FPS & Particle count update
        frameCount++;
        if (now - lastFpsTime >= 500) {
          const fps = Math.round((frameCount * 1000) / (now - lastFpsTime));
          fpsDisplay.textContent = fps;
          particleCountEl.textContent = particles.length.toLocaleString();
          frameCount = 0;
          lastFpsTime = now;
        }
      }

      // Initial galaxy burst
      spawnBurst(width / 2, height / 2, 100, 0, 0, 'cyber', true);

      requestAnimationFrame(render);
    })();
  </script>
</body>
</html>''';

  static const String spaceDemoHtml = r'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>DroidSpace — Multiplayer 2D Vector Space Dogfight</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;700;800&family=JetBrains+Mono:wght@400;600;700&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg: #030712;
      --card-bg: rgba(15, 23, 42, 0.85);
      --border: rgba(56, 189, 248, 0.2);
      --accent: #00f3ff;
      --accent-pink: #ff0077;
      --accent-green: #00ff88;
      --text: #f8fafc;
      --text-muted: #94a3b8;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; user-select: none; -webkit-user-select: none; }
    body {
      background: var(--bg);
      color: var(--text);
      font-family: 'Outfit', sans-serif;
      width: 100vw;
      height: 100vh;
      overflow: hidden;
      position: relative;
    }
    #spaceCanvas {
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      display: block;
      cursor: crosshair;
    }
    .header-hud {
      position: absolute;
      top: 16px;
      left: 16px;
      right: 16px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      pointer-events: none;
      z-index: 50;
    }
    .brand-glass {
      pointer-events: auto;
      background: var(--card-bg);
      backdrop-filter: blur(16px);
      border: 1px solid var(--border);
      border-radius: 14px;
      padding: 8px 16px;
      display: flex;
      align-items: center;
      gap: 12px;
      box-shadow: 0 8px 32px rgba(0,0,0,0.5);
    }
    .brand-icon {
      width: 30px;
      height: 30px;
      border-radius: 8px;
      background: linear-gradient(135deg, #00f3ff, #3b82f6);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 1.1rem;
      box-shadow: 0 0 12px rgba(0, 243, 255, 0.5);
    }
    .brand-title {
      font-weight: 800;
      font-size: 1.15rem;
      letter-spacing: -0.5px;
    }
    .stats-pill {
      display: flex;
      align-items: center;
      gap: 12px;
      font-family: 'JetBrains Mono', monospace;
      font-size: 0.8rem;
      color: var(--text-muted);
    }
    .stat-val { color: var(--accent); font-weight: 700; }
    .status-badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 4px 10px;
      border-radius: 9999px;
      font-size: 0.75rem;
      font-weight: 600;
      background: rgba(255,255,255,0.05);
      border: 1px solid rgba(255,255,255,0.1);
      font-family: 'JetBrains Mono', monospace;
    }
    .status-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: #eab308;
    }
    .status-dot.connected {
      background: var(--accent-green);
      box-shadow: 0 0 8px var(--accent-green);
    }
    .user-pill {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 4px 10px;
      background: rgba(0, 243, 255, 0.08);
      border: 1px solid rgba(0, 243, 255, 0.2);
      border-radius: 9999px;
      font-size: 0.8rem;
    }
    .user-color-indicator {
      width: 12px;
      height: 12px;
      border-radius: 50%;
      border: 2px solid #fff;
    }
    /* Leaderboard HUD */
    .leaderboard-panel {
      position: absolute;
      top: 76px;
      right: 16px;
      background: var(--card-bg);
      backdrop-filter: blur(16px);
      border: 1px solid var(--border);
      border-radius: 14px;
      padding: 12px;
      width: 200px;
      pointer-events: none;
      z-index: 40;
    }
    .leaderboard-title {
      font-size: 0.75rem;
      text-transform: uppercase;
      letter-spacing: 1px;
      color: var(--text-muted);
      font-weight: 700;
      margin-bottom: 8px;
    }
    .leaderboard-list {
      display: flex;
      flex-direction: column;
      gap: 6px;
      font-size: 0.8rem;
      font-family: 'JetBrains Mono', monospace;
    }
    .leaderboard-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    /* Controls banner */
    .controls-banner {
      position: absolute;
      bottom: 20px;
      left: 50%;
      transform: translateX(-50%);
      background: rgba(15, 23, 42, 0.85);
      border: 1px solid var(--border);
      backdrop-filter: blur(12px);
      border-radius: 9999px;
      padding: 8px 20px;
      display: flex;
      align-items: center;
      gap: 16px;
      font-size: 0.8rem;
      pointer-events: none;
      z-index: 40;
    }
    .kbd {
      background: rgba(255,255,255,0.15);
      border-radius: 4px;
      padding: 2px 6px;
      font-family: 'JetBrains Mono', monospace;
      font-size: 0.75rem;
      color: #fff;
      border: 1px solid rgba(255,255,255,0.2);
    }
    /* Mobile Touch Controls */
    .mobile-controls {
      display: none;
      position: absolute;
      bottom: 20px;
      left: 20px;
      right: 20px;
      justify-content: space-between;
      pointer-events: none;
      z-index: 50;
    }
    .touch-btn {
      pointer-events: auto;
      width: 60px;
      height: 60px;
      border-radius: 50%;
      background: rgba(15, 23, 42, 0.75);
      border: 2px solid var(--border);
      color: #fff;
      font-size: 1.5rem;
      display: flex;
      align-items: center;
      justify-content: center;
      touch-action: none;
    }
    .touch-btn:active {
      background: rgba(0, 243, 255, 0.3);
      border-color: var(--accent);
    }
    @media (max-width: 768px) {
      .controls-banner { display: none; }
      .mobile-controls { display: flex; }
      .leaderboard-panel { display: none; }
    }
  </style>
</head>
<body>
  <canvas id="spaceCanvas"></canvas>

  <div class="header-hud">
    <div class="brand-glass">
      <div class="brand-icon">🚀</div>
      <span class="brand-title">DroidSpace</span>
      <div class="stats-pill">
        <div>SCORE: <span class="stat-val" id="scoreDisplay">0</span></div>
        <div>PILOTS: <span class="stat-val" id="pilotCount">1</span></div>
      </div>
      <div class="status-badge" id="wsStatus">
        <div class="status-dot" id="statusDot"></div>
        <span id="statusText">Connecting...</span>
      </div>
      <div class="user-pill">
        <div class="user-color-indicator" id="userColorIndicator"></div>
        <span id="userNameDisplay">Pilot</span>
      </div>
    </div>
  </div>

  <div class="leaderboard-panel">
    <div class="leaderboard-title">Pilot Leaderboard</div>
    <div class="leaderboard-list" id="leaderboardList">
      <div class="leaderboard-row"><span style="color: var(--accent);">You</span><span>0</span></div>
    </div>
  </div>

  <div class="controls-banner">
    <div><span class="kbd">W</span> or <span class="kbd">▲</span> Thrusters</div>
    <div><span class="kbd">A</span>/<span class="kbd">D</span> or <span class="kbd">◀</span>/<span class="kbd">▶</span> Steer</div>
    <div><span class="kbd">SPACE</span> or Click to Fire Plasma</div>
  </div>

  <!-- On-Screen Mobile Controls -->
  <div class="mobile-controls">
    <div style="display: flex; gap: 12px;">
      <button class="touch-btn" id="btnLeft">◀</button>
      <button class="touch-btn" id="btnRight">▶</button>
    </div>
    <div style="display: flex; gap: 12px;">
      <button class="touch-btn" id="btnThrust" style="background: rgba(0, 243, 255, 0.15); border-color: var(--accent);">▲</button>
      <button class="touch-btn" id="btnFire" style="background: rgba(255, 0, 119, 0.2); border-color: var(--accent-pink);">🔥</button>
    </div>
  </div>

  <script>
    (function() {
      const canvas = document.getElementById('spaceCanvas');
      const ctx = canvas.getContext('2d');
      const scoreDisplay = document.getElementById('scoreDisplay');
      const pilotCount = document.getElementById('pilotCount');
      const statusDot = document.getElementById('statusDot');
      const statusText = document.getElementById('statusText');
      const userNameDisplay = document.getElementById('userNameDisplay');
      const userColorIndicator = document.getElementById('userColorIndicator');
      const leaderboardList = document.getElementById('leaderboardList');

      let width = 0, height = 0;
      function resize() {
        width = canvas.width = window.innerWidth;
        height = canvas.height = window.innerHeight;
      }
      window.addEventListener('resize', resize);
      resize();

      // Pilot identity
      const myId = 'plt_' + Math.random().toString(36).substr(2, 7);
      const PILOT_COLORS = ['#00f3ff', '#ff0077', '#00ff88', '#ffea00', '#a855f7', '#f97316'];
      const myColor = PILOT_COLORS[Math.floor(Math.random() * PILOT_COLORS.length)];
      const myName = 'Pilot #' + Math.floor(1000 + Math.random() * 9000);
      userNameDisplay.textContent = myName;
      userColorIndicator.style.background = myColor;

      // Stars background
      const stars = [];
      for (let i = 0; i < 150; i++) {
        stars.push({
          x: Math.random() * 2000,
          y: Math.random() * 2000,
          size: Math.random() * 1.8 + 0.5,
          alpha: Math.random() * 0.8 + 0.2
        });
      }

      // Local Ship
      const ship = {
        x: width / 2,
        y: height / 2,
        vx: 0,
        vy: 0,
        angle: -Math.PI / 2,
        rotationSpeed: 0.065,
        thrustPower: 0.18,
        friction: 0.985,
        isThrusting: false,
        isRotatingLeft: false,
        isRotatingRight: false,
        score: 0
      };

      // Game objects
      const lasers = [];
      const remoteLasers = [];
      const particles = [];
      const asteroids = [];
      const remoteShips = new Map(); // id -> { x, y, angle, vx, vy, color, name, isThrusting, lastSeen }

      // Spawn initial asteroids
      for (let i = 0; i < 8; i++) {
        spawnAsteroid();
      }

      function spawnAsteroid(x, y, r = Math.random() * 25 + 20) {
        asteroids.push({
          x: x !== undefined ? x : Math.random() * width,
          y: y !== undefined ? y : Math.random() * height,
          vx: (Math.random() - 0.5) * 1.8,
          vy: (Math.random() - 0.5) * 1.8,
          radius: r,
          angle: 0,
          vRot: (Math.random() - 0.5) * 0.03,
          points: Math.floor(Math.random() * 4 + 7)
        });
      }

      // Input listeners
      window.addEventListener('keydown', (e) => {
        if (e.code === 'KeyW' || e.code === 'ArrowUp') ship.isThrusting = true;
        if (e.code === 'KeyA' || e.code === 'ArrowLeft') ship.isRotatingLeft = true;
        if (e.code === 'KeyD' || e.code === 'ArrowRight') ship.isRotatingRight = true;
        if (e.code === 'Space' && !e.repeat) fireLaser();
      });

      window.addEventListener('keyup', (e) => {
        if (e.code === 'KeyW' || e.code === 'ArrowUp') ship.isThrusting = false;
        if (e.code === 'KeyA' || e.code === 'ArrowLeft') ship.isRotatingLeft = false;
        if (e.code === 'KeyD' || e.code === 'ArrowRight') ship.isRotatingRight = false;
      });

      canvas.addEventListener('pointerdown', (e) => {
        if (e.target.closest('.header-hud') || e.target.closest('.mobile-controls')) return;
        fireLaser();
      });

      // Mobile Touch Handlers
      const btnLeft = document.getElementById('btnLeft');
      const btnRight = document.getElementById('btnRight');
      const btnThrust = document.getElementById('btnThrust');
      const btnFire = document.getElementById('btnFire');

      btnLeft.addEventListener('pointerdown', () => ship.isRotatingLeft = true);
      btnLeft.addEventListener('pointerup', () => ship.isRotatingLeft = false);
      btnRight.addEventListener('pointerdown', () => ship.isRotatingRight = true);
      btnRight.addEventListener('pointerup', () => ship.isRotatingRight = false);
      btnThrust.addEventListener('pointerdown', () => ship.isThrusting = true);
      btnThrust.addEventListener('pointerup', () => ship.isThrusting = false);
      btnFire.addEventListener('pointerdown', () => fireLaser());

      function fireLaser() {
        const speed = 12;
        const noseX = ship.x + Math.cos(ship.angle) * 18;
        const noseY = ship.y + Math.sin(ship.angle) * 18;
        const lvx = Math.cos(ship.angle) * speed + ship.vx * 0.4;
        const lvy = Math.sin(ship.angle) * speed + ship.vy * 0.4;

        lasers.push({ x: noseX, y: noseY, vx: lvx, vy: lvy, life: 60, color: myColor });

        sendWs({
          type: 'laser',
          id: myId,
          x: Math.round(noseX),
          y: Math.round(noseY),
          vx: Math.round(lvx * 10) / 10,
          vy: Math.round(lvy * 10) / 10,
          color: myColor
        });
      }

      // WebSocket Multiplayer
      let ws = null;
      let reconnectTimer = null;

      function connectWs() {
        if (reconnectTimer) clearTimeout(reconnectTimer);
        const protocol = location.protocol === 'https:' ? 'wss:' : 'ws:';
        const url = `${protocol}//${location.host}/ws/space`;

        statusText.textContent = 'Connecting...';
        statusDot.className = 'status-dot';

        try {
          ws = new WebSocket(url);
          ws.onopen = () => {
            statusText.textContent = 'Live Dogfight';
            statusDot.className = 'status-dot connected';
          };
          ws.onmessage = (e) => {
            try {
              const msg = JSON.parse(e.data);
              handleRemoteMessage(msg);
            } catch (_) {}
          };
          ws.onclose = () => {
            statusText.textContent = 'Disconnected';
            statusDot.className = 'status-dot error';
            reconnectTimer = setTimeout(connectWs, 2500);
          };
          ws.onerror = () => ws.close();
        } catch (_) {
          reconnectTimer = setTimeout(connectWs, 3000);
        }
      }
      connectWs();

      function sendWs(data) {
        if (ws && ws.readyState === WebSocket.OPEN) {
          ws.send(JSON.stringify(data));
        }
      }

      function handleRemoteMessage(msg) {
        if (msg.type === 'presence' || msg.type === 'user_count') {
          pilotCount.textContent = msg.count || 1;
        } else if (msg.type === 'ship') {
          let s = remoteShips.get(msg.id);
          if (!s) {
            s = { ...msg, lastSeen: performance.now() };
            remoteShips.set(msg.id, s);
          } else {
            Object.assign(s, msg);
            s.lastSeen = performance.now();
          }
        } else if (msg.type === 'laser') {
          remoteLasers.push({
            x: msg.x,
            y: msg.y,
            vx: msg.vx,
            vy: msg.vy,
            life: 60,
            color: msg.color
          });
        }
      }

      // Broadcast local ship state throttled
      setInterval(() => {
        sendWs({
          type: 'ship',
          id: myId,
          name: myName,
          color: myColor,
          x: Math.round(ship.x),
          y: Math.round(ship.y),
          angle: Math.round(ship.angle * 100) / 100,
          thrusting: ship.isThrusting,
          score: ship.score
        });
      }, 40);

      // Cleanup inactive pilots
      setInterval(() => {
        const now = performance.now();
        for (const [id, s] of remoteShips.entries()) {
          if (now - s.lastSeen > 4000) remoteShips.delete(id);
        }
        updateLeaderboard();
      }, 1500);

      function updateLeaderboard() {
        let html = `<div class="leaderboard-row"><span style="color: ${myColor};">● ${myName}</span><span>${ship.score}</span></div>`;
        for (const s of remoteShips.values()) {
          html += `<div class="leaderboard-row"><span style="color: ${s.color};">● ${s.name}</span><span>${s.score || 0}</span></div>`;
        }
        leaderboardList.innerHTML = html;
      }

      function spawnThrusterSpark(x, y, angle, color) {
        const backX = x - Math.cos(angle) * 12;
        const backY = y - Math.sin(angle) * 12;
        const spread = (Math.random() - 0.5) * 0.8;
        const speed = Math.random() * 4 + 2;
        particles.push({
          x: backX,
          y: backY,
          vx: -Math.cos(angle + spread) * speed,
          vy: -Math.sin(angle + spread) * speed,
          color: color,
          life: 20,
          maxLife: 20,
          size: Math.random() * 2.5 + 1
        });
      }

      function spawnExplosion(x, y, color) {
        for (let i = 0; i < 25; i++) {
          const a = Math.random() * Math.PI * 2;
          const spd = Math.random() * 6 + 1;
          particles.push({
            x: x,
            y: y,
            vx: Math.cos(a) * spd,
            vy: Math.sin(a) * spd,
            color: color,
            life: 30,
            maxLife: 30,
            size: Math.random() * 3 + 1
          });
        }
      }

      // Draw Ship
      function drawShip(x, y, angle, color, name, isThrusting) {
        ctx.save();
        ctx.translate(x, y);
        ctx.rotate(angle);

        // Thruster flame
        if (isThrusting) {
          ctx.beginPath();
          ctx.moveTo(-10, -5);
          ctx.lineTo(-20 - Math.random() * 6, 0);
          ctx.lineTo(-10, 5);
          ctx.fillStyle = '#ff8800';
          ctx.shadowBlur = 10;
          ctx.shadowColor = '#ff8800';
          ctx.fill();
        }

        // Hull
        ctx.beginPath();
        ctx.moveTo(16, 0);
        ctx.lineTo(-12, -10);
        ctx.lineTo(-6, 0);
        ctx.lineTo(-12, 10);
        ctx.closePath();

        ctx.fillStyle = 'rgba(15, 23, 42, 0.9)';
        ctx.fill();
        ctx.strokeStyle = color;
        ctx.lineWidth = 2.5;
        ctx.shadowBlur = 12;
        ctx.shadowColor = color;
        ctx.stroke();

        ctx.restore();

        // Nametag
        if (name) {
          ctx.save();
          ctx.font = '10px "JetBrains Mono", monospace';
          ctx.fillStyle = color;
          ctx.textAlign = 'center';
          ctx.fillText(name, x, y - 22);
          ctx.restore();
        }
      }

      // Game Loop
      function loop() {
        requestAnimationFrame(loop);

        // Motion blur dark clear
        ctx.globalCompositeOperation = 'source-over';
        ctx.fillStyle = 'rgba(3, 7, 18, 0.35)';
        ctx.fillRect(0, 0, width, height);

        // Draw stars
        ctx.fillStyle = '#ffffff';
        for (const st of stars) {
          ctx.globalAlpha = st.alpha;
          ctx.fillRect(st.x % width, st.y % height, st.size, st.size);
        }
        ctx.globalAlpha = 1;

        // Local ship updates
        if (ship.isRotatingLeft) ship.angle -= ship.rotationSpeed;
        if (ship.isRotatingRight) ship.angle += ship.rotationSpeed;

        if (ship.isThrusting) {
          ship.vx += Math.cos(ship.angle) * ship.thrustPower;
          ship.vy += Math.sin(ship.angle) * ship.thrustPower;
          spawnThrusterSpark(ship.x, ship.y, ship.angle, myColor);
        }

        ship.vx *= ship.friction;
        ship.vy *= ship.friction;
        ship.x = (ship.x + ship.vx + width) % width;
        ship.y = (ship.y + ship.vy + height) % height;

        // Update & draw asteroids
        for (const ast of asteroids) {
          ast.x = (ast.x + ast.vx + width) % width;
          ast.y = (ast.y + ast.vy + height) % height;
          ast.angle += ast.vRot;

          ctx.save();
          ctx.translate(ast.x, ast.y);
          ctx.rotate(ast.angle);
          ctx.strokeStyle = '#94a3b8';
          ctx.lineWidth = 2;
          ctx.shadowBlur = 8;
          ctx.shadowColor = '#64748b';
          ctx.beginPath();
          for (let i = 0; i < ast.points; i++) {
            const a = (i / ast.points) * Math.PI * 2;
            const r = ast.radius * (1 + (i % 2 === 0 ? 0.2 : -0.2));
            const px = Math.cos(a) * r;
            const py = Math.sin(a) * r;
            if (i === 0) ctx.moveTo(px, py);
            else ctx.lineTo(px, py);
          }
          ctx.closePath();
          ctx.fillStyle = 'rgba(15, 23, 42, 0.8)';
          ctx.fill();
          ctx.stroke();
          ctx.restore();
        }

        // Update local lasers
        ctx.lineWidth = 2;
        for (let i = lasers.length - 1; i >= 0; i--) {
          const l = lasers[i];
          l.x = (l.x + l.vx + width) % width;
          l.y = (l.y + l.vy + height) % height;
          l.life--;

          // Draw laser bolt
          ctx.strokeStyle = l.color;
          ctx.shadowBlur = 10;
          ctx.shadowColor = l.color;
          ctx.beginPath();
          ctx.moveTo(l.x, l.y);
          ctx.lineTo(l.x - l.vx * 1.5, l.y - l.vy * 1.5);
          ctx.stroke();

          // Laser collision with asteroids
          for (let j = asteroids.length - 1; j >= 0; j--) {
            const ast = asteroids[j];
            const dx = l.x - ast.x;
            const dy = l.y - ast.y;
            if (dx * dx + dy * dy < ast.radius * ast.radius) {
              spawnExplosion(ast.x, ast.y, '#eab308');
              ship.score += Math.round(50 - ast.radius);
              scoreDisplay.textContent = ship.score;
              lasers.splice(i, 1);

              if (ast.radius > 16) {
                spawnAsteroid(ast.x, ast.y, ast.radius * 0.55);
                spawnAsteroid(ast.x, ast.y, ast.radius * 0.55);
              }
              asteroids.splice(j, 1);
              if (asteroids.length < 5) spawnAsteroid();
              break;
            }
          }

          if (l.life <= 0) lasers.splice(i, 1);
        }

        // Draw remote lasers
        for (let i = remoteLasers.length - 1; i >= 0; i--) {
          const l = remoteLasers[i];
          l.x = (l.x + l.vx + width) % width;
          l.y = (l.y + l.vy + height) % height;
          l.life--;

          ctx.strokeStyle = l.color;
          ctx.shadowBlur = 10;
          ctx.shadowColor = l.color;
          ctx.beginPath();
          ctx.moveTo(l.x, l.y);
          ctx.lineTo(l.x - l.vx * 1.5, l.y - l.vy * 1.5);
          ctx.stroke();

          if (l.life <= 0) remoteLasers.splice(i, 1);
        }

        // Update & draw particles
        for (let i = particles.length - 1; i >= 0; i--) {
          const p = particles[i];
          p.x += p.vx;
          p.y += p.vy;
          p.life--;
          const prog = p.life / p.maxLife;
          ctx.fillStyle = p.color;
          ctx.globalAlpha = prog;
          ctx.beginPath();
          ctx.arc(p.x, p.y, p.size * prog, 0, Math.PI * 2);
          ctx.fill();
          if (p.life <= 0) particles.splice(i, 1);
        }
        ctx.globalAlpha = 1;

        // Draw Remote Ships
        for (const s of remoteShips.values()) {
          drawShip(s.x, s.y, s.angle, s.color, s.name, s.thrusting);
        }

        // Draw Local Ship
        drawShip(ship.x, ship.y, ship.angle, myColor, myName, ship.isThrusting);
      }

      requestAnimationFrame(loop);
    })();
  </script>
</body>
</html>''';

  static const String synthDemoHtml = r'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>DroidSynth — Multiplayer Cyber Audio Matrix & Sequencer</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;700;800&family=JetBrains+Mono:wght@400;600;700&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg: #070913;
      --card-bg: rgba(15, 23, 42, 0.85);
      --border: rgba(56, 189, 248, 0.2);
      --accent: #00f3ff;
      --accent-pink: #ff0077;
      --accent-green: #00ff88;
      --accent-purple: #a855f7;
      --text: #f8fafc;
      --text-muted: #94a3b8;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; user-select: none; -webkit-user-select: none; }
    body {
      background: var(--bg);
      color: var(--text);
      font-family: 'Outfit', sans-serif;
      height: 100vh;
      width: 100vw;
      overflow: hidden;
      display: flex;
      flex-direction: column;
    }
    header {
      height: 56px;
      background: var(--card-bg);
      border-bottom: 1px solid var(--border);
      backdrop-filter: blur(16px);
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 0 16px;
      z-index: 50;
      gap: 12px;
    }
    .brand {
      display: flex;
      align-items: center;
      gap: 10px;
      font-weight: 800;
      font-size: 1.2rem;
    }
    .brand-icon {
      width: 32px;
      height: 32px;
      background: linear-gradient(135deg, var(--accent-pink), var(--accent-purple));
      border-radius: 8px;
      display: flex;
      align-items: center;
      justify-content: center;
      box-shadow: 0 0 12px rgba(255, 0, 119, 0.4);
    }
    .header-controls {
      display: flex;
      align-items: center;
      gap: 12px;
    }
    .status-badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 4px 10px;
      border-radius: 9999px;
      font-size: 0.75rem;
      font-weight: 600;
      background: rgba(255,255,255,0.05);
      border: 1px solid rgba(255,255,255,0.1);
      font-family: 'JetBrains Mono', monospace;
    }
    .status-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: #eab308;
    }
    .status-dot.connected {
      background: var(--accent-green);
      box-shadow: 0 0 8px var(--accent-green);
    }
    .user-pill {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 4px 10px;
      background: rgba(0, 243, 255, 0.08);
      border: 1px solid rgba(0, 243, 255, 0.2);
      border-radius: 9999px;
      font-size: 0.8rem;
    }
    .user-color-indicator {
      width: 12px;
      height: 12px;
      border-radius: 50%;
      border: 2px solid #fff;
    }
    .online-count {
      display: flex;
      align-items: center;
      gap: 6px;
      font-size: 0.8rem;
      color: var(--text-muted);
      font-family: 'JetBrains Mono', monospace;
    }
    /* Main Layout */
    .synth-container {
      flex: 1;
      display: flex;
      flex-direction: column;
      padding: 16px;
      gap: 14px;
      overflow-y: auto;
      max-width: 1200px;
      margin: 0 auto;
      width: 100%;
    }
    /* Oscilloscope Visualizer Card */
    .visualizer-card {
      height: 110px;
      background: rgba(15, 23, 42, 0.6);
      border: 1px solid var(--border);
      border-radius: 14px;
      position: relative;
      overflow: hidden;
    }
    #scopeCanvas {
      width: 100%;
      height: 100%;
      display: block;
    }
    /* Sequencer Grid */
    .matrix-card {
      background: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 14px;
      padding: 16px;
      display: flex;
      flex-direction: column;
      gap: 10px;
      box-shadow: 0 10px 30px rgba(0,0,0,0.5);
    }
    .matrix-head {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 4px;
    }
    .matrix-title {
      font-weight: 700;
      font-size: 0.9rem;
      color: var(--text-muted);
      text-transform: uppercase;
      letter-spacing: 1px;
    }
    .bpm-control {
      display: flex;
      align-items: center;
      gap: 8px;
      font-family: 'JetBrains Mono', monospace;
      font-size: 0.8rem;
    }
    .sequencer-row {
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .track-label {
      width: 110px;
      font-family: 'JetBrains Mono', monospace;
      font-size: 0.75rem;
      font-weight: 700;
      color: var(--accent);
      display: flex;
      align-items: center;
      gap: 6px;
      flex-shrink: 0;
    }
    .steps-container {
      flex: 1;
      display: grid;
      grid-template-columns: repeat(16, 1fr);
      gap: 4px;
    }
    .step-pad {
      aspect-ratio: 1;
      border-radius: 6px;
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(255, 255, 255, 0.08);
      cursor: pointer;
      transition: transform 0.08s, background 0.1s;
    }
    .step-pad:nth-child(4n+1) {
      border-left: 2px solid rgba(255, 255, 255, 0.2);
    }
    .step-pad.active {
      background: var(--pad-color, var(--accent));
      box-shadow: 0 0 10px var(--pad-color, var(--accent));
    }
    .step-pad.current {
      border-color: #fff;
      transform: scale(1.1);
    }
    /* Piano Keyboard */
    .keyboard-card {
      background: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 14px;
      padding: 14px;
      display: flex;
      flex-direction: column;
      gap: 8px;
    }
    .keys-row {
      display: flex;
      height: 90px;
      gap: 4px;
      position: relative;
    }
    .key-white {
      flex: 1;
      background: rgba(255,255,255,0.08);
      border: 1px solid rgba(255,255,255,0.2);
      border-radius: 0 0 8px 8px;
      cursor: pointer;
      display: flex;
      align-items: flex-end;
      justify-content: center;
      padding-bottom: 6px;
      font-family: 'JetBrains Mono', monospace;
      font-size: 0.7rem;
      color: var(--text-muted);
      transition: background 0.1s;
    }
    .key-white:active, .key-white.active {
      background: var(--accent);
      color: #000;
      box-shadow: 0 0 15px var(--accent);
    }
    .action-btn {
      padding: 8px 16px;
      border-radius: 8px;
      border: 1px solid rgba(255,255,255,0.1);
      background: rgba(255,255,255,0.05);
      color: var(--text);
      font-weight: 700;
      font-size: 0.8rem;
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 6px;
      transition: all 0.15s;
    }
    .action-btn:hover { background: rgba(255,255,255,0.1); }
    .primary-btn {
      background: rgba(0, 243, 255, 0.2);
      border-color: var(--accent);
      color: var(--accent);
    }
    .primary-btn:hover {
      background: rgba(0, 243, 255, 0.35);
      box-shadow: 0 0 15px rgba(0, 243, 255, 0.4);
    }
  </style>
</head>
<body>
  <header>
    <div class="brand">
      <div class="brand-icon">🎵</div>
      <span>DroidSynth</span>
    </div>
    <div class="header-controls">
      <button class="action-btn primary-btn" id="playBtn">▶️ Start Engine</button>
      <button class="action-btn" id="clearBtn">Clear</button>
      <div class="status-badge" id="wsStatus">
        <div class="status-dot" id="statusDot"></div>
        <span id="statusText">Connecting...</span>
      </div>
      <div class="user-pill">
        <div class="user-color-indicator" id="userColorIndicator"></div>
        <span id="userNameDisplay">Musician</span>
      </div>
      <div class="online-count">
        <span>👥</span>
        <span id="onlineCount">1</span>
      </div>
    </div>
  </header>

  <div class="synth-container">
    <div class="visualizer-card">
      <canvas id="scopeCanvas"></canvas>
    </div>

    <div class="matrix-card">
      <div class="matrix-head">
        <div class="matrix-title">16-Step Collaborative Beat Matrix</div>
        <div class="bpm-control">
          <span>TEMPO:</span>
          <input type="range" id="bpmSlider" min="90" max="160" value="125" style="width: 90px;">
          <span id="bpmVal" style="color: var(--accent); font-weight: 700;">125 BPM</span>
        </div>
      </div>
      <div id="sequencerGrid"></div>
    </div>

    <div class="keyboard-card">
      <div style="font-size: 0.75rem; text-transform: uppercase; letter-spacing: 1px; color: var(--text-muted); font-weight: 700;">
        Live Synthesizer Keyboard (Polyphonic Web Audio)
      </div>
      <div class="keys-row" id="keysRow"></div>
    </div>
  </div>

  <script>
    (function() {
      const scopeCanvas = document.getElementById('scopeCanvas');
      const scopeCtx = scopeCanvas.getContext('2d');
      const playBtn = document.getElementById('playBtn');
      const clearBtn = document.getElementById('clearBtn');
      const bpmSlider = document.getElementById('bpmSlider');
      const bpmVal = document.getElementById('bpmVal');
      const sequencerGrid = document.getElementById('sequencerGrid');
      const keysRow = document.getElementById('keysRow');
      const statusDot = document.getElementById('statusDot');
      const statusText = document.getElementById('statusText');
      const userNameDisplay = document.getElementById('userNameDisplay');
      const userColorIndicator = document.getElementById('userColorIndicator');
      const onlineCount = document.getElementById('onlineCount');

      function resizeScope() {
        scopeCanvas.width = scopeCanvas.clientWidth;
        scopeCanvas.height = scopeCanvas.clientHeight;
      }
      window.addEventListener('resize', resizeScope);
      setTimeout(resizeScope, 100);

      // Identity
      const myId = 'mus_' + Math.random().toString(36).substr(2, 7);
      const COLORS = ['#00f3ff', '#ff0077', '#00ff88', '#a855f7', '#ffea00', '#f97316'];
      const myColor = COLORS[Math.floor(Math.random() * COLORS.length)];
      const myName = 'Musician #' + Math.floor(1000 + Math.random() * 9000);
      userNameDisplay.textContent = myName;
      userColorIndicator.style.background = myColor;

      // Audio Context
      let audioCtx = null;
      let analyser = null;
      let isPlaying = false;
      let currentStep = 0;
      let tempo = 125;
      let timerId = null;

      function initAudio() {
        if (audioCtx) return;
        audioCtx = new (window.AudioContext || window.webkitAudioContext)();
        analyser = audioCtx.createAnalyser();
        analyser.fftSize = 256;
        analyser.connect(audioCtx.destination);
      }

      // Track Setup
      const TRACKS = [
        { name: 'KICK 808', color: '#ff0077', type: 'kick' },
        { name: 'SNARE 909', color: '#00f3ff', type: 'snare' },
        { name: 'HI-HAT', color: '#00ff88', type: 'hat' },
        { name: 'CYBER BASS', color: '#a855f7', type: 'bass' },
        { name: 'NEON ARP', color: '#ffea00', type: 'lead' }
      ];

      // 5 tracks x 16 steps grid
      const gridState = Array(TRACKS.length).fill(0).map(() => Array(16).fill(false));

      // Build Sequencer UI
      TRACKS.forEach((track, tIdx) => {
        const row = document.createElement('div');
        row.className = 'sequencer-row';

        const label = document.createElement('div');
        label.className = 'track-label';
        label.style.color = track.color;
        label.textContent = track.name;
        row.appendChild(label);

        const steps = document.createElement('div');
        steps.className = 'steps-container';

        for (let s = 0; s < 16; s++) {
          const pad = document.createElement('div');
          pad.className = 'step-pad';
          pad.style.setProperty('--pad-color', track.color);
          pad.dataset.track = tIdx;
          pad.dataset.step = s;

          pad.onclick = () => {
            initAudio();
            toggleStep(tIdx, s, !gridState[tIdx][s], false);
          };
          steps.appendChild(pad);
        }
        row.appendChild(steps);
        sequencerGrid.appendChild(row);
      });

      function toggleStep(t, s, val, isRemote = false) {
        gridState[t][s] = val;
        const pad = sequencerGrid.children[t].querySelector(`.step-pad[data-step="${s}"]`);
        if (pad) {
          if (val) pad.classList.add('active');
          else pad.classList.remove('active');
        }
        if (!isRemote) {
          sendWs({ type: 'step', track: t, step: s, active: val });
        }
      }

      // Synthesizers
      function playKick() {
        if (!audioCtx) return;
        const osc = audioCtx.createOscillator();
        const gain = audioCtx.createGain();
        osc.connect(gain);
        gain.connect(analyser);

        osc.frequency.setValueAtTime(140, audioCtx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.35);

        gain.gain.setValueAtTime(1, audioCtx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + 0.35);

        osc.start();
        osc.stop(audioCtx.currentTime + 0.35);
      }

      function playSnare() {
        if (!audioCtx) return;
        // White noise
        const bufferSize = audioCtx.sampleRate * 0.18;
        const buffer = audioCtx.createBuffer(1, bufferSize, audioCtx.sampleRate);
        const data = buffer.getChannelData(0);
        for (let i = 0; i < bufferSize; i++) data[i] = Math.random() * 2 - 1;

        const noise = audioCtx.createBufferSource();
        noise.buffer = buffer;
        const filter = audioCtx.createBiquadFilter();
        filter.type = 'highpass';
        filter.frequency.value = 1000;

        const gain = audioCtx.createGain();
        gain.gain.setValueAtTime(0.8, audioCtx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.18);

        noise.connect(filter);
        filter.connect(gain);
        gain.connect(analyser);
        noise.start();
      }

      function playHat() {
        if (!audioCtx) return;
        const osc = audioCtx.createOscillator();
        osc.type = 'square';
        osc.frequency.value = 8000;
        const gain = audioCtx.createGain();
        gain.gain.setValueAtTime(0.3, audioCtx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + 0.05);

        osc.connect(gain);
        gain.connect(analyser);
        osc.start();
        osc.stop(audioCtx.currentTime + 0.05);
      }

      function playTone(freq, duration = 0.25, type = 'sawtooth') {
        if (!audioCtx) return;
        const osc = audioCtx.createOscillator();
        const filter = audioCtx.createBiquadFilter();
        const gain = audioCtx.createGain();

        osc.type = type;
        osc.frequency.value = freq;

        filter.type = 'lowpass';
        filter.frequency.setValueAtTime(1800, audioCtx.currentTime);
        filter.frequency.exponentialRampToValueAtTime(300, audioCtx.currentTime + duration);

        gain.gain.setValueAtTime(0.4, audioCtx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + duration);

        osc.connect(filter);
        filter.connect(gain);
        gain.connect(analyser);

        osc.start();
        osc.stop(audioCtx.currentTime + duration);
      }

      // Step Runner
      function runStep() {
        const pads = document.querySelectorAll(`.step-pad[data-step="${currentStep}"]`);
        pads.forEach(p => p.classList.add('current'));

        // Play active sounds
        if (gridState[0][currentStep]) playKick();
        if (gridState[1][currentStep]) playSnare();
        if (gridState[2][currentStep]) playHat();
        if (gridState[3][currentStep]) playTone(55 + (currentStep % 4) * 20, 0.3, 'sawtooth');
        if (gridState[4][currentStep]) playTone(220 + ((currentStep * 3) % 7) * 45, 0.2, 'square');

        setTimeout(() => {
          pads.forEach(p => p.classList.remove('current'));
        }, 120);

        currentStep = (currentStep + 1) % 16;
      }

      function startSequencer() {
        if (timerId) clearInterval(timerId);
        const interval = (60 / tempo / 4) * 1000;
        timerId = setInterval(runStep, interval);
      }

      playBtn.onclick = () => {
        initAudio();
        if (audioCtx.state === 'suspended') audioCtx.resume();
        isPlaying = !isPlaying;
        playBtn.innerHTML = isPlaying ? '⏸️ Stop Engine' : '▶️ Start Engine';
        if (isPlaying) startSequencer();
        else {
          clearInterval(timerId);
          timerId = null;
        }
      };

      bpmSlider.oninput = (e) => {
        tempo = parseInt(e.target.value, 10);
        bpmVal.textContent = `${tempo} BPM`;
        if (isPlaying) startSequencer();
      };

      clearBtn.onclick = () => {
        for (let t = 0; t < TRACKS.length; t++) {
          for (let s = 0; s < 16; s++) {
            if (gridState[t][s]) toggleStep(t, s, false, false);
          }
        }
      };

      // Piano Keyboard UI
      const NOTES = [
        { name: 'C4', freq: 261.63 },
        { name: 'D4', freq: 293.66 },
        { name: 'E4', freq: 329.63 },
        { name: 'F4', freq: 349.23 },
        { name: 'G4', freq: 392.00 },
        { name: 'A4', freq: 440.00 },
        { name: 'B4', freq: 493.88 },
        { name: 'C5', freq: 523.25 },
        { name: 'D5', freq: 587.33 },
        { name: 'E5', freq: 659.25 },
        { name: 'F5', freq: 698.46 },
        { name: 'G5', freq: 783.99 }
      ];

      NOTES.forEach(n => {
        const key = document.createElement('div');
        key.className = 'key-white';
        key.textContent = n.name;
        key.onpointerdown = () => {
          initAudio();
          playTone(n.freq, 0.4, 'sawtooth');
          key.classList.add('active');
          sendWs({ type: 'note', freq: n.freq, name: n.name });
        };
        key.onpointerup = () => key.classList.remove('active');
        key.onpointerleave = () => key.classList.remove('active');
        keysRow.appendChild(key);
      });

      // WebSocket setup
      let ws = null;
      let reconnectTimer = null;

      function connectWs() {
        if (reconnectTimer) clearTimeout(reconnectTimer);
        const protocol = location.protocol === 'https:' ? 'wss:' : 'ws:';
        const url = `${protocol}//${location.host}/ws/synth`;

        statusText.textContent = 'Connecting...';
        statusDot.className = 'status-dot';

        try {
          ws = new WebSocket(url);
          ws.onopen = () => {
            statusText.textContent = 'Live Jam';
            statusDot.className = 'status-dot connected';
          };
          ws.onmessage = (e) => {
            try {
              const msg = JSON.parse(e.data);
              handleRemoteMessage(msg);
            } catch (_) {}
          };
          ws.onclose = () => {
            statusText.textContent = 'Disconnected';
            statusDot.className = 'status-dot error';
            reconnectTimer = setTimeout(connectWs, 2500);
          };
          ws.onerror = () => ws.close();
        } catch (_) {
          reconnectTimer = setTimeout(connectWs, 3000);
        }
      }
      connectWs();

      function sendWs(data) {
        if (ws && ws.readyState === WebSocket.OPEN) {
          ws.send(JSON.stringify(data));
        }
      }

      function handleRemoteMessage(msg) {
        if (msg.type === 'presence' || msg.type === 'user_count') {
          onlineCount.textContent = msg.count || 1;
        } else if (msg.type === 'step') {
          toggleStep(msg.track, msg.step, msg.active, true);
        } else if (msg.type === 'note') {
          initAudio();
          playTone(msg.freq, 0.4, 'sawtooth');
        }
      }

      // Visualizer Render Loop
      function drawVisualizer() {
        requestAnimationFrame(drawVisualizer);
        scopeCtx.fillStyle = 'rgba(15, 23, 42, 0.4)';
        scopeCtx.fillRect(0, 0, scopeCanvas.width, scopeCanvas.height);

        if (!analyser) return;

        const bufferLength = analyser.frequencyBinCount;
        const timeData = new Uint8Array(bufferLength);
        analyser.getByteTimeDomainData(timeData);

        scopeCtx.lineWidth = 2.5;
        scopeCtx.strokeStyle = '#00f3ff';
        scopeCtx.shadowBlur = 10;
        scopeCtx.shadowColor = '#00f3ff';
        scopeCtx.beginPath();

        const sliceWidth = scopeCanvas.width / bufferLength;
        let x = 0;
        for (let i = 0; i < bufferLength; i++) {
          const v = timeData[i] / 128.0;
          const y = (v * scopeCanvas.height) / 2;
          if (i === 0) scopeCtx.moveTo(x, y);
          else scopeCtx.lineTo(x, y);
          x += sliceWidth;
        }
        scopeCtx.stroke();
      }
      drawVisualizer();

      // Seed default catchy beat
      [0, 8].forEach(s => toggleStep(0, s, true, true)); // kick
      [4, 12].forEach(s => toggleStep(1, s, true, true)); // snare
      [2, 6, 10, 14].forEach(s => toggleStep(2, s, true, true)); // hat
      [0, 3, 6, 8, 11, 14].forEach(s => toggleStep(3, s, true, true)); // bass
    })();
  </script>
</body>
</html>''';

  static const String mazeDemoHtml = r'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>DroidMaze — Multiplayer 3D Neon Cyber Labyrinth</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;700;800&family=JetBrains+Mono:wght@400;600;700&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg: #030712;
      --card-bg: rgba(15, 23, 42, 0.85);
      --border: rgba(56, 189, 248, 0.25);
      --accent: #00f3ff;
      --accent-pink: #ff0077;
      --accent-green: #00ff88;
      --text: #f8fafc;
      --text-muted: #94a3b8;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; user-select: none; -webkit-user-select: none; }
    body {
      background: var(--bg);
      color: var(--text);
      font-family: 'Outfit', sans-serif;
      width: 100vw;
      height: 100vh;
      overflow: hidden;
      position: relative;
    }
    #viewCanvas {
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      display: block;
      image-rendering: pixelated;
    }
    .header-hud {
      position: absolute;
      top: 16px;
      left: 16px;
      right: 16px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      pointer-events: none;
      z-index: 50;
    }
    .brand-glass {
      pointer-events: auto;
      background: var(--card-bg);
      backdrop-filter: blur(16px);
      border: 1px solid var(--border);
      border-radius: 14px;
      padding: 8px 16px;
      display: flex;
      align-items: center;
      gap: 12px;
      box-shadow: 0 8px 32px rgba(0,0,0,0.5);
    }
    .brand-icon {
      width: 30px;
      height: 30px;
      border-radius: 8px;
      background: linear-gradient(135deg, #10b981, #00f3ff);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 1.1rem;
      box-shadow: 0 0 12px rgba(16, 185, 129, 0.4);
    }
    .brand-title {
      font-weight: 800;
      font-size: 1.15rem;
      letter-spacing: -0.5px;
    }
    .stats-pill {
      display: flex;
      align-items: center;
      gap: 12px;
      font-family: 'JetBrains Mono', monospace;
      font-size: 0.8rem;
      color: var(--text-muted);
    }
    .stat-val { color: var(--accent); font-weight: 700; }
    .status-badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 4px 10px;
      border-radius: 9999px;
      font-size: 0.75rem;
      font-weight: 600;
      background: rgba(255,255,255,0.05);
      border: 1px solid rgba(255,255,255,0.1);
      font-family: 'JetBrains Mono', monospace;
    }
    .status-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: #eab308;
    }
    .status-dot.connected {
      background: var(--accent-green);
      box-shadow: 0 0 8px var(--accent-green);
    }
    .user-pill {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 4px 10px;
      background: rgba(0, 243, 255, 0.08);
      border: 1px solid rgba(0, 243, 255, 0.2);
      border-radius: 9999px;
      font-size: 0.8rem;
    }
    .user-color-indicator {
      width: 12px;
      height: 12px;
      border-radius: 50%;
      border: 2px solid #fff;
    }
    /* Mini-Map Radar */
    .minimap-card {
      position: absolute;
      top: 76px;
      right: 16px;
      background: var(--card-bg);
      backdrop-filter: blur(16px);
      border: 1px solid var(--border);
      border-radius: 14px;
      padding: 10px;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 6px;
      z-index: 40;
    }
    #miniCanvas {
      width: 120px;
      height: 120px;
      background: #000;
      border-radius: 8px;
      display: block;
    }
    .minimap-title {
      font-size: 0.7rem;
      font-family: 'JetBrains Mono', monospace;
      color: var(--text-muted);
      font-weight: 700;
    }
    /* Controls Banner */
    .controls-banner {
      position: absolute;
      bottom: 20px;
      left: 50%;
      transform: translateX(-50%);
      background: rgba(15, 23, 42, 0.85);
      border: 1px solid var(--border);
      backdrop-filter: blur(12px);
      border-radius: 9999px;
      padding: 8px 20px;
      display: flex;
      align-items: center;
      gap: 16px;
      font-size: 0.8rem;
      pointer-events: none;
      z-index: 40;
    }
    .kbd {
      background: rgba(255,255,255,0.15);
      border-radius: 4px;
      padding: 2px 6px;
      font-family: 'JetBrains Mono', monospace;
      font-size: 0.75rem;
      color: #fff;
      border: 1px solid rgba(255,255,255,0.2);
    }
    /* Mobile DPAD */
    .mobile-dpad {
      display: none;
      position: absolute;
      bottom: 24px;
      left: 24px;
      flex-direction: column;
      align-items: center;
      gap: 8px;
      z-index: 50;
    }
    .dpad-row { display: flex; gap: 8px; }
    .dpad-btn {
      width: 54px;
      height: 54px;
      border-radius: 12px;
      background: rgba(15, 23, 42, 0.75);
      border: 2px solid var(--border);
      color: #fff;
      font-size: 1.4rem;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      touch-action: none;
    }
    .dpad-btn:active {
      background: rgba(0, 243, 255, 0.3);
      border-color: var(--accent);
    }
    @media (max-width: 768px) {
      .controls-banner { display: none; }
      .mobile-dpad { display: flex; }
      .minimap-card { top: auto; bottom: 24px; right: 24px; }
    }
  </style>
</head>
<body>
  <canvas id="viewCanvas"></canvas>

  <div class="header-hud">
    <div class="brand-glass">
      <div class="brand-icon">🕹️</div>
      <span class="brand-title">DroidMaze</span>
      <div class="stats-pill">
        <div>FPS: <span class="stat-val" id="fpsDisplay">60</span></div>
        <div>ORBS: <span class="stat-val" id="orbsCollected">0/12</span></div>
      </div>
      <div class="status-badge" id="wsStatus">
        <div class="status-dot" id="statusDot"></div>
        <span id="statusText">Connecting...</span>
      </div>
      <div class="user-pill">
        <div class="user-color-indicator" id="userColorIndicator"></div>
        <span id="userNameDisplay">Explorer</span>
      </div>
      <div class="stats-pill">
        <div>EXPLORERS: <span class="stat-val" id="onlineCount">1</span></div>
      </div>
    </div>
  </div>

  <div class="minimap-card">
    <div class="minimap-title">RADAR SCANNER</div>
    <canvas id="miniCanvas" width="120" height="120"></canvas>
  </div>

  <div class="controls-banner">
    <div><span class="kbd">W</span> / <span class="kbd">S</span> Move Forward / Back</div>
    <div><span class="kbd">A</span> / <span class="kbd">D</span> Turn Left / Right</div>
    <div>Walk through glowing energy orbs to score!</div>
  </div>

  <!-- Mobile Touch Controls -->
  <div class="mobile-dpad">
    <button class="dpad-btn" id="btnUp">▲</button>
    <div class="dpad-row">
      <button class="dpad-btn" id="btnLeft">◀</button>
      <button class="dpad-btn" id="btnDown">▼</button>
      <button class="dpad-btn" id="btnRight">▶</button>
    </div>
  </div>

  <script>
    (function() {
      const viewCanvas = document.getElementById('viewCanvas');
      const viewCtx = viewCanvas.getContext('2d');
      const miniCanvas = document.getElementById('miniCanvas');
      const miniCtx = miniCanvas.getContext('2d');
      const fpsDisplay = document.getElementById('fpsDisplay');
      const orbsCollected = document.getElementById('orbsCollected');
      const statusDot = document.getElementById('statusDot');
      const statusText = document.getElementById('statusText');
      const userNameDisplay = document.getElementById('userNameDisplay');
      const userColorIndicator = document.getElementById('userColorIndicator');
      const onlineCount = document.getElementById('onlineCount');

      let screenW = 320, screenH = 200;
      function resize() {
        viewCanvas.width = screenW;
        viewCanvas.height = screenH;
      }
      resize();

      // Identity
      const myId = 'exp_' + Math.random().toString(36).substr(2, 7);
      const COLORS = ['#00f3ff', '#ff0077', '#00ff88', '#ffea00', '#a855f7', '#f97316'];
      const myColor = COLORS[Math.floor(Math.random() * COLORS.length)];
      const myName = 'Explorer #' + Math.floor(1000 + Math.random() * 9000);
      userNameDisplay.textContent = myName;
      userColorIndicator.style.background = myColor;

      // 16x16 Cyber Maze Map (1: Cyan Wall, 2: Pink Wall, 3: Amber Wall, 4: Green Wall)
      const MAP_W = 16, MAP_H = 16;
      const MAP = [
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1,
        1,0,2,2,0,0,1,0,3,3,3,0,0,4,0,1,
        1,0,2,0,0,0,0,0,0,0,3,0,0,4,0,1,
        1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
        1,0,1,1,0,0,4,4,0,0,2,2,0,0,0,1,
        1,0,1,0,0,0,4,0,0,0,0,2,0,0,0,1,
        1,0,0,0,0,0,0,0,0,0,0,0,0,3,0,1,
        1,0,0,3,3,0,0,0,1,1,0,0,0,3,0,1,
        1,0,0,0,3,0,0,0,0,1,0,0,0,0,0,1,
        1,0,0,0,0,0,2,0,0,0,0,4,4,0,0,1,
        1,0,4,4,0,0,2,0,0,0,0,0,4,0,0,1,
        1,0,4,0,0,0,0,0,3,0,0,0,0,0,0,1,
        1,0,0,0,0,0,0,0,3,3,0,0,2,2,0,1,
        1,0,0,0,1,1,0,0,0,0,0,0,0,0,0,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
      ];

      // Player State
      const player = {
        x: 2.5,
        y: 2.5,
        dirX: 1,
        dirY: 0,
        planeX: 0,
        planeY: 0.66,
        score: 0
      };

      // Collectible Orbs
      const orbs = [
        { x: 3.5, y: 1.5, collected: false },
        { x: 7.5, y: 1.5, collected: false },
        { x: 14.5, y: 3.5, collected: false },
        { x: 10.5, y: 4.5, collected: false },
        { x: 1.5, y: 7.5, collected: false },
        { x: 6.5, y: 7.5, collected: false },
        { x: 11.5, y: 8.5, collected: false },
        { x: 3.5, y: 11.5, collected: false },
        { x: 8.5, y: 12.5, collected: false },
        { x: 14.5, y: 12.5, collected: false },
        { x: 3.5, y: 14.5, collected: false },
        { x: 12.5, y: 14.5, collected: false }
      ];

      // Remote Explorers
      const remoteExplorers = new Map();

      // Controls
      const keys = { up: false, down: false, left: false, right: false };
      window.addEventListener('keydown', (e) => {
        if (e.code === 'KeyW' || e.code === 'ArrowUp') keys.up = true;
        if (e.code === 'KeyS' || e.code === 'ArrowDown') keys.down = true;
        if (e.code === 'KeyA' || e.code === 'ArrowLeft') keys.left = true;
        if (e.code === 'KeyD' || e.code === 'ArrowRight') keys.right = true;
      });
      window.addEventListener('keyup', (e) => {
        if (e.code === 'KeyW' || e.code === 'ArrowUp') keys.up = false;
        if (e.code === 'KeyS' || e.code === 'ArrowDown') keys.down = false;
        if (e.code === 'KeyA' || e.code === 'ArrowLeft') keys.left = false;
        if (e.code === 'KeyD' || e.code === 'ArrowRight') keys.right = false;
      });

      // Mobile Touch DPAD
      const btnUp = document.getElementById('btnUp');
      const btnDown = document.getElementById('btnDown');
      const btnLeft = document.getElementById('btnLeft');
      const btnRight = document.getElementById('btnRight');

      btnUp.onpointerdown = () => keys.up = true;
      btnUp.onpointerup = () => keys.up = false;
      btnDown.onpointerdown = () => keys.down = true;
      btnDown.onpointerup = () => keys.down = false;
      btnLeft.onpointerdown = () => keys.left = true;
      btnLeft.onpointerup = () => keys.left = false;
      btnRight.onpointerdown = () => keys.right = true;
      btnRight.onpointerup = () => keys.right = false;

      // WebSocket setup
      let ws = null;
      let reconnectTimer = null;

      function connectWs() {
        if (reconnectTimer) clearTimeout(reconnectTimer);
        const protocol = location.protocol === 'https:' ? 'wss:' : 'ws:';
        const url = `${protocol}//${location.host}/ws/maze`;

        statusText.textContent = 'Connecting...';
        statusDot.className = 'status-dot';

        try {
          ws = new WebSocket(url);
          ws.onopen = () => {
            statusText.textContent = 'Live Radar';
            statusDot.className = 'status-dot connected';
          };
          ws.onmessage = (e) => {
            try {
              const msg = JSON.parse(e.data);
              handleRemoteMessage(msg);
            } catch (_) {}
          };
          ws.onclose = () => {
            statusText.textContent = 'Disconnected';
            statusDot.className = 'status-dot error';
            reconnectTimer = setTimeout(connectWs, 2500);
          };
          ws.onerror = () => ws.close();
        } catch (_) {
          reconnectTimer = setTimeout(connectWs, 3000);
        }
      }
      connectWs();

      function sendWs(data) {
        if (ws && ws.readyState === WebSocket.OPEN) {
          ws.send(JSON.stringify(data));
        }
      }

      function handleRemoteMessage(msg) {
        if (msg.type === 'presence' || msg.type === 'user_count') {
          onlineCount.textContent = msg.count || 1;
        } else if (msg.type === 'pos') {
          remoteExplorers.set(msg.id, {
            ...msg,
            lastSeen: performance.now()
          });
        }
      }

      setInterval(() => {
        sendWs({
          type: 'pos',
          id: myId,
          name: myName,
          color: myColor,
          x: Math.round(player.x * 100) / 100,
          y: Math.round(player.y * 100) / 100,
          dirX: Math.round(player.dirX * 100) / 100,
          dirY: Math.round(player.dirY * 100) / 100
        });
      }, 50);

      setInterval(() => {
        const now = performance.now();
        for (const [id, exp] of remoteExplorers.entries()) {
          if (now - exp.lastSeen > 4000) remoteExplorers.delete(id);
        }
      }, 1500);

      // Wall Colors
      const WALL_COLORS = {
        1: { base: [0, 243, 255], hex: '#00f3ff' },
        2: { base: [255, 0, 119], hex: '#ff0077' },
        3: { base: [255, 170, 0], hex: '#ffaa00' },
        4: { base: [0, 255, 136], hex: '#00ff88' }
      };

      // Raycasting Engine (DDA)
      const zBuffer = new Float32Array(screenW);

      function render3D() {
        // Ceiling & Floor
        viewCtx.fillStyle = '#04060d';
        viewCtx.fillRect(0, 0, screenW, screenH / 2);
        viewCtx.fillStyle = '#0b0f19';
        viewCtx.fillRect(0, screenH / 2, screenW, screenH / 2);

        // Raycast each vertical stripe
        for (let x = 0; x < screenW; x++) {
          const cameraX = (2 * x) / screenW - 1;
          const rayDirX = player.dirX + player.planeX * cameraX;
          const rayDirY = player.dirY + player.planeY * cameraX;

          let mapX = Math.floor(player.x);
          let mapY = Math.floor(player.y);

          const deltaDistX = Math.abs(1 / rayDirX);
          const deltaDistY = Math.abs(1 / rayDirY);

          let stepX, stepY, sideDistX, sideDistY;
          if (rayDirX < 0) {
            stepX = -1;
            sideDistX = (player.x - mapX) * deltaDistX;
          } else {
            stepX = 1;
            sideDistX = (mapX + 1.0 - player.x) * deltaDistX;
          }
          if (rayDirY < 0) {
            stepY = -1;
            sideDistY = (player.y - mapY) * deltaDistY;
          } else {
            stepY = 1;
            sideDistY = (mapY + 1.0 - player.y) * deltaDistY;
          }

          let hit = 0, side = 0, wallType = 1;
          while (hit === 0) {
            if (sideDistX < sideDistY) {
              sideDistX += deltaDistX;
              mapX += stepX;
              side = 0;
            } else {
              sideDistY += deltaDistY;
              mapY += stepY;
              side = 1;
            }
            if (mapX >= 0 && mapX < MAP_W && mapY >= 0 && mapY < MAP_H) {
              const cell = MAP[mapY * MAP_W + mapX];
              if (cell > 0) {
                hit = 1;
                wallType = cell;
              }
            } else break;
          }

          let perpWallDist = side === 0 ? (sideDistX - deltaDistX) : (sideDistY - deltaDistY);
          zBuffer[x] = perpWallDist;

          const lineHeight = Math.floor(screenH / perpWallDist);
          let drawStart = Math.floor(-lineHeight / 2 + screenH / 2);
          if (drawStart < 0) drawStart = 0;
          let drawEnd = Math.floor(lineHeight / 2 + screenH / 2);
          if (drawEnd >= screenH) drawEnd = screenH - 1;

          // Depth shade & color
          const wc = WALL_COLORS[wallType] || WALL_COLORS[1];
          const brightness = Math.max(0.1, Math.min(1.0, 1.0 / (perpWallDist * 0.28)));
          const sideDim = side === 1 ? 0.75 : 1.0;
          const r = Math.floor(wc.base[0] * brightness * sideDim);
          const g = Math.floor(wc.base[1] * brightness * sideDim);
          const b = Math.floor(wc.base[2] * brightness * sideDim);

          viewCtx.fillStyle = `rgb(${r},${g},${b})`;
          viewCtx.fillRect(x, drawStart, 1, drawEnd - drawStart + 1);
        }

        // Render Remote Players as 3D Billboards
        for (const exp of remoteExplorers.values()) {
          const spriteX = exp.x - player.x;
          const spriteY = exp.y - player.y;

          const invDet = 1.0 / (player.planeX * player.dirY - player.dirX * player.planeY);
          const transformX = invDet * (player.dirY * spriteX - player.dirX * spriteY);
          const transformY = invDet * (-player.planeY * spriteX + player.planeX * spriteY);

          if (transformY > 0.3) {
            const spriteScreenX = Math.floor((screenW / 2) * (1 + transformX / transformY));
            const spriteHeight = Math.abs(Math.floor(screenH / transformY));
            const spriteWidth = Math.abs(Math.floor(screenH / transformY));

            if (transformY < zBuffer[spriteScreenX]) {
              const drawStartY = Math.floor(-spriteHeight / 2 + screenH / 2);
              const drawStartX = Math.floor(-spriteWidth / 2 + spriteScreenX);

              // 3D Avatar Diamond
              viewCtx.fillStyle = exp.color;
              viewCtx.beginPath();
              viewCtx.arc(spriteScreenX, drawStartY + spriteHeight * 0.4, Math.max(3, spriteWidth * 0.25), 0, Math.PI * 2);
              viewCtx.fill();

              // Nameplate
              viewCtx.font = '8px "JetBrains Mono", monospace';
              viewCtx.fillStyle = '#ffffff';
              viewCtx.textAlign = 'center';
              viewCtx.fillText(exp.name, spriteScreenX, drawStartY + spriteHeight * 0.15);
            }
          }
        }
      }

      // Draw Mini-Map
      function drawRadar() {
        miniCtx.fillStyle = '#070a14';
        miniCtx.fillRect(0, 0, 120, 120);

        const scale = 120 / MAP_W;

        // Maze walls
        for (let y = 0; y < MAP_H; y++) {
          for (let x = 0; x < MAP_W; x++) {
            const cell = MAP[y * MAP_W + x];
            if (cell > 0) {
              miniCtx.fillStyle = WALL_COLORS[cell]?.hex || '#64748b';
              miniCtx.fillRect(x * scale, y * scale, scale - 0.5, scale - 0.5);
            }
          }
        }

        // Orbs
        for (const orb of orbs) {
          if (!orb.collected) {
            miniCtx.fillStyle = '#ffea00';
            miniCtx.beginPath();
            miniCtx.arc(orb.x * scale, orb.y * scale, 2.5, 0, Math.PI * 2);
            miniCtx.fill();
          }
        }

        // Remote Explorers
        for (const exp of remoteExplorers.values()) {
          miniCtx.fillStyle = exp.color;
          miniCtx.beginPath();
          miniCtx.arc(exp.x * scale, exp.y * scale, 3, 0, Math.PI * 2);
          miniCtx.fill();
        }

        // Local Player Dot & Direction cone
        miniCtx.fillStyle = myColor;
        miniCtx.beginPath();
        miniCtx.arc(player.x * scale, player.y * scale, 3.5, 0, Math.PI * 2);
        miniCtx.fill();

        miniCtx.strokeStyle = '#ffffff';
        miniCtx.lineWidth = 1.5;
        miniCtx.beginPath();
        miniCtx.moveTo(player.x * scale, player.y * scale);
        miniCtx.lineTo((player.x + player.dirX * 1.5) * scale, (player.y + player.dirY * 1.5) * scale);
        miniCtx.stroke();
      }

      // Movement & Collision
      const moveSpeed = 0.055;
      const rotSpeed = 0.045;

      let lastFpsTime = performance.now();
      let frames = 0;

      function loop(now) {
        requestAnimationFrame(loop);

        // Turn
        if (keys.left) {
          const oldDirX = player.dirX;
          player.dirX = player.dirX * Math.cos(-rotSpeed) - player.dirY * Math.sin(-rotSpeed);
          player.dirY = oldDirX * Math.sin(-rotSpeed) + player.dirY * Math.cos(-rotSpeed);
          const oldPlaneX = player.planeX;
          player.planeX = player.planeX * Math.cos(-rotSpeed) - player.planeY * Math.sin(-rotSpeed);
          player.planeY = oldPlaneX * Math.sin(-rotSpeed) + player.planeY * Math.cos(-rotSpeed);
        }
        if (keys.right) {
          const oldDirX = player.dirX;
          player.dirX = player.dirX * Math.cos(rotSpeed) - player.dirY * Math.sin(rotSpeed);
          player.dirY = oldDirX * Math.sin(rotSpeed) + player.dirY * Math.cos(rotSpeed);
          const oldPlaneX = player.planeX;
          player.planeX = player.planeX * Math.cos(rotSpeed) - player.planeY * Math.sin(rotSpeed);
          player.planeY = oldPlaneX * Math.sin(rotSpeed) + player.planeY * Math.cos(rotSpeed);
        }

        // Move
        if (keys.up) {
          const nextX = player.x + player.dirX * moveSpeed;
          const nextY = player.y + player.dirY * moveSpeed;
          if (MAP[Math.floor(player.y) * MAP_W + Math.floor(nextX)] === 0) player.x = nextX;
          if (MAP[Math.floor(nextY) * MAP_W + Math.floor(player.x)] === 0) player.y = nextY;
        }
        if (keys.down) {
          const nextX = player.x - player.dirX * moveSpeed;
          const nextY = player.y - player.dirY * moveSpeed;
          if (MAP[Math.floor(player.y) * MAP_W + Math.floor(nextX)] === 0) player.x = nextX;
          if (MAP[Math.floor(nextY) * MAP_W + Math.floor(player.x)] === 0) player.y = nextY;
        }

        // Collect Orbs
        for (const orb of orbs) {
          if (!orb.collected) {
            const dx = player.x - orb.x;
            const dy = player.y - orb.y;
            if (dx * dx + dy * dy < 0.35) {
              orb.collected = true;
              player.score++;
              orbsCollected.textContent = `${player.score}/${orbs.length}`;
            }
          }
        }

        render3D();
        drawRadar();

        frames++;
        if (now - lastFpsTime >= 500) {
          const fps = Math.round((frames * 1000) / (now - lastFpsTime));
          fpsDisplay.textContent = fps;
          frames = 0;
          lastFpsTime = now;
        }
      }

      requestAnimationFrame(loop);
    })();
  </script>
</body>
</html>''';
}
