@echo off
chcp 65001 >nul
setlocal

set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"

echo ============================================
echo   FlashTime Backup Script
echo ============================================
echo.

pwsh -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\bakup.ps1" "%ROOT%"

echo.
pause
