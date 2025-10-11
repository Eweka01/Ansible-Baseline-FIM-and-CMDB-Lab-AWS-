#!/bin/bash

# test-fim-thresholds.sh
# This script creates controlled FIM events to test alert thresholds
# It allows manual testing of FIM alerting without triggering false positives

# --- Configuration ---
INVENTORY_PATH="ansible/inventory/aws-instances"
PROMETHEUS_URL="http://localhost:9090"
ALERTMANAGER_URL="http://localhost:9093"

# Test file locations
TEST_DIR="/tmp/fim-test-$(date +%s)"
CRITICAL_TEST_FILE="/etc/fim-test-critical.txt"
UNAUTHORIZED_TEST_FILE="/etc/passwd"
HIGH_ACTIVITY_DIR="/tmp/fim-high-activity-test"

# Thresholds (matching prometheus-alerts.yml)
CRITICAL_THRESHOLD=5      # Changes to trigger FIMCriticalFileChange
UNAUTHORIZED_THRESHOLD=1  # Changes to trigger FIMUnauthorizedChange  
HIGH_ACTIVITY_THRESHOLD=200  # Changes to trigger FIMHighActivity

# --- Utility Functions ---
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

check_prerequisites() {
    log "🔍 Checking prerequisites..."
    command -v curl >/dev/null 2>&1 || { echo >&2 "curl is required but not installed. Aborting."; exit 1; }
    command -v ansible >/dev/null 2>&1 || { echo >&2 "ansible is required but not installed. Aborting."; exit 1; }
    
    log "Checking Prometheus status..."
    if curl -s -o /dev/null -w "%{http_code}" "$PROMETHEUS_URL" | grep -q "200"; then
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

# --- Test Scenarios ---

test_critical_file_changes() {
    log "🧪 Testing FIMCriticalFileChange threshold..."
    log "Target: Create $CRITICAL_THRESHOLD changes to critical files"
    
    local target_node="manage-node-1"
    
    log "1. Creating test files in critical directories..."
    for i in $(seq 1 $CRITICAL_THRESHOLD); do
        ansible $target_node -i "$INVENTORY_PATH" -m shell -a "echo 'test content $i' | sudo tee /etc/fim-test-$i.txt" >/dev/null 2>&1
        ansible $target_node -i "$INVENTORY_PATH" -m shell -a "echo 'test content $i' | sudo tee /root/fim-test-$i.txt" >/dev/null 2>&1
        sleep 2
    done
    
    wait_for_metrics_update 30
    
    log "2. Checking for FIMCriticalFileChange alert..."
    local critical_alerts=$(curl -s "$PROMETHEUS_URL/api/v1/alerts" | jq -r '.data.alerts[] | select(.labels.alertname == "FIMCriticalFileChange" and .status.state == "firing")')
    
    if [[ -n "$critical_alerts" ]]; then
        log "✅ FIMCriticalFileChange alert triggered successfully!"
        echo "$critical_alerts" | jq -r '.annotations.description'
    else
        log "❌ FIMCriticalFileChange alert not triggered. Check threshold or FIM agent."
    fi
    
    log "3. Cleaning up critical test files..."
    for i in $(seq 1 $CRITICAL_THRESHOLD); do
        ansible $target_node -i "$INVENTORY_PATH" -m shell -a "sudo rm -f /etc/fim-test-$i.txt /root/fim-test-$i.txt" >/dev/null 2>&1
    done
}

test_unauthorized_changes() {
    log "🧪 Testing FIMUnauthorizedChange threshold..."
    log "Target: Create $UNAUTHORIZED_THRESHOLD change to unauthorized file"
    
    local target_node="manage-node-2"
    
    log "1. Creating backup of /etc/passwd..."
    ansible $target_node -i "$INVENTORY_PATH" -m shell -a "sudo cp /etc/passwd /etc/passwd.backup" >/dev/null 2>&1
    
    log "2. Making unauthorized change to /etc/passwd..."
    ansible $target_node -i "$INVENTORY_PATH" -m shell -a "echo '# FIM TEST - UNAUTHORIZED CHANGE' | sudo tee -a /etc/passwd" >/dev/null 2>&1
    
    wait_for_metrics_update 30
    
    log "3. Checking for FIMUnauthorizedChange alert..."
    local unauthorized_alerts=$(curl -s "$PROMETHEUS_URL/api/v1/alerts" | jq -r '.data.alerts[] | select(.labels.alertname == "FIMUnauthorizedChange" and .status.state == "firing")')
    
    if [[ -n "$unauthorized_alerts" ]]; then
        log "✅ FIMUnauthorizedChange alert triggered successfully!"
        echo "$unauthorized_alerts" | jq -r '.annotations.description'
    else
        log "❌ FIMUnauthorizedChange alert not triggered. Check threshold or FIM agent."
    fi
    
    log "4. Restoring /etc/passwd from backup..."
    ansible $target_node -i "$INVENTORY_PATH" -m shell -a "sudo cp /etc/passwd.backup /etc/passwd && sudo rm /etc/passwd.backup" >/dev/null 2>&1
}

test_high_activity() {
    log "🧪 Testing FIMHighActivity threshold..."
    log "Target: Create $HIGH_ACTIVITY_THRESHOLD file changes in 10 minutes"
    
    local target_node="manage-node-3"
    
    log "1. Creating high activity test directory..."
    ansible $target_node -i "$INVENTORY_PATH" -m shell -a "sudo mkdir -p $HIGH_ACTIVITY_DIR" >/dev/null 2>&1
    
    log "2. Creating $HIGH_ACTIVITY_THRESHOLD files rapidly..."
    for i in $(seq 1 $HIGH_ACTIVITY_THRESHOLD); do
        ansible $target_node -i "$INVENTORY_PATH" -m shell -a "echo 'high activity test file $i' | sudo tee $HIGH_ACTIVITY_DIR/test-file-$i.txt" >/dev/null 2>&1
        if [ $((i % 50)) -eq 0 ]; then
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
    ansible $target_node -i "$INVENTORY_PATH" -m shell -a "sudo rm -rf $HIGH_ACTIVITY_DIR" >/dev/null 2>&1
}

test_all_thresholds() {
    log "🚀 Running comprehensive FIM threshold tests..."
    
    get_current_fim_metrics
    echo ""
    
    test_critical_file_changes
    echo ""
    
    test_unauthorized_changes
    echo ""
    
    test_high_activity
    echo ""
    
    log "📊 Final status check..."
    get_active_alerts
}

cleanup_all_tests() {
    log "🧹 Cleaning up all test artifacts..."
    
    # Clean up critical test files
    ansible all -i "$INVENTORY_PATH" -m shell -a "sudo rm -f /etc/fim-test-*.txt /root/fim-test-*.txt" >/dev/null 2>&1
    
    # Clean up high activity test directory
    ansible all -i "$INVENTORY_PATH" -m shell -a "sudo rm -rf /tmp/fim-high-activity-test" >/dev/null 2>&1
    
    # Restore any modified system files
    ansible all -i "$INVENTORY_PATH" -m shell -a "sudo cp /etc/passwd.backup /etc/passwd 2>/dev/null; sudo rm -f /etc/passwd.backup" >/dev/null 2>&1
    
    log "✅ Cleanup complete."
}

show_help() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  critical     Test FIMCriticalFileChange threshold"
    echo "  unauthorized Test FIMUnauthorizedChange threshold"
    echo "  high-activity Test FIMHighActivity threshold"
    echo "  all          Run all threshold tests"
    echo "  cleanup      Clean up all test artifacts"
    echo "  status       Show current FIM metrics and alerts"
    echo "  help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 critical        # Test critical file change threshold"
    echo "  $0 all            # Run all tests"
    echo "  $0 cleanup        # Clean up test files"
}

# --- Main Logic ---
case "$1" in
    "critical")
        check_prerequisites
        test_critical_file_changes
        ;;
    "unauthorized")
        check_prerequisites
        test_unauthorized_changes
        ;;
    "high-activity")
        check_prerequisites
        test_high_activity
        ;;
    "all")
        check_prerequisites
        test_all_thresholds
        ;;
    "cleanup")
        cleanup_all_tests
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
