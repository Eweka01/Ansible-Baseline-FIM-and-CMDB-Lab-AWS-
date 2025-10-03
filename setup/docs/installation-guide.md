# Installation Guide

This guide provides step-by-step instructions for setting up the Ansible Baseline, FIM, and CMDB lab environment.

## Prerequisites

### System Requirements
- **Operating System**: Ubuntu 20.04+ or CentOS 7+ (or compatible distributions)
- **Memory**: Minimum 2GB RAM, recommended 4GB+
- **Storage**: Minimum 10GB free disk space
- **Network**: Internet connectivity for package installation

### Software Requirements
- Python 3.7 or higher
- Ansible 2.9 or higher
- Git
- SSH client and server
- curl and wget

## Installation Steps

### 1. System Preparation

#### Update System Packages
```bash
# Ubuntu/Debian
sudo apt update && sudo apt upgrade -y

# CentOS/RHEL
sudo yum update -y
```

#### Install Essential Packages
```bash
# Ubuntu/Debian
sudo apt install -y python3 python3-pip python3-venv git curl wget vim htop

# CentOS/RHEL
sudo yum install -y python3 python3-pip git curl wget vim htop
```

### 2. Ansible Installation

#### Install Ansible
```bash
# Ubuntu/Debian
sudo apt install -y ansible

# CentOS/RHEL
sudo yum install -y ansible

# Or install via pip
pip3 install ansible
```

#### Verify Ansible Installation
```bash
ansible --version
```

### 3. Python Dependencies

#### Install Required Python Packages
```bash
pip3 install psutil watchdog pyyaml jinja2
```

#### Create Virtual Environment (Optional but Recommended)
```bash
python3 -m venv lab-env
source lab-env/bin/activate
pip install -r requirements.txt
```

### 4. SSH Configuration

#### Generate SSH Key Pair
```bash
ssh-keygen -t rsa -b 4096 -C "lab@$(hostname)"
```

#### Configure SSH Client
```bash
# Create SSH config
mkdir -p ~/.ssh
cat >> ~/.ssh/config << EOF
Host lab-*
    User ansible
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF
```

### 5. Lab Environment Setup

#### Clone or Copy Lab Files
```bash
# If using git
git clone <repository-url> lab-environment
cd lab-environment

# Or copy files to your desired location
cp -r /path/to/lab/files /opt/lab-environment
cd /opt/lab-environment
```

#### Set Permissions
```bash
chmod +x tests/run-all-tests.sh
chmod +x fim/agents/fim-agent.py
chmod +x cmdb/scripts/cmdb-collector.py
```

### 6. Configuration

#### Configure Ansible Inventory
Edit `ansible/inventory/hosts` to match your environment:

```ini
[all:vars]
ansible_user=your_username
ansible_ssh_private_key_file=~/.ssh/id_rsa

[webservers]
web01 ansible_host=192.168.1.10
web02 ansible_host=192.168.1.11

[databases]
db01 ansible_host=192.168.1.20

[monitoring]
monitor01 ansible_host=192.168.1.30
```

#### Configure FIM Settings
Edit `fim/agents/fim-config.json` to customize monitoring paths:

```json
{
  "monitored_paths": [
    "/etc",
    "/usr/bin",
    "/usr/sbin",
    "/var/log"
  ],
  "excluded_paths": [
    "/tmp",
    "/var/tmp",
    "/var/cache"
  ],
  "scan_interval": 300
}
```

#### Configure CMDB Settings
Edit `cmdb/scripts/cmdb-collector.py` if needed for your environment.

### 7. Service Setup

#### Create System Users
```bash
# Create ansible user on target systems
sudo useradd -m -s /bin/bash ansible
sudo usermod -aG sudo ansible

# Copy SSH public key
ssh-copy-id ansible@target-host
```

#### Setup FIM Service
```bash
# Create FIM service file
sudo tee /etc/systemd/system/fim-agent.service << EOF
[Unit]
Description=FIM Agent
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /opt/lab-environment/fim/agents/fim-agent.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable fim-agent
sudo systemctl start fim-agent
```

#### Setup CMDB Collection
```bash
# Create CMDB collection cron job
sudo tee /etc/cron.d/cmdb-collection << EOF
# CMDB data collection - every hour
0 * * * * root /usr/bin/python3 /opt/lab-environment/cmdb/scripts/cmdb-collector.py
EOF
```

### 8. Verification

#### Test Ansible Connectivity
```bash
cd ansible
ansible all -m ping
```

#### Test FIM Agent
```bash
# Check FIM agent status
sudo systemctl status fim-agent

# Test FIM functionality
sudo python3 fim/agents/fim-agent.py --scan-once
```

#### Test CMDB Collector
```bash
# Run CMDB collector
python3 cmdb/scripts/cmdb-collector.py

# Verify data collection
ls -la /var/lib/cmdb/data/
```

### 9. Initial Baseline Deployment

#### Deploy Baseline Configuration
```bash
cd ansible
ansible-playbook -i inventory/hosts playbooks/setup-baseline.yml
```

#### Initialize FIM Baseline
```bash
# On each target system
sudo python3 /opt/lab-environment/fim/agents/fim-agent.py --init-baseline
```

#### Run Initial CMDB Collection
```bash
# On each target system
python3 /opt/lab-environment/cmdb/scripts/cmdb-collector.py
```

## Post-Installation

### 1. Run Test Suite
```bash
cd tests
./run-all-tests.sh
```

### 2. Review Logs
```bash
# Check Ansible logs
tail -f ansible/ansible.log

# Check FIM logs
tail -f /var/log/fim-agent.log

# Check CMDB logs
tail -f /var/log/cmdb-collector.log
```

### 3. Access Web Interfaces (if configured)
- **Monitoring Dashboard**: http://monitor-host:3000
- **CMDB Interface**: http://cmdb-host:8080

## Troubleshooting

### Common Issues

#### SSH Connection Problems
```bash
# Test SSH connectivity
ssh -v ansible@target-host

# Check SSH key permissions
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

#### Ansible Permission Issues
```bash
# Check sudo configuration
sudo visudo

# Add ansible user to sudoers
echo "ansible ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ansible
```

#### Python Module Issues
```bash
# Install missing modules
pip3 install --user psutil watchdog pyyaml

# Check Python path
python3 -c "import sys; print(sys.path)"
```

#### Service Issues
```bash
# Check service status
sudo systemctl status fim-agent

# Check service logs
sudo journalctl -u fim-agent -f

# Restart service
sudo systemctl restart fim-agent
```

### Getting Help

1. Check the logs in `/var/log/` for error messages
2. Review the test scenarios in `tests/test-scenarios.md`
3. Verify configuration files for syntax errors
4. Ensure all prerequisites are installed
5. Check network connectivity between systems

## Next Steps

After successful installation:

1. **Customize Configuration**: Modify configuration files to match your environment
2. **Add More Hosts**: Update inventory files with additional systems
3. **Configure Monitoring**: Set up monitoring dashboards and alerting
4. **Run Tests**: Execute the test suite to validate functionality
5. **Document Changes**: Keep track of any customizations made

## Security Considerations

- Change default passwords and keys
- Configure firewall rules appropriately
- Enable audit logging
- Regularly update system packages
- Monitor system logs for suspicious activity
- Implement proper backup procedures

