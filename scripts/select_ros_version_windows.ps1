param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet("ROS1", "ROS2", "ros1", "ros2")]
    [string]$RosVersion
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$RosVersionNorm = $RosVersion.ToLower()

function Copy-TemplateIfExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageDir
    )

    $TemplateBase = Join-Path $PackageDir ("ros/" + $RosVersionNorm)
    $CmakeSrc = "$TemplateBase.CMakeLists.txt"
    $PackageSrc = "$TemplateBase.package.xml"
    $CmakeDst = Join-Path $PackageDir "CMakeLists.txt"
    $PackageDst = Join-Path $PackageDir "package.xml"

    if (-not ((Test-Path $CmakeSrc) -and (Test-Path $PackageSrc))) {
        Write-Host "[skip] $(Split-Path $PackageDir -Leaf) has no $RosVersionNorm templates."
        return
    }

    Copy-Item $CmakeSrc $CmakeDst -Force
    Copy-Item $PackageSrc $PackageDst -Force
    Write-Host "[ok] switched $(Split-Path $PackageDir -Leaf) to $RosVersionNorm"
}

Copy-TemplateIfExists (Join-Path $RootDir "Controller/src/utils/quadrotor_msgs")
Copy-TemplateIfExists (Join-Path $RootDir "Controller/src/utils/mavros_msgs")
Copy-TemplateIfExists (Join-Path $RootDir "Controller/src/so3_control")
Copy-TemplateIfExists (Join-Path $RootDir "Controller/src/so3_quadrotor_simulator")
Copy-TemplateIfExists (Join-Path $RootDir "Simulator/src")

Write-Host "Done. Selected $RosVersionNorm templates where available."
