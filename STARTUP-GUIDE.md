# 🚀 Lab Startup Guide - FIM & CMDB Monitoring

## 📋 **Quick Start Checklist**

When starting your Ansible Baseline, FIM, and CMDB lab, follow these steps to get live monitoring data flowing to Prometheus and Grafana.

## 🚀 **QUICK START (Automated)**

### **Option 0: Complete Automated Startup (Recommended)**
```bash
cd "/Users/osamudiameneweka/Desktop/Ansible Baseline, FIM, and CMDB Lab"
./start-monitoring-lab.sh
```

This single command will:
- Start all Docker services (Prometheus + Grafana)
- Establish all SSH tunnels to AWS instances
- Start HTTP server for dashboard on port 8088
- Verify all services are working
- Display access URLs and testing commands

### **To Stop Everything:**
```bash
./stop-monitoring-lab.sh
```

### **Dashboard Startup (If Needed):**
```bash
./start_dashboard.sh
```

---

## 🆘 **Emergency Recovery (One-Command Restart)**
If anything stops working (Docker, tunnels, dashboard), run this command to fully recover the lab:

```bash
cd "/Users/osamudiameneweka/Desktop/Ansible Baseline, FIM, and CMDB Lab"
./restart-monitoring-lab.sh
```

What this does:
- Restarts Docker services (Prometheus + Grafana)
- Re-establishes all 9 SSH tunnels (binds to 0.0.0.0 for Docker access)
- Ensures the dashboard HTTP server is running on port 8088
- Verifies endpoints and prints HTTP codes (200/302/401/405 are OK)
- Prints access URLs and active tunnel count

---

## 🔧 **Step 1: Start SSH Tunnels (Manual)**

### **Option A: Complete Tunnel Setup (Recommended)**
```bash
cd "/Users/osamudiameneweka/Desktop/Ansible Baseline, FIM, and CMDB Lab"
./setup-ssh-tunnel-monitoring.sh
```

### **Option B: Using Tunnel Manager**
```bash
cd "/Users/osamudiameneweka/Desktop/Ansible Baseline, FIM, and CMDB Lab"
./manage-tunnels.sh start
```

### **Option C: Manual Tunnel Commands**
```bash
# Node Exporter Tunnels (System Metrics)
ssh -f -N -L 9101:localhost:9100 -i /Users/osamudiameneweka/Desktop/key-p3.pem ec2-user@18.234.152.228
ssh -f -N -L 9102:localhost:9100 -i /Users/osamudiameneweka/Desktop/key-p3.pem ubuntu@54.242.234.69
ssh -f -N -L 9103:localhost:9100 -i /Users/osamudiameneweka/Desktop/key-p3.pem ubuntu@13.217.82.23

# FIM Agent Tunnels (File Integrity Monitoring)
ssh -f -N -L 8080:localhost:8080 -i /Users/osamudiameneweka/Desktop/key-p3.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ec2-user@18.234.152.228
ssh -f -N -L 8082:localhost:8080 -i /Users/osamudiameneweka/Desktop/key-p3.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@54.242.234.69
ssh -f -N -L 8084:localhost:8080 -i /Users/osamudiameneweka/Desktop/key-p3.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@13.217.82.23

# CMDB Collector Tunnels (Asset Management)
ssh -f -N -L 8081:localhost:8081 -i /Users/osamudiameneweka/Desktop/key-p3.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ec2-user@18.234.152.228
ssh -f -N -L 8083:localhost:8081 -i /Users/osamudiameneweka/Desktop/key-p3.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@54.242.234.69
ssh -f -N -L 8085:localhost:8081 -i /Users/osamudiameneweka/Desktop/key-p3.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@13.217.82.23
```

## 🐳 **Step 2: Start Docker Services**

```bash
cd "/Users/osamudiameneweka/Desktop/Ansible Baseline, FIM, and CMDB Lab"
docker-compose up -d
```

## ⚙️ **Step 3: Verify Prometheus Configuration**

Ensure your `prometheus.yml` contains all three job configurations:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'aws-nodes'
    scrape_interval: 15s
    static_configs:
      - targets:
          - 'host.docker.internal:9101'  # manage-node-1 via SSH tunnel
          - 'host.docker.internal:9102'  # manage-node-2 via SSH tunnel
          - 'host.docker.internal:9103'  # manage-node-3 via SSH tunnel
    metrics_path: /metrics

  - job_name: 'fim-agents'
    scrape_interval: 15s
    static_configs:
      - targets:
          - 'host.docker.internal:8080'  # manage-node-1 FIM agent
          - 'host.docker.internal:8082'  # manage-node-2 FIM agent
          - 'host.docker.internal:8084'  # manage-node-3 FIM agent
    metrics_path: /metrics

  - job_name: 'cmdb-collectors'
    scrape_interval: 15s
    static_configs:
      - targets:
          - 'host.docker.internal:8081'  # manage-node-1 CMDB collector
          - 'host.docker.internal:8083'  # manage-node-2 CMDB collector
          - 'host.docker.internal:8085'  # manage-node-3 CMDB collector
    metrics_path: /metrics
```

## 🔄 **Step 4: Restart Prometheus (If Needed)**

```bash
docker-compose restart prometheus
```

## ✅ **Step 5: Verification Commands**

### **Check SSH Tunnels**
```bash
ps aux | grep "ssh.*-L" | grep -v grep
# Should show 9 active tunnels
```

### **Test Local Metrics Endpoints**
```bash
# Test FIM metrics
curl -s http://localhost:8080/metrics | grep fim_events_total

# Test CMDB metrics
curl -s http://localhost:8081/metrics | grep cmdb_collections_total

# Test Node Exporter metrics
curl -s http://localhost:9101/metrics | grep node_cpu_seconds_total
```

### **Check Prometheus Targets**
```bash
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .job, instance: .instance, health: .health}'
```

### **Test Prometheus Queries**
```bash
# FIM metrics
curl -s "http://localhost:9090/api/v1/query?query=fim_events_total" | jq '.data.result | length'

# CMDB metrics
curl -s "http://localhost:9090/api/v1/query?query=cmdb_collections_total" | jq '.data.result | length'

# Node Exporter metrics
curl -s "http://localhost:9090/api/v1/query?query=node_cpu_seconds_total" | jq '.data.result | length'
```

## 🌐 **Step 6: Access Your Monitoring Stack**

### **Real-time Dashboard**
- **URL**: http://localhost:8088/simple-monitoring-dashboard.html
- **Features**: Live service status, alerts, monitoring log
- **Auto-refresh**: Every 30 seconds

### **Prometheus**
- **URL**: http://localhost:9090
- **Targets**: http://localhost:9090/targets
- **Graph**: http://localhost:9090/graph

### **Grafana**
- **URL**: http://localhost:3000
- **Username**: admin
- **Password**: admin
- **Dashboards**:
  - AWS Lab Monitoring Dashboard
  - FIM & CMDB Monitoring Dashboard

### **Lab Dashboard** (Legacy)
- **URL**: http://localhost:8088/simple-monitoring-dashboard.html
- **Note**: This is the same as the Real-time Dashboard above

## 🔧 **Tunnel Management Commands**

### **Start Tunnels**
```bash
./manage-tunnels.sh start
```

### **Stop Tunnels**
```bash
./manage-tunnels.sh stop
```

### **Check Status**
```bash
./manage-tunnels.sh status
```

### **Restart Tunnels**
```bash
./manage-tunnels.sh restart
```

## 📊 **Expected Results**

After successful startup, you should see:

- **9 SSH tunnels** active
- **9 Prometheus targets** showing as "UP"
- **FIM metrics** queryable (should return 300+ results)
- **CMDB metrics** queryable (should return 3+ results)
- **Node Exporter metrics** queryable (should return 100+ results)
- **Grafana dashboards** showing live data

## 🚨 **Common Issues & Quick Fixes**

### **Issue: "Address already in use"**
```bash
# Kill existing tunnels
pkill -f "ssh.*-L"
# Restart tunnels
./manage-tunnels.sh restart
```

### **Issue: Prometheus targets show "DOWN"**
```bash
# Check if tunnels are active
ps aux | grep "ssh.*-L" | grep -v grep
# Restart tunnels if needed
./manage-tunnels.sh restart
```

### **Issue: No FIM/CMDB data in Grafana**
```bash
# Verify prometheus.yml has all job configurations
cat prometheus.yml
# Restart Prometheus
docker-compose restart prometheus
```

### **Issue: Docker services not running**
```bash
# Start Docker services
docker-compose up -d
# Check status
docker ps
```

## 📝 **Port Mapping Reference**

| Service | Local Port | AWS Instance | Remote Port | Purpose |
|---------|------------|--------------|-------------|---------|
| Node Exporter | 9101 | manage-node-1 | 9100 | System metrics |
| Node Exporter | 9102 | manage-node-2 | 9100 | System metrics |
| Node Exporter | 9103 | manage-node-3 | 9100 | System metrics |
| FIM Agent | 8080 | manage-node-1 | 8080 | File integrity |
| FIM Agent | 8082 | manage-node-2 | 8080 | File integrity |
| FIM Agent | 8084 | manage-node-3 | 8080 | File integrity |
| CMDB Collector | 8081 | manage-node-1 | 8081 | Asset management |
| CMDB Collector | 8083 | manage-node-2 | 8081 | Asset management |
| CMDB Collector | 8085 | manage-node-3 | 8081 | Asset management |

## 🎯 **Success Indicators**

✅ **All systems operational when you see:**
- 9 SSH tunnels running
- 9 Prometheus targets UP
- FIM metrics returning 300+ results
- CMDB metrics returning 3+ results
- Grafana dashboards showing live data
- Lab dashboard showing all green status indicators

## 📞 **Need Help?**

If you encounter issues not covered in this guide, refer to:
- `TROUBLESHOOTING-GUIDE.md` - Detailed troubleshooting steps
- `My Sys/OPERATIONS_RUNBOOK.md` - Day-2 operations guide
- `My Sys/TESTING_AND_VALIDATION.md` - Testing procedures
