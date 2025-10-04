# Interview Brief: PSEG Configuration Management Specialist

## Role Mapping to PSEG Requirements

### **Monitor runtime environments & detect adverse events**
→ **FIM Implementation** (`fim/agents/fim-agent.py`)
- Real-time file integrity monitoring with SHA-256 hash verification
- Automated change detection across critical system directories (`/etc`, `/usr/bin`, `/usr/sbin`, `/var/log`, `/home`, `/opt`)
- Prometheus metrics integration for event tracking (`fim_events_total`, `fim_files_monitored`)
- Alert generation for unauthorized changes with severity classification
- **Evidence**: `ansible/playbooks/setup-aws-instances.yml` lines 393-408 (FIM agent deployment and testing)

### **Implement configuration change controls**
→ **Ansible Baseline Management** (`ansible/playbooks/setup-baseline.yml`)
- Automated baseline enforcement across mixed OS environments (Amazon Linux + Ubuntu)
- Role-based configuration management with idempotent operations
- Change approval workflow through Ansible check mode and diff validation
- **Evidence**: `ansible/roles/security_hardening/tasks/main.yml` lines 17-23 (SSH configuration with backup and notification)

### **Establish, track, and control baselines**
→ **System Baseline Role** (`ansible/roles/system_baseline/`)
- Comprehensive baseline configuration including users, groups, directories, permissions
- Kernel parameter management and system limits configuration
- Service management (enable/disable) with systemd integration
- **Evidence**: `ansible/roles/system_baseline/tasks/main.yml` lines 36-62 (system limits and kernel parameters)

### **Asset inventory (CMDB)**
→ **CMDB Collector** (`cmdb/scripts/cmdb-collector.py`)
- Automated asset discovery including hardware, software, network, and security information
- JSON-based data storage with structured schema (`cmdb/schemas/cmdb-schema.json`)
- Systemd timer-based collection with hourly automation
- Prometheus metrics for asset tracking (`system_packages_total`, `system_cpu_cores`, `system_users_total`)
- **Evidence**: `ansible/playbooks/setup-aws-instances.yml` lines 272-288 (CMDB service and timer deployment)

### **Collaborate with Cybersecurity**
→ **Security Hardening Role** (`ansible/roles/security_hardening/`)
- SSH hardening with key-based authentication and security policies
- Firewall configuration (UFW/iptables) with intrusion prevention (fail2ban)
- Audit logging (auditd) with comprehensive rule sets
- File integrity monitoring (AIDE) with automated integrity checks
- **Evidence**: `ansible/roles/security_hardening/templates/audit.rules.j2` (audit rules for security events)

### **Quality Control & Assurance**
→ **Testing Framework** (`tests/` directory)
- Static analysis with ansible-lint, yamllint, and flake8
- Functional testing with automated validation scripts
- Integration testing with end-to-end deployment validation
- CI/CD integration with GitHub Actions workflow
- **Evidence**: `tests/run-all-tests.sh` (comprehensive test suite execution)

### **Security policies, alerts, reports, audits**
→ **Security Monitoring and Alerting**
- Real-time security event monitoring with Prometheus metrics
- Automated alert generation for FIM events, authentication failures, and system changes
- Comprehensive audit logging with ausearch integration
- Security compliance reporting with CIS Controls and NIST framework mapping
- **Evidence**: `ansible/roles/security_hardening/templates/security-check.sh.j2` (daily security monitoring script)

### **Tooling Integration**
→ **Production-Grade Monitoring Stack**
- **Ansible**: Primary automation and configuration management tool
- **Prometheus**: Metrics collection and alerting system
- **Grafana**: Visualization and dashboard management
- **Node Exporter**: System metrics collection
- **SSH Tunneling**: Secure cloud monitoring without security group changes
- **Docker**: Container orchestration for monitoring stack
- **Evidence**: `docker-compose.yml` (Prometheus + Grafana stack), `prometheus.yml` (metrics configuration)

## 90-Second Interview Talk Track

"Good morning! I'm excited to discuss how my lab environment directly addresses PSEG's Configuration Management Specialist requirements. 

I've built a production-grade monitoring and configuration management system that demonstrates expertise in exactly what you're looking for. The system implements automated baseline enforcement across mixed AWS environments - Amazon Linux and Ubuntu - using Ansible for infrastructure as code.

The core strength is real-time monitoring and change detection. I've implemented a custom File Integrity Monitoring system that tracks changes to critical system files using SHA-256 hashing, with automated alerting through Prometheus metrics. This directly addresses your need to monitor runtime environments and detect adverse events.

For configuration change controls, everything is automated through Ansible roles with idempotent operations, check mode validation, and comprehensive logging. The system establishes secure baselines including SSH hardening, firewall configuration, and audit logging - all following CIS Controls and NIST frameworks.

The CMDB component provides automated asset discovery, collecting hardware, software, network, and security information with hourly updates. Everything integrates with Prometheus and Grafana for real-time visualization and alerting.

This demonstrates my ability to work with the exact tools PSEG uses - Ansible for automation, Prometheus for monitoring, and enterprise security practices. The system is production-ready with comprehensive testing, CI/CD integration, and security compliance built-in."

## 5 Demo Steps (Exact Commands + Screen Actions)

### **Demo Step 1: Show Live Monitoring Dashboard**
**Command**: `open http://localhost:3000/d/lab-dashboard`
**Screen Action**: Point to real-time CPU, memory, and system metrics from all 3 AWS instances
**Say**: "This shows live monitoring of our AWS infrastructure with real-time metrics collection through Prometheus and Grafana."

### **Demo Step 2: Demonstrate FIM Change Detection**
**Command**: 
```bash
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "echo 'unauthorized change' >> /etc/passwd"
sleep 5
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "tail -n 3 /var/log/fim-agent.log | grep 'FILE_CHANGE'"
```
**Screen Action**: Show the FIM alert in the log output
**Say**: "Watch this - I'm making an unauthorized change to a critical system file, and our FIM system immediately detects and alerts on it."

### **Demo Step 3: Show CMDB Asset Discovery**
**Command**: 
```bash
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "python3 -c \"
import json
with open('/var/lib/cmdb/data/system-info.json', 'r') as f:
    data = json.load(f)
    print(f'Hostname: {data[\"hostname\"]}')
    print(f'OS: {data[\"system_info\"][\"operating_system\"]}')
    print(f'CPU Cores: {data[\"hardware\"][\"cpu_cores\"]}')
    print(f'Packages: {len(data[\"software\"][\"installed_packages\"])}')
    print(f'Services: {len(data[\"software\"][\"running_services\"])}')
\""
```
**Screen Action**: Show the structured asset data output
**Say**: "This demonstrates our CMDB automatically discovering and tracking all system assets - hardware, software, services, and configurations."

### **Demo Step 4: Show Security Compliance Dashboard**
**Command**: `open http://localhost:3000/d/fim-cmdb-dashboard`
**Screen Action**: Point to FIM events, security metrics, and compliance status
**Say**: "This security dashboard shows real-time FIM events, system security status, and compliance metrics - exactly what you need for security monitoring and audit reporting."

### **Demo Step 5: Demonstrate Automated Baseline Enforcement**
**Command**: 
```bash
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "systemctl status ssh | grep 'Active:'"
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml --tags security --check --diff
```
**Screen Action**: Show the dry-run output with security configuration changes
**Say**: "This shows our automated baseline enforcement - we can validate and apply security configurations across all systems with a single command, ensuring consistent compliance."

## Key Technical Achievements

### **Production-Grade Architecture**
- **Mixed OS Support**: Amazon Linux 2023 + Ubuntu 24.04 compatibility
- **SSH Tunneling**: Secure monitoring without opening AWS security groups
- **Prometheus Integration**: Live metrics collection with 200-hour retention
- **Grafana Dashboards**: Real-time visualization with custom node labeling

### **Security Implementation**
- **CIS Controls**: 8 major controls implemented (5.1-5.8)
- **NIST Framework**: All 5 functions (Identify, Protect, Detect, Respond, Recover)
- **ISO 27001**: 10+ controls implemented with audit trails
- **Real-time Monitoring**: FIM, auditd, fail2ban integration

### **Automation Excellence**
- **Idempotent Operations**: All Ansible tasks are idempotent and safe to re-run
- **Error Handling**: Comprehensive error handling with rollback capabilities
- **Testing Framework**: Static analysis, functional testing, and CI/CD integration
- **Documentation**: Complete operational runbooks and troubleshooting guides

### **Enterprise Integration**
- **API Endpoints**: RESTful APIs for FIM and CMDB data access
- **Metrics Export**: Prometheus-compatible metrics for enterprise monitoring
- **Log Aggregation**: Centralized logging with structured JSON output
- **Backup/Recovery**: Automated backup procedures with retention policies

This lab environment demonstrates production-ready configuration management capabilities that directly align with PSEG's requirements for monitoring, automation, security, and compliance in enterprise environments.
