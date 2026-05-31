@echo off
setlocal EnableExtensions EnableDelayedExpansion
title TRAE-Ollama-Bridge
cd /d "%~dp0"

rem Use UTF-8 code page to avoid garbled output
chcp 65001 >nul

echo [TRAE] Checking dependencies...
if not exist "node_modules" (
  echo First run detected. Installing dependencies...
  call npm install
  if errorlevel 1 (
    echo Dependency installation failed. Please verify your Node.js/npm setup.
    pause
    exit /b 1
  )
)

rem Load PORT, HTTPS_ENABLED, and BIND_ADDRESS from .env if present
if exist ".env" (
  for /f "usebackq tokens=1* delims==" %%A in (".env") do (
    if /I "%%~A"=="PORT" set PORT=%%~B
    if /I "%%~A"=="HTTPS_ENABLED" set HTTPS_ENABLED=%%~B
    if /I "%%~A"=="BIND_ADDRESS" set BIND_ADDRESS=%%~B
  )
)

if "%PORT%"=="" set PORT=3000
if "%HTTPS_ENABLED%"=="" set HTTPS_ENABLED=false
if "%BIND_ADDRESS%"=="" set BIND_ADDRESS=127.0.0.1
set /a "HTTP_PORT=%PORT%+2000"

echo [TRAE] Starting bridge service: PORT=%PORT% HTTPS_ENABLED=%HTTPS_ENABLED%

start "" http://%BIND_ADDRESS%:%HTTP_PORT%/
node server.js

endlocal