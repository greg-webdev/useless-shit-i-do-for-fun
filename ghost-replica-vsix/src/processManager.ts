import * as cp from 'child_process';
import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';
import * as readline from 'readline';

export interface AutomationConfig {
    minTypeDelayMs: number;
    maxTypeDelayMs: number;
    punctuationPauseMs: number;
    newlinePauseMs: number;
    mouseSpeedDurationMs: number;
    typoProbability: number;
    failsafeCornerTolerancePx: number;
    testMode?: boolean;
}

export interface AutomationPayload {
    sourceRoot: string;
    destinationRoot: string;
    targetWindowTitle: string;
    config: AutomationConfig;
    entries: Array<{
        type: 'directory' | 'file';
        relativePath: string;
        content?: string;
    }>;
}

export type ProcessEventHandler = (event: string, data: any) => void;

export class AutomationProcessManager {
    private childProcess: cp.ChildProcess | null = null;
    private payloadFilePath: string | null = null;
    private isRunning = false;

    constructor(private readonly binaryPath: string) {}

    public get active(): boolean {
        return this.isRunning;
    }

    public async start(payload: AutomationPayload, onEvent: ProcessEventHandler): Promise<number> {
        if (this.isRunning) {
            throw new Error('Automation engine is already running.');
        }

        if (!fs.existsSync(this.binaryPath)) {
            throw new Error(`Automation binary not found at: ${this.binaryPath}`);
        }

        // Write payload to temporary file
        const tempId = `ghost_payload_${Date.now()}_${Math.random().toString(36).substring(2, 8)}.json`;
        this.payloadFilePath = path.join(os.tmpdir(), tempId);
        await fs.promises.writeFile(this.payloadFilePath, JSON.stringify(payload, null, 2), 'utf8');

        return new Promise<number>((resolve, reject) => {
            const args = ['--payload', this.payloadFilePath!];
            if (payload.config.testMode) {
                args.push('--test-mode');
            }

            try {
                this.childProcess = cp.spawn(this.binaryPath, args, {
                    windowsHide: false,
                    stdio: ['pipe', 'pipe', 'pipe']
                });
                this.isRunning = true;
            } catch (err: any) {
                this.cleanup();
                return reject(err);
            }

            if (!this.childProcess || !this.childProcess.stdout || !this.childProcess.stderr) {
                this.cleanup();
                return reject(new Error('Failed to spawn automation engine process streams.'));
            }

            const rl = readline.createInterface({
                input: this.childProcess.stdout,
                terminal: false
            });

            rl.on('line', (line: string) => {
                const trimmed = line.trim();
                if (!trimmed) return;

                try {
                    const parsed = JSON.parse(trimmed);
                    if (parsed && parsed.event) {
                        onEvent(parsed.event, parsed);
                    } else {
                        onEvent('log', { message: trimmed });
                    }
                } catch {
                    onEvent('log', { message: trimmed });
                }
            });

            this.childProcess.stderr.on('data', (data: Buffer) => {
                const text = data.toString('utf8').trim();
                if (text) {
                    onEvent('error', { message: text });
                }
            });

            this.childProcess.on('error', (err: Error) => {
                onEvent('error', { message: err.message });
                this.cleanup();
                reject(err);
            });

            this.childProcess.on('close', (code: number | null) => {
                this.isRunning = false;
                const exitCode = code ?? 0;

                if (exitCode === 2) {
                    onEvent('aborted', { code: exitCode, message: 'Failsafe abort triggered.' });
                } else if (exitCode === 0) {
                    onEvent('finished', { code: exitCode });
                } else {
                    onEvent('error', { code: exitCode, message: `Process exited with code ${exitCode}` });
                }

                this.cleanup();
                resolve(exitCode);
            });
        });
    }

    public kill(): void {
        if (this.childProcess && this.isRunning) {
            try {
                if (process.platform === 'win32' && this.childProcess.pid) {
                    cp.spawnSync('taskkill', ['/pid', this.childProcess.pid.toString(), '/f', '/t']);
                } else {
                    this.childProcess.kill('SIGTERM');
                }
            } catch {
                // Ignore kill errors
            } finally {
                this.isRunning = false;
                this.cleanup();
            }
        }
    }

    private cleanup(): void {
        this.isRunning = false;
        this.childProcess = null;

        if (this.payloadFilePath && fs.existsSync(this.payloadFilePath)) {
            try {
                fs.unlinkSync(this.payloadFilePath);
            } catch {
                // Ignore unlink errors
            }
            this.payloadFilePath = null;
        }
    }
}
