# YOPO ROS2 在 Windows 的构建说明

本文档用于在 Windows（PowerShell）下构建本仓库的 ROS2 版本。

## 1. 结论先说

- 可以在 Windows 上使用 ROS2 编译本项目的 ROS2 子项目。
- `Controller` 相关 ROS2 包（消息、控制器、动力学仿真）可按 ROS2/colcon 标准流程构建。
- `Simulator`（`sensor_simulator`）理论可编译，但依赖更多（CUDA/PCL/OpenCV/yaml-cpp/OpenMP），Windows 环境准备成本更高。
- 当前仓库的“一键脚本/部分 launch”是 Linux 写法（`bash`、`/opt/ros/.../setup.bash`、硬编码 Linux 路径），在 Windows 不能直接复用。

## 2. 适用范围与前提

- OS: Windows 10/11
- ROS2: 建议 Humble（与仓库文档一致）
- Shell: PowerShell
- 已安装并可用：
  - Visual Studio C++ 工具链（MSVC）
  - CMake + colcon
  - Python（与 ROS2 匹配版本）
  - 可选：CUDA Toolkit（若编译 `sensor_simulator`）
  - 可选：PCL / OpenCV / yaml-cpp / Armadillo（建议用 vcpkg 统一管理）

> 注意：`sensor_simulator` 强依赖 CUDA；没有 CUDA 时可先只编译 `Controller` 子项目。

## 3. 先切换到 ROS2 模板（Windows 版）

仓库中的 `scripts/select_ros_version.sh` 是 bash 脚本，Windows 下请用以下 PowerShell 方式执行同等操作：

```powershell
Set-Location D:\YOPO_ROS2

$packages = @(
  "Controller/src/utils/quadrotor_msgs",
  "Controller/src/utils/mavros_msgs",
  "Controller/src/so3_control",
  "Controller/src/so3_quadrotor_simulator",
  "Simulator/src"
)

foreach ($p in $packages) {
  $cmakeSrc = Join-Path $p "ros/ros2.CMakeLists.txt"
  $pkgSrc   = Join-Path $p "ros/ros2.package.xml"
  if ((Test-Path $cmakeSrc) -and (Test-Path $pkgSrc)) {
    Copy-Item $cmakeSrc (Join-Path $p "CMakeLists.txt") -Force
    Copy-Item $pkgSrc   (Join-Path $p "package.xml")    -Force
    Write-Host "[ok] switched $p to ROS2 template"
  } else {
    Write-Host "[skip] $p has no ROS2 template pair"
  }
}
```

## 4. 加载 ROS2 环境（每个新终端都要做）

```powershell
# 例子：根据你的 ROS2 安装路径修改
& "C:\dev\ros2_humble\local_setup.ps1"
```

## 5. 各子项目 Windows 编译命令

下面按“子项目”给出建议顺序。

### 5.1 `quadrotor_msgs`（Controller 消息包）

```powershell
Set-Location D:\YOPO_ROS2\Controller\src
colcon build --merge-install --packages-select quadrotor_msgs
```

### 5.2 `mavros_msgs`（可选消息包）

```powershell
Set-Location D:\YOPO_ROS2\Controller\src
colcon build --merge-install --packages-select mavros_msgs
```

### 5.3 `so3_control`（控制器）

```powershell
Set-Location D:\YOPO_ROS2\Controller\src
colcon build --merge-install --packages-select so3_control
```

### 5.4 `so3_quadrotor_simulator`（动力学仿真）

```powershell
Set-Location D:\YOPO_ROS2\Controller\src
colcon build --merge-install --packages-select so3_quadrotor_simulator
```

### 5.5 `yopo_bringup`（ROS2 启动包）

```powershell
Set-Location D:\YOPO_ROS2\Controller\src
colcon build --merge-install --packages-select yopo_bringup
```

### 5.6 `sensor_simulator`（Simulator，CUDA）

先加载 Controller overlay（保证消息和控制器依赖可见）：

```powershell
& "C:\dev\ros2_humble\local_setup.ps1"
& "D:\YOPO_ROS2\Controller\src\install\local_setup.ps1"
```

然后编译：

```powershell
Set-Location D:\YOPO_ROS2\Simulator\src

# 按你的 GPU 架构调整 YOPO_CUDA_ARCH（例如 86/89）
colcon build --merge-install --packages-select sensor_simulator `
  --cmake-args -DYOPO_CUDA_ARCH=86
```

> 若你已配置原始 NVCC 参数，也可改为 `-DYOPO_CUDA_ARCH_FLAGS="..."`。

## 6. 一次性构建命令（可选）

### 6.1 Controller 一次性构建

```powershell
Set-Location D:\YOPO_ROS2\Controller\src
colcon build --merge-install --packages-select `
  quadrotor_msgs so3_control so3_quadrotor_simulator yopo_bringup
```

### 6.2 Simulator 构建

```powershell
& "C:\dev\ros2_humble\local_setup.ps1"
& "D:\YOPO_ROS2\Controller\src\install\local_setup.ps1"
Set-Location D:\YOPO_ROS2\Simulator\src
colcon build --merge-install --packages-select sensor_simulator --cmake-args -DYOPO_CUDA_ARCH=86
```

## 7. 当前 Windows 直接运行会遇到的问题

下面这些不是“编译器语法错误”，但会影响 Windows 直接运行整链路：

- `scripts/*.sh` 仅支持 bash（Windows PowerShell 不能直接 source `setup.bash`）。
- 若 launch 内部 `ExecuteProcess` 写死 `bash -lc`，在 Windows 会失败。
- 若 launch 默认值写死 Linux 路径（例如 `/home/...`），需要改成 Windows 路径或通过参数传入。

## 8. 是否需要额外改代码？

### 8.1 只要求“编译 Controller”：

- 通常不需要改核心 C++ 逻辑代码。
- 只需要改“流程层”（不使用 `.sh`，改用 PowerShell 命令）即可。

### 8.2 要在 Windows 跑完整系统（含 launch 一键拉起 + YOPO Python）：

建议做以下改造：

1. 增加 `scripts/build_controller_ros2.ps1`、`scripts/build_simulator_ros2.ps1`（替代 bash 脚本）。
2. 修改 `yopo_bringup` 的 launch：避免 `bash -lc` 和 `/opt/ros/.../setup.bash`。
3. 将 launch 中硬编码 Linux 默认路径改为参数化或平台无关路径。
4. 在 `Simulator/src/CMakeLists.txt` 做稳健性增强：`OpenMP` 目标加存在性判断（避免某些 Windows 环境找不到 `OpenMP::OpenMP_CXX` 时配置失败）。

## 9. 快速排错

- `Could not find package configuration file`：先确认已执行 ROS2 `local_setup.ps1`，并且前序 overlay 已 source。
- `PCL/OpenCV/yaml-cpp not found`：先在 Windows 安装对应依赖，并让 CMake 能找到。
- `CUDA architecture` 报错：显式传 `-DYOPO_CUDA_ARCH=<你的架构>`。

