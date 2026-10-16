import * as fs from 'fs';
import * as path from 'path';

export interface ScannerEntry {
    type: 'directory' | 'file';
    relativePath: string;
    content?: string;
}

export interface ScanResult {
    sourceRoot: string;
    entries: ScannerEntry[];
    totalFiles: number;
    totalDirectories: number;
    totalChars: number;
}

const DEFAULT_IGNORED_DIRS = new Set([
    '.git',
    'node_modules',
    'bin',
    'obj',
    'dist',
    'out',
    '.vscode',
    '.vscode-test',
    '.idea'
]);

const DEFAULT_IGNORED_EXTENSIONS = new Set([
    '.vsix',
    '.exe',
    '.dll',
    '.pdb',
    '.zip',
    '.tar',
    '.gz',
    '.7z',
    '.png',
    '.jpg',
    '.jpeg',
    '.gif',
    '.ico',
    '.pdf',
    '.woff',
    '.woff2',
    '.ttf',
    '.eot',
    '.mp4',
    '.mp3',
    '.wav'
]);

export function isBinaryFile(filePath: string): boolean {
    const ext = path.extname(filePath).toLowerCase();
    if (DEFAULT_IGNORED_EXTENSIONS.has(ext)) {
        return true;
    }

    try {
        const fd = fs.openSync(filePath, 'r');
        const buffer = Buffer.alloc(Math.min(8000, fs.statSync(filePath).size));
        const bytesRead = fs.readSync(fd, buffer, 0, buffer.length, 0);
        fs.closeSync(fd);

        for (let i = 0; i < bytesRead; i++) {
            if (buffer[i] === 0) {
                return true;
            }
        }
    } catch {
        return false;
    }

    return false;
}

export async function scanSourceDirectory(sourceRoot: string): Promise<ScanResult> {
    const entries: ScannerEntry[] = [];
    let totalFiles = 0;
    let totalDirectories = 0;
    let totalChars = 0;

    async function walk(currentDir: string, relativeDir: string) {
        const dirEntries = await fs.promises.readdir(currentDir, { withFileTypes: true });

        // Sort to ensure stable tree traversal: directories first, then alphabetical
        dirEntries.sort((a, b) => {
            if (a.isDirectory() && !b.isDirectory()) return -1;
            if (!a.isDirectory() && b.isDirectory()) return 1;
            return a.name.localeCompare(b.name);
        });

        for (const dirent of dirEntries) {
            const relPath = relativeDir ? path.join(relativeDir, dirent.name) : dirent.name;
            const fullPath = path.join(currentDir, dirent.name);

            if (dirent.isDirectory()) {
                if (DEFAULT_IGNORED_DIRS.has(dirent.name)) {
                    continue;
                }

                entries.push({
                    type: 'directory',
                    relativePath: relPath
                });
                totalDirectories++;

                await walk(fullPath, relPath);
            } else if (dirent.isFile()) {
                if (isBinaryFile(fullPath)) {
                    continue;
                }

                const rawContent = await fs.promises.readFile(fullPath, 'utf8');
                const normalized = rawContent.replace(/\r\n/g, '\n');

                entries.push({
                    type: 'file',
                    relativePath: relPath,
                    content: normalized
                });

                totalFiles++;
                totalChars += normalized.length;
            }
        }
    }

    if (fs.existsSync(sourceRoot) && fs.statSync(sourceRoot).isDirectory()) {
        await walk(sourceRoot, '');
    }

    return {
        sourceRoot,
        entries,
        totalFiles,
        totalDirectories,
        totalChars
    };
}
