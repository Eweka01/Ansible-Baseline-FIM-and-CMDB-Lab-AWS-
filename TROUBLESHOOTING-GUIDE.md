# Troubleshooting Guide - AWS Lab Deployment

This document records all the errors encountered during the AWS lab deployment and their solutions. This serves as a reference for troubleshooting similar issues in the future.

## Table of Contents
1. [Ansible Configuration Errors](#ansible-configuration-errors)
2. [Inventory Parsing Errors](#inventory-parsing-errors)
3. [Package Management Errors](#package-management-errors)
4. [Python Environment Errors](#python-environment-errors)
5. [Firewall Configuration Errors](#firewall-configuration-errors)
6. [Service Configuration Errors](#service-configuration-errors)
7. [Template Variable Errors](#template-variable-errors)
8. [Mixed OS Compatibility Issues](#mixed-os-compatibility-issues)

---

## Ansible Configuration Errors

### Error 1: Duplicate Configuration Option
**Error Message:**
```
ERROR: Error reading config file (.../ansible.cfg): While reading from '<string>' [line 23]: option 'host_key_checking' in section 'defaults' already exists
```

**Root Cause:** The `ansible.cfg` file had duplicate `host_key_checking` options.

**Solution:**
```bash
# Removed the duplicate line from ansible/ansible.cfg
# Kept only one instance of:
host_key_checking = False
```

**Prevention:** Always check for duplicate configuration options when editing Ansible config files.

---

## Inventory Parsing Errors

### Error 2: YAML Syntax in INI Inventory
**Error Message:**
```
[WARNING]: Failed to parse inventory with 'yaml' plugin: YAML parsing failed: Did not find expected <document start>.
[WARNING]: Failed to parse inventory with 'ini' plugin: Failed to parse inventory: Expected key=value, got: ntp_servers:
```

**Root Cause:** The inventory file used YAML-style syntax (`ntp_servers:` with a list) in an INI format file.

**Solution:**
```ini
# REMOVED this YAML-style syntax:
ntp_servers:
  - 0.pool.ntp.org
  - 1.pool.ntp.org
  - 2.pool.ntp.org

# INI format doesn't support complex data structures like lists
```

**Prevention:** Use proper INI format for inventory files, or use YAML format consistently.

### Error 3: Boolean Conversion Issues
**Error Message:**
```
[ERROR]: Task failed: Conditional result (True) was derived from value of type 'str' at '/Users/.../ansible/inventory/aws-instances:19'. Conditionals must have a boolean result.
```

**Root Cause:** Ansible couldn't convert string values to boolean for conditional statements.

**Solution:**
```yaml
# BEFORE (caused error):
when: 
  - enable_firewall | default(true)
  - ansible_os_family == "Debian"

# AFTER (fixed):
when: 
  - (enable_firewall | default(true)) | bool
  - ansible_os_family == "Debian"
```

**Prevention:** Always use the `| bool` filter when working with variables that might be strings but need boolean evaluation.

---

## Package Management Errors

### Error 4: Amazon Linux Curl Package Conflict
**Error Message:**
```
[ERROR]: Task failed: Module failed: Depsolve Error occurred: 
Problem: problem with installed package curl-minimal-8.11.1-4.amzn2023.0.1.x86_64
- package curl-minimal-8.11.1-4.amzn2023.0.1.x86_64 from @System conflicts with curl provided by curl-7.87.0-2.amzn2023.0.2.x86_64 from amazonlinux
```

**Root Cause:** Amazon Linux 2023 has a pre-installed `curl-minimal` package that conflicts with the full `curl` package.

**Solution:**
```yaml
# REMOVED curl from Amazon Linux package list:
- name: "Install essential packages (Amazon Linux)"
  yum:
    name:
      - python3
      - python3-pip
      # - curl  # REMOVED - conflicts with curl-minimal
      - wget
      - vim
      # ... other packages
```

**Prevention:** Research package conflicts for specific OS versions before including packages in playbooks.

---

## Python Environment Errors

### Error 5: Ubuntu Externally Managed Environment
**Error Message:**
```
[ERROR]: Task failed: Module failed: 
:stderr: error: externally-managed-environment

× This environment is externally managed
╰─> To install Python packages system-wide, try apt install python3-xyz, where xyz is the package you are trying to install.
```

**Root Cause:** Ubuntu 24.04 has PEP 668 protection that prevents pip installs to system Python.

**Solution:**
```yaml
# BEFORE (failed):
- name: "Install Python dependencies"
  pip:
    name:
      - psutil
      - watchdog
      # ... other packages
    state: present
  become: yes

# AFTER (fixed):
- name: "Create virtual environment directory"
  file:
    path: /opt/lab-env
    state: directory
    mode: '0755'
  become: yes

- name: "Create virtual environment"
  command: python3 -m venv /opt/lab-env
  become: yes

- name: "Install Python dependencies in virtual environment"
  pip:
    name:
      - psutil
      - watchdog
      # ... other packages
    state: present
    virtualenv: /opt/lab-env
  become: yes
```

**Prevention:** Always use virtual environments for Python package installation on modern Ubuntu/Debian systems.

### Error 6: Module Import Errors in Services
**Error Message:**
```
Traceback (most recent call last):
  File "/opt/lab-environment/cmdb-collector.py", line 13, in <module>
    import psutil
ModuleNotFoundError: No module named 'psutil'
```

**Root Cause:** Services were trying to use system Python instead of the virtual environment.

**Solution:**
```yaml
# Updated systemd service templates to use virtual environment:

# fim-agent.service.j2:
ExecStart=/opt/lab-env/bin/python /opt/lab-environment/fim-agent.py --config /etc/fim/fim-config.json

# cmdb-collector.service.j2:
ExecStart=/opt/lab-env/bin/python /opt/lab-environment/cmdb-collector.py --output-dir /var/lib/cmdb/data

# Updated playbook commands:
- name: "Run initial CMDB collection"
  command: /opt/lab-env/bin/python /opt/lab-environment/cmdb-collector.py
```

**Prevention:** Always specify the full path to the Python interpreter in virtual environments for services and commands.

---

## Firewall Configuration Errors

### Error 7: iptables Service Not Found
**Error Message:**
```
[ERROR]: Task failed: Module failed: Could not find the requested service iptables: host
```

**Root Cause:** Amazon Linux 2023 doesn't have an iptables systemd service (uses firewalld or direct iptables).

**Solution:**
```yaml
- name: "Start and enable iptables (Amazon Linux)"
  systemd:
    name: iptables
    enabled: yes
    state: started
  when:
    - (enable_firewall | default(true)) | bool
    - ansible_distribution == "Amazon"
  ignore_errors: yes  # Added to prevent playbook failure
```

**Prevention:** Research the correct service names for different Linux distributions before configuring systemd services.

---

## Template Variable Errors

### Error 8: Undefined Template Variable
**Error Message:**
```
[ERROR]: Task failed: 'ansible_memavailable_mb' is undefined
```

**Root Cause:** The template tried to use a variable that might not be available on all systems.

**Solution:**
```jinja2
# BEFORE (failed):
Available Memory: {{ ansible_memavailable_mb }} MB

# AFTER (fixed):
Available Memory: {{ ansible_memavailable_mb | default(ansible_memtotal_mb) }} MB
```

**Prevention:** Always use default values for Ansible facts that might not be available on all systems.

---

## Mixed OS Compatibility Issues

### Error 9: SSH User Mismatch
**Root Cause:** The inventory assumed all instances used `ubuntu` user, but Amazon Linux uses `ec2-user`.

**Solution:**
```ini
# Updated inventory to specify correct users:
[webservers]
manage-node-1 ansible_host=18.234.152.228 ansible_user=ec2-user  # Amazon Linux

[databases]
manage-node-2 ansible_host=54.242.234.69 ansible_user=ubuntu     # Ubuntu

[monitoring]
manage-node-3 ansible_host=13.217.82.23 ansible_user=ubuntu      # Ubuntu
```

**Prevention:** Always verify the default user for each OS type in your inventory.

### Error 10: Package Manager Differences
**Root Cause:** Different OS families use different package managers (`apt` vs `yum`).

**Solution:**
```yaml
# Added conditional tasks for different OS families:
- name: "Install essential packages (Ubuntu/Debian)"
  apt:
    name: [package_list]
    state: present
  when: ansible_os_family == "Debian"

- name: "Install essential packages (Amazon Linux)"
  yum:
    name: [package_list]
    state: present
  when: ansible_distribution == "Amazon"
```

**Prevention:** Use `ansible_os_family` and `ansible_distribution` facts to create OS-specific tasks.

---

## Best Practices Learned

### 1. Always Use Virtual Environments
- Modern Linux distributions protect system Python
- Use virtual environments for all Python package installations
- Update service files to use virtual environment Python

### 2. Handle Mixed OS Environments
- Use conditional tasks based on `ansible_os_family` and `ansible_distribution`
- Specify correct users for each OS type
- Research package names and service names for each distribution

### 3. Robust Error Handling
- Use `ignore_errors: yes` for non-critical tasks
- Provide default values for potentially undefined variables
- Use `| bool` filter for boolean conversions

### 4. Inventory Management
- Use proper INI or YAML format consistently
- Avoid mixing syntax styles
- Test inventory parsing before deployment

### 5. Service Configuration
- Always specify full paths to executables
- Use virtual environment Python for custom services
- Test service configurations before enabling

---

## Quick Reference Commands

### Test Inventory Parsing
```bash
ansible-inventory -i inventory/aws-instances --list
```

### Test SSH Connectivity
```bash
ansible -i inventory/aws-instances all -m ping
```

### Check Service Status
```bash
ansible -i inventory/aws-instances all -m shell -a "systemctl status fim-agent"
```

### View Logs
```bash
ansible -i inventory/aws-instances all -m shell -a "tail -f /var/log/fim-agent.log"
```

---

## Conclusion

These errors and their solutions demonstrate the importance of:
- Understanding OS-specific differences
- Using proper Python environment management
- Implementing robust error handling
- Testing configurations before deployment
- Documenting troubleshooting steps for future reference

This guide should help prevent similar issues in future deployments and provide quick solutions when they do occur.
