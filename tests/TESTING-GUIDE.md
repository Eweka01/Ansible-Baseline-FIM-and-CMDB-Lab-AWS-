# Testing Guide - Production Monitoring Lab

This guide provides comprehensive information about testing your **production-grade monitoring lab** with Ansible Baseline, FIM, CMDB, and live monitoring via Prometheus + Grafana.

## 📋 Table of Contents

1. [Test Overview](#test-overview)
2. [Test Scripts](#test-scripts)
3. [Running Tests](#running-tests)
4. [Understanding Results](#understanding-results)
5. [Troubleshooting](#troubleshooting)
6. [Advanced Testing](#advanced-testing)

---

## 🎯 Test Overview

The lab includes comprehensive testing for all major components:

### **Components Under Test**
- **Ansible Automation** - Playbook execution and configuration management
- **File Integrity Monitoring (FIM)** - File change detection and monitoring
- **Configuration Management Database (CMDB)** - System information collection
- **Security Hardening** - Firewall, fail2ban, and SSH configuration
- **Service Management** - Systemd services and timers
- **Live Monitoring Stack** - Prometheus + Grafana monitoring
- **SSH Tunneling** - Secure AWS monitoring connectivity
- **Node Exporter** - System metrics collection

### **Test Categories**
- **Unit Tests** - Individual component functionality
- **Integration Tests** - Component interaction testing
- **End-to-End Tests** - Complete workflow validation
- **Performance Tests** - Load and stress testing
- **Security Tests** - Security configuration validation
- **Monitoring Tests** - Real-time metrics and alerting
- **Production Tests** - Enterprise-grade scenarios

---

## 🧪 Test Scripts

### **1. test-prometheus-grafana-fix.sh - Monitoring Stack Testing**

**Purpose**: Comprehensive testing of the production monitoring stack.

**What it tests**:
- SSH tunnel connectivity and status
- Prometheus targets and data collection
- Grafana accessibility and functionality
- Docker services status
- Node Exporter metrics availability

**Key Features**:
- Tests all 3 SSH tunnels (ports 9101, 9102, 9103)
- Verifies Prometheus targets are UP
- Tests Prometheus queries return data
- Checks Grafana health and accessibility
- Validates Docker container status

**Usage**:
```bash
./test-prometheus-grafana-fix.sh
```

**Expected Output**:
- ✅ All 3 SSH tunnels running
- ✅ All 3 Prometheus targets UP
- ✅ CPU and memory queries working
- ✅ Grafana accessible
- ✅ All Docker services running

### **2. test-fim.py - Advanced FIM Testing**

**Purpose**: Comprehensive testing of File Integrity Monitoring functionality.

**What it tests**:
- FIM agent initialization and configuration
- File monitoring and change detection
- Baseline creation and comparison
- Alert generation and reporting
- Different file types and monitoring scenarios

**Key Features**:
- Tests file creation, modification, and deletion detection
- Validates hash calculation and comparison
- Tests baseline management
- Validates alert generation
- Tests different file types (text, config, scripts)

**Usage**:
```bash
# Basic test
python3 tests/scripts/test-fim.py

# Verbose output
python3 tests/scripts/test-fim.py --verbose

# Custom test directory
python3 tests/scripts/test-fim.py --test-dir /tmp/fim-test
```

**Expected Output**:
- FIM agent initialization status
- File change detection results
- Baseline comparison results
- Alert generation status
- Test summary with pass/fail counts

### **2. test-fim-simple.py - Simplified FIM Testing**

**Purpose**: Standalone FIM testing without complex dependencies.

**What it tests**:
- Basic file monitoring functionality
- Hash calculation and comparison
- Local file change detection
- Simplified reporting

**Key Features**:
- No external dependencies
- Simple file monitoring
- Basic hash comparison
- Local testing only

**Usage**:
```bash
# Basic test
python3 tests/scripts/test-fim-simple.py

# Custom monitoring directory
python3 tests/scripts/test-fim-simple.py --monitor-dir /etc
```

**Expected Output**:
- File monitoring status
- Hash calculation results
- Change detection summary
- Simple test report

### **3. test-cmdb.py - CMDB Testing**

**Purpose**: Tests Configuration Management Database collector functionality.

**What it tests**:
- System information collection
- Hardware information gathering
- Software and package detection
- Network interface detection
- Data storage and retrieval
- JSON schema validation

**Key Features**:
- Tests system information collection
- Validates hardware detection
- Tests software inventory
- Validates network configuration
- Tests data persistence
- Validates JSON schema compliance

**Usage**:
```bash
# Basic test
python3 tests/scripts/test-cmdb.py

# Custom output directory
python3 tests/scripts/test-cmdb.py --output-dir /tmp/cmdb-test

# Verbose output
python3 tests/scripts/test-cmdb.py --verbose
```

**Expected Output**:
- System information collection status
- Hardware detection results
- Software inventory results
- Network configuration data
- Data validation results
- JSON schema compliance status

### **4. run-lab-tests.sh - Comprehensive Test Suite**

**Purpose**: Runs all lab tests and generates comprehensive reports.

**What it tests**:
- All individual test scripts
- End-to-end lab functionality
- Component integration
- Overall lab health

**Key Features**:
- Executes all test scripts
- Generates detailed reports
- Provides pass/fail status
- Creates test summaries
- Handles test failures gracefully

**Usage**:
```bash
# Run all tests
./tests/scripts/run-lab-tests.sh

# Verbose output
./tests/scripts/run-lab-tests.sh --verbose

# Run specific test categories
./tests/scripts/run-lab-tests.sh --fim-only
./tests/scripts/run-lab-tests.sh --cmdb-only

# Clean test data
./tests/scripts/run-lab-tests.sh --clean
```

**Expected Output**:
- Comprehensive test report
- Individual component results
- Overall lab status
- Detailed logs and summaries

---

## 🚀 Running Tests

### **Prerequisites**

Before running tests, ensure you have:

```bash
# Required Python packages
pip3 install -r requirements.txt

# Required system tools
sudo apt-get install jq curl wget  # Ubuntu/Debian
sudo yum install jq curl wget      # Amazon Linux

# Proper permissions
chmod +x tests/scripts/*.py
chmod +x tests/scripts/*.sh
```

### **Basic Test Execution**

```bash
# Run all tests
./tests/scripts/run-lab-tests.sh

# Run individual tests
python3 tests/scripts/test-fim.py
python3 tests/scripts/test-cmdb.py
```

### **Advanced Test Options**

```bash
# Verbose output
./tests/scripts/run-lab-tests.sh --verbose

# Debug mode
./tests/scripts/run-lab-tests.sh --debug

# Clean test data
./tests/scripts/run-lab-tests.sh --clean

# Backup test results
./tests/scripts/run-lab-tests.sh --backup
```

### **Test Environment Setup**

```bash
# Set test directories
export FIM_TEST_DIR="/tmp/fim-test"
export CMDB_TEST_DIR="/tmp/cmdb-test"
export LOG_DIR="/tmp/lab-logs"

# Set test verbosity
export TEST_VERBOSE="true"
export TEST_DEBUG="false"
```

---

## 📊 Understanding Results

### **Test Result Codes**

| Code | Meaning | Description |
|------|---------|-------------|
| **PASS** | ✅ Success | Test completed successfully |
| **FAIL** | ❌ Failure | Test failed with errors |
| **SKIP** | ⏭️ Skipped | Test was skipped (missing dependencies) |
| **WARN** | ⚠️ Warning | Test completed with warnings |

### **Test Output Interpretation**

#### **FIM Test Results**
```bash
=== FIM Functionality Test ===
✅ FIM Agent initialized successfully
✅ File monitoring started
✅ Baseline created: 4 files monitored
✅ File change detected: test1.txt modified
✅ Alert generated: File change alert
📊 Test Summary: 5/5 tests passed
```

#### **CMDB Test Results**
```bash
=== CMDB Functionality Test ===
✅ System information collected
✅ Hardware information gathered
✅ Software inventory completed
✅ Network configuration detected
✅ Data validation passed
📊 Test Summary: 5/5 tests passed
```

#### **Overall Test Results**
```bash
🎉 Lab Test Results Summary
========================
Total Tests: 15
Passed: 14
Failed: 1
Skipped: 0
Success Rate: 93.3%

📋 Component Status:
- FIM Agent: ✅ PASS
- CMDB Collector: ✅ PASS
- Ansible Automation: ✅ PASS
- Security Hardening: ⚠️ WARN
- Service Management: ✅ PASS
```

### **Test Report Files**

After running tests, you'll find:

```
data/
├── test-results/
│   ├── fim-baseline.json      # FIM baseline data
│   ├── fim-reports.json       # FIM change reports
│   └── fim-test-reports.json  # FIM test results
├── reports/
│   └── lab-test-report-*.txt  # Comprehensive test reports
└── cmdb-test-data/
    ├── system_info-*.json     # System information
    ├── hardware_info-*.json   # Hardware information
    └── software_info-*.json   # Software inventory
```

---

## 🔧 Troubleshooting

### **Common Issues**

#### **1. Permission Errors**
```bash
# Fix permission issues
sudo chown -R $USER:$USER tests/scripts/
chmod +x tests/scripts/*.py
chmod +x tests/scripts/*.sh
```

#### **2. Import Errors**
```bash
# Install required dependencies
pip3 install -r requirements.txt

# Check Python path
export PYTHONPATH="${PYTHONPATH}:$(pwd)"
```

#### **3. Path Issues**
```bash
# Set correct paths
export FIM_TEST_DIR="/tmp/fim-test"
export CMDB_TEST_DIR="/tmp/cmdb-test"

# Create test directories
mkdir -p /tmp/fim-test /tmp/cmdb-test
```

#### **4. Service Issues**
```bash
# Check if services are running
systemctl status fim-agent
systemctl status cmdb-collector.timer

# Restart services if needed
sudo systemctl restart fim-agent
sudo systemctl restart cmdb-collector.timer
```

### **Debug Mode**

```bash
# Enable debug logging
export DEBUG="true"
./tests/scripts/run-lab-tests.sh --debug

# Verbose output
./tests/scripts/run-lab-tests.sh --verbose
```

### **Test Logs**

Check test logs for detailed information:

```bash
# View test logs
tail -f logs/fim/fim-agent.log
tail -f logs/cmdb/cmdb-test.log
tail -f logs/ansible/ansible.log

# Search for errors
grep -i error logs/*/*.log
grep -i fail logs/*/*.log
```

---

## 🚀 Advanced Testing

### **Performance Testing**

```bash
# Run performance tests
./tests/scripts/run-lab-tests.sh --benchmark

# Test with large datasets
./tests/scripts/run-lab-tests.sh --large-dataset

# Memory usage testing
./tests/scripts/run-lab-tests.sh --memory-test
```

### **Continuous Testing**

```bash
# Run tests in loop
./tests/scripts/run-lab-tests.sh --loop --count 10

# Run tests with intervals
./tests/scripts/run-lab-tests.sh --interval 300
```

### **Custom Test Scenarios**

```bash
# Test specific file types
python3 tests/scripts/test-fim.py --file-types "txt,conf,sh"

# Test specific system components
python3 tests/scripts/test-cmdb.py --components "system,hardware,network"

# Test with custom configurations
./tests/scripts/run-lab-tests.sh --config custom-test-config.json
```

### **Test Automation**

#### **Scheduled Testing**
```bash
# Add to crontab for daily testing
0 2 * * * /path/to/lab/tests/scripts/run-lab-tests.sh --quiet
```

#### **CI/CD Integration**
```bash
# Run tests in CI pipeline
./tests/scripts/run-lab-tests.sh --ci-mode --exit-on-fail
```

### **Test Data Management**

```bash
# Clean test data
./tests/scripts/run-lab-tests.sh --clean

# Backup test results
./tests/scripts/run-lab-tests.sh --backup

# Restore test data
./tests/scripts/run-lab-tests.sh --restore
```

---

## 📈 Test Metrics

### **Key Performance Indicators**

- **Test Coverage**: Percentage of code tested
- **Test Execution Time**: Time to complete all tests
- **Success Rate**: Percentage of passing tests
- **Failure Rate**: Percentage of failing tests
- **Test Reliability**: Consistency of test results

### **Test Reporting**

```bash
# Generate JSON report
./tests/scripts/run-lab-tests.sh --format json

# Generate HTML report
./tests/scripts/run-lab-tests.sh --format html

# Generate CSV report
./tests/scripts/run-lab-tests.sh --format csv
```

---

## 🎯 Best Practices

### **Testing Guidelines**

1. **Always run tests before deployment**
2. **Keep test data separate from production data**
3. **Clean up test artifacts after completion**
4. **Document test failures and resolutions**
5. **Regularly update test scenarios for new features**

### **Test Maintenance**

1. **Review test results regularly**
2. **Update test scenarios as needed**
3. **Monitor test performance**
4. **Keep test documentation current**
5. **Validate test data integrity**

---

## 🆘 Getting Help

### **Test Script Help**

```bash
# Get help for individual scripts
python3 tests/scripts/test-fim.py --help
python3 tests/scripts/test-cmdb.py --help
./tests/scripts/run-lab-tests.sh --help
```

### **Support Resources**

- **Troubleshooting Guide**: `../setup/guides/TROUBLESHOOTING-GUIDE.md`
- **User Guide**: `../setup/guides/HOW-TO-USE-THIS-LAB.md`
- **Test Logs**: `logs/` directory
- **Test Results**: `data/` directory

### **Community Support**

- **GitHub Issues**: Report bugs and request features
- **Documentation**: Check the comprehensive guides
- **Logs**: Review test logs for error details
- **Configuration**: Verify test configuration settings

---

## 📚 Additional Resources

- **[HOW-TO-USE-THIS-LAB.md](../setup/guides/HOW-TO-USE-THIS-LAB.md)** - Complete user guide
- **[TROUBLESHOOTING-GUIDE.md](../setup/guides/TROUBLESHOOTING-GUIDE.md)** - Error solutions
- **[AWS-DEPLOYMENT-GUIDE.md](../setup/guides/AWS-DEPLOYMENT-GUIDE.md)** - Deployment instructions
- **[NEXT-STEPS.md](../setup/guides/NEXT-STEPS.md)** - Advanced usage

---

**Happy Testing! 🧪✨**
