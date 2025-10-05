#!/bin/bash

# 🚀 Ansible Baseline, FIM, and CMDB Lab - Complete Startup Script
# This script automates the entire lab startup process for demos and interviews

set -e  # Exit on any error

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

echo -e "${PURPLE}🚀 ANSIBLE BASELINE, FIM, AND CMDB LAB STARTUP${NC}"
echo -e "${PURPLE}===============================================${NC}"
echo ""
echo -e "${CYAN}This script will start your complete monitoring lab:${NC}"
echo -e "• Docker services (Prometheus + Grafana)"
echo -e "• SSH tunnels to AWS instances"
echo -e "• HTTP server for dashboard"
echo -e "• Verification of all services"
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

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to check if a port is in use
check_port() {
    local port=$1
    if lsof -i :$port >/dev/null 2>&1; then
        return 0  # Port is in use
    else
        return 1  # Port is free
    fi
}

# Function to wait for service to be ready
wait_for_service() {
    local url=$1
    local service_name=$2
    local max_attempts=30
    local attempt=1
    
    print_status "Waiting for $service_name to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "$url" >/dev/null 2>&1; then
            print_success "$service_name is ready!"
            return 0
        fi
        
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    print_error "$service_name failed to start after $max_attempts attempts"
    return 1
}

# Step 1: Change to lab directory
print_status "Step 1: Navigating to lab directory..."
cd "$LAB_DIR"
print_success "Changed to lab directory: $LAB_DIR"

# Step 2: Start Docker services
print_status "Step 2: Starting Docker services (Prometheus + Grafana)..."
if command -v docker-compose >/dev/null 2>&1; then
    docker-compose up -d
    print_success "Docker services started"
else
    print_error "docker-compose not found. Please install Docker Compose."
    exit 1
fi

# Step 3: Wait for Docker services to be ready
print_status "Step 3: Waiting for Docker services to be ready..."
wait_for_service "http://localhost:3000/api/health" "Grafana"
wait_for_service "http://localhost:9090/api/v1/status/config" "Prometheus"

# Step 4: Start SSH tunnels
print_status "Step 4: Starting SSH tunnels to AWS instances..."
if [ -f "./setup-ssh-tunnel-monitoring.sh" ]; then
    ./setup-ssh-tunnel-monitoring.sh
    print_success "SSH tunnels started"
else
    print_warning "SSH tunnel script not found. Starting manually..."
    
    # Kill existing tunnels
    pkill -f "ssh.*-L" 2>/dev/null || true
    
    # Start Node Exporter tunnels
    ssh -f -N -L 9101:localhost:9100 -i /Users/osamudiameneweka/Desktop/key-p3.pem ec2-user@18.234.152.228
    ssh -f -N -L 9102:localhost:9100 -i /Users/osamudiameneweka/Desktop/key-p3.pem ubuntu@54.242.234.69
    ssh -f -N -L 9103:localhost:9100 -i /Users/osamudiameneweka/Desktop/key-p3.pem ubuntu@13.217.82.23
    
    # Start FIM Agent tunnels
    ssh -f -N -L 8080:localhost:8080 -i /Users/osamudiameneweka/Desktop/key-p3.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ec2-user@18.234.152.228
    ssh -f -N -L 8082:localhost:8080 -i /Users/osamudiameneweka/Desktop/key-p3.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@54.242.234.69
    ssh -f -N -L 8084:localhost:8080 -i /Users/osamudiameneweka/Desktop/key-p3.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@13.217.82.23
    
    # Start CMDB Collector tunnels
    ssh -f -N -L 8081:localhost:8081 -i /Users/osamudiameneweka/Desktop/key-p3.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ec2-user@18.234.152.228
    ssh -f -N -L 8083:localhost:8081 -i /Users/osamudiameneweka/Desktop/key-p3.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@54.242.234.69
    ssh -f -N -L 8085:localhost:8081 -i /Users/osamudiameneweka/Desktop/key-p3.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@13.217.82.23
    
    print_success "SSH tunnels started manually"
fi

# Step 5: Wait for SSH tunnels to be ready
print_status "Step 5: Waiting for SSH tunnels to be ready..."
sleep 5

# Step 6: Start HTTP server for dashboard
print_status "Step 6: Starting HTTP server for dashboard..."
if check_port 8088; then
    print_warning "Port 8088 is already in use. Killing existing process..."
    pkill -f "python3.*8088" 2>/dev/null || true
    sleep 2
fi

python3 -m http.server 8088 --bind 127.0.0.1 &
HTTP_SERVER_PID=$!
print_success "HTTP server started on port 8088 (PID: $HTTP_SERVER_PID)"

# Step 7: Wait for HTTP server to be ready
print_status "Step 7: Waiting for HTTP server to be ready..."
wait_for_service "http://localhost:8088/simple-monitoring-dashboard.html" "Dashboard HTTP Server"

# Step 8: Verify all services
print_status "Step 8: Verifying all services..."

# Check Docker services
echo -e "\n${CYAN}🐳 Docker Services:${NC}"
if curl -s -f "http://localhost:3000/api/health" >/dev/null 2>&1; then
    print_success "Grafana: http://localhost:3000"
else
    print_error "Grafana: Not responding"
fi

if curl -s -f "http://localhost:9090/api/v1/status/config" >/dev/null 2>&1; then
    print_success "Prometheus: http://localhost:9090"
else
    print_error "Prometheus: Not responding"
fi

# Check SSH tunnels
echo -e "\n${CYAN}🔗 SSH Tunnels:${NC}"
tunnel_count=$(ps aux | grep "ssh.*-L" | grep -v grep | wc -l | tr -d ' ')
if [ "$tunnel_count" -ge 9 ]; then
    print_success "SSH Tunnels: $tunnel_count active"
else
    print_warning "SSH Tunnels: $tunnel_count active (expected 9)"
fi

# Check metrics endpoints
echo -e "\n${CYAN}📊 Metrics Endpoints:${NC}"
for port in 9101 9102 9103 8080 8081 8082 8083 8084 8085; do
    if curl -s -f "http://localhost:$port/metrics" >/dev/null 2>&1; then
        print_success "Port $port: Metrics available"
    else
        print_error "Port $port: Not responding"
    fi
done

# Check Prometheus targets
echo -e "\n${CYAN}🎯 Prometheus Targets:${NC}"
targets_response=$(curl -s "http://localhost:9090/api/v1/targets" 2>/dev/null)
if [ $? -eq 0 ]; then
    target_count=$(echo "$targets_response" | jq '.data.activeTargets | length' 2>/dev/null || echo "unknown")
    print_success "Prometheus Targets: $target_count active"
else
    print_error "Prometheus Targets: Unable to query"
fi

# Check FIM and CMDB metrics
echo -e "\n${CYAN}🔒 FIM & CMDB Metrics:${NC}"
fim_response=$(curl -s "http://localhost:9090/api/v1/query?query=fim_events_total" 2>/dev/null)
if [ $? -eq 0 ]; then
    fim_count=$(echo "$fim_response" | jq '.data.result | length' 2>/dev/null || echo "unknown")
    print_success "FIM Events: $fim_count metrics"
else
    print_error "FIM Events: Unable to query"
fi

cmdb_response=$(curl -s "http://localhost:9090/api/v1/query?query=cmdb_collections_total" 2>/dev/null)
if [ $? -eq 0 ]; then
    cmdb_count=$(echo "$cmdb_response" | jq '.data.result | length' 2>/dev/null || echo "unknown")
    print_success "CMDB Collections: $cmdb_count metrics"
else
    print_error "CMDB Collections: Unable to query"
fi

# Step 9: Display access information
echo -e "\n${GREEN}🎉 LAB STARTUP COMPLETE!${NC}"
echo -e "${GREEN}========================${NC}"
echo ""
echo -e "${CYAN}📊 Access Your Monitoring Stack:${NC}"
echo -e "• ${YELLOW}Real-Time Dashboard:${NC} http://localhost:8088/simple-monitoring-dashboard.html"
echo -e "• ${YELLOW}Grafana:${NC} http://localhost:3000 (admin/admin)"
echo -e "• ${YELLOW}Prometheus:${NC} http://localhost:9090"
echo -e "• ${YELLOW}Prometheus Targets:${NC} http://localhost:9090/targets"
echo ""
echo -e "${CYAN}🔧 Management Commands:${NC}"
echo -e "• ${YELLOW}Stop all services:${NC} ./stop-monitoring-lab.sh"
echo -e "• ${YELLOW}Restart tunnels:${NC} ./manage-tunnels.sh restart"
echo -e "• ${YELLOW}Check status:${NC} ./manage-tunnels.sh status"
echo ""
echo -e "${CYAN}🧪 Testing Commands:${NC}"
echo -e "• ${YELLOW}Test FIM metrics:${NC} curl -s http://localhost:8080/metrics | grep fim_events_total"
echo -e "• ${YELLOW}Test CMDB metrics:${NC} curl -s http://localhost:8081/metrics | grep cmdb_collections_total"
echo -e "• ${YELLOW}Test Prometheus:${NC} curl -s 'http://localhost:9090/api/v1/query?query=up'"
echo ""
echo -e "${GREEN}✅ Your production-grade monitoring lab is now running!${NC}"
echo -e "${GREEN}🚀 Ready for demos and interviews!${NC}"

# Save PID for cleanup script
echo $HTTP_SERVER_PID > .http_server.pid

echo ""
echo -e "${PURPLE}Press Ctrl+C to stop all services, or run ./stop-monitoring-lab.sh${NC}"
