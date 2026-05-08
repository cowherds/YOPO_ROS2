from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, ExecuteProcess, IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import LaunchConfiguration, PathJoinSubstitution
from launch_ros.substitutions import FindPackageShare
from launch_ros.actions import Node


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

    controller_stage = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            PathJoinSubstitution([FindPackageShare("yopo_bringup"), "launch", "controller_stage.launch.py"])
        )
    )

    sensor_sim = Node(
        package="sensor_simulator",
        executable="sensor_simulator",
        name="sensor_simulator_node",
        output="screen",
    )

    yopo_node = ExecuteProcess(
        cmd=[
            "bash",
            "-lc",
            [
                "cd ",
                yopo_root,
                " && source /opt/ros/${ROS_DISTRO:-humble}/setup.bash"
                " && source Controller/src/utils/install/setup.bash"
                " && source Simulator/install/setup.bash"
                " && conda run -n yopo python YOPO/test_yopo_ros.py --ros_version ros2 --trial=",
                trial,
                " --epoch=",
                epoch,
            ],
        ],
        output="screen",
        emulate_tty=True,
    )

    return LaunchDescription([yopo_root_arg, trial_arg, epoch_arg, controller_stage, sensor_sim, yopo_node])
