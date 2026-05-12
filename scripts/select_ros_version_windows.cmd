@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "PS1=%SCRIPT_DIR%select_ros_version_windows.ps1"

if "%~1"=="" (
  echo Usage: %~nx0 [ROS1^|ROS2]
  exit /b 1
)

if not exist "%PS1%" (
  echo [error] PowerShell script not found: "%PS1%"
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" "%~1"
exit /b %ERRORLEVEL%
