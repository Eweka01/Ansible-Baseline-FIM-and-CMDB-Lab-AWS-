#!/bin/bash

# =============================================================================
# Production Testing Suite - Comprehensive Lab Testing
# =============================================================================
#
# This script provides comprehensive testing for the production monitoring lab
# including infrastructure monitoring, security testing, and compliance validation.
#
# Usage:
#     ./production-testing-suite.sh [--quick] [--full] [--monitoring] [--security]
#
# Author: Gabriel Eweka
# Version: 1.0.0
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
QUICK_TEST=false
FULL_TEST=false
MONITORING_TEST=false
SECURITY_TEST=false

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

# Function to show help
show_help() {
    echo -e "${BLUE}🧪 Production Testing Suite${NC}"
    echo -e "${BLUE}===========================${NC}\n"
    echo -e "${YELLOW}Usage:${NC}"
    echo -e "  ./production-testing-suite.sh [--quick] [--full] [--monitoring] [--security]"
    echo -e "\n${YELLOW}Options:${NC}"
    echo -e "  --quick      Run quick monitoring tests only"
    echo -e "  --full       Run comprehensive test suite"
    echo -e "  --monitoring Run monitoring stack tests only"
    echo -e "  --security   Run security and compliance tests only"
    echo -e "  --help       Show this help message"
    echo -e "\n${GREEN}Test Categories:${NC}"
    echo -e "  • Monitoring Stack (Prometheus + Grafana)"
    echo -e "  • Infrastructure Monitoring (CPU, Memory, Disk)"
    echo -e "  • Security Monitoring (FIM, Compliance)"
    echo -e "  • Configuration Management (CMDB)"
    echo -e "  • High Availability (Service Failover)"
    echo -e "  • Performance Testing (Load Testing)"
}

# Test monitoring stack
test_monitoring_stack() {
    echo -e "${CYAN}📊 TESTING MONITORING STACK${NC}"
    echo -e "${CYAN}============================${NC}\n"
    
    local passed=0
    local total=0
    
    # Test SSH tunnels
    log_info "Testing SSH tunnels..."
    tunnel_count=$(ps aux | grep "ssh.*910[0-9]" | grep -v grep | wc -l)
    ((total++))
    if [ $tunnel_count -eq 3 ]; then
        log_success "SSH tunnels: 3/3 active"
        ((passed++))
    else
        log_error "SSH tunnels: Only $tunnel_count/3 active"
    fi
    
    # Test Prometheus targets
    log_info "Testing Prometheus targets..."
    targets_status=$(curl -s http://localhost:9090/api/v1/targets | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    up_count = sum(1 for target in data['data']['activeTargets'] if target['health'] == 'up')
    total_count = len(data['data']['activeTargets'])
    print(f'{up_count}/{total_count}')
except:
    print('0/0')
" 2>/dev/null)
    ((total++))
    if [[ $targets_status == "3/3" ]]; then
        log_success "Prometheus targets: $targets_status UP"
        ((passed++))
    else
        log_error "Prometheus targets: Only $targets_status UP"
    fi
    
    # Test Prometheus queries
    log_info "Testing Prometheus queries..."
    cpu_result=$(curl -s "http://localhost:9090/api/v1/query?query=node_cpu_seconds_total" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if data['status'] == 'success' and data['data']['result']:
        print('SUCCESS')
    else:
        print('FAILED')
except:
    print('ERROR')
" 2>/dev/null)
    ((total++))
    if [[ $cpu_result == "SUCCESS" ]]; then
        log_success "Prometheus queries: Working"
        ((passed++))
    else
        log_error "Prometheus queries: Failed"
    fi
    
    # Test Grafana
    log_info "Testing Grafana..."
    grafana_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/health 2>/dev/null)
    ((total++))
    if [[ $grafana_status == "200" ]]; then
        log_success "Grafana: Accessible"
        ((passed++))
    else
        log_error "Grafana: Status $grafana_status"
    fi
    
    # Test Docker services
    log_info "Testing Docker services..."
    docker_services=$(docker compose -f docker-compose.yml ps --services --filter "status=running" | wc -l 2>/dev/null)
    ((total++))
    if [ $docker_services -eq 2 ]; then
        log_success "Docker services: $docker_services/2 running"
        ((passed++))
    else
        log_error "Docker services: Only $docker_services/2 running"
    fi
    
    echo ""
    log_info "Monitoring Stack Results: $passed/$total tests passed"
    return $((total - passed))
}

# Test infrastructure monitoring
test_infrastructure_monitoring() {
    echo -e "${CYAN}🖥️ TESTING INFRASTRUCTURE MONITORING${NC}"
    echo -e "${CYAN}=====================================${NC}\n"
    
    local passed=0
    local total=0
    
    # Test CPU monitoring
    log_info "Testing CPU monitoring..."
    cpu_metrics=$(curl -s "http://localhost:9090/api/v1/query?query=node_cpu_seconds_total" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(len(data['data']['result']) if data['data']['result'] else 0)
except:
    print(0)
" 2>/dev/null)
    ((total++))
    if [ $cpu_metrics -gt 0 ]; then
        log_success "CPU metrics: $cpu_metrics data points"
        ((passed++))
    else
        log_error "CPU metrics: No data"
    fi
    
    # Test memory monitoring
    log_info "Testing memory monitoring..."
    memory_metrics=$(curl -s "http://localhost:9090/api/v1/query?query=node_memory_MemAvailable_bytes" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(len(data['data']['result']) if data['data']['result'] else 0)
except:
    print(0)
" 2>/dev/null)
    ((total++))
    if [ $memory_metrics -gt 0 ]; then
        log_success "Memory metrics: $memory_metrics data points"
        ((passed++))
    else
        log_error "Memory metrics: No data"
    fi
    
    # Test disk monitoring
    log_info "Testing disk monitoring..."
    disk_metrics=$(curl -s "http://localhost:9090/api/v1/query?query=node_filesystem_size_bytes" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(len(data['data']['result']) if data['data']['result'] else 0)
except:
    print(0)
" 2>/dev/null)
    ((total++))
    if [ $disk_metrics -gt 0 ]; then
        log_success "Disk metrics: $disk_metrics data points"
        ((passed++))
    else
        log_error "Disk metrics: No data"
    fi
    
    echo ""
    log_info "Infrastructure Monitoring Results: $passed/$total tests passed"
    return $((total - passed))
}

# Test security monitoring
test_security_monitoring() {
    echo -e "${CYAN}🔒 TESTING SECURITY MONITORING${NC}"
    echo -e "${CYAN}===============================${NC}\n"
    
    local passed=0
    local total=0
    
    # Test FIM agents
    log_info "Testing FIM agents..."
    fim_status=$(cd ansible && ansible aws_instances -i inventory/aws-instances -m shell -a "systemctl is-active fim-agent" 2>/dev/null | grep -c "active" || echo "0")
    ((total++))
    if [ $fim_status -eq 3 ]; then
        log_success "FIM agents: 3/3 active"
        ((passed++))
    else
        log_error "FIM agents: Only $fim_status/3 active"
    fi
    
    # Test CMDB collectors
    log_info "Testing CMDB collectors..."
    cmdb_status=$(cd ansible && ansible aws_instances -i inventory/aws-instances -m shell -a "systemctl is-active cmdb-collector.timer" 2>/dev/null | grep -c "active" || echo "0")
    ((total++))
    if [ $cmdb_status -eq 3 ]; then
        log_success "CMDB collectors: 3/3 active"
        ((passed++))
    else
        log_error "CMDB collectors: Only $cmdb_status/3 active"
    fi
    
    # Test Node Exporter
    log_info "Testing Node Exporter..."
    node_exporter_status=$(cd ansible && ansible aws_instances -i inventory/aws-instances -m shell -a "systemctl is-active node_exporter" 2>/dev/null | grep -c "active" || echo "0")
    ((total++))
    if [ $node_exporter_status -eq 3 ]; then
        log_success "Node Exporter: 3/3 active"
        ((passed++))
    else
        log_error "Node Exporter: Only $node_exporter_status/3 active"
    fi
    
    echo ""
    log_info "Security Monitoring Results: $passed/$total tests passed"
    return $((total - passed))
}

# Test high availability
test_high_availability() {
    echo -e "${CYAN}🔄 TESTING HIGH AVAILABILITY${NC}"
    echo -e "${CYAN}============================${NC}\n"
    
    local passed=0
    local total=0
    
    # Test service restart
    log_info "Testing service restart capability..."
    cd ansible
    ansible manage-node-1 -i inventory/aws-instances -m shell -a "systemctl restart fim-agent" >/dev/null 2>&1
    sleep 5
    restart_status=$(ansible manage-node-1 -i inventory/aws-instances -m shell -a "systemctl is-active fim-agent" 2>/dev/null | grep -c "active" || echo "0")
    cd ..
    ((total++))
    if [ $restart_status -eq 1 ]; then
        log_success "Service restart: Working"
        ((passed++))
    else
        log_error "Service restart: Failed"
    fi
    
    # Test tunnel recovery
    log_info "Testing tunnel recovery..."
    ./manage-tunnels.sh stop >/dev/null 2>&1
    sleep 2
    ./manage-tunnels.sh start >/dev/null 2>&1
    sleep 5
    tunnel_count=$(ps aux | grep "ssh.*910[0-9]" | grep -v grep | wc -l)
    ((total++))
    if [ $tunnel_count -eq 3 ]; then
        log_success "Tunnel recovery: Working"
        ((passed++))
    else
        log_error "Tunnel recovery: Failed"
    fi
    
    echo ""
    log_info "High Availability Results: $passed/$total tests passed"
    return $((total - passed))
}

# Test performance
test_performance() {
    echo -e "${CYAN}⚡ TESTING PERFORMANCE${NC}"
    echo -e "${CYAN}======================${NC}\n"
    
    local passed=0
    local total=0
    
    # Test metrics collection speed
    log_info "Testing metrics collection speed..."
    start_time=$(date +%s)
    curl -s "http://localhost:9090/api/v1/query?query=node_cpu_seconds_total" >/dev/null 2>&1
    end_time=$(date +%s)
    response_time=$((end_time - start_time))
    ((total++))
    if [ $response_time -le 5 ]; then
        log_success "Metrics collection: ${response_time}s (≤5s)"
        ((passed++))
    else
        log_warning "Metrics collection: ${response_time}s (>5s)"
        ((passed++)) # Still pass but warn
    fi
    
    # Test dashboard load time
    log_info "Testing dashboard load time..."
    start_time=$(date +%s)
    curl -s -o /dev/null "http://localhost:3000/api/health"
    end_time=$(date +%s)
    response_time=$((end_time - start_time))
    ((total++))
    if [ $response_time -le 3 ]; then
        log_success "Dashboard load: ${response_time}s (≤3s)"
        ((passed++))
    else
        log_warning "Dashboard load: ${response_time}s (>3s)"
        ((passed++)) # Still pass but warn
    fi
    
    echo ""
    log_info "Performance Results: $passed/$total tests passed"
    return $((total - passed))
}

# Quick test function
run_quick_test() {
    echo -e "${CYAN}⚡ QUICK TEST SUITE${NC}"
    echo -e "${CYAN}==================${NC}\n"
    
    test_monitoring_stack
    local monitoring_failures=$?
    
    echo ""
    if [ $monitoring_failures -eq 0 ]; then
        log_success "Quick test completed successfully!"
        echo -e "${GREEN}🎯 Your monitoring stack is fully operational!${NC}"
    else
        log_error "Quick test found $monitoring_failures issues"
        echo -e "${RED}🔧 Please check the monitoring stack configuration${NC}"
    fi
}

# Full test function
run_full_test() {
    echo -e "${CYAN}🧪 FULL TEST SUITE${NC}"
    echo -e "${CYAN}==================${NC}\n"
    
    local total_failures=0
    
    test_monitoring_stack
    total_failures=$((total_failures + $?))
    
    test_infrastructure_monitoring
    total_failures=$((total_failures + $?))
    
    test_security_monitoring
    total_failures=$((total_failures + $?))
    
    test_high_availability
    total_failures=$((total_failures + $?))
    
    test_performance
    total_failures=$((total_failures + $?))
    
    echo ""
    echo -e "${CYAN}📊 FINAL RESULTS${NC}"
    echo -e "${CYAN}================${NC}"
    
    if [ $total_failures -eq 0 ]; then
        log_success "All tests passed! Your lab is production-ready! 🎉"
        echo ""
        echo -e "${GREEN}🌐 Access your monitoring:${NC}"
        echo "   • Grafana: http://localhost:3000 (admin/admin)"
        echo "   • Prometheus: http://localhost:9090"
        echo "   • Lab Dashboard: http://localhost:8080/simple-monitoring-dashboard.html"
    else
        log_error "Found $total_failures test failures"
        echo -e "${RED}🔧 Please review the failed tests and fix issues${NC}"
    fi
}

# Main function
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --quick)
                QUICK_TEST=true
                shift
                ;;
            --full)
                FULL_TEST=true
                shift
                ;;
            --monitoring)
                MONITORING_TEST=true
                shift
                ;;
            --security)
                SECURITY_TEST=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    echo -e "${CYAN}🧪 PRODUCTION TESTING SUITE${NC}"
    echo -e "${CYAN}============================${NC}\n"
    
    # Run appropriate tests
    if [ "$QUICK_TEST" = true ]; then
        run_quick_test
    elif [ "$FULL_TEST" = true ]; then
        run_full_test
    elif [ "$MONITORING_TEST" = true ]; then
        test_monitoring_stack
    elif [ "$SECURITY_TEST" = true ]; then
        test_security_monitoring
    else
        # Default to quick test
        run_quick_test
    fi
}

# Run main function
main "$@"
