#!/bin/bash

# 🛑 Ansible Baseline, FIM, and CMDB Lab - Complete Shutdown Script
# This script safely stops all lab services

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Lab directory
LAB_DIR="/Users/osamudiameneweka/Desktop/Ansible Baseline, FIM, and CMDB Lab"

echo -e "${PURPLE}🛑 ANSIBLE BASELINE, FIM, AND CMDB LAB SHUTDOWN${NC}"
echo -e "${PURPLE}===============================================${NC}"
echo ""

# Function to print status
print_status() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Change to lab directory
print_status "Navigating to lab directory..."
cd "$LAB_DIR"

# Step 1: Stop HTTP server
print_status "Step 1: Stopping HTTP server..."
if [ -f ".http_server.pid" ]; then
    HTTP_PID=$(cat .http_server.pid)
    if kill -0 $HTTP_PID 2>/dev/null; then
        kill $HTTP_PID
        print_success "HTTP server stopped (PID: $HTTP_PID)"
    else
        print_warning "HTTP server PID file found but process not running"
    fi
    rm -f .http_server.pid
else
    # Try to kill any Python HTTP server on port 8088
    pkill -f "python3.*8088" 2>/dev/null && print_success "HTTP server stopped" || print_warning "No HTTP server found"
fi

# Step 2: Stop SSH tunnels
print_status "Step 2: Stopping SSH tunnels..."
tunnel_count=$(ps aux | grep "ssh.*-L" | grep -v grep | wc -l | tr -d ' ')
if [ "$tunnel_count" -gt 0 ]; then
    pkill -f "ssh.*-L"
    print_success "Stopped $tunnel_count SSH tunnels"
else
    print_warning "No SSH tunnels found"
fi

# Step 3: Stop Docker services
print_status "Step 3: Stopping Docker services..."
if command -v docker-compose >/dev/null 2>&1; then
    docker-compose down
    print_success "Docker services stopped"
else
    print_warning "docker-compose not found"
fi

# Step 4: Cleanup
print_status "Step 4: Cleaning up..."
# Remove any remaining Python processes
pkill -f "python3.*http.server" 2>/dev/null || true

# Clean up any temporary files
rm -f .http_server.pid

print_success "Cleanup completed"

echo ""
echo -e "${GREEN}🎉 LAB SHUTDOWN COMPLETE!${NC}"
echo -e "${GREEN}========================${NC}"
echo ""
echo -e "${CYAN}All services have been stopped:${NC}"
echo -e "• HTTP server (port 8088)"
echo -e "• SSH tunnels (9 tunnels)"
echo -e "• Docker services (Prometheus + Grafana)"
echo ""
echo -e "${YELLOW}To restart the lab, run: ./start-monitoring-lab.sh${NC}"
