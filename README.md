# Ansible Baseline, FIM, and CMDB Lab - AWS Deployment

This lab provides a comprehensive environment for learning and practicing infrastructure automation on AWS EC2 instances:
- **Ansible Baseline**: Automated system configuration and compliance across mixed OS environments
- **File Integrity Monitoring (FIM)**: Real-time file change detection and alerting
- **Configuration Management Database (CMDB)**: Asset and configuration tracking

## 🎯 Lab Overview

This lab is designed for **AWS EC2 deployment** and supports mixed operating systems:
- **Amazon Linux 2023** (manage-node-1)
- **Ubuntu 24.04** (manage-node-2, manage-node-3)

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
├── logs/                   # Organized log files
│   ├── ansible/            # Ansible execution logs
│   ├── fim/                # FIM agent logs
│   ├── cmdb/               # CMDB collector logs
│   └── deployment/         # Deployment logs
├── data/                   # Data files and test results
│   ├── test-results/       # FIM baseline and test data
│   ├── reports/            # Generated reports
│   ├── test-files/         # Test files for monitoring
│   └── cmdb-test-data/     # CMDB collected data
├── tests/                  # Test scenarios and validation
│   ├── scripts/            # Test scripts with documentation
│   └── TESTING-GUIDE.md    # Comprehensive testing guide
├── docs/                   # Documentation
├── AWS-DEPLOYMENT-GUIDE.md # Step-by-step AWS deployment guide
├── TROUBLESHOOTING-GUIDE.md # Error solutions and fixes
└── setup-aws-ssh.sh        # SSH connectivity setup
```

## 🚀 Quick Start - AWS Deployment

1. **Setup SSH Connectivity**:
   ```bash
   ./setup-aws-ssh.sh
   ```

2. **Deploy to AWS Instances**:
   ```bash
   cd ansible
   ansible-playbook -i inventory/aws-instances playbooks/setup-aws-instances.yml
   ```

3. **Verify Deployment**:
   ```bash
   # Check FIM agent status
   ansible -i inventory/aws-instances all -m shell -a "systemctl status fim-agent"
   
   # Check CMDB data collection
   ansible -i inventory/aws-instances all -m shell -a "ls -la /var/lib/cmdb/data/"
   ```

## 🎓 Learning Objectives

- Deploy Ansible automation across mixed OS environments (Amazon Linux + Ubuntu)
- Implement file integrity monitoring for security compliance
- Build and maintain a configuration management database
- Handle OS-specific differences in package management and services
- Troubleshoot deployment issues in cloud environments

## 📚 Documentation

- **[HOW-TO-USE-THIS-LAB.md](HOW-TO-USE-THIS-LAB.md)** - **Complete user guide with step-by-step instructions**
- **[AWS-DEPLOYMENT-GUIDE.md](AWS-DEPLOYMENT-GUIDE.md)** - Complete deployment instructions
- **[TROUBLESHOOTING-GUIDE.md](TROUBLESHOOTING-GUIDE.md)** - Common errors and solutions
- **[NEXT-STEPS.md](NEXT-STEPS.md)** - Advanced usage and extensions

# Ansible-Baseline-FIM-and-CMDB-Lab-AWS-
