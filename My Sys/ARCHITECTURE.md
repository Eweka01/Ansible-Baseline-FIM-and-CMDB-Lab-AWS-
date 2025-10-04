# System Architecture

## Overview

This lab implements a production-grade configuration management and monitoring system with automated baseline enforcement, file integrity monitoring, and asset tracking across mixed AWS EC2 environments.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           CONTROL NODE (Local Machine)                      │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐  │
│  │   Ansible       │  │   Prometheus    │  │        Grafana              │  │
│  │   Controller    │  │   (Port 9090)   │  │      (Port 3000)            │  │
│  │                 │  │                 │  │                             │  │
│  │ • Playbooks     │  │ • Metrics       │  │ • Dashboards                │  │
│  │ • Roles         │  │ • Alerting      │  │ • Visualization             │  │
│  │ • Inventory     │  │ • Storage       │  │ • Monitoring                │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘  │
│           │                       │                         │               │
│           │                       │                         │               │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐  │
│  │   SSH Tunnels   │  │   Docker        │  │     Lab Dashboard           │  │
│  │   Management    │  │   Compose       │  │   (Port 8080)               │  │
│  │                 │  │                 │  │                             │  │
│  │ • Port 9101-3   │  │ • Container     │  │ • Status Overview           │  │
│  │ • Port 8080-5   │  │   Orchestration │  │ • Health Checks             │  │
│  │ • Auto-reconnect│  │ • Networking    │  │ • Quick Actions             │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ SSH Tunnels
                                    │
┌─────────────────────────────────────────────────────────────────────────────┐
│                           AWS EC2 INSTANCES                                │
│                                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐  │
│  │  manage-node-1  │  │  manage-node-2  │  │      manage-node-3          │  │
│  │ (Amazon Linux)  │  │   (Ubuntu)      │  │       (Ubuntu)              │  │
│  │ 18.234.152.228  │  │ 54.242.234.69   │  │    13.217.82.23             │  │
│  │                 │  │                 │  │                             │  │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────────────────┐ │  │
│  │ │Node Exporter│ │  │ │Node Exporter│ │  │ │    Node Exporter        │ │  │
│  │ │  :9100      │ │  │ │  :9100      │ │  │ │      :9100              │ │  │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────────────────┘ │  │
│  │                 │  │                 │  │                             │  │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────────────────┐ │  │
│  │ │FIM Agent    │ │  │ │FIM Agent    │ │  │ │    FIM Agent            │ │  │
│  │ │  :8080      │ │  │ │  :8082      │ │  │ │      :8084              │ │  │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────────────────┘ │  │
│  │                 │  │                 │  │                             │  │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────────────────┐ │  │
│  │ │CMDB Collector│ │  │ │CMDB Collector│ │  │ │   CMDB Collector        │ │  │
│  │ │  :8081      │ │  │ │  :8083      │ │  │ │      :8085              │ │  │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────────────────┘ │  │
│  │                 │  │                 │  │                             │  │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────────────────┐ │  │
│  │ │Security     │ │  │ │Security     │ │  │ │    Security             │ │  │
│  │ │Hardening    │ │  │ │Hardening    │ │  │ │    Hardening            │ │  │
│  │ │• SSH Config │ │  │ │• SSH Config │ │  │ │• SSH Config             │ │  │
│  │ │• Firewall   │ │  │ │• Firewall   │ │  │ │• Firewall               │ │  │
│  │ │• Fail2ban   │ │  │ │• Fail2ban   │ │  │ │• Fail2ban               │ │  │
│  │ │• Auditd     │ │  │ │• Auditd     │ │  │ │• Auditd                 │ │  │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────────────────┘ │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Data Flow Architecture

### 1. Configuration Management Flow
```
Ansible Controller → AWS Instances → Baseline Configuration → Compliance Verification
     │                    │                    │                        │
     │                    │                    │                        │
     ▼                    ▼                    ▼                        ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ Playbooks   │    │ SSH         │    │ System      │    │ Audit       │
│ & Roles     │───▶│ Connection  │───▶│ Hardening   │───▶│ Logs        │
│             │    │             │    │             │    │             │
│ • Security  │    │ • Key-based │    │ • SSH       │    │ • Compliance│
│ • Baseline  │    │ • Port 22   │    │ • Firewall  │    │ • Reports   │
│ • Packages  │    │ • Timeout   │    │ • Services  │    │ • Alerts    │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

### 2. File Integrity Monitoring Flow
```
File System Changes → FIM Agent → Hash Comparison → Alert Generation → Prometheus
        │                │              │                │              │
        │                │              │                │              │
        ▼                ▼              ▼                ▼              ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ Monitored   │    │ Real-time   │    │ SHA-256     │    │ Security    │    │ Metrics     │
│ Paths       │───▶│ Watchdog    │───▶│ Hash Check  │───▶│ Alerts      │───▶│ Collection  │
│             │    │ Observer    │    │             │    │             │    │             │
│ • /etc      │    │ • Events    │    │ • Baseline  │    │ • Logs      │    │ • Events    │
│ • /usr/bin  │    │ • Filtering │    │ • Current   │    │ • Notify    │    │ • Rates     │
│ • /var/log  │    │ • Queuing   │    │ • Compare   │    │ • Escalate  │    │ • Counters  │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

### 3. CMDB Data Collection Flow
```
System Discovery → CMDB Collector → Data Processing → Storage → Prometheus Metrics
       │                │                │              │              │
       │                │                │              │              │
       ▼                ▼                ▼              ▼              ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ System      │    │ Scheduled   │    │ Data        │    │ JSON        │    │ Asset       │
│ Components  │───▶│ Collection  │───▶│ Validation  │───▶│ Storage     │───▶│ Metrics     │
│             │    │             │    │             │    │             │    │             │
│ • Hardware  │    │ • Timer     │    │ • Schema    │    │ • Files     │    │ • Counts    │
│ • Software  │    │ • Service   │    │ • Types     │    │ • Database  │    │ • Changes   │
│ • Network   │    │ • Cron      │    │ • Format    │    │ • Backup    │    │ • Status    │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

### 4. Monitoring and Alerting Flow
```
AWS Instances → SSH Tunnels → Prometheus → Grafana → Alerting → Notification
      │              │             │           │          │           │
      │              │             │           │          │           │
      ▼              ▼             ▼           ▼          ▼           ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│ Node        │ │ Port        │ │ Metrics     │ │ Dashboard   │ │ Alert       │ │ Incident    │
│ Exporters   │ │ Forwarding  │ │ Scraping    │ │ Visualization│ │ Rules       │ │ Response    │
│             │ │             │ │             │ │             │ │             │ │             │
│ • CPU       │ │ • 9101-3    │ │ • 15s       │ │ • Real-time │ │ • Threshold │ │ • Logs      │
│ • Memory    │ │ • 8080-5    │ │ • Storage   │ │ • Historical│ │ • Duration  │ │ • Escalate  │
│ • Disk      │ │ • Auto-recon│ │ • Retention │ │ • Alerts    │ │ • Severity  │ │ • Remediate │
└─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘
```

## Component Dependencies

### Ansible Roles Dependency Graph
```
setup-aws-instances.yml
├── system_baseline (roles/system_baseline/)
│   ├── package_management (roles/package_management/)
│   ├── network_config (roles/network_config/)
│   └── logging_setup (roles/logging_setup/)
├── security_hardening (roles/security_hardening/)
│   ├── SSH configuration
│   ├── Firewall setup
│   ├── Fail2ban configuration
│   └── Auditd setup
└── monitoring_setup (roles/monitoring_setup/)
    ├── Node Exporter installation
    ├── FIM agent deployment
    └── CMDB collector setup
```

### Service Dependencies
```
systemd services
├── node_exporter.service
│   └── Depends on: network-online.target
├── fim-agent.service
│   └── Depends on: /opt/lab-env/bin/python
└── cmdb-collector.timer
    └── Triggers: cmdb-collector.service
```

## Configuration Model

### Variable Hierarchy
```
group_vars/all.yml (Global defaults)
├── system.* (System configuration)
├── security.* (Security settings)
├── network.* (Network configuration)
├── logging.* (Logging settings)
├── monitoring.* (Monitoring configuration)
├── fim.* (FIM settings)
└── cmdb.* (CMDB configuration)

inventory/aws-instances (Host-specific overrides)
├── [webservers:vars] (manage-node-1 specific)
├── [databases:vars] (manage-node-2 specific)
└── [monitoring:vars] (manage-node-3 specific)
```

### Template System
```
ansible/playbooks/templates/
├── fim-config-aws.j2 → /etc/fim/fim-config.json
├── fim-agent.service.j2 → /etc/systemd/system/fim-agent.service
├── cmdb-collector.service.j2 → /etc/systemd/system/cmdb-collector.service
├── cmdb-collector.timer.j2 → /etc/systemd/system/cmdb-collector.timer
├── fail2ban-aws.j2 → /etc/fail2ban/jail.local
└── system-info-aws.j2 → /etc/system-info
```

## Security Architecture

### Network Security
- **SSH Key-based Authentication**: No password authentication
- **Firewall Configuration**: UFW (Ubuntu) / iptables (Amazon Linux)
- **SSH Tunneling**: Secure monitoring without opening AWS security groups
- **Fail2ban**: Intrusion prevention and detection

### Data Security
- **File Integrity Monitoring**: SHA-256 hash-based verification
- **Audit Logging**: Comprehensive system audit trails
- **Secure File Permissions**: Enforced via Ansible tasks
- **Encrypted Communications**: SSH tunnels for all remote access

### Access Control
- **Principle of Least Privilege**: Minimal required permissions
- **Service Isolation**: Dedicated users for monitoring services
- **Configuration Management**: Version-controlled and auditable changes

## Scalability Considerations

### Horizontal Scaling
- **Inventory Management**: Easy addition of new AWS instances
- **Role-based Deployment**: Consistent configuration across environments
- **SSH Tunnel Management**: Automated tunnel setup for new instances

### Vertical Scaling
- **Resource Monitoring**: CPU, memory, disk usage tracking
- **Performance Metrics**: Prometheus-based performance monitoring
- **Alerting**: Automated scaling recommendations

### Data Retention
- **Prometheus**: 200-hour retention (configurable)
- **Log Files**: 30-day rotation with compression
- **CMDB Data**: JSON-based storage with backup capabilities
- **FIM Baselines**: Version-controlled integrity databases

## Integration Points

### External Systems
- **AWS EC2**: Instance management and metadata collection
- **Prometheus**: Metrics collection and alerting
- **Grafana**: Visualization and dashboard management
- **Docker**: Container orchestration for monitoring stack

### API Endpoints
- **FIM Agent**: HTTP metrics endpoint on ports 8080, 8082, 8084
- **CMDB Collector**: HTTP metrics endpoint on ports 8081, 8083, 8085
- **Node Exporter**: Prometheus metrics on port 9100
- **Grafana**: Web interface on port 3000
- **Prometheus**: Web interface on port 9090

This architecture provides a robust, scalable, and secure foundation for enterprise configuration management and monitoring operations.
