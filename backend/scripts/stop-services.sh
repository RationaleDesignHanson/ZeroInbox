#!/bin/bash

# Script to cleanly stop all Zero backend services

set -e

echo "🛑 Stopping Zero Backend Services"
echo "=================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

BACKEND_DIR="/Users/matthanson/EmailShortForm_01/backend"
PID_DIR="$BACKEND_DIR/pids"

# Function to stop service by PID file
stop_service_by_pid() {
    local pid_file=$1
    local service_name=$2

    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if ps -p $pid > /dev/null 2>&1; then
            echo -n "   Stopping $service_name (PID: $pid)..."
            kill $pid 2>/dev/null || kill -9 $pid 2>/dev/null || true
            sleep 1
            if ps -p $pid > /dev/null 2>&1; then
                kill -9 $pid 2>/dev/null || true
            fi
            echo -e " ${GREEN}✓${NC}"
        else
            echo -e "   ${YELLOW}⚠️  $service_name (PID: $pid) not running${NC}"
        fi
        rm -f "$pid_file"
    fi
}

# Stop services using PID files
if [ -d "$PID_DIR" ]; then
    stop_service_by_pid "$PID_DIR/backend.pid" "Core Backend Services"
    stop_service_by_pid "$PID_DIR/smart-replies.pid" "Smart Replies"
    stop_service_by_pid "$PID_DIR/shopping-agent.pid" "Shopping Agent"
    stop_service_by_pid "$PID_DIR/steel-agent.pid" "Steel Agent"
fi

# Kill any remaining processes on our ports
echo ""
echo "Cleaning up any remaining processes..."
lsof -ti:3001,8081,8082,8083,8084,8085,8087 | xargs kill -9 2>/dev/null || true

# Kill any npm/node service processes
pkill -9 -f "npm.*start:all" 2>/dev/null || true
pkill -9 -f "node.*gateway/server" 2>/dev/null || true
pkill -9 -f "node.*services/email" 2>/dev/null || true
pkill -9 -f "node.*services/classifier" 2>/dev/null || true
pkill -9 -f "node.*services/summarization" 2>/dev/null || true
pkill -9 -f "node.*services/smart-replies" 2>/dev/null || true
pkill -9 -f "node.*services/shopping-agent" 2>/dev/null || true
pkill -9 -f "node.*services/steel-agent" 2>/dev/null || true

sleep 1

echo -e "${GREEN}✓${NC} All services stopped"
echo ""
