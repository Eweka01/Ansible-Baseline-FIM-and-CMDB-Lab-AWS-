#!/bin/bash

# Emergency Recovery: Restart the entire monitoring lab stack
# - Restarts Docker services (Prometheus, Grafana)
# - Re-establishes all SSH tunnels (Node Exporter, FIM, CMDB)
# - Starts/ensures dashboard HTTP server on 8088
# - Verifies endpoints and prints clear status

set -euo pipefail

LAB_DIR="/Users/osamudiameneweka/Desktop/Ansible Baseline, FIM, and CMDB Lab"
KEY="/path/to/your/ssh-key.pem"
DASHBOARD_PORT=8088
RESTORATION_DASHBOARD_PORT=8089
LOG_CLEAR_PORT=8090

# Instance mapping
AL1_IP="REPLACED_IP_1"   # manage-node-1 (Amazon Linux)
UB2_IP="REPLACED_IP_2"    # manage-node-2 (Ubuntu)
UB3_IP="REPLACED_IP_3"     # manage-node-3 (Ubuntu)

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

log "Restarting Docker services (Prometheus + Grafana + Alertmanager)..."
docker-compose up -d

log "Starting automated remediation system..."
if [ -f "./start-automated-remediation.sh" ]; then
  chmod +x ./start-automated-remediation.sh
  if ./start-automated-remediation.sh restart >/dev/null 2>&1; then
    log "✅ Automated remediation system started successfully"
  else
    log "⚠️  Warning: Automated remediation system may not be fully started"
  fi
else
  log "⚠️  Warning: start-automated-remediation.sh not found"
fi

log "Starting SSH tunnels (bind to 0.0.0.0 for Docker access)..."
# Node Exporters
log "  Setting up Node Exporter tunnels..."
ssh -f -N -L 0.0.0.0:9101:localhost:9100 -i "$KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ec2-user@"$AL1_IP" && log "    ✅ Node 1 (9101)" || log "    ❌ Node 1 (9101) failed"
ssh -f -N -L 0.0.0.0:9102:localhost:9100 -i "$KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@"$UB2_IP" && log "    ✅ Node 2 (9102)" || log "    ❌ Node 2 (9102) failed"
ssh -f -N -L 0.0.0.0:9103:localhost:9100 -i "$KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@"$UB3_IP" && log "    ✅ Node 3 (9103)" || log "    ❌ Node 3 (9103) failed"

# FIM agents
log "  Setting up FIM agent tunnels..."
ssh -f -N -L 0.0.0.0:8080:localhost:8080 -i "$KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ec2-user@"$AL1_IP" && log "    ✅ Node 1 FIM (8080)" || log "    ❌ Node 1 FIM (8080) failed"
ssh -f -N -L 0.0.0.0:8082:localhost:8080 -i "$KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@"$UB2_IP" && log "    ✅ Node 2 FIM (8082)" || log "    ❌ Node 2 FIM (8082) failed"
ssh -f -N -L 0.0.0.0:8084:localhost:8080 -i "$KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@"$UB3_IP" && log "    ✅ Node 3 FIM (8084)" || log "    ❌ Node 3 FIM (8084) failed"

# CMDB collectors
log "  Setting up CMDB collector tunnels..."
ssh -f -N -L 0.0.0.0:8081:localhost:8081 -i "$KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ec2-user@"$AL1_IP" && log "    ✅ Node 1 CMDB (8081)" || log "    ❌ Node 1 CMDB (8081) failed"
ssh -f -N -L 0.0.0.0:8083:localhost:8081 -i "$KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@"$UB2_IP" && log "    ✅ Node 2 CMDB (8083)" || log "    ❌ Node 2 CMDB (8083) failed"
ssh -f -N -L 0.0.0.0:8085:localhost:8081 -i "$KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@"$UB3_IP" && log "    ✅ Node 3 CMDB (8085)" || log "    ❌ Node 3 CMDB (8085) failed"

log "Ensuring dashboard HTTP servers..."
# Kill any python http servers on 8088, 8089, and 8090
kill_by_pattern "python3 -m http.server $DASHBOARD_PORT"
kill_by_pattern "python3 -m http.server $RESTORATION_DASHBOARD_PORT"
kill_by_pattern "python3.*log-clear-server.py"

# Start main dashboard server on 8088
if ! port_in_use "$DASHBOARD_PORT"; then
  nohup python3 -m http.server "$DASHBOARD_PORT" --bind 127.0.0.1 >/dev/null 2>&1 &
  log "✅ Started main dashboard server on http://localhost:$DASHBOARD_PORT"
else
  log "⚠️  Main dashboard server already running on :$DASHBOARD_PORT"
fi

# Start restoration monitoring dashboard server on 8089
if ! port_in_use "$RESTORATION_DASHBOARD_PORT"; then
  nohup python3 -m http.server "$RESTORATION_DASHBOARD_PORT" --bind 127.0.0.1 >/dev/null 2>&1 &
  log "✅ Started restoration dashboard server on http://localhost:$RESTORATION_DASHBOARD_PORT"
else
  log "⚠️  Restoration dashboard server already running on :$RESTORATION_DASHBOARD_PORT"
fi

# Start log clear server on 8090
if ! port_in_use "$LOG_CLEAR_PORT"; then
  if [ -f "log-clear-server.py" ]; then
    nohup python3 log-clear-server.py "$LOG_CLEAR_PORT" >/dev/null 2>&1 &
    log "✅ Started log clear server on http://localhost:$LOG_CLEAR_PORT"
  else
    log "⚠️  log-clear-server.py not found, skipping log clear server"
  fi
else
  log "⚠️  Log clear server already running on :$LOG_CLEAR_PORT"
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
echo "- Main Dashboard:        http://localhost:$DASHBOARD_PORT/simple-monitoring-dashboard.html"
echo "- Restoration Dashboard: http://localhost:$RESTORATION_DASHBOARD_PORT/restoration-monitoring-dashboard.html"
echo "- Log Clear Server:      http://localhost:$LOG_CLEAR_PORT"
echo "- Grafana:               http://localhost:3000"
echo "- Prometheus:            http://localhost:9090"
echo "- Tunnels:               $(ps aux | grep 'ssh.*-L' | grep -v grep | wc -l) active"

log "Done. If any endpoint shows 000 or 000, re-run this script once."
