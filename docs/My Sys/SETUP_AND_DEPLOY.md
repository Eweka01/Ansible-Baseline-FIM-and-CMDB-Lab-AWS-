# Setup and Deployment Guide

## Prerequisites

### System Requirements
- **Operating System**: macOS (ARM64), Linux (x86_64), or Windows with WSL2
- **Python**: 3.8+ with pip package manager
- **Docker**: 20.10+ with Docker Compose
- **SSH Client**: OpenSSH 7.0+ for key-based authentication
- **Git**: 2.20+ for version control

### AWS Requirements
- **EC2 Instances**: 3 running instances with public IP addresses
- **SSH Key Pair**: `key-p3.pem` file in `~/Desktop/` directory
- **Security Groups**: Allow SSH (port 22) from your IP address
- **Instance Types**: t2.micro or larger (minimum 1GB RAM, 1 vCPU)

### Required AWS Instances
```
manage-node-1 (Amazon Linux 2023): 18.234.152.228
manage-node-2 (Ubuntu 24.04):      54.242.234.69
manage-node-3 (Ubuntu 24.04):      13.217.82.23
```

## Installation Steps

### 1. Clone and Setup Repository
```bash
# Navigate to project directory
cd "/Users/osamudiameneweka/Desktop/Ansible Baseline, FIM, and CMDB Lab"

# Verify SSH key permissions
chmod 600 ~/Desktop/key-p3.pem

# Create Python virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install Python dependencies
pip install -r requirements.txt
```

### 2. Install Ansible and Collections
```bash
# Install Ansible
pip install ansible>=2.9.0

# Install required Ansible collections
ansible-galaxy collection install community.general
ansible-galaxy collection install ansible.posix
ansible-galaxy collection install community.docker

# Verify Ansible installation
ansible --version
ansible-playbook --version
```

### 3. Configure Ansible
```bash
# Verify ansible.cfg configuration
cat ansible/ansible.cfg

# Test SSH connectivity to AWS instances
ansible aws_instances -i ansible/inventory/aws-instances -m ping
```

Expected output:
```
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

### 4. Deploy to AWS Instances
```bash
# Deploy complete lab environment
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml

# Verify deployment with specific tags
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml --tags security
```

### 5. Setup Monitoring Stack
```bash
# Start Prometheus and Grafana
docker compose -f docker-compose.yml up -d

# Verify containers are running
docker ps

# Setup SSH tunnels for monitoring
./setup-ssh-tunnel-monitoring.sh

# Verify tunnel status
./manage-tunnels.sh status
```

### 6. Initialize FIM and CMDB
```bash
# Initialize FIM baseline on all instances
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "/opt/lab-env/bin/python /opt/lab-environment/fim-agent.py --init-baseline"

# Run initial CMDB collection
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "/opt/lab-env/bin/python /opt/lab-environment/cmdb-collector.py"

# Verify services are running
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "systemctl status fim-agent cmdb-collector.timer node_exporter"
```

## Inventory Configuration

### AWS Instances Inventory
**File**: `ansible/inventory/aws-instances`

```ini
[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/Desktop/key-p3.pem
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[webservers]
manage-node-1 ansible_host=18.234.152.228 ansible_user=ec2-user

[databases]
manage-node-2 ansible_host=54.242.234.69 ansible_user=ubuntu

[monitoring]
manage-node-3 ansible_host=13.217.82.23 ansible_user=ubuntu

[aws_instances:children]
webservers
databases
monitoring
```

### Group Variables
**File**: `ansible/group_vars/all.yml`

Key configuration sections:
- **System Configuration**: Timezone, locale, hostname settings
- **Security Settings**: Firewall, SSH, user management
- **Package Management**: Essential, security, monitoring packages
- **FIM Configuration**: Monitored paths, scan intervals, alerting
- **CMDB Configuration**: Data collection intervals, auto-discovery

## Playbook Execution

### Basic Deployment
```bash
# Deploy to all instances
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml

# Deploy to specific group
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml --limit webservers

# Deploy to single instance
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml --limit manage-node-1
```

### Tagged Execution
```bash
# Security hardening only
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml --tags security

# Package installation only
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml --tags packages

# Skip specific tasks
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml --skip-tags backup
```

### Dry Run and Diff Mode
```bash
# Check what would be changed without making changes
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml --check

# Show differences for changed files
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml --check --diff

# Verbose output for debugging
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml -vvv
```

## Feature Configuration

### Enable/Disable Features via Variables

#### Security Features
```bash
# Disable firewall
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml -e "enable_firewall=false"

# Enable SELinux (Amazon Linux only)
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml -e "enable_selinux=true"
```

#### Monitoring Features
```bash
# Disable monitoring
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml -e "monitoring_enabled=false"

# Custom FIM scan interval (seconds)
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml -e "fim_scan_interval=600"
```

#### Backup Features
```bash
# Enable backup
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml -e "backup_enabled=true"
```

### Environment-Specific Configuration

#### Development Environment
```bash
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml -e "environment=development" -e "security_level=basic"
```

#### Production Environment
```bash
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml -e "environment=production" -e "security_level=strict"
```

## Verification and Testing

### Post-Deployment Verification
```bash
# Check service status
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "systemctl is-active fim-agent cmdb-collector.timer node_exporter"

# Verify FIM baseline
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "ls -la /var/lib/fim/baseline.json"

# Check CMDB data collection
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "ls -la /var/lib/cmdb/data/"

# Test FIM agent
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "/opt/lab-env/bin/python /opt/lab-environment/fim-agent.py --scan-once"

# Test CMDB collector
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "/opt/lab-env/bin/python /opt/lab-environment/cmdb-collector.py --help"
```

### Monitoring Stack Verification
```bash
# Check Prometheus targets
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, instance: .labels.instance, health: .health}'

# Check Grafana data sources
curl -u admin:admin http://localhost:3000/api/datasources

# Test SSH tunnels
netstat -an | grep -E ":(9101|9102|9103|8080|8081|8082|8083|8084|8085)"
```

### Access Verification
```bash
# Grafana dashboard
open http://localhost:3000

# Prometheus interface
open http://localhost:9090

# Lab status dashboard
open http://localhost:8080/simple-monitoring-dashboard.html
```

## Troubleshooting Common Issues

### SSH Connection Issues
```bash
# Test SSH connectivity
ssh -i ~/Desktop/key-p3.pem ec2-user@18.234.152.228
ssh -i ~/Desktop/key-p3.pem ubuntu@54.242.234.69
ssh -i ~/Desktop/key-p3.pem ubuntu@13.217.82.23

# Check SSH key permissions
ls -la ~/Desktop/key-p3.pem
chmod 600 ~/Desktop/key-p3.pem
```

### Ansible Connection Issues
```bash
# Test with verbose output
ansible aws_instances -i ansible/inventory/aws-instances -m ping -vvv

# Check inventory syntax
ansible-inventory -i ansible/inventory/aws-instances --list

# Test specific host
ansible manage-node-1 -i ansible/inventory/aws-instances -m ping
```

### Service Issues
```bash
# Check service logs
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "journalctl -u fim-agent -n 20"
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "journalctl -u node_exporter -n 20"

# Restart services
ansible aws_instances -i ansible/inventory/aws-instances -m systemd -a "name=fim-agent state=restarted"
```

### Docker Issues
```bash
# Check container status
docker ps -a

# Check container logs
docker logs ansiblebaselinefimandcmdblab-prometheus-1
docker logs ansiblebaselinefimandcmdblab-grafana-1

# Restart containers
docker compose -f docker-compose.yml restart
```

## Security Considerations

### SSH Key Management
- Store SSH keys in secure locations with proper permissions (600)
- Use different keys for different environments
- Regularly rotate SSH keys in production

### Network Security
- Ensure AWS security groups only allow necessary ports
- Use SSH tunnels for monitoring instead of opening additional ports
- Implement fail2ban for intrusion prevention

### Access Control
- Use principle of least privilege for service accounts
- Regularly audit user accounts and permissions
- Monitor and log all administrative access

This deployment guide provides comprehensive instructions for setting up the complete lab environment with proper security controls and monitoring capabilities.
