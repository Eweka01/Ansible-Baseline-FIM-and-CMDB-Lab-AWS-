# 🧪 Test Scripts Directory

This directory contains all testing scripts for the Ansible Baseline, FIM, and CMDB Lab. All scripts are designed to be **safe for production environments** and won't damage your system.

## 📋 Available Test Scripts

### 1️⃣ **safe-fim-test.sh** - Safe FIM Threshold Testing
**Purpose**: Test FIM alert thresholds without damaging the system

**Usage**:
```bash
./safe-fim-test.sh critical      # Test critical file changes (safe)
./safe-fim-test.sh high-activity # Test high activity threshold (safe)
./safe-fim-test.sh unauthorized  # Test FIM detection (safe simulation)
./safe-fim-test.sh all          # Run all safe FIM tests
./safe-fim-test.sh cleanup      # Clean up safe test artifacts
./safe-fim-test.sh status       # Show current FIM metrics
```

**Safety Features**:
- ✅ Only creates files in `/tmp/` and `/var/tmp/` directories
- ✅ Never modifies system files (`/etc/`, `/root/`, etc.)
- ✅ Automatically cleans up all test files
- ✅ Safe for production-like environments

### 2️⃣ **agent-status-test.sh** - Agent Monitoring
**Purpose**: Monitor FIM and CMDB agent status across all nodes

**Usage**:
```bash
./agent-status-test.sh status    # Check all agent statuses
./agent-status-test.sh fim       # Check FIM agent status only
./agent-status-test.sh cmdb      # Check CMDB collector status only
./agent-status-test.sh targets   # Check Prometheus targets
./agent-status-test.sh metrics   # Check agent metrics
./agent-status-test.sh logs      # Check agent logs
./agent-status-test.sh ports     # Check agent ports
./agent-status-test.sh restart   # Restart all agents
```

**Features**:
- ✅ Read-only monitoring (no system modifications)
- ✅ Comprehensive agent health checking
- ✅ Prometheus target status verification
- ✅ Agent log analysis

### 3️⃣ **live-remediation-test.sh** - Live Remediation Testing
**Purpose**: Demonstrate live automated remediation in action

**Usage**:
```bash
./live-remediation-test.sh fim        # Test FIM remediation flow
./live-remediation-test.sh cmdb       # Test CMDB remediation flow
./live-remediation-test.sh webhook    # Test webhook processing
./live-remediation-test.sh flow       # Test complete alert-to-remediation flow
./live-remediation-test.sh dashboards # Show live dashboard URLs
./live-remediation-test.sh monitor    # Monitor remediation logs only
./live-remediation-test.sh all        # Run all remediation tests
```

**Features**:
- ✅ Live remediation flow testing
- ✅ Webhook processing verification
- ✅ Dashboard URL display
- ✅ Real-time log monitoring

### 4️⃣ **test-fim-thresholds.sh** - Original FIM Threshold Testing
**Purpose**: Original FIM threshold testing script

**Usage**:
```bash
./test-fim-thresholds.sh critical     # Test critical file changes
./test-fim-thresholds.sh high-activity # Test high activity threshold
./test-fim-thresholds.sh unauthorized  # Test unauthorized changes
./test-fim-thresholds.sh all          # Run all tests
./test-fim-thresholds.sh cleanup      # Clean up test artifacts
./test-fim-thresholds.sh status       # Show current metrics
```

### 5️⃣ **test-alert-remediation.sh** - Alert Remediation Testing
**Purpose**: Comprehensive alert and remediation testing

**Usage**:
```bash
./test-alert-remediation.sh fim-only   # Test FIM alerts only
./test-alert-remediation.sh cmdb-only  # Test CMDB alerts only
./test-alert-remediation.sh status     # Check system status
./test-alert-remediation.sh cleanup    # Clean up test artifacts
./test-alert-remediation.sh            # Run full end-to-end test
```

### 6️⃣ **test-fim-cmdb-metrics.sh** - FIM/CMDB Metrics Testing
**Purpose**: Test FIM and CMDB metrics collection

**Usage**:
```bash
./test-fim-cmdb-metrics.sh status      # Check metrics status
./test-fim-cmdb-metrics.sh test        # Run metrics tests
./test-fim-cmdb-metrics.sh cleanup     # Clean up test files
```

## 🛡️ Safety Features

All test scripts include the following safety measures:

- **Safe File Locations**: Only create files in `/tmp/` and `/var/tmp/` directories
- **No System Modifications**: Never modify critical system files
- **Automatic Cleanup**: All scripts include cleanup functionality
- **Production Safe**: Designed to be safe for production-like environments
- **Read-Only Monitoring**: Most scripts are read-only and don't modify anything

## 🎯 Quick Start Guide

### For FIM Testing:
```bash
cd test/
./safe-fim-test.sh status    # Check current FIM status
./safe-fim-test.sh critical  # Test critical file change threshold
./safe-fim-test.sh cleanup   # Clean up test files
```

### For Agent Monitoring:
```bash
cd test/
./agent-status-test.sh status  # Check all agent statuses
./agent-status-test.sh logs    # Check agent logs
./agent-status-test.sh restart # Restart agents if needed
```

### For Live Remediation Testing:
```bash
cd test/
./live-remediation-test.sh dashboards  # Show dashboard URLs
./live-remediation-test.sh flow        # Test complete remediation flow
./live-remediation-test.sh monitor     # Monitor remediation logs
```

## 📊 Live Dashboards

When running tests, you can monitor the results in real-time using these dashboards:

- **HTML Restoration Dashboard**: `http://localhost:8089/restoration-monitoring-dashboard.html`
- **Grafana Monitoring Dashboard**: `http://localhost:3000`
- **Prometheus Alerts**: `http://localhost:9090/alerts`
- **Prometheus Targets**: `http://localhost:9090/targets`
- **Alertmanager**: `http://localhost:9093`

## 🔧 Prerequisites

Before running any test scripts, ensure:

1. **Prometheus is running**: `http://localhost:9090`
2. **Grafana is running**: `http://localhost:3000`
3. **SSH tunnels are active**: For AWS node connectivity
4. **Webhook receiver is running**: For automated remediation testing

## 📝 Notes

- All scripts are executable and ready to use
- Scripts automatically check prerequisites before running
- Use `./script-name.sh help` for detailed usage information
- All test files are automatically cleaned up after testing
- Scripts provide detailed logging and status information
