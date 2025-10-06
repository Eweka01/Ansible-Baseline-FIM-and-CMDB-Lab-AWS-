# FIM and CMDB Prometheus Metrics Guide 🚀

This guide explains how to use the new Prometheus-instrumented FIM and CMDB agents to get real-time metrics in your Grafana dashboards.

## 🎯 Overview

Your lab now includes **Prometheus-instrumented agents** that expose metrics for:
- **File Integrity Monitoring (FIM)** events and statistics
- **Configuration Management Database (CMDB)** collection metrics
- **System information** and asset tracking

## 📊 Available Metrics

### FIM Agent Metrics

| Metric Name | Type | Description |
|-------------|------|-------------|
| `fim_events_total` | Counter | Total number of FIM events detected (by event type and path) |
| `fim_files_monitored` | Gauge | Number of files currently being monitored |
| `fim_directories_monitored` | Gauge | Number of directories currently being monitored |
| `fim_scan_duration_seconds` | Histogram | Time spent scanning files |
| `fim_last_scan_timestamp` | Gauge | Timestamp of last FIM scan |
| `fim_agent_uptime_seconds` | Gauge | FIM agent uptime in seconds |

### CMDB Collector Metrics

| Metric Name | Type | Description |
|-------------|------|-------------|
| `cmdb_collections_total` | Counter | Total number of CMDB data collections |
| `cmdb_collection_duration_seconds` | Histogram | Time spent collecting CMDB data |
| `cmdb_last_collection_timestamp` | Gauge | Timestamp of last CMDB collection |
| `cmdb_agent_uptime_seconds` | Gauge | CMDB agent uptime in seconds |
| `system_cpu_cores` | Gauge | Number of CPU cores |
| `system_memory_total_bytes` | Gauge | Total system memory in bytes |
| `system_disk_total_bytes` | Gauge | Total disk space in bytes |
| `system_uptime_seconds` | Gauge | System uptime in seconds |
| `system_processes_total` | Gauge | Total number of processes |
| `system_users_total` | Gauge | Total number of users |
| `system_packages_total` | Gauge | Total number of installed packages |

## 🚀 Quick Start

### 1. Deploy Prometheus-Instrumented Agents

```bash
# Deploy the new agents to AWS instances
cd ansible
ansible-playbook -i inventory/aws-instances playbooks/deploy-prometheus-agents.yml
```

### 2. Setup SSH Tunnels for Metrics

```bash
# Create SSH tunnels for FIM and CMDB metrics
./setup-fim-cmdb-tunnels.sh
```

### 3. Test the Metrics

```bash
# Test all FIM and CMDB metrics
./test-fim-cmdb-metrics.sh
```

## 🔍 Prometheus Queries

### FIM Queries

```promql
# Total FIM events by type
fim_events_total

# FIM events by event type
fim_events_total{event_type="new"}
fim_events_total{event_type="modified"}
fim_events_total{event_type="deleted"}

# Files being monitored
fim_files_monitored

# FIM agent uptime
fim_agent_uptime_seconds

# Last scan time
fim_last_scan_timestamp
```

### CMDB Queries

```promql
# Total CMDB collections
cmdb_collections_total

# System packages count
system_packages_total

# System resources
system_cpu_cores
system_memory_total_bytes
system_disk_total_bytes

# System uptime
system_uptime_seconds

# CMDB agent uptime
cmdb_agent_uptime_seconds
```

### Combined Queries

```promql
# FIM events rate (events per minute)
rate(fim_events_total[5m]) * 60

# CMDB collection rate
rate(cmdb_collections_total[1h])

# System resource utilization
(1 - (system_memory_available_bytes / system_memory_total_bytes)) * 100
```

## 📈 Grafana Dashboard Panels

### FIM Dashboard Panels

1. **FIM Events Over Time**
   - Query: `fim_events_total`
   - Visualization: Time series
   - Group by: `event_type`

2. **Files Monitored**
   - Query: `fim_files_monitored`
   - Visualization: Stat panel

3. **FIM Agent Status**
   - Query: `fim_agent_uptime_seconds`
   - Visualization: Stat panel

4. **Scan Duration**
   - Query: `fim_scan_duration_seconds`
   - Visualization: Histogram

### CMDB Dashboard Panels

1. **System Packages**
   - Query: `system_packages_total`
   - Visualization: Stat panel

2. **System Resources**
   - Query: `system_cpu_cores`, `system_memory_total_bytes`, `system_disk_total_bytes`
   - Visualization: Stat panels

3. **CMDB Collection Status**
   - Query: `cmdb_collections_total`
   - Visualization: Time series

4. **System Uptime**
   - Query: `system_uptime_seconds`
   - Visualization: Stat panel

## 🧪 Testing Scenarios

### 1. Generate FIM Events

```bash
# Create test files to trigger FIM events
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "echo 'Test file' > /tmp/fim-test-$(date +%s).txt"

# Modify existing files
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "echo 'Modified' >> /etc/hostname"

# Check metrics in Prometheus
curl -s "http://localhost:9090/api/v1/query?query=fim_events_total"
```

### 2. Trigger CMDB Collection

```bash
# Install new software to change package count
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "yum install -y htop || apt-get install -y htop"

# Check metrics in Prometheus
curl -s "http://localhost:9090/api/v1/query?query=system_packages_total"
```

### 3. Monitor Real-Time Changes

```bash
# Watch FIM events in real-time
watch -n 5 'curl -s "http://localhost:9090/api/v1/query?query=fim_events_total" | python3 -c "import sys, json; data=json.load(sys.stdin); print(f\"FIM Events: {sum(int(r[\"value\"][1]) for r in data[\"data\"][\"result\"])}\")"'

# Watch system packages
watch -n 10 'curl -s "http://localhost:9090/api/v1/query?query=system_packages_total" | python3 -c "import sys, json; data=json.load(sys.stdin); print(f\"Packages: {sum(int(r[\"value\"][1]) for r in data[\"data\"][\"result\"])}\")"'
```

## 🔧 Troubleshooting

### Check Agent Status

```bash
# Check if agents are running
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "systemctl status fim-agent-prometheus cmdb-collector-prometheus"

# Check metrics endpoints
curl -s http://localhost:8080/metrics | grep fim_events_total
curl -s http://localhost:8081/metrics | grep cmdb_collections_total
```

### Check Prometheus Targets

```bash
# Check if Prometheus is scraping the new targets
curl -s "http://localhost:9090/api/v1/targets" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for target in data['data']['activeTargets']:
    if 'fim-agents' in target['discoveredLabels'].get('job', '') or 'cmdb-collectors' in target['discoveredLabels'].get('job', ''):
        print(f\"{target['discoveredLabels']['__address__']} - {target['health']}\")
"
```

### Check SSH Tunnels

```bash
# Check tunnel status
ps aux | grep "ssh.*-L.*808"

# Test tunnel connectivity
curl -s http://localhost:8080/metrics | head -5
curl -s http://localhost:8081/metrics | head -5
```

## 📊 Metrics Endpoints

| Service | Port | Endpoint | Description |
|---------|------|----------|-------------|
| FIM Agent (node-1) | 8080 | `/metrics` | FIM metrics from manage-node-1 |
| CMDB Collector (node-1) | 8081 | `/metrics` | CMDB metrics from manage-node-1 |
| FIM Agent (node-2) | 8082 | `/metrics` | FIM metrics from manage-node-2 |
| CMDB Collector (node-2) | 8083 | `/metrics` | CMDB metrics from manage-node-2 |
| FIM Agent (node-3) | 8084 | `/metrics` | FIM metrics from manage-node-3 |
| CMDB Collector (node-3) | 8085 | `/metrics` | CMDB metrics from manage-node-3 |

## 🎯 Next Steps

1. **Create Custom Dashboards**: Build Grafana dashboards specific to your monitoring needs
2. **Set Up Alerting**: Configure Prometheus alerting rules for FIM and CMDB events
3. **Add More Metrics**: Extend the agents to collect additional system information
4. **Integrate with SIEM**: Connect FIM events to security information systems
5. **Automate Responses**: Set up automated responses to critical FIM events

## 🚀 Production Ready

Your lab now has **production-grade monitoring** with:
- ✅ **Real-time FIM metrics** for security monitoring
- ✅ **CMDB metrics** for asset and configuration tracking
- ✅ **Prometheus integration** for metrics collection
- ✅ **Grafana dashboards** for visualization
- ✅ **SSH tunneling** for secure cloud monitoring
- ✅ **Comprehensive testing** and validation

**Your Configuration Management Engineer lab is now fully equipped with enterprise-level monitoring capabilities!** 🎉
