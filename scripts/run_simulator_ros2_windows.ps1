param(
    [string]$RosSetup = "",
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ForwardArgs
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$CtrlDir = Join-Path $RootDir "Controller/src"
$SimDir = Join-Path $RootDir "Simulator/src"

if (-not [string]::IsNullOrWhiteSpace($RosSetup)) {
    if (-not (Test-Path $RosSetup)) {
        throw "RosSetup file not found: $RosSetup"
    }
    . $RosSetup
} elseif (-not $env:ROS_DISTRO) {
    throw "ROS_DISTRO is not set. Please source ROS2 first or pass -RosSetup <local_setup.ps1>."
}

$CtrlOverlay = Join-Path $CtrlDir "install_ros2/local_setup.ps1"
$SimOverlay = Join-Path $SimDir "install_ros2/local_setup.ps1"

if (-not (Test-Path $CtrlOverlay)) {
    throw "Controller ROS2 overlay not found: $CtrlOverlay. Build controller first."
}
if (-not (Test-Path $SimOverlay)) {
    throw "Simulator ROS2 overlay not found: $SimOverlay. Build simulator first."
}

. $CtrlOverlay
. $SimOverlay

ros2 launch sensor_simulator sensor_simulator.launch.py @ForwardArgs
