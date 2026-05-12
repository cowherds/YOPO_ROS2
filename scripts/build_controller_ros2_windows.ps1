param(
    [string]$RosSetup = ""
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$CtrlDir = Join-Path $RootDir "Controller/src"
$SelectScript = Join-Path $ScriptDir "select_ros_version_windows.ps1"

function Ensure-RosEnv {
    if (-not [string]::IsNullOrWhiteSpace($RosSetup)) {
        if (-not (Test-Path $RosSetup)) {
            throw "RosSetup file not found: $RosSetup"
        }
        . $RosSetup
    } elseif (-not $env:ROS_DISTRO) {
        throw "ROS_DISTRO is not set. Please source ROS2 first or pass -RosSetup <local_setup.ps1>."
    }
}

Ensure-RosEnv
& $SelectScript ROS2

Set-Location $CtrlDir
$PythonExe = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $PythonExe) {
    $PythonExe = "python"
}
colcon --log-base log_ros2 build --symlink-install `
  --base-paths utils/quadrotor_msgs so3_control so3_quadrotor_simulator utils/yopo_bringup `
  --build-base build_ros2 `
  --install-base install_ros2 `
  --cmake-args "-DPython3_EXECUTABLE=$PythonExe"

Write-Host ""
Write-Host "Controller ROS2 build finished."
Write-Host "Source overlay with:"
Write-Host "  . `"$CtrlDir\install_ros2\local_setup.ps1`""
