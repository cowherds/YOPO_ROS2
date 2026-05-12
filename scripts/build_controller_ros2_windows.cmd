@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "PS1=%SCRIPT_DIR%build_controller_ros2_windows.ps1"

if not exist "%PS1%" (
  echo [error] PowerShell script not found: "%PS1%"
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -RosSetup "%~1"
exit /b %ERRORLEVEL%
