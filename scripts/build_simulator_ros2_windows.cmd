@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "PS1=%SCRIPT_DIR%build_simulator_ros2_windows.ps1"

if not exist "%PS1%" (
  echo [error] PowerShell script not found: "%PS1%"
  exit /b 1
)

set "ROS_SETUP=%~1"
set "YOPO_CUDA_ARCH=%~2"
set "YOPO_CUDA_ARCH_FLAGS=%~3"

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -RosSetup "%ROS_SETUP%" -YopoCudaArch "%YOPO_CUDA_ARCH%" -YopoCudaArchFlags "%YOPO_CUDA_ARCH_FLAGS%"
exit /b %ERRORLEVEL%
