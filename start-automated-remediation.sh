#!/bin/bash
# Automated Remediation System Startup Script
# Author: Gabriel Eweka
# Date: October 6, 2025

set -e

LAB_DIR="/Users/osamudiameneweka/Desktop/Ansible Baseline, FIM, and CMDB Lab"
WEBHOOK_PORT=5001
WEBHOOK_SCRIPT="$LAB_DIR/automated-remediation/webhook-receiver.py"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

check_dependencies() {
    log "Checking dependencies..."
    
    # Check if Python 3 is available
    if ! command -v python3 &> /dev/null; then
        log "ERROR: Python 3 is not installed"
        exit 1
    fi
    
    # Check if Ansible is available
    if ! command -v ansible-playbook &> /dev/null; then
        log "ERROR: Ansible is not installed"
        exit 1
    fi
    
    # Check if webhook script exists
    if [ ! -f "$WEBHOOK_SCRIPT" ]; then
        log "ERROR: Webhook receiver script not found: $WEBHOOK_SCRIPT"
        exit 1
    fi
    
    log "All dependencies are available"
}

check_port() {
    local port="$1"
    if lsof -i :$port &> /dev/null; then
        log "Port $port is already in use"
        return 1
    else
        log "Port $port is available"
        return 0
    fi
}

start_webhook_receiver() {
    log "Starting webhook receiver on port $WEBHOOK_PORT"
    
    # Check if port is available
    if ! check_port $WEBHOOK_PORT; then
        log "Stopping existing webhook receiver..."
        pkill -f "webhook-receiver.py" || true
        sleep 2
    fi
    
    # Start webhook receiver in background
    nohup python3 "$WEBHOOK_SCRIPT" $WEBHOOK_PORT > /tmp/webhook-receiver.log 2>&1 &
    WEBHOOK_PID=$!
    
    # Wait for webhook to start
    sleep 3
    
    # Check if webhook is running
    if ps -p $WEBHOOK_PID > /dev/null; then
        log "Webhook receiver started successfully (PID: $WEBHOOK_PID)"
        echo $WEBHOOK_PID > /tmp/webhook-receiver.pid
    else
        log "ERROR: Failed to start webhook receiver"
        exit 1
    fi
}

test_webhook() {
    log "Testing webhook receiver..."
    
    # Test webhook with a sample alert
    test_alert='{
        "alerts": [{
            "labels": {
                "alertname": "TestAlert",
                "severity": "warning",
                "instance": "test-instance"
            },
            "annotations": {
                "summary": "Test alert",
                "description": "This is a test alert"
            },
            "status": {
                "state": "firing"
            }
        }]
    }'
    
    if curl -s -X POST -H "Content-Type: application/json" \
           -d "$test_alert" http://localhost:$WEBHOOK_PORT/ > /dev/null; then
        log "Webhook test successful"
    else
        log "WARNING: Webhook test failed"
    fi
}

restart_alertmanager() {
    log "Restarting Alertmanager to apply new configuration..."
    
    cd "$LAB_DIR"
    docker-compose restart alertmanager
    
    # Wait for Alertmanager to start
    sleep 5
    
    # Check if Alertmanager is running
    if curl -s http://localhost:9093/api/v1/status > /dev/null; then
        log "Alertmanager restarted successfully"
    else
        log "WARNING: Alertmanager may not be running properly"
    fi
}

show_status() {
    log "Automated Remediation System Status:"
    
    # Check webhook receiver
    if [ -f /tmp/webhook-receiver.pid ]; then
        WEBHOOK_PID=$(cat /tmp/webhook-receiver.pid)
        if ps -p $WEBHOOK_PID > /dev/null; then
            echo "  Webhook Receiver: Running (PID: $WEBHOOK_PID)"
        else
            echo "  Webhook Receiver: Not running"
        fi
    else
        echo "  Webhook Receiver: Not running"
    fi
    
    # Check Alertmanager
    if curl -s http://localhost:9093/api/v1/status > /dev/null; then
        echo "  Alertmanager: Running"
    else
        echo "  Alertmanager: Not running"
    fi
    
    # Check Prometheus
    if curl -s http://localhost:9090/api/v1/status > /dev/null; then
        echo "  Prometheus: Running"
    else
        echo "  Prometheus: Not running"
    fi
    
    # Check audit logs
    if [ -d "/var/log/audit" ]; then
        echo "  Audit Logs: Available"
    else
        echo "  Audit Logs: Not set up"
    fi
}

stop_webhook_receiver() {
    log "Stopping webhook receiver..."
    
    if [ -f /tmp/webhook-receiver.pid ]; then
        WEBHOOK_PID=$(cat /tmp/webhook-receiver.pid)
        if ps -p $WEBHOOK_PID > /dev/null; then
            kill $WEBHOOK_PID
            log "Webhook receiver stopped (PID: $WEBHOOK_PID)"
        fi
        rm -f /tmp/webhook-receiver.pid
    fi
    
    # Kill any remaining webhook processes
    pkill -f "webhook-receiver.py" || true
}

case "$1" in
    "start")
        log "Starting Automated Remediation System..."
        check_dependencies
        start_webhook_receiver
        test_webhook
        restart_alertmanager
        show_status
        log "Automated Remediation System started successfully"
        ;;
    "stop")
        log "Stopping Automated Remediation System..."
        stop_webhook_receiver
        log "Automated Remediation System stopped"
        ;;
    "restart")
        log "Restarting Automated Remediation System..."
        stop_webhook_receiver
        sleep 2
        check_dependencies
        start_webhook_receiver
        test_webhook
        restart_alertmanager
        show_status
        log "Automated Remediation System restarted successfully"
        ;;
    "status")
        show_status
        ;;
    "test")
        test_webhook
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|test}"
        echo "  start   - Start the automated remediation system"
        echo "  stop    - Stop the automated remediation system"
        echo "  restart - Restart the automated remediation system"
        echo "  status  - Show system status"
        echo "  test    - Test webhook receiver"
        exit 1
        ;;
esac
