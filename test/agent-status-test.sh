#!/bin/bash

# agent-status-test.sh
# Test script to check FIM and CMDB agent status across all nodes
# Safe monitoring script that doesn't modify anything

# --- Configuration ---
INVENTORY_PATH="../ansible/inventory/aws-instances"
PROMETHEUS_URL="http://localhost:9090"

# Service names
FIM_AGENT_SERVICE="fim-agent-prometheus.service"
CMDB_COLLECTOR_SERVICE="cmdb-collector-prometheus.service"

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

# --- Agent Status Tests ---

check_fim_agent_status() {
    log "🔍 Checking FIM Agent Status..."
    echo "============================="
    
    ansible all -i "$INVENTORY_PATH" -m systemd -a "name=$FIM_AGENT_SERVICE" --become | grep -E "(manage-node|Active|Main PID)" | while read line; do
        if [[ $line == *"manage-node"* ]]; then
            echo "📊 $line"
        elif [[ $line == *"Active:"* ]]; then
            if [[ $line == *"active (running)"* ]]; then
                echo "✅ $line"
            else
                echo "❌ $line"
            fi
        elif [[ $line == *"Main PID:"* ]]; then
            echo "🆔 $line"
        fi
    done
    echo ""
}

check_cmdb_collector_status() {
    log "🔍 Checking CMDB Collector Status..."
    echo "================================="
    
    ansible all -i "$INVENTORY_PATH" -m systemd -a "name=$CMDB_COLLECTOR_SERVICE" --become | grep -E "(manage-node|Active|Main PID)" | while read line; do
        if [[ $line == *"manage-node"* ]]; then
            echo "📊 $line"
        elif [[ $line == *"Active:"* ]]; then
            if [[ $line == *"active (running)"* ]]; then
                echo "✅ $line"
            else
                echo "❌ $line"
            fi
        elif [[ $line == *"Main PID:"* ]]; then
            echo "🆔 $line"
        fi
    done
    echo ""
}

check_prometheus_targets() {
    log "🔍 Checking Prometheus Targets..."
    echo "=============================="
    
    # Check FIM agents
    log "📊 FIM Agent Targets:"
    curl -s "$PROMETHEUS_URL/api/v1/targets" | jq -r '.data.activeTargets[] | select(.labels.job == "fim-agents") | "\(.labels.instance): \(.health) - \(.lastScrape)"' 2>/dev/null || echo "No FIM agent targets found"
    echo ""
    
    # Check CMDB collectors
    log "📊 CMDB Collector Targets:"
    curl -s "$PROMETHEUS_URL/api/v1/targets" | jq -r '.data.activeTargets[] | select(.labels.job == "cmdb-collectors") | "\(.labels.instance): \(.health) - \(.lastScrape)"' 2>/dev/null || echo "No CMDB collector targets found"
    echo ""
    
    # Check Node Exporters
    log "📊 Node Exporter Targets:"
    curl -s "$PROMETHEUS_URL/api/v1/targets" | jq -r '.data.activeTargets[] | select(.labels.job == "aws-nodes") | "\(.labels.instance): \(.health) - \(.lastScrape)"' 2>/dev/null || echo "No Node Exporter targets found"
    echo ""
}

check_agent_metrics() {
    log "🔍 Checking Agent Metrics..."
    echo "========================="
    
    # FIM metrics
    log "📊 FIM Event Metrics:"
    curl -s "$PROMETHEUS_URL/api/v1/query?query=fim_events_total" | jq -r '.data.result[] | "\(.metric.instance): \(.value[1]) total events"' 2>/dev/null || echo "No FIM metrics found"
    echo ""
    
    # CMDB metrics
    log "📊 CMDB Collection Metrics:"
    curl -s "$PROMETHEUS_URL/api/v1/query?query=cmdb_collections_total" | jq -r '.data.result[] | "\(.metric.instance): \(.value[1]) total collections"' 2>/dev/null || echo "No CMDB metrics found"
    echo ""
    
    # Agent uptime
    log "📊 Agent Uptime Metrics:"
    curl -s "$PROMETHEUS_URL/api/v1/query?query=up{job=~\"fim-agents|cmdb-collectors\"}" | jq -r '.data.result[] | "\(.metric.instance) (\(.metric.job)): \(.value[1])"' 2>/dev/null || echo "No uptime metrics found"
    echo ""
}

check_agent_logs() {
    log "🔍 Checking Agent Logs (Last 5 lines each)..."
    echo "==========================================="
    
    # FIM agent logs
    log "📊 FIM Agent Logs:"
    ansible all -i "$INVENTORY_PATH" -m shell -a "sudo journalctl -u $FIM_AGENT_SERVICE --no-pager -n 5" --become | grep -E "(manage-node|FIM|ERROR|WARN)" | tail -15
    echo ""
    
    # CMDB collector logs
    log "📊 CMDB Collector Logs:"
    ansible all -i "$INVENTORY_PATH" -m shell -a "sudo journalctl -u $CMDB_COLLECTOR_SERVICE --no-pager -n 5" --become | grep -E "(manage-node|CMDB|ERROR|WARN)" | tail -15
    echo ""
}

check_agent_ports() {
    log "🔍 Checking Agent Ports..."
    echo "======================="
    
    # Check if agents are listening on expected ports
    log "📊 FIM Agent Ports (8080, 8082, 8084):"
    ansible all -i "$INVENTORY_PATH" -m shell -a "sudo netstat -tlnp | grep -E ':(8080|8082|8084)'" --become | grep -E "(manage-node|LISTEN)" || echo "No FIM agent ports found"
    echo ""
    
    log "📊 CMDB Collector Ports (8081, 8083, 8085):"
    ansible all -i "$INVENTORY_PATH" -m shell -a "sudo netstat -tlnp | grep -E ':(8081|8083|8085)'" --become | grep -E "(manage-node|LISTEN)" || echo "No CMDB collector ports found"
    echo ""
}

restart_agents() {
    log "🔄 Restarting Agents..."
    echo "===================="
    
    log "1. Restarting FIM agents..."
    ansible all -i "$INVENTORY_PATH" -m systemd -a "name=$FIM_AGENT_SERVICE state=restarted" --become
    echo ""
    
    log "2. Restarting CMDB collectors..."
    ansible all -i "$INVENTORY_PATH" -m systemd -a "name=$CMDB_COLLECTOR_SERVICE state=restarted" --become
    echo ""
    
    log "⏳ Waiting for agents to start..."
    sleep 10
    
    log "3. Checking agent status after restart..."
    check_fim_agent_status
    check_cmdb_collector_status
}

show_help() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Agent Status Testing Options:"
    echo "  status       Check all agent statuses (default)"
    echo "  fim          Check FIM agent status only"
    echo "  cmdb         Check CMDB collector status only"
    echo "  targets      Check Prometheus targets"
    echo "  metrics      Check agent metrics"
    echo "  logs         Check agent logs"
    echo "  ports        Check agent ports"
    echo "  restart      Restart all agents"
    echo "  help         Show this help message"
    echo ""
    echo "SAFETY FEATURES:"
    echo "• Read-only monitoring (no system modifications)"
    echo "• Safe for production environments"
    echo "• Comprehensive agent health checking"
    echo ""
    echo "Examples:"
    echo "  $0 status        # Check all agent statuses"
    echo "  $0 fim          # Check FIM agents only"
    echo "  $0 restart      # Restart all agents"
}

# --- Main Logic ---
case "$1" in
    "fim")
        check_prerequisites
        check_fim_agent_status
        ;;
    "cmdb")
        check_prerequisites
        check_cmdb_collector_status
        ;;
    "targets")
        check_prerequisites
        check_prometheus_targets
        ;;
    "metrics")
        check_prerequisites
        check_agent_metrics
        ;;
    "logs")
        check_prerequisites
        check_agent_logs
        ;;
    "ports")
        check_prerequisites
        check_agent_ports
        ;;
    "restart")
        check_prerequisites
        restart_agents
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    "status"|"")
        check_prerequisites
        log "🚀 Running comprehensive agent status check..."
        echo "==========================================="
        echo ""
        check_fim_agent_status
        check_cmdb_collector_status
        check_prometheus_targets
        check_agent_metrics
        check_agent_logs
        check_agent_ports
        ;;
    *)
        echo "❌ Invalid option: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
