@echo off
setlocal EnableDelayedExpansion

set GIT="D:\ProgramPortable\PortableGit\cmd\git.exe"
set WORK_DIR=%~dp0
set CURL=curl.exe
set GH_USER=imlgmcom
set GH_REPO=AIWORKS-FlashTime

title Git Toolbox - FlashTime

:menu
cls
echo.
echo  ====================================================
echo            Git Toolbox - FlashTime
echo  ====================================================
echo.
echo   [1] Show status          (git status)
echo   [2] Show diff            (git diff)
echo   [3] Show log             (git log)
echo   [4] Commit and push      (add + commit + push)
echo   [5] Pull updates         (git pull)
echo   [6] Show ignored files   (check gitignore)
echo   [7] Undo last commit     (reset soft)
echo   [8] Create branch        (git branch)
echo   [9] Switch branch        (git checkout)
echo   [R] Build and release to GitHub Releases
echo   [0] Exit
echo.
echo  ====================================================
echo.
set /p choice="Please select [0-9/R]: "

if "%choice%"=="1" goto status
if "%choice%"=="2" goto diff
if "%choice%"=="3" goto log
if "%choice%"=="4" goto push
if "%choice%"=="5" goto pull
if "%choice%"=="6" goto ignored
if "%choice%"=="7" goto undo
if "%choice%"=="8" goto branch
if "%choice%"=="9" goto checkout
if /i "%choice%"=="R" goto release
if "%choice%"=="0" exit
echo Invalid option
timeout /t 2 >nul
goto menu

:status
cls
echo.
echo  --- Current status ---
echo.
cd /d "%WORK_DIR%"
%GIT% status
echo.
pause
goto menu

:diff
cls
echo.
echo  --- Unstaged changes ---
echo.
cd /d "%WORK_DIR%"
%GIT% diff
echo.
echo  --- Staged changes ---
echo.
%GIT% diff --cached
echo.
pause
goto menu

:log
cls
echo.
echo  --- Last 20 commits ---
echo.
cd /d "%WORK_DIR%"
%GIT% log --oneline --graph -20
echo.
pause
goto menu

:push
cls
echo.
echo  --- Commit and push ---
echo.
cd /d "%WORK_DIR%"

echo Files to commit:
%GIT% status --short
echo.

set /p msg="Commit message (Enter for default): "
if "%msg%"=="" set msg=update %date% %time%

%GIT% add .
%GIT% commit -m "%msg%"
%GIT% push
echo.
echo  --- Done ---
echo.
pause
goto menu

:pull
cls
echo.
echo  --- Pull remote updates ---
echo.
cd /d "%WORK_DIR%"
%GIT% pull
echo.
pause
goto menu

:ignored
cls
echo.
echo  --- Files ignored by .gitignore (first 30) ---
echo.
cd /d "%WORK_DIR%"
%GIT% ls-files --others --ignored --exclude-standard
echo.
pause
goto menu

:undo
cls
echo.
echo  --- Undo last commit (keep changes staged) ---
echo.
echo Last commit:
cd /d "%WORK_DIR%"
%GIT% log --oneline -1
echo.
set /p confirm="Undo? (y/N): "
if /i "%confirm%"=="y" (
    %GIT% reset --soft HEAD~1
    echo Undone, changes are kept in the staging area
) else (
    echo Canceled
)
echo.
pause
goto menu

:branch
cls
echo.
echo  --- Branch management ---
echo.
echo Current branch:
cd /d "%WORK_DIR%"
%GIT% branch --show-current
echo.
echo All branches:
%GIT% branch
echo.
set /p newbranch="New branch name (Enter to return): "
if "%newbranch%"=="" goto menu
%GIT% checkout -b "%newbranch%"
echo Created and switched to: %newbranch%
echo.
pause
goto menu

:checkout
cls
echo.
echo  --- Switch branch ---
echo.
echo Current branch:
cd /d "%WORK_DIR%"
%GIT% branch --show-current
echo.
echo All branches:
%GIT% branch
echo.
set /p target="Branch name (Enter to return): "
if "%target%"=="" goto menu
%GIT% checkout "%target%"
echo.
pause
goto menu

:release
cls
echo.
echo  ====================================================
echo     Build and publish to GitHub Releases
echo  ====================================================
echo.

cd /d "%WORK_DIR%"

REM --- Get token from Git Credential Manager ---
set GHTOKEN=
echo protocol=https> "%TEMP%\gcm_input.txt"
echo host=github.com>> "%TEMP%\gcm_input.txt"
echo.>> "%TEMP%\gcm_input.txt"
for /f "tokens=1,* delims==" %%a in ('type "%TEMP%\gcm_input.txt" ^| %GIT% credential fill') do (
    if "%%a"=="password" set "GHTOKEN=%%b"
)
del /f "%TEMP%\gcm_input.txt" 2>nul

if "%GHTOKEN%"=="" (
    echo  [FAILED] Could not get credentials from Git Credential Manager
    echo  Please run "git push" once first to cache credentials
    pause
    goto menu
)
echo  [OK] Got credentials from Git Credential Manager

REM --- Read version number ---
for /f "tokens=2 delims=:, " %%a in ('findstr /c:"\"version\"" "package.json"') do (
    set "VER=%%~a"
)
echo.
echo  Current version: %VER%
echo.
set /p newver="New version (Enter to use %VER%): "
if not "%newver%"=="" set VER=%newver%

REM --- Find latest portable zip ---
set "ZIP_PATH="
for /f "delims=" %%f in ('dir /b /a-d /o-d flashtime-portable-*.zip 2^>nul') do (
    if not defined ZIP_PATH set "ZIP_PATH=%WORK_DIR%%%f"
)
if not defined ZIP_PATH for /f "delims=" %%f in ('dir /b /a-d /o-d *.zip 2^>nul') do (
    if not defined ZIP_PATH set "ZIP_PATH=%WORK_DIR%%%f"
)
if "%ZIP_PATH%"=="" (
    echo  [FAILED] No flashtime-portable-*.zip found, run build-portable.bat first
    pause
    goto menu
)
for %%F in ("%ZIP_PATH%") do set "ZIP_NAME=%%~nxF"

echo.
echo  Will release: %ZIP_PATH%
echo.
set /p go="Start? (y/N): "
if /i not "%go%"=="y" (
    echo Canceled
    pause
    goto menu
)

REM --- Create Release ---
echo.
echo  [1/2] Creating GitHub Release v%VER%...

set "API_URL=https://api.github.com/repos/%GH_USER%/%GH_REPO%/releases"
set "TAG=v%VER%"

%curl% -s -o "%TEMP%\release_resp.json" -w "%%{http_code}" ^
  -X POST "%API_URL%" ^
  -H "Authorization: token %GHTOKEN%" ^
  -H "Accept: application/vnd.github.v3+json" ^
  -d "{\"tag_name\":\"%TAG%\",\"name\":\"FlashTime %VER%\",\"body\":\"FlashTime %VER% Portable\",\"draft\":false,\"prerelease\":false}" > "%TEMP%\release_http_code.txt"

set /p HTTP_CODE=<"%TEMP%\release_http_code.txt"

if "%HTTP_CODE%"=="201" (
    echo  [OK] Release created successfully
) else (
    echo  [WARN] HTTP %HTTP_CODE% - Release may already exist
)

REM --- Get upload_url ---
for /f "tokens=*" %%u in ('powershell -NoProfile -Command "(Get-Content '%TEMP%\release_resp.json' | ConvertFrom-Json).upload_url"') do set "UPLOAD_URL=%%u"

if "%UPLOAD_URL%"=="" (
    echo  [FAILED] Could not get upload URL
    echo  Hint: Check if the release already exists on GitHub
    set GHTOKEN=
    pause
    goto menu
)

REM Strip the {?name,label} template part
for /f "tokens=1 delims={?" %%p in ("%UPLOAD_URL%") do set "UPLOAD_URL=%%p"

echo  [OK] Got upload URL

REM --- Upload zip ---
echo.
echo  [2/2] Uploading %ZIP_NAME% ...

%curl% -s -o "%TEMP%\upload_resp.json" -w "%%{http_code}" ^
  -X POST "%UPLOAD_URL%?name=%ZIP_NAME%" ^
  -H "Authorization: token %GHTOKEN%" ^
  -H "Content-Type: application/zip" ^
  --data-binary "@%ZIP_PATH%" > "%TEMP%\upload_code.txt"

set /p UPLOAD_CODE=<"%TEMP%\upload_code.txt"

if "%UPLOAD_CODE%"=="201" (
    echo  [OK] Upload successful!
) else (
    echo  [WARN] HTTP %UPLOAD_CODE% - Check the upload result
)

REM Clear token from memory
set GHTOKEN=

echo.
echo  ====================================================
echo   Done!
echo   https://github.com/%GH_USER%/%GH_REPO%/releases/tag/%TAG%
echo  ====================================================
echo.

REM Clean up temp files
del /f "%TEMP%\release_resp.json" 2>nul
del /f "%TEMP%\release_http_code.txt" 2>nul
del /f "%TEMP%\upload_resp.json" 2>nul
del /f "%TEMP%\upload_code.txt" 2>nul

pause
goto menu