#!/bin/bash
# =============================================================================
# Setup SSH Tunnels for FIM and CMDB Prometheus Metrics
# =============================================================================
#
# This script creates SSH tunnels to expose FIM and CMDB metrics from AWS
# instances to the local machine, enabling Prometheus to scrape the metrics.
#
# Usage: ./setup-fim-cmdb-tunnels.sh
#
# Author: Gabriel Eweka
# Version: 1.0.0
# =============================================================================

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# AWS Instance details (replace with your actual IPs)
MANAGE_NODE_1_IP="REPLACED_IP_1"
MANAGE_NODE_2_IP="REPLACED_IP_2"
MANAGE_NODE_3_IP="REPLACED_IP_3"

# Local ports for FIM and CMDB tunnels
# FIM agents: 8080, 8082, 8084
# CMDB collectors: 8081, 8083, 8085
FIM_LOCAL_PORT_1="8080"
CMDB_LOCAL_PORT_1="8081"
FIM_LOCAL_PORT_2="8082"
CMDB_LOCAL_PORT_2="8083"
FIM_LOCAL_PORT_3="8084"
CMDB_LOCAL_PORT_3="8085"

# Remote ports for FIM and CMDB agents
FIM_REMOTE_PORT="8080"
CMDB_REMOTE_PORT="8081"

# SSH Key path
SSH_KEY="/path/to/your/ssh-key.pem"
SSH_USER_AMAZON="ec2-user"
SSH_USER_UBUNTU="ubuntu"

# Function to kill existing tunnels
kill_existing_tunnels() {
    log_info "Killing existing FIM/CMDB tunnels..."
    
    # Kill FIM tunnels
    pkill -f "ssh.*-L [0-9]*:8080" || true
    pkill -f "ssh.*-L [0-9]*:8082" || true
    pkill -f "ssh.*-L [0-9]*:8084" || true
    
    # Kill CMDB tunnels
    pkill -f "ssh.*-L [0-9]*:8081" || true
    pkill -f "ssh.*-L [0-9]*:8083" || true
    pkill -f "ssh.*-L [0-9]*:8085" || true
    
    sleep 2
}

# Function to create SSH tunnel
create_tunnel() {
    local remote_ip="$1"
    local local_port="$2"
    local remote_port="$3"
    local service_name="$4"
    local ssh_user="$5"
    
    log_info "Creating tunnel for $service_name: $remote_ip:$remote_port -> localhost:$local_port"
    
    ssh -f -N -L "$local_port:localhost:$remote_port" \
        -i "$SSH_KEY" \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o LogLevel=ERROR \
        "$ssh_user@$remote_ip" &
    
    local tunnel_pid=$!
    sleep 2
    
    # Check if tunnel is working
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$local_port/metrics" | grep -q "200"; then
        log_success "$service_name tunnel is working (PID: $tunnel_pid)"
        return 0
    else
        log_warning "$service_name tunnel may not be ready yet"
        return 1
    fi
}

# Function to test tunnels
test_tunnels() {
    log_info "Testing FIM and CMDB tunnels..."
    
    local working_tunnels=0
    local total_tunnels=6
    
    # Test FIM tunnels
    for port in 8080 8082 8084; do
        if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$port/metrics" | grep -q "200"; then
            log_success "FIM tunnel on port $port is working"
            ((working_tunnels++))
        else
            log_warning "FIM tunnel on port $port is not responding"
        fi
    done
    
    # Test CMDB tunnels
    for port in 8081 8083 8085; do
        if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$port/metrics" | grep -q "200"; then
            log_success "CMDB tunnel on port $port is working"
            ((working_tunnels++))
        else
            log_warning "CMDB tunnel on port $port is not responding"
        fi
    done
    
    log_info "Working tunnels: $working_tunnels/$total_tunnels"
    
    if [ $working_tunnels -eq $total_tunnels ]; then
        log_success "All FIM and CMDB tunnels are working!"
        return 0
    else
        log_warning "Some tunnels are not working. Check if agents are running on AWS instances."
        return 1
    fi
}

# Function to test Prometheus targets
test_prometheus_targets() {
    log_info "Testing Prometheus targets..."
    
    # Wait for Prometheus to reload
    sleep 5
    
    # Check FIM targets
    local fim_targets=$(curl -s "http://localhost:9090/api/v1/targets" | python3 -c "
import sys, json
data = json.load(sys.stdin)
fim_targets = [t for t in data['data']['activeTargets'] if 'fim-agents' in t['discoveredLabels'].get('job', '')]
print(f'FIM targets: {len(fim_targets)}')
for target in fim_targets:
    print(f'  {target[\"discoveredLabels\"][\"__address__\"]} - {target[\"health\"]}')
" 2>/dev/null || echo "Error checking FIM targets")
    
    # Check CMDB targets
    local cmdb_targets=$(curl -s "http://localhost:9090/api/v1/targets" | python3 -c "
import sys, json
data = json.load(sys.stdin)
cmdb_targets = [t for t in data['data']['activeTargets'] if 'cmdb-collectors' in t['discoveredLabels'].get('job', '')]
print(f'CMDB targets: {len(cmdb_targets)}')
for target in cmdb_targets:
    print(f'  {target[\"discoveredLabels\"][\"__address__\"]} - {target[\"health\"]}')
" 2>/dev/null || echo "Error checking CMDB targets")
    
    echo "$fim_targets"
    echo "$cmdb_targets"
}

# Main script logic
main() {
    log_info "Setting up SSH tunnels for FIM and CMDB Prometheus metrics..."
    
    # Check if SSH key exists
    if [ ! -f "$SSH_KEY" ]; then
        log_error "SSH key not found: $SSH_KEY"
        exit 1
    fi
    
    log_info "SSH key found: $SSH_KEY"
    
    # Kill existing tunnels
    kill_existing_tunnels
    
    log_info "Creating SSH tunnels for FIM and CMDB agents..."
    
    # Create FIM tunnels
    create_tunnel "$MANAGE_NODE_1_IP" "$FIM_LOCAL_PORT_1" "$FIM_REMOTE_PORT" "FIM-manage-node-1" "$SSH_USER_AMAZON" &
    create_tunnel "$MANAGE_NODE_2_IP" "$FIM_LOCAL_PORT_2" "$FIM_REMOTE_PORT" "FIM-manage-node-2" "$SSH_USER_UBUNTU" &
    create_tunnel "$MANAGE_NODE_3_IP" "$FIM_LOCAL_PORT_3" "$FIM_REMOTE_PORT" "FIM-manage-node-3" "$SSH_USER_UBUNTU" &
    
    # Create CMDB tunnels
    create_tunnel "$MANAGE_NODE_1_IP" "$CMDB_LOCAL_PORT_1" "$CMDB_REMOTE_PORT" "CMDB-manage-node-1" "$SSH_USER_AMAZON" &
    create_tunnel "$MANAGE_NODE_2_IP" "$CMDB_LOCAL_PORT_2" "$CMDB_REMOTE_PORT" "CMDB-manage-node-2" "$SSH_USER_UBUNTU" &
    create_tunnel "$MANAGE_NODE_3_IP" "$CMDB_LOCAL_PORT_3" "$CMDB_REMOTE_PORT" "CMDB-manage-node-3" "$SSH_USER_UBUNTU" &
    
    log_info "Waiting for SSH tunnels to establish..."
    sleep 10
    
    # Test tunnels
    test_tunnels
    
    log_info "Updating Prometheus configuration for FIM and CMDB metrics..."
    
    # Restart Prometheus to pick up new configuration
    log_info "Restarting Prometheus with new configuration..."
    docker compose -f docker-compose.yml restart prometheus
    log_info "Waiting for Prometheus to restart..."
    sleep 10
    
    # Test Prometheus targets
    test_prometheus_targets
    
    log_success "FIM and CMDB SSH tunnel setup completed!"
    
    echo ""
    log_info "📊 Access your FIM and CMDB metrics:"
    echo "  • FIM Metrics (manage-node-1): http://localhost:8080/metrics"
    echo "  • CMDB Metrics (manage-node-1): http://localhost:8081/metrics"
    echo "  • FIM Metrics (manage-node-2): http://localhost:8082/metrics"
    echo "  • CMDB Metrics (manage-node-2): http://localhost:8083/metrics"
    echo "  • FIM Metrics (manage-node-3): http://localhost:8084/metrics"
    echo "  • CMDB Metrics (manage-node-3): http://localhost:8085/metrics"
    echo ""
    log_info "🔍 Prometheus queries to try:"
    echo "  • FIM Events: fim_events_total"
    echo "  • CMDB Collections: cmdb_collections_total"
    echo "  • System Packages: system_packages_total"
    echo "  • FIM Files Monitored: fim_files_monitored"
    echo ""
    log_info "🌐 Access Prometheus: http://localhost:9090"
    log_info "🌐 Access Grafana: http://localhost:3000"
}

# Run main function
main "$@"
