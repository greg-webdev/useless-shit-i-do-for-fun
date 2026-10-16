import * as vscode from 'vscode';

export class GhostReplicaPanel {
    public static currentPanel: GhostReplicaPanel | undefined;
    private readonly _panel: vscode.WebviewPanel;
    private readonly _extensionUri: vscode.Uri;
    private _disposables: vscode.Disposable[] = [];

    public static createOrShow(extensionUri: vscode.Uri, onMessage: (msg: any) => void): GhostReplicaPanel {
        const column = vscode.window.activeTextEditor
            ? vscode.window.activeTextEditor.viewColumn
            : undefined;

        if (GhostReplicaPanel.currentPanel) {
            GhostReplicaPanel.currentPanel._panel.reveal(column);
            return GhostReplicaPanel.currentPanel;
        }

        const panel = vscode.window.createWebviewPanel(
            'ghostReplicaPanel',
            'GhostReplica: Slow Folder Retyper',
            column || vscode.ViewColumn.One,
            {
                enableScripts: true,
                retainContextWhenHidden: true,
                localResourceRoots: [extensionUri]
            }
        );

        GhostReplicaPanel.currentPanel = new GhostReplicaPanel(panel, extensionUri, onMessage);
        return GhostReplicaPanel.currentPanel;
    }

    private constructor(
        panel: vscode.WebviewPanel,
        extensionUri: vscode.Uri,
        private readonly onMessageCallback: (msg: any) => void
    ) {
        this._panel = panel;
        this._extensionUri = extensionUri;

        this._update();

        this._panel.onDidDispose(() => this.dispose(), null, this._disposables);

        this._panel.webview.onDidReceiveMessage(
            message => {
                this.onMessageCallback(message);
            },
            null,
            this._disposables
        );
    }

    public postMessage(message: any) {
        this._panel.webview.postMessage(message);
    }

    public dispose() {
        GhostReplicaPanel.currentPanel = undefined;
        this._panel.dispose();
        while (this._disposables.length) {
            const x = this._disposables.pop();
            if (x) {
                x.dispose();
            }
        }
    }

    private _update() {
        this._panel.title = 'GhostReplica: Slow Folder Retyper';
        this._panel.webview.html = this._getHtmlForWebview();
    }

    private _getHtmlForWebview(): string {
        return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>GhostReplica: Slow Folder Retyper</title>
    <style>
        :root {
            --bg-color: var(--vscode-editor-background, #1e1e1e);
            --text-color: var(--vscode-editor-foreground, #d4d4d4);
            --card-bg: var(--vscode-sideBar-background, #252526);
            --border-color: var(--vscode-widget-border, #3c3c3c);
            --accent-color: var(--vscode-button-background, #007acc);
            --accent-hover: var(--vscode-button-hoverBackground, #0062a3);
            --accent-text: var(--vscode-button-foreground, #ffffff);
            --danger-bg: var(--vscode-errorForeground, #f44336);
            --success-color: #4caf50;
            --warning-color: #ff9800;
            --font-family: var(--vscode-font-family, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif);
            --mono-font: var(--vscode-editor-font-family, 'Cascadia Code', Consolas, 'Courier New', monospace);
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            background-color: var(--bg-color);
            color: var(--text-color);
            font-family: var(--font-family);
            font-size: 13px;
            line-height: 1.5;
            padding: 20px;
            user-select: none;
        }

        .header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding-bottom: 16px;
            border-bottom: 1px solid var(--border-color);
            margin-bottom: 20px;
        }

        .header-title-group {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .title {
            font-size: 18px;
            font-weight: 700;
            letter-spacing: 0.5px;
            background: linear-gradient(135deg, #00aaff, #9d4edd);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }

        .badge-status {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 3px 8px;
            border-radius: 12px;
            font-size: 11px;
            font-weight: 600;
            background-color: rgba(76, 175, 80, 0.15);
            color: var(--success-color);
            border: 1px solid rgba(76, 175, 80, 0.3);
        }

        .badge-status.running {
            background-color: rgba(0, 122, 204, 0.2);
            color: #4fc3f7;
            border-color: rgba(0, 122, 204, 0.5);
        }

        .badge-status.aborted {
            background-color: rgba(244, 67, 54, 0.2);
            color: #ef5350;
            border-color: rgba(244, 67, 54, 0.5);
        }

        .pulse-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background-color: currentColor;
            box-shadow: 0 0 6px currentColor;
        }

        .btn-emergency {
            background-color: #d32f2f;
            color: #ffffff;
            border: none;
            padding: 8px 16px;
            font-weight: 700;
            font-size: 12px;
            border-radius: 4px;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            transition: all 0.2s ease;
            box-shadow: 0 2px 8px rgba(211, 47, 47, 0.4);
        }

        .btn-emergency:hover {
            background-color: #b71c1c;
            transform: scale(1.02);
            box-shadow: 0 3px 12px rgba(211, 47, 47, 0.6);
        }

        .grid-2 {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 16px;
            margin-bottom: 16px;
        }

        .card {
            background-color: var(--card-bg);
            border: 1px solid var(--border-color);
            border-radius: 6px;
            padding: 16px;
        }

        .card-title {
            font-size: 13px;
            font-weight: 600;
            margin-bottom: 12px;
            display: flex;
            align-items: center;
            gap: 8px;
            color: var(--text-color);
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .path-group {
            display: flex;
            gap: 8px;
            margin-bottom: 10px;
        }

        .input-path {
            flex: 1;
            background-color: var(--vscode-input-background, #3c3c3c);
            color: var(--vscode-input-foreground, #cccccc);
            border: 1px solid var(--border-color);
            border-radius: 4px;
            padding: 6px 10px;
            font-family: var(--mono-font);
            font-size: 11px;
            outline: none;
        }

        .btn-secondary {
            background-color: var(--vscode-button-secondaryBackground, #3a3d41);
            color: var(--vscode-button-secondaryForeground, #ffffff);
            border: 1px solid var(--border-color);
            border-radius: 4px;
            padding: 6px 12px;
            font-size: 12px;
            cursor: pointer;
            transition: background 0.15s ease;
            white-space: nowrap;
        }

        .btn-secondary:hover {
            background-color: var(--vscode-button-secondaryHoverBackground, #45494e);
        }

        .btn-primary {
            background-color: var(--accent-color);
            color: var(--accent-text);
            border: none;
            border-radius: 4px;
            padding: 10px 20px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.15s ease;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            box-shadow: 0 2px 8px rgba(0, 122, 204, 0.3);
        }

        .btn-primary:hover:not(:disabled) {
            background-color: var(--accent-hover);
            transform: translateY(-1px);
        }

        .btn-primary:disabled {
            opacity: 0.5;
            cursor: not-allowed;
            transform: none;
        }

        .control-row {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 12px;
            gap: 16px;
        }

        .control-label {
            font-size: 12px;
            color: var(--text-color);
            min-width: 170px;
        }

        .control-slider-group {
            display: flex;
            align-items: center;
            gap: 10px;
            flex: 1;
        }

        .slider {
            flex: 1;
            height: 4px;
            border-radius: 2px;
            background: #444;
            outline: none;
            -webkit-appearance: none;
        }

        .slider::-webkit-slider-thumb {
            -webkit-appearance: none;
            width: 14px;
            height: 14px;
            border-radius: 50%;
            background: var(--accent-color);
            cursor: pointer;
            box-shadow: 0 0 4px rgba(0, 0, 0, 0.5);
        }

        .slider-value {
            font-family: var(--mono-font);
            font-size: 12px;
            min-width: 45px;
            text-align: right;
            font-weight: 600;
            color: #4fc3f7;
        }

        .checkbox-row {
            display: flex;
            align-items: center;
            gap: 8px;
            cursor: pointer;
            margin-top: 6px;
        }

        .checkbox-row input {
            cursor: pointer;
            accent-color: var(--accent-color);
        }

        .telemetry-section {
            margin-top: 16px;
        }

        .progress-block {
            margin-bottom: 12px;
        }

        .progress-header {
            display: flex;
            justify-content: space-between;
            font-size: 11px;
            margin-bottom: 4px;
            color: #aaa;
        }

        .progress-bar-container {
            width: 100%;
            height: 8px;
            background-color: rgba(255, 255, 255, 0.08);
            border-radius: 4px;
            overflow: hidden;
            position: relative;
        }

        .progress-bar-fill {
            height: 100%;
            background: linear-gradient(90deg, #007acc, #4caf50);
            width: 0%;
            transition: width 0.15s ease;
        }

        .progress-bar-fill.file {
            background: linear-gradient(90deg, #9d4edd, #00aaff);
        }

        .readout-bar {
            display: flex;
            gap: 20px;
            background-color: rgba(0, 0, 0, 0.25);
            padding: 8px 12px;
            border-radius: 4px;
            font-family: var(--mono-font);
            font-size: 11px;
            margin-bottom: 12px;
            border: 1px solid var(--border-color);
        }

        .readout-item {
            display: flex;
            gap: 6px;
        }

        .readout-label {
            color: #888;
        }

        .readout-val {
            color: #4fc3f7;
            font-weight: 600;
        }

        .terminal-container {
            background-color: #121212;
            border: 1px solid var(--border-color);
            border-radius: 4px;
            font-family: var(--mono-font);
            font-size: 11px;
            padding: 10px;
            height: 180px;
            overflow-y: auto;
            color: #ccc;
        }

        .log-line {
            margin-bottom: 3px;
            white-space: pre-wrap;
            word-break: break-all;
        }

        .log-time {
            color: #666;
            margin-right: 6px;
        }

        .log-tag {
            font-weight: 700;
            margin-right: 6px;
        }

        .log-tag.info { color: #4fc3f7; }
        .log-tag.success { color: #66bb6a; }
        .log-tag.warning { color: #ffa726; }
        .log-tag.error { color: #ef5350; }
        .log-tag.typing { color: #ab47bc; }

        .action-bar {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-top: 16px;
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="header-title-group">
            <span class="title">GhostReplica</span>
            <div id="statusBadge" class="badge-status">
                <div class="pulse-dot"></div>
                <span id="statusText">ENGINE READY</span>
            </div>
        </div>
        <button id="btnEmergencyStop" class="btn-emergency" title="Instant Physical Kill Switch (or press ESC)">
            <span>EMERGENCY STOP (ESC)</span>
        </button>
    </div>

    <div class="grid-2">
        <div class="card">
            <div class="card-title">Folder Configuration</div>
            
            <label style="font-size: 11px; color: #aaa; margin-bottom: 4px; display: block;">Source Codebase (Files to Replicate)</label>
            <div class="path-group">
                <input id="sourcePathInput" class="input-path" type="text" placeholder="Select source codebase folder..." readonly />
                <button id="btnBrowseSource" class="btn-secondary">Browse...</button>
            </div>

            <label style="font-size: 11px; color: #aaa; margin-bottom: 4px; display: block;">Destination Target (Where to Retype)</label>
            <div class="path-group">
                <input id="destPathInput" class="input-path" type="text" placeholder="Select destination target folder..." readonly />
                <button id="btnBrowseDest" class="btn-secondary">Browse...</button>
            </div>

            <div id="scanSummary" style="font-size: 11px; color: #888; margin-top: 8px;">
                No folders selected.
            </div>
        </div>

        <div class="card">
            <div class="card-title">Input Simulation & Cadence</div>
            
            <div class="control-row">
                <span class="control-label">Min Keystroke Delay</span>
                <div class="control-slider-group">
                    <input id="sliderMinDelay" class="slider" type="range" min="5" max="200" value="35" />
                    <span id="valMinDelay" class="slider-value">35ms</span>
                </div>
            </div>

            <div class="control-row">
                <span class="control-label">Max Keystroke Delay</span>
                <div class="control-slider-group">
                    <input id="sliderMaxDelay" class="slider" type="range" min="10" max="500" value="120" />
                    <span id="valMaxDelay" class="slider-value">120ms</span>
                </div>
            </div>

            <div class="control-row">
                <span class="control-label">Mouse Speed Duration</span>
                <div class="control-slider-group">
                    <input id="sliderMouseSpeed" class="slider" type="range" min="100" max="2000" value="600" />
                    <span id="valMouseSpeed" class="slider-value">600ms</span>
                </div>
            </div>

            <label class="checkbox-row">
                <input id="chkSimulateTypos" type="checkbox" checked />
                <span>Simulate Human Typos (QWERTY Backspace Recovery ~3%)</span>
            </label>
        </div>
    </div>

    <div class="card telemetry-section">
        <div class="card-title">Live Hardware Telemetry & Progress</div>

        <div class="progress-block">
            <div class="progress-header">
                <span>Overall Progress</span>
                <span id="overallPercentText">0% (0/0 files)</span>
            </div>
            <div class="progress-bar-container">
                <div id="overallProgressFill" class="progress-bar-fill"></div>
            </div>
        </div>

        <div class="progress-block">
            <div class="progress-header">
                <span id="currentFileLabel">Current File: None</span>
                <span id="currentFilePercentText">0% (0/0 chars)</span>
            </div>
            <div class="progress-bar-container">
                <div id="currentFileProgressFill" class="progress-bar-fill file"></div>
            </div>
        </div>

        <div class="readout-bar">
            <div class="readout-item">
                <span class="readout-label">OS Cursor:</span>
                <span id="readoutCursor" class="readout-val">X: 0, Y: 0</span>
            </div>
            <div class="readout-item">
                <span class="readout-label">Target Window:</span>
                <span class="readout-val">Visual Studio Code</span>
            </div>
            <div class="readout-item">
                <span class="readout-label">Failsafe:</span>
                <span style="color: #66bb6a; font-weight: 600;">ACTIVE (ESC / Top-Left)</span>
            </div>
        </div>

        <div id="terminalLog" class="terminal-container">
            <div class="log-line"><span class="log-time">[Init]</span><span class="log-tag info">[READY]</span>GhostReplica engine ready. Select folders and click 'Start Retyping'.</div>
        </div>
    </div>

    <div class="action-bar">
        <button id="btnStartRetype" class="btn-primary" disabled>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
                <path d="M8 5v14l11-7z"/>
            </svg>
            <span>Start Slow Folder Retyper</span>
        </button>

        <button id="btnClearLog" class="btn-secondary">Clear Terminal</button>
    </div>

    <script>
        const vscode = acquireVsCodeApi();

        // State
        let sourcePath = '';
        let destPath = '';
        let isRunning = false;
        let totalFiles = 0;
        let currentFileIndex = 0;

        // Elements
        const statusBadge = document.getElementById('statusBadge');
        const statusText = document.getElementById('statusText');
        const sourcePathInput = document.getElementById('sourcePathInput');
        const destPathInput = document.getElementById('destPathInput');
        const scanSummary = document.getElementById('scanSummary');
        const btnBrowseSource = document.getElementById('btnBrowseSource');
        const btnBrowseDest = document.getElementById('btnBrowseDest');
        const btnStartRetype = document.getElementById('btnStartRetype');
        const btnEmergencyStop = document.getElementById('btnEmergencyStop');
        const btnClearLog = document.getElementById('btnClearLog');
        const terminalLog = document.getElementById('terminalLog');

        const sliderMinDelay = document.getElementById('sliderMinDelay');
        const valMinDelay = document.getElementById('valMinDelay');
        const sliderMaxDelay = document.getElementById('sliderMaxDelay');
        const valMaxDelay = document.getElementById('valMaxDelay');
        const sliderMouseSpeed = document.getElementById('sliderMouseSpeed');
        const valMouseSpeed = document.getElementById('valMouseSpeed');
        const chkSimulateTypos = document.getElementById('chkSimulateTypos');

        const overallProgressFill = document.getElementById('overallProgressFill');
        const overallPercentText = document.getElementById('overallPercentText');
        const currentFileProgressFill = document.getElementById('currentFileProgressFill');
        const currentFileLabel = document.getElementById('currentFileLabel');
        const currentFilePercentText = document.getElementById('currentFilePercentText');
        const readoutCursor = document.getElementById('readoutCursor');

        // Sliders binding
        sliderMinDelay.addEventListener('input', () => {
            valMinDelay.textContent = sliderMinDelay.value + 'ms';
            if (parseInt(sliderMinDelay.value) > parseInt(sliderMaxDelay.value)) {
                sliderMaxDelay.value = sliderMinDelay.value;
                valMaxDelay.textContent = sliderMaxDelay.value + 'ms';
            }
        });

        sliderMaxDelay.addEventListener('input', () => {
            valMaxDelay.textContent = sliderMaxDelay.value + 'ms';
            if (parseInt(sliderMaxDelay.value) < parseInt(sliderMinDelay.value)) {
                sliderMinDelay.value = sliderMaxDelay.value;
                valMinDelay.textContent = sliderMinDelay.value + 'ms';
            }
        });

        sliderMouseSpeed.addEventListener('input', () => {
            valMouseSpeed.textContent = sliderMouseSpeed.value + 'ms';
        });

        // Browsing
        btnBrowseSource.addEventListener('click', () => {
            vscode.postMessage({ command: 'browseSource' });
        });

        btnBrowseDest.addEventListener('click', () => {
            vscode.postMessage({ command: 'browseDestination' });
        });

        // Start
        btnStartRetype.addEventListener('click', () => {
            if (isRunning) return;
            const config = {
                minTypeDelayMs: parseInt(sliderMinDelay.value),
                maxTypeDelayMs: parseInt(sliderMaxDelay.value),
                mouseSpeedDurationMs: parseInt(sliderMouseSpeed.value),
                punctuationPauseMs: 220,
                newlinePauseMs: 180,
                typoProbability: chkSimulateTypos.checked ? 0.03 : 0.0,
                failsafeCornerTolerancePx: 5
            };

            vscode.postMessage({
                command: 'startRetyper',
                config: config
            });
        });

        // Emergency Stop
        btnEmergencyStop.addEventListener('click', () => {
            vscode.postMessage({ command: 'stopRetyper' });
        });

        btnClearLog.addEventListener('click', () => {
            terminalLog.innerHTML = '';
        });

        // Logging helper
        function appendLog(tag, tagClass, text) {
            const time = new Date().toLocaleTimeString();
            const div = document.createElement('div');
            div.className = 'log-line';
            div.innerHTML = '<span class="log-time">[' + time + ']</span><span class="log-tag ' + tagClass + '">[' + tag + ']</span>' + escapeHtml(text);
            terminalLog.appendChild(div);
            terminalLog.scrollTop = terminalLog.scrollHeight;
        }

        function escapeHtml(str) {
            return String(str)
                .replace(/&/g, '&amp;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;')
                .replace(/"/g, '&quot;');
        }

        function updateStartButtonState() {
            btnStartRetype.disabled = !sourcePath || !destPath || isRunning;
        }

        function setStatus(state, text) {
            statusBadge.className = 'badge-status ' + state;
            statusText.textContent = text;
        }

        // Messages from Extension Host
        window.addEventListener('message', event => {
            const msg = event.data;
            switch (msg.type) {
                case 'setSourcePath':
                    sourcePath = msg.path;
                    sourcePathInput.value = sourcePath;
                    updateStartButtonState();
                    break;

                case 'setDestinationPath':
                    destPath = msg.path;
                    destPathInput.value = destPath;
                    updateStartButtonState();
                    break;

                case 'scanComplete':
                    totalFiles = msg.totalFiles;
                    scanSummary.textContent = 'Found ' + msg.totalFiles + ' text files, ' + msg.totalDirectories + ' folders (' + (msg.totalChars.toLocaleString()) + ' chars).';
                    appendLog('SCAN', 'info', 'Source scanned: ' + msg.totalFiles + ' files, ' + msg.totalChars + ' characters.');
                    updateStartButtonState();
                    break;

                case 'statusChange':
                    isRunning = (msg.status === 'running');
                    updateStartButtonState();

                    if (msg.status === 'running') {
                        setStatus('running', 'TYPING IN PROGRESS');
                        appendLog('ENGINE', 'info', 'Physical automation engine spawned and active.');
                    } else if (msg.status === 'finished') {
                        setStatus('', 'COMPLETED');
                        appendLog('SUCCESS', 'success', 'All files physically typed and saved successfully!');
                    } else if (msg.status === 'aborted') {
                        setStatus('aborted', 'ABORTED (FAILSAFE)');
                        appendLog('ABORT', 'error', 'Operation stopped via hardware failsafe (ESC or Corner).');
                    } else if (msg.status === 'error') {
                        setStatus('aborted', 'ERROR');
                        appendLog('ERROR', 'error', msg.message || 'An error occurred.');
                    } else {
                        setStatus('', 'ENGINE READY');
                    }
                    break;

                case 'engineEvent':
                    handleEngineEvent(msg.event, msg.data);
                    break;
            }
        });

        function handleEngineEvent(eventType, data) {
            if (eventType === 'started') {
                totalFiles = data.totalFiles || totalFiles;
                currentFileIndex = 0;
            } else if (eventType === 'opening_file') {
                currentFileIndex = data.fileIndex;
                currentFileLabel.textContent = 'File (' + data.fileIndex + '/' + data.totalFiles + '): ' + data.relativePath;
                
                const overallPct = Math.round(((data.fileIndex - 1) / (data.totalFiles || 1)) * 100);
                overallProgressFill.style.width = overallPct + '%';
                overallPercentText.textContent = overallPct + '% (' + data.fileIndex + '/' + data.totalFiles + ' files)';
                
                currentFileProgressFill.style.width = '0%';
                currentFilePercentText.textContent = '0%';
                appendLog('OPEN', 'typing', 'Focusing editor: ' + data.relativePath);
            } else if (eventType === 'typing_progress') {
                currentFileProgressFill.style.width = data.percent + '%';
                currentFilePercentText.textContent = data.percent + '% (' + data.charsTyped + '/' + data.totalChars + ' chars)';
                readoutCursor.textContent = 'X: ' + data.cursorX + ', Y: ' + data.cursorY;
            } else if (eventType === 'file_completed') {
                const overallPct = Math.round((data.fileIndex / (data.totalFiles || 1)) * 100);
                overallProgressFill.style.width = overallPct + '%';
                overallPercentText.textContent = overallPct + '% (' + data.fileIndex + '/' + data.totalFiles + ' files)';
                appendLog('SAVED', 'success', 'Committed via Ctrl+S: ' + data.relativePath + ' (' + data.size + ' bytes)');
            } else if (eventType === 'directory_created') {
                appendLog('FOLDER', 'info', 'Ensured directory: ' + data.relativePath);
            } else if (eventType === 'aborted') {
                appendLog('ABORT', 'error', 'Hardware failsafe triggered: ' + data.reason);
            } else if (eventType === 'log') {
                appendLog('STDOUT', 'info', data.message);
            } else if (eventType === 'error') {
                appendLog('STDERR', 'error', data.message);
            }
        }
    </script>
</body>
</html>`;
    }
}
