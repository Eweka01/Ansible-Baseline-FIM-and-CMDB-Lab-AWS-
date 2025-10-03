# Ansible Baseline, FIM, and CMDB Lab

This lab provides a comprehensive environment for learning and practicing:
- **Ansible Baseline**: Automated system configuration and compliance
- **File Integrity Monitoring (FIM)**: Real-time file change detection and alerting
- **Configuration Management Database (CMDB)**: Asset and configuration tracking

## Lab Structure

```
├── ansible/                 # Ansible configuration and playbooks
│   ├── playbooks/          # Main playbooks for system configuration
│   ├── roles/              # Reusable Ansible roles
│   ├── inventory/          # Host inventory files
│   └── group_vars/         # Group-specific variables
├── fim/                    # File Integrity Monitoring
│   ├── agents/             # FIM agent configurations
│   ├── rules/              # Monitoring rules and policies
│   └── reports/            # Generated reports and logs
├── cmdb/                   # Configuration Management Database
│   ├── data/               # CMDB data files
│   ├── schemas/            # Data schemas and templates
│   └── scripts/            # Data collection and management scripts
├── monitoring/             # Monitoring and alerting
│   ├── dashboards/         # Monitoring dashboards
│   └── alerts/             # Alert configurations
├── tests/                  # Test scenarios and validation
└── docs/                   # Additional documentation
```

## Prerequisites

- Ansible 2.9+
- Python 3.7+
- Docker (optional, for containerized services)
- Linux/Unix environment

## Quick Start

1. **Setup Ansible Environment**:
   ```bash
   cd ansible
   ansible-playbook -i inventory/hosts playbooks/setup-baseline.yml
   ```

2. **Deploy FIM Agents**:
   ```bash
   cd fim
   ./deploy-agents.sh
   ```

3. **Initialize CMDB**:
   ```bash
   cd cmdb
   python3 scripts/init-cmdb.py
   ```

## Learning Objectives

- Understand Ansible automation for system baseline configuration
- Implement file integrity monitoring for security compliance
- Build and maintain a configuration management database
- Integrate all components for comprehensive infrastructure management

## Lab Scenarios

See the `tests/` directory for various lab scenarios and exercises.

# Ansible-Baseline-FIM-and-CMDB-Lab-AWS-
