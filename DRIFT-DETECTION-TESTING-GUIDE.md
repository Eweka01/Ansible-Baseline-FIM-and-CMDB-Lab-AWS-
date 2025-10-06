# 🧪 Drift Detection & Alerting Testing Guide

## 📅 **Created**: October 6, 2025  
**Author**: Gabriel Eweka  
**Lab**: Ansible Baseline, FIM, and CMDB Lab

---

## 🎯 **Overview**

This guide provides comprehensive testing procedures for drift detection and alerting in your monitoring lab. The lab includes:

- **File Integrity Monitoring (FIM)** - Detects file changes
- **Configuration Management Database (CMDB)** - Tracks system configuration changes
- **Prometheus Alerting** - Automated alert generation
- **Alertmanager** - Alert routing and notification

---

## 🚀 **Prerequisites**

### **Lab Status Check**
```bash
# Verify all services are running
cd "/Users/osamudiameneweka/Desktop/Ansible Baseline, FIM, and CMDB Lab"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Expected output:
# ansiblebaselinefimandcmdblab-prometheus-1     Up
# ansiblebaselinefimandcmdblab-grafana-1        Up  
# ansiblebaselinefimandcmdblab-alertmanager-1   Up
```

### **SSH Tunnels Status**
```bash
# Check tunnel status
./manage-tunnels.sh status

# Expected: 9 active tunnels
# - Node Exporters: 9101, 9102, 9103
# - FIM Agents: 8080, 8082, 8084
# - CMDB Collectors: 8081, 8083, 8085
```

---

## 🧪 **Test 1: FIM File Change Detection**

### **Objective**
Test File Integrity Monitoring by creating, modifying, and deleting files to trigger drift detection alerts.

### **Steps**

#### **1.1 Check Current FIM Metrics**
```bash
# View current FIM event counts
curl -s "http://localhost:9090/api/v1/query?query=fim_events_total" | jq '.data.result[] | {instance: .metric.instance, value: .value[1]}'

# Expected: Multiple metrics with various event counts
```

#### **1.2 SSH into AWS Node**
```bash
# Connect to manage-node-1 (Amazon Linux)
ssh -i /Users/osamudiameneweka/Desktop/key-p3.pem ec2-user@18.234.152.228

# OR connect to manage-node-2 (Ubuntu)
ssh -i /Users/osamudiameneweka/Desktop/key-p3.pem ubuntu@54.242.234.69
```

#### **1.3 Create Test File**
```bash
# Create a new file in monitored directory
echo "Test drift detection - $(date)" | sudo tee /etc/test-drift-file.txt

# Expected: FIM should detect this as a new file
```

#### **1.4 Modify Existing File**
```bash
# Modify a system file
echo "# Test modification - $(date)" | sudo tee -a /etc/hosts

# Expected: FIM should detect this as a file modification
```

#### **1.5 Delete Test File**
```bash
# Remove the test file
sudo rm -f /etc/test-drift-file.txt

# Expected: FIM should detect this as a file deletion
```

#### **1.6 Check FIM Metrics After Changes**
```bash
# From your local machine, check updated metrics
curl -s "http://localhost:9090/api/v1/query?query=fim_events_total" | jq '.data.result[] | {instance: .metric.instance, value: .value[1]}'

# Expected: Event counts should have increased
```

#### **1.7 Verify Alerts**
```bash
# Check active alerts in Prometheus
curl -s "http://localhost:9090/api/v1/alerts" | jq '.data.alerts[] | {name: .labels.alertname, state: .state, severity: .labels.severity}'

# Expected: FIMFileChange alerts should be FIRING
```

---

## 🧪 **Test 2: CMDB Configuration Drift Detection**

### **Objective**
Test Configuration Management Database by installing/removing packages to trigger configuration drift alerts.

### **Steps**

#### **2.1 Check Current CMDB Metrics**
```bash
# View current CMDB collection counts
curl -s "http://localhost:9090/api/v1/query?query=cmdb_collections_total" | jq '.data.result[] | {instance: .metric.instance, value: .value[1]}'
```

#### **2.2 SSH into AWS Node**
```bash
# Connect to any node
ssh -i /Users/osamudiameneweka/Desktop/key-p3.pem ec2-user@18.234.152.228
```

#### **2.3 Install Test Package**
```bash
# Install a test package (Amazon Linux)
sudo yum install -y nano

# OR (Ubuntu)
sudo apt install -y nano

# Expected: CMDB should detect package installation
```

#### **2.4 Remove Test Package**
```bash
# Remove the package (Amazon Linux)
sudo yum remove -y nano

# OR (Ubuntu)
sudo apt remove -y nano

# Expected: CMDB should detect package removal
```

#### **2.5 Check CMDB Metrics**
```bash
# From local machine, check updated metrics
curl -s "http://localhost:9090/api/v1/query?query=cmdb_collections_total" | jq '.data.result[] | {instance: .metric.instance, value: .value[1]}'

# Expected: Collection counts should have increased
```

---

## 🧪 **Test 3: Alerting System Verification**

### **Objective**
Verify that Prometheus alerting rules are working and Alertmanager is receiving alerts.

### **Steps**

#### **3.1 Check Alert Rules Status**
```bash
# View all alert rules
curl -s "http://localhost:9090/api/v1/rules" | jq '.data.groups[].rules[] | {name: .name, state: .state}'

# Expected output:
# {
#   "name": "FIMFileChange",
#   "state": "firing"
# }
# {
#   "name": "FIMHighActivity", 
#   "state": "pending"
# }
```

#### **3.2 Check Active Alerts**
```bash
# View currently firing alerts
curl -s "http://localhost:9090/api/v1/alerts" | jq '.data.alerts[] | {name: .labels.alertname, state: .state, severity: .labels.severity}'

# Expected: Multiple FIMFileChange alerts with "firing" state
```

#### **3.3 Check Alertmanager Status**
```bash
# Verify Alertmanager is receiving alerts
curl -s "http://localhost:9093/api/v1/alerts" | jq '.data.alerts[] | {alertname: .labels.alertname, status: .status.state}'

# Expected: Alerts should appear in Alertmanager
```

#### **3.4 Access Alertmanager Web UI**
```bash
# Open Alertmanager in browser
open http://localhost:9093

# Expected: Web interface showing active alerts
```

---

## 🧪 **Test 4: High Activity Alert Trigger**

### **Objective**
Trigger the FIMHighActivity alert by creating multiple files quickly.

### **Steps**

#### **4.1 Create Multiple Files Rapidly**
```bash
# SSH into a node
ssh -i /Users/osamudiameneweka/Desktop/key-p3.pem ec2-user@18.234.152.228

# Create multiple files quickly
for i in {1..60}; do
    echo "Test file $i - $(date)" | sudo tee /etc/test-bulk-$i.txt
    sleep 1
done

# Expected: Should trigger FIMHighActivity alert (>50 changes in 10 minutes)
```

#### **4.2 Check High Activity Alert**
```bash
# From local machine, check for high activity alert
curl -s "http://localhost:9090/api/v1/alerts" | jq '.data.alerts[] | select(.labels.alertname=="FIMHighActivity") | {name: .labels.alertname, state: .state, severity: .labels.severity}'

# Expected: FIMHighActivity should be "firing" with "critical" severity
```

---

## 🧪 **Test 5: Service Down Detection**

### **Objective**
Test alerting when FIM or CMDB agents go down.

### **Steps**

#### **5.1 Stop FIM Agent**
```bash
# SSH into a node
ssh -i /Users/osamudiameneweka/Desktop/key-p3.pem ec2-user@18.234.152.228

# Stop FIM agent
sudo systemctl stop fim-agent-prometheus

# Expected: FIMAgentDown alert should fire
```

#### **5.2 Check Service Down Alert**
```bash
# From local machine, check for service down alert
curl -s "http://localhost:9090/api/v1/alerts" | jq '.data.alerts[] | select(.labels.alertname=="FIMAgentDown") | {name: .labels.alertname, state: .state, severity: .labels.severity}'

# Expected: FIMAgentDown should be "firing" with "critical" severity
```

#### **5.3 Restart FIM Agent**
```bash
# SSH back into the node
ssh -i /Users/osamudiameneweka/Desktop/key-p3.pem ec2-user@18.234.152.228

# Restart FIM agent
sudo systemctl start fim-agent-prometheus

# Expected: Alert should resolve
```

---

## 📊 **Expected Test Results**

### **FIM Metrics**
- **manage-node-1**: 22,495+ total events
- **manage-node-2**: 45,882+ total events
- **manage-node-3**: 45,510+ total events

### **Alert States**
- **FIMFileChange**: FIRING (when files change)
- **FIMHighActivity**: PENDING → FIRING (when >50 changes in 10min)
- **FIMAgentDown**: FIRING (when agent stops)
- **CMDBCollectionFailure**: PENDING (when collections fail)

### **Response Times**
- **File Changes**: Detected within 15-30 seconds
- **Alert Generation**: Within 1-2 minutes
- **Alert Resolution**: Within 2-5 minutes after fix

---

## 🔧 **Troubleshooting**

### **No Alerts Appearing**
```bash
# Check if FIM agents are running
ansible all -i ansible/inventory/aws-instances -m shell -a "systemctl status fim-agent-prometheus --no-pager"

# Check Prometheus targets
curl -s "http://localhost:9090/api/v1/targets" | jq '.data.activeTargets[] | {job: .labels.job, instance: .labels.instance, health: .health}'

# Restart FIM agent if needed
ssh -i /Users/osamudiameneweka/Desktop/key-p3.pem ec2-user@18.234.152.228 "sudo systemctl restart fim-agent-prometheus"
```

### **SSH Tunnel Issues**
```bash
# Restart all tunnels
./manage-tunnels.sh restart

# Check tunnel status
./manage-tunnels.sh status
```

### **Prometheus Configuration Issues**
```bash
# Reload Prometheus configuration
curl -X POST http://localhost:9090/-/reload

# Check configuration
curl -s "http://localhost:9090/api/v1/status/config" | jq '.data.yaml'
```

---

## 📍 **Access Points**

### **Monitoring Interfaces**
- **Prometheus**: http://localhost:9090
  - Alerts tab: http://localhost:9090/alerts
  - Targets tab: http://localhost:9090/targets
- **Alertmanager**: http://localhost:9093
- **Grafana**: http://localhost:3000 (admin/admin)

### **Real-time Dashboard**
- **Lab Dashboard**: http://localhost:8088/simple-monitoring-dashboard.html

---

## 🎯 **Success Criteria**

### **✅ Test Passes If:**
1. FIM detects file changes within 30 seconds
2. Alerts appear in Prometheus within 2 minutes
3. Alertmanager receives and displays alerts
4. High activity alerts trigger with >50 changes
5. Service down alerts fire when agents stop
6. Alerts resolve when issues are fixed

### **📈 Performance Metrics**
- **Detection Time**: <30 seconds
- **Alert Generation**: <2 minutes
- **False Positive Rate**: <5%
- **Alert Resolution**: <5 minutes

---

## 🚀 **Advanced Testing**

### **Bulk File Operations**
```bash
# Create 100 files to test high activity
for i in {1..100}; do
    echo "Bulk test $i" | sudo tee /etc/bulk-test-$i.txt
done
```

### **Configuration Changes**
```bash
# Modify system configuration
sudo sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config
sudo systemctl restart sshd
```

### **Network Configuration**
```bash
# Change network settings (will be detected by CMDB)
sudo ip addr add 192.168.1.100/24 dev eth0
```

---

**Last Updated**: October 6, 2025  
**Status**: ✅ All tests validated and working  
**Next Action**: Use this guide for ongoing drift detection validation
