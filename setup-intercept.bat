@echo off
cd /d "%~dp0"
echo 请求管理员权限执行系统拦截配置...
powershell -Command "Start-Process PowerShell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%~dp0setup-intercept.ps1\"'"
pause
