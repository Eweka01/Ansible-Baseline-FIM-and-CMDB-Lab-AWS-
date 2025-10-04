# Ansible Baseline, FIM, and CMDB Lab

A production-grade configuration management and monitoring lab that implements automated system hardening, file integrity monitoring (FIM), and configuration management database (CMDB) capabilities across mixed AWS EC2 environments.

## Problem Solved

This lab addresses the critical need for automated configuration management, security compliance monitoring, and asset tracking in enterprise environments. It provides a complete solution for:

- **Configuration Drift Detection**: Automated baseline enforcement across mixed OS environments
- **Security Compliance**: Real-time file integrity monitoring with alerting
- **Asset Management**: Comprehensive system inventory and configuration tracking
- **Production Monitoring**: Live metrics collection with Prometheus and Grafana
- **Infrastructure as Code**: Fully automated deployment and management

## High-Level Features

- ✅ **Automated Baseline Configuration**: Cross-platform system hardening (Amazon Linux + Ubuntu)
- ✅ **File Integrity Monitoring (FIM)**: Real-time file change detection with SHA-256 hashing
- ✅ **Configuration Management Database (CMDB)**: Asset discovery and configuration tracking
- ✅ **Security Hardening**: SSH hardening, firewall configuration, fail2ban, auditd
- ✅ **Production Monitoring**: Prometheus metrics collection with Grafana visualization
- ✅ **SSH Tunneling**: Secure cloud monitoring without opening security groups
- ✅ **Mixed OS Support**: Amazon Linux 2023 and Ubuntu 24.04 compatibility
- ✅ **Automated Testing**: Comprehensive validation and testing framework

## Quick Start

### Prerequisites
```bash
# Install Ansible and dependencies
pip3 install ansible>=2.9.0
pip3 install -r requirements.txt

# Ensure AWS EC2 instances are running:
# - manage-node-1 (Amazon Linux): 18.234.152.228
# - manage-node-2 (Ubuntu): 54.242.234.69  
# - manage-node-3 (Ubuntu): 13.217.82.23
```

### 1. Setup SSH Connectivity
```bash
./setup/scripts/setup-aws-ssh.sh
```

### 2. Deploy to AWS Instances
```bash
cd ansible
ansible-playbook -i inventory/aws-instances playbooks/setup-aws-instances.yml
```

### 3. Start Monitoring Stack
```bash
# Start Prometheus + Grafana
docker compose -f docker-compose.yml up -d

# Setup SSH tunnels for monitoring
./setup-ssh-tunnel-monitoring.sh
```

### 4. Access Monitoring
- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Lab Dashboard**: http://localhost:8080/simple-monitoring-dashboard.html

### 5. Verify Deployment
```bash
# Test monitoring stack
./test-prometheus-grafana-fix.sh

# Check tunnel status
./manage-tunnels.sh status
```

## Documentation

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System architecture and data flows
- **[SETUP_AND_DEPLOY.md](SETUP_AND_DEPLOY.md)** - Detailed installation and deployment guide
- **[OPERATIONS_RUNBOOK.md](OPERATIONS_RUNBOOK.md)** - Day-2 operations and troubleshooting
- **[SECURITY_AND_BASELINES.md](SECURITY_AND_BASELINES.md)** - Security controls and compliance
- **[FIM_IMPLEMENTATION.md](FIM_IMPLEMENTATION.md)** - File integrity monitoring details
- **[CMDB_AND_ASSET_INVENTORY.md](CMDB_AND_ASSET_INVENTORY.md)** - Asset management and inventory
- **[ANSIBLE_PLAYBOOKS_REFERENCE.md](ANSIBLE_PLAYBOOKS_REFERENCE.md)** - Complete playbook documentation
- **[TESTING_AND_VALIDATION.md](TESTING_AND_VALIDATION.md)** - Testing framework and validation
- **[INTERVIEW_BRIEF_PSEG_CM.md](INTERVIEW_BRIEF_PSEG_CM.md)** - PSEG Configuration Management mapping

## Key Components

### Ansible Automation
- **Location**: `ansible/` directory
- **Playbooks**: `setup-aws-instances.yml`, `setup-baseline.yml`
- **Roles**: `security_hardening`, `system_baseline`, `monitoring_setup`
- **Inventory**: `inventory/aws-instances` with mixed OS support

### File Integrity Monitoring
- **Location**: `fim/agents/fim-agent.py`
- **Configuration**: `fim/agents/fim-config.json`
- **Monitoring**: Real-time file change detection with Prometheus metrics
- **Baseline**: SHA-256 hash-based integrity verification

### Configuration Management Database
- **Location**: `cmdb/scripts/cmdb-collector.py`
- **Data Collection**: System info, packages, services, network config
- **Storage**: JSON-based data export with Prometheus instrumentation
- **Automation**: Systemd timer-based collection

### Monitoring Stack
- **Prometheus**: `prometheus.yml` configuration with SSH tunnel targets
- **Grafana**: Pre-configured dashboards in `grafana/dashboards/`
- **SSH Tunnels**: Secure monitoring without AWS security group changes
- **Metrics**: Node Exporter, FIM events, CMDB data collection

## Production Ready

This lab provides enterprise-grade capabilities suitable for:
- Configuration management automation
- Security compliance monitoring  
- Infrastructure asset tracking
- DevOps learning and training
- Real-world production scenarios

## Support

For detailed setup instructions, troubleshooting, and advanced usage, refer to the comprehensive documentation in the `GAB/` directory.
