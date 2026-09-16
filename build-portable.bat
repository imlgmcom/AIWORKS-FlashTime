@echo off
chcp 65001 >nul
setlocal

REM ============================================================
REM  FlashTime Portable Build Script
REM  Usage: Double-click build-portable.bat
REM  Output: portable zip in project root
REM ============================================================

set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"
set "EXE=%ROOT%\src-tauri\target\release\flashtime-tauri.exe"
cd /d "%ROOT%"

echo ============================================================
echo   FlashTime Build Script
echo ============================================================
echo.

REM ---- [1/6] Check Rust toolchain ----
echo [1/6] Checking Rust...
where rustc >nul 2>&1
if %errorlevel% neq 0 (
    echo   [MISSING] rustc not found
    echo   Please install Rust: https://rustup.rs
    echo.
    pause
    exit /b 1
)
where cargo >nul 2>&1
if %errorlevel% neq 0 (
    echo   [MISSING] cargo not found
    echo   Please install Rust: https://rustup.rs
    echo.
    pause
    exit /b 1
)
for /f "tokens=*" %%v in ('rustc --version') do echo   %%v
for /f "tokens=*" %%v in ('cargo --version') do echo   %%v
echo.

REM ---- [2/6] Check Node.js ----
echo [2/6] Checking Node.js...
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo   [MISSING] node not found
    echo   Please install Node.js: https://nodejs.org
    echo.
    pause
    exit /b 1
)
where npm >nul 2>&1
if %errorlevel% neq 0 (
    echo   [MISSING] npm not found
    echo   Please install Node.js: https://nodejs.org
    echo.
    pause
    exit /b 1
)
for /f "tokens=*" %%v in ('node --version') do echo   node %%v
for /f "tokens=*" %%v in ('npm --version') do echo   npm  %%v
echo.

REM ---- [3/6] Check node_modules ----
echo [3/6] Checking node_modules...
if not exist "%ROOT%\node_modules" (
    echo   node_modules not found, running npm install...
    call npm install
    if %errorlevel% neq 0 (
        echo   [ERROR] npm install failed!
        pause
        exit /b 1
    )
    echo   npm install done.
) else (
    echo   node_modules exists, skip.
)
echo.

REM ---- [4/6] Build Release ----
echo [4/6] Building Release...
set "CI=false"
call npx @tauri-apps/cli build --no-bundle
if %errorlevel% neq 0 (
    echo   [ERROR] Build failed!
    pause
    exit /b 1
)
echo.

REM ---- [5/6] Check exe ----
echo [5/6] Checking exe...
if not exist "%EXE%" (
    echo   [ERROR] exe not found: %EXE%
    pause
    exit /b 1
)
echo   OK: %EXE%
echo.

REM ---- [6/6] Package ----
echo [6/6] Packaging...
pwsh -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\build-portable.ps1" "%ROOT%" "%EXE%"
if %errorlevel% neq 0 (
    echo   [ERROR] Package failed!
    pause
    exit /b 1
)

echo.
echo ============================================================
echo   Done! See portable zip in project root.
echo ============================================================

pause
