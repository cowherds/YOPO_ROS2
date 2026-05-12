param(
    [string]$RosSetup = "",
    [string]$YopoCudaArch = "",
    [string]$YopoCudaArchFlags = ""
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$CtrlDir = Join-Path $RootDir "Controller/src"
$SimDir = Join-Path $RootDir "Simulator/src"
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

$CtrlOverlay = Join-Path $CtrlDir "install_ros2/local_setup.ps1"
if (Test-Path $CtrlOverlay) {
    . $CtrlOverlay
}

Set-Location $SimDir
$PythonExe = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $PythonExe) {
    $PythonExe = "python"
}

$CmakeArgs = @("-DPython3_EXECUTABLE=$PythonExe")
if (-not [string]::IsNullOrWhiteSpace($YopoCudaArch)) {
    $CmakeArgs += "-DYOPO_CUDA_ARCH=$YopoCudaArch"
}
if (-not [string]::IsNullOrWhiteSpace($YopoCudaArchFlags)) {
    $CmakeArgs += "-DYOPO_CUDA_ARCH_FLAGS=$YopoCudaArchFlags"
}

colcon --log-base log_ros2 build --symlink-install `
  --base-paths . `
  --build-base build_ros2 `
  --install-base install_ros2 `
  --cmake-args @CmakeArgs

Write-Host ""
Write-Host "Simulator ROS2 build finished."
Write-Host "Source overlay with:"
Write-Host "  . `"$SimDir\install_ros2\local_setup.ps1`""
