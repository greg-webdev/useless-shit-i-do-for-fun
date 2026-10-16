import * as fs from 'fs';
import * as path from 'path';
import * as vscode from 'vscode';
import { AutomationProcessManager, AutomationConfig, AutomationPayload } from './processManager';
import { scanSourceDirectory, ScanResult } from './scanner';
import { GhostReplicaPanel } from './webview/panel';

interface OriginalSettingsBackup {
    autoIndent?: any;
    autoClosingBrackets?: any;
    autoClosingQuotes?: any;
    acceptSuggestionOnEnter?: any;
    quickSuggestions?: any;
    autoSave?: any;
}

let activeProcessManager: AutomationProcessManager | null = null;
let currentSourcePath: string = '';
let currentDestPath: string = '';
let currentScanResult: ScanResult | null = null;

export function activate(context: vscode.ExtensionContext) {
    const binaryPath = path.join(context.extensionPath, 'bin', 'automation_engine.exe');
    activeProcessManager = new AutomationProcessManager(binaryPath);

    const openPanelCmd = vscode.commands.registerCommand('ghostReplica.openPanel', () => {
        const panel = GhostReplicaPanel.createOrShow(context.extensionUri, async (message) => {
            switch (message.command) {
                case 'browseSource': {
                    const uris = await vscode.window.showOpenDialog({
                        canSelectFiles: false,
                        canSelectFolders: true,
                        canSelectMany: false,
                        title: 'Select Source Codebase Folder'
                    });
                    if (uris && uris.length > 0) {
                        currentSourcePath = uris[0].fsPath;
                        panel.postMessage({ type: 'setSourcePath', path: currentSourcePath });

                        vscode.window.withProgress({
                            location: vscode.ProgressLocation.Notification,
                            title: 'Scanning source codebase...'
                        }, async () => {
                            currentScanResult = await scanSourceDirectory(currentSourcePath);
                            panel.postMessage({
                                type: 'scanComplete',
                                totalFiles: currentScanResult.totalFiles,
                                totalDirectories: currentScanResult.totalDirectories,
                                totalChars: currentScanResult.totalChars
                            });
                        });
                    }
                    break;
                }

                case 'browseDestination': {
                    const uris = await vscode.window.showOpenDialog({
                        canSelectFiles: false,
                        canSelectFolders: true,
                        canSelectMany: false,
                        title: 'Select Destination Folder'
                    });
                    if (uris && uris.length > 0) {
                        currentDestPath = uris[0].fsPath;
                        panel.postMessage({ type: 'setDestinationPath', path: currentDestPath });
                    }
                    break;
                }

                case 'startRetyper': {
                    if (!currentSourcePath || !currentDestPath) {
                        vscode.window.showErrorMessage('Please select both a source folder and a destination folder.');
                        return;
                    }

                    if (!currentScanResult || currentScanResult.entries.length === 0) {
                        currentScanResult = await scanSourceDirectory(currentSourcePath);
                    }

                    if (currentScanResult.entries.length === 0) {
                        vscode.window.showWarningMessage('No text files found in the source directory.');
                        return;
                    }

                    const config: AutomationConfig = message.config;

                    // Ensure target window title includes VS Code
                    const payload: AutomationPayload = {
                        sourceRoot: currentSourcePath,
                        destinationRoot: currentDestPath,
                        targetWindowTitle: 'Visual Studio Code',
                        config: config,
                        entries: currentScanResult.entries
                    };

                    runAutomationWithSanitation(panel, payload, binaryPath);
                    break;
                }

                case 'stopRetyper': {
                    if (activeProcessManager && activeProcessManager.active) {
                        activeProcessManager.kill();
                        panel.postMessage({ type: 'statusChange', status: 'aborted' });
                        vscode.window.showInformationMessage('GhostReplica engine stopped.');
                    }
                    break;
                }
            }
        });

        // Initialize with active workspace if open
        if (vscode.workspace.workspaceFolders && vscode.workspace.workspaceFolders.length > 0) {
            currentSourcePath = vscode.workspace.workspaceFolders[0].uri.fsPath;
            panel.postMessage({ type: 'setSourcePath', path: currentSourcePath });

            scanSourceDirectory(currentSourcePath).then(res => {
                currentScanResult = res;
                panel.postMessage({
                    type: 'scanComplete',
                    totalFiles: res.totalFiles,
                    totalDirectories: res.totalDirectories,
                    totalChars: res.totalChars
                });
            });
        }
    });

    context.subscriptions.push(openPanelCmd);
}

async function runAutomationWithSanitation(
    panel: GhostReplicaPanel,
    payload: AutomationPayload,
    binaryPath: string
) {
    const editorConfig = vscode.workspace.getConfiguration('editor');
    const filesConfig = vscode.workspace.getConfiguration('files');

    // 1. Backup original editor settings
    const backup: OriginalSettingsBackup = {
        autoIndent: editorConfig.inspect('autoIndent')?.globalValue,
        autoClosingBrackets: editorConfig.inspect('autoClosingBrackets')?.globalValue,
        autoClosingQuotes: editorConfig.inspect('autoClosingQuotes')?.globalValue,
        acceptSuggestionOnEnter: editorConfig.inspect('acceptSuggestionOnEnter')?.globalValue,
        quickSuggestions: editorConfig.inspect('quickSuggestions')?.globalValue,
        autoSave: filesConfig.inspect('autoSave')?.globalValue
    };

    // 2. Apply editor sanitation guards
    try {
        await editorConfig.update('autoIndent', 'none', vscode.ConfigurationTarget.Global);
        await editorConfig.update('autoClosingBrackets', 'never', vscode.ConfigurationTarget.Global);
        await editorConfig.update('autoClosingQuotes', 'never', vscode.ConfigurationTarget.Global);
        await editorConfig.update('acceptSuggestionOnEnter', 'off', vscode.ConfigurationTarget.Global);
        await editorConfig.update('quickSuggestions', { other: false, comments: false, strings: false }, vscode.ConfigurationTarget.Global);
        await filesConfig.update('autoSave', 'off', vscode.ConfigurationTarget.Global);

        // Pre-create destination directories and empty files so VS Code can open tabs
        for (const entry of payload.entries) {
            const destFullPath = path.join(payload.destinationRoot, entry.relativePath);
            if (entry.type === 'directory') {
                if (!fs.existsSync(destFullPath)) {
                    await fs.promises.mkdir(destFullPath, { recursive: true });
                }
            } else if (entry.type === 'file') {
                const parentDir = path.dirname(destFullPath);
                if (!fs.existsSync(parentDir)) {
                    await fs.promises.mkdir(parentDir, { recursive: true });
                }
                if (!fs.existsSync(destFullPath)) {
                    await fs.promises.writeFile(destFullPath, '', 'utf8');
                }
            }
        }

        panel.postMessage({ type: 'statusChange', status: 'running' });

        if (!activeProcessManager) {
            activeProcessManager = new AutomationProcessManager(binaryPath);
        }

        const exitCode = await activeProcessManager.start(payload, async (event, data) => {
            panel.postMessage({
                type: 'engineEvent',
                event: event,
                data: data
            });

            // When engine begins a file, bring that editor tab into active focus in VS Code
            if (event === 'opening_file' && data.fullPath) {
                try {
                    const doc = await vscode.workspace.openTextDocument(data.fullPath);
                    await vscode.window.showTextDocument(doc, { preview: false, preserveFocus: false });
                } catch {
                    // Ignore focus errors
                }
            }
        });

        if (exitCode === 0) {
            panel.postMessage({ type: 'statusChange', status: 'finished' });
            vscode.window.showInformationMessage('GhostReplica: All files successfully replicated and committed!');
        } else if (exitCode === 2) {
            panel.postMessage({ type: 'statusChange', status: 'aborted' });
            vscode.window.showWarningMessage('GhostReplica: Operation aborted via hardware failsafe.');
        } else {
            panel.postMessage({ type: 'statusChange', status: 'error', message: `Engine process exited with code ${exitCode}` });
        }
    } catch (err: any) {
        panel.postMessage({ type: 'statusChange', status: 'error', message: err.message });
        vscode.window.showErrorMessage(`GhostReplica error: ${err.message}`);
    } finally {
        // 3. ALWAYS restore original settings in finally block
        try {
            await editorConfig.update('autoIndent', backup.autoIndent, vscode.ConfigurationTarget.Global);
            await editorConfig.update('autoClosingBrackets', backup.autoClosingBrackets, vscode.ConfigurationTarget.Global);
            await editorConfig.update('autoClosingQuotes', backup.autoClosingQuotes, vscode.ConfigurationTarget.Global);
            await editorConfig.update('acceptSuggestionOnEnter', backup.acceptSuggestionOnEnter, vscode.ConfigurationTarget.Global);
            await editorConfig.update('quickSuggestions', backup.quickSuggestions, vscode.ConfigurationTarget.Global);
            await filesConfig.update('autoSave', backup.autoSave, vscode.ConfigurationTarget.Global);
        } catch {
            // Ignore settings restore errors
        }
    }
}

export function deactivate() {
    if (activeProcessManager && activeProcessManager.active) {
        activeProcessManager.kill();
    }
}
