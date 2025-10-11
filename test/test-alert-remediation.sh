#!/bin/bash
# Comprehensive Alert and Remediation Testing Script
# Tests FIM and CMDB alerts and automated remediation system
# Author: Gabriel Eweka
# Date: October 6, 2025

set -e

LAB_DIR="/Users/osamudiameneweka/Desktop/Ansible Baseline, FIM, and CMDB Lab"
SSH_KEY="/path/to/your/ssh-key.pem"
LOG_FILE="/tmp/alert-remediation-test.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✅ $1${NC}" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}❌ $1${NC}" | tee -a "$LOG_FILE"
}

check_prerequisites() {
    log "🔍 Checking prerequisites..."
    
    # Check if SSH key exists
    if [ ! -f "$SSH_KEY" ]; then
        error "SSH key not found: $SSH_KEY"
        exit 1
    fi
    
    # Check if webhook receiver is running
    if ! ps aux | grep webhook-receiver | grep -v grep > /dev/null; then
        error "Webhook receiver is not running. Start it with: ./start-automated-remediation.sh start"
        exit 1
    fi
    
    # Check if Prometheus is accessible
    if ! curl -s http://localhost:9090/api/v1/status > /dev/null; then
        error "Prometheus is not accessible"
        exit 1
    fi
    
    success "All prerequisites met"
}

get_aws_instances() {
    log "🌐 Getting AWS instance information..."
    
    # Extract IPs from inventory
    NODE1_IP=$(grep "manage-node-1" ansible/inventory/aws-instances | awk '{print $2}' | cut -d'=' -f2)
    NODE2_IP=$(grep "manage-node-2" ansible/inventory/aws-instances | awk '{print $2}' | cut -d'=' -f2)
    NODE3_IP=$(grep "manage-node-3" ansible/inventory/aws-instances | awk '{print $2}' | cut -d'=' -f2)
    
    log "Node IPs: $NODE1_IP, $NODE2_IP, $NODE3_IP"
}

test_fim_alerts() {
    log "🔍 Testing FIM alerts..."
    
    # Create test files on each node to trigger FIM alerts
    for i in {1..3}; do
        case $i in
            1) NODE_IP=$NODE1_IP; NODE_NAME="manage-node-1" ;;
            2) NODE_IP=$NODE2_IP; NODE_NAME="manage-node-2" ;;
            3) NODE_IP=$NODE3_IP; NODE_NAME="manage-node-3" ;;
        esac
        
        log "Creating test files on $NODE_NAME ($NODE_IP)..."
        
        # Create multiple test files to ensure FIM detection
        ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ec2-user@$NODE_IP "
            echo 'FIM Test File 1 - $(date)' | sudo tee /tmp/fim-test-$(date +%s)-1.txt
            echo 'FIM Test File 2 - $(date)' | sudo tee /tmp/fim-test-$(date +%s)-2.txt
            echo 'FIM Test File 3 - $(date)' | sudo tee /tmp/fim-test-$(date +%s)-3.txt
            echo 'Unauthorized change' | sudo tee /etc/test-drift-$(date +%s).txt
        " 2>/dev/null || warning "Could not create test files on $NODE_NAME"
    done
    
    success "FIM test files created on all nodes"
}

test_cmdb_alerts() {
    log "📊 Testing CMDB alerts..."
    
    # Stop CMDB collectors temporarily to trigger collection failure alerts
    for i in {1..3}; do
        case $i in
            1) NODE_IP=$NODE1_IP; NODE_NAME="manage-node-1" ;;
            2) NODE_IP=$NODE2_IP; NODE_NAME="manage-node-2" ;;
            3) NODE_IP=$NODE3_IP; NODE_NAME="manage-node-3" ;;
        esac
        
        log "Stopping CMDB collector on $NODE_NAME ($NODE_IP)..."
        
        ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ec2-user@$NODE_IP "
            sudo systemctl stop cmdb-collector-prometheus
        " 2>/dev/null || warning "Could not stop CMDB collector on $NODE_NAME"
    done
    
    success "CMDB collectors stopped for testing"
}

wait_for_alerts() {
    log "⏳ Waiting for alerts to fire..."
    
    # Wait for FIM alerts to appear
    log "Waiting for FIM alerts (up to 2 minutes)..."
    for i in {1..24}; do
        FIM_ALERTS=$(curl -s "http://localhost:9090/api/v1/alerts" | jq '.data.alerts[] | select(.labels.alertname == "FIMFileChange" and .status.state == "firing")' 2>/dev/null | wc -l)
        if [ "$FIM_ALERTS" -gt 0 ]; then
            success "FIM alerts detected: $FIM_ALERTS firing"
            break
        fi
        sleep 5
    done
    
    # Wait for CMDB alerts to appear
    log "Waiting for CMDB alerts (up to 2 minutes)..."
    for i in {1..24}; do
        CMDB_ALERTS=$(curl -s "http://localhost:9090/api/v1/alerts" | jq '.data.alerts[] | select(.labels.alertname == "CMDBCollectionFailure" and .status.state == "firing")' 2>/dev/null | wc -l)
        if [ "$CMDB_ALERTS" -gt 0 ]; then
            success "CMDB alerts detected: $CMDB_ALERTS firing"
            break
        fi
        sleep 5
    done
}

check_webhook_processing() {
    log "🔗 Checking webhook processing..."
    
    # Check webhook logs for alert processing
    if [ -f /tmp/webhook-receiver.log ]; then
        RECENT_ALERTS=$(tail -20 /tmp/webhook-receiver.log | grep -c "Processing alert" || echo "0")
        if [ "$RECENT_ALERTS" -gt 0 ]; then
            success "Webhook processed $RECENT_ALERTS recent alerts"
        else
            warning "No recent webhook processing detected"
        fi
    else
        warning "Webhook log file not found"
    fi
}

check_remediation_execution() {
    log "🔧 Checking remediation execution..."
    
    # Check remediation audit log
    if [ -f /tmp/automated-remediation-audit.log ]; then
        RECENT_REMEDIATIONS=$(tail -10 /tmp/automated-remediation-audit.log | grep -c "status.*success" || echo "0")
        if [ "$RECENT_REMEDIATIONS" -gt 0 ]; then
            success "Recent successful remediations: $RECENT_REMEDIATIONS"
        else
            warning "No recent successful remediations found"
        fi
    else
        warning "Remediation audit log not found"
    fi
}

restore_services() {
    log "🔄 Restoring services..."
    
    # Restart CMDB collectors
    for i in {1..3}; do
        case $i in
            1) NODE_IP=$NODE1_IP; NODE_NAME="manage-node-1" ;;
            2) NODE_IP=$NODE2_IP; NODE_NAME="manage-node-2" ;;
            3) NODE_IP=$NODE3_IP; NODE_NAME="manage-node-3" ;;
        esac
        
        log "Restarting CMDB collector on $NODE_NAME ($NODE_IP)..."
        
        ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ec2-user@$NODE_IP "
            sudo systemctl start cmdb-collector-prometheus
        " 2>/dev/null || warning "Could not restart CMDB collector on $NODE_NAME"
    done
    
    success "Services restored"
}

cleanup_test_files() {
    log "🧹 Cleaning up test files..."
    
    # Remove test files from all nodes
    for i in {1..3}; do
        case $i in
            1) NODE_IP=$NODE1_IP; NODE_NAME="manage-node-1" ;;
            2) NODE_IP=$NODE2_IP; NODE_NAME="manage-node-2" ;;
            3) NODE_IP=$NODE3_IP; NODE_NAME="manage-node-3" ;;
        esac
        
        log "Cleaning up test files on $NODE_NAME ($NODE_IP)..."
        
        ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ec2-user@$NODE_IP "
            sudo rm -f /tmp/fim-test-*.txt
            sudo rm -f /etc/test-drift-*.txt
        " 2>/dev/null || warning "Could not clean up test files on $NODE_NAME"
    done
    
    success "Test files cleaned up"
}

generate_test_report() {
    log "📊 Generating test report..."
    
    REPORT_FILE="/tmp/alert-remediation-test-report.txt"
    
    cat > "$REPORT_FILE" << EOF
# Alert and Remediation Test Report
Generated: $(date)

## Test Summary
- FIM Alerts: Tested by creating unauthorized files
- CMDB Alerts: Tested by stopping collectors
- Webhook Processing: Checked for alert processing
- Remediation Execution: Checked for successful remediations

## Current Alert Status
EOF
    
    # Get current alert status
    curl -s "http://localhost:9090/api/v1/alerts" | jq '.data.alerts[] | {alertname: .labels.alertname, state: .status.state, severity: .labels.severity}' >> "$REPORT_FILE" 2>/dev/null || echo "Could not retrieve alert status" >> "$REPORT_FILE"
    
    echo "" >> "$REPORT_FILE"
    echo "## Webhook Logs (Last 10 lines)" >> "$REPORT_FILE"
    if [ -f /tmp/webhook-receiver.log ]; then
        tail -10 /tmp/webhook-receiver.log >> "$REPORT_FILE"
    else
        echo "Webhook log not found" >> "$REPORT_FILE"
    fi
    
    echo "" >> "$REPORT_FILE"
    echo "## Remediation Audit Log (Last 5 entries)" >> "$REPORT_FILE"
    if [ -f /tmp/automated-remediation-audit.log ]; then
        tail -5 /tmp/automated-remediation-audit.log >> "$REPORT_FILE"
    else
        echo "Remediation audit log not found" >> "$REPORT_FILE"
    fi
    
    success "Test report generated: $REPORT_FILE"
}

show_current_status() {
    log "📈 Current system status..."
    
    echo ""
    echo "🔍 CURRENT ALERTS:"
    echo "=================="
    curl -s "http://localhost:9090/api/v1/alerts" | jq '.data.alerts[] | {alertname: .labels.alertname, state: .status.state, severity: .labels.severity}' 2>/dev/null || echo "Could not retrieve alerts"
    
    echo ""
    echo "📊 FIM METRICS:"
    echo "=============="
    curl -s "http://localhost:9090/api/v1/query?query=fim_events_total" | jq '.data.result[] | {instance: .metric.instance, value: .value[1]}' 2>/dev/null || echo "Could not retrieve FIM metrics"
    
    echo ""
    echo "📊 CMDB METRICS:"
    echo "==============="
    curl -s "http://localhost:9090/api/v1/query?query=cmdb_collections_total" | jq '.data.result[] | {instance: .metric.instance, value: .value[1]}' 2>/dev/null || echo "Could not retrieve CMDB metrics"
}

main() {
    echo "🚀 ALERT AND REMEDIATION TESTING SCRIPT"
    echo "======================================="
    echo ""
    
    log "Starting comprehensive alert and remediation testing..."
    
    # Run all test phases
    check_prerequisites
    get_aws_instances
    test_fim_alerts
    test_cmdb_alerts
    wait_for_alerts
    check_webhook_processing
    check_remediation_execution
    restore_services
    cleanup_test_files
    generate_test_report
    show_current_status
    
    echo ""
    success "Alert and remediation testing completed!"
    echo ""
    log "Check the test report: /tmp/alert-remediation-test-report.txt"
    log "Check the test log: $LOG_FILE"
}

# Handle script arguments
case "${1:-}" in
    "fim-only")
        log "Running FIM alert test only..."
        check_prerequisites
        get_aws_instances
        test_fim_alerts
        wait_for_alerts
        check_webhook_processing
        check_remediation_execution
        cleanup_test_files
        show_current_status
        ;;
    "cmdb-only")
        log "Running CMDB alert test only..."
        check_prerequisites
        get_aws_instances
        test_cmdb_alerts
        wait_for_alerts
        check_webhook_processing
        check_remediation_execution
        restore_services
        show_current_status
        ;;
    "status")
        show_current_status
        ;;
    "cleanup")
        log "Running cleanup only..."
        get_aws_instances
        cleanup_test_files
        restore_services
        ;;
    *)
        main
        ;;
esac
