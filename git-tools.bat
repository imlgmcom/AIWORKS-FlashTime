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
echo   [1] 查看状态          (git status)
echo   [2] 查看改动          (git diff)
echo   [3] 查看日志          (git log)
echo   [4] 提交并推送        (add + commit + push)
echo   [5] 拉取更新          (git pull)
echo   [6] 查看忽略文件      (gitignore)
echo   [7] 撤销上次提交      (reset soft)
echo   [8] 新建分支          (git branch)
echo   [9] 切换分支          (git checkout)
echo   [R] 发布 GitHub Release
echo   [0] 退出
echo.
echo  ====================================================
echo.
set /p choice="请选择 [0-9/R]: "

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
echo 无效选项
timeout /t 2 >nul
goto menu

:status
cls
echo.
echo  --- 当前状态 ---
echo.
cd /d "%WORK_DIR%"
%GIT% status
echo.
pause
goto menu

:diff
cls
echo.
echo  --- 未暂存改动 ---
echo.
cd /d "%WORK_DIR%"
%GIT% diff
echo.
echo  --- 已暂存改动 ---
echo.
%GIT% diff --cached
echo.
pause
goto menu

:log
cls
echo.
echo  --- 最近 20 条提交 ---
echo.
cd /d "%WORK_DIR%"
%GIT% log --oneline --graph -20
echo.
pause
goto menu

:push
cls
echo.
echo  --- 提交并推送 ---
echo.
cd /d "%WORK_DIR%"

echo 待提交文件:
%GIT% status --short
echo.

set /p msg="提交说明 (回车使用默认): "
if "%msg%"=="" set msg=update %date% %time%

%GIT% add .
%GIT% commit -m "%msg%"
%GIT% push
echo.
echo  --- 完成 ---
echo.
pause
goto menu

:pull
cls
echo.
echo  --- 拉取远程更新 ---
echo.
cd /d "%WORK_DIR%"
%GIT% pull
echo.
pause
goto menu

:ignored
cls
echo.
echo  --- 被 .gitignore 忽略的文件 (前 30 条) ---
echo.
cd /d "%WORK_DIR%"
%GIT% ls-files --others --ignored --exclude-standard
echo.
pause
goto menu

:undo
cls
echo.
echo  --- 撤销上次提交 (保留改动到暂存区) ---
echo.
echo 上次提交:
cd /d "%WORK_DIR%"
%GIT% log --oneline -1
echo.
set /p confirm="确认撤销? (y/N): "
if /i "%confirm%"=="y" (
    %GIT% reset --soft HEAD~1
    echo 已撤销，改动保留在暂存区
) else (
    echo 已取消
)
echo.
pause
goto menu

:branch
cls
echo.
echo  --- 分支管理 ---
echo.
echo 当前分支:
cd /d "%WORK_DIR%"
%GIT% branch --show-current
echo.
echo 所有分支:
%GIT% branch
echo.
set /p newbranch="新分支名 (回车返回): "
if "%newbranch%"=="" goto menu
%GIT% checkout -b "%newbranch%"
echo 已创建并切换到: %newbranch%
echo.
pause
goto menu

:checkout
cls
echo.
echo  --- 切换分支 ---
echo.
echo 当前分支:
cd /d "%WORK_DIR%"
%GIT% branch --show-current
echo.
echo 所有分支:
%GIT% branch
echo.
set /p target="分支名 (回车返回菜单): "
if "%target%"=="" goto menu
%GIT% checkout "%target%"
echo.
pause
goto menu

:release
cls
echo.
echo  ====================================================
echo      发布到 GitHub Releases
echo  ====================================================
echo.

cd /d "%WORK_DIR%"

REM --- 从 Git Credential Manager 获取 token ---
set GH_TOKEN=
echo protocol=https> "%TEMP%\gcm_input.txt"
echo host=github.com>> "%TEMP%\gcm_input.txt"
echo.>> "%TEMP%\gcm_input.txt"
for /f "tokens=1,* delims==" %%a in ('type "%TEMP%\gcm_input.txt" ^| %GIT% credential fill') do (
    if "%%a"=="password" set "GH_TOKEN=%%b"
)
del /f "%TEMP%\gcm_input.txt" 2>nul

if "%GH_TOKEN%"=="" (
    echo  [失败] 无法从 Git Credential Manager 获取凭据
    echo  请先执行一次 "git push" 缓存凭据
    pause
    goto menu
)
echo  [OK] 已获取凭据

REM --- 读取版本号
for /f "tokens=2 delims=:, " %%a in ('findstr /c:"\"version\"" "package.json"') do (
    set "VER=%%~a"
)
echo.
echo  当前版本: %VER%
echo.
set /p newver="新版本号 (回车使用 %VER%): "
if not "%newver%"=="" set VER=%newver%

REM --- 自动查找最新便携包
set "ZIP_PATH="
for /f "delims=" %%f in ('dir /b /a-d /o-d flashtime-portable-*.zip 2^>nul') do (
    if not defined ZIP_PATH set "ZIP_PATH=%WORK_DIR%%%f"
)
if not defined ZIP_PATH for /f "delims=" %%f in ('dir /b /a-d /o-d *.zip 2^>nul') do (
    if not defined ZIP_PATH set "ZIP_PATH=%WORK_DIR%%%f"
)
if "%ZIP_PATH%"=="" (
    echo  [失败] 未找到 flashtime-portable-*.zip，请先运行 build-portable.bat
    pause
    goto menu
)

echo.
echo 将发布: %ZIP_PATH%
echo.
set /p go="开始? (y/N): "
if /i not "%go%"=="y" (
    echo 已取消
    pause
    goto menu
)

REM --- 创建 Release
echo.
echo  [1/2] 创建 GitHub Release v%VER%...

set "API_URL=https://api.github.com/repos/%GH_USER%/%GH_REPO%/releases"
set "TAG=v%VER%"
for %%F in ("%ZIP_PATH%") do set "ZIP_NAME=%%~nxF"

%curl% -s -o "%TEMP%\release_resp.json" -w "%%{http_code}" ^
  -X POST "%API_URL%" ^
  -H "Authorization: token %GH_TOKEN%" ^
  -H "Accept: application/vnd.github.v3+json" ^
  -d "{\"tag_name\":\"%TAG%\",\"name\":\"FlashTime %VER%\",\"body\":\"FlashTime %VER% Portable\",\"draft\":false,\"prerelease\":false}" > "%TEMP%\release_http_code.txt"

set /p HTTP_CODE=<"%TEMP%\release_http_code.txt"

if "%HTTP_CODE%"=="201" (
    echo  [OK] Release 创建成功
) else (
    echo  [WARN] HTTP %HTTP_CODE% - Release 可能已存在
)

REM --- 获取 upload_url
for /f "tokens=*" %%u in ('powershell -NoProfile -Command "(Get-Content '%TEMP%\release_resp.json' | ConvertFrom-Json).upload_url"') do set "UPLOAD_URL=%%u"

if "%UPLOAD_URL%"=="" (
    echo  [失败] 无法获取上传地址
    echo  提示: 检查 Release 是否已在 GitHub 上存在
    set GH_TOKEN=
    pause
    goto menu
)

REM 去掉 {?name,label} 模板部分
for /f "tokens=1 delims={?" %%p in ("%UPLOAD_URL%") do set "UPLOAD_URL=%%p"

echo  [OK] 已获取上传地址

REM --- 上传 zip
echo.
echo [2/2] 上传 %ZIP_NAME% ...

%curl% -s -o "%TEMP%\upload_resp.json" -w "%%{http_code}" ^
  -X POST "%UPLOAD_URL%?name=%ZIP_NAME%" ^
  -H "Authorization: token %GH_TOKEN%" ^
  -H "Content-Type: application/zip" ^
  --data-binary "@%ZIP_PATH%" > "%TEMP%\upload_code.txt"

set /p UPLOAD_CODE=<"%TEMP%\upload_code.txt"

if "%UPLOAD_CODE%"=="201" (
    echo  [OK] 上传成功!
) else (
    echo  [WARN] HTTP %UPLOAD_CODE% - 请检查上传结果
)

REM 清理 token
set GH_TOKEN=

echo.
echo  ====================================================
echo   完成!
echo   https://github.com/%GH_USER%/%GH_REPO%/releases/tag/%TAG%
echo  ====================================================
echo.

REM 清理临时文件
del /f "%TEMP%\release_resp.json" 2>nul
del /f "%TEMP%\release_http_code.txt" 2>nul
del /f "%TEMP%\upload_resp.json" 2>nul
del /f "%TEMP%\upload_code.txt" 2>nul

pause
goto menu