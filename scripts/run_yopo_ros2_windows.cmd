@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "PS1=%SCRIPT_DIR%run_yopo_ros2_windows.ps1"

if not exist "%PS1%" (
  echo [error] PowerShell script not found: "%PS1%"
  exit /b 1
)

set "ROS_SETUP=%~1"
set "PY_EXE=%~2"
if "%PY_EXE%"=="" set "PY_EXE=python"

if "%ROS_SETUP%"=="" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -PythonExe "%PY_EXE%"
  exit /b %ERRORLEVEL%
)

shift
shift
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -RosSetup "%ROS_SETUP%" -PythonExe "%PY_EXE%" --% %*
exit /b %ERRORLEVEL%
