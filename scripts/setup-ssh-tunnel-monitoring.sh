#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

echo -e "${CYAN}🔧 SSH TUNNEL MONITORING SETUP${NC}"
echo -e "${CYAN}==============================${NC}\n"

# Check if SSH key exists
SSH_KEY="$HOME/Desktop/key-p3.pem"
if [ ! -f "$SSH_KEY" ]; then
    log_error "SSH key not found at $SSH_KEY"
    exit 1
fi

log_info "SSH key found: $SSH_KEY"

# Set correct permissions for SSH key
chmod 600 "$SSH_KEY"

# Kill existing SSH tunnels
log_info "Killing existing SSH tunnels..."
pkill -f "ssh.*9100" 2>/dev/null || true
sleep 2

# Create SSH tunnels for each instance
log_info "Creating SSH tunnels for AWS instances..."

# Instance 1: manage-node-1 (Amazon Linux)
log_info "Setting up tunnel for manage-node-1 (REPLACED_IP_1:9100 -> localhost:9101)"
ssh -f -N -L 9101:localhost:9100 -i "$SSH_KEY" ec2-user@REPLACED_IP_1 &
TUNNEL1_PID=$!

# Instance 2: manage-node-2 (Ubuntu)
log_info "Setting up tunnel for manage-node-2 (REPLACED_IP_2:9100 -> localhost:9102)"
ssh -f -N -L 9102:localhost:9100 -i "$SSH_KEY" ubuntu@REPLACED_IP_2 &
TUNNEL2_PID=$!

# Instance 3: manage-node-3 (Ubuntu)
log_info "Setting up tunnel for manage-node-3 (REPLACED_IP_3:9100 -> localhost:9103)"
ssh -f -N -L 9103:localhost:9100 -i "$SSH_KEY" ubuntu@REPLACED_IP_3 &
TUNNEL3_PID=$!

# Wait for tunnels to establish
log_info "Waiting for SSH tunnels to establish..."
sleep 5

# Test tunnels
log_info "Testing SSH tunnels..."

test_tunnel() {
    local port=$1
    local instance=$2
    if curl -s http://localhost:$port/metrics | head -1 >/dev/null 2>&1; then
        log_success "Tunnel to $instance (port $port) is working"
        return 0
    else
        log_warning "Tunnel to $instance (port $port) is not working"
        return 1
    fi
}

test_tunnel 9101 "manage-node-1"
test_tunnel 9102 "manage-node-2"
test_tunnel 9103 "manage-node-3"

# Update Prometheus configuration
log_info "Updating Prometheus configuration for SSH tunnels..."

cat > prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'aws-nodes'
    scrape_interval: 15s
    static_configs:
      - targets:
          - 'host.docker.internal:9101'  # manage-node-1 via SSH tunnel
          - 'host.docker.internal:9102'  # manage-node-2 via SSH tunnel
          - 'host.docker.internal:9103'  # manage-node-3 via SSH tunnel
    metrics_path: /metrics
EOF

# Restart Prometheus
log_info "Restarting Prometheus with new configuration..."
docker compose -f docker-compose.yml restart prometheus

# Wait for Prometheus to restart
log_info "Waiting for Prometheus to restart..."
sleep 10

# Test Prometheus targets
log_info "Testing Prometheus targets..."
curl -s http://localhost:9090/api/v1/targets | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print('Target Status:')
    for target in data['data']['activeTargets']:
        address = target['discoveredLabels']['__address__']
        health = target['health']
        status = '✅ UP' if health == 'up' else '❌ DOWN' if health == 'down' else '⚠️ UNKNOWN'
        print(f'  {address} - {status}')
except Exception as e:
    print(f'Error checking targets: {e}')
"

# Create tunnel management script
log_info "Creating tunnel management script..."

cat > manage-tunnels.sh << 'EOF'
#!/bin/bash

case "$1" in
    start)
        echo "Starting SSH tunnels..."
        ./setup-ssh-tunnel-monitoring.sh
        ;;
    stop)
        echo "Stopping SSH tunnels..."
        pkill -f "ssh.*910[0-9]"
        echo "SSH tunnels stopped"
        ;;
    status)
        echo "SSH Tunnel Status:"
        ps aux | grep "ssh.*910[0-9]" | grep -v grep || echo "No tunnels running"
        ;;
    restart)
        echo "Restarting SSH tunnels..."
        pkill -f "ssh.*910[0-9]"
        sleep 2
        ./setup-ssh-tunnel-monitoring.sh
        ;;
    *)
        echo "Usage: $0 {start|stop|status|restart}"
        exit 1
        ;;
esac
EOF

chmod +x manage-tunnels.sh

log_success "SSH tunnel monitoring setup completed!"
echo ""
log_info "📊 ACCESS YOUR MONITORING:"
echo "   • Prometheus: http://localhost:9090"
echo "   • Grafana: http://localhost:3000 (admin/admin)"
echo "   • Lab Dashboard: http://localhost:8080/simple-monitoring-dashboard.html"
echo ""
log_info "🔧 TUNNEL MANAGEMENT:"
echo "   • Start tunnels: ./manage-tunnels.sh start"
echo "   • Stop tunnels: ./manage-tunnels.sh stop"
echo "   • Check status: ./manage-tunnels.sh status"
echo "   • Restart tunnels: ./manage-tunnels.sh restart"
echo ""
log_info "🧪 TEST PROMETHEUS QUERIES:"
echo "   • node_cpu_seconds_total"
echo "   • node_memory_MemAvailable_bytes"
echo "   • node_filesystem_size_bytes"
echo ""
log_success "Your Prometheus should now have working targets!"
