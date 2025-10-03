# How to Use This Lab - Complete User Guide 🚀

This guide shows you exactly how to use your Ansible Baseline, FIM, and CMDB lab on AWS EC2 instances.

## 📋 Prerequisites Checklist

Before starting, ensure you have:

- ✅ **3 AWS EC2 instances running** (your instances are already set up)
- ✅ **SSH key file** (`key-p3.pem`) in `~/Desktop/key-p3.pem`
- ✅ **Ansible installed** on your local machine
- ✅ **Internet connectivity**

## 🎯 Your AWS Instances

| Instance | IP Address | OS | User | Role |
|----------|------------|----|----- |------|
| **manage-node-1** | 18.234.152.228 | Amazon Linux 2023 | ec2-user | Web Server |
| **manage-node-2** | 54.242.234.69 | Ubuntu 24.04 | ubuntu | Database Server |
| **manage-node-3** | 13.217.82.23 | Ubuntu 24.04 | ubuntu | Monitoring Server |

---

## 🚀 Step 1: Initial Setup (One-time)

### 1.1 Clone the Repository
```bash
# If you don't have the lab locally:
git clone https://github.com/Eweka01/Ansible-Baseline-FIM-and-CMDB-Lab-AWS-.git
cd Ansible-Baseline-FIM-and-CMDB-Lab-AWS-
```

### 1.2 Setup SSH Connectivity
```bash
# Make the script executable and run it
chmod +x setup/scripts/setup-aws-ssh.sh
./setup/scripts/setup-aws-ssh.sh
```

This will:
- Test SSH connections to all 3 instances
- Create SSH config file for easy access
- Verify your key permissions

### 1.3 Deploy the Lab
```bash
# Navigate to ansible directory
cd ansible

# Deploy to all AWS instances
ansible-playbook -i inventory/aws-instances playbooks/setup-aws-instances.yml
```

**Expected Output:**
- ✅ All 3 instances will be configured
- ✅ FIM agents will be installed and running
- ✅ CMDB collectors will be set up
- ✅ Security hardening will be applied
- ✅ Services will be started automatically

---

## 🔍 Step 2: Verify Your Deployment

### 2.1 Check Service Status
```bash
# Check if FIM agents are running
ansible -i inventory/aws-instances all -m shell -a "systemctl status fim-agent --no-pager"

# Check if CMDB collectors are working
ansible -i inventory/aws-instances all -m shell -a "systemctl status cmdb-collector.timer --no-pager"
```

### 2.2 Test Individual Components
```bash
# Test FIM agent manually
ansible -i inventory/aws-instances all -m shell -a "/opt/lab-env/bin/python /opt/lab-environment/fim-agent.py --scan-once"

# Test CMDB collector manually
ansible -i inventory/aws-instances all -m shell -a "/opt/lab-env/bin/python /opt/lab-environment/cmdb-collector.py"
```

### 2.3 Check Data Collection
```bash
# View FIM baseline data
ansible -i inventory/aws-instances all -m shell -a "ls -la /var/lib/fim/"

# View CMDB collected data
ansible -i inventory/aws-instances all -m shell -a "ls -la /var/lib/cmdb/data/"
```

---

## 🛠️ Step 3: Using the Lab Components

### 3.1 File Integrity Monitoring (FIM)

#### Connect to an Instance
```bash
# Connect to Amazon Linux instance
ssh -i ~/Desktop/key-p3.pem ec2-user@18.234.152.228

# Connect to Ubuntu instances
ssh -i ~/Desktop/key-p3.pem ubuntu@54.242.234.69
ssh -i ~/Desktop/key-p3.pem ubuntu@13.217.82.23
```

#### Check FIM Status
```bash
# Check FIM agent status
sudo systemctl status fim-agent

# View FIM logs
sudo tail -f /var/log/fim-agent.log

# View FIM configuration
sudo cat /etc/fim/fim-config.json
```

#### Test File Changes
```bash
# Create a test file to trigger FIM
sudo touch /etc/test-file.txt

# Run FIM scan to detect changes
sudo /opt/lab-env/bin/python /opt/lab-environment/fim-agent.py --scan-once

# Check for alerts
sudo tail -f /var/log/fim-agent.log
```

#### View FIM Reports
```bash
# View baseline data
sudo cat /var/lib/fim/baseline.json | jq .

# View change reports
sudo cat /var/lib/fim/reports.json | jq .
```

### 3.2 Configuration Management Database (CMDB)

#### Check CMDB Status
```bash
# Check CMDB collector status
sudo systemctl status cmdb-collector.timer

# View CMDB logs
sudo journalctl -u cmdb-collector.service
```

#### Run CMDB Collection
```bash
# Run CMDB collector manually
sudo /opt/lab-env/bin/python /opt/lab-environment/cmdb-collector.py

# Check collected data
ls -la /var/lib/cmdb/data/
```

#### View CMDB Data
```bash
# View system information
sudo cat /var/lib/cmdb/data/system_info-*.json | jq .

# View hardware information
sudo cat /var/lib/cmdb/data/hardware_info-*.json | jq .

# View software information
sudo cat /var/lib/cmdb/data/software_info-*.json | jq .
```

### 3.3 System Information
```bash
# View system information file
sudo cat /opt/lab-environment/system-info.txt

# View security configuration
sudo cat /etc/fail2ban/jail.local
```

---

## 🧪 Step 4: Lab Exercises and Testing

### 4.1 Test File Integrity Monitoring

#### Exercise 1: Monitor System Files
```bash
# 1. Check current baseline
sudo /opt/lab-env/bin/python /opt/lab-environment/fim-agent.py --scan-once

# 2. Make a change to a monitored file
sudo echo "test change" >> /etc/hostname

# 3. Run scan again to detect change
sudo /opt/lab-env/bin/python /opt/lab-environment/fim-agent.py --scan-once

# 4. Check the logs for alerts
sudo tail -f /var/log/fim-agent.log
```

#### Exercise 2: Test Different File Types
```bash
# Create files in different monitored directories
sudo touch /etc/test-config.conf
sudo touch /usr/bin/test-script.sh
sudo chmod +x /usr/bin/test-script.sh

# Run FIM scan
sudo /opt/lab-env/bin/python /opt/lab-environment/fim-agent.py --scan-once
```

### 4.2 Test CMDB Data Collection

#### Exercise 1: Collect System Information
```bash
# Run CMDB collector
sudo /opt/lab-env/bin/python /opt/lab-environment/cmdb-collector.py

# Check what data was collected
ls -la /var/lib/cmdb/data/

# View the collected data
sudo cat /var/lib/cmdb/data/system_info-*.json | jq '.system_info'
```

#### Exercise 2: Monitor Changes Over Time
```bash
# Run collection multiple times
sudo /opt/lab-env/bin/python /opt/lab-environment/cmdb-collector.py
sleep 60
sudo /opt/lab-env/bin/python /opt/lab-environment/cmdb-collector.py

# Compare timestamps in the data files
ls -la /var/lib/cmdb/data/
```

### 4.3 Test Ansible Automation

#### Exercise 1: Run Individual Tasks
```bash
# Update packages on all instances
ansible -i inventory/aws-instances all -m shell -a "sudo apt update" --become

# Check disk usage across all instances
ansible -i inventory/aws-instances all -m shell -a "df -h"

# Check memory usage
ansible -i inventory/aws-instances all -m shell -a "free -h"
```

#### Exercise 2: Deploy Configuration Changes
```bash
# Update FIM configuration on all instances
ansible -i inventory/aws-instances all -m template -a "src=../../ansible/playbooks/templates/fim-config-aws.j2 dest=/etc/fim/fim-config.json" --become

# Restart FIM agents
ansible -i inventory/aws-instances all -m systemd -a "name=fim-agent state=restarted" --become
```

---

## 📊 Step 5: Monitoring and Maintenance

### 5.1 Daily Monitoring Tasks

#### Check Service Health
```bash
# Check all services on all instances
ansible -i inventory/aws-instances all -m shell -a "systemctl status fim-agent cmdb-collector.timer fail2ban --no-pager"
```

#### View Logs
```bash
# Check FIM logs for alerts
ansible -i inventory/aws-instances all -m shell -a "sudo tail -20 /var/log/fim-agent.log"

# Check system logs
ansible -i inventory/aws-instances all -m shell -a "sudo journalctl -u fim-agent --no-pager -n 20"
```

#### Check Data Collection
```bash
# Verify CMDB data is being collected
ansible -i inventory/aws-instances all -m shell -a "ls -la /var/lib/cmdb/data/ | tail -5"
```

### 5.2 Weekly Maintenance Tasks

#### Update Baselines
```bash
# Update FIM baselines (run on each instance)
ssh -i ~/Desktop/key-p3.pem ec2-user@18.234.152.228 "sudo /opt/lab-env/bin/python /opt/lab-environment/fim-agent.py --init-baseline"
ssh -i ~/Desktop/key-p3.pem ubuntu@54.242.234.69 "sudo /opt/lab-env/bin/python /opt/lab-environment/fim-agent.py --init-baseline"
ssh -i ~/Desktop/key-p3.pem ubuntu@13.217.82.23 "sudo /opt/lab-env/bin/python /opt/lab-environment/fim-agent.py --init-baseline"
```

#### Clean Old Data
```bash
# Clean old CMDB data (keep last 30 days)
ansible -i inventory/aws-instances all -m shell -a "find /var/lib/cmdb/data/ -name '*.json' -mtime +30 -delete" --become
```

---

## 🔧 Step 6: Troubleshooting Common Issues

### 6.1 Service Issues

#### FIM Agent Not Running
```bash
# Check service status
sudo systemctl status fim-agent

# Restart the service
sudo systemctl restart fim-agent

# Check logs for errors
sudo journalctl -u fim-agent -f
```

#### CMDB Collector Not Working
```bash
# Check timer status
sudo systemctl status cmdb-collector.timer

# Run manually to test
sudo /opt/lab-env/bin/python /opt/lab-environment/cmdb-collector.py

# Check for Python module errors
sudo /opt/lab-env/bin/python -c "import psutil, watchdog, yaml"
```

### 6.2 Permission Issues

#### Fix File Permissions
```bash
# Fix FIM directory permissions
sudo chown -R root:root /var/lib/fim/
sudo chmod -R 755 /var/lib/fim/

# Fix CMDB directory permissions
sudo chown -R root:root /var/lib/cmdb/
sudo chmod -R 755 /var/lib/cmdb/
```

### 6.3 Network Issues

#### Test Connectivity
```bash
# Test SSH connectivity
ansible -i inventory/aws-instances all -m ping

# Test specific instance
ssh -i ~/Desktop/key-p3.pem ec2-user@18.234.152.228 "echo 'Connection successful'"
```

---

## 📚 Step 7: Advanced Usage

### 7.1 Custom FIM Rules

#### Add Custom Monitoring Paths
```bash
# Edit FIM configuration
sudo nano /etc/fim/fim-config.json

# Add custom paths to monitor
{
  "monitored_paths": [
    "/etc",
    "/usr/bin",
    "/var/log",
    "/home",
    "/opt",
    "/your/custom/path"  # Add your custom path here
  ]
}

# Restart FIM agent
sudo systemctl restart fim-agent
```

### 7.2 Custom CMDB Collection

#### Add Custom Data Collection
```bash
# Edit CMDB collector script
sudo nano /opt/lab-environment/cmdb-collector.py

# Add your custom collection logic
# Restart CMDB collector
sudo systemctl restart cmdb-collector.timer
```

### 7.3 Scaling to More Instances

#### Add New Instances
```bash
# Edit inventory file
nano ansible/inventory/aws-instances

# Add new instance:
# [new_group]
# new-instance ansible_host=NEW_IP ansible_user=ubuntu

# Deploy to new instances
ansible-playbook -i inventory/aws-instances playbooks/setup-aws-instances.yml --limit new_group
```

---

## 🎯 Step 8: Learning Objectives Achieved

By using this lab, you will have learned:

### ✅ **Ansible Automation**
- Deploy configurations across multiple servers
- Handle mixed OS environments (Amazon Linux + Ubuntu)
- Use conditional tasks and templates
- Manage services and systemd units

### ✅ **File Integrity Monitoring**
- Implement real-time file change detection
- Create and manage baselines
- Generate and analyze change reports
- Configure monitoring rules and policies

### ✅ **Configuration Management Database**
- Collect system and hardware information
- Store and manage configuration data
- Implement automated data collection
- Validate and structure collected data

### ✅ **Security Hardening**
- Configure firewalls (UFW and iptables)
- Implement intrusion detection (Fail2ban)
- Apply security policies and restrictions
- Monitor system security status

### ✅ **Cloud Infrastructure**
- Deploy to AWS EC2 instances
- Handle cloud-specific configurations
- Manage SSH keys and connectivity
- Scale infrastructure automation

---

## 🆘 Getting Help

### Documentation References
- **[AWS-DEPLOYMENT-GUIDE.md](AWS-DEPLOYMENT-GUIDE.md)** - Complete deployment instructions
- **[TROUBLESHOOTING-GUIDE.md](TROUBLESHOOTING-GUIDE.md)** - Common errors and solutions
- **[NEXT-STEPS.md](NEXT-STEPS.md)** - Advanced usage and extensions

### Quick Commands Reference
```bash
# Check all services
ansible -i inventory/aws-instances all -m shell -a "systemctl status fim-agent cmdb-collector.timer fail2ban"

# View logs
ansible -i inventory/aws-instances all -m shell -a "sudo tail -f /var/log/fim-agent.log"

# Run tests
ansible -i inventory/aws-instances all -m shell -a "/opt/lab-env/bin/python /opt/lab-environment/fim-agent.py --scan-once"
```

---

## 🎉 Congratulations!

You now have a fully functional Ansible Baseline, FIM, and CMDB lab running on AWS! This lab provides hands-on experience with:

- **Infrastructure Automation** with Ansible
- **Security Monitoring** with File Integrity Monitoring
- **Configuration Management** with CMDB
- **Cloud Operations** on AWS EC2

Use this lab to practice, experiment, and learn these essential DevOps and security skills! 🚀
