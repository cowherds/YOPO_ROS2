from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, ExecuteProcess
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
    trial_arg = DeclareLaunchArgument(
        "trial",
        default_value="1",
        description="YOPO trial index (weights folder).",
    )
    epoch_arg = DeclareLaunchArgument(
        "epoch",
        default_value="50",
        description="YOPO epoch checkpoint.",
    )

    run_yopo = ExecuteProcess(
        cmd=[
            "bash",
            "-lc",
            [
                "cd ",
                yopo_root,
                " && source /opt/ros/${ROS_DISTRO:-humble}/setup.bash"
                " && conda run -n yopo bash scripts/run_yopo_ros2.sh"
                " --trial=",
                trial,
                " --epoch=",
                epoch,
            ],
        ],
        output="screen",
        emulate_tty=False,
    )

    return LaunchDescription([yopo_root_arg, trial_arg, epoch_arg, run_yopo])
