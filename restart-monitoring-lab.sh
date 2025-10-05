#!/bin/bash

# Emergency Recovery: Restart the entire monitoring lab stack
# - Restarts Docker services (Prometheus, Grafana)
# - Re-establishes all SSH tunnels (Node Exporter, FIM, CMDB)
# - Starts/ensures dashboard HTTP server on 8088
# - Verifies endpoints and prints clear status

set -euo pipefail

LAB_DIR="/Users/osamudiameneweka/Desktop/Ansible Baseline, FIM, and CMDB Lab"
KEY="/Users/osamudiameneweka/Desktop/key-p3.pem"
DASHBOARD_PORT=8088

# Instance mapping
AL1_IP="18.234.152.228"   # manage-node-1 (Amazon Linux)
UB2_IP="54.242.234.69"    # manage-node-2 (Ubuntu)
UB3_IP="13.217.82.23"     # manage-node-3 (Ubuntu)

# Helpers
log() { echo -e "[$(date '+%H:%M:%S')] $*"; }
port_in_use() { lsof -i :"$1" -sTCP:LISTEN >/dev/null 2>&1; }
kill_by_pattern() { pkill -f "$1" >/dev/null 2>&1 || true; }

cd "$LAB_DIR"

log "Stopping existing SSH tunnels (if any)..."
kill_by_pattern "ssh.*-L 9101:"
kill_by_pattern "ssh.*-L 9102:"
kill_by_pattern "ssh.*-L 9103:"
kill_by_pattern "ssh.*-L 8080:"
kill_by_pattern "ssh.*-L 8082:"
kill_by_pattern "ssh.*-L 8084:"
kill_by_pattern "ssh.*-L 8081:"
kill_by_pattern "ssh.*-L 8083:"
kill_by_pattern "ssh.*-L 8085:"

log "Restarting Docker services (Prometheus + Grafana)..."
docker-compose up -d

log "Starting SSH tunnels (bind to 0.0.0.0 for Docker access)..."
# Node Exporters
ssh -f -N -L 0.0.0.0:9101:localhost:9100 -i "$KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ec2-user@"$AL1_IP"
ssh -f -N -L 0.0.0.0:9102:localhost:9100 -i "$KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@"$UB2_IP"
ssh -f -N -L 0.0.0.0:9103:localhost:9100 -i "$KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@"$UB3_IP"
# FIM agents
ssh -f -N -L 0.0.0.0:8080:localhost:8080 -i "$KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ec2-user@"$AL1_IP"
ssh -f -N -L 0.0.0.0:8082:localhost:8080 -i "$KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@"$UB2_IP"
ssh -f -N -L 0.0.0.0:8084:localhost:8080 -i "$KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@"$UB3_IP"
# CMDB collectors
ssh -f -N -L 0.0.0.0:8081:localhost:8081 -i "$KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ec2-user@"$AL1_IP"
ssh -f -N -L 0.0.0.0:8083:localhost:8081 -i "$KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@"$UB2_IP"
ssh -f -N -L 0.0.0.0:8085:localhost:8081 -i "$KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@"$UB3_IP"

log "Ensuring dashboard HTTP server on :$DASHBOARD_PORT..."
# Kill any python http server on 8088
kill_by_pattern "python3 -m http.server $DASHBOARD_PORT"
if ! port_in_use "$DASHBOARD_PORT"; then
  nohup python3 -m http.server "$DASHBOARD_PORT" --bind 127.0.0.1 >/dev/null 2>&1 &
  log "Started dashboard server on http://localhost:$DASHBOARD_PORT"
else
  log "Dashboard server already running on :$DASHBOARD_PORT"
fi

log "Waiting for services to stabilize..."
sleep 8

log "Verifying key endpoints (HTTP codes expected: 200/302/401/405)..."
check() {
  local url="$1"
  code=$(curl -s -o /dev/null -w "%{http_code}" "$url" || true)
  printf "%-50s %s\n" "$url" "$code"
}
check http://localhost:3000
check http://localhost:9090/api/v1/status/config
check http://localhost:9101/metrics
check http://localhost:9102/metrics
check http://localhost:9103/metrics
check http://localhost:8080/metrics
check http://localhost:8082/metrics
check http://localhost:8084/metrics
check http://localhost:8081/metrics
check http://localhost:8083/metrics
check http://localhost:8085/metrics

log "Summary:"
echo "- Dashboard:   http://localhost:$DASHBOARD_PORT/simple-monitoring-dashboard.html"
echo "- Grafana:     http://localhost:3000"
echo "- Prometheus:  http://localhost:9090"
echo "- Tunnels:     $(ps aux | grep 'ssh.*-L' | grep -v grep | wc -l) active"

log "Done. If any endpoint shows 000 or 000, re-run this script once."
