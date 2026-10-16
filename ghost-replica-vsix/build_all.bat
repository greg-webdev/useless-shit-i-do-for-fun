@echo off
setlocal enabledelayedexpansion

echo ===============================================================================
echo GHOSTREPLICA: MASTER BUILD, VERIFICATION, AND PACKAGING PIPELINE
echo Target: Windows 10/11 x64 (win32-x64)
echo ===============================================================================

set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

echo [1/5] Verifying toolchain environment...
where node >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Node.js is not installed or not in PATH.
    exit /b 1
)

where npm >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] npm is not installed or not in PATH.
    exit /b 1
)

where dotnet >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] .NET SDK is not installed or not in PATH.
    exit /b 1
)

echo   - Node.js, npm, and .NET SDK confirmed.

echo [2/5] Installing dependencies and compiling TypeScript extension...
if not exist "node_modules\" (
    echo   - Running npm install...
    call npm install --silent
    if %ERRORLEVEL% neq 0 (
        echo [ERROR] npm install failed.
        exit /b 1
    )
)

call npm run compile
if %ERRORLEVEL% neq 0 (
    echo [ERROR] TypeScript compilation failed.
    exit /b 1
)
echo   - TypeScript compilation successful (dist/ created).

echo [3/5] Compiling native Windows automation engine (automation_engine.exe)...
dotnet publish engine_src/automation_engine.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -o bin
if %ERRORLEVEL% neq 0 (
    echo [ERROR] .NET native single-file compilation failed.
    exit /b 1
)
if not exist "bin\automation_engine.exe" (
    echo [ERROR] Expected binary bin\automation_engine.exe not found!
    exit /b 1
)
echo   - Native Windows executable compiled: bin\automation_engine.exe

echo [4/5] Executing 5-Phase End-to-End Verification Suite...
node test/e2e_verify.js
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Verification suite failed!
    exit /b 1
)

echo [5/5] Finalizing VSIX package...
if exist "ghost-replica-1.0.0.vsix" (
    del /f /q "ghost-replica-1.0.0.vsix"
)
call npx @vscode/vsce package --no-dependencies -o ghost-replica.vsix
if %ERRORLEVEL% neq 0 (
    echo [ERROR] vsce packaging failed.
    exit /b 1
)

echo ===============================================================================
echo BUILD AND VERIFICATION PIPELINE COMPLETED SUCCESSFULLY!
echo Final Package: %SCRIPT_DIR%ghost-replica.vsix
echo ===============================================================================

exit /b 0
