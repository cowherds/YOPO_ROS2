param(
    [string]$RosSetup = "",
    [string]$PythonExe = "python",
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ForwardArgs
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$CtrlUtilsDir = Join-Path $RootDir "Controller/src/utils"
$CtrlWsDir = Join-Path $RootDir "Controller/src"
$YopoDir = Join-Path $RootDir "YOPO"
$SelectScript = Join-Path $ScriptDir "select_ros_version_windows.ps1"

if (-not [string]::IsNullOrWhiteSpace($RosSetup)) {
    if (-not (Test-Path $RosSetup)) {
        throw "RosSetup file not found: $RosSetup"
    }
    . $RosSetup
} elseif (-not $env:ROS_DISTRO) {
    throw "ROS_DISTRO is not set. Please source your ROS2 installation first or pass -RosSetup."
}

& $SelectScript ROS2

$CtrlWsOverlay = Join-Path $CtrlWsDir "install_ros2/local_setup.ps1"
$CtrlUtilsOverlay = Join-Path $CtrlUtilsDir "install/local_setup.ps1"
if (Test-Path $CtrlWsOverlay) {
    . $CtrlWsOverlay
} elseif (Test-Path $CtrlUtilsOverlay) {
    . $CtrlUtilsOverlay
} else {
    throw "ROS2 controller workspace is not built. Run scripts/build_controller_ros2_windows.ps1 first."
}

Set-Location $YopoDir
& $PythonExe "test_yopo_ros.py" "--ros_version" "ros2" @ForwardArgs
