# User Guide

This guide provides comprehensive instructions for using the Ansible Baseline, FIM, and CMDB lab environment.

## Overview

The lab environment consists of three main components:

1. **Ansible Baseline**: Automated system configuration and compliance
2. **File Integrity Monitoring (FIM)**: Real-time file change detection
3. **Configuration Management Database (CMDB)**: Asset and configuration tracking

## Getting Started

### Quick Start

1. **Deploy Baseline Configuration**:
   ```bash
   cd ansible
   ansible-playbook -i inventory/hosts playbooks/setup-baseline.yml
   ```

2. **Initialize FIM Monitoring**:
   ```bash
   sudo python3 fim/agents/fim-agent.py --init-baseline
   ```

3. **Collect CMDB Data**:
   ```bash
   python3 cmdb/scripts/cmdb-collector.py
   ```

## Ansible Baseline

### Configuration Management

#### Applying Baseline Configuration
```bash
# Apply to all hosts
ansible-playbook -i inventory/hosts playbooks/setup-baseline.yml

# Apply to specific group
ansible-playbook -i inventory/hosts playbooks/setup-baseline.yml --limit webservers

# Apply with tags
ansible-playbook -i inventory/hosts playbooks/setup-baseline.yml --tags security
```

#### Checking Configuration Status
```bash
# Check if baseline is applied
ansible all -m shell -a "test -f /etc/ansible-baseline-completed && echo 'Baseline applied' || echo 'Baseline not applied'"

# Check system information
ansible all -m shell -a "cat /etc/system-info"
```

#### Customizing Configuration

Edit group variables in `ansible/group_vars/all.yml`:
```yaml
# Example: Change timezone
system:
  timezone: "America/New_York"

# Example: Add custom packages
packages:
  essential:
    - curl
    - wget
    - vim
    - htop
    - my-custom-package
```

### Role Management

#### Available Roles
- `system_baseline`: Basic system configuration
- `security_hardening`: Security settings and hardening
- `package_management`: Package installation and management
- `network_config`: Network configuration
- `logging_setup`: Logging configuration
- `monitoring_setup`: Monitoring configuration
- `backup_setup`: Backup configuration

#### Running Specific Roles
```bash
# Run only security hardening
ansible-playbook -i inventory/hosts playbooks/setup-baseline.yml --tags security

# Run only system baseline
ansible-playbook -i inventory/hosts playbooks/setup-baseline.yml --tags system
```

## File Integrity Monitoring (FIM)

### FIM Agent Management

#### Starting FIM Agent
```bash
# Start as service
sudo systemctl start fim-agent

# Start manually
sudo python3 fim/agents/fim-agent.py

# Start with custom config
sudo python3 fim/agents/fim-agent.py --config /path/to/custom-config.json
```

#### Stopping FIM Agent
```bash
# Stop service
sudo systemctl stop fim-agent

# Stop manually (Ctrl+C)
```

#### Checking FIM Status
```bash
# Check service status
sudo systemctl status fim-agent

# Check FIM logs
tail -f /var/log/fim-agent.log

# Check baseline database
ls -la /var/lib/fim/
```

### FIM Configuration

#### Monitoring Paths
Edit `fim/agents/fim-config.json`:
```json
{
  "monitored_paths": [
    "/etc",
    "/usr/bin",
    "/usr/sbin",
    "/var/log",
    "/home",
    "/opt"
  ],
  "excluded_paths": [
    "/tmp",
    "/var/tmp",
    "/var/cache",
    "/var/log/*.log"
  ]
}
```

#### Scan Intervals
```json
{
  "scan_interval": 300,  // 5 minutes
  "report_interval": 3600  // 1 hour
}
```

### FIM Operations

#### Manual Scan
```bash
# Perform single scan
sudo python3 fim/agents/fim-agent.py --scan-once

# Initialize new baseline
sudo python3 fim/agents/fim-agent.py --init-baseline
```

#### Viewing Reports
```bash
# View latest report
cat /var/log/fim-reports.json | jq '.[-1]'

# View all reports
cat /var/log/fim-reports.json | jq '.'

# View specific change
cat /var/log/fim-reports.json | jq '.[] | select(.changes[].file | contains("passwd"))'
```

#### FIM Rules Management
Edit `fim/rules/fim-rules.yml` to customize monitoring rules:
```yaml
monitoring_rules:
  - name: "Critical System Files"
    paths:
      - "/etc"
    priority: "critical"
    scan_interval: 300
    alert_on_change: true
```

## Configuration Management Database (CMDB)

### Data Collection

#### Manual Data Collection
```bash
# Collect all data
python3 cmdb/scripts/cmdb-collector.py

# Collect specific component
python3 cmdb/scripts/cmdb-collector.py --component system

# Collect with custom output directory
python3 cmdb/scripts/cmdb-collector.py --output-dir /custom/path
```

#### Automated Data Collection
```bash
# Setup cron job for hourly collection
echo "0 * * * * root /usr/bin/python3 /opt/lab-environment/cmdb/scripts/cmdb-collector.py" | sudo tee /etc/cron.d/cmdb-collection
```

### Data Analysis

#### Viewing Collected Data
```bash
# List collected data files
ls -la /var/lib/cmdb/data/

# View latest system data
cat /var/lib/cmdb/data/system_info-*.json | jq '.'

# View hardware information
cat /var/lib/cmdb/data/hardware_info-*.json | jq '.cpu'
```

#### Data Comparison
```bash
# Compare data between timestamps
diff /var/lib/cmdb/data/cmdb-data-20231201-120000.json /var/lib/cmdb/data/cmdb-data-20231201-130000.json
```

### CMDB Schema Validation

#### Validate Data Structure
```bash
# Install jsonschema if not already installed
pip3 install jsonschema

# Validate against schema
python3 -c "
import json
import jsonschema
with open('cmdb/schemas/cmdb-schema.json') as f:
    schema = json.load(f)
with open('/var/lib/cmdb/data/cmdb-data-*.json') as f:
    data = json.load(f)
jsonschema.validate(data, schema)
print('Data is valid')
"
```

## Monitoring and Alerting

### System Monitoring

#### Check System Status
```bash
# Check all services
ansible all -m systemd -a "name=fim-agent state=started"

# Check disk usage
ansible all -m shell -a "df -h"

# Check memory usage
ansible all -m shell -a "free -h"
```

#### View Logs
```bash
# Ansible logs
tail -f ansible/ansible.log

# FIM logs
ansible all -m shell -a "tail -f /var/log/fim-agent.log"

# System logs
ansible all -m shell -a "tail -f /var/log/syslog"
```

### Alerting Configuration

#### Email Alerts
Configure email alerts in FIM config:
```json
{
  "notification": {
    "enabled": true,
    "email": {
      "enabled": true,
      "smtp_server": "smtp.example.com",
      "smtp_port": 587,
      "username": "alerts@example.com",
      "password": "password",
      "to_addresses": ["admin@example.com"]
    }
  }
}
```

#### Webhook Alerts
```json
{
  "notification": {
    "webhook": {
      "enabled": true,
      "url": "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK",
      "headers": {
        "Content-Type": "application/json"
      }
    }
  }
}
```

## Troubleshooting

### Common Issues

#### Ansible Issues
```bash
# Test connectivity
ansible all -m ping

# Check syntax
ansible-playbook --syntax-check playbooks/setup-baseline.yml

# Run in verbose mode
ansible-playbook -i inventory/hosts playbooks/setup-baseline.yml -vvv
```

#### FIM Issues
```bash
# Check FIM agent process
ps aux | grep fim-agent

# Check FIM configuration
python3 -m json.tool fim/agents/fim-config.json

# Test FIM functionality
sudo python3 fim/agents/fim-agent.py --scan-once
```

#### CMDB Issues
```bash
# Check Python dependencies
python3 -c "import psutil, json, datetime"

# Test data collection
python3 cmdb/scripts/cmdb-collector.py --component system

# Check data files
ls -la /var/lib/cmdb/data/
```

### Performance Optimization

#### FIM Performance
- Adjust scan intervals based on system load
- Exclude frequently changing directories
- Use SSD storage for baseline database

#### CMDB Performance
- Schedule collection during low-usage periods
- Compress old data files
- Use efficient data storage formats

#### Ansible Performance
- Increase fork count in ansible.cfg
- Use pipelining for faster execution
- Cache facts for repeated runs

## Best Practices

### Security
- Regularly update system packages
- Monitor security logs
- Use strong authentication
- Encrypt sensitive data

### Maintenance
- Regular backup of configuration data
- Monitor disk space usage
- Update documentation
- Test changes in development first

### Monitoring
- Set up comprehensive logging
- Monitor system performance
- Track configuration changes
- Alert on critical events

## Advanced Usage

### Custom Playbooks
Create custom playbooks for specific tasks:
```yaml
---
- name: "Custom Configuration Task"
  hosts: all
  become: yes
  tasks:
    - name: "Custom task"
      shell: echo "Custom configuration applied"
```

### Custom FIM Rules
Create custom FIM rules for specific requirements:
```yaml
custom_rules:
  - name: "Application Monitoring"
    paths:
      - "/opt/myapp"
    priority: "high"
    scan_interval: 60
    alert_on_change: true
```

### Custom CMDB Collectors
Extend CMDB collector for additional data:
```python
def collect_custom_data(self):
    """Collect custom application data"""
    # Add custom data collection logic
    pass
```

## Support and Resources

### Documentation
- Installation Guide: `installation-guide.md`
- Test Scenarios: `../../tests/test-scenarios.md`
- API Documentation: `api-reference.md`

### Logs and Debugging
- Ansible logs: `ansible/ansible.log`
- FIM logs: `/var/log/fim-agent.log`
- CMDB logs: `/var/log/cmdb-collector.log`
- System logs: `/var/log/syslog`

### Getting Help
1. Check logs for error messages
2. Review configuration files
3. Run test scenarios
4. Consult documentation
5. Check system requirements

