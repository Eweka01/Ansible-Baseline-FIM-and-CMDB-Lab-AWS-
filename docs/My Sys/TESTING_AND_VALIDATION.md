# Testing and Validation

## Overview

This document provides comprehensive testing procedures, validation methods, and quality assurance practices for the Ansible Baseline, FIM, and CMDB lab environment.

## Static Analysis and Linting

### Ansible Linting

#### Installation
```bash
# Install ansible-lint
pip install ansible-lint

# Install yamllint for YAML validation
pip install yamllint
```

#### Linting Commands
```bash
# Lint all Ansible files
ansible-lint ansible/

# Lint specific playbook
ansible-lint ansible/playbooks/setup-aws-instances.yml

# Lint with specific rules
ansible-lint ansible/ --rules-dir custom-rules/

# YAML syntax validation
yamllint ansible/
```

#### Expected Output
```bash
# Clean output (no issues)
$ ansible-lint ansible/playbooks/setup-aws-instances.yml
$

# Issues found
$ ansible-lint ansible/playbooks/setup-aws-instances.yml
WARNING: Couldn't open /etc/ansible/hosts: [Errno 13] Permission denied: '/etc/ansible/hosts'
WARNING: Couldn't open /etc/ansible/ansible.cfg: [Errno 13] Permission denied: '/etc/ansible/ansible.cfg'
```

### Python Code Linting

#### Installation
```bash
# Install flake8 for Python linting
pip install flake8

# Install black for code formatting
pip install black
```

#### Linting Commands
```bash
# Lint Python files
flake8 fim/agents/ cmdb/scripts/

# Format Python code
black fim/agents/ cmdb/scripts/

# Check formatting without changes
black --check fim/agents/ cmdb/scripts/
```

#### Expected Output
```bash
# Clean output
$ flake8 fim/agents/fim-agent.py
$

# Issues found
$ flake8 fim/agents/fim-agent.py
fim/agents/fim-agent.py:45:1: E302 expected 2 blank lines before class definition
fim/agents/fim-agent.py:123:80: E501 line too long (85 > 79 characters)
```

## Dry Run and Validation

### Ansible Check Mode

#### Syntax Validation
```bash
# Check playbook syntax
ansible-playbook --syntax-check ansible/playbooks/setup-aws-instances.yml

# Expected output
playbook: ansible/playbooks/setup-aws-instances.yml
```

#### Dry Run Execution
```bash
# Dry run with check mode
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml --check

# Dry run with diff
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml --check --diff

# Dry run with verbose output
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml --check -vvv
```

#### Expected Output
```bash
# Successful dry run
PLAY [AWS Lab Environment Setup] **********************************************

TASK [Display setup information] **********************************************
ok: [manage-node-1] => {
    "msg": [
        "Setting up lab environment on manage-node-1",
        "Instance: manage-node-1 (18.234.152.228)",
        "Environment: production",
        "OS: Amazon 2023",
        "Instance Type: t2.micro",
        "Playbook started at: 2025-01-03T14:35:00Z"
    ]
}

TASK [Update package cache (Amazon Linux)] ************************************
changed: [manage-node-1]

PLAY RECAP *********************************************************************
manage-node-1              : ok=2    changed=1    unreachable=0    failed=0
```

### Inventory Validation

#### Inventory Syntax Check
```bash
# Validate inventory syntax
ansible-inventory -i ansible/inventory/aws-instances --list

# Test inventory connectivity
ansible-inventory -i ansible/inventory/aws-instances --list --yaml
```

#### Expected Output
```yaml
# Inventory structure
all:
  children:
    aws_instances:
      children:
        databases:
          hosts:
            manage-node-2:
              ansible_host: 54.242.234.69
              ansible_user: ubuntu
        monitoring:
          hosts:
            manage-node-3:
              ansible_host: 13.217.82.23
              ansible_user: ubuntu
        webservers:
          hosts:
            manage-node-1:
              ansible_host: 18.234.152.228
              ansible_user: ec2-user
```

## Functional Testing

### Connectivity Testing

#### SSH Connectivity Test
```bash
# Test SSH connectivity to all instances
ansible aws_instances -i ansible/inventory/aws-instances -m ping

# Test specific instance
ansible manage-node-1 -i ansible/inventory/aws-instances -m ping

# Test with verbose output
ansible aws_instances -i ansible/inventory/aws-instances -m ping -vvv
```

#### Expected Output
```bash
# Successful connectivity
manage-node-1 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
manage-node-2 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
manage-node-3 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

### Service Testing

#### Service Status Validation
```bash
# Check service status
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "systemctl is-active fim-agent cmdb-collector.timer node_exporter"

# Check service enabled status
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "systemctl is-enabled fim-agent cmdb-collector.timer node_exporter"
```

#### Expected Output
```bash
# All services active
manage-node-1 | CHANGED | rc=0 >>
active
active
active

manage-node-2 | CHANGED | rc=0 >>
active
active
active

manage-node-3 | CHANGED | rc=0 >>
active
active
active
```

#### Service Log Validation
```bash
# Check service logs
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "journalctl -u fim-agent -n 5 --no-pager"

# Check for errors in logs
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "journalctl -u fim-agent --since '1 hour ago' | grep -i error"
```

### FIM Testing

#### FIM Baseline Test
```bash
# Initialize FIM baseline
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "/opt/lab-env/bin/python /opt/lab-environment/fim-agent.py --init-baseline"

# Verify baseline creation
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "ls -la /var/lib/fim/baseline.json"
```

#### Expected Output
```bash
# Baseline created successfully
manage-node-1 | CHANGED | rc=0 >>
FIM baseline initialized successfully
Baseline file: /var/lib/fim/baseline.json
Files monitored: 1234
Baseline created at: 2025-01-03T14:35:00Z

manage-node-1 | CHANGED | rc=0 >>
-rw-r--r-- 1 root root 12345 Jan  3 14:35 /var/lib/fim/baseline.json
```

#### FIM Change Detection Test
```bash
# Create test file
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "echo 'test content' > /etc/fim-test.txt"

# Wait for FIM scan
sleep 10

# Check for FIM alert
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "tail -n 5 /var/log/fim-agent.log | grep 'NEW_FILE'"

# Clean up test file
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "rm /etc/fim-test.txt"
```

#### Expected Output
```bash
# FIM alert generated
manage-node-1 | CHANGED | rc=0 >>
{"timestamp": "2025-01-03T14:35:00Z", "type": "NEW_FILE", "severity": "MEDIUM", "file_path": "/etc/fim-test.txt", "hostname": "manage-node-1", "message": "New file detected: /etc/fim-test.txt"}
```

### CMDB Testing

#### CMDB Collection Test
```bash
# Run CMDB collection
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "/opt/lab-env/bin/python /opt/lab-environment/cmdb-collector.py"

# Verify data collection
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "ls -la /var/lib/cmdb/data/"

# Validate data format
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "python3 -m json.tool /var/lib/cmdb/data/system-info.json | head -20"
```

#### Expected Output
```bash
# CMDB collection successful
manage-node-1 | CHANGED | rc=0 >>
CMDB data collection completed
Data file: /var/lib/cmdb/data/system-info.json
Collection timestamp: 2025-01-03T14:35:00Z
Files collected: 5
Data size: 15.2 KB

manage-node-1 | CHANGED | rc=0 >>
-rw-r--r-- 1 root root 15543 Jan  3 14:35 /var/lib/cmdb/data/system-info.json

manage-node-1 | CHANGED | rc=0 >>
{
    "collection_timestamp": "2025-01-03T14:35:00Z",
    "hostname": "manage-node-1",
    "system_info": {
        "hostname": "manage-node-1",
        "fqdn": "manage-node-1.ec2.internal",
        "operating_system": "Linux",
        "kernel_version": "5.15.0-1028-aws",
        "architecture": "x86_64"
    }
}
```

### Monitoring Testing

#### Prometheus Targets Test
```bash
# Check Prometheus targets
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, instance: .labels.instance, health: .health}'

# Check specific job targets
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.labels.job=="aws-nodes")'
```

#### Expected Output
```bash
# All targets healthy
{
  "job": "aws-nodes",
  "instance": "host.docker.internal:9101",
  "health": "up"
}
{
  "job": "aws-nodes",
  "instance": "host.docker.internal:9102",
  "health": "up"
}
{
  "job": "aws-nodes",
  "instance": "host.docker.internal:9103",
  "health": "up"
}
```

#### Metrics Validation
```bash
# Test Node Exporter metrics
curl -s http://localhost:9101/metrics | grep node_cpu_seconds_total | head -5

# Test FIM metrics
curl -s http://localhost:8080/metrics | grep fim_events_total

# Test CMDB metrics
curl -s http://localhost:8081/metrics | grep cmdb_collections_total
```

#### Expected Output
```bash
# Node Exporter metrics
node_cpu_seconds_total{cpu="0",mode="idle"} 12345.67
node_cpu_seconds_total{cpu="0",mode="iowait"} 12.34
node_cpu_seconds_total{cpu="0",mode="irq"} 0.00
node_cpu_seconds_total{cpu="0",mode="nice"} 0.00
node_cpu_seconds_total{cpu="0",mode="softirq"} 5.67

# FIM metrics
fim_events_total{event_type="FILE_CHANGE",severity="HIGH"} 1
fim_events_total{event_type="NEW_FILE",severity="MEDIUM"} 1

# CMDB metrics
cmdb_collections_total 1
system_packages_total 516
system_cpu_cores 1
```

### Grafana Testing

#### Dashboard Access Test
```bash
# Test Grafana API access
curl -u admin:admin http://localhost:3000/api/health

# Test data source connectivity
curl -u admin:admin http://localhost:3000/api/datasources
```

#### Expected Output
```bash
# Grafana health check
{"database":"ok","version":"9.0.0"}

# Data sources
[
  {
    "id": 1,
    "name": "Prometheus",
    "type": "prometheus",
    "url": "http://prometheus:9090",
    "access": "proxy"
  }
]
```

#### Dashboard Validation
```bash
# Test dashboard queries
curl -u admin:admin "http://localhost:3000/api/datasources/1/query" -H "Content-Type: application/json" -d '{"query": "up", "time": "2025-01-03T14:35:00Z"}'
```

## Integration Testing

### End-to-End Testing

#### Complete Deployment Test
```bash
# Full deployment test
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml

# Verify all components
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "systemctl is-active fim-agent cmdb-collector.timer node_exporter"

# Test monitoring stack
docker compose -f docker-compose.yml up -d
./setup-ssh-tunnel-monitoring.sh

# Verify monitoring
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health != "up")'
```

#### Expected Output
```bash
# All services active
manage-node-1 | CHANGED | rc=0 >>
active
active
active

# No unhealthy targets
# (empty output indicates all targets are healthy)
```

### Performance Testing

#### Resource Usage Test
```bash
# Check CPU usage
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "top -bn1 | grep 'Cpu(s)'"

# Check memory usage
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "free -h"

# Check disk usage
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "df -h"
```

#### Expected Output
```bash
# CPU usage
manage-node-1 | CHANGED | rc=0 >>
%Cpu(s):  2.1 us,  1.2 sy,  0.0 ni, 96.4 id,  0.2 wa,  0.0 hi,  0.1 si,  0.0 st

# Memory usage
manage-node-1 | CHANGED | rc=0 >>
              total        used        free      shared  buff/cache   available
Mem:           1.0G        456M        234M         12M        312M        512M
Swap:            0B          0B          0B

# Disk usage
manage-node-1 | CHANGED | rc=0 >>
Filesystem      Size  Used Avail Use% Mounted on
/dev/xvda1      8.0G  2.1G  5.9G  27% /
```

## Automated Testing Scripts

### Test Suite Execution
**File**: `tests/run-all-tests.sh`

```bash
#!/bin/bash
# Comprehensive test suite

set -e

echo "Starting comprehensive test suite..."

# Static analysis
echo "Running static analysis..."
ansible-lint ansible/
yamllint ansible/
flake8 fim/agents/ cmdb/scripts/

# Syntax validation
echo "Validating syntax..."
ansible-playbook --syntax-check ansible/playbooks/setup-aws-instances.yml
ansible-playbook --syntax-check ansible/playbooks/setup-baseline.yml

# Connectivity test
echo "Testing connectivity..."
ansible aws_instances -i ansible/inventory/aws-instances -m ping

# Service validation
echo "Validating services..."
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "systemctl is-active fim-agent cmdb-collector.timer node_exporter"

# FIM testing
echo "Testing FIM..."
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "/opt/lab-env/bin/python /opt/lab-environment/fim-agent.py --scan-once"

# CMDB testing
echo "Testing CMDB..."
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "/opt/lab-env/bin/python /opt/lab-environment/cmdb-collector.py"

# Monitoring testing
echo "Testing monitoring..."
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health != "up")'

echo "All tests completed successfully!"
```

### Individual Test Scripts

#### FIM Test Script
**File**: `tests/scripts/test-fim.py`

```python
#!/usr/bin/env python3
"""
FIM Testing Script
"""

import subprocess
import json
import time
import os

def test_fim_baseline():
    """Test FIM baseline initialization"""
    print("Testing FIM baseline initialization...")
    
    result = subprocess.run([
        'ansible', 'aws_instances', '-i', 'ansible/inventory/aws-instances',
        '-m', 'shell', '-a', '/opt/lab-env/bin/python /opt/lab-environment/fim-agent.py --init-baseline'
    ], capture_output=True, text=True)
    
    if result.returncode == 0:
        print("✓ FIM baseline initialization successful")
        return True
    else:
        print(f"✗ FIM baseline initialization failed: {result.stderr}")
        return False

def test_fim_change_detection():
    """Test FIM change detection"""
    print("Testing FIM change detection...")
    
    # Create test file
    subprocess.run([
        'ansible', 'aws_instances', '-i', 'ansible/inventory/aws-instances',
        '-m', 'shell', '-a', 'echo "test content" > /etc/fim-test.txt'
    ])
    
    # Wait for scan
    time.sleep(10)
    
    # Check for alert
    result = subprocess.run([
        'ansible', 'aws_instances', '-i', 'ansible/inventory/aws-instances',
        '-m', 'shell', '-a', 'tail -n 5 /var/log/fim-agent.log | grep "NEW_FILE"'
    ], capture_output=True, text=True)
    
    # Clean up
    subprocess.run([
        'ansible', 'aws_instances', '-i', 'ansible/inventory/aws-instances',
        '-m', 'shell', '-a', 'rm /etc/fim-test.txt'
    ])
    
    if "NEW_FILE" in result.stdout:
        print("✓ FIM change detection successful")
        return True
    else:
        print("✗ FIM change detection failed")
        return False

if __name__ == "__main__":
    success = True
    success &= test_fim_baseline()
    success &= test_fim_change_detection()
    
    if success:
        print("\n✓ All FIM tests passed")
        exit(0)
    else:
        print("\n✗ Some FIM tests failed")
        exit(1)
```

#### CMDB Test Script
**File**: `tests/scripts/test-cmdb.py`

```python
#!/usr/bin/env python3
"""
CMDB Testing Script
"""

import subprocess
import json

def test_cmdb_collection():
    """Test CMDB data collection"""
    print("Testing CMDB data collection...")
    
    result = subprocess.run([
        'ansible', 'aws_instances', '-i', 'ansible/inventory/aws-instances',
        '-m', 'shell', '-a', '/opt/lab-env/bin/python /opt/lab-environment/cmdb-collector.py'
    ], capture_output=True, text=True)
    
    if result.returncode == 0:
        print("✓ CMDB data collection successful")
        return True
    else:
        print(f"✗ CMDB data collection failed: {result.stderr}")
        return False

def test_cmdb_data_validation():
    """Test CMDB data validation"""
    print("Testing CMDB data validation...")
    
    result = subprocess.run([
        'ansible', 'aws_instances', '-i', 'ansible/inventory/aws-instances',
        '-m', 'shell', '-a', 'python3 -c "import json; data=json.load(open(\'/var/lib/cmdb/data/system-info.json\')); print(f\'Hostname: {data[\"hostname\"]}\'); print(f\'OS: {data[\"system_info\"][\"operating_system\"]}\'); print(f\'CPU Cores: {data[\"hardware\"][\"cpu_cores\"]}\')"'
    ], capture_output=True, text=True)
    
    if result.returncode == 0 and "Hostname:" in result.stdout:
        print("✓ CMDB data validation successful")
        return True
    else:
        print("✗ CMDB data validation failed")
        return False

if __name__ == "__main__":
    success = True
    success &= test_cmdb_collection()
    success &= test_cmdb_data_validation()
    
    if success:
        print("\n✓ All CMDB tests passed")
        exit(0)
    else:
        print("\n✗ Some CMDB tests failed")
        exit(1)
```

## CI/CD Integration

### GitHub Actions Workflow
**File**: `.github/workflows/test.yml`

```yaml
name: Test Lab Environment

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.9'
    
    - name: Install dependencies
      run: |
        pip install ansible ansible-lint yamllint flake8 black
    
    - name: Lint Ansible
      run: ansible-lint ansible/
    
    - name: Lint YAML
      run: yamllint ansible/
    
    - name: Lint Python
      run: flake8 fim/agents/ cmdb/scripts/
    
    - name: Check Python formatting
      run: black --check fim/agents/ cmdb/scripts/

  syntax:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.9'
    
    - name: Install Ansible
      run: pip install ansible
    
    - name: Check playbook syntax
      run: ansible-playbook --syntax-check ansible/playbooks/setup-aws-instances.yml
    
    - name: Check inventory
      run: ansible-inventory -i ansible/inventory/aws-instances --list

  functional:
    runs-on: ubuntu-latest
    needs: [lint, syntax]
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.9'
    
    - name: Install dependencies
      run: pip install ansible pytest
    
    - name: Run functional tests
      run: |
        python tests/scripts/test-fim.py
        python tests/scripts/test-cmdb.py
```

### Test Artifacts

#### Test Reports
```bash
# Generate test report
./tests/run-all-tests.sh > test-report-$(date +%Y%m%d-%H%M%S).txt 2>&1

# Test coverage report
coverage run -m pytest tests/
coverage report -m
coverage html
```

#### Performance Benchmarks
```bash
# Performance test
time ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml

# Resource usage test
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "ps aux | grep -E '(fim-agent|cmdb-collector|node_exporter)'"
```

This comprehensive testing framework ensures the reliability, performance, and quality of the lab environment through static analysis, functional testing, integration testing, and automated CI/CD validation.
