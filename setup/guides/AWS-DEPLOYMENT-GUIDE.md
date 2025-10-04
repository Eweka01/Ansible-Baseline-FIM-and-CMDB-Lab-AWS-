# AWS Deployment Guide - Production Monitoring Stack

This guide will help you deploy your Ansible Baseline, FIM, and CMDB lab to your AWS EC2 instances with **live monitoring** via Prometheus + Grafana.

## 🎯 Your AWS Instances

You have 3 AWS EC2 instances ready for deployment:

| Instance Name | Instance ID | Public IP | Role | OS | User |
|---------------|-------------|-----------|------|----|----- |
| manage-node-1 | i-0006c64a0f6f64259 | 18.234.152.228 | Web Server | Amazon Linux | ec2-user |
| manage-node-2 | i-009c6ab695ca10c7e | 54.242.234.69 | Database Server | Ubuntu | ubuntu |
| manage-node-3 | i-0cfb3f2e1be0bbd44 | 13.217.82.23 | Monitoring Server | Ubuntu | ubuntu |

**Instance Details:**
- **Type**: t2.micro
- **OS**: Mixed (Amazon Linux + Ubuntu)
- **Region**: us-east-1a
- **SSH Key**: key-p3
- **Security Group**: default

## 🚀 Quick Start

### Step 1: Setup SSH Connectivity

```bash
# Run the SSH setup script
./setup/scripts/setup-aws-ssh.sh
```

This script will:
- Find your SSH key (key-p3.pem)
- Test connectivity to all instances
- Configure SSH shortcuts
- Verify all connections work

### Step 2: Deploy the Lab

```bash
# Deploy to all AWS instances
cd ansible
ansible-playbook -i inventory/aws-instances playbooks/setup-aws-instances.yml
```

### Step 3: Setup Live Monitoring

```bash
# Start Prometheus + Grafana stack
docker compose -f docker-compose.yml up -d

# Setup SSH tunnels for monitoring (bypasses AWS security groups)
./setup-ssh-tunnel-monitoring.sh
```

### Step 4: Verify Deployment

```bash
# Check deployment status
ansible aws_instances -i inventory/aws-instances -m shell -a "systemctl status fim-agent cmdb-collector.timer"

# Test monitoring stack
./test-prometheus-grafana-fix.sh

# Check tunnel status
./manage-tunnels.sh status
```

## 📊 Access Your Live Monitoring

Once deployed, you can access your monitoring stack:

### 🌐 Web Interfaces
- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Lab Dashboard**: http://localhost:8080/simple-monitoring-dashboard.html

### 🔍 Prometheus Queries
Try these live queries in Prometheus:
```promql
# Check if all targets are up
up{job="aws-nodes"}

# CPU usage by instance
node_cpu_seconds_total

# Available memory
node_memory_MemAvailable_bytes

# Disk space
node_filesystem_size_bytes
```

### 🧪 Testing Commands

```bash
# Check FIM logs
ansible aws_instances -i inventory/aws-instances -m shell -a "tail -f /var/log/fim-agent.log"

# Check CMDB data
ansible aws_instances -i inventory/aws-instances -m shell -a "ls -la /var/lib/cmdb/data/"
```

## ⚠️ Important: Mixed OS Setup

Your instances have different operating systems:
- **manage-node-1**: Amazon Linux (uses `ec2-user`)
- **manage-node-2**: Ubuntu (uses `ubuntu`)  
- **manage-node-3**: Ubuntu (uses `ubuntu`)

The deployment playbook automatically handles the differences between Amazon Linux and Ubuntu, including:
- Different package managers (`yum` vs `apt`)
- Different firewall systems (`iptables` vs `ufw`)
- Different default users (`ec2-user` vs `ubuntu`)

## 📋 Prerequisites

> **Note**: This lab is designed specifically for AWS EC2 deployment. Local testing components have been removed to focus on cloud infrastructure automation.

### 1. SSH Key Setup

Make sure you have your SSH key (`key-p3.pem`) in one of these locations:
- `~/Desktop/key-p3.pem` ✅ **Your key is here**
- `~/.ssh/key-p3.pem`
- `~/Downloads/key-p3.pem`
- `~/key-p3.pem`
- `./key-p3.pem`

**Download from AWS Console:**
1. Go to AWS Console > EC2 > Key Pairs
2. Find `key-p3`
3. Click Actions > Download
4. Save to one of the locations above

### 2. Security Group Configuration

Ensure your security group allows:
- **SSH (22)** - for Ansible connections
- **HTTP (80)** - for web servers
- **HTTPS (443)** - for web servers (optional)

### 3. Instance Status

Verify all instances are:
- ✅ **Running** (not stopped/terminated)
- ✅ **Status Check**: 2/2 checks passed
- ✅ **Network**: Public IP accessible

## 🔧 Detailed Deployment Steps

### Step 1: SSH Key Setup

```bash
# Make sure the key has correct permissions
chmod 600 ~/.ssh/key-p3.pem

# Test SSH connection manually
ssh -i ~/.ssh/key-p3.pem ubuntu@18.234.152.228
```

### Step 2: Ansible Inventory Configuration

The inventory file `ansible/inventory/aws-instances` is already configured with:
- All 3 instances with their public IPs
- Proper SSH key path
- Role assignments (web, database, monitoring)
- AWS-specific variables

### Step 3: Deploy to Specific Groups

```bash
# Deploy only to web servers
ansible-playbook -i inventory/aws-instances playbooks/setup-aws-instances.yml --limit webservers

# Deploy only to database servers
ansible-playbook -i inventory/aws-instances playbooks/setup-aws-instances.yml --limit databases

# Deploy only to monitoring servers
ansible-playbook -i inventory/aws-instances playbooks/setup-aws-instances.yml --limit monitoring
```

### Step 4: Verify Services

```bash
# Check FIM agent status
ansible aws_instances -i inventory/aws-instances -m systemd -a "name=fim-agent state=started"

# Check CMDB collector status
ansible aws_instances -i inventory/aws-instances -m systemd -a "name=cmdb-collector.timer state=started"

# Check firewall status
ansible aws_instances -i inventory/aws-instances -m shell -a "ufw status"
```

## 📊 What Gets Deployed

### On Each Instance:

1. **System Packages**
   - Python 3 and pip
   - Essential tools (curl, wget, vim, htop, etc.)
   - Security tools (fail2ban, ufw, auditd, aide)
   - Monitoring tools (sysstat, iotop)

2. **Python Dependencies**
   - psutil, watchdog, pyyaml, jinja2
   - requests, paramiko, cryptography

3. **Lab Components**
   - FIM Agent (`/opt/lab-environment/fim-agent.py`)
   - CMDB Collector (`/opt/lab-environment/cmdb-collector.py`)
   - Configuration files in `/etc/fim/` and `/etc/cmdb/`

4. **System Services**
   - FIM Agent service (continuous monitoring)
   - CMDB Collector timer (hourly data collection)
   - Fail2ban (intrusion prevention)
   - UFW firewall (network security)

5. **Security Configuration**
   - Firewall rules (SSH, HTTP, HTTPS)
   - Fail2ban jail configuration
   - SSH security hardening
   - File permissions and ownership

## 🔍 Monitoring and Verification

### 🎯 Quick Testing Commands

**Start with these essential commands to verify your deployment:**

```bash
# 1. Check if services are running
cd ansible
ansible aws_instances -i inventory/aws-instances -m shell -a "systemctl is-active fim-agent cmdb-collector.timer"

# 2. View real FIM logs from all instances (NEW!)
./show-real-fim-logs.sh

# 3. Test manual FIM scan
ansible aws_instances -i inventory/aws-instances -m shell -a "/opt/lab-env/bin/python /opt/lab-environment/fim-agent.py --scan-once"

# 4. Check CMDB data collection
ansible aws_instances -i inventory/aws-instances -m shell -a "ls -la /var/lib/cmdb/data/"
```

### 📊 Centralized Log Viewing (NEW!)

**View FIM logs from your local machine without SSH'ing to each server:**

```bash
# View real FIM logs from all instances
./show-real-fim-logs.sh

# View FIM logs from specific instance
./show-real-fim-logs.sh manage-node-1
./show-real-fim-logs.sh manage-node-2
./show-real-fim-logs.sh manage-node-3

# View FIM summary only
./show-real-fim-logs.sh summary

# Collect and organize all FIM logs locally
./collect-fim-logs.sh
```

### 🔍 Detailed FIM Testing

```bash
# Run FIM scan on all instances
ansible aws_instances -i inventory/aws-instances -m shell -a "/opt/lab-env/bin/python /opt/lab-environment/fim-agent.py --scan-once"

# Check FIM baseline
ansible aws_instances -i inventory/aws-instances -m shell -a "ls -la /var/lib/fim/"

# View FIM service status
ansible aws_instances -i inventory/aws-instances -m shell -a "systemctl status fim-agent"

# View recent FIM activity (shows actual log content)
./show-real-fim-logs.sh all 20
```

### 🗄️ CMDB Testing

```bash
# Run CMDB collection
ansible aws_instances -i inventory/aws-instances -m shell -a "/opt/lab-env/bin/python /opt/lab-environment/cmdb-collector.py"

# Check collected data
ansible aws_instances -i inventory/aws-instances -m shell -a "ls -la /var/lib/cmdb/data/"

# View system information
ansible aws_instances -i inventory/aws-instances -m shell -a "cat /etc/system-info"

# Check CMDB service status
ansible aws_instances -i inventory/aws-instances -m shell -a "systemctl status cmdb-collector.timer"
```

### 🛡️ Security Configuration Testing

```bash
# Check firewall status (Ubuntu)
ansible aws_instances -i inventory/aws-instances -m shell -a "ufw status verbose"

# Check firewall status (Amazon Linux)
ansible manage-node-1 -i inventory/aws-instances -m shell -a "systemctl status firewalld"

# Check fail2ban status
ansible aws_instances -i inventory/aws-instances -m shell -a "systemctl status fail2ban"

# Check SSH configuration
ansible aws_instances -i inventory/aws-instances -m shell -a "sshd -T | grep -E '(PermitRootLogin|PasswordAuthentication)'"
```

### 🧪 Comprehensive Testing

```bash
# Run all lab tests
./tests/scripts/run-lab-tests.sh

# Test FIM functionality locally
./tests/scripts/test-fim.py

# Test CMDB functionality locally
./tests/scripts/test-cmdb.py
```

## 🚨 Troubleshooting

### Common Issues

1. **SSH Connection Failed**
   ```bash
   # Check if instances are running
   aws ec2 describe-instances --instance-ids i-0006c64a0f6f64259 i-009c6ab695ca10c7e i-0cfb3f2e1be0bbd44
   
   # Check security group
   aws ec2 describe-security-groups --group-names default
   ```

2. **Ansible Connection Issues**
   ```bash
   # Test connectivity
   ansible aws_instances -i inventory/aws-instances -m ping
   
   # Check SSH key permissions
   ls -la ~/.ssh/key-p3.pem
   ```

3. **Service Failures**
   ```bash
   # Check service logs
   ansible aws_instances -i inventory/aws-instances -m shell -a "journalctl -u fim-agent -n 20"
   
   # Restart services
   ansible aws_instances -i inventory/aws-instances -m systemd -a "name=fim-agent state=restarted"
   ```

### Debug Commands

```bash
# Run playbook in verbose mode
ansible-playbook -i inventory/aws-instances playbooks/setup-aws-instances.yml -vvv

# Test specific tasks
ansible-playbook -i inventory/aws-instances playbooks/setup-aws-instances.yml --check

# Run with specific tags
ansible-playbook -i inventory/aws-instances playbooks/setup-aws-instances.yml --tags "fim,cmdb"
```

## 📈 Next Steps After Deployment

### 1. **Monitor the Lab**
```bash
# Set up log monitoring
ansible aws_instances -i inventory/aws-instances -m shell -a "tail -f /var/log/fim-agent.log"
```

### 2. **Test File Changes**
```bash
# Create test files on instances
ansible aws_instances -i inventory/aws-instances -m shell -a "echo 'test' > /tmp/test-file"

# Check if FIM detects the change
ansible aws_instances -i inventory/aws-instances -m shell -a "tail -5 /var/log/fim-reports.json"
```

### 3. **Collect CMDB Data**
```bash
# Run manual CMDB collection
ansible aws_instances -i inventory/aws-instances -m shell -a "/opt/lab-environment/cmdb-collector.py"

# Download CMDB data for analysis
scp ubuntu@18.234.152.228:/var/lib/cmdb/data/* ./aws-cmdb-data/
```

### 4. **Set Up Centralized Monitoring**
- Configure log aggregation
- Set up alerting for FIM changes
- Create dashboards for CMDB data
- Implement automated reporting

## 🎉 Success Criteria

Your deployment is successful when:

✅ **All instances respond to Ansible**
✅ **FIM agent is running and monitoring files**
✅ **CMDB collector is gathering data hourly**
✅ **Firewall is configured and active**
✅ **Fail2ban is protecting against brute force**
✅ **All services are enabled and running**
✅ **Log files are being generated**
✅ **System information is being collected**

## 📞 Support

If you encounter issues:

1. **Check the logs** on each instance
2. **Run the test suite** locally first
3. **Verify SSH connectivity** manually
4. **Check AWS console** for instance status
5. **Review security group** settings

Your lab is now ready for production use on AWS! 🚀
