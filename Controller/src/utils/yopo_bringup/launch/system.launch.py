import os

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, ExecuteProcess, IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import LaunchConfiguration


def generate_launch_description():
    yopo_root = LaunchConfiguration("yopo_root")
    trial = LaunchConfiguration("trial")
    epoch = LaunchConfiguration("epoch")

    yopo_root_arg = DeclareLaunchArgument(
        "yopo_root",
        default_value="/home/duckcity/YOPO_ROS2/YOPO",
        description="Absolute path to YOPO repository root.",
    )
    trial_arg = DeclareLaunchArgument("trial", default_value="1")
    epoch_arg = DeclareLaunchArgument("epoch", default_value="50")

    sim_ctrl_launch = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(
                get_package_share_directory("so3_quadrotor_simulator"),
                "launch",
                "simulator_attitude_control.launch.py",
            )
        )
    )

    sensor_launch = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(
                get_package_share_directory("sensor_simulator"),
                "launch",
                "sensor_simulator.launch.py",
            )
        )
    )

    yopo_node = ExecuteProcess(
        cmd=[
            "bash",
            "-lc",
            [
                "cd ",
                yopo_root,
                " && source /opt/ros/${ROS_DISTRO:-humble}/setup.bash",
                " && conda run -n yopo bash scripts/run_yopo_ros2.sh",
                " --trial=",
                trial,
                " --epoch=",
                epoch,
            ],
        ],
        output="screen",
        emulate_tty=False,
    )

    return LaunchDescription([
        yopo_root_arg,
        trial_arg,
        epoch_arg,
        sim_ctrl_launch,
        sensor_launch,
        yopo_node,
    ])
