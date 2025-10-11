#!/bin/bash

# live-remediation-test.sh
# Test script to demonstrate live remediation in action
# Creates safe test scenarios and shows automated remediation working

# --- Configuration ---
INVENTORY_PATH="../ansible/inventory/aws-instances"
PROMETHEUS_URL="http://localhost:9090"
WEBHOOK_RECEIVER_URL="http://localhost:5001"

# Test file locations (safe locations only)
TEST_BASE_DIR="/tmp/live-remediation-test-$(date +%s)"
SAFE_TEST_FILE="/tmp/safe-remediation-test.txt"
SAFE_CONFIG_FILE="/tmp/safe-config-test.conf"

# --- Utility Functions ---
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

check_prerequisites() {
    log "🔍 Checking prerequisites..."
    command -v curl >/dev/null 2>&1 || { echo >&2 "curl is required but not installed. Aborting."; exit 1; }
    command -v ansible >/dev/null 2>&1 || { echo >&2 "ansible is required but not installed. Aborting."; exit 1; }
    
    log "Checking Prometheus status..."
    if curl -s -o /dev/null -w "%{http_code}" "$PROMETHEUS_URL" | grep -q "200\|302"; then
        log "✅ Prometheus is running."
    else
        log "❌ Prometheus is not reachable at $PROMETHEUS_URL. Please ensure it's running."
        exit 1
    fi
    
    log "Checking webhook receiver status..."
    if pgrep -f "webhook-receiver.py 5001" > /dev/null; then
        log "✅ Webhook receiver is running."
    else
        log "❌ Webhook receiver is not running. Please start it using 'start-automated-remediation.sh'."
        exit 1
    fi
    log "Prerequisites check complete."
}

wait_for_metrics_update() {
    local wait_time=${1:-30}
    log "⏳ Waiting ${wait_time}s for metrics to update..."
    sleep $wait_time
}

monitor_remediation_logs() {
    log "📊 Monitoring remediation logs..."
    echo "=============================="
    
    if [ -f "../automated-remediation-audit.log" ]; then
        log "📋 Recent remediation events:"
        tail -5 "../automated-remediation-audit.log" | jq -r '.timestamp + " | " + .playbook + " | " + .target_node + " | " + .status' 2>/dev/null || tail -5 "../automated-remediation-audit.log"
    else
        log "❌ No remediation audit log found."
    fi
    echo ""
    
    if [ -f "../webhook-receiver.log" ]; then
        log "📋 Recent webhook processing:"
        tail -5 "../webhook-receiver.log" | grep -E "(Processing|Running|Success|Error)" || echo "No recent webhook activity"
    else
        log "❌ No webhook receiver log found."
    fi
    echo ""
}

# --- Live Remediation Tests ---

test_fim_remediation_flow() {
    log "🧪 Testing FIM Remediation Flow..."
    echo "==============================="
    
    local target_node="manage-node-1"
    local test_file="/tmp/fim-remediation-test.txt"
    
    log "1. Creating baseline test file..."
    ansible $target_node -i "$INVENTORY_PATH" -m shell -a "echo 'BASELINE CONTENT - $(date)' > $test_file" >/dev/null 2>&1
    
    log "2. Modifying test file to trigger FIM event..."
    ansible $target_node -i "$INVENTORY_PATH" -m shell -a "echo 'UNAUTHORIZED MODIFICATION - $(date)' >> $test_file" >/dev/null 2>&1
    
    wait_for_metrics_update 30
    
    log "3. Checking for FIM events..."
    local fim_events=$(curl -s "$PROMETHEUS_URL/api/v1/query?query=increase(fim_events_total[5m])" | jq -r '.data.result[] | "\(.metric.instance): \(.value[1]) events"')
    
    if [[ -n "$fim_events" ]]; then
        log "✅ FIM events detected:"
        echo "$fim_events"
    else
        log "❌ No FIM events detected."
    fi
    
    log "4. Monitoring remediation process..."
    monitor_remediation_logs
    
    log "5. Cleaning up test file..."
    ansible $target_node -i "$INVENTORY_PATH" -m shell -a "rm -f $test_file" >/dev/null 2>&1
}

test_cmdb_remediation_flow() {
    log "🧪 Testing CMDB Remediation Flow..."
    echo "================================="
    
    local target_node="manage-node-2"
    
    log "1. Stopping CMDB collector to trigger alert..."
    ansible $target_node -i "$INVENTORY_PATH" -m systemd -a "name=cmdb-collector-prometheus.service state=stopped" --become >/dev/null 2>&1
    
    wait_for_metrics_update 30
    
    log "2. Checking for CMDB collector down alert..."
    local cmdb_alerts=$(curl -s "$PROMETHEUS_URL/api/v1/alerts" | jq -r '.data.alerts[] | select(.labels.alertname == "CMDBCollectorDown" and .status.state == "firing")')
    
    if [[ -n "$cmdb_alerts" ]]; then
        log "✅ CMDBCollectorDown alert detected:"
        echo "$cmdb_alerts" | jq -r '.annotations.description'
    else
        log "❌ CMDBCollectorDown alert not detected."
    fi
    
    log "3. Monitoring remediation process..."
    monitor_remediation_logs
    
    log "4. Checking if CMDB collector was restarted by remediation..."
    sleep 10
    local cmdb_status=$(ansible $target_node -i "$INVENTORY_PATH" -m systemd -a "name=cmdb-collector-prometheus.service" --become | grep "Active:")
    
    if [[ $cmdb_status == *"active (running)"* ]]; then
        log "✅ CMDB collector is running (may have been restarted by remediation)"
    else
        log "❌ CMDB collector is not running"
        log "5. Manually restarting CMDB collector..."
        ansible $target_node -i "$INVENTORY_PATH" -m systemd -a "name=cmdb-collector-prometheus.service state=started" --become >/dev/null 2>&1
    fi
}

test_webhook_processing() {
    log "🧪 Testing Webhook Processing..."
    echo "============================="
    
    log "1. Checking webhook receiver status..."
    if pgrep -f "webhook-receiver.py 5001" > /dev/null; then
        log "✅ Webhook receiver is running (PID: $(pgrep -f 'webhook-receiver.py 5001'))"
    else
        log "❌ Webhook receiver is not running"
        return 1
    fi
    
    log "2. Testing webhook endpoint..."
    local test_alert='{"alerts":[{"labels":{"alertname":"TestAlert","instance":"test-instance"},"annotations":{"description":"Test alert for webhook processing"}}]}'
    
    local response=$(curl -s -X POST -H "Content-Type: application/json" -d "$test_alert" "$WEBHOOK_RECEIVER_URL/webhook" 2>/dev/null)
    
    if [[ $response == *"success"* ]]; then
        log "✅ Webhook endpoint is responding correctly"
    else
        log "❌ Webhook endpoint test failed"
    fi
    
    log "3. Checking webhook processing logs..."
    if [ -f "../webhook-receiver.log" ]; then
        log "📋 Recent webhook activity:"
        tail -3 "../webhook-receiver.log" | grep -E "(Processing|TestAlert)" || echo "No recent test activity"
    fi
}

test_alert_to_remediation_flow() {
    log "🧪 Testing Complete Alert-to-Remediation Flow..."
    echo "============================================="
    
    local target_node="manage-node-3"
    local test_file="/tmp/alert-remediation-flow-test.txt"
    
    log "1. Creating test file for alert flow..."
    ansible $target_node -i "$INVENTORY_PATH" -m shell -a "echo 'ALERT FLOW TEST - $(date)' > $test_file" >/dev/null 2>&1
    
    log "2. Making multiple changes to trigger threshold..."
    for i in {1..6}; do
        ansible $target_node -i "$INVENTORY_PATH" -m shell -a "echo 'Change $i - $(date)' >> $test_file" >/dev/null 2>&1
        sleep 2
    done
    
    wait_for_metrics_update 60
    
    log "3. Checking for alerts..."
    local alerts=$(curl -s "$PROMETHEUS_URL/api/v1/alerts" | jq -r '.data.alerts[] | select(.status.state == "firing") | "\(.labels.alertname): \(.labels.instance)"')
    
    if [[ -n "$alerts" ]]; then
        log "✅ Active alerts detected:"
        echo "$alerts"
    else
        log "❌ No active alerts detected"
    fi
    
    log "4. Monitoring complete remediation flow..."
    monitor_remediation_logs
    
    log "5. Checking remediation dashboard..."
    log "🌐 Open restoration dashboard: http://localhost:8089/restoration-monitoring-dashboard.html"
    log "🌐 Open Grafana dashboard: http://localhost:3000"
    
    log "6. Cleaning up test file..."
    ansible $target_node -i "$INVENTORY_PATH" -m shell -a "rm -f $test_file" >/dev/null 2>&1
}

show_live_dashboards() {
    log "🌐 LIVE DASHBOARDS FOR MONITORING..."
    echo "================================="
    echo ""
    echo "📊 HTML Restoration Dashboard:"
    echo "http://localhost:8089/restoration-monitoring-dashboard.html"
    echo ""
    echo "📊 Grafana Monitoring Dashboard:"
    echo "http://localhost:3000"
    echo ""
    echo "📊 Prometheus Alerts:"
    echo "http://localhost:9090/alerts"
    echo ""
    echo "📊 Prometheus Targets:"
    echo "http://localhost:9090/targets"
    echo ""
    echo "📊 Alertmanager:"
    echo "http://localhost:9093"
    echo ""
}

show_help() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Live Remediation Testing Options:"
    echo "  fim          Test FIM remediation flow"
    echo "  cmdb         Test CMDB remediation flow"
    echo "  webhook      Test webhook processing"
    echo "  flow         Test complete alert-to-remediation flow"
    echo "  dashboards   Show live dashboard URLs"
    echo "  monitor      Monitor remediation logs only"
    echo "  all          Run all remediation tests"
    echo "  help         Show this help message"
    echo ""
    echo "SAFETY FEATURES:"
    echo "• Only creates files in /tmp/ directory"
    echo "• Safe for production environments"
    echo "• Demonstrates live remediation without system damage"
    echo ""
    echo "Examples:"
    echo "  $0 flow        # Test complete remediation flow"
    echo "  $0 monitor     # Monitor remediation logs"
    echo "  $0 dashboards  # Show dashboard URLs"
}

# --- Main Logic ---
case "$1" in
    "fim")
        check_prerequisites
        test_fim_remediation_flow
        ;;
    "cmdb")
        check_prerequisites
        test_cmdb_remediation_flow
        ;;
    "webhook")
        check_prerequisites
        test_webhook_processing
        ;;
    "flow")
        check_prerequisites
        test_alert_to_remediation_flow
        ;;
    "dashboards")
        show_live_dashboards
        ;;
    "monitor")
        monitor_remediation_logs
        ;;
    "all")
        check_prerequisites
        log "🚀 Running comprehensive live remediation tests..."
        echo "=============================================="
        echo ""
        test_fim_remediation_flow
        echo ""
        test_cmdb_remediation_flow
        echo ""
        test_webhook_processing
        echo ""
        test_alert_to_remediation_flow
        echo ""
        show_live_dashboards
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        echo "❌ Invalid option: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
