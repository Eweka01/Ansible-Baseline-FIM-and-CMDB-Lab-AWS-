#!/bin/bash

# 🚀 Dashboard HTTP Server Startup Script
# This script starts the HTTP server for the real-time monitoring dashboard

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Lab directory
LAB_DIR="/Users/osamudiameneweka/Desktop/Ansible Baseline, FIM, and CMDB Lab"
DASHBOARD_PORT=8088

echo -e "${BLUE}🚀 STARTING DASHBOARD HTTP SERVER${NC}"
echo -e "${BLUE}=================================${NC}"
echo ""

# Change to lab directory
cd "$LAB_DIR"

# Function to check if port is in use
check_port() {
    local port=$1
    if lsof -i :$port >/dev/null 2>&1; then
        return 0  # Port is in use
    else
        return 1  # Port is free
    fi
}

# Check if port 8088 is already in use
if check_port $DASHBOARD_PORT; then
    echo -e "${YELLOW}⚠️  Port $DASHBOARD_PORT is already in use.${NC}"
    echo -e "${YELLOW}Checking if it's our dashboard server...${NC}"
    
    # Check if it's our Python HTTP server
    if lsof -i :$DASHBOARD_PORT | grep -q "python3.*http.server"; then
        echo -e "${GREEN}✅ Dashboard HTTP server is already running on port $DASHBOARD_PORT${NC}"
        echo ""
        echo -e "${GREEN}🌐 Your dashboard is available at:${NC}"
        echo -e "${GREEN}   http://localhost:$DASHBOARD_PORT/simple-monitoring-dashboard.html${NC}"
        echo ""
        echo -e "${BLUE}To stop the server, run: pkill -f 'python3.*$DASHBOARD_PORT'${NC}"
        exit 0
    else
        echo -e "${RED}❌ Port $DASHBOARD_PORT is used by another service.${NC}"
        echo -e "${YELLOW}Please stop the service using port $DASHBOARD_PORT and try again.${NC}"
        exit 1
    fi
fi

# Start the HTTP server
echo -e "${BLUE}Starting Python HTTP server on port $DASHBOARD_PORT...${NC}"
python3 -m http.server $DASHBOARD_PORT --bind 127.0.0.1 &

# Get the PID
SERVER_PID=$!

# Wait a moment for the server to start
sleep 2

# Verify the server is running
if check_port $DASHBOARD_PORT; then
    echo -e "${GREEN}✅ Dashboard HTTP server started successfully!${NC}"
    echo -e "${GREEN}   PID: $SERVER_PID${NC}"
    echo -e "${GREEN}   Port: $DASHBOARD_PORT${NC}"
    echo ""
    echo -e "${GREEN}🌐 Your dashboard is now available at:${NC}"
    echo -e "${GREEN}   http://localhost:$DASHBOARD_PORT/simple-monitoring-dashboard.html${NC}"
    echo ""
    echo -e "${BLUE}📊 Dashboard Features:${NC}"
    echo -e "   • Real-time monitoring of all services"
    echo -e "   • Live alerts when services go down"
    echo -e "   • Auto-refresh every 30 seconds"
    echo -e "   • Individual service testing"
    echo -e "   • Live monitoring log with timestamps"
    echo ""
    echo -e "${BLUE}🔧 To stop the server:${NC}"
    echo -e "   pkill -f 'python3.*$DASHBOARD_PORT'"
    echo ""
    echo -e "${BLUE}🧪 Test the dashboard:${NC}"
    echo -e "   curl -I http://localhost:$DASHBOARD_PORT/simple-monitoring-dashboard.html"
    echo ""
    
    # Save PID for cleanup
    echo $SERVER_PID > .dashboard_server.pid
    echo -e "${GREEN}✅ Dashboard server PID saved to .dashboard_server.pid${NC}"
    
else
    echo -e "${RED}❌ Failed to start dashboard HTTP server${NC}"
    exit 1
fi
