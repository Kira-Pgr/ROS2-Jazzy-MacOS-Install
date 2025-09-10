# ROS2 Jazzy Development Environment with GUI Support
FROM osrf/ros:jazzy-desktop-full

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=jazzy
ENV AMENT_PREFIX_PATH=/opt/ros/jazzy
ENV COLCON_PREFIX_PATH=/opt/ros/jazzy
ENV LD_LIBRARY_PATH=/opt/ros/jazzy/lib
ENV PATH=/opt/ros/jazzy/bin:$PATH
ENV PYTHONPATH=/opt/ros/jazzy/lib/python3.12/site-packages
ENV ROS_PYTHON_VERSION=3
ENV ROS_VERSION=2
ENV DISPLAY=:0

# Create workspace directories
RUN mkdir -p /ros2_ws/src

# Install additional packages for GUI support and development tools
RUN apt-get update && apt-get install -y \
    # X11 and GUI dependencies
    libxcb-xinerama0 \
    libxcb-xinput0 \
    libxcb-randr0-dev \
    libxcb-xtest0-dev \
    libxcb-shape0-dev \
    libxcb-sync-dev \
    libxcb-render-util0-dev \
    libxcb-icccm4-dev \
    libxcb-keysyms1-dev \
    libxcb-image0-dev \
    libgl1-mesa-dev \
    libgl1-mesa-dri \
    libglu1-mesa-dev \
    freeglut3-dev \
    mesa-utils \
    x11-apps \
    # Qt dependencies (Ubuntu 24.04 compatible)
    qtbase5-dev \
    qtdeclarative5-dev \
    qtmultimedia5-dev \
    qt5-qmake \
    qtbase5-dev-tools \
    # Development tools
    git \
    vim \
    nano \
    curl \
    wget \
    unzip \
    build-essential \
    cmake \
    python3-pip \
    python3-colcon-common-extensions \
    python3-rosdep \
    python3-vcstool \
    python3-argcomplete \
    # ROS2 development packages
    ros-jazzy-demo-nodes-py \
    ros-jazzy-demo-nodes-cpp \
    ros-jazzy-example-interfaces \
    ros-jazzy-launch-ros \
    ros-jazzy-launch-testing-ament-cmake \
    ros-jazzy-rmw-fastrtps-cpp \
    # Foxglove bridge for visualization
    ros-jazzy-foxglove-bridge \
    # Additional useful packages
    bash-completion \
    && rm -rf /var/lib/apt/lists/*

# Initialize rosdep
RUN rosdep init || true
RUN rosdep update

# Setup workspace permissions and create user
RUN useradd -m -s /bin/bash ros && \
    usermod -aG sudo ros && \
    echo "ros ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    chown -R ros:ros /ros2_ws

# Switch to ros
USER ros
WORKDIR /home/ros

# Create user's ROS workspace
RUN mkdir -p /home/ros/ros2_ws/src

# Setup ROS2 environment in bashrc
RUN echo "# ROS2 Environment Setup" >> ~/.bashrc && \
    echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc && \
    echo "source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash" >> ~/.bashrc && \
    echo "export ROS_DOMAIN_ID=0" >> ~/.bashrc && \
    echo "export DISPLAY=:0" >> ~/.bashrc && \
    echo "" >> ~/.bashrc && \
    echo "# Workspace setup" >> ~/.bashrc && \
    echo "if [ -f /home/ros/ros2_ws/install/setup.bash ]; then" >> ~/.bashrc && \
    echo "    source /home/ros/ros2_ws/install/setup.bash" >> ~/.bashrc && \
    echo "fi" >> ~/.bashrc && \
    echo "" >> ~/.bashrc && \
    echo "# Aliases for convenience" >> ~/.bashrc && \
    echo "alias ws='cd /home/ros/ros2_ws'" >> ~/.bashrc && \
    echo "alias src='cd /home/ros/ros2_ws/src'" >> ~/.bashrc && \
    echo "alias cb='cd /home/ros/ros2_ws && colcon build'" >> ~/.bashrc && \
    echo "alias cbs='cd /home/ros/ros2_ws && colcon build --symlink-install'" >> ~/.bashrc && \
    echo "alias cbp='cd /home/ros/ros2_ws && colcon build --packages-select'" >> ~/.bashrc && \
    echo "alias cs='cd /home/ros/ros2_ws && source install/setup.bash'" >> ~/.bashrc && \
    echo "alias ll='ls -alF'" >> ~/.bashrc && \
    echo "alias foxglove='ros2 launch foxglove_bridge foxglove_bridge_launch.xml'" >> ~/.bashrc && \
    echo "" >> ~/.bashrc && \
    echo "# Warp Terminal Integration" >> ~/.bashrc && \
    echo "# This enables Warp's modern IDE features (blocks, completions, syntax highlighting)" >> ~/.bashrc && \
    echo "printf '\\eP\$f{\"hook\": \"SourcedRcFileForWarp\", \"value\": { \"shell\": \"bash\"}}\\x9c'" >> ~/.bashrc

# Create a startup script
RUN echo '#!/bin/bash' > /home/ros/start_ros2.sh && \
    echo 'source /opt/ros/jazzy/setup.bash' >> /home/ros/start_ros2.sh && \
    echo 'if [ -f /home/ros/ros2_ws/install/setup.bash ]; then' >> /home/ros/start_ros2.sh && \
    echo '    source /home/ros/ros2_ws/install/setup.bash' >> /home/ros/start_ros2.sh && \
    echo 'fi' >> /home/ros/start_ros2.sh && \
    echo 'exec "$@"' >> /home/ros/start_ros2.sh && \
    chmod +x /home/ros/start_ros2.sh

# Set working directory to workspace
WORKDIR /home/ros/ros2_ws

# Default command
CMD ["/bin/bash"]

# Health check to verify ROS2 installation
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD /bin/bash -c "source /opt/ros/jazzy/setup.bash && ros2 --help" || exit 1