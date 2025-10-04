# Ansible Baseline, FIM, and CMDB Lab - Production Monitoring Stack

This lab provides a **production-grade monitoring environment** with live metrics collection from AWS EC2 instances:
- **Ansible Baseline**: Automated system configuration and compliance across mixed OS environments
- **File Integrity Monitoring (FIM)**: Real-time file change detection and alerting
- **Configuration Management Database (CMDB)**: Asset and configuration tracking
- **Prometheus + Grafana**: Live metrics collection and visualization
- **SSH Tunneling**: Secure monitoring without opening AWS security groups

## 🎯 Lab Overview

This lab is designed for **AWS EC2 deployment** with **live monitoring** and supports mixed operating systems:
- **Amazon Linux 2023** (manage-node-1) - 18.234.152.228
- **Ubuntu 24.04** (manage-node-2) - 54.242.234.69
- **Ubuntu 24.04** (manage-node-3) - 13.217.82.23

## 📁 Lab Structure

```
├── ansible/                 # Ansible configuration and playbooks
│   ├── playbooks/          # AWS deployment playbooks
│   │   ├── setup-aws-instances.yml  # Main AWS deployment
│   │   └── templates/      # AWS-specific templates
│   ├── roles/              # Reusable Ansible roles
│   ├── inventory/          # AWS instances inventory
│   │   └── aws-instances   # Your 3 EC2 instances
│   └── group_vars/         # Group-specific variables
├── fim/                    # File Integrity Monitoring
│   ├── agents/             # FIM agent configurations
│   └── rules/              # Monitoring rules and policies
├── cmdb/                   # Configuration Management Database
│   ├── schemas/            # Data schemas and templates
│   └── scripts/            # Data collection scripts
├── grafana/                # Grafana configuration
│   ├── dashboards/         # Dashboard definitions
│   └── provisioning/       # Auto-provisioning configs
├── data/                   # Data files and test results
│   ├── test-results/       # FIM baseline and test data
│   ├── reports/            # Generated reports
│   ├── test-files/         # Test files for monitoring
│   └── aws-cmdb-data/      # CMDB collected data from AWS
├── tests/                  # Test scenarios and validation
│   ├── scripts/            # Test scripts with documentation
│   └── TESTING-GUIDE.md    # Comprehensive testing guide
├── setup/                  # Setup scripts and documentation
│   ├── scripts/            # Setup and deployment scripts
│   ├── guides/             # Comprehensive guides and documentation
│   └── docs/               # Additional documentation
├── docker-compose.yml      # Prometheus + Grafana stack
├── prometheus.yml          # Prometheus configuration
├── simple-monitoring-dashboard.html  # Lab status dashboard
├── setup-ssh-tunnel-monitoring.sh    # SSH tunnel setup
├── manage-tunnels.sh       # Tunnel management
└── test-prometheus-grafana-fix.sh    # Monitoring tests
```

## 🚀 Quick Start - Production Monitoring Stack

1. **Setup SSH Connectivity**:
   ```bash
   ./setup/scripts/setup-aws-ssh.sh
   ```

2. **Deploy to AWS Instances**:
   ```bash
   cd ansible
   ansible-playbook -i inventory/aws-instances playbooks/setup-aws-instances.yml
   ```

3. **Setup Live Monitoring**:
   ```bash
   # Start Prometheus + Grafana
   docker compose -f docker-compose.yml up -d
   
   # Setup SSH tunnels for monitoring
   ./setup-ssh-tunnel-monitoring.sh
   ```

4. **Access Your Monitoring**:
   - **Grafana**: http://localhost:3000 (admin/admin)
   - **Prometheus**: http://localhost:9090
   - **Lab Dashboard**: http://localhost:8080/simple-monitoring-dashboard.html

5. **Verify Everything is Working**:
   ```bash
   # Test monitoring stack
   ./test-prometheus-grafana-fix.sh
   
   # Check tunnel status
   ./manage-tunnels.sh status
   ```

## 🎓 Learning Objectives

- Deploy Ansible automation across mixed OS environments (Amazon Linux + Ubuntu)
- Implement file integrity monitoring for security compliance
- Build and maintain a configuration management database
- Set up production-grade monitoring with Prometheus + Grafana
- Use SSH tunneling for secure cloud monitoring
- Handle OS-specific differences in package management and services
- Troubleshoot deployment issues in cloud environments

## 📊 Live Monitoring Features

- **Real-time Metrics**: CPU, memory, disk usage from all AWS instances
- **SSH Tunneling**: Secure monitoring without opening AWS security groups
- **Prometheus Queries**: Live system metrics and service status
- **Grafana Dashboards**: Visual monitoring with live data
- **Automated Testing**: Comprehensive monitoring stack validation

## 📚 Documentation

- **[setup/README.md](setup/README.md)** - **Setup scripts and documentation overview**
- **[setup/guides/HOW-TO-USE-THIS-LAB.md](setup/guides/HOW-TO-USE-THIS-LAB.md)** - Complete user guide with step-by-step instructions
- **[setup/guides/AWS-DEPLOYMENT-GUIDE.md](setup/guides/AWS-DEPLOYMENT-GUIDE.md)** - Complete deployment instructions
- **[setup/guides/TROUBLESHOOTING-GUIDE.md](setup/guides/TROUBLESHOOTING-GUIDE.md)** - Common errors and solutions
- **[setup/guides/NEXT-STEPS.md](setup/guides/NEXT-STEPS.md)** - Advanced usage and extensions
- **[tests/TESTING-GUIDE.md](tests/TESTING-GUIDE.md)** - Comprehensive testing guide
- **[PROMETHEUS-GRAFANA-FIX-SUMMARY.md](PROMETHEUS-GRAFANA-FIX-SUMMARY.md)** - Complete monitoring setup guide

## 🎯 Production Ready

This lab provides a **production-grade monitoring environment** suitable for:
- Enterprise configuration management
- Security compliance monitoring
- Infrastructure automation learning
- Real-world DevOps practices
