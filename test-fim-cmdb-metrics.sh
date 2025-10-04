#!/bin/bash
# =============================================================================
# Test FIM and CMDB Prometheus Metrics
# =============================================================================
#
# This script tests the Prometheus-instrumented FIM and CMDB agents
# to ensure metrics are being collected and exposed correctly.
#
# Usage: ./test-fim-cmdb-metrics.sh
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

# Test functions
test_fim_metrics() {
    log_info "1️⃣ Testing FIM Agent Metrics..."
    
    local fim_ports=(8080 8082 8084)
    local working_fim=0
    
    for port in "${fim_ports[@]}"; do
        log_info "Testing FIM metrics on port $port..."
        
        if curl -s "http://localhost:$port/metrics" | grep -q "fim_events_total"; then
            log_success "FIM metrics found on port $port"
            ((working_fim++))
            
            # Show sample metrics
            echo "Sample FIM metrics:"
            curl -s "http://localhost:$port/metrics" | grep -E "(fim_events_total|fim_files_monitored|fim_agent_uptime)" | head -5
        else
            log_warning "FIM metrics not found on port $port"
        fi
        echo ""
    done
    
    log_info "FIM agents working: $working_fim/3"
    return $working_fim
}

test_cmdb_metrics() {
    log_info "2️⃣ Testing CMDB Collector Metrics..."
    
    local cmdb_ports=(8081 8083 8085)
    local working_cmdb=0
    
    for port in "${cmdb_ports[@]}"; do
        log_info "Testing CMDB metrics on port $port..."
        
        if curl -s "http://localhost:$port/metrics" | grep -q "cmdb_collections_total"; then
            log_success "CMDB metrics found on port $port"
            ((working_cmdb++))
            
            # Show sample metrics
            echo "Sample CMDB metrics:"
            curl -s "http://localhost:$port/metrics" | grep -E "(cmdb_collections_total|system_packages_total|system_cpu_cores)" | head -5
        else
            log_warning "CMDB metrics not found on port $port"
        fi
        echo ""
    done
    
    log_info "CMDB collectors working: $working_cmdb/3"
    return $working_cmdb
}

test_prometheus_targets() {
    log_info "3️⃣ Testing Prometheus Targets..."
    
    # Check FIM targets
    local fim_targets=$(curl -s "http://localhost:9090/api/v1/targets" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    fim_targets = [t for t in data['data']['activeTargets'] if 'fim-agents' in t['discoveredLabels'].get('job', '')]
    print(f'FIM targets: {len(fim_targets)}')
    for target in fim_targets:
        status = 'UP' if target['health'] == 'up' else 'DOWN'
        print(f'  {target[\"discoveredLabels\"][\"__address__\"]} - {status}')
except Exception as e:
    print(f'Error: {e}')
" 2>/dev/null)
    
    # Check CMDB targets
    local cmdb_targets=$(curl -s "http://localhost:9090/api/v1/targets" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    cmdb_targets = [t for t in data['data']['activeTargets'] if 'cmdb-collectors' in t['discoveredLabels'].get('job', '')]
    print(f'CMDB targets: {len(cmdb_targets)}')
    for target in cmdb_targets:
        status = 'UP' if target['health'] == 'up' else 'DOWN'
        print(f'  {target[\"discoveredLabels\"][\"__address__\"]} - {status}')
except Exception as e:
    print(f'Error: {e}')
" 2>/dev/null)
    
    echo "$fim_targets"
    echo "$cmdb_targets"
}

test_prometheus_queries() {
    log_info "4️⃣ Testing Prometheus Queries..."
    
    # Test FIM queries
    log_info "Testing FIM queries..."
    local fim_events=$(curl -s "http://localhost:9090/api/v1/query?query=fim_events_total" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if data['status'] == 'success' and data['data']['result']:
        print(f'FIM events found: {len(data[\"data\"][\"result\"])}')
        for result in data['data']['result'][:3]:  # Show first 3
            print(f'  {result[\"metric\"].get(\"event_type\", \"unknown\")}: {result[\"value\"][1]}')
    else:
        print('No FIM events found')
except Exception as e:
    print(f'Error: {e}')
" 2>/dev/null)
    
    # Test CMDB queries
    log_info "Testing CMDB queries..."
    local cmdb_collections=$(curl -s "http://localhost:9090/api/v1/query?query=cmdb_collections_total" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if data['status'] == 'success' and data['data']['result']:
        print(f'CMDB collections found: {len(data[\"data\"][\"result\"])}')
        for result in data['data']['result'][:3]:  # Show first 3
            print(f'  Collections: {result[\"value\"][1]}')
    else:
        print('No CMDB collections found')
except Exception as e:
    print(f'Error: {e}')
" 2>/dev/null)
    
    # Test system metrics
    log_info "Testing system metrics..."
    local system_packages=$(curl -s "http://localhost:9090/api/v1/query?query=system_packages_total" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if data['status'] == 'success' and data['data']['result']:
        print(f'System packages found: {len(data[\"data\"][\"result\"])}')
        for result in data['data']['result'][:3]:  # Show first 3
            print(f'  Packages: {result[\"value\"][1]}')
    else:
        print('No system packages found')
except Exception as e:
    print(f'Error: {e}')
" 2>/dev/null)
    
    echo "$fim_events"
    echo "$cmdb_collections"
    echo "$system_packages"
}

test_file_changes() {
    log_info "5️⃣ Testing File Changes to Generate FIM Events..."
    
    # Create test files on AWS instances
    log_info "Creating test files on AWS instances..."
    ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "echo 'FIM test file created at $(date)' > /tmp/fim-test-$(date +%s).txt" || log_warning "Failed to create test files"
    
    # Wait for FIM agents to detect changes
    log_info "Waiting for FIM agents to detect changes..."
    sleep 30
    
    # Check for new FIM events
    log_info "Checking for new FIM events..."
    local new_events=$(curl -s "http://localhost:9090/api/v1/query?query=fim_events_total" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if data['status'] == 'success' and data['data']['result']:
        total_events = sum(int(result['value'][1]) for result in data['data']['result'])
        print(f'Total FIM events: {total_events}')
        return total_events
    else:
        print('No FIM events found')
        return 0
except Exception as e:
    print(f'Error: {e}')
    return 0
" 2>/dev/null)
    
    if [ "$new_events" -gt 0 ]; then
        log_success "FIM events detected: $new_events"
    else
        log_warning "No FIM events detected yet"
    fi
}

test_grafana_integration() {
    log_info "6️⃣ Testing Grafana Integration..."
    
    # Check if Grafana is accessible
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost:3000" | grep -q "200"; then
        log_success "Grafana is accessible"
        
        # Check if Prometheus datasource is configured
        local datasource_status=$(curl -s "http://localhost:3000/api/datasources" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    prometheus_ds = [ds for ds in data if ds.get('type') == 'prometheus']
    if prometheus_ds:
        print(f'Prometheus datasource found: {prometheus_ds[0][\"name\"]}')
    else:
        print('No Prometheus datasource found')
except Exception as e:
    print(f'Error: {e}')
" 2>/dev/null)
        
        echo "$datasource_status"
    else
        log_warning "Grafana is not accessible"
    fi
}

# Main test function
main() {
    log_info "🧪 Testing FIM and CMDB Prometheus Metrics..."
    echo "=================================================="
    
    local total_tests=0
    local passed_tests=0
    
    # Test 1: FIM Metrics
    if test_fim_metrics; then
        ((passed_tests++))
    fi
    ((total_tests++))
    echo ""
    
    # Test 2: CMDB Metrics
    if test_cmdb_metrics; then
        ((passed_tests++))
    fi
    ((total_tests++))
    echo ""
    
    # Test 3: Prometheus Targets
    test_prometheus_targets
    echo ""
    
    # Test 4: Prometheus Queries
    test_prometheus_queries
    echo ""
    
    # Test 5: File Changes
    test_file_changes
    echo ""
    
    # Test 6: Grafana Integration
    test_grafana_integration
    echo ""
    
    # Summary
    log_info "📊 Test Summary:"
    echo "  Tests passed: $passed_tests/$total_tests"
    
    if [ $passed_tests -eq $total_tests ]; then
        log_success "🎉 All FIM and CMDB metrics tests passed!"
        echo ""
        log_info "🔍 Try these Prometheus queries:"
        echo "  • fim_events_total"
        echo "  • cmdb_collections_total"
        echo "  • system_packages_total"
        echo "  • fim_files_monitored"
        echo "  • system_cpu_cores"
        echo ""
        log_info "🌐 Access your monitoring:"
        echo "  • Prometheus: http://localhost:9090"
        echo "  • Grafana: http://localhost:3000"
    else
        log_warning "Some tests failed. Check the output above for details."
    fi
}

# Run main function
main "$@"
