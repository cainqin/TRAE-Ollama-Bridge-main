@echo off
setlocal EnableExtensions EnableDelayedExpansion
title TRAE-Ollama-Bridge 管理程序
cd /d "%~dp0"

chcp 65001 >nul

:: ====== 配置 ======
set "PORT=3000"
set "HTTPS_ENABLED=false"
set "BIND_ADDRESS=127.0.0.1"

if exist ".env" (
  for /f "usebackq tokens=1* delims==" %%A in (".env") do (
    if /I "%%~A"=="PORT" set "PORT=%%~B"
    if /I "%%~A"=="HTTPS_ENABLED" set "HTTPS_ENABLED=%%~B"
    if /I "%%~A"=="BIND_ADDRESS" set "BIND_ADDRESS=%%~B"
  )
)

set "SCHEME=http"
if /I "%HTTPS_ENABLED%"=="true" set "SCHEME=https"
set "WEB_URL=%SCHEME%://%BIND_ADDRESS%:%PORT%/"

:: ====== 优雅退出处理 ======
set "EXIT_FLAG=0"

:menu
cls
echo.
echo ╔═══════════════════════════════════════════╗
echo ║     TRAE-Ollama-Bridge 管理程序           ║
echo ╚═══════════════════════════════════════════╝
echo.
echo  端口: %PORT%  绑定: %BIND_ADDRESS%  HTTPS: %HTTPS_ENABLED%
echo.
echo  ┌─────────────────────────────────────────┐
echo  │  1. 启动桥接服务（前台运行）              │
echo  │  2. 启动桥接服务（后台静默运行）          │
echo  │  3. 停止桥接服务                         │
echo  │  4. 查看服务状态                         │
echo  │  5. 打开 Web 管理界面                    │
echo  │  6. 安装依赖（npm install）              │
echo  │  7. 运行自动测试                         │
echo  │  8. 查看环境配置                         │
echo  │  0. 退出                                 │
echo  └─────────────────────────────────────────┘
echo.
set /p "choice=请输入数字 [0-8]: "

if "%choice%"=="1" goto start_foreground
if "%choice%"=="2" goto start_background
if "%choice%"=="3" goto stop_bridge
if "%choice%"=="4" goto check_status
if "%choice%"=="5" goto open_webui
if "%choice%"=="6" goto install_deps
if "%choice%"=="7" goto run_tests
if "%choice%"=="8" goto show_config
if "%choice%"=="0" goto exit_program
goto menu

:: ====== 1. 前台启动 ======
:start_foreground
cls
echo [信息] 正在检查依赖...
call :check_deps
if errorlevel 1 goto menu_pause

echo [信息] 启动桥接服务 (前台模式)...
echo [信息] WebUI 地址: %WEB_URL%
echo [信息] 按 Ctrl+C 停止服务
echo.
node server.js
echo.
echo [信息] 服务已停止。
pause
goto menu

:: ====== 2. 后台启动 ======
:start_background
cls
echo [信息] 正在检查依赖...
call :check_deps
if errorlevel 1 goto menu_pause

echo [信息] 检查是否已有服务在运行...
call :is_running
if "%IS_RUNNING%"=="1" (
  echo [警告] 桥接服务似乎已在运行！
  echo        进程 PID: %BRIDGE_PID%
  echo        如果无法访问，请先选「3. 停止桥接服务」
  pause
  goto menu
)

echo [信息] 启动桥接服务 (后台静默模式)...
start "" /B node server.js > bridge.log 2>&1

:: 等待 3 秒检查是否启动成功
timeout /t 3 /nobreak >nul
call :is_running
if "%IS_RUNNING%"=="1" (
  echo [成功] 桥接服务已启动！
  echo [信息] PID: %BRIDGE_PID%
  echo [信息] WebUI 地址: %WEB_URL%
  start "" %WEB_URL%
) else (
  echo [失败] 服务启动失败，请检查 bridge.log
)
pause
goto menu

:: ====== 3. 停止服务 ======
:stop_bridge
cls
echo [信息] 正在停止桥接服务...
call :is_running
if "%IS_RUNNING%"=="0" (
  echo [信息] 没有正在运行的桥接服务。
  pause
  goto menu
)
taskkill /PID %BRIDGE_PID% /F >nul 2>&1
if errorlevel 1 (
  echo [警告] 无法通过 PID 停止，尝试按名称停止...
  taskkill /IM node.exe /F >nul 2>&1
)
echo [成功] 桥接服务已停止。
pause
goto menu

:: ====== 4. 查看状态 ======
:check_status
cls
echo ═══ 服务状态 ═══
echo.
call :is_running
if "%IS_RUNNING%"=="1" (
  echo  运行状态: ✅ 正在运行 (PID: %BRIDGE_PID%)
) else (
  echo  运行状态: ❌ 未运行
)
echo.
echo  端口 %PORT% 占用检查:
call :check_port %PORT%
echo.
echo  日志文件 (bridge.log):
if exist bridge.log (
  for /f "skip=5 delims=" %%L in (bridge.log) do (
    echo  %%L
    goto :log_done
  )
  :log_done
  type bridge.log 2>nul
) else (
  echo  (暂无日志)
)
echo.
echo  配置文件 (.env):
if exist .env (
  type .env
) else (
  echo  (文件不存在，请从 .env.example 复制)
)
echo.
pause
goto menu

:: ====== 5. 打开 WebUI ======
:open_webui
cls
call :is_running
if "%IS_RUNNING%"=="1" (
  echo [信息] 正在打开 WebUI: %WEB_URL%
  start "" %WEB_URL%
) else (
  echo [警告] 桥接服务未运行，请先启动服务。
)
pause
goto menu

:: ====== 6. 安装依赖 ======
:install_deps
cls
echo [信息] 正在安装 Node.js 依赖...
echo.
call npm install
if errorlevel 1 (
  echo [失败] 依赖安装失败！
  echo 请确保已安装 Node.js (v18+)：https://nodejs.org/
) else (
  echo [成功] 依赖安装完成！
)
pause
goto menu

:: ====== 7. 运行测试 ======
:run_tests
cls
echo [信息] 正在运行自动测试...
echo.
npm test
echo.
if errorlevel 1 (
  echo [失败] 部分测试未通过，请检查上方输出。
) else (
  echo [成功] 所有测试通过！
)
pause
goto menu

:: ====== 8. 查看配置 ======
:show_config
cls
echo ═══ 当前环境配置 ═══
echo.
echo  配置文件: .env
if exist .env (
  type .env
) else (
  echo  (文件不存在)
)
echo.
echo  ─────────────────────────────────────────
echo  Node.js 版本: 
node --version
echo  npm 版本:
npm --version
echo  ─────────────────────────────────────────
echo.
echo  项目文件结构:
echo    server.js          - 桥接服务主程序
echo    elevated-service.js - 高权限助手
echo    web/index.html     - Web 管理界面
echo    data/models.json   - 模型映射数据
echo.
pause
goto menu

:: ====== 退出 ======
:exit_program
cls
echo 感谢使用 TRAE-Ollama-Bridge！
timeout /t 1 /nobreak >nul
exit /b 0

:: ====== 辅助函数 ======

:check_deps
if not exist "node_modules" (
  echo [信息] 首次运行，正在安装依赖...
  call npm install
  if errorlevel 1 (
    echo [失败] 依赖安装失败！
    echo 请确认已安装 Node.js：https://nodejs.org/
    exit /b 1
  )
  echo [成功] 依赖安装完成！
)
exit /b 0

:check_port
set "port=%1"
netstat -ano | findstr ":%port% " >nul 2>&1
if errorlevel 1 (
  echo   端口 %port% 未被占用 ✅
) else (
  echo   端口 %port% 已被占用 ⚠️
  for /f "tokens=5" %%P in ('netstat -ano ^| findstr ":%port% "') do (
    echo   占用进程 PID: %%P
  )
)
exit /b 0

:is_running
set "IS_RUNNING=0"
set "BRIDGE_PID="
for /f "tokens=2 delims= " %%A in ('tasklist /FI "IMAGENAME eq node.exe" /FO LIST 2^>nul ^| findstr /B "PID:"') do (
  set "BRIDGE_PID=%%A"
  set "IS_RUNNING=1"
)
exit /b 0

:menu_pause
pause
goto menu
