# Real-World Testing Guide - Production Monitoring Lab 🧪

This guide provides comprehensive real-world testing scenarios for your production-grade monitoring lab with Ansible Baseline, FIM, CMDB, and live monitoring via Prometheus + Grafana.

## 🎯 Lab Overview

Your lab simulates a **production enterprise environment** with:
- **3 AWS EC2 instances** (Amazon Linux + Ubuntu)
- **Live monitoring** via Prometheus + Grafana
- **File Integrity Monitoring (FIM)** for security compliance
- **Configuration Management Database (CMDB)** for asset tracking
- **SSH tunneling** for secure cloud monitoring

## 📊 Monitoring Stack Components

| Component | Purpose | Access URL |
|-----------|---------|------------|
| **Grafana** | Visual monitoring dashboards | http://localhost:3000 |
| **Prometheus** | Metrics collection and querying | http://localhost:9090 |
| **Lab Dashboard** | Lab status overview | http://localhost:8080/simple-monitoring-dashboard.html |
| **SSH Tunnels** | Secure AWS monitoring | Ports 9101, 9102, 9103 |

## 🧪 Real-World Testing Scenarios

### Scenario 1: Infrastructure Monitoring & Alerting

**Objective**: Test real-time infrastructure monitoring and alerting capabilities.

#### 1.1 CPU Load Testing
```bash
# Generate CPU load on AWS instances
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "stress --cpu 2 --timeout 60s"

# Monitor in Grafana:
# 1. Go to http://localhost:3000
# 2. Login: admin/admin
# 3. Watch CPU usage spike in real-time
# 4. Observe memory usage changes
```

#### 1.2 Disk Space Testing
```bash
# Fill disk space on one instance
ansible manage-node-1 -i ansible/inventory/aws-instances -m shell -a "dd if=/dev/zero of=/tmp/largefile bs=1M count=100"

# Monitor disk usage in Prometheus:
# 1. Go to http://localhost:9090
# 2. Query: node_filesystem_avail_bytes
# 3. Observe disk space decrease
```

#### 1.3 Network Traffic Testing
```bash
# Generate network traffic
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "ping -c 100 google.com"

# Monitor network metrics in Grafana
# Query: rate(node_network_receive_bytes_total[5m])
```

### Scenario 2: Security Monitoring & File Integrity

**Objective**: Test FIM capabilities and security monitoring.

#### 2.1 File Change Detection
```bash
# Create test files on AWS instances
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "echo 'Test file created at $(date)' > /tmp/security-test.txt"

# Modify existing files
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "echo 'File modified at $(date)' >> /etc/hostname"

# Check FIM logs
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "tail -20 /var/log/fim-agent.log"
```

#### 2.2 Configuration Drift Detection
```bash
# Change system configurations
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "echo 'drift-test' >> /etc/motd"

# Monitor for configuration changes
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "grep -i drift /var/log/fim-agent.log"
```

#### 2.3 Unauthorized Access Simulation
```bash
# Simulate unauthorized file access
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "touch /etc/unauthorized-file.txt"

# Check security logs
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "grep -i unauthorized /var/log/fim-agent.log"
```

### Scenario 3: Configuration Management & CMDB

**Objective**: Test CMDB data collection and configuration management.

#### 3.1 Asset Discovery Testing
```bash
# Trigger CMDB data collection
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "systemctl start cmdb-collector"

# Check collected data
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "ls -la /var/lib/cmdb/data/"

# View system information
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "cat /var/lib/cmdb/data/system_info.json | head -20"
```

#### 3.2 Software Inventory Testing
```bash
# Install new software
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "yum install -y htop || apt-get install -y htop"

# Trigger CMDB collection
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "systemctl start cmdb-collector"

# Check software inventory
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "cat /var/lib/cmdb/data/software_info.json | grep htop"
```

#### 3.3 Hardware Change Detection
```bash
# Simulate hardware changes (virtual)
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "echo 'Hardware change simulation' > /tmp/hardware-change.log"

# Check hardware inventory
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "cat /var/lib/cmdb/data/hardware_info.json | head -10"
```

### Scenario 4: High Availability & Failover Testing

**Objective**: Test monitoring during service failures and recovery.

#### 4.1 Service Failure Simulation
```bash
# Stop FIM agent on one instance
ansible manage-node-1 -i ansible/inventory/aws-instances -m shell -a "systemctl stop fim-agent"

# Monitor service status in Prometheus
# Query: up{job="aws-nodes"}
# Should show one instance as down

# Restart service
ansible manage-node-1 -i ansible/inventory/aws-instances -m shell -a "systemctl start fim-agent"
```

#### 4.2 SSH Tunnel Failure Testing
```bash
# Kill SSH tunnel
./manage-tunnels.sh stop

# Check Prometheus targets (should show down)
curl -s http://localhost:9090/api/v1/targets

# Restart tunnels
./manage-tunnels.sh start

# Verify targets are back up
curl -s http://localhost:9090/api/v1/targets
```

#### 4.3 Container Failure Testing
```bash
# Stop Grafana container
docker compose -f docker-compose.yml stop grafana

# Check lab dashboard (should show error)
# Go to http://localhost:8080/simple-monitoring-dashboard.html

# Restart container
docker compose -f docker-compose.yml start grafana
```

### Scenario 5: Performance & Scalability Testing

**Objective**: Test monitoring performance under load.

#### 5.1 Metrics Collection Load Testing
```bash
# Generate high-frequency metrics
for i in {1..100}; do
  ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "echo 'Load test $i' > /tmp/load-test-$i.txt"
  sleep 1
done

# Monitor Prometheus metrics collection
# Query: prometheus_tsdb_symbol_table_size_bytes
```

#### 5.2 Dashboard Performance Testing
```bash
# Open multiple dashboard tabs
# 1. Grafana: http://localhost:3000
# 2. Prometheus: http://localhost:9090
# 3. Lab Dashboard: http://localhost:8080/simple-monitoring-dashboard.html

# Monitor response times and resource usage
```

### Scenario 6: Compliance & Audit Testing

**Objective**: Test compliance monitoring and audit capabilities.

#### 6.1 Security Compliance Testing
```bash
# Check security hardening
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "grep -i 'password' /etc/ssh/sshd_config"

# Verify firewall rules
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "ufw status || iptables -L"
```

#### 6.2 Audit Trail Testing
```bash
# Generate audit events
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "sudo su -c 'echo audit test'"

# Check audit logs
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "grep -i audit /var/log/fim-agent.log"
```

## 📈 Monitoring Queries for Testing

### Prometheus Queries
```promql
# System Health
up{job="aws-nodes"}

# CPU Usage
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory Usage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Disk Usage
(1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100

# Network Traffic
rate(node_network_receive_bytes_total[5m])

# Service Status
systemctl_status_active
```

### Grafana Dashboard Panels
- **CPU Usage by Instance**
- **Memory Usage Trends**
- **Disk Space Monitoring**
- **Network Traffic**
- **Service Health Status**
- **FIM Agent Status**
- **CMDB Collection Status**

## 🔧 Troubleshooting Commands

### Check Monitoring Stack
```bash
# Test all components
./test-prometheus-grafana-fix.sh

# Check tunnel status
./manage-tunnels.sh status

# Restart tunnels if needed
./manage-tunnels.sh restart
```

### Check AWS Services
```bash
# Check FIM agents
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "systemctl status fim-agent"

# Check CMDB collectors
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "systemctl status cmdb-collector.timer"

# Check Node Exporter
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "systemctl status node_exporter"
```

### Check Logs
```bash
# FIM logs
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "tail -50 /var/log/fim-agent.log"

# CMDB logs
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "tail -50 /var/log/cmdb-collector.log"

# System logs
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "journalctl -u fim-agent --no-pager -n 20"
```

## 🎯 Expected Results

### Successful Test Outcomes
- ✅ **Real-time metrics** visible in Grafana
- ✅ **File changes** detected by FIM agents
- ✅ **CMDB data** collected and stored
- ✅ **Service failures** detected and alerted
- ✅ **Performance metrics** accurate and timely
- ✅ **Compliance** monitoring working

### Performance Benchmarks
- **Metrics collection**: < 5 seconds delay
- **Dashboard refresh**: < 2 seconds
- **Alert response**: < 30 seconds
- **Data retention**: 7 days minimum
- **Uptime**: 99.9% target

## 🚀 Production Readiness Checklist

- ✅ **Monitoring stack** fully operational
- ✅ **SSH tunnels** secure and stable
- ✅ **FIM agents** detecting changes
- ✅ **CMDB collectors** gathering data
- ✅ **Grafana dashboards** showing live data
- ✅ **Prometheus queries** returning results
- ✅ **Alerting** configured and tested
- ✅ **Documentation** complete and up-to-date

## 📚 Next Steps

1. **Custom Dashboards**: Create specific dashboards for your use cases
2. **Alerting Rules**: Set up Prometheus alerting rules
3. **Data Retention**: Configure long-term storage
4. **Integration**: Connect to external systems
5. **Automation**: Add automated responses to alerts

---

**Your lab is now ready for production-grade monitoring and testing!** 🎉
