#!/bin/bash

# ROS2 Docker Container Management Script
# Easy commands to manage your persistent ROS2 development container

set -e

CONTAINER_NAME="ros2-jazzy-dev"
COMPOSE_SERVICE="ros2-dev"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Docker Compose is available
check_compose() {
    if [ -f "docker-compose.yml" ]; then
        return 0
    else
        return 1
    fi
}

# Setup X11 forwarding
setup_x11() {
    print_status "Setting up X11 forwarding..."
    
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
    if command -v xhost >/dev/null 2>&1; then
        xhost +local:docker >/dev/null 2>&1 || true
    fi
}

# Show container status
status() {
    print_status "Checking container status..."
    
    if check_compose; then
        echo ""
        echo "Docker Compose Status:"
        docker-compose ps
        echo ""
        
        if docker-compose ps --services --filter "status=running" | grep -q "$COMPOSE_SERVICE"; then
            print_success "Container is running"
            echo ""
            echo "To connect: ./manage.sh connect"
            echo "To stop:    ./manage.sh stop"
        else
            print_warning "Container is not running"
            echo ""
            echo "To start: ./manage.sh start"
        fi
    else
        # Check direct Docker container
        if docker ps --format 'table {{.Names}}\t{{.Status}}' | grep -q "^$CONTAINER_NAME"; then
            print_success "Container is running"
            docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep "$CONTAINER_NAME"
        elif docker ps -a --format 'table {{.Names}}\t{{.Status}}' | grep -q "^$CONTAINER_NAME"; then
            print_warning "Container exists but is not running"
            docker ps -a --format 'table {{.Names}}\t{{.Status}}' | grep "$CONTAINER_NAME"
            echo ""
            echo "To start: ./manage.sh start"
        else
            print_warning "Container does not exist"
            echo ""
            echo "To create: ./manage.sh start"
        fi
    fi
}

# Start container
start() {
    setup_x11
    
    if check_compose; then
        print_status "Starting container with Docker Compose..."
        docker-compose up -d
        print_success "Container started successfully"
        echo ""
        echo "To connect: ./manage.sh connect"
    else
        print_status "Starting container with Docker..."
        
        # Check if container exists
        if docker ps -a --format 'table {{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
            print_status "Container exists. Starting it..."
            docker start $CONTAINER_NAME
            print_success "Container started successfully"
        else
            print_error "Container does not exist. Please run './setup.sh' first to create it."
            exit 1
        fi
        echo ""
        echo "To connect: ./manage.sh connect"
    fi
}

# Stop container
stop() {
    if check_compose; then
        print_status "Stopping container with Docker Compose..."
        docker-compose stop
        print_success "Container stopped successfully"
    else
        if docker ps --format 'table {{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
            print_status "Stopping container..."
            docker stop $CONTAINER_NAME
            print_success "Container stopped successfully"
        else
            print_warning "Container is not running"
        fi
    fi
}

# Connect to running container
connect() {
    setup_x11
    
    if check_compose; then
        # Check if container is running
        if docker-compose ps --services --filter "status=running" | grep -q "$COMPOSE_SERVICE"; then
            print_status "Connecting to container..."
            docker-compose exec $COMPOSE_SERVICE /bin/bash
        else
            print_warning "Container is not running. Starting it first..."
            docker-compose up -d
            sleep 2
            print_status "Connecting to container..."
            docker-compose exec $COMPOSE_SERVICE /bin/bash
        fi
    else
        # Check if container is running
        if docker ps --format 'table {{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
            print_status "Connecting to container..."
            docker exec -it $CONTAINER_NAME /bin/bash
        else
            print_warning "Container is not running. Starting it first..."
            docker start $CONTAINER_NAME
            sleep 2
            print_status "Connecting to container..."
            docker exec -it $CONTAINER_NAME /bin/bash
        fi
    fi
}

# Connect with Warp terminal integration (Warpified subshell)
warp() {
    setup_x11
    
    print_status "Connecting with Warp terminal integration..."
    print_status "This will enable Warp's modern IDE features in the container"
    
    if check_compose; then
        # Check if container is running
        if docker-compose ps --services --filter "status=running" | grep -q "$COMPOSE_SERVICE"; then
            print_status "Connecting to Warpified container..."
            # Use docker-compose exec which Warp recognizes as subshell-compatible
            docker-compose exec $COMPOSE_SERVICE bash
        else
            print_warning "Container is not running. Starting it first..."
            docker-compose up -d
            sleep 2
            print_status "Connecting to Warpified container..."
            docker-compose exec $COMPOSE_SERVICE bash
        fi
    else
        # Check if container is running
        if docker ps --format 'table {{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
            print_status "Connecting to Warpified container..."
            # Use docker exec which Warp recognizes as subshell-compatible
            docker exec -it $CONTAINER_NAME bash
        else
            print_warning "Container is not running. Starting it first..."
            docker start $CONTAINER_NAME
            sleep 2
            print_status "Connecting to Warpified container..."
            docker exec -it $CONTAINER_NAME bash
        fi
    fi
}

# Restart container
restart() {
    print_status "Restarting container..."
    stop
    sleep 2
    start
}

# Remove container (careful!)
remove() {
    echo ""
    print_warning "This will PERMANENTLY DELETE the container and all data inside it!"
    print_warning "Your workspace files are safe (they're mounted from host), but any installed packages or config changes inside the container will be lost."
    echo ""
    read -p "Are you sure you want to remove the container? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if check_compose; then
            print_status "Removing container with Docker Compose..."
            docker-compose down
            print_success "Container removed successfully"
        else
            if docker ps -a --format 'table {{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
                print_status "Stopping and removing container..."
                docker stop $CONTAINER_NAME 2>/dev/null || true
                docker rm $CONTAINER_NAME
                print_success "Container removed successfully"
            else
                print_warning "Container does not exist"
            fi
        fi
        echo ""
        echo "To create a new container, run: ./setup.sh"
    else
        print_status "Operation cancelled"
    fi
}

# Show logs
logs() {
    if check_compose; then
        print_status "Showing container logs..."
        docker-compose logs -f $COMPOSE_SERVICE
    else
        if docker ps -a --format 'table {{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
            print_status "Showing container logs..."
            docker logs -f $CONTAINER_NAME
        else
            print_warning "Container does not exist"
        fi
    fi
}

# Show help
help() {
    echo ""
    echo "🐳 ROS2 Docker Container Management"
    echo ""
    echo "Usage: ./manage.sh [command]"
    echo ""
    echo "Commands:"
    echo "  start     - Start the container (create if doesn't exist)"
    echo "  stop      - Stop the container"
    echo "  restart   - Restart the container"
    echo "  connect   - Connect to the running container"
    echo "  warp      - Connect with Warp terminal integration (recommended for Warp users)"
    echo "  status    - Show container status"
    echo "  logs      - Show container logs"
    echo "  remove    - Remove container (DESTRUCTIVE - asks for confirmation)"
    echo "  help      - Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./manage.sh start     # Start container"
    echo "  ./manage.sh warp      # Connect with Warp features (recommended)"
    echo "  ./manage.sh connect   # Connect to container (basic)"
    echo "  ./manage.sh status    # Check if running"
    echo ""
    echo "Quick workflow:"
    echo "  1. ./setup.sh         # Initial setup (run once)"
    echo "  2. ./manage.sh warp    # Connect with Warp features (recommended)"
    echo "  3. ./manage.sh stop    # Stop when done"
    echo "  4. ./manage.sh start   # Start again later"
    echo ""
    echo "💡 Warp Terminal Users:"
    echo "  Use './manage.sh warp' to enable Warp's modern IDE features"
    echo "  (blocks, completions, syntax highlighting) in the container"
    echo ""
}

# Main command handling
case "${1:-help}" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    connect|attach|exec)
        connect
        ;;
    warp|warpify)
        warp
        ;;
    status|ps)
        status
        ;;
    logs)
        logs
        ;;
    remove|rm|delete)
        remove
        ;;
    help|--help|-h)
        help
        ;;
    *)
        print_error "Unknown command: $1"
        help
        exit 1
        ;;
esac
