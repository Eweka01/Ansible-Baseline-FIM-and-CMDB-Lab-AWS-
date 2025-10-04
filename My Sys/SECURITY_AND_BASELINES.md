# Security and Baselines

## Security Baseline Overview

This lab implements comprehensive security hardening measures across mixed operating systems (Amazon Linux 2023 and Ubuntu 24.04) following industry best practices and compliance frameworks.

## Implemented Security Controls

### SSH Security Hardening

#### Configuration Location
**File**: `ansible/roles/security_hardening/templates/sshd_config.j2`

#### Implemented Controls
```bash
# SSH Configuration (sshd_config.j2)
PermitRootLogin no                    # CIS Control 5.1
PasswordAuthentication no             # CIS Control 5.2
PubkeyAuthentication yes              # CIS Control 5.3
MaxAuthTries 3                        # CIS Control 5.4
ClientAliveInterval 300               # CIS Control 5.5
ClientAliveCountMax 2                 # CIS Control 5.5
Protocol 2                            # CIS Control 5.6
X11Forwarding no                      # CIS Control 5.7
AllowUsers {{ ansible_user }}         # CIS Control 5.8
```

#### Verification Commands
```bash
# Verify SSH configuration
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "sshd -T | grep -E '(PermitRootLogin|PasswordAuthentication|MaxAuthTries)'"

# Expected output:
# permitrootlogin no
# passwordauthentication no
# maxauthtries 3
```

### Firewall Configuration

#### Ubuntu/Debian (UFW)
**File**: `ansible/roles/security_hardening/tasks/main.yml`

```yaml
# UFW Configuration
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
```

#### Amazon Linux (iptables)
**File**: `ansible/playbooks/templates/fail2ban-aws.j2`

```bash
# iptables Configuration
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -i lo -j ACCEPT
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A INPUT -p tcp --dport 22 -j ACCEPT
COMMIT
```

#### Verification Commands
```bash
# Check UFW status (Ubuntu)
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "ufw status verbose"

# Check iptables rules (Amazon Linux)
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "iptables -L -n"
```

### Intrusion Prevention (Fail2ban)

#### Configuration Location
**File**: `ansible/roles/security_hardening/templates/fail2ban.j2`

#### Implemented Controls
```ini
# Fail2ban Configuration
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

#### Verification Commands
```bash
# Check fail2ban status
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "fail2ban-client status"

# Check banned IPs
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "fail2ban-client status sshd"
```

### System Audit (auditd)

#### Configuration Location
**File**: `ansible/roles/security_hardening/templates/auditd.conf.j2`

#### Implemented Controls
```bash
# Audit Configuration
log_file = /var/log/audit/audit.log
log_format = RAW
log_group = adm
priority_boost = 4
flush = INCREMENTAL
freq = 20
num_logs = 5
disp_qos = lossy
dispatcher = /sbin/audispd
name_format = HOSTNAME
max_log_file = 6
max_log_file_action = ROTATE
space_left = 75
space_left_action = SYSLOG
action_mail_acct = root
admin_space_left = 50
admin_space_left_action = SUSPEND
disk_full_action = SUSPEND
disk_error_action = SUSPEND
```

#### Audit Rules
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

#### Verification Commands
```bash
# Check auditd status
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "systemctl status auditd"

# Check audit rules
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "auditctl -l"

# Search audit logs
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "ausearch -m USER_LOGIN -ts today"
```

### File Integrity Monitoring (AIDE)

#### Configuration Location
**File**: `ansible/roles/security_hardening/tasks/main.yml`

#### Implemented Controls
```yaml
# AIDE Configuration
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
```

#### Verification Commands
```bash
# Check AIDE database
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "ls -la /var/lib/aide/aide.db.gz"

# Run AIDE check
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "aide --check"
```

### File Permissions

#### Critical File Permissions
**File**: `ansible/roles/security_hardening/tasks/main.yml`

```yaml
# File Permissions
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
```

#### Verification Commands
```bash
# Check critical file permissions
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "ls -la /etc/passwd /etc/shadow /etc/group /etc/gshadow"

# Expected output:
# -rw-r--r-- 1 root root /etc/passwd
# -rw------- 1 root root /etc/shadow
# -rw-r--r-- 1 root root /etc/group
# -rw------- 1 root root /etc/gshadow
```

### Password Policy

#### Ubuntu/Debian Configuration
**File**: `ansible/roles/security_hardening/templates/common-password.j2`

```bash
# Password Policy
password        requisite                       pam_pwquality.so retry=3 minlen=8 dcredit=-1 ucredit=-1 lcredit=-1 ocredit=-1
password        [success=1 default=ignore]      pam_unix.so obscure use_authtok try_first_pass yescrypt
password        requisite                       pam_deny.so
password        required                        pam_permit.so
```

#### Amazon Linux Configuration
**File**: `ansible/roles/security_hardening/templates/system-auth.j2`

```bash
# Password Policy
password    requisite     pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type= minlen=8 dcredit=-1 ucredit=-1 lcredit=-1 ocredit=-1
password    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok
password    required      pam_deny.so
```

#### Verification Commands
```bash
# Check password policy
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "grep -E '(minlen|dcredit|ucredit|lcredit|ocredit)' /etc/pam.d/common-password"
```

## Compliance Framework Mapping

### CIS Controls Implementation

| CIS Control | Implementation | File Location | Verification |
|-------------|----------------|---------------|--------------|
| 5.1 - Establish Secure Configurations | SSH hardening | `ansible/roles/security_hardening/templates/sshd_config.j2` | `sshd -T` |
| 5.2 - Maintain Secure Configurations | File permissions | `ansible/roles/security_hardening/tasks/main.yml` | `ls -la /etc/passwd` |
| 5.3 - Implement Network Segmentation | Firewall rules | `ansible/playbooks/templates/fail2ban-aws.j2` | `ufw status` |
| 5.4 - Restrict Administrative Privileges | User management | `ansible/roles/system_baseline/tasks/main.yml` | `grep sudo /etc/group` |
| 5.5 - Use Multi-Factor Authentication | SSH key-based auth | `ansible/inventory/aws-instances` | SSH key verification |
| 5.6 - Use Dedicated Administrative Workstations | SSH configuration | `ansible/roles/security_hardening/templates/sshd_config.j2` | `sshd -T` |
| 5.7 - Deploy and Maintain Endpoint Detection | FIM implementation | `fim/agents/fim-agent.py` | FIM baseline check |
| 5.8 - Deploy and Maintain Network Monitoring | Audit logging | `ansible/roles/security_hardening/templates/audit.rules.j2` | `auditctl -l` |

### NIST Cybersecurity Framework

| NIST Function | Implementation | Controls |
|---------------|----------------|----------|
| **Identify** | Asset inventory | CMDB collector, system discovery |
| **Protect** | Access controls | SSH hardening, firewall, fail2ban |
| **Detect** | Monitoring | FIM, auditd, Prometheus metrics |
| **Respond** | Incident response | Automated alerts, log analysis |
| **Recover** | Backup/restore | Configuration backups, rollback procedures |

### ISO 27001 Controls

| ISO Control | Implementation | Evidence |
|-------------|----------------|----------|
| A.9.1.1 - Access Control Policy | SSH configuration | `sshd_config.j2` |
| A.9.1.2 - Access to Networks | Firewall rules | UFW/iptables configuration |
| A.9.2.1 - User Registration | User management | Ansible user tasks |
| A.9.2.3 - Management of Privileged Access | Sudo configuration | `/etc/sudoers.d/lab-users` |
| A.9.4.2 - Secure Log-on Procedures | SSH key authentication | Inventory configuration |
| A.10.1.1 - Policy on Use of Cryptographic Controls | SSH encryption | SSH protocol configuration |
| A.12.6.1 - Management of Technical Vulnerabilities | Package updates | Ansible package tasks |
| A.13.1.1 - Network Controls | Firewall implementation | UFW/iptables rules |
| A.13.1.3 - Segregation of Networks | Network segmentation | Security group configuration |
| A.14.1.1 - Information Security Requirements | Security baseline | Role-based configuration |

## Security Monitoring and Alerting

### Real-time Security Monitoring

#### FIM Security Events
```bash
# Monitor FIM security events
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "tail -f /var/log/fim-agent.log" | grep -E "(CHANGED|NEW|DELETED)"

# Check FIM baseline integrity
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "/opt/lab-env/bin/python /opt/lab-environment/fim-agent.py --scan-once"
```

#### Audit Log Monitoring
```bash
# Monitor authentication events
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "ausearch -m USER_LOGIN -ts today"

# Monitor privilege escalation
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "ausearch -m USER_CMD -k sudo"

# Monitor file access
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "ausearch -m FILE -k identity"
```

#### Fail2ban Monitoring
```bash
# Check fail2ban status
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "fail2ban-client status sshd"

# View banned IPs
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "fail2ban-client get sshd banned"
```

### Security Metrics and Dashboards

#### Prometheus Security Metrics
```bash
# Query FIM events
curl -s 'http://localhost:9090/api/v1/query?query=fim_events_total' | jq '.data.result'

# Query authentication failures
curl -s 'http://localhost:9090/api/v1/query?query=node_auth_failures_total' | jq '.data.result'

# Query system security status
curl -s 'http://localhost:9090/api/v1/query?query=node_security_status' | jq '.data.result'
```

#### Grafana Security Dashboard
- **Access**: http://localhost:3000/d/fim-cmdb-dashboard
- **Metrics**: FIM events, authentication failures, system security status
- **Alerts**: Real-time security incident notifications

## Extending Security Baselines

### Adding New Security Controls

#### Custom Security Tasks
**File**: `ansible/roles/security_hardening/tasks/custom.yml`

```yaml
# Custom Security Tasks
- name: "Install additional security packages"
  package:
    name: "{{ item }}"
    state: present
  loop:
    - clamav
    - rkhunter
    - chkrootkit

- name: "Configure custom security settings"
  template:
    src: custom-security.j2
    dest: /etc/custom-security.conf
    mode: '0644'
  notify: restart custom-service
```

#### Custom Security Variables
**File**: `ansible/group_vars/all.yml`

```yaml
# Custom Security Variables
custom_security:
  enabled: true
  packages:
    - clamav
    - rkhunter
    - chkrootkit
  settings:
    scan_interval: 3600
    alert_threshold: 5
```

### Environment-Specific Security

#### Development Environment
```bash
# Relaxed security for development
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml -e "security_level=development"
```

#### Production Environment
```bash
# Strict security for production
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml -e "security_level=production"
```

#### High-Security Environment
```bash
# Maximum security settings
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml -e "security_level=high"
```

## Security Incident Response

### Automated Security Response

#### FIM Alert Response
```bash
# Automatic FIM alert handling
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "/opt/lab-env/bin/python /opt/lab-environment/fim-agent.py --alert-response"

# Isolate affected system
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "ufw --force enable" --become
```

#### Intrusion Response
```bash
# Block suspicious IPs
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "fail2ban-client set sshd banip SUSPICIOUS_IP"

# Collect forensic data
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "ausearch -m ALL -ts today > /tmp/forensic_data.log"
```

### Security Reporting

#### Compliance Reports
```bash
# Generate security compliance report
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "/opt/lab-env/bin/python /opt/lab-environment/security-report.py"

# Export audit logs
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "ausearch -m ALL -ts today -f /var/log/audit/audit.log > /tmp/audit_export.log"
```

This security baseline provides comprehensive protection following industry standards and compliance frameworks, with automated monitoring and response capabilities.
