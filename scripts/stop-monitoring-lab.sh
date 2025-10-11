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

# Step 1: Stop HTTP servers
print_status "Step 1: Stopping HTTP servers..."
# Stop main dashboard server (port 8088)
pkill -f "python3.*http.server.*8088" 2>/dev/null && print_success "Main dashboard server stopped (port 8088)" || print_warning "No main dashboard server found"

# Stop restoration dashboard server (port 8089)
pkill -f "python3.*http.server.*8089" 2>/dev/null && print_success "Restoration dashboard server stopped (port 8089)" || print_warning "No restoration dashboard server found"

# Stop log clear server (port 8090)
pkill -f "python3.*log-clear-server.py" 2>/dev/null && print_success "Log clear server stopped (port 8090)" || print_warning "No log clear server found"

# Force kill any remaining Python HTTP servers on our ports
for port in 8088 8089 8090; do
    PID=$(lsof -ti :$port 2>/dev/null)
    if [ ! -z "$PID" ]; then
        kill -9 $PID 2>/dev/null && print_success "Force killed process on port $port (PID: $PID)" || true
    fi
done

# Step 2: Stop automated remediation system
print_status "Step 2: Stopping automated remediation system..."
if [ -f "./start-automated-remediation.sh" ]; then
    ./start-automated-remediation.sh stop
    print_success "Automated remediation system stopped"
else
    # Fallback: kill webhook receiver directly
    pkill -f "webhook-receiver.py" 2>/dev/null && print_success "Webhook receiver stopped" || print_warning "No webhook receiver found"
fi

# Step 3: Stop SSH tunnels
print_status "Step 3: Stopping SSH tunnels..."
tunnel_count=$(ps aux | grep "ssh.*-L" | grep -v grep | wc -l | tr -d ' ')
if [ "$tunnel_count" -gt 0 ]; then
    pkill -f "ssh.*-L"
    print_success "Stopped $tunnel_count SSH tunnels"
else
    print_warning "No SSH tunnels found"
fi

# Step 4: Stop Docker services
print_status "Step 4: Stopping Docker services..."
if command -v docker-compose >/dev/null 2>&1; then
    docker-compose down
    print_success "Docker services stopped (Prometheus, Grafana, Alertmanager)"
else
    print_warning "docker-compose not found"
fi

# Step 5: Cleanup
print_status "Step 5: Cleaning up..."
# Remove any remaining Python processes
pkill -f "python3.*http.server" 2>/dev/null || true
pkill -f "python3.*log-clear-server" 2>/dev/null || true
pkill -f "webhook-receiver.py" 2>/dev/null || true

# Clean up any temporary files
rm -f .http_server.pid
rm -f /tmp/webhook-receiver.pid

# Final verification - force kill any remaining processes on our ports
for port in 8088 8089 8090 5001; do
    PID=$(lsof -ti :$port 2>/dev/null)
    if [ ! -z "$PID" ]; then
        kill -9 $PID 2>/dev/null && print_success "Force killed remaining process on port $port (PID: $PID)" || true
    fi
done

print_success "Cleanup completed"

echo ""
echo -e "${GREEN}🎉 LAB SHUTDOWN COMPLETE!${NC}"
echo -e "${GREEN}========================${NC}"
echo ""
echo -e "${CYAN}All services have been stopped:${NC}"
echo -e "• Main dashboard server (port 8088)"
echo -e "• Restoration dashboard server (port 8089)"
echo -e "• Log clear server (port 8090)"
echo -e "• Automated remediation system (webhook receiver)"
echo -e "• SSH tunnels (9 tunnels)"
echo -e "• Docker services (Prometheus, Grafana, Alertmanager)"
echo ""
echo -e "${YELLOW}To restart the lab, run: ./restart-monitoring-lab.sh${NC}"
