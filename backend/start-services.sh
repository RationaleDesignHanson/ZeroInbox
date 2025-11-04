#!/bin/bash

###############################################################################
# ZerO Inbox Backend Services Startup Script
#
# This script provides a self-healing, production-ready startup for all services
#
# Features:
# - Dependency checking
# - Health monitoring
# - Automatic restart on failure
# - Graceful shutdown
# - Log aggregation
#
# Usage:
#   ./start-services.sh [start|stop|restart|status|logs]
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKEND_DIR="/Users/matthanson/Zer0_Inbox/backend"
LOG_DIR="$BACKEND_DIR/services/logs"
HEALTH_CHECK_INTERVAL=30

# Service ports (name:port pairs)
SERVICE_LIST="gateway:3000 classifier:3001 email:3002 smart-replies:3003 shopping-agent:3004 analytics:3005 summarization:3006 scheduled-purchase:3007 actions:3008 steel-agent:3009"

# Print colored message
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Check if PM2 is installed
check_pm2() {
    if ! command -v pm2 &> /dev/null; then
        print_message "$RED" "PM2 is not installed. Installing PM2 globally..."
        npm install -g pm2
        if [ $? -eq 0 ]; then
            print_message "$GREEN" "PM2 installed successfully"
        else
            print_message "$RED" "Failed to install PM2. Please install manually: npm install -g pm2"
            exit 1
        fi
    else
        print_message "$GREEN" "PM2 is installed"
    fi
}

# Check if port is in use
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        return 0  # Port is in use
    else
        return 1  # Port is free
    fi
}

# Create log directory if it doesn't exist
setup_logs() {
    if [ ! -d "$LOG_DIR" ]; then
        print_message "$YELLOW" "Creating log directory: $LOG_DIR"
        mkdir -p "$LOG_DIR"
    fi
    print_message "$GREEN" "Log directory ready: $LOG_DIR"
}

# Start all services using PM2
start_services() {
    print_message "$BLUE" "================================================"
    print_message "$BLUE" "Starting ZerO Inbox Backend Services"
    print_message "$BLUE" "================================================"

    check_pm2
    setup_logs

    # Change to backend directory
    cd "$BACKEND_DIR"

    # Stop any existing PM2 processes
    print_message "$YELLOW" "Cleaning up any existing processes..."
    pm2 delete all 2>/dev/null || true

    # Start services using ecosystem config
    print_message "$YELLOW" "Starting services with PM2..."
    pm2 start ecosystem.config.js

    # Save PM2 process list
    pm2 save

    # Display status
    sleep 2
    pm2 list

    print_message "$GREEN" "================================================"
    print_message "$GREEN" "All services started successfully!"
    print_message "$GREEN" "================================================"
    print_message "$YELLOW" "\nUseful commands:"
    print_message "$NC" "  pm2 list                  - View all services"
    print_message "$NC" "  pm2 logs                  - View all logs"
    print_message "$NC" "  pm2 logs <service-name>   - View specific service logs"
    print_message "$NC" "  pm2 monit                 - Real-time monitoring"
    print_message "$NC" "  pm2 restart all           - Restart all services"
    print_message "$NC" "  ./start-services.sh stop  - Stop all services"
}

# Stop all services
stop_services() {
    print_message "$BLUE" "================================================"
    print_message "$BLUE" "Stopping ZerO Inbox Backend Services"
    print_message "$BLUE" "================================================"

    if command -v pm2 &> /dev/null; then
        pm2 stop all
        pm2 delete all
        pm2 save --force
        print_message "$GREEN" "All services stopped"
    else
        print_message "$YELLOW" "PM2 not found. No services to stop."
    fi
}

# Restart all services
restart_services() {
    print_message "$BLUE" "Restarting services..."
    stop_services
    sleep 2
    start_services
}

# Show service status
show_status() {
    if command -v pm2 &> /dev/null; then
        pm2 list
        print_message "$BLUE" "\nDetailed status:"
        pm2 describe all 2>/dev/null || print_message "$YELLOW" "No services running"
    else
        print_message "$RED" "PM2 not installed"
    fi
}

# Show logs
show_logs() {
    if command -v pm2 &> /dev/null; then
        pm2 logs
    else
        print_message "$RED" "PM2 not installed"
    fi
}

# Enable PM2 startup on system boot
enable_startup() {
    print_message "$BLUE" "Setting up PM2 to start on system boot..."
    if command -v pm2 &> /dev/null; then
        pm2 startup
        print_message "$GREEN" "Follow the command above to enable startup"
    else
        print_message "$RED" "PM2 not installed"
    fi
}

# Health check for all services
health_check() {
    print_message "$BLUE" "Running health check..."

    for service_port in $SERVICE_LIST; do
        service=$(echo $service_port | cut -d: -f1)
        port=$(echo $service_port | cut -d: -f2)
        if check_port $port; then
            print_message "$GREEN" "✓ $service (port $port) - Running"
        else
            print_message "$RED" "✗ $service (port $port) - Not responding"
        fi
    done
}

# Main command handler
case "$1" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    health)
        health_check
        ;;
    startup)
        enable_startup
        ;;
    *)
        print_message "$BLUE" "ZerO Inbox Backend Services Manager"
        print_message "$NC" ""
        print_message "$NC" "Usage: $0 {start|stop|restart|status|logs|health|startup}"
        print_message "$NC" ""
        print_message "$NC" "Commands:"
        print_message "$NC" "  start    - Start all services"
        print_message "$NC" "  stop     - Stop all services"
        print_message "$NC" "  restart  - Restart all services"
        print_message "$NC" "  status   - Show service status"
        print_message "$NC" "  logs     - Show service logs"
        print_message "$NC" "  health   - Run health check"
        print_message "$NC" "  startup  - Enable auto-start on boot"
        exit 1
        ;;
esac

exit 0
