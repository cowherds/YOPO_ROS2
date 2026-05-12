# YOPO ROS2 构建与运行完整流程

本文档用于在全新环境下，从源码构建并运行 YOPO（ROS2 版）。

## 1. 环境要求

- Ubuntu 22.04（或可运行 ROS2 Humble 的系统）
- ROS2 Humble（已安装）
- NVIDIA 驱动 + CUDA（用于 `sensor_simulator`）
- Conda（用于 YOPO Python 环境）

> 重要：ROS2 Humble 对 `rclpy` 的 Python 版本要求为 **3.10**。  
> 若使用 `python=3.8` 会出现 `rclpy._rclpy_pybind11` 导入失败。

## 2. 获取代码

```bash
cd ~
git clone <your-repo-url> YOPO_ROS2
cd YOPO_ROS2/YOPO
```

## 3. 创建 YOPO Python 环境

```bash
conda create -n yopo python=3.10 -y
conda activate yopo
cd YOPO
pip install -r requirements.txt
```

## 4. 构建 ROS2 Controller 阶段

```bash
cd ~/YOPO_ROS2/YOPO
source /opt/ros/humble/setup.bash
bash scripts/build_controller_ros2.sh
```

成功后会生成：

- `Controller/src/install_ros2/`

## 5. 构建 ROS2 Simulator 阶段

```bash
cd ~/YOPO_ROS2/YOPO
source /opt/ros/humble/setup.bash
bash scripts/build_simulator_ros2.sh
```

成功后会生成：

- `Simulator/src/install_ros2/`

### CUDA 架构兼容（可选）

如果 `nvcc` 报 GPU 架构不支持，可手动指定：

```bash
export YOPO_CUDA_ARCH=86
bash scripts/build_simulator_ros2.sh
```

或直接传原始 NVCC 参数：

```bash
export YOPO_CUDA_ARCH_FLAGS="-gencode arch=compute_86,code=sm_86"
bash scripts/build_simulator_ros2.sh
```

## 6. 一键启动全系统

```bash
cd ~/YOPO_ROS2/YOPO
source /opt/ros/humble/setup.bash
source Controller/src/install_ros2/setup.bash
source Simulator/src/install_ros2/setup.bash
ros2 launch yopo_bringup system.launch.py trial:=1 epoch:=50
```

启动后终端会常驻，这是正常行为（launch 前台运行，等待 Ctrl+C 退出）。

## 7. 三终端精确清单（手动分步）

如果你希望按 `Controller` / `Simulator` / `YOPO Planner` 分开启动，请按以下顺序执行。

### 7.1 终端 1：Controller（先启动）

```bash
cd ~/YOPO_ROS2
source /opt/ros/humble/setup.bash
source ~/YOPO_ROS2/Controller/src/install_ros2/setup.bash
ros2 launch so3_quadrotor_simulator simulator_attitude_control.launch.py
```

### 7.2 终端 2：Simulator（第二个启动）

```bash
cd ~/YOPO_ROS2
source /opt/ros/humble/setup.bash
source ~/YOPO_ROS2/Controller/src/install_ros2/setup.bash
source ~/YOPO_ROS2/Simulator/src/install_ros2/setup.bash
ros2 run sensor_simulator sensor_simulator
```

### 7.3 终端 3：YOPO Planner（最后启动）

```bash
cd ~/YOPO_ROS2
source /opt/ros/humble/setup.bash
source ~/YOPO_ROS2/Controller/src/install_ros2/setup.bash
conda activate yopo
cd YOPO
python test_yopo_ros.py --ros_version ros2 --trial=1 --epoch=50
```

### 7.4 终端 4：Rviz（可视化）

```bash
cd ~/YOPO_ROS2/YOPO
source /opt/ros/humble/setup.bash
rviz2 -d yopo_ros2.rviz
```


> 说明：`sensor_simulator` 包的可执行名是 `sensor_simulator`，不是 `sensor_simulator_cuda`。

## 8. 启动后健康检查

新开一个终端执行：

```bash
source /opt/ros/humble/setup.bash
source ~/YOPO_ROS2/YOPO/Controller/src/install_ros2/setup.bash
source ~/YOPO_ROS2/YOPO/Simulator/src/install_ros2/setup.bash
ros2 topic echo /sim/odom --once
ros2 topic echo /depth_image --once
ros2 topic echo /so3_control/pos_cmd --once
```

若三条均有输出，说明主链路正常。

## 9. 常见问题

### 9.1 `ROS2 requested, but rclpy is not available`

原因：`yopo` 环境 Python 版本不是 3.10。  
解决：重建 `conda` 环境为 `python=3.10`。

### 9.2 `Unsupported gpu architecture 'compute_89'`

原因：当前 CUDA 工具链不支持自动探测到的架构。  
解决：设置 `YOPO_CUDA_ARCH=86` 后重新构建。

### 9.3 启动时卡在终端不返回

这是 `ros2 launch` 正常行为，不是死锁。  
前台常驻意味着节点在持续运行。

### 9.4 `AttributeError: module 'em' has no attribute 'BUFFERED_OPT'`

原因：构建时误用了 Conda 里的 `python`/`em`，与 ROS2 Humble 的 `rosidl_adapter` 不兼容。  
解决：使用仓库内脚本重新构建（脚本已固定 ROS2 使用 `/usr/bin/python3`）：

```bash
cd ~/YOPO_ROS2
source /opt/ros/humble/setup.bash
bash scripts/build_controller_ros2.sh
```

## 10. 清理构建产物（发布前）

```bash
cd ~/YOPO_ROS2
rm -rf build install log
rm -rf super_ws/build super_ws/install super_ws/log
rm -rf YOPO/.ros_logs
rm -rf YOPO/Controller/src/build YOPO/Controller/src/install YOPO/Controller/src/log
rm -rf YOPO/Controller/src/build_ros2 YOPO/Controller/src/install_ros2 YOPO/Controller/src/log_ros2
rm -rf YOPO/Simulator/src/build YOPO/Simulator/src/install YOPO/Simulator/src/log
rm -rf YOPO/Simulator/src/build_ros2 YOPO/Simulator/src/install_ros2 YOPO/Simulator/src/log_ros2
```
