#!/bin/bash

# Lab Test Runner
# Executes all test scenarios for the Ansible Baseline, FIM, and CMDB lab

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$TEST_DIR")"
LOG_DIR="$TEST_DIR/logs"
REPORT_DIR="$TEST_DIR/reports"

# Create directories
mkdir -p "$LOG_DIR" "$REPORT_DIR"

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_DIR/test-run.log"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1" | tee -a "$LOG_DIR/test-run.log"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_DIR/test-run.log"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1" | tee -a "$LOG_DIR/test-run.log"
}

# Test execution function
run_test() {
    local test_name="$1"
    local test_script="$2"
    local test_description="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    log_info "Running test: $test_name"
    log_info "Description: $test_description"
    
    if [ -f "$test_script" ]; then
        if bash "$test_script"; then
            log_success "Test passed: $test_name"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            return 0
        else
            log_error "Test failed: $test_name"
            FAILED_TESTS=$((FAILED_TESTS + 1))
            return 1
        fi
    else
        log_warning "Test script not found: $test_script"
        SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
        return 2
    fi
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing_deps=()
    
    # Check required commands
    for cmd in ansible python3 git curl wget; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    # Check Python modules
    for module in psutil watchdog; do
        if ! python3 -c "import $module" &> /dev/null; then
            missing_deps+=("python3-$module")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_info "Please install missing dependencies and try again"
        exit 1
    fi
    
    log_success "All prerequisites met"
}

# Test 1: Ansible Baseline Tests
test_ansible_baseline() {
    log_info "=== Testing Ansible Baseline Configuration ==="
    
    # Test 1.1: Playbook syntax check
    run_test "ansible-syntax-check" \
             "$TEST_DIR/test-ansible-syntax.sh" \
             "Validate Ansible playbook syntax"
    
    # Test 1.2: Inventory validation
    run_test "ansible-inventory-check" \
             "$TEST_DIR/test-ansible-inventory.sh" \
             "Validate Ansible inventory configuration"
    
    # Test 1.3: Role structure validation
    run_test "ansible-roles-check" \
             "$TEST_DIR/test-ansible-roles.sh" \
             "Validate Ansible role structure and dependencies"
    
    # Test 1.4: Configuration validation
    run_test "ansible-config-check" \
             "$TEST_DIR/test-ansible-config.sh" \
             "Validate Ansible configuration files"
}

# Test 2: FIM Tests
test_fim_functionality() {
    log_info "=== Testing File Integrity Monitoring ==="
    
    # Test 2.1: FIM agent validation
    run_test "fim-agent-check" \
             "$TEST_DIR/test-fim-agent.sh" \
             "Validate FIM agent configuration and functionality"
    
    # Test 2.2: FIM configuration validation
    run_test "fim-config-check" \
             "$TEST_DIR/test-fim-config.sh" \
             "Validate FIM configuration files"
    
    # Test 2.3: FIM rules validation
    run_test "fim-rules-check" \
             "$TEST_DIR/test-fim-rules.sh" \
             "Validate FIM monitoring rules"
    
    # Test 2.4: FIM integration test
    run_test "fim-integration-test" \
             "$TEST_DIR/test-fim-integration.sh" \
             "Test FIM file change detection"
}

# Test 3: CMDB Tests
test_cmdb_functionality() {
    log_info "=== Testing Configuration Management Database ==="
    
    # Test 3.1: CMDB collector validation
    run_test "cmdb-collector-check" \
             "$TEST_DIR/test-cmdb-collector.sh" \
             "Validate CMDB data collector functionality"
    
    # Test 3.2: CMDB schema validation
    run_test "cmdb-schema-check" \
             "$TEST_DIR/test-cmdb-schema.sh" \
             "Validate CMDB data schema"
    
    # Test 3.3: CMDB data collection test
    run_test "cmdb-data-collection" \
             "$TEST_DIR/test-cmdb-data.sh" \
             "Test CMDB data collection and storage"
    
    # Test 3.4: CMDB integration test
    run_test "cmdb-integration-test" \
             "$TEST_DIR/test-cmdb-integration.sh" \
             "Test CMDB integration with other components"
}

# Test 4: Integration Tests
test_integration() {
    log_info "=== Testing System Integration ==="
    
    # Test 4.1: End-to-end workflow
    run_test "end-to-end-test" \
             "$TEST_DIR/test-end-to-end.sh" \
             "Test complete workflow from baseline to monitoring"
    
    # Test 4.2: Component interaction
    run_test "component-interaction" \
             "$TEST_DIR/test-component-interaction.sh" \
             "Test interaction between Ansible, FIM, and CMDB"
    
    # Test 4.3: Performance test
    run_test "performance-test" \
             "$TEST_DIR/test-performance.sh" \
             "Test system performance under load"
}

# Test 5: Security Tests
test_security() {
    log_info "=== Testing Security Configuration ==="
    
    # Test 5.1: Security hardening validation
    run_test "security-hardening" \
             "$TEST_DIR/test-security-hardening.sh" \
             "Validate security hardening configuration"
    
    # Test 5.2: Access control test
    run_test "access-control" \
             "$TEST_DIR/test-access-control.sh" \
             "Test access control and permissions"
    
    # Test 5.3: Data protection test
    run_test "data-protection" \
             "$TEST_DIR/test-data-protection.sh" \
             "Test data protection and encryption"
}

# Generate test report
generate_report() {
    local report_file="$REPORT_DIR/test-report-$(date +%Y%m%d-%H%M%S).html"
    
    log_info "Generating test report: $report_file"
    
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Lab Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
        .summary { margin: 20px 0; }
        .test-result { margin: 10px 0; padding: 10px; border-radius: 3px; }
        .pass { background-color: #d4edda; border: 1px solid #c3e6cb; }
        .fail { background-color: #f8d7da; border: 1px solid #f5c6cb; }
        .skip { background-color: #fff3cd; border: 1px solid #ffeaa7; }
        .stats { display: flex; gap: 20px; }
        .stat { text-align: center; padding: 10px; border-radius: 5px; }
        .stat.pass { background-color: #d4edda; }
        .stat.fail { background-color: #f8d7da; }
        .stat.skip { background-color: #fff3cd; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Lab Test Report</h1>
        <p>Generated on: $(date)</p>
        <p>Test Environment: $(hostname)</p>
    </div>
    
    <div class="summary">
        <h2>Test Summary</h2>
        <div class="stats">
            <div class="stat pass">
                <h3>$PASSED_TESTS</h3>
                <p>Passed</p>
            </div>
            <div class="stat fail">
                <h3>$FAILED_TESTS</h3>
                <p>Failed</p>
            </div>
            <div class="stat skip">
                <h3>$SKIPPED_TESTS</h3>
                <p>Skipped</p>
            </div>
        </div>
        <p><strong>Total Tests:</strong> $TOTAL_TESTS</p>
        <p><strong>Success Rate:</strong> $(( (PASSED_TESTS * 100) / TOTAL_TESTS ))%</p>
    </div>
    
    <div class="test-results">
        <h2>Test Results</h2>
        <p>Detailed test results are available in the log file: <code>$LOG_DIR/test-run.log</code></p>
    </div>
</body>
</html>
EOF
    
    log_success "Test report generated: $report_file"
}

# Main execution
main() {
    log_info "Starting Lab Test Suite"
    log_info "Test directory: $TEST_DIR"
    log_info "Lab directory: $LAB_DIR"
    
    # Check prerequisites
    check_prerequisites
    
    # Run test suites
    test_ansible_baseline
    test_fim_functionality
    test_cmdb_functionality
    test_integration
    test_security
    
    # Generate report
    generate_report
    
    # Final summary
    log_info "=== Test Suite Complete ==="
    log_info "Total Tests: $TOTAL_TESTS"
    log_success "Passed: $PASSED_TESTS"
    if [ $FAILED_TESTS -gt 0 ]; then
        log_error "Failed: $FAILED_TESTS"
    fi
    if [ $SKIPPED_TESTS -gt 0 ]; then
        log_warning "Skipped: $SKIPPED_TESTS"
    fi
    
    # Exit with appropriate code
    if [ $FAILED_TESTS -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# Run main function
main "$@"

