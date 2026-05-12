param(
    [string]$RosSetup = "",
    [string]$PythonExe = "python"
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$CtrlUtilsDir = Join-Path $RootDir "Controller/src/utils"
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

Write-Host "[1/5] Switch packages to ROS2 templates"
& $SelectScript ROS2

Write-Host "[2/5] Build ROS2 interface package (quadrotor_msgs)"
Set-Location $CtrlUtilsDir
colcon build --symlink-install --packages-select quadrotor_msgs

Write-Host "[3/5] Source generated setup"
$Overlay = Join-Path $CtrlUtilsDir "install/local_setup.ps1"
if (-not (Test-Path $Overlay)) {
    throw "Expected overlay not found: $Overlay"
}
. $Overlay

Write-Host "[4/5] Python dependency check for ROS2 runtime bridge"
@'
import importlib.util as u
mods = ["rclpy", "sensor_msgs_py", "nav_msgs.msg", "geometry_msgs.msg", "sensor_msgs.msg"]
missing = [m for m in mods if u.find_spec(m) is None]
if missing:
    raise SystemExit("Missing modules: " + ", ".join(missing))
print("ROS2 Python deps check passed.")
'@ | & $PythonExe -
if ($LASTEXITCODE -ne 0) { throw "ROS2 Python dependencies check failed." }
Write-Host "ROS2 Python deps check passed."

Write-Host "[5/5] YOPO ROS2 dry-run bridge check"
Set-Location $YopoDir
& $PythonExe -c "import importlib,sys;sys.path.insert(0,'.');c=importlib.import_module('ros_compat');v=c.detect_ros_version(force_version='ros2');p=c.import_position_command(v);print('Loaded ROS bridge successfully.');print('PositionCommand type: '+p.__module__+'.'+p.__name__)"

Write-Host "Use runtime command:"
Write-Host "  python test_yopo_ros.py --ros_version ros2 --trial=1 --epoch=50"
Write-Host "ROS2 compatibility smoke test completed."
