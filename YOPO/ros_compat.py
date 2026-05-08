import os
import time


class RosCompatError(RuntimeError):
    pass


def detect_ros_version(force_version=None):
    requested = (force_version or os.environ.get("YOPO_ROS_VERSION", "auto")).strip().lower()
    if requested not in {"auto", "ros1", "ros2"}:
        raise RosCompatError(f"Invalid YOPO_ROS_VERSION='{requested}', expected auto|ros1|ros2")

    ros1_ok = False
    ros2_ok = False
    try:
        import rospy  # noqa: F401
        ros1_ok = True
    except Exception:
        ros1_ok = False

    try:
        import rclpy  # noqa: F401
        ros2_ok = True
    except Exception:
        ros2_ok = False

    if requested == "ros1":
        if not ros1_ok:
            raise RosCompatError("ROS1 requested, but rospy is not available.")
        return "ros1"
    if requested == "ros2":
        if not ros2_ok:
            raise RosCompatError("ROS2 requested, but rclpy is not available.")
        return "ros2"

    if ros2_ok:
        return "ros2"
    if ros1_ok:
        return "ros1"
    raise RosCompatError("Neither ROS1(rospy) nor ROS2(rclpy) is available in current environment.")


class Ros1Adapter:
    def __init__(self, node_name):
        import rospy
        self._rospy = rospy
        self._rospy.init_node(node_name, anonymous=False)

    def create_publisher(self, msg_type, topic, queue_size=1):
        return self._rospy.Publisher(topic, msg_type, queue_size=queue_size)

    def create_subscription(self, msg_type, topic, callback, queue_size=1):
        return self._rospy.Subscriber(topic, msg_type, callback, queue_size=queue_size, tcp_nodelay=True)

    def create_timer(self, period_sec, callback):
        return self._rospy.Timer(self._rospy.Duration(period_sec), callback)

    def now(self):
        return self._rospy.Time.now()

    def sleep(self, sec):
        self._rospy.sleep(sec)

    def spin(self):
        self._rospy.spin()

    def logwarn(self, msg):
        self._rospy.logwarn(msg)

    @staticmethod
    def has_connections(pub):
        return pub.get_num_connections() > 0


class Ros2Adapter:
    def __init__(self, node_name):
        import rclpy
        from rclpy.node import Node

        rclpy.init(args=None)
        self._rclpy = rclpy
        self.node = Node(node_name)

    def create_publisher(self, msg_type, topic, queue_size=1):
        return self.node.create_publisher(msg_type, topic, queue_size)

    def create_subscription(self, msg_type, topic, callback, queue_size=1):
        return self.node.create_subscription(msg_type, topic, callback, queue_size)

    def create_timer(self, period_sec, callback):
        return self.node.create_timer(period_sec, lambda: callback(None))

    def now(self):
        return self.node.get_clock().now().to_msg()

    @staticmethod
    def sleep(sec):
        time.sleep(sec)

    def spin(self):
        try:
            self._rclpy.spin(self.node)
        finally:
            self.node.destroy_node()
            self._rclpy.shutdown()

    def logwarn(self, msg):
        self.node.get_logger().warning(msg)

    @staticmethod
    def has_connections(pub):
        return pub.get_subscription_count() > 0


def make_ros_adapter(node_name, force_version=None):
    ros_version = detect_ros_version(force_version=force_version)
    if ros_version == "ros2":
        return ros_version, Ros2Adapter(node_name)
    return ros_version, Ros1Adapter(node_name)


def import_point_cloud2(ros_version):
    if ros_version == "ros2":
        from sensor_msgs_py import point_cloud2
        return point_cloud2
    from sensor_msgs import point_cloud2
    return point_cloud2


def import_position_command(ros_version):
    if ros_version == "ros2":
        from quadrotor_msgs.msg import PositionCommand
        return PositionCommand
    from control_msg import PositionCommand
    return PositionCommand
