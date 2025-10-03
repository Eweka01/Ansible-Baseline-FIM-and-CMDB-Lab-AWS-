# Test Scripts Documentation

This directory contains all test scripts for the Ansible Baseline, FIM, and CMDB lab. Each script is designed to test specific functionality and validate the lab components.

## 📁 Test Scripts Overview

| Script | Purpose | Functionality | Usage |
|--------|---------|---------------|-------|
| `test-fim.py` | FIM Agent Testing | Tests File Integrity Monitoring agent functionality | `python3 test-fim.py` |
| `test-fim-simple.py` | Simplified FIM Testing | Standalone FIM testing without complex imports | `python3 test-fim-simple.py` |
| `test-cmdb.py` | CMDB Testing | Tests Configuration Management Database collector | `python3 test-cmdb.py` |
| `run-lab-tests.sh` | Comprehensive Testing | Runs all lab tests and generates reports | `./run-lab-tests.sh` |

## 🧪 Individual Script Documentation

### 1. test-fim.py - Advanced FIM Testing

**Purpose**: Comprehensive testing of the File Integrity Monitoring agent with full functionality.

**Features**:
- Tests FIM agent initialization and configuration
- Validates file monitoring and change detection
- Tests baseline creation and comparison
- Validates alert generation and reporting
- Tests different file types and monitoring scenarios

**Usage**:
```bash
# Run basic FIM test
python3 tests/scripts/test-fim.py

# Run with verbose output
python3 tests/scripts/test-fim.py --verbose

# Run with specific test directory
python3 tests/scripts/test-fim.py --test-dir /tmp/fim-test
```

**Expected Output**:
- FIM agent initialization status
- File change detection results
- Baseline comparison results
- Alert generation status

### 2. test-fim-simple.py - Simplified FIM Testing

**Purpose**: Standalone FIM testing without complex import dependencies.

**Features**:
- Simple file monitoring without external dependencies
- Basic hash calculation and comparison
- Local file change detection
- Simplified reporting for quick testing

**Usage**:
```bash
# Run simple FIM test
python3 tests/scripts/test-fim-simple.py

# Run with custom monitoring directory
python3 tests/scripts/test-fim-simple.py --monitor-dir /etc
```

**Expected Output**:
- File monitoring status
- Hash calculation results
- Change detection summary
- Simple test report

### 3. test-cmdb.py - CMDB Testing

**Purpose**: Tests the Configuration Management Database collector functionality.

**Features**:
- Tests system information collection
- Validates hardware information gathering
- Tests software and package detection
- Validates network interface detection
- Tests data storage and retrieval

**Usage**:
```bash
# Run CMDB test
python3 tests/scripts/test-cmdb.py

# Run with specific output directory
python3 tests/scripts/test-cmdb.py --output-dir /tmp/cmdb-test
```

**Expected Output**:
- System information collection status
- Hardware detection results
- Software inventory results
- Network configuration data
- Data validation results

### 4. run-lab-tests.sh - Comprehensive Test Suite

**Purpose**: Runs all lab tests and generates comprehensive reports.

**Features**:
- Executes all individual test scripts
- Generates detailed test reports
- Validates lab functionality end-to-end
- Creates test summaries and logs
- Provides pass/fail status for each component

**Usage**:
```bash
# Run all lab tests
./tests/scripts/run-lab-tests.sh

# Run with verbose output
./tests/scripts/run-lab-tests.sh --verbose

# Run specific test categories
./tests/scripts/run-lab-tests.sh --fim-only
./tests/scripts/run-lab-tests.sh --cmdb-only
```

**Expected Output**:
- Comprehensive test report
- Individual component test results
- Overall lab functionality status
- Detailed logs and error reporting

## 🔧 Test Configuration

### Environment Variables

```bash
# Set test directories
export FIM_TEST_DIR="/tmp/fim-test"
export CMDB_TEST_DIR="/tmp/cmdb-test"
export LOG_DIR="/tmp/lab-logs"

# Set test verbosity
export TEST_VERBOSE="true"
export TEST_DEBUG="false"
```

### Test Data Management

```bash
# Clean test data
./tests/scripts/run-lab-tests.sh --clean

# Backup test results
./tests/scripts/run-lab-tests.sh --backup

# Restore test data
./tests/scripts/run-lab-tests.sh --restore
```

## 📊 Test Results Analysis

### Understanding Test Output

1. **PASS** - Test completed successfully
2. **FAIL** - Test failed with errors
3. **SKIP** - Test was skipped (usually due to missing dependencies)
4. **WARN** - Test completed with warnings

### Common Test Scenarios

#### FIM Testing Scenarios
- **File Creation**: Tests detection of new files
- **File Modification**: Tests detection of file changes
- **File Deletion**: Tests detection of removed files
- **Permission Changes**: Tests detection of permission modifications
- **Directory Monitoring**: Tests recursive directory monitoring

#### CMDB Testing Scenarios
- **System Information**: Tests collection of OS and hardware details
- **Network Configuration**: Tests network interface detection
- **Software Inventory**: Tests installed package detection
- **Service Status**: Tests running service detection
- **User Accounts**: Tests user and group information

## 🚨 Troubleshooting Tests

### Common Issues

1. **Permission Errors**
   ```bash
   # Fix permission issues
   sudo chown -R $USER:$USER tests/scripts/
   chmod +x tests/scripts/*.py
   ```

2. **Import Errors**
   ```bash
   # Install required dependencies
   pip3 install -r requirements.txt
   ```

3. **Path Issues**
   ```bash
   # Set correct Python path
   export PYTHONPATH="${PYTHONPATH}:$(pwd)"
   ```

### Debug Mode

```bash
# Run tests in debug mode
python3 tests/scripts/test-fim.py --debug
python3 tests/scripts/test-cmdb.py --debug
./tests/scripts/run-lab-tests.sh --debug
```

## 📈 Test Performance

### Benchmarking

```bash
# Run performance tests
./tests/scripts/run-lab-tests.sh --benchmark

# Test with large datasets
./tests/scripts/run-lab-tests.sh --large-dataset

# Memory usage testing
./tests/scripts/run-lab-tests.sh --memory-test
```

### Continuous Testing

```bash
# Run tests in loop
./tests/scripts/run-lab-tests.sh --loop --count 10

# Run tests with intervals
./tests/scripts/run-lab-tests.sh --interval 300
```

## 📝 Test Reporting

### Report Formats

- **JSON**: Machine-readable test results
- **HTML**: Human-readable test reports
- **CSV**: Spreadsheet-compatible data
- **XML**: Structured test data

### Report Generation

```bash
# Generate JSON report
./tests/scripts/run-lab-tests.sh --format json

# Generate HTML report
./tests/scripts/run-lab-tests.sh --format html

# Generate CSV report
./tests/scripts/run-lab-tests.sh --format csv
```

## 🔄 Test Automation

### Scheduled Testing

```bash
# Add to crontab for daily testing
0 2 * * * /path/to/lab/tests/scripts/run-lab-tests.sh --quiet
```

### CI/CD Integration

```bash
# Run tests in CI pipeline
./tests/scripts/run-lab-tests.sh --ci-mode --exit-on-fail
```

## 📚 Best Practices

1. **Always run tests before deployment**
2. **Keep test data separate from production data**
3. **Clean up test artifacts after completion**
4. **Document test failures and resolutions**
5. **Regularly update test scenarios for new features**

## 🆘 Getting Help

### Test Script Help

```bash
# Get help for individual scripts
python3 tests/scripts/test-fim.py --help
python3 tests/scripts/test-cmdb.py --help
./tests/scripts/run-lab-tests.sh --help
```

### Debug Information

```bash
# Enable debug logging
export DEBUG="true"
./tests/scripts/run-lab-tests.sh --debug
```

### Support

For test-related issues:
1. Check the troubleshooting guide
2. Review test logs in `logs/` directory
3. Verify test dependencies are installed
4. Ensure proper permissions on test directories
