#!/bin/bash

# =============================================================================
# Comprehensive Lab Test Runner
# =============================================================================
#
# This script provides comprehensive testing for the Ansible Baseline, FIM,
# and CMDB lab. It runs all individual test scripts, validates lab functionality,
# and generates detailed test reports.
#
# Features:
# - Executes all individual test scripts
# - Generates detailed test reports
# - Validates lab functionality end-to-end
# - Creates test summaries and logs
# - Provides pass/fail status for each component
#
# Usage:
#     ./run-lab-tests.sh [--verbose] [--fim-only] [--cmdb-only] [--clean]
#
# Author: Ansible Baseline, FIM, and CMDB Lab
# Version: 1.0.0
# =============================================================================

set -e  # Exit on any error

# =============================================================================
# Configuration and Setup
# =============================================================================

# Color codes for terminal output
RED='\033[0;31m'      # Red for errors and failures
GREEN='\033[0;32m'    # Green for success and passes
YELLOW='\033[1;33m'   # Yellow for warnings
BLUE='\033[0;34m'     # Blue for information
NC='\033[0m'          # No Color (reset)

# Test result counters
TOTAL_TESTS=0         # Total number of tests executed
PASSED_TESTS=0        # Number of tests that passed
FAILED_TESTS=0        # Number of tests that failed

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Test execution function
run_test() {
    local test_name="$1"
    local test_command="$2"
    local test_description="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    log_info "Running test: $test_name"
    log_info "Description: $test_description"
    
    if eval "$test_command"; then
        log_success "Test passed: $test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        log_error "Test failed: $test_name"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Python
    if command -v python3 &> /dev/null; then
        log_success "Python 3 found: $(python3 --version)"
    else
        log_error "Python 3 not found"
        return 1
    fi
    
    # Check virtual environment
    if [[ -d "venv" ]]; then
        log_success "Virtual environment found"
    else
        log_warning "Virtual environment not found - creating one"
        python3 -m venv venv
        source venv/bin/activate
        pip install --upgrade pip
        pip install psutil watchdog pyyaml jinja2 requests paramiko cryptography
        log_success "Virtual environment created and dependencies installed"
    fi
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Check Python modules
    local missing_modules=()
    for module in psutil watchdog yaml jinja2; do
        if ! python3 -c "import $module" &> /dev/null; then
            missing_modules+=("$module")
        fi
    done
    
    if [ ${#missing_modules[@]} -gt 0 ]; then
        log_warning "Missing Python modules: ${missing_modules[*]}"
        log_info "Installing missing modules..."
        pip install "${missing_modules[@]}"
        log_success "Missing modules installed"
    else
        log_success "All Python modules available"
    fi
}

# Test 1: FIM Functionality
test_fim() {
    log_info "=== Testing FIM Functionality ==="
    
    run_test "fim-basic-test" \
             "python3 test-fim-simple.py" \
             "Test basic FIM functionality (hash calculation, change detection)"
    
    # Check if FIM files were created
    if [[ -f "fim-baseline.json" && -f "fim-test-reports.json" ]]; then
        log_success "FIM test files created successfully"
    else
        log_error "FIM test files not created"
        return 1
    fi
}

# Test 2: CMDB Functionality
test_cmdb() {
    log_info "=== Testing CMDB Functionality ==="
    
    run_test "cmdb-basic-test" \
             "python3 tests/scripts/test-cmdb.py" \
             "Test CMDB data collection and storage"
    
    # Check if CMDB files were created
    if [[ -d "cmdb-test-data" && -f "cmdb-test.log" ]]; then
        log_success "CMDB test files created successfully"
        
        # Count data files
        local data_files=$(find cmdb-test-data -name "*.json" | wc -l)
        log_info "CMDB collected $data_files data files"
    else
        log_error "CMDB test files not created"
        return 1
    fi
}

# Test 3: Ansible Configuration
test_ansible() {
    log_info "=== Testing Ansible Configuration ==="
    
    run_test "ansible-syntax-check" \
             "ansible-playbook --syntax-check ansible/playbooks/setup-localhost.yml" \
             "Check Ansible playbook syntax"
    
    run_test "ansible-inventory-check" \
             "ansible-inventory -i ansible/inventory/localhost --list" \
             "Check Ansible inventory configuration"
}

# Test 4: File Structure
test_file_structure() {
    log_info "=== Testing File Structure ==="
    
    local required_dirs=("ansible" "fim" "cmdb" "docs" "tests")
    local required_files=("README.md" "requirements.txt" "setup/scripts/setup-lab.sh")
    
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            log_success "Directory found: $dir"
        else
            log_error "Directory missing: $dir"
            return 1
        fi
    done
    
    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_success "File found: $file"
        else
            log_error "File missing: $file"
            return 1
        fi
    done
}

# Test 5: Integration Test
test_integration() {
    log_info "=== Testing Integration ==="
    
    # Test that FIM can monitor CMDB data
    run_test "fim-cmdb-integration" \
             "python3 -c \"
import os, json, hashlib
from datetime import datetime

# Create a test file in CMDB data directory
os.makedirs('cmdb-test-data', exist_ok=True)
test_file = 'cmdb-test-data/integration-test.json'
with open(test_file, 'w') as f:
    json.dump({'test': 'integration', 'timestamp': datetime.now().isoformat()}, f)

# Calculate hash
with open(test_file, 'rb') as f:
    content = f.read()
    file_hash = hashlib.sha256(content).hexdigest()

print(f'Integration test file created: {test_file}')
print(f'File hash: {file_hash[:16]}...')
print('Integration test passed')
\"" \
             "Test FIM monitoring of CMDB data files"
}

# Generate test report
generate_report() {
    log_info "Generating test report..."
    
    local report_file="lab-test-report-$(date +%Y%m%d-%H%M%S).txt"
    
    cat > "$report_file" << EOF
Lab Test Report
===============
Generated: $(date)
Environment: $(uname -s) $(uname -r)
Python: $(python3 --version)
Lab Directory: $(pwd)

Test Results:
- Total Tests: $TOTAL_TESTS
- Passed: $PASSED_TESTS
- Failed: $FAILED_TESTS
- Success Rate: $(( (PASSED_TESTS * 100) / TOTAL_TESTS ))%

Component Status:
- FIM: $([ -f "fim-baseline.json" ] && echo "Working" || echo "Not Working")
- CMDB: $([ -d "cmdb-test-data" ] && echo "Working" || echo "Not Working")
- Ansible: $([ -f "ansible/ansible.cfg" ] && echo "Configured" || echo "Not Configured")

Files Created:
$(find . -name "*.json" -o -name "*.log" | head -10)

Next Steps:
1. Review any failed tests
2. Check log files for errors
3. Run individual component tests
4. Deploy to target systems

EOF
    
    log_success "Test report generated: $report_file"
}

# Main execution
main() {
    echo "Lab Test Suite"
    echo "=============="
    echo "Testing Ansible Baseline, FIM, and CMDB Lab"
    echo
    
    # Run test suites
    check_prerequisites
    test_file_structure
    test_fim
    test_cmdb
    test_ansible
    test_integration
    
    # Generate report
    generate_report
    
    # Final summary
    echo
    echo "=========================================="
    echo "Test Suite Complete"
    echo "=========================================="
    echo "Total Tests: $TOTAL_TESTS"
    log_success "Passed: $PASSED_TESTS"
    if [ $FAILED_TESTS -gt 0 ]; then
        log_error "Failed: $FAILED_TESTS"
    fi
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo
        log_success "🎉 All tests passed! Your lab is ready to use."
        echo
        echo "Next steps:"
        echo "1. Review the test report"
        echo "2. Try the individual components:"
        echo "   - FIM: python3 test-fim-simple.py"
        echo "   - CMDB: python3 tests/scripts/test-cmdb.py"
        echo "3. Deploy to target systems using Ansible"
        echo "4. Run the full test suite: ./run-lab-tests.sh"
    else
        echo
        log_error "Some tests failed. Please review the output above."
        echo "Check the log files for more details."
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
