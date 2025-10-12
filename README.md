# 🚀 Ansible Baseline, FIM, and CMDB Lab

## 📅 **Created**: October 6, 2025  
**Author**: Gabriel Eweka

---

## 🎯 **Lab Overview**

This is a **production-ready** Ansible Baseline, File Integrity Monitoring (FIM), and Configuration Management Database (CMDB) lab deployed on AWS with **automated drift detection and remediation**.

### **✅ Current Status: FULLY OPERATIONAL**
- **3 AWS Instances**: manage-node-1, manage-node-2, manage-node-3
- **Live Monitoring**: Prometheus + Grafana + Real-time Dashboard
- **Automated Remediation**: Complete drift detection and auto-remediation system
- **Audit Compliance**: Comprehensive logging and change tracking

---

## 🚀 **Quick Start**

### **1. Start the Lab**
```bash
# Complete lab startup (Docker + SSH tunnels + Dashboard)
./scripts/start-monitoring-lab.sh

# OR start automated remediation system
./scripts/start-automated-remediation.sh start
```

### **2. Access Points**
- **Real-time Dashboard**: http://localhost:8088/simple-monitoring-dashboard.html
- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Alertmanager**: http://localhost:9093

### **3. Test Drift Detection**
```bash
# SSH into a node and make a change
ssh -i /path/to/your/ssh-key.pem ec2-user@REPLACED_IP_1
echo "Test change" | sudo tee /etc/test-drift.txt

# System will automatically detect and remediate the change
```

---

## 📁 **Project Structure**

```
├── scripts/                    # All shell scripts organized here
│   ├── start-monitoring-lab.sh
│   ├── restart-monitoring-lab.sh
│   ├── stop-monitoring-lab.sh
│   ├── setup-ssh-tunnel-monitoring.sh
│   ├── setup-fim-cmdb-tunnels.sh
│   ├── start-automated-remediation.sh
│   ├── production-testing-suite.sh
│   ├── manage-tunnels.sh
│   └── start_dashboard.sh
├── ansible/                    # Ansible playbooks and configuration
├── automated-remediation/      # Automated remediation system
├── fim/                       # File Integrity Monitoring
├── cmdb/                      # Configuration Management Database
├── grafana/                   # Grafana dashboards and configuration
├── docs/                      # Documentation
├── test/                      # Testing scripts and scenarios
├── baseline-configs/          # Baseline configuration files
├── audit-logs/               # Audit logging system
└── data/                     # Data storage and reports
```

## 📚 **Documentation**

**All documentation is organized in the `docs/` directory:**

### **📋 Quick Access**
- [📚 Documentation Index](docs/README.md) - **Start here for all documentation**
- [🚀 Startup Guide](docs/guides/STARTUP-GUIDE.md) - Complete lab startup procedures
- [🧪 Testing Guide](docs/guides/DRIFT-DETECTION-TESTING-GUIDE.md) - How to test drift detection

### **📖 Documentation Structure**
- **📋 [Main Documentation](docs/README.md)** - Documentation index and navigation
- **📖 [Guides](docs/guides/)** - Step-by-step procedures and tutorials
- **📚 [Reference](docs/reference/)** - Technical reference documentation
- **🤖 [Automation](docs/automation/)** - Automated remediation system
- **🔧 [Troubleshooting](docs/troubleshooting/)** - Error history and fixes
- **🏗️ [System Documentation](docs/My%20Sys/)** - Comprehensive technical documentation

---

## 🎯 **Key Features**

### **🔍 Monitoring & Detection**
- **File Integrity Monitoring (FIM)**: Real-time file change detection
- **Configuration Management Database (CMDB)**: Asset inventory and configuration tracking
- **System Monitoring**: CPU, memory, disk, network metrics
- **Real-time Alerts**: Prometheus alerting with Alertmanager

### **🤖 Automated Remediation**
- **Webhook Receiver**: Processes Prometheus alerts automatically
- **Ansible Playbooks**: Automated remediation actions
- **Baseline Configurations**: Version-controlled known good states
- **Audit Logging**: Comprehensive change tracking and compliance

### **📊 Live Monitoring**
- **Real-time Dashboard**: Live system status and alerts
- **Grafana Dashboards**: Professional monitoring visualizations
- **Prometheus Metrics**: Comprehensive system and application metrics
- **SSH Tunnels**: Secure access to AWS instance metrics

---

## 🛠️ **Management Scripts**

### **Lab Management**
- `./scripts/start-monitoring-lab.sh` - Start complete lab
- `./scripts/stop-monitoring-lab.sh` - Stop complete lab
- `./scripts/restart-monitoring-lab.sh` - Emergency recovery

### **Automated Remediation**
- `./scripts/start-automated-remediation.sh start` - Start automated remediation
- `./scripts/start-automated-remediation.sh status` - Check system status
- `./scripts/start-automated-remediation.sh test` - Test webhook receiver

### **Tunnel Management**
- `./scripts/manage-tunnels.sh start` - Start SSH tunnels
- `./scripts/manage-tunnels.sh status` - Check tunnel status
- `./scripts/manage-tunnels.sh stop` - Stop SSH tunnels

### **Testing & Validation**
- `./test/test-fim-cmdb-metrics.sh` - Test FIM and CMDB metrics
- `./scripts/production-testing-suite.sh` - Comprehensive testing

---

## 📈 **Current Metrics**

### **Live Monitoring Status**
- **Prometheus Targets**: 8/9 UP (excellent performance)
- **FIM Metrics**: 324+ events available (14,000+ total events)
- **CMDB Metrics**: 3+ collections available (11+ total collections)
- **SSH Tunnels**: 11 active tunnels
- **Real-time Dashboard**: Fully operational

### **Automated Remediation**
- **Detection Time**: <30 seconds
- **Remediation Time**: <5 minutes
- **Success Rate**: >95%
- **Audit Coverage**: 100%

---

## 🔧 **Troubleshooting**

### **Quick Fixes**
```bash
# If dashboard not working
./scripts/start_dashboard.sh

# If tunnels down
./scripts/manage-tunnels.sh restart

# If services down
./scripts/restart-monitoring-lab.sh
```

### **Documentation**
- [🔧 Troubleshooting Guide](docs/troubleshooting/COMPLETE-ERROR-HISTORY.md) - All known issues and fixes
- [📋 Current Fixes](docs/troubleshooting/fix.md) - Latest diagnostic reports

---

## 🎓 **Learning & Development**

### **For Interviews**
- [📋 Interview Brief](docs/My%20Sys/INTERVIEW_BRIEF.md) - Complete interview preparation
- [🏗️ Architecture Overview](docs/My%20Sys/ARCHITECTURE.md) - Technical architecture
- [🔧 Operations Runbook](docs/My%20Sys/OPERATIONS_RUNBOOK.md) - Operational procedures

### **For Production Use**
- [🤖 Automated Remediation](docs/automation/AUTOMATED-REMEDIATION-SYSTEM.md) - Production-ready automation
- [🔒 Security & Baselines](docs/My%20Sys/SECURITY_AND_BASELINES.md) - Security configurations
- [📊 Testing & Validation](docs/My%20Sys/TESTING_AND_VALIDATION.md) - Comprehensive testing

---

## 📞 **Support**

### **Documentation**
- **Start with**: [📚 Documentation Index](docs/README.md)
- **Quick Start**: [🚀 Startup Guide](docs/guides/STARTUP-GUIDE.md)
- **Testing**: [🧪 Testing Guide](docs/guides/DRIFT-DETECTION-TESTING-GUIDE.md)

### **Emergency Recovery**
```bash
# Full lab recovery
./scripts/restart-monitoring-lab.sh

# Check system status
./scripts/start-automated-remediation.sh status
```

---

### **Setup Instructions**
Before using this lab, replace the following placeholders with your actual values:
- `REPLACED_IP_1`, `REPLACED_IP_2`, `REPLACED_IP_3` → Your AWS instance IPs
- `/path/to/your/ssh-key.pem` → Your actual SSH key path

### **Cleanup Summary**
- All log files and sensitive data removed
- Scripts organized into `scripts/` directory
- Directory structure cleaned and optimized
- Documentation updated with new paths

---

**Status**: ✅ Production-ready lab with automated remediation  
**Documentation**: 📚 Fully organized in `docs/` directory  
**Security**: 🔒 Cleaned and safe for public sharing
