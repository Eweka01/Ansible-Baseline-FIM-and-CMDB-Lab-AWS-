# Ansible Playbooks Reference

## Overview

This document provides comprehensive documentation for all Ansible playbooks, roles, and tasks in the lab environment. Each component is documented with its purpose, variables, handlers, and example invocations.

## Main Playbooks

### setup-aws-instances.yml
**File**: `ansible/playbooks/setup-aws-instances.yml`

#### Purpose
Deploys the complete production monitoring lab environment to AWS EC2 instances, handling mixed OS environments (Amazon Linux + Ubuntu) and deploying FIM agents, CMDB collectors, Node Exporter, and security hardening.

#### Key Features
- Cross-platform package management (apt/yum)
- Python virtual environment setup
- Node Exporter installation and configuration
- FIM agent deployment with systemd service
- CMDB collector deployment with timer-based collection
- Security hardening (firewall, fail2ban, SSH)
- Service validation and testing

#### Variables
```yaml
# Global variables from group_vars/all.yml
environment: "{{ environment | default('production') }}"
enable_firewall: "{{ enable_firewall | default(true) }}"
service_type: "{{ service_type | default('') }}"

# Playbook-specific variables
playbook_start_time: "{{ ansible_date_time.iso8601 }}"
```

#### Tags
- No specific tags (runs all tasks)
- Can be run with `--tags` for specific components

#### Handlers
```yaml
handlers:
  - name: restart fim-agent
    systemd:
      name: fim-agent
      state: restarted
  
  - name: restart fail2ban
    systemd:
      name: fail2ban
      state: restarted
  
  - name: restart iptables
    systemd:
      name: iptables
      state: restarted
  
  - name: reload systemd
    systemd:
      daemon_reload: yes
```

#### Example Invocations
```bash
# Deploy to all instances
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml

# Deploy to specific group
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml --limit webservers

# Deploy to single instance
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml --limit manage-node-1

# Dry run with diff
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml --check --diff
```

#### Important Tasks
```yaml
# Package installation with OS detection
- name: "Install essential packages (Ubuntu/Debian)"
  apt:
    name:
      - python3
      - python3-pip
      - python3-venv
      - curl
      - wget
      - vim
      - htop
      - tree
      - unzip
      - git
      - iotop
      - sysstat
      - fail2ban
      - ufw
      - auditd
      - aide
      - rkhunter
      - chkrootkit
    state: present
    update_cache: yes
  when: ansible_os_family == "Debian"

# Node Exporter installation
- name: "Download Node Exporter (Amazon Linux)"
  get_url:
    url: "https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz"
    dest: "/tmp/node_exporter-1.7.0.linux-amd64.tar.gz"
    mode: '0644'
  when: ansible_distribution == "Amazon"

# FIM agent deployment
- name: "Copy lab files to instances"
  copy:
    src: "{{ item.src }}"
    dest: "{{ item.dest }}"
    mode: "{{ item.mode | default('0644') }}"
    owner: root
    group: root
  loop:
    - { src: "../../fim/agents/fim-agent.py", dest: "/opt/lab-environment/fim-agent.py", mode: "0755" }
    - { src: "../../fim/agents/fim-config.json", dest: "/etc/fim/fim-config.json" }
    - { src: "../../cmdb/scripts/cmdb-collector.py", dest: "/opt/lab-environment/cmdb-collector.py", mode: "0755" }
```

### setup-baseline.yml
**File**: `ansible/playbooks/setup-baseline.yml`

#### Purpose
Establishes a secure baseline configuration for all lab hosts using modular Ansible roles for system configuration, security hardening, package management, and monitoring setup.

#### Key Features
- Modular role-based architecture
- Cross-platform compatibility
- Security hardening implementation
- Package management and updates
- Network configuration
- Logging and monitoring setup
- Backup configuration (optional)

#### Variables
```yaml
# Playbook variables
playbook_start_time: "{{ ansible_date_time.iso8601 }}"
environment: "{{ environment | default('development') }}"

# Role-specific variables from group_vars/all.yml
system:
  timezone: "{{ timezone | default('UTC') }}"
  locale: "en_US.UTF-8"
  hostname_prefix: "lab-"

security:
  firewall:
    enabled: "{{ enable_firewall | default(true) }}"
    default_policy: deny
    allow_ssh: true
    ssh_port: 22

monitoring:
  enabled: "{{ monitoring_enabled | default(true) }}"
  metrics_retention: 30d
  alerting_enabled: "{{ alerting_enabled | default(false) }}"
```

#### Tags
```yaml
# Available tags
- baseline: All baseline configuration tasks
- system: System-level configuration (users, directories, permissions)
- security: Security hardening measures
- packages: Package management and installation
- network: Network configuration and connectivity
- logging: Logging setup and configuration
- monitoring: Monitoring and alerting setup
- backup: Backup configuration and procedures
```

#### Example Invocations
```bash
# Run all baseline tasks
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-baseline.yml

# Run only security hardening
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-baseline.yml --tags security

# Skip backup tasks
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-baseline.yml --skip-tags backup

# Run with specific environment
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-baseline.yml -e "environment=production"
```

#### Role Dependencies
```yaml
roles:
  - role: system_baseline
    tags: [baseline, system]
  
  - role: security_hardening
    tags: [baseline, security]
  
  - role: package_management
    tags: [baseline, packages]
  
  - role: network_config
    tags: [baseline, network]
  
  - role: logging_setup
    tags: [baseline, logging]
  
  - role: monitoring_setup
    tags: [baseline, monitoring]
    when: monitoring.enabled | default(true)
  
  - role: backup_setup
    tags: [baseline, backup]
    when: backup.enabled | default(false)
```

### deploy-prometheus-agents.yml
**File**: `ansible/playbooks/deploy-prometheus-agents.yml`

#### Purpose
Deploys Prometheus-compatible agents and exporters to AWS instances for metrics collection and monitoring integration.

#### Key Features
- Node Exporter deployment
- FIM agent with Prometheus metrics
- CMDB collector with Prometheus metrics
- Service configuration and startup
- Metrics endpoint validation

#### Example Invocations
```bash
# Deploy Prometheus agents
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/deploy-prometheus-agents.yml

# Deploy to specific group
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/deploy-prometheus-agents.yml --limit monitoring
```

### install-node-exporter.yml
**File**: `ansible/playbooks/install-node-exporter.yml`

#### Purpose
Installs and configures Node Exporter for Prometheus metrics collection on AWS instances.

#### Key Features
- Node Exporter binary download and installation
- Systemd service configuration
- User and group creation
- Service startup and validation

#### Example Invocations
```bash
# Install Node Exporter
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/install-node-exporter.yml

# Install on specific instance
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/install-node-exporter.yml --limit manage-node-1
```

## Ansible Roles

### system_baseline
**Directory**: `ansible/roles/system_baseline/`

#### Purpose
Establishes fundamental system configuration including users, directories, permissions, and basic system settings.

#### Main Tasks
**File**: `ansible/roles/system_baseline/tasks/main.yml`

```yaml
# Package cache update
- name: "Update package cache"
  package:
    update_cache: yes
  when: ansible_os_family == "Debian"

# Essential package installation
- name: "Install essential packages"
  package:
    name: "{{ system_packages.essential }}"
    state: present

# System timezone configuration
- name: "Set system timezone"
  timezone:
    name: "{{ system.timezone }}"

# System locale configuration
- name: "Configure system locale"
  locale_gen:
    name: "{{ system.locale }}"
    state: present
  when: ansible_os_family == "Debian"

# System limits configuration
- name: "Configure system limits"
  pam_limits:
    domain: "*"
    limit_type: "{{ item.type }}"
    limit_item: "{{ item.item }}"
    value: "{{ item.value }}"
  loop:
    - { type: "soft", item: "nofile", value: "{{ system_limits.max_open_files }}" }
    - { type: "hard", item: "nofile", value: "{{ system_limits.max_open_files }}" }
    - { type: "soft", item: "nproc", value: "{{ system_limits.max_processes }}" }
    - { type: "hard", item: "nproc", value: "{{ system_limits.max_processes }}" }

# Kernel parameters configuration
- name: "Configure kernel parameters"
  sysctl:
    name: "{{ item.name }}"
    value: "{{ item.value }}"
    state: present
    reload: yes
  loop: "{{ kernel_parameters }}"

# Service management
- name: "Enable system services"
  systemd:
    name: "{{ item }}"
    enabled: yes
    state: started
  loop: "{{ system_services }}"

- name: "Disable unnecessary services"
  systemd:
    name: "{{ item }}"
    enabled: no
    state: stopped
  loop: "{{ system_services_disabled }}"
  ignore_errors: yes

# User management
- name: "Create lab user"
  user:
    name: "{{ item.name }}"
    groups: "{{ item.groups | join(',') }}"
    shell: "{{ item.shell }}"
    state: present
    create_home: yes
  loop: "{{ security.users }}"
  when: security.users is defined

# Sudo configuration
- name: "Configure sudo for lab user"
  lineinfile:
    path: /etc/sudoers.d/lab-users
    line: "{{ item.name }} ALL=(ALL) NOPASSWD:ALL"
    create: yes
    mode: '0440'
    validate: 'visudo -cf %s'
  loop: "{{ security.users }}"
  when: security.users is defined
```

#### Default Variables
**File**: `ansible/roles/system_baseline/defaults/main.yml`

```yaml
system_packages:
  essential:
    - curl
    - wget
    - vim
    - htop
    - tree
    - unzip
    - git
    - python3-pip
    - python3-venv

system_services:
  - ssh
  - cron
  - rsyslog

system_services_disabled:
  - bluetooth
  - cups
  - avahi-daemon

system_limits:
  max_open_files: 65536
  max_processes: 32768

kernel_parameters:
  - { name: "net.ipv4.ip_forward", value: "0" }
  - { name: "net.ipv4.conf.all.send_redirects", value: "0" }
  - { name: "net.ipv4.conf.default.send_redirects", value: "0" }
  - { name: "net.ipv4.conf.all.accept_redirects", value: "0" }
  - { name: "net.ipv4.conf.default.accept_redirects", value: "0" }
```

#### Handlers
**File**: `ansible/roles/system_baseline/handlers/main.yml`

```yaml
- name: restart services
  systemd:
    name: "{{ item }}"
    state: restarted
  loop: "{{ system_services }}"
```

#### Templates
**File**: `ansible/roles/system_baseline/templates/system-info.j2`

```bash
# System Information
Hostname: {{ ansible_hostname }}
FQDN: {{ ansible_fqdn }}
OS: {{ ansible_distribution }} {{ ansible_distribution_version }}
Kernel: {{ ansible_kernel }}
Architecture: {{ ansible_architecture }}
CPU Cores: {{ ansible_processor_vcpus }}
Memory: {{ ansible_memtotal_mb }} MB
Disk: {{ ansible_devices.sda.size if ansible_devices.sda is defined else 'Unknown' }}
Network: {{ ansible_default_ipv4.address if ansible_default_ipv4 is defined else 'Unknown' }}
Uptime: {{ ansible_uptime_seconds | int // 3600 }} hours
```

### security_hardening
**Directory**: `ansible/roles/security_hardening/`

#### Purpose
Implements comprehensive security hardening measures including SSH configuration, firewall setup, intrusion prevention, and audit logging.

#### Main Tasks
**File**: `ansible/roles/security_hardening/tasks/main.yml`

```yaml
# Security package installation
- name: "Install security packages"
  package:
    name: "{{ item }}"
    state: present
  loop:
    - fail2ban
    - ufw
    - aide
    - rkhunter
    - chkrootkit
    - auditd
    - auditd-plugins

# SSH security configuration
- name: "Configure SSH security settings"
  template:
    src: sshd_config.j2
    dest: /etc/ssh/sshd_config
    backup: yes
    mode: '0600'
  notify: restart ssh

# Fail2ban configuration
- name: "Configure fail2ban"
  template:
    src: fail2ban.j2
    dest: /etc/fail2ban/jail.local
    mode: '0644'
  notify: restart fail2ban

# UFW firewall configuration
- name: "Configure UFW firewall"
  ufw:
    state: enabled
    policy: deny
    direction: incoming
  when: security.firewall.enabled | default(true)

- name: "Allow SSH through firewall"
  ufw:
    rule: allow
    port: "{{ security.firewall.ssh_port | default(22) }}"
    proto: tcp
  when: security.firewall.allow_ssh | default(true)

# Auditd configuration
- name: "Configure auditd"
  template:
    src: auditd.conf.j2
    dest: /etc/audit/auditd.conf
    backup: yes
    mode: '0640'
  notify: restart auditd

- name: "Configure audit rules"
  template:
    src: audit.rules.j2
    dest: /etc/audit/rules.d/audit.rules
    mode: '0640'
  notify: restart auditd

# AIDE integrity monitoring
- name: "Initialize AIDE database"
  command: aide --init
  args:
    creates: /var/lib/aide/aide.db.new.gz

- name: "Move AIDE database to production"
  command: mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz

- name: "Configure AIDE cron job"
  cron:
    name: "AIDE integrity check"
    minute: "0"
    hour: "2"
    job: "/usr/bin/aide --check"
    user: root

# File permissions
- name: "Set secure file permissions"
  file:
    path: "{{ item.path }}"
    mode: "{{ item.mode }}"
    owner: "{{ item.owner | default('root') }}"
    group: "{{ item.group | default('root') }}"
  loop:
    - { path: "/etc/passwd", mode: "0644" }
    - { path: "/etc/shadow", mode: "0600" }
    - { path: "/etc/group", mode: "0644" }
    - { path: "/etc/gshadow", mode: "0600" }
    - { path: "/etc/ssh/sshd_config", mode: "0600" }
    - { path: "/etc/audit/auditd.conf", mode: "0640" }

# Password policy
- name: "Configure password policy"
  template:
    src: common-password.j2
    dest: /etc/pam.d/common-password
    backup: yes
    mode: '0644'
  when: ansible_os_family == "Debian"

# Security monitoring script
- name: "Set up security monitoring script"
  template:
    src: security-check.sh.j2
    dest: /usr/local/bin/security-check.sh
    mode: '0755'

- name: "Create security check cron job"
  cron:
    name: "Daily security check"
    minute: "30"
    hour: "1"
    job: "/usr/local/bin/security-check.sh"
    user: root
```

#### Templates

##### SSH Configuration
**File**: `ansible/roles/security_hardening/templates/sshd_config.j2`

```bash
# SSH Configuration
Port 22
Protocol 2
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
X11Forwarding no
AllowUsers {{ ansible_user }}
```

##### Fail2ban Configuration
**File**: `ansible/roles/security_hardening/templates/fail2ban.j2`

```ini
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
```

##### Audit Rules
**File**: `ansible/roles/security_hardening/templates/audit.rules.j2`

```bash
# Audit Rules
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/sudoers -p wa -k identity
-w /etc/ssh/sshd_config -p wa -k sshd_config
-w /var/log/auth.log -p wa -k auth_log
-w /var/log/audit/audit.log -p wa -k audit_log
```

### package_management
**Directory**: `ansible/roles/package_management/`

#### Purpose
Manages package installation, updates, and removal across different operating systems with proper dependency handling.

#### Main Tasks
**File**: `ansible/roles/package_management/tasks/main.yml`

```yaml
# Package cache update
- name: "Update package cache (Ubuntu/Debian)"
  apt:
    update_cache: yes
    cache_valid_time: 3600
  when: ansible_os_family == "Debian"

- name: "Update package cache (RedHat)"
  yum:
    update_cache: yes
  when: ansible_os_family == "RedHat"

# Essential packages
- name: "Install essential packages"
  package:
    name: "{{ packages.essential }}"
    state: present

# Security packages
- name: "Install security packages"
  package:
    name: "{{ packages.security }}"
    state: present

# Monitoring packages
- name: "Install monitoring packages"
  package:
    name: "{{ packages.monitoring }}"
    state: present

# Remove unnecessary packages
- name: "Remove unnecessary packages"
  package:
    name: "{{ packages.remove }}"
    state: absent
  when: packages.remove is defined
```

### network_config
**Directory**: `ansible/roles/network_config/`

#### Purpose
Configures network settings including DNS servers, NTP servers, and network interfaces.

#### Main Tasks
**File**: `ansible/roles/network_config/tasks/main.yml`

```yaml
# DNS configuration
- name: "Configure DNS servers"
  lineinfile:
    path: /etc/resolv.conf
    line: "nameserver {{ item }}"
    create: yes
  loop: "{{ network.dns_servers }}"

# NTP configuration
- name: "Install NTP"
  package:
    name: "{{ item }}"
    state: present
  loop:
    - ntp
    - ntpdate
  when: ansible_os_family == "Debian"

- name: "Configure NTP servers"
  lineinfile:
    path: /etc/ntp.conf
    line: "server {{ item }}"
    create: yes
  loop: "{{ network.ntp_servers }}"

- name: "Start and enable NTP"
  systemd:
    name: ntp
    enabled: yes
    state: started
```

### logging_setup
**Directory**: `ansible/roles/logging_setup/`

#### Purpose
Configures centralized logging, log rotation, and log management across the lab environment.

#### Main Tasks
**File**: `ansible/roles/logging_setup/tasks/main.yml`

```yaml
# Rsyslog configuration
- name: "Configure rsyslog"
  template:
    src: rsyslog.conf.j2
    dest: /etc/rsyslog.conf
    backup: yes
  notify: restart rsyslog

# Log rotation configuration
- name: "Configure log rotation"
  template:
    src: logrotate.conf.j2
    dest: /etc/logrotate.d/lab-logs
    mode: '0644'

# Log directory creation
- name: "Create log directories"
  file:
    path: "{{ item }}"
    state: directory
    mode: '0755'
    owner: root
    group: root
  loop:
    - /var/log/lab
    - /var/log/ansible
    - /var/log/security
```

### monitoring_setup
**Directory**: `ansible/roles/monitoring_setup/`

#### Purpose
Sets up monitoring components including metrics collection, alerting, and monitoring agents.

#### Main Tasks
**File**: `ansible/roles/monitoring_setup/tasks/main.yml`

```yaml
# Monitoring packages
- name: "Install monitoring packages"
  package:
    name: "{{ packages.monitoring }}"
    state: present

# Monitoring configuration
- name: "Configure monitoring"
  template:
    src: monitoring.conf.j2
    dest: /etc/monitoring.conf
    mode: '0644'

# Monitoring service
- name: "Start monitoring service"
  systemd:
    name: monitoring
    enabled: yes
    state: started
  when: monitoring.enabled | default(true)
```

### backup_setup
**Directory**: `ansible/roles/backup_setup/`

#### Purpose
Configures backup procedures and schedules for critical system files and configurations.

#### Main Tasks
**File**: `ansible/roles/backup_setup/tasks/main.yml`

```yaml
# Backup directory creation
- name: "Create backup directories"
  file:
    path: "{{ item }}"
    state: directory
    mode: '0755'
    owner: root
    group: root
  loop: "{{ backup.destinations }}"

# Backup script
- name: "Create backup script"
  template:
    src: backup.sh.j2
    dest: /usr/local/bin/backup.sh
    mode: '0755'

# Backup cron job
- name: "Configure backup schedule"
  cron:
    name: "System backup"
    minute: "0"
    hour: "2"
    job: "/usr/local/bin/backup.sh"
    user: root
  when: backup.enabled | default(false)
```

## Conventions and Best Practices

### Naming Conventions
- **Playbooks**: Use descriptive names with hyphens (`setup-aws-instances.yml`)
- **Roles**: Use underscores for role names (`security_hardening`)
- **Tasks**: Use descriptive names with quotes and proper capitalization
- **Variables**: Use lowercase with underscores (`enable_firewall`)

### Error Handling
```yaml
# Use ignore_errors for non-critical tasks
- name: "Disable unnecessary services"
  systemd:
    name: "{{ item }}"
    enabled: no
    state: stopped
  loop: "{{ system_services_disabled }}"
  ignore_errors: yes

# Use failed_when for custom failure conditions
- name: "Check service status"
  command: systemctl is-active {{ service_name }}
  register: service_status
  failed_when: service_status.rc != 0 and service_status.rc != 3
```

### Idempotency
```yaml
# Use creates parameter for idempotent commands
- name: "Initialize FIM baseline"
  command: /opt/lab-env/bin/python /opt/lab-environment/fim-agent.py --init-baseline
  args:
    creates: /var/lib/fim/baseline.json

# Use state parameter for idempotent file operations
- name: "Create directory"
  file:
    path: /opt/lab-environment
    state: directory
    mode: '0755'
```

### Handler Usage
```yaml
# Notify handlers when configuration changes
- name: "Configure SSH"
  template:
    src: sshd_config.j2
    dest: /etc/ssh/sshd_config
    backup: yes
  notify: restart ssh

# Handlers are triggered at the end of the playbook
handlers:
  - name: restart ssh
    systemd:
      name: ssh
      state: restarted
```

### Variable Precedence
1. **Command line variables** (`-e` or `--extra-vars`)
2. **Playbook variables** (`vars:` section)
3. **Host variables** (`host_vars/`)
4. **Group variables** (`group_vars/`)
5. **Role defaults** (`roles/*/defaults/main.yml`)

### Testing and Validation
```bash
# Syntax check
ansible-playbook --syntax-check ansible/playbooks/setup-aws-instances.yml

# Dry run
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml --check

# Diff mode
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml --check --diff

# Verbose output
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml -vvv
```

This comprehensive reference provides detailed documentation for all Ansible components in the lab environment, enabling effective automation and configuration management across mixed operating system environments.
