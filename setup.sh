#!/bin/bash

# ROS2 Docker Environment Setup Script
# This script sets up X11 forwarding and launches the ROS2 development environment

set -e

echo "🚀 Setting up ROS2 Jazzy Development Environment..."

# Create necessary directories
echo "📁 Creating workspace directories..."
mkdir -p ros2_workspace/src
mkdir -p ros2_home
mkdir -p src

# Setup X11 forwarding
echo "🖥️  Setting up X11 forwarding..."

# Create Xauth file for Docker
XAUTH=/tmp/.docker.xauth
if [ ! -f $XAUTH ]; then
    xauth_list=$(xauth nlist $DISPLAY 2>/dev/null | sed -e 's/^..../ffff/')
    if [ ! -z "$xauth_list" ]; then
        echo $xauth_list | xauth -f $XAUTH nmerge -
    else
        touch $XAUTH
    fi
    chmod a+r $XAUTH
fi

# Allow X11 connections
echo "🔓 Allowing X11 connections..."
if command -v xhost >/dev/null 2>&1; then
    xhost +local:docker
else
    echo "⚠️  xhost not found - GUI apps may not work without X11 server (like XQuartz on macOS)"
    echo "💡 Install XQuartz from https://www.xquartz.org/ if you need GUI applications"
fi

# Build the Docker image
echo "🔨 Building ROS2 development image..."
docker build -t ros2-jazzy-dev .

# Function to run ROS2 container (persistent mode)
run_container() {
    echo "🐳 Starting ROS2 container..."
    
    # Check if container already exists
    if docker ps -a --format 'table {{.Names}}' | grep -q "^ros2-jazzy-dev$"; then
        echo "📦 Container already exists. Starting it..."
        docker start ros2-jazzy-dev
        docker exec -it ros2-jazzy-dev /bin/bash
    else
        echo "📦 Creating new persistent container..."
        docker run -it -d \
            --name ros2-jazzy-dev \
            --network host \
            -e DISPLAY=$DISPLAY \
            -e QT_X11_NO_MITSHM=1 \
            -e XAUTHORITY=/tmp/.docker.xauth \
            -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
            -v /tmp/.docker.xauth:/tmp/.docker.xauth:rw \
            -v $(pwd)/ros2_workspace:/home/ros/ros2_ws:rw \
            -v $(pwd)/src:/home/ros/ros2_ws/src:rw \
            -v $(pwd)/ros2_home:/home/ros/.ros:rw \
            --cap-add SYS_PTRACE \
            --restart unless-stopped \
            ros2-jazzy-dev \
            tail -f /dev/null
        
        echo "📦 Connecting to container..."
        docker exec -it ros2-jazzy-dev /bin/bash
    fi
}

# Function to run with Docker Compose
run_compose() {
    echo "🐳 Starting ROS2 environment with Docker Compose..."
    docker-compose up -d
    echo "📦 Container is running in background. Connecting..."
    docker-compose exec ros2-dev /bin/bash
}

# Check if docker-compose.yml exists
if [ -f "docker-compose.yml" ]; then
    echo "📋 Docker Compose file found. Choose your preferred method:"
    echo "1) Run with Docker Compose (recommended)"
    echo "2) Run with direct Docker command"
    read -p "Enter choice (1 or 2): " choice
    
    case $choice in
        1)
            run_compose
            ;;
        2)
            run_container
            ;;
        *)
            echo "Invalid choice. Using Docker Compose..."
            run_compose
            ;;
    esac
else
    run_container
fi

# Cleanup function (only cleans X11, leaves containers running)
cleanup() {
    echo "🧹 Cleaning up X11 access..."
    if command -v xhost >/dev/null 2>&1; then
        xhost -local:docker
    fi
    echo "📦 Container remains running in background"
    echo "💡 Use 'docker-compose stop ros2-dev' or './manage.sh stop' to stop container"
}

# Set trap for cleanup on script exit
trap cleanup EXIT

echo "✅ ROS2 development environment is ready!"
echo ""
echo "📚 Quick Start Commands (inside container):"
echo "  ws          - Go to workspace"
echo "  src         - Go to src directory"
echo "  cb          - Build workspace"
echo "  cbs         - Build with symlinks"
echo "  cs          - Source workspace"
echo "  rviz2       - Launch RViz2"
echo "  rqt         - Launch RQT"
echo ""
echo "🎯 Test GUI with: rviz2 or rqt"
echo "🔄 Container Management:"
echo "  ./manage.sh warp                - Connect with Warp terminal features (recommended)"
echo "  ./manage.sh connect             - Connect to container (basic)"
echo "  ./manage.sh stop                - Stop container"
echo "  ./manage.sh start               - Start container"
echo "  ./manage.sh status              - Check container status"
echo ""
echo "💡 Warp Terminal Users:"
echo "  Use './manage.sh warp' to enable Warp's modern IDE features in the container"