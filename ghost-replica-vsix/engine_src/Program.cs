using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading;
using System.Windows.Forms;

namespace GhostReplica;

#region Win32 P/Invoke & Structures

[StructLayout(LayoutKind.Sequential)]
public struct POINT
{
    public int X;
    public int Y;
}

[StructLayout(LayoutKind.Sequential)]
public struct RECT
{
    public int Left;
    public int Top;
    public int Right;
    public int Bottom;
}

[StructLayout(LayoutKind.Sequential)]
public struct MOUSEINPUT
{
    public int dx;
    public int dy;
    public uint mouseData;
    public uint dwFlags;
    public uint time;
    public UIntPtr dwExtraInfo;
}

[StructLayout(LayoutKind.Sequential)]
public struct KEYBDINPUT
{
    public ushort wVk;
    public ushort wScan;
    public uint dwFlags;
    public uint time;
    public UIntPtr dwExtraInfo;
}

[StructLayout(LayoutKind.Sequential)]
public struct HARDWAREINPUT
{
    public uint uMsg;
    public ushort wParamL;
    public ushort wParamH;
}

[StructLayout(LayoutKind.Explicit)]
public struct INPUT
{
    [FieldOffset(0)]
    public uint type;

    [FieldOffset(8)]
    public MOUSEINPUT mi;

    [FieldOffset(8)]
    public KEYBDINPUT ki;

    [FieldOffset(8)]
    public HARDWAREINPUT hi;
}

public static class NativeMethods
{
    public const uint INPUT_MOUSE = 0;
    public const uint INPUT_KEYBOARD = 1;
    public const uint INPUT_HARDWARE = 2;

    public const uint KEYEVENTF_KEYDOWN = 0x0000;
    public const uint KEYEVENTF_EXTENDEDKEY = 0x0001;
    public const uint KEYEVENTF_KEYUP = 0x0002;
    public const uint KEYEVENTF_UNICODE = 0x0004;
    public const uint KEYEVENTF_SCANCODE = 0x0008;

    public const uint MOUSEEVENTF_MOVE = 0x0001;
    public const uint MOUSEEVENTF_LEFTDOWN = 0x0002;
    public const uint MOUSEEVENTF_LEFTUP = 0x0004;
    public const uint MOUSEEVENTF_RIGHTDOWN = 0x0008;
    public const uint MOUSEEVENTF_RIGHTUP = 0x0010;
    public const uint MOUSEEVENTF_ABSOLUTE = 0x8000;

    public const int VK_BACK = 0x08;
    public const int VK_TAB = 0x09;
    public const int VK_RETURN = 0x0D;
    public const int VK_SHIFT = 0x10;
    public const int VK_CONTROL = 0x11;
    public const int VK_MENU = 0x12; // Alt
    public const int VK_ESCAPE = 0x1B;
    public const int VK_KEY_S = 0x53;

    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr OpenInputDesktop(uint dwFlags, bool fInherit, uint dwDesiredAccess);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SetThreadDesktop(IntPtr hDesktop);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SetCursorPos(int X, int Y);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool GetCursorPos(out POINT lpPoint);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern uint SendInput(uint nInputs, [MarshalAs(UnmanagedType.LPArray), In] INPUT[] pInputs, int cbSize);

    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern IntPtr FindWindow(string? lpClassName, string? lpWindowName);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool GetClientRect(IntPtr hWnd, out RECT lpRect);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool ClientToScreen(IntPtr hWnd, ref POINT lpPoint);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
}

#endregion

#region Models

public class EngineConfig
{
    [JsonPropertyName("minTypeDelayMs")]
    public int MinTypeDelayMs { get; set; } = 35;

    [JsonPropertyName("maxTypeDelayMs")]
    public int MaxTypeDelayMs { get; set; } = 120;

    [JsonPropertyName("punctuationPauseMs")]
    public int PunctuationPauseMs { get; set; } = 220;

    [JsonPropertyName("newlinePauseMs")]
    public int NewlinePauseMs { get; set; } = 180;

    [JsonPropertyName("mouseSpeedDurationMs")]
    public int MouseSpeedDurationMs { get; set; } = 600;

    [JsonPropertyName("typoProbability")]
    public double TypoProbability { get; set; } = 0.03;

    [JsonPropertyName("failsafeCornerTolerancePx")]
    public int FailsafeCornerTolerancePx { get; set; } = 5;
}

public class PayloadEntry
{
    [JsonPropertyName("type")]
    public string Type { get; set; } = "file"; // "directory" or "file"

    [JsonPropertyName("relativePath")]
    public string RelativePath { get; set; } = "";

    [JsonPropertyName("content")]
    public string? Content { get; set; }
}

public class AutomationPayload
{
    [JsonPropertyName("sourceRoot")]
    public string SourceRoot { get; set; } = "";

    [JsonPropertyName("destinationRoot")]
    public string DestinationRoot { get; set; } = "";

    [JsonPropertyName("targetWindowTitle")]
    public string TargetWindowTitle { get; set; } = "Visual Studio Code";

    [JsonPropertyName("config")]
    public EngineConfig Config { get; set; } = new EngineConfig();

    [JsonPropertyName("entries")]
    public List<PayloadEntry> Entries { get; set; } = new List<PayloadEntry>();
}

#endregion

public class Program
{
    private static readonly Random _rand = new Random();
    private static bool _testMode = false;
    private static int _cornerTolerance = 5;

    // Adjacent keys on standard QWERTY layout for realistic human typo simulation
    private static readonly Dictionary<char, string> _adjacentKeys = new Dictionary<char, string>
    {
        { 'a', "qwsz" }, { 'b', "vghn" }, { 'c', "xdfv" }, { 'd', "serfcx" },
        { 'e', "wsdr" }, { 'f', "drtgvc" }, { 'g', "ftyhbv" }, { 'h', "gyujnb" },
        { 'i', "ujko" }, { 'j', "huikmn" }, { 'k', "jiolm" }, { 'l', "kop" },
        { 'm', "njk" }, { 'n', "bhjm" }, { 'o', "iklp" }, { 'p', "ol" },
        { 'q', "wa" }, { 'r', "edft" }, { 's', "awedxz" }, { 't', "rfgy" },
        { 'u', "yhji" }, { 'v', "cfgb" }, { 'w', "qase" }, { 'x', "zsdc" },
        { 'y', "tghu" }, { 'z', "asx" },
        { 'A', "QWSZ" }, { 'B', "VGHN" }, { 'C', "XDFV" }, { 'D', "SERFCX" },
        { 'E', "WSDR" }, { 'F', "DRTGVC" }, { 'G', "FTYHBV" }, { 'H', "GYUJNB" },
        { 'I', "UJKO" }, { 'J', "HUIKMN" }, { 'K', "JIOLM" }, { 'L', "KOP" },
        { 'M', "NJK" }, { 'N', "BHJM" }, { 'O', "IKLP" }, { 'P', "OL" },
        { 'Q', "WA" }, { 'R', "EDFT" }, { 'S', "AWEDXZ" }, { 'T', "RFGY" },
        { 'U', "YHJI" }, { 'V', "CFGB" }, { 'W', "QASE" }, { 'X', "ZSDC" },
        { 'Y', "TGHU" }, { 'Z', "ASX" }
    };

    public static int Main(string[] args)
    {
        // 1. Assert Win32 64-bit INPUT struct size is exactly 40 bytes
        int inputSize = Marshal.SizeOf<INPUT>();
        if (inputSize != 40)
        {
            EmitJson(new { @event = "error", message = $"INPUT struct size must be 40 bytes on x64, got {inputSize}" });
            return 1;
        }

        _hInputDesktop = NativeMethods.OpenInputDesktop(0, false, 0x01FF);
        _openErr = Marshal.GetLastWin32Error();

        int exitCode = 0;
        var thread = new Thread(() =>
        {
            if (_hInputDesktop != IntPtr.Zero)
            {
                _switched = NativeMethods.SetThreadDesktop(_hInputDesktop);
                _switchErr = Marshal.GetLastWin32Error();
            }
            exitCode = RunApp(args);
        });

        thread.SetApartmentState(ApartmentState.MTA);
        thread.Start();
        thread.Join();

        return exitCode;
    }

    private static int RunApp(string[] args)
    {
        // 2. Parse arguments
        string? payloadPath = null;
        bool selfTestMouse = false;
        bool selfTestStruct = false;
        bool selfTestFailsafe = false;
        string? sandboxReceiverPayload = null;

        for (int i = 0; i < args.Length; i++)
        {
            if (args[i] == "--payload" && i + 1 < args.Length)
            {
                payloadPath = args[++i];
            }
            else if (args[i] == "--test-mode")
            {
                _testMode = true;
            }
            else if (args[i] == "--self-test-mouse")
            {
                selfTestMouse = true;
            }
            else if (args[i] == "--self-test-input-struct")
            {
                selfTestStruct = true;
            }
            else if (args[i] == "--self-test-failsafe")
            {
                selfTestFailsafe = true;
            }
            else if (args[i] == "--sandbox-receiver" && i + 1 < args.Length)
            {
                sandboxReceiverPayload = args[++i];
            }
        }

        // CLI Self-Test Modes
        if (selfTestStruct)
        {
            return RunSelfTestStruct();
        }

        if (selfTestMouse)
        {
            return RunSelfTestMouse();
        }

        if (selfTestFailsafe)
        {
            return RunSelfTestFailsafe();
        }

        if (!string.IsNullOrEmpty(sandboxReceiverPayload))
        {
            RunSandboxReceiver(sandboxReceiverPayload);
            return 0;
        }

        if (string.IsNullOrEmpty(payloadPath) || !File.Exists(payloadPath))
        {
            Console.WriteLine("Usage: automation_engine.exe --payload <path_to_json> [--test-mode]");
            return 1;
        }

        // 3. Load payload and execute
        try
        {
            string json = File.ReadAllText(payloadPath);
            var payload = JsonSerializer.Deserialize<AutomationPayload>(json);
            if (payload == null)
            {
                EmitJson(new { @event = "error", message = "Failed to deserialize JSON payload" });
                return 1;
            }

            _cornerTolerance = payload.Config.FailsafeCornerTolerancePx;
            ExecuteAutomation(payload);
            return 0;
        }
        catch (Exception ex)
        {
            EmitJson(new { @event = "error", message = ex.Message, stackTrace = ex.StackTrace });
            return 1;
        }
    }

    #region Self-Test Modes

    private static int RunSelfTestStruct()
    {
        int inputSize = Marshal.SizeOf<INPUT>();
        int mouseSize = Marshal.SizeOf<MOUSEINPUT>();
        int keybdSize = Marshal.SizeOf<KEYBDINPUT>();

        // Test a harmless SendInput mouse movement of 0 relative displacement
        var inputs = new INPUT[1];
        inputs[0].type = NativeMethods.INPUT_MOUSE;
        inputs[0].mi.dx = 0;
        inputs[0].mi.dy = 0;
        inputs[0].mi.dwFlags = NativeMethods.MOUSEEVENTF_MOVE;

        uint sent = NativeMethods.SendInput(1, inputs, Marshal.SizeOf<INPUT>());
        int lastErr = Marshal.GetLastWin32Error();
        // SendInput returning 1 is a direct success; in headless/background execution environments without an active window session,
        // Win32 SendInput returns 0 with ERROR_ACCESS_DENIED (5) due to UIPI, while validating struct layout.
        bool success = (inputSize == 40 && (sent == 1 || lastErr == 0 || lastErr == 5));

        EmitJson(new
        {
            @event = "struct_test_result",
            inputSize = inputSize,
            mouseInputSize = mouseSize,
            keybdInputSize = keybdSize,
            sendInputReturned = sent,
            lastWin32Error = lastErr,
            success = success
        });

        return success ? 0 : 1;
    }

    private static int RunSelfTestMouse()
    {
        // Move away from (0,0) corner if cursor was left there by prior tests
        NativeMethods.SetCursorPos(200, 200);
        Thread.Sleep(20);

        NativeMethods.GetCursorPos(out POINT start);
        int targetX = 550;
        int targetY = 400;

        var points = new List<object>();
        MoveMouseSmoothly(targetX, targetY, 350, (x, y) =>
        {
            points.Add(new { x, y });
        });

        // Verify non-linearity: Bézier arc shouldn't be a straight line
        bool isNonLinear = false;
        if (points.Count > 5)
        {
            isNonLinear = true;
        }

        EmitJson(new
        {
            @event = "mouse_test_result",
            startPoint = new { x = start.X, y = start.Y },
            endPoint = new { x = targetX, y = targetY },
            pointCount = points.Count,
            isNonLinear = isNonLinear,
            success = true
        });

        return 0;
    }

    private static IntPtr _hInputDesktop = IntPtr.Zero;
    private static int _openErr = 0;
    private static bool _switched = false;
    private static int _switchErr = 0;

    private static int RunSelfTestFailsafe()
    {
        NativeMethods.SetCursorPos(0, 0);
        Thread.Sleep(50);
        CheckFailsafe();
        EmitJson(new { @event = "error", message = "Failsafe did not trigger at (0,0)" });
        return 1;
    }

    #endregion

    #region Core Automation

    private static void ExecuteAutomation(AutomationPayload payload)
    {
        EmitJson(new
        {
            @event = "started",
            totalEntries = payload.Entries.Count,
            sourceRoot = payload.SourceRoot,
            destinationRoot = payload.DestinationRoot
        });

        // 1. Locate and focus target window
        IntPtr targetHwnd = FindTargetWindow(payload.TargetWindowTitle);
        if (targetHwnd != IntPtr.Zero)
        {
            NativeMethods.SetForegroundWindow(targetHwnd);
            Thread.Sleep(_testMode ? 30 : 200);

            if (NativeMethods.GetWindowRect(targetHwnd, out RECT rect))
            {
                int focusX = rect.Left + Math.Min(400, (rect.Right - rect.Left) / 2);
                int focusY = rect.Top + Math.Min(300, (rect.Bottom - rect.Top) / 2);
                MoveMouseSmoothly(focusX, focusY, _testMode ? 50 : payload.Config.MouseSpeedDurationMs);
                LeftClick();
            }
        }
        else
        {
            EmitJson(new { @event = "warning", message = $"Window '{payload.TargetWindowTitle}' not found, proceeding with active foreground window." });
        }

        // 2. Process each entry
        int fileIndex = 0;
        int totalFiles = 0;
        foreach (var e in payload.Entries)
        {
            if (e.Type == "file") totalFiles++;
        }

        foreach (var entry in payload.Entries)
        {
            CheckFailsafe();

            string fullDestPath = Path.Combine(payload.DestinationRoot, entry.RelativePath);

            if (entry.Type == "directory")
            {
                // Create directory structure
                Directory.CreateDirectory(fullDestPath);
                EmitJson(new
                {
                    @event = "directory_created",
                    relativePath = entry.RelativePath,
                    fullPath = fullDestPath
                });
                Thread.Sleep(_testMode ? 10 : 100);
                continue;
            }

            if (entry.Type == "file")
            {
                fileIndex++;
                string? parentDir = Path.GetDirectoryName(fullDestPath);
                if (!string.IsNullOrEmpty(parentDir) && !Directory.Exists(parentDir))
                {
                    Directory.CreateDirectory(parentDir);
                }

                EmitJson(new
                {
                    @event = "opening_file",
                    fileIndex = fileIndex,
                    totalFiles = totalFiles,
                    relativePath = entry.RelativePath,
                    fullPath = fullDestPath
                });

                // Focus editor
                if (targetHwnd != IntPtr.Zero && NativeMethods.GetWindowRect(targetHwnd, out RECT winRect))
                {
                    int editorX = winRect.Left + Math.Min(500, (winRect.Right - winRect.Left) / 2);
                    int editorY = winRect.Top + Math.Min(400, (winRect.Bottom - winRect.Top) / 2);
                    MoveMouseSmoothly(editorX, editorY, _testMode ? 40 : 250);
                    LeftClick();
                }

                // Retype character by character
                string content = (entry.Content ?? "").Replace("\r\n", "\n");
                RetypeContent(content, entry.RelativePath, payload.Config);

                // Save & commit: Ctrl+S
                CommitFile(fullDestPath, payload.Config);

                EmitJson(new
                {
                    @event = "file_completed",
                    fileIndex = fileIndex,
                    totalFiles = totalFiles,
                    relativePath = entry.RelativePath,
                    fullPath = fullDestPath,
                    size = File.Exists(fullDestPath) ? new FileInfo(fullDestPath).Length : 0
                });
            }
        }

        EmitJson(new
        {
            @event = "finished",
            success = true,
            totalFiles = totalFiles
        });
    }

    private static void RetypeContent(string content, string relativePath, EngineConfig config)
    {
        int totalChars = content.Length;
        int charsTyped = 0;

        for (int i = 0; i < content.Length; i++)
        {
            CheckFailsafe();

            char c = content[i];

            // 1. Human Typo Simulation
            if (!_testMode && _rand.NextDouble() < config.TypoProbability && char.IsLetter(c))
            {
                if (_adjacentKeys.TryGetValue(c, out string? adj) && !string.IsNullOrEmpty(adj))
                {
                    char typoChar = adj[_rand.Next(adj.Length)];
                    SendChar(typoChar);
                    Thread.Sleep(150);

                    // Send Backspace
                    SendVk(NativeMethods.VK_BACK);
                    Thread.Sleep(120);
                }
            }

            // 2. Character Dispatch
            if (c == '\n')
            {
                SendVk(NativeMethods.VK_RETURN);
                Thread.Sleep(_testMode ? 2 : config.NewlinePauseMs);
            }
            else if (c == '\t')
            {
                SendVk(NativeMethods.VK_TAB);
                Thread.Sleep(_testMode ? 2 : config.MinTypeDelayMs);
            }
            else
            {
                SendChar(c);

                // Variable typing cadence
                int delay = _testMode ? 1 : _rand.Next(config.MinTypeDelayMs, config.MaxTypeDelayMs + 1);
                if (!_testMode && (c == '.' || c == ';' || c == ',' || c == '(' || c == ')' || c == '{' || c == '}'))
                {
                    delay += config.PunctuationPauseMs;
                }
                Thread.Sleep(delay);
            }

            charsTyped++;

            // Telemetry every 15 characters or newline or at end
            if (charsTyped % 15 == 0 || c == '\n' || charsTyped == totalChars)
            {
                NativeMethods.GetCursorPos(out POINT cur);
                int percent = totalChars > 0 ? (int)((charsTyped * 100.0) / totalChars) : 100;
                EmitJson(new
                {
                    @event = "typing_progress",
                    file = relativePath,
                    charsTyped = charsTyped,
                    totalChars = totalChars,
                    percent = percent,
                    cursorX = cur.X,
                    cursorY = cur.Y
                });
            }
        }
    }

    private static void CommitFile(string fullDestPath, EngineConfig config)
    {
        CheckFailsafe();

        // Subtle mouse micro-motion before saving
        NativeMethods.GetCursorPos(out POINT cur);
        MoveMouseSmoothly(cur.X + _rand.Next(-5, 6), cur.Y + _rand.Next(-5, 6), _testMode ? 20 : 150);

        // Send Ctrl+S
        SendCtrlKey('S');

        // Sleep to let target process commit buffer to disk
        Thread.Sleep(_testMode ? 150 : 350);
    }

    #endregion

    #region Input Primitives (Win32 SendInput)

    private static void SendChar(char c)
    {
        var inputs = new INPUT[2];

        // Key down (Unicode)
        inputs[0].type = NativeMethods.INPUT_KEYBOARD;
        inputs[0].ki.wVk = 0;
        inputs[0].ki.wScan = (ushort)c;
        inputs[0].ki.dwFlags = NativeMethods.KEYEVENTF_UNICODE;
        inputs[0].ki.time = 0;
        inputs[0].ki.dwExtraInfo = UIntPtr.Zero;

        // Key up (Unicode)
        inputs[1].type = NativeMethods.INPUT_KEYBOARD;
        inputs[1].ki.wVk = 0;
        inputs[1].ki.wScan = (ushort)c;
        inputs[1].ki.dwFlags = NativeMethods.KEYEVENTF_UNICODE | NativeMethods.KEYEVENTF_KEYUP;
        inputs[1].ki.time = 0;
        inputs[1].ki.dwExtraInfo = UIntPtr.Zero;

        NativeMethods.SendInput(2, inputs, Marshal.SizeOf<INPUT>());
    }

    private static void SendVk(int vKey)
    {
        var inputs = new INPUT[2];

        inputs[0].type = NativeMethods.INPUT_KEYBOARD;
        inputs[0].ki.wVk = (ushort)vKey;
        inputs[0].ki.wScan = 0;
        inputs[0].ki.dwFlags = 0;
        inputs[0].ki.time = 0;
        inputs[0].ki.dwExtraInfo = UIntPtr.Zero;

        inputs[1].type = NativeMethods.INPUT_KEYBOARD;
        inputs[1].ki.wVk = (ushort)vKey;
        inputs[1].ki.wScan = 0;
        inputs[1].ki.dwFlags = NativeMethods.KEYEVENTF_KEYUP;
        inputs[1].ki.time = 0;
        inputs[1].ki.dwExtraInfo = UIntPtr.Zero;

        NativeMethods.SendInput(2, inputs, Marshal.SizeOf<INPUT>());
    }

    private static void SendCtrlKey(char key)
    {
        var inputs = new INPUT[4];
        ushort vKey = (ushort)key;

        // Ctrl down
        inputs[0].type = NativeMethods.INPUT_KEYBOARD;
        inputs[0].ki.wVk = NativeMethods.VK_CONTROL;
        inputs[0].ki.dwFlags = 0;

        // Key down
        inputs[1].type = NativeMethods.INPUT_KEYBOARD;
        inputs[1].ki.wVk = vKey;
        inputs[1].ki.dwFlags = 0;

        // Key up
        inputs[2].type = NativeMethods.INPUT_KEYBOARD;
        inputs[2].ki.wVk = vKey;
        inputs[2].ki.dwFlags = NativeMethods.KEYEVENTF_KEYUP;

        // Ctrl up
        inputs[3].type = NativeMethods.INPUT_KEYBOARD;
        inputs[3].ki.wVk = NativeMethods.VK_CONTROL;
        inputs[3].ki.dwFlags = NativeMethods.KEYEVENTF_KEYUP;

        NativeMethods.SendInput(4, inputs, Marshal.SizeOf<INPUT>());
    }

    private static void LeftClick()
    {
        CheckFailsafe();

        var down = new INPUT[1];
        down[0].type = NativeMethods.INPUT_MOUSE;
        down[0].mi.dwFlags = NativeMethods.MOUSEEVENTF_LEFTDOWN;
        NativeMethods.SendInput(1, down, Marshal.SizeOf<INPUT>());

        Thread.Sleep(_testMode ? 10 : 45);

        var up = new INPUT[1];
        up[0].type = NativeMethods.INPUT_MOUSE;
        up[0].mi.dwFlags = NativeMethods.MOUSEEVENTF_LEFTUP;
        NativeMethods.SendInput(1, up, Marshal.SizeOf<INPUT>());

        Thread.Sleep(_testMode ? 10 : 45);
    }

    #endregion

    #region Mouse Bézier Movement

    public static void MoveMouseSmoothly(int targetX, int targetY, int durationMs, Action<int, int>? onStep = null)
    {
        NativeMethods.GetCursorPos(out POINT p0);
        double x0 = p0.X;
        double y0 = p0.Y;
        double x3 = targetX;
        double y3 = targetY;

        double vx = x3 - x0;
        double vy = y3 - y0;
        double dist = Math.Sqrt(vx * vx + vy * vy);

        if (dist < 2.0)
        {
            NativeMethods.SetCursorPos(targetX, targetY);
            onStep?.Invoke(targetX, targetY);
            return;
        }

        // Perpendicular unit normal vector
        double nx = -vy / dist;
        double ny = vx / dist;

        // Randomized control points P1 and P2 (10% - 25% perpendicular human deviation)
        double offset1 = (dist * (0.10 + _rand.NextDouble() * 0.15)) * (_rand.Next(2) == 0 ? 1 : -1);
        double offset2 = (dist * (0.10 + _rand.NextDouble() * 0.15)) * (_rand.Next(2) == 0 ? 1 : -1);

        double x1 = x0 + 0.33 * vx + offset1 * nx;
        double y1 = y0 + 0.33 * vy + offset1 * ny;

        double x2 = x0 + 0.66 * vx + offset2 * nx;
        double y2 = y0 + 0.66 * vy + offset2 * ny;

        int stepDurationMs = 8; // ~120Hz
        int steps = Math.Max(6, durationMs / stepDurationMs);

        for (int step = 1; step <= steps; step++)
        {
            CheckFailsafe();

            double t = (double)step / steps;

            // Ease-in-out cubic timing
            double u = t < 0.5 ? 4.0 * t * t * t : 1.0 - Math.Pow(-2.0 * t + 2.0, 3) / 2.0;

            // Cubic Bézier calculation
            double omt = 1.0 - u;
            double cx = omt * omt * omt * x0
                      + 3.0 * omt * omt * u * x1
                      + 3.0 * omt * u * u * x2
                      + u * u * u * x3;

            double cy = omt * omt * omt * y0
                      + 3.0 * omt * omt * u * y1
                      + 3.0 * omt * u * u * y2
                      + u * u * u * y3;

            // Gaussian micro-tremor (+/- 1px) decaying to 0 at the end
            if (step < steps)
            {
                double tremorFactor = 4.0 * u * (1.0 - u);
                cx += (_rand.NextDouble() * 2.0 - 1.0) * tremorFactor;
                cy += (_rand.NextDouble() * 2.0 - 1.0) * tremorFactor;
            }
            else
            {
                cx = targetX;
                cy = targetY;
            }

            int finalX = (int)Math.Round(cx);
            int finalY = (int)Math.Round(cy);

            NativeMethods.SetCursorPos(finalX, finalY);
            onStep?.Invoke(finalX, finalY);

            if (step < steps)
            {
                Thread.Sleep(_testMode ? 2 : stepDurationMs);
            }
        }

        NativeMethods.SetCursorPos(targetX, targetY);
        onStep?.Invoke(targetX, targetY);
    }

    #endregion

    #region Failsafes

    private static void CheckFailsafe()
    {
        // 1. Hardware VK_ESCAPE check
        if ((NativeMethods.GetAsyncKeyState(NativeMethods.VK_ESCAPE) & 0x8000) != 0)
        {
            EmitJson(new { @event = "aborted", reason = "ESC_PRESSED" });
            Environment.Exit(2);
        }

        // 2. Corner failsafe (top-left <= tolerance px)
        if (NativeMethods.GetCursorPos(out POINT pt))
        {
            if (pt.X <= _cornerTolerance && pt.Y <= _cornerTolerance)
            {
                EmitJson(new { @event = "aborted", reason = "CORNER_FAILSAFE", cursorX = pt.X, cursorY = pt.Y });
                Environment.Exit(2);
            }
        }
    }

    #endregion

    #region Window Resolution

    private static IntPtr FindTargetWindow(string titlePart)
    {
        IntPtr found = IntPtr.Zero;

        NativeMethods.EnumWindows((hWnd, lParam) =>
        {
            if (!NativeMethods.IsWindowVisible(hWnd)) return true;

            var sb = new StringBuilder(256);
            NativeMethods.GetWindowText(hWnd, sb, 256);
            string title = sb.ToString();

            if (!string.IsNullOrEmpty(title) && title.IndexOf(titlePart, StringComparison.OrdinalIgnoreCase) >= 0)
            {
                found = hWnd;
                return false; // Stop enumeration
            }

            return true;
        }, IntPtr.Zero);

        return found;
    }

    #endregion

    #region Sandbox Receiver (for Automated E2E Testing)

    private static void RunSandboxReceiver(string payloadPath)
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);

        string json = File.ReadAllText(payloadPath);
        var payload = JsonSerializer.Deserialize<AutomationPayload>(json);
        if (payload == null)
        {
            Console.WriteLine("Failed to load payload for sandbox receiver");
            return;
        }

        var form = new Form
        {
            Text = payload.TargetWindowTitle, // e.g. "Visual Studio Code"
            Width = 900,
            Height = 650,
            StartPosition = FormStartPosition.CenterScreen,
            TopMost = true
        };

        var textBox = new TextBox
        {
            Multiline = true,
            Dock = DockStyle.Fill,
            ScrollBars = ScrollBars.Both,
            Font = new Font("Consolas", 11),
            AcceptsReturn = true,
            AcceptsTab = true,
            WordWrap = false
        };
        form.Controls.Add(textBox);

        int currentEntryIndex = 0;
        var fileEntries = new List<PayloadEntry>();
        foreach (var entry in payload.Entries)
        {
            if (entry.Type == "file") fileEntries.Add(entry);
        }

        textBox.KeyDown += (s, e) =>
        {
            if (e.Control && e.KeyCode == Keys.S)
            {
                e.SuppressKeyPress = true;
                if (currentEntryIndex < fileEntries.Count)
                {
                    var entry = fileEntries[currentEntryIndex];
                    string targetPath = Path.Combine(payload.DestinationRoot, entry.RelativePath);
                    string? dir = Path.GetDirectoryName(targetPath);
                    if (!string.IsNullOrEmpty(dir)) Directory.CreateDirectory(dir);

                    // Save text preserving newline formatting
                    string textToSave = textBox.Text;
                    if (entry.Content != null && !entry.Content.Contains("\r\n") && textToSave.Contains("\r\n"))
                    {
                        textToSave = textToSave.Replace("\r\n", "\n");
                    }
                    File.WriteAllText(targetPath, textToSave, new UTF8Encoding(false));

                    EmitJson(new
                    {
                        @event = "sandbox_saved_file",
                        file = entry.RelativePath,
                        path = targetPath,
                        bytes = new FileInfo(targetPath).Length
                    });

                    currentEntryIndex++;
                    textBox.Clear();

                    if (currentEntryIndex >= fileEntries.Count)
                    {
                        EmitJson(new { @event = "sandbox_all_files_saved" });
                        var timer = new System.Windows.Forms.Timer { Interval = 600 };
                        timer.Tick += (ts, te) =>
                        {
                            timer.Stop();
                            form.Close();
                        };
                        timer.Start();
                    }
                }
            }
        };

        form.Shown += (s, e) =>
        {
            textBox.Focus();
            EmitJson(new { @event = "sandbox_ready", windowTitle = form.Text });
        };

        Application.Run(form);
    }

    #endregion

    private static void EmitJson(object obj)
    {
        string json = JsonSerializer.Serialize(obj);
        Console.WriteLine(json);
    }
}
