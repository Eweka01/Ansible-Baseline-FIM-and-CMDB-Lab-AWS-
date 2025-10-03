# Setup Directory

This directory contains all setup scripts, documentation, and guides for the Ansible Baseline, FIM, and CMDB lab.

## 📁 Directory Structure

```
setup/
├── scripts/              # Setup and deployment scripts
│   ├── setup-aws-ssh.sh  # SSH connectivity setup for AWS instances
│   └── setup-lab.sh      # Complete lab setup script
├── guides/               # Comprehensive guides and documentation
│   ├── AWS-DEPLOYMENT-GUIDE.md    # Step-by-step AWS deployment guide
│   ├── HOW-TO-USE-THIS-LAB.md     # Complete user guide
│   ├── TROUBLESHOOTING-GUIDE.md   # Error solutions and fixes
│   └── NEXT-STEPS.md              # Advanced usage and extensions
└── docs/                 # Additional documentation
    ├── installation-guide.md      # Installation instructions
    └── user-guide.md              # User manual
```

## 🚀 Quick Start

### 1. AWS Deployment Setup
```bash
# Setup SSH connectivity to AWS instances
./setup/scripts/setup-aws-ssh.sh

# Deploy the complete lab
cd ansible
ansible-playbook -i inventory/aws-instances playbooks/setup-aws-instances.yml
```

### 2. Local Lab Setup
```bash
# Run complete lab setup
./setup/scripts/setup-lab.sh
```

## 📚 Documentation Overview

### **Setup Scripts**

#### `setup-aws-ssh.sh`
- **Purpose**: Sets up SSH connectivity to AWS EC2 instances
- **Features**: 
  - Tests SSH connections to all 3 instances
  - Creates SSH config file for easy access
  - Verifies SSH key permissions
  - Handles mixed OS environments (Amazon Linux + Ubuntu)

#### `setup-lab.sh`
- **Purpose**: Complete lab setup and configuration
- **Features**:
  - Sets up Python virtual environment
  - Installs all dependencies
  - Configures lab components
  - Runs initial tests

### **Comprehensive Guides**

#### `AWS-DEPLOYMENT-GUIDE.md`
- **Purpose**: Complete AWS deployment instructions
- **Contents**:
  - Prerequisites and setup
  - Step-by-step deployment process
  - Verification and testing
  - Troubleshooting common issues

#### `HOW-TO-USE-THIS-LAB.md`
- **Purpose**: Complete user guide for lab usage
- **Contents**:
  - Initial setup instructions
  - Component usage examples
  - Hands-on exercises
  - Advanced usage scenarios

#### `TROUBLESHOOTING-GUIDE.md`
- **Purpose**: Error solutions and fixes
- **Contents**:
  - Common errors and solutions
  - Debugging techniques
  - Performance optimization
  - Recovery procedures

#### `NEXT-STEPS.md`
- **Purpose**: Advanced usage and extensions
- **Contents**:
  - Advanced features
  - Customization options
  - Integration possibilities
  - Learning objectives

### **Additional Documentation**

#### `docs/installation-guide.md`
- **Purpose**: Detailed installation instructions
- **Contents**:
  - System requirements
  - Dependency installation
  - Configuration steps
  - Validation procedures

#### `docs/user-guide.md`
- **Purpose**: User manual for lab components
- **Contents**:
  - Component overview
  - Usage instructions
  - Configuration options
  - Best practices

## 🔧 Setup Scripts Usage

### SSH Setup Script
```bash
# Basic usage
./setup/scripts/setup-aws-ssh.sh

# The script will:
# 1. Check for SSH key in common locations
# 2. Set correct permissions on SSH key
# 3. Test connections to all AWS instances
# 4. Create SSH config file
# 5. Verify connectivity
```

### Lab Setup Script
```bash
# Basic usage
./setup/scripts/setup-lab.sh

# The script will:
# 1. Create Python virtual environment
# 2. Install all dependencies
# 3. Configure lab components
# 4. Run initial tests
# 5. Generate setup report
```

## 📖 Guide Usage

### AWS Deployment
1. **Read**: `setup/guides/AWS-DEPLOYMENT-GUIDE.md`
2. **Follow**: Step-by-step instructions
3. **Verify**: Deployment success
4. **Test**: Lab functionality

### Lab Usage
1. **Read**: `setup/guides/HOW-TO-USE-THIS-LAB.md`
2. **Practice**: Hands-on exercises
3. **Explore**: Advanced features
4. **Learn**: DevOps and security concepts

### Troubleshooting
1. **Identify**: Error or issue
2. **Check**: `setup/guides/TROUBLESHOOTING-GUIDE.md`
3. **Apply**: Recommended solution
4. **Verify**: Issue resolution

## 🎯 Setup Prerequisites

### For AWS Deployment
- ✅ AWS EC2 instances running
- ✅ SSH key file (`key-p3.pem`)
- ✅ Ansible installed locally
- ✅ Python 3.7+ installed
- ✅ Internet connectivity

### For Local Setup
- ✅ Python 3.7+ installed
- ✅ pip package manager
- ✅ Git installed
- ✅ Terminal/command line access

## 🔍 Verification Steps

### After SSH Setup
```bash
# Test SSH connections
ssh manage-node-1 "echo 'Connection successful'"
ssh manage-node-2 "echo 'Connection successful'"
ssh manage-node-3 "echo 'Connection successful'"
```

### After Lab Setup
```bash
# Test lab components
python3 tests/scripts/test-fim.py
python3 tests/scripts/test-cmdb.py
./tests/scripts/run-lab-tests.sh
```

## 🚨 Common Issues

### SSH Connection Issues
- **Problem**: Cannot connect to AWS instances
- **Solution**: Check security groups, key permissions, instance status
- **Guide**: See `setup/guides/TROUBLESHOOTING-GUIDE.md`

### Setup Script Issues
- **Problem**: Setup script fails
- **Solution**: Check dependencies, permissions, network connectivity
- **Guide**: See `setup/guides/TROUBLESHOOTING-GUIDE.md`

### Lab Component Issues
- **Problem**: Lab components not working
- **Solution**: Check service status, logs, configuration
- **Guide**: See `setup/guides/HOW-TO-USE-THIS-LAB.md`

## 📊 Setup Validation

### Health Checks
```bash
# Check all services
ansible -i ansible/inventory/aws-instances all -m shell -a "systemctl status fim-agent cmdb-collector.timer"

# Check lab functionality
./tests/scripts/run-lab-tests.sh

# Check logs
tail -f logs/fim/fim-agent.log
tail -f logs/cmdb/cmdb-test.log
```

### Performance Checks
```bash
# Check system resources
ansible -i ansible/inventory/aws-instances all -m shell -a "free -h && df -h"

# Check service performance
ansible -i ansible/inventory/aws-instances all -m shell -a "systemctl status fim-agent --no-pager"
```

## 🔄 Maintenance

### Regular Updates
```bash
# Update lab components
cd ansible
ansible-playbook -i inventory/aws-instances playbooks/setup-aws-instances.yml

# Update documentation
git pull origin main
```

### Backup and Recovery
```bash
# Backup lab configuration
tar -czf lab-backup-$(date +%Y%m%d).tar.gz setup/ ansible/ fim/ cmdb/

# Restore from backup
tar -xzf lab-backup-YYYYMMDD.tar.gz
```

## 📚 Learning Path

### Beginner
1. **Start**: `setup/guides/AWS-DEPLOYMENT-GUIDE.md`
2. **Learn**: `setup/guides/HOW-TO-USE-THIS-LAB.md`
3. **Practice**: Hands-on exercises
4. **Explore**: Basic features

### Intermediate
1. **Review**: `setup/guides/NEXT-STEPS.md`
2. **Customize**: Lab configurations
3. **Integrate**: Additional components
4. **Optimize**: Performance settings

### Advanced
1. **Extend**: Lab functionality
2. **Integrate**: External systems
3. **Scale**: To more instances
4. **Automate**: Advanced workflows

## 🆘 Support

### Getting Help
1. **Check**: `setup/guides/TROUBLESHOOTING-GUIDE.md`
2. **Review**: Error logs in `logs/` directory
3. **Search**: GitHub issues and documentation
4. **Ask**: Community for assistance

### Reporting Issues
1. **Document**: Error details and steps to reproduce
2. **Include**: Relevant logs and configuration
3. **Check**: Existing issues and solutions
4. **Submit**: Detailed issue report

---

## 🎉 Success!

Once setup is complete, you'll have:
- ✅ **Fully functional lab** on AWS instances
- ✅ **Comprehensive documentation** for all components
- ✅ **Working FIM and CMDB** systems
- ✅ **Security hardening** applied
- ✅ **Ready for learning** and experimentation

**Happy Learning! 🚀✨**
