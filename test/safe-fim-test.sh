#!/bin/bash

# safe-fim-test.sh
# Safe FIM testing script that won't damage the system
# Creates controlled test files in safe locations only

# --- Configuration ---
INVENTORY_PATH="../ansible/inventory/aws-instances"
PROMETHEUS_URL="http://localhost:9090"
TEST_BASE_DIR="/tmp/safe-fim-test-$(date +%s)"

# Safe test file locations (won't damage system)
SAFE_TEST_DIRS=(
    "/tmp/safe-fim-test"
    "/var/tmp/safe-fim-test"
    "/home/ubuntu/safe-fim-test"
    "/home/ec2-user/safe-fim-test"
)

# Test thresholds (matching prometheus-alerts.yml)
CRITICAL_THRESHOLD=6      # Changes to trigger FIMCriticalFileChange
HIGH_ACTIVITY_THRESHOLD=500  # Changes to trigger FIMHighActivity

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
    log "Prerequisites check complete."
}

get_current_fim_metrics() {
    log "📊 Current FIM metrics:"
    curl -s "$PROMETHEUS_URL/api/v1/query?query=fim_events_total" | jq -r '.data.result[] | "\(.metric.instance): \(.value[1]) events"' 2>/dev/null || echo "No FIM metrics found"
}

get_active_alerts() {
    log "🚨 Active FIM alerts:"
    curl -s "$PROMETHEUS_URL/api/v1/alerts" | jq -r '.data.alerts[] | select(.labels.alertname | contains("FIM")) | "\(.labels.alertname): \(.status.state) - \(.labels.instance)"' 2>/dev/null || echo "No active FIM alerts"
}

wait_for_metrics_update() {
    local wait_time=${1:-30}
    log "⏳ Waiting ${wait_time}s for metrics to update..."
    sleep $wait_time
}

# --- Safe Test Scenarios ---

test_safe_critical_changes() {
    log "🧪 Testing FIMCriticalFileChange with SAFE files..."
    log "Target: Create $CRITICAL_THRESHOLD changes in safe locations"
    
    local target_node="manage-node-1"
    local test_dir="/tmp/safe-fim-critical-test"
    
    log "1. Creating safe test directory..."
    ansible $target_node -i "$INVENTORY_PATH" -m shell -a "mkdir -p $test_dir" >/dev/null 2>&1
    
    log "2. Creating $CRITICAL_THRESHOLD test files in safe location..."
    for i in $(seq 1 $CRITICAL_THRESHOLD); do
        ansible $target_node -i "$INVENTORY_PATH" -m shell -a "echo 'safe test content $i - $(date)' > $test_dir/safe-test-$i.txt" >/dev/null 2>&1
        sleep 1
    done
    
    wait_for_metrics_update 30
    
    log "3. Checking for FIMCriticalFileChange alert..."
    local critical_alerts=$(curl -s "$PROMETHEUS_URL/api/v1/alerts" | jq -r '.data.alerts[] | select(.labels.alertname == "FIMCriticalFileChange" and .status.state == "firing")')
    
    if [[ -n "$critical_alerts" ]]; then
        log "✅ FIMCriticalFileChange alert triggered successfully!"
        echo "$critical_alerts" | jq -r '.annotations.description'
    else
        log "❌ FIMCriticalFileChange alert not triggered. Check threshold or FIM agent."
    fi
    
    log "4. Cleaning up safe test files..."
    ansible $target_node -i "$INVENTORY_PATH" -m shell -a "rm -rf $test_dir" >/dev/null 2>&1
}

test_safe_high_activity() {
    log "🧪 Testing FIMHighActivity with SAFE files..."
    log "Target: Create $HIGH_ACTIVITY_THRESHOLD file changes in safe location"
    
    local target_node="manage-node-2"
    local test_dir="/tmp/safe-fim-high-activity-test"
    
    log "1. Creating safe high activity test directory..."
    ansible $target_node -i "$INVENTORY_PATH" -m shell -a "mkdir -p $test_dir" >/dev/null 2>&1
    
    log "2. Creating $HIGH_ACTIVITY_THRESHOLD files rapidly in safe location..."
    for i in $(seq 1 $HIGH_ACTIVITY_THRESHOLD); do
        ansible $target_node -i "$INVENTORY_PATH" -m shell -a "echo 'high activity test file $i - $(date)' > $test_dir/activity-test-$i.txt" >/dev/null 2>&1
        if [ $((i % 100)) -eq 0 ]; then
            log "Created $i files..."
        fi
    done
    
    wait_for_metrics_update 60
    
    log "3. Checking for FIMHighActivity alert..."
    local high_activity_alerts=$(curl -s "$PROMETHEUS_URL/api/v1/alerts" | jq -r '.data.alerts[] | select(.labels.alertname == "FIMHighActivity" and .status.state == "firing")')
    
    if [[ -n "$high_activity_alerts" ]]; then
        log "✅ FIMHighActivity alert triggered successfully!"
        echo "$high_activity_alerts" | jq -r '.annotations.description'
    else
        log "❌ FIMHighActivity alert not triggered. Check threshold or FIM agent."
    fi
    
    log "4. Cleaning up high activity test files..."
    ansible $target_node -i "$INVENTORY_PATH" -m shell -a "rm -rf $test_dir" >/dev/null 2>&1
}

test_safe_unauthorized_simulation() {
    log "🧪 Testing FIMUnauthorizedChange simulation (SAFE)..."
    log "Target: Simulate unauthorized change without damaging system"
    
    local target_node="manage-node-3"
    local test_file="/tmp/safe-unauthorized-test.txt"
    
    log "1. Creating safe unauthorized test file..."
    ansible $target_node -i "$INVENTORY_PATH" -m shell -a "echo 'safe unauthorized test - $(date)' > $test_file" >/dev/null 2>&1
    
    log "2. Modifying the test file to simulate unauthorized change..."
    ansible $target_node -i "$INVENTORY_PATH" -m shell -a "echo 'UNAUTHORIZED MODIFICATION - $(date)' >> $test_file" >/dev/null 2>&1
    
    wait_for_metrics_update 30
    
    log "3. Checking for FIM events (this won't trigger FIMUnauthorizedChange as it's not a system file)..."
    local fim_events=$(curl -s "$PROMETHEUS_URL/api/v1/query?query=increase(fim_events_total[5m])" | jq -r '.data.result[] | "\(.metric.instance): \(.value[1]) events"')
    
    if [[ -n "$fim_events" ]]; then
        log "✅ FIM events detected (safe test file changes):"
        echo "$fim_events"
    else
        log "❌ No FIM events detected."
    fi
    
    log "4. Cleaning up safe unauthorized test file..."
    ansible $target_node -i "$INVENTORY_PATH" -m shell -a "rm -f $test_file" >/dev/null 2>&1
}

test_all_safe_scenarios() {
    log "🚀 Running comprehensive SAFE FIM tests..."
    
    get_current_fim_metrics
    echo ""
    
    test_safe_critical_changes
    echo ""
    
    test_safe_high_activity
    echo ""
    
    test_safe_unauthorized_simulation
    echo ""
    
    log "📊 Final status check..."
    get_active_alerts
}

cleanup_all_safe_tests() {
    log "🧹 Cleaning up all SAFE test artifacts..."
    
    # Clean up all safe test directories
    for test_dir in "${SAFE_TEST_DIRS[@]}"; do
        ansible all -i "$INVENTORY_PATH" -m shell -a "rm -rf $test_dir" >/dev/null 2>&1
    done
    
    # Clean up any remaining safe test files
    ansible all -i "$INVENTORY_PATH" -m shell -a "rm -f /tmp/safe-* /var/tmp/safe-*" >/dev/null 2>&1
    
    log "✅ Safe cleanup complete."
}

show_help() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "SAFE FIM Testing Options:"
    echo "  critical     Test FIMCriticalFileChange with safe files"
    echo "  high-activity Test FIMHighActivity with safe files"
    echo "  unauthorized Test FIM event detection (safe simulation)"
    echo "  all          Run all safe FIM tests"
    echo "  cleanup      Clean up all safe test artifacts"
    echo "  status       Show current FIM metrics and alerts"
    echo "  help         Show this help message"
    echo ""
    echo "SAFETY FEATURES:"
    echo "• Only creates files in /tmp/ and /var/tmp/ directories"
    echo "• Never modifies system files (/etc/, /root/, etc.)"
    echo "• Automatically cleans up all test files"
    echo "• Safe for production-like environments"
    echo ""
    echo "Examples:"
    echo "  $0 critical        # Test critical file change threshold safely"
    echo "  $0 all            # Run all safe tests"
    echo "  $0 cleanup        # Clean up test files"
}

# --- Main Logic ---
case "$1" in
    "critical")
        check_prerequisites
        test_safe_critical_changes
        ;;
    "high-activity")
        check_prerequisites
        test_safe_high_activity
        ;;
    "unauthorized")
        check_prerequisites
        test_safe_unauthorized_simulation
        ;;
    "all")
        check_prerequisites
        test_all_safe_scenarios
        ;;
    "cleanup")
        cleanup_all_safe_tests
        ;;
    "status")
        check_prerequisites
        get_current_fim_metrics
        echo ""
        get_active_alerts
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
