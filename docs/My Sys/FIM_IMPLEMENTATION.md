# File Integrity Monitoring (FIM) Implementation

## Overview

The File Integrity Monitoring (FIM) system provides real-time detection of unauthorized file changes across critical system directories. It implements SHA-256 hash-based integrity verification with automated alerting and Prometheus metrics integration.

## FIM Architecture

### Core Components

#### FIM Agent
**File**: `fim/agents/fim-agent.py`

```python
class FIMAgent:
    def __init__(self, config_file='/etc/fim/fim-config.json'):
        self.config_file = config_file
        self.config = self.load_config()
        self.setup_logging()
        self.observer = Observer()
        self.running = False
        
        # Setup signal handlers for graceful shutdown
        signal.signal(signal.SIGINT, self.signal_handler)
        signal.signal(signal.SIGTERM, self.signal_handler)
```

#### Configuration Management
**File**: `fim/agents/fim-config.json`

```json
{
    "monitored_paths": [
        "/etc",
        "/usr/bin",
        "/usr/sbin",
        "/var/log",
        "/home",
        "/opt"
    ],
    "excluded_paths": [
        "/tmp",
        "/var/tmp",
        "/var/cache",
        "/var/log/*.log",
        "/proc",
        "/sys",
        "/dev"
    ],
    "scan_interval": 300,
    "hash_algorithm": "sha256",
    "alert_on_change": true,
    "log_level": "INFO"
}
```

## Monitored Paths and Rationale

### Critical System Directories

#### `/etc` - System Configuration
**Why Monitored**: Contains critical system configuration files
**Key Files**:
- `/etc/passwd` - User account information
- `/etc/shadow` - Encrypted password data
- `/etc/group` - Group membership data
- `/etc/ssh/sshd_config` - SSH server configuration
- `/etc/audit/auditd.conf` - Audit daemon configuration

**Security Impact**: Unauthorized changes could compromise system security, user accounts, or service configurations.

#### `/usr/bin` and `/usr/sbin` - System Binaries
**Why Monitored**: Contains executable system binaries and utilities
**Key Files**:
- `/usr/bin/sudo` - Privilege escalation utility
- `/usr/bin/passwd` - Password change utility
- `/usr/sbin/sshd` - SSH daemon binary
- `/usr/bin/su` - Switch user utility

**Security Impact**: Binary modification could introduce backdoors, rootkits, or malicious functionality.

#### `/var/log` - System Logs
**Why Monitored**: Contains system and security logs
**Key Files**:
- `/var/log/auth.log` - Authentication events
- `/var/log/audit/audit.log` - Audit trail
- `/var/log/syslog` - System messages
- `/var/log/secure` - Security events

**Security Impact**: Log tampering could hide evidence of security breaches or unauthorized access.

#### `/home` - User Directories
**Why Monitored**: Contains user data and configurations
**Key Files**:
- `/home/*/.ssh/authorized_keys` - SSH public keys
- `/home/*/.bashrc` - Shell configuration
- `/home/*/.profile` - User profile settings

**Security Impact**: Unauthorized access to user directories could lead to privilege escalation or data theft.

#### `/opt` - Optional Software
**Why Monitored**: Contains custom applications and lab components
**Key Files**:
- `/opt/lab-environment/fim-agent.py` - FIM agent binary
- `/opt/lab-environment/cmdb-collector.py` - CMDB collector
- `/opt/lab-env/` - Python virtual environment

**Security Impact**: Modification of lab components could compromise monitoring and data collection.

### Excluded Paths

#### Temporary Directories
- `/tmp` - Temporary files (frequently changing)
- `/var/tmp` - Temporary files (frequently changing)
- `/var/cache` - Cache files (frequently changing)

#### Dynamic System Directories
- `/proc` - Process information (kernel-generated)
- `/sys` - System information (kernel-generated)
- `/dev` - Device files (kernel-generated)

#### Log Files
- `/var/log/*.log` - Individual log files (excluded to prevent noise)

## Hash Computation and Storage

### Hash Algorithm Implementation
**File**: `fim/agents/fim-agent.py`

```python
def compute_file_hash(self, file_path):
    """Compute SHA-256 hash of a file"""
    try:
        hash_sha256 = hashlib.sha256()
        with open(file_path, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                hash_sha256.update(chunk)
        return hash_sha256.hexdigest()
    except Exception as e:
        self.logger.error(f"Error computing hash for {file_path}: {e}")
        return None
```

### Baseline Storage
**File**: `/var/lib/fim/baseline.json`

```json
{
    "baseline_version": "1.0.0",
    "created_at": "2025-01-03T14:35:00Z",
    "files": {
        "/etc/passwd": {
            "hash": "a1b2c3d4e5f6...",
            "size": 1234,
            "permissions": "0644",
            "owner": "root",
            "group": "root",
            "modified": "2025-01-03T14:30:00Z"
        }
    }
}
```

### Hash Comparison Logic
**File**: `fim/agents/fim-agent.py`

```python
def check_file_integrity(self, file_path):
    """Check file integrity against baseline"""
    current_hash = self.compute_file_hash(file_path)
    if not current_hash:
        return False
    
    baseline_hash = self.baseline.get(file_path, {}).get('hash')
    if not baseline_hash:
        self.logger.warning(f"No baseline hash for {file_path}")
        return True
    
    if current_hash != baseline_hash:
        self.logger.warning(f"Hash mismatch for {file_path}")
        self.alert_file_change(file_path, baseline_hash, current_hash)
        return False
    
    return True
```

## Alert Generation and Routing

### Alert Types

#### File Change Alerts
**File**: `fim/agents/fim-agent.py`

```python
def alert_file_change(self, file_path, old_hash, new_hash):
    """Generate alert for file change"""
    alert = {
        "timestamp": datetime.now().isoformat(),
        "type": "FILE_CHANGE",
        "severity": "HIGH",
        "file_path": file_path,
        "old_hash": old_hash,
        "new_hash": new_hash,
        "hostname": socket.gethostname(),
        "message": f"File {file_path} has been modified"
    }
    
    self.logger.warning(json.dumps(alert))
    self.send_alert(alert)
```

#### New File Alerts
```python
def alert_new_file(self, file_path):
    """Generate alert for new file"""
    alert = {
        "timestamp": datetime.now().isoformat(),
        "type": "NEW_FILE",
        "severity": "MEDIUM",
        "file_path": file_path,
        "hostname": socket.gethostname(),
        "message": f"New file detected: {file_path}"
    }
    
    self.logger.info(json.dumps(alert))
    self.send_alert(alert)
```

#### Deleted File Alerts
```python
def alert_deleted_file(self, file_path):
    """Generate alert for deleted file"""
    alert = {
        "timestamp": datetime.now().isoformat(),
        "type": "DELETED_FILE",
        "severity": "HIGH",
        "file_path": file_path,
        "hostname": socket.gethostname(),
        "message": f"File deleted: {file_path}"
    }
    
    self.logger.warning(json.dumps(alert))
    self.send_alert(alert)
```

### Alert Routing

#### Log File Output
**File**: `/var/log/fim-agent.log`

```bash
# Example log entries
2025-01-03T14:35:00Z - FIMAgent - WARNING - {"timestamp": "2025-01-03T14:35:00Z", "type": "FILE_CHANGE", "severity": "HIGH", "file_path": "/etc/passwd", "old_hash": "a1b2c3...", "new_hash": "x9y8z7...", "hostname": "manage-node-1", "message": "File /etc/passwd has been modified"}
```

#### Prometheus Metrics
**File**: `fim/agents/fim-agent-prometheus.py`

```python
from prometheus_client import Counter, Gauge, start_http_server

# Prometheus metrics
fim_events_total = Counter('fim_events_total', 'Total FIM events', ['event_type', 'severity'])
fim_files_monitored = Gauge('fim_files_monitored', 'Number of files being monitored')
fim_last_scan_time = Gauge('fim_last_scan_time', 'Timestamp of last FIM scan')

def send_alert(self, alert):
    """Send alert to Prometheus metrics"""
    fim_events_total.labels(
        event_type=alert['type'],
        severity=alert['severity']
    ).inc()
```

#### HTTP Metrics Endpoint
```python
# Start HTTP server for Prometheus scraping
start_http_server(8080)  # FIM agent on manage-node-1
start_http_server(8082)  # FIM agent on manage-node-2
start_http_server(8084)  # FIM agent on manage-node-3
```

## Testing and Validation

### Test Plan for FIM Functionality

#### 1. Baseline Initialization Test
```bash
# Initialize FIM baseline
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "/opt/lab-env/bin/python /opt/lab-environment/fim-agent.py --init-baseline"

# Verify baseline creation
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "ls -la /var/lib/fim/baseline.json"

# Expected output:
# -rw-r--r-- 1 root root 12345 Jan  3 14:35 /var/lib/fim/baseline.json
```

#### 2. File Modification Detection Test
```bash
# Create test file
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "echo 'test content' > /etc/fim-test.txt"

# Wait for FIM scan
sleep 10

# Check for new file alert
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "tail -n 5 /var/log/fim-agent.log | grep 'NEW_FILE'"

# Expected output:
# {"timestamp": "2025-01-03T14:35:00Z", "type": "NEW_FILE", "severity": "MEDIUM", "file_path": "/etc/fim-test.txt", "hostname": "manage-node-1", "message": "New file detected: /etc/fim-test.txt"}
```

#### 3. File Change Detection Test
```bash
# Modify existing file
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "echo 'modified content' >> /etc/fim-test.txt"

# Wait for FIM scan
sleep 10

# Check for file change alert
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "tail -n 5 /var/log/fim-agent.log | grep 'FILE_CHANGE'"

# Expected output:
# {"timestamp": "2025-01-03T14:35:00Z", "type": "FILE_CHANGE", "severity": "HIGH", "file_path": "/etc/fim-test.txt", "old_hash": "a1b2c3...", "new_hash": "x9y8z7...", "hostname": "manage-node-1", "message": "File /etc/fim-test.txt has been modified"}
```

#### 4. File Deletion Detection Test
```bash
# Delete test file
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "rm /etc/fim-test.txt"

# Wait for FIM scan
sleep 10

# Check for deleted file alert
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "tail -n 5 /var/log/fim-agent.log | grep 'DELETED_FILE'"

# Expected output:
# {"timestamp": "2025-01-03T14:35:00Z", "type": "DELETED_FILE", "severity": "HIGH", "file_path": "/etc/fim-test.txt", "hostname": "manage-node-1", "message": "File deleted: /etc/fim-test.txt"}
```

### Prometheus Metrics Validation

#### 1. Check FIM Metrics Endpoint
```bash
# Test FIM metrics endpoint
curl -s http://localhost:8080/metrics | grep fim_

# Expected output:
# fim_events_total{event_type="FILE_CHANGE",severity="HIGH"} 1
# fim_events_total{event_type="NEW_FILE",severity="MEDIUM"} 1
# fim_events_total{event_type="DELETED_FILE",severity="HIGH"} 1
# fim_files_monitored 1234
# fim_last_scan_time 1.640123456e+09
```

#### 2. Verify Prometheus Scraping
```bash
# Check Prometheus targets
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.labels.job=="fim-agents")'

# Expected output:
# {
#   "labels": {
#     "job": "fim-agents",
#     "instance": "host.docker.internal:8080"
#   },
#   "health": "up",
#   "lastScrape": "2025-01-03T14:35:00Z"
# }
```

#### 3. Query FIM Metrics in Prometheus
```bash
# Query FIM events
curl -s 'http://localhost:9090/api/v1/query?query=fim_events_total' | jq '.data.result'

# Expected output:
# [
#   {
#     "metric": {
#       "__name__": "fim_events_total",
#       "event_type": "FILE_CHANGE",
#       "instance": "host.docker.internal:8080",
#       "job": "fim-agents",
#       "severity": "HIGH"
#     },
#     "value": [1640123456, "1"]
#   }
# ]
```

### Grafana Dashboard Validation

#### 1. Access FIM Dashboard
```bash
# Open Grafana dashboard
open http://localhost:3000/d/fim-cmdb-dashboard
```

#### 2. Verify FIM Panels
- **FIM Events by Type**: Pie chart showing event distribution
- **FIM Events Rate**: Time series of event frequency
- **Files Monitored**: Gauge showing total monitored files
- **Last Scan Time**: Timestamp of most recent scan

#### 3. Test Real-time Updates
```bash
# Generate test events
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "touch /etc/fim-test-$(date +%s).txt"

# Watch dashboard update in real-time
# Events should appear within 30 seconds
```

## Performance Considerations

### Scan Optimization

#### Exclude High-Frequency Paths
```json
{
    "excluded_paths": [
        "/tmp",
        "/var/tmp",
        "/var/cache",
        "/var/log/*.log",
        "/proc",
        "/sys",
        "/dev",
        "/var/run",
        "/var/lock"
    ]
}
```

#### Batch Processing
```python
def batch_scan_files(self, file_list):
    """Process files in batches to reduce memory usage"""
    batch_size = 100
    for i in range(0, len(file_list), batch_size):
        batch = file_list[i:i + batch_size]
        for file_path in batch:
            self.check_file_integrity(file_path)
        time.sleep(0.1)  # Small delay between batches
```

### Resource Usage Monitoring

#### CPU Usage
```bash
# Monitor FIM agent CPU usage
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "top -p $(pgrep fim-agent) -n 1"

# Expected: < 5% CPU usage during normal operation
```

#### Memory Usage
```bash
# Monitor FIM agent memory usage
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "ps aux | grep fim-agent"

# Expected: < 50MB memory usage
```

#### Disk Usage
```bash
# Check baseline file size
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "du -sh /var/lib/fim/"

# Expected: < 10MB for baseline storage
```

## Troubleshooting

### Common Issues

#### FIM Agent Not Starting
```bash
# Check service status
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "systemctl status fim-agent"

# Check logs
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "journalctl -u fim-agent -n 20"

# Restart service
ansible aws_instances -i ansible/inventory/aws-instances -m systemd -a "name=fim-agent state=restarted"
```

#### Missing Baseline
```bash
# Reinitialize baseline
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "/opt/lab-env/bin/python /opt/lab-environment/fim-agent.py --init-baseline"

# Verify baseline creation
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "ls -la /var/lib/fim/baseline.json"
```

#### High False Positive Rate
```bash
# Update baseline after legitimate changes
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "/opt/lab-env/bin/python /opt/lab-environment/fim-agent.py --update-baseline"

# Adjust excluded paths in configuration
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "vim /etc/fim/fim-config.json"
```

This FIM implementation provides comprehensive file integrity monitoring with automated alerting, Prometheus integration, and robust testing capabilities for enterprise security requirements.
