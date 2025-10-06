# 📊 Prometheus Alerting Rules Documentation

## 📅 **Created**: October 6, 2025  
**Author**: Gabriel Eweka  
**Lab**: Ansible Baseline, FIM, and CMDB Lab  
**File**: `prometheus-alerts.yml`

---

## 🎯 **Overview**

This document provides comprehensive documentation for the Prometheus alerting rules configured in your monitoring lab. The alerting system automatically detects and responds to:

- **File Integrity Monitoring (FIM)** violations
- **Configuration Management Database (CMDB)** issues
- **System resource** problems
- **Infrastructure** failures

---

## 🏗️ **Alert Architecture**

### **Alert Flow**
```
AWS Instances → FIM/CMDB Agents → Prometheus → Alert Rules → Alertmanager → Notifications
```

### **Evaluation Cycle**
- **Scrape Interval**: 15 seconds (metrics collection)
- **Evaluation Interval**: 15 seconds (rule evaluation)
- **Alert Processing**: Real-time with configurable delays

---

## 🚨 **Alert Groups**

## **Group 1: FIM Alerts (File Integrity Monitoring)**

### **1.1 FIMFileChange Alert**
```yaml
- alert: FIMFileChange
  expr: increase(fim_events_total[5m]) > 0
  for: 0m
  labels:
    severity: warning
    service: fim
  annotations:
    summary: "File integrity monitoring detected changes"
    description: "FIM agent detected {{ $value }} file changes in the last 5 minutes on {{ $labels.instance }}"
```

#### **Purpose**
Detects any unauthorized file modifications, additions, or deletions on monitored systems.

#### **Trigger Conditions**
- **Expression**: `increase(fim_events_total[5m]) > 0`
- **Time Window**: 5 minutes
- **Threshold**: Any file changes (> 0)
- **Delay**: Immediate (0 minutes)

#### **When It Fires**
- Files are created in monitored directories (`/etc/`, `/bin/`, `/usr/`, etc.)
- Existing files are modified
- Files are deleted
- File permissions are changed
- File ownership is modified

#### **Example Scenarios**
```bash
# These actions will trigger the alert:
sudo touch /etc/new-config-file.conf
echo "modified" >> /etc/hosts
sudo rm /etc/old-file.txt
sudo chmod 777 /etc/passwd
```

#### **Alert Details**
- **Severity**: Warning
- **Service**: FIM
- **Instance**: Specific node where change occurred
- **Value**: Number of file changes detected

---

### **1.2 FIMHighActivity Alert**
```yaml
- alert: FIMHighActivity
  expr: increase(fim_events_total[10m]) > 50
  for: 2m
  labels:
    severity: critical
    service: fim
  annotations:
    summary: "High FIM activity detected"
    description: "FIM agent detected {{ $value }} file changes in the last 10 minutes on {{ $labels.instance }} - possible security incident"
```

#### **Purpose**
Detects potential security incidents or mass file operations that could indicate system compromise.

#### **Trigger Conditions**
- **Expression**: `increase(fim_events_total[10m]) > 50`
- **Time Window**: 10 minutes
- **Threshold**: More than 50 file changes
- **Delay**: 2 minutes (to confirm sustained activity)

#### **When It Fires**
- Malware infection spreading files
- Bulk file operations (backup, migration, etc.)
- Automated attacks modifying multiple files
- System updates or package installations
- Configuration management tools making changes

#### **Example Scenarios**
```bash
# These actions will trigger the alert:
for i in {1..60}; do
    echo "test" > /etc/file-$i.txt
done

# Or malware creating multiple files:
# Malware creates 100+ files in /tmp/
```

#### **Alert Details**
- **Severity**: Critical
- **Service**: FIM
- **Instance**: Specific node with high activity
- **Value**: Number of file changes in 10-minute window

---

### **1.3 FIMAgentDown Alert**
```yaml
- alert: FIMAgentDown
  expr: up{job="fim-agents"} == 0
  for: 1m
  labels:
    severity: critical
    service: fim
  annotations:
    summary: "FIM agent is down"
    description: "FIM agent on {{ $labels.instance }} has been down for more than 1 minute"
```

#### **Purpose**
Ensures FIM monitoring is always active and detects when monitoring capabilities are lost.

#### **Trigger Conditions**
- **Expression**: `up{job="fim-agents"} == 0`
- **Time Window**: Continuous monitoring
- **Threshold**: Agent not responding
- **Delay**: 1 minute (to avoid false alarms from brief restarts)

#### **When It Fires**
- FIM agent service crashes
- FIM agent process stops
- Network connectivity issues
- SSH tunnel problems
- System resource exhaustion
- Agent configuration errors

#### **Troubleshooting Steps**
```bash
# Check FIM agent status
sudo systemctl status fim-agent-prometheus

# Restart FIM agent
sudo systemctl restart fim-agent-prometheus

# Check logs
sudo journalctl -u fim-agent-prometheus --no-pager -n 50
```

#### **Alert Details**
- **Severity**: Critical
- **Service**: FIM
- **Instance**: Specific node with down agent
- **Impact**: Loss of file integrity monitoring

---

## **Group 2: CMDB Alerts (Configuration Management Database)**

### **2.1 CMDBCollectionFailure Alert**
```yaml
- alert: CMDBCollectionFailure
  expr: increase(cmdb_collections_total[15m]) == 0
  for: 5m
  labels:
    severity: warning
    service: cmdb
  annotations:
    summary: "CMDB collection failure"
    description: "CMDB collector on {{ $labels.instance }} has not collected data in the last 15 minutes"
```

#### **Purpose**
Ensures configuration data is being collected regularly and detects when collection processes fail.

#### **Trigger Conditions**
- **Expression**: `increase(cmdb_collections_total[15m]) == 0`
- **Time Window**: 15 minutes
- **Threshold**: No collections performed
- **Delay**: 5 minutes (to confirm sustained failure)

#### **When It Fires**
- CMDB collector stops running
- Collection scripts fail
- Network connectivity issues
- Database connection problems
- Resource constraints preventing collection
- Configuration errors in collection process

#### **What Gets Collected**
- Installed packages and versions
- System services and their status
- Network configuration
- User accounts and groups
- System hardware information
- Software inventory

#### **Troubleshooting Steps**
```bash
# Check CMDB collector status
sudo systemctl status cmdb-collector-prometheus

# Restart CMDB collector
sudo systemctl restart cmdb-collector-prometheus

# Check collection logs
sudo journalctl -u cmdb-collector-prometheus --no-pager -n 50
```

#### **Alert Details**
- **Severity**: Warning
- **Service**: CMDB
- **Instance**: Specific node with collection failure
- **Impact**: Loss of configuration tracking

---

### **2.2 CMDBCollectorDown Alert**
```yaml
- alert: CMDBCollectorDown
  expr: up{job="cmdb-collectors"} == 0
  for: 1m
  labels:
    severity: critical
    service: cmdb
  annotations:
    summary: "CMDB collector is down"
    description: "CMDB collector on {{ $labels.instance }} has been down for more than 1 minute"
```

#### **Purpose**
Ensures CMDB monitoring is always active and detects when the collector service stops responding.

#### **Trigger Conditions**
- **Expression**: `up{job="cmdb-collectors"} == 0`
- **Time Window**: Continuous monitoring
- **Threshold**: Collector not responding
- **Delay**: 1 minute (to avoid false alarms)

#### **When It Fires**
- CMDB collector service crashes
- Collector process stops
- Network connectivity issues
- SSH tunnel problems
- System resource exhaustion
- Collector configuration errors

#### **Alert Details**
- **Severity**: Critical
- **Service**: CMDB
- **Instance**: Specific node with down collector
- **Impact**: Complete loss of configuration monitoring

---

## **Group 3: System Alerts (Infrastructure Monitoring)**

### **3.1 NodeExporterDown Alert**
```yaml
- alert: NodeExporterDown
  expr: up{job="aws-nodes"} == 0
  for: 1m
  labels:
    severity: critical
    service: node-exporter
  annotations:
    summary: "Node Exporter is down"
    description: "Node Exporter on {{ $labels.instance }} has been down for more than 1 minute"
```

#### **Purpose**
Ensures system metrics collection is always active and detects when Node Exporter stops responding.

#### **Trigger Conditions**
- **Expression**: `up{job="aws-nodes"} == 0`
- **Time Window**: Continuous monitoring
- **Threshold**: Node Exporter not responding
- **Delay**: 1 minute (to avoid false alarms)

#### **When It Fires**
- Node Exporter service crashes
- AWS instance becomes unresponsive
- Network connectivity issues
- SSH tunnel problems
- System resource exhaustion

#### **Metrics Affected**
- CPU usage and load
- Memory utilization
- Disk space and I/O
- Network statistics
- System processes
- File system information

#### **Alert Details**
- **Severity**: Critical
- **Service**: node-exporter
- **Instance**: Specific AWS node
- **Impact**: Loss of system metrics

---

### **3.2 HighCPUUsage Alert**
```yaml
- alert: HighCPUUsage
  expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
  for: 5m
  labels:
    severity: warning
    service: system
  annotations:
    summary: "High CPU usage detected"
    description: "CPU usage is above 80% for more than 5 minutes on {{ $labels.instance }}"
```

#### **Purpose**
Detects performance issues and resource exhaustion that could impact system stability.

#### **Trigger Conditions**
- **Expression**: `100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80`
- **Time Window**: 5 minutes average
- **Threshold**: CPU usage > 80%
- **Delay**: 5 minutes (to confirm sustained high usage)

#### **Calculation Explanation**
```
CPU Usage = 100% - (Idle CPU Percentage)
Idle CPU = irate(node_cpu_seconds_total{mode="idle"}[5m]) * 100
```

#### **When It Fires**
- High system load
- Runaway processes
- Insufficient CPU resources
- Malware consuming CPU
- Application performance issues
- System updates or maintenance

#### **Troubleshooting Steps**
```bash
# Check CPU usage
top
htop

# Check running processes
ps aux --sort=-%cpu | head -10

# Check system load
uptime
```

#### **Alert Details**
- **Severity**: Warning
- **Service**: system
- **Instance**: Specific node with high CPU
- **Threshold**: 80% CPU usage

---

### **3.3 HighMemoryUsage Alert**
```yaml
- alert: HighMemoryUsage
  expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
  for: 5m
  labels:
    severity: warning
    service: system
  annotations:
    summary: "High memory usage detected"
    description: "Memory usage is above 85% for more than 5 minutes on {{ $labels.instance }}"
```

#### **Purpose**
Detects memory leaks and resource exhaustion that could lead to system instability.

#### **Trigger Conditions**
- **Expression**: `(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85`
- **Time Window**: 5 minutes average
- **Threshold**: Memory usage > 85%
- **Delay**: 5 minutes (to confirm sustained high usage)

#### **Calculation Explanation**
```
Memory Usage = (Total Memory - Available Memory) / Total Memory * 100
```

#### **When It Fires**
- Memory leaks in applications
- Too many running processes
- Insufficient RAM for workload
- Malware consuming memory
- Application memory issues
- System cache buildup

#### **Troubleshooting Steps**
```bash
# Check memory usage
free -h
cat /proc/meminfo

# Check memory usage by process
ps aux --sort=-%mem | head -10

# Check for memory leaks
dmesg | grep -i "out of memory"
```

#### **Alert Details**
- **Severity**: Warning
- **Service**: system
- **Instance**: Specific node with high memory
- **Threshold**: 85% memory usage

---

### **3.4 DiskSpaceLow Alert**
```yaml
- alert: DiskSpaceLow
  expr: (1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100 > 90
  for: 5m
  labels:
    severity: critical
    service: system
  annotations:
    summary: "Disk space low"
    description: "Disk usage is above 90% for more than 5 minutes on {{ $labels.instance }}"
```

#### **Purpose**
Prevents disk space exhaustion that could cause system failures and data loss.

#### **Trigger Conditions**
- **Expression**: `(1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100 > 90`
- **Time Window**: 5 minutes average
- **Threshold**: Disk usage > 90%
- **Delay**: 5 minutes (to confirm sustained high usage)

#### **Calculation Explanation**
```
Disk Usage = (Total Space - Available Space) / Total Space * 100
```

#### **When It Fires**
- Log files growing too large
- Application data accumulation
- Insufficient disk space
- Backup files not cleaned up
- Temporary files not removed
- Database growth

#### **Troubleshooting Steps**
```bash
# Check disk usage
df -h
du -sh /*

# Find large files
find / -type f -size +100M 2>/dev/null

# Clean up logs
sudo journalctl --vacuum-time=7d
sudo find /var/log -name "*.log" -mtime +30 -delete
```

#### **Alert Details**
- **Severity**: Critical
- **Service**: system
- **Instance**: Specific node with low disk space
- **Threshold**: 90% disk usage

---

## **Group 4: Prometheus Alerts (Monitoring System Health)**

### **4.1 PrometheusDown Alert**
```yaml
- alert: PrometheusDown
  expr: up{job="prometheus"} == 0
  for: 1m
  labels:
    severity: critical
    service: prometheus
  annotations:
    summary: "Prometheus is down"
    description: "Prometheus monitoring system is down"
```

#### **Purpose**
Self-monitoring of the monitoring system to detect when Prometheus itself becomes unavailable.

#### **Trigger Conditions**
- **Expression**: `up{job="prometheus"} == 0`
- **Time Window**: Continuous monitoring
- **Threshold**: Prometheus not responding
- **Delay**: 1 minute (to avoid false alarms)

#### **When It Fires**
- Prometheus service crashes
- Prometheus process stops
- Docker container issues
- System resource exhaustion
- Configuration errors
- Network connectivity problems

#### **Impact**
- Complete loss of monitoring capabilities
- No alert generation
- No metrics collection
- No dashboards or visualizations

#### **Alert Details**
- **Severity**: Critical
- **Service**: prometheus
- **Impact**: Complete monitoring system failure

---

### **4.2 PrometheusConfigReloadFailed Alert**
```yaml
- alert: PrometheusConfigReloadFailed
  expr: prometheus_config_last_reload_successful == 0
  for: 0m
  labels:
    severity: warning
    service: prometheus
  annotations:
    summary: "Prometheus configuration reload failed"
    description: "Prometheus configuration reload failed"
```

#### **Purpose**
Ensures configuration changes are applied correctly and detects when reload operations fail.

#### **Trigger Conditions**
- **Expression**: `prometheus_config_last_reload_successful == 0`
- **Time Window**: Immediate
- **Threshold**: Reload unsuccessful
- **Delay**: Immediate (0 minutes)

#### **When It Fires**
- Syntax errors in `prometheus.yml`
- Invalid alert rules in `prometheus-alerts.yml`
- Invalid target configurations
- File permission issues
- Configuration file corruption
- Network configuration errors

#### **Common Causes**
```yaml
# Invalid YAML syntax
scrape_configs:
  - job_name: 'test'
    static_configs:
      - targets: ['localhost:9090']
    # Missing closing bracket

# Invalid alert rule
- alert: TestAlert
  expr: invalid_metric_name > 0  # Metric doesn't exist
```

#### **Troubleshooting Steps**
```bash
# Check Prometheus configuration
curl -s "http://localhost:9090/api/v1/status/config" | jq '.data.yaml'

# Test configuration syntax
promtool check config prometheus.yml
promtool check rules prometheus-alerts.yml

# Reload configuration
curl -X POST http://localhost:9090/-/reload
```

#### **Alert Details**
- **Severity**: Warning
- **Service**: prometheus
- **Impact**: Configuration changes not applied

---

## 🔧 **Alert Management**

### **Alert States**
- **Inactive**: Condition not met
- **Pending**: Condition met, waiting for delay period
- **Firing**: Alert is active and being sent

### **Alert Lifecycle**
```
Inactive → Pending → Firing → Resolved → Inactive
```

### **Alert Resolution**
Alerts automatically resolve when:
- The triggering condition is no longer met
- The underlying issue is fixed
- The service is restored

---

## 📊 **Monitoring and Testing**

### **Check Alert Status**
```bash
# View all alerts
curl -s "http://localhost:9090/api/v1/alerts" | jq '.data.alerts[] | {name: .labels.alertname, state: .state, severity: .labels.severity}'

# View alert rules
curl -s "http://localhost:9090/api/v1/rules" | jq '.data.groups[].rules[] | {name: .name, state: .state}'

# View Alertmanager alerts
curl -s "http://localhost:9093/api/v1/alerts" | jq '.data.alerts[] | {alertname: .labels.alertname, status: .status.state}'
```

### **Test Alert Rules**
```bash
# Test FIM alert by creating a file
ssh -i /Users/osamudiameneweka/Desktop/key-p3.pem ec2-user@18.234.152.228 "echo 'test' | sudo tee /etc/test-alert.txt"

# Test high CPU by running stress test
ssh -i /Users/osamudiameneweka/Desktop/key-p3.pem ec2-user@18.234.152.228 "stress --cpu 4 --timeout 300s"

# Test service down by stopping FIM agent
ssh -i /Users/osamudiameneweka/Desktop/key-p3.pem ec2-user@18.234.152.228 "sudo systemctl stop fim-agent-prometheus"
```

---

## 🎯 **Best Practices**

### **Alert Tuning**
- **Thresholds**: Adjust based on your environment
- **Delays**: Balance between responsiveness and false positives
- **Severity**: Match business impact to alert severity

### **Alert Fatigue Prevention**
- Use appropriate delays to avoid false alarms
- Group related alerts to reduce noise
- Set up alert suppression for maintenance windows

### **Response Procedures**
- Document response procedures for each alert type
- Set up escalation policies
- Create runbooks for common issues

---

## 📍 **Access Points**

### **Monitoring Interfaces**
- **Prometheus Alerts**: http://localhost:9090/alerts
- **Prometheus Rules**: http://localhost:9090/rules
- **Alertmanager**: http://localhost:9093
- **Grafana**: http://localhost:3000

### **Configuration Files**
- **Alert Rules**: `prometheus-alerts.yml`
- **Alertmanager Config**: `alertmanager.yml`
- **Prometheus Config**: `prometheus.yml`

---

**Last Updated**: October 6, 2025  
**Status**: ✅ All alert rules documented and validated  
**Next Action**: Use this documentation for alert management and troubleshooting
