# ROS2 Jazzy Docker Development Environment (For MacOS) 

A Docker-based development environment for ROS2 Jazzy with GUI support.

## 🚀 Quick Start

### Initial Setup (Run Once)
```bash
./setup.sh
```
This creates your persistent container and all necessary directories.

### Starting
```bash
# Connect to your container (starts automatically if stopped)
./manage.sh warp      # Recommended for Warp terminal users
# OR
./manage.sh connect   # Basic connection

# When done working, optionally stop the container
./manage.sh stop
```

### Management Commands
```bash
./manage.sh start      # Start the container
./manage.sh stop       # Stop the container  
./manage.sh warp       # Connect with Warp terminal integration (recommended)
./manage.sh connect    # Connect to container (basic)
./manage.sh status     # Check container status
./manage.sh restart    # Restart the container
./manage.sh logs       # View container logs
./manage.sh remove     # Remove container (destructive!)
```

### Alternative: Docker Compose
```bash
# Start container in background
docker-compose up -d

# Connect to running container
docker-compose exec ros2-dev /bin/bash

# Stop container
docker-compose stop ros2-dev
```

## 📁 Persistent Data

Your data persists in these locations:

- **`./ros2_workspace/`** - Your ROS2 workspace (source code, builds)
- **`./src/`** - Additional source code directory  
- **`./ros2_home/`** - ROS configuration and data

These directories are mounted from your host machine, so your work is always safe even if you remove the container.

## 🛠️ Inside the Container

### Pre-configured Aliases
- `ws` - Go to workspace (`/home/ros/ros2_ws`)
- `src` - Go to src directory (`/home/ros/ros2_ws/src`)
- `cb` - Build workspace (`colcon build`)
- `cbs` - Build with symlinks (`colcon build --symlink-install`)
- `cs` - Source workspace (`source install/setup.bash`)

## Visualization
### Download Foxglove 
[Foxglove](https://foxglove.dev/download)


### Foxglove Bridge
Foxglove Bridge is installed and ready to use. To launch it, run:
```bash
foxglove
```
