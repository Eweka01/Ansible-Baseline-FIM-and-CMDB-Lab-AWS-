# CMDB and Asset Inventory

## Overview

The Configuration Management Database (CMDB) system provides comprehensive asset discovery, configuration tracking, and system inventory management across mixed AWS EC2 environments. It implements automated data collection with Prometheus metrics integration and JSON-based data storage.

## CMDB Architecture

### Core Components

#### CMDB Collector
**File**: `cmdb/scripts/cmdb-collector.py`

```python
class CMDBCollector:
    def __init__(self, output_dir='/var/lib/cmdb/data'):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.setup_logging()
        self.collection_timestamp = datetime.now().isoformat()
```

#### Data Schema
**File**: `cmdb/schemas/cmdb-schema.json`

```json
{
    "system_info": {
        "hostname": "string",
        "fqdn": "string",
        "operating_system": "string",
        "kernel_version": "string",
        "architecture": "string",
        "uptime": "integer",
        "boot_time": "string"
    },
    "hardware": {
        "cpu_cores": "integer",
        "cpu_model": "string",
        "memory_total": "integer",
        "memory_available": "integer",
        "disk_devices": "array",
        "network_interfaces": "array"
    },
    "software": {
        "installed_packages": "array",
        "running_services": "array",
        "environment_variables": "object",
        "cron_jobs": "array"
    },
    "network": {
        "interfaces": "array",
        "routing_table": "array",
        "dns_servers": "array",
        "open_ports": "array"
    },
    "security": {
        "users": "array",
        "groups": "array",
        "sudoers": "array",
        "ssh_keys": "array"
    }
}
```

## Data Collection Sources

### System Information Collection

#### Hardware Discovery
**File**: `cmdb/scripts/cmdb-collector.py`

```python
def collect_hardware_info(self):
    """Collect hardware information"""
    hardware_info = {
        "cpu_cores": psutil.cpu_count(),
        "cpu_model": self.get_cpu_model(),
        "memory_total": psutil.virtual_memory().total,
        "memory_available": psutil.virtual_memory().available,
        "disk_devices": self.get_disk_devices(),
        "network_interfaces": self.get_network_interfaces()
    }
    return hardware_info

def get_cpu_model(self):
    """Get CPU model information"""
    try:
        with open('/proc/cpuinfo', 'r') as f:
            for line in f:
                if line.startswith('model name'):
                    return line.split(':')[1].strip()
    except Exception:
        return "Unknown"
```

#### Operating System Information
```python
def collect_system_info(self):
    """Collect system information"""
    system_info = {
        "hostname": socket.gethostname(),
        "fqdn": socket.getfqdn(),
        "operating_system": platform.system(),
        "kernel_version": platform.release(),
        "architecture": platform.machine(),
        "uptime": int(time.time() - psutil.boot_time()),
        "boot_time": datetime.fromtimestamp(psutil.boot_time()).isoformat()
    }
    return system_info
```

### Software Inventory

#### Installed Packages
```python
def collect_installed_packages(self):
    """Collect installed package information"""
    packages = []
    
    # Ubuntu/Debian packages
    if os.path.exists('/usr/bin/dpkg'):
        result = self.run_command('dpkg -l')
        if result['rc'] == 0:
            for line in result['stdout'].split('\n')[5:]:  # Skip header
                if line.strip():
                    parts = line.split()
                    if len(parts) >= 3:
                        packages.append({
                            "name": parts[1],
                            "version": parts[2],
                            "status": parts[0],
                            "package_manager": "dpkg"
                        })
    
    # Amazon Linux packages
    elif os.path.exists('/usr/bin/rpm'):
        result = self.run_command('rpm -qa --queryformat "%{NAME}\t%{VERSION}\t%{RELEASE}\n"')
        if result['rc'] == 0:
            for line in result['stdout'].split('\n'):
                if line.strip():
                    parts = line.split('\t')
                    if len(parts) >= 2:
                        packages.append({
                            "name": parts[0],
                            "version": f"{parts[1]}-{parts[2]}" if len(parts) > 2 else parts[1],
                            "package_manager": "rpm"
                        })
    
    return packages
```

#### Running Services
```python
def collect_running_services(self):
    """Collect running service information"""
    services = []
    
    # Systemd services
    result = self.run_command('systemctl list-units --type=service --state=running --no-pager')
    if result['rc'] == 0:
        for line in result['stdout'].split('\n')[1:]:  # Skip header
            if '.service' in line and 'running' in line:
                parts = line.split()
                if len(parts) >= 1:
                    service_name = parts[0].replace('.service', '')
                    services.append({
                        "name": service_name,
                        "status": "running",
                        "type": "systemd"
                    })
    
    return services
```

### Network Configuration

#### Network Interfaces
```python
def collect_network_info(self):
    """Collect network configuration"""
    network_info = {
        "interfaces": self.get_network_interfaces(),
        "routing_table": self.get_routing_table(),
        "dns_servers": self.get_dns_servers(),
        "open_ports": self.get_open_ports()
    }
    return network_info

def get_network_interfaces(self):
    """Get network interface information"""
    interfaces = []
    for interface, addrs in psutil.net_if_addrs().items():
        interface_info = {
            "name": interface,
            "addresses": []
        }
        
        for addr in addrs:
            interface_info["addresses"].append({
                "family": str(addr.family),
                "address": addr.address,
                "netmask": addr.netmask,
                "broadcast": addr.broadcast
            })
        
        interfaces.append(interface_info)
    
    return interfaces
```

#### Open Ports
```python
def get_open_ports(self):
    """Get open network ports"""
    open_ports = []
    
    for conn in psutil.net_connections(kind='inet'):
        if conn.status == 'LISTEN':
            open_ports.append({
                "port": conn.laddr.port,
                "address": conn.laddr.ip,
                "protocol": "tcp" if conn.type == socket.SOCK_STREAM else "udp",
                "pid": conn.pid,
                "process": self.get_process_name(conn.pid) if conn.pid else None
            })
    
    return open_ports
```

### Security Information

#### User Accounts
```python
def collect_security_info(self):
    """Collect security-related information"""
    security_info = {
        "users": self.get_user_accounts(),
        "groups": self.get_groups(),
        "sudoers": self.get_sudoers(),
        "ssh_keys": self.get_ssh_keys()
    }
    return security_info

def get_user_accounts(self):
    """Get user account information"""
    users = []
    
    # Read /etc/passwd
    try:
        with open('/etc/passwd', 'r') as f:
            for line in f:
                parts = line.strip().split(':')
                if len(parts) >= 7:
                    users.append({
                        "username": parts[0],
                        "uid": int(parts[2]),
                        "gid": int(parts[3]),
                        "home_directory": parts[5],
                        "shell": parts[6],
                        "description": parts[4]
                    })
    except Exception as e:
        self.logger.error(f"Error reading /etc/passwd: {e}")
    
    return users
```

#### SSH Keys
```python
def get_ssh_keys(self):
    """Get SSH public keys"""
    ssh_keys = []
    
    # Find authorized_keys files
    for root, dirs, files in os.walk('/home'):
        if 'authorized_keys' in files:
            authorized_keys_path = os.path.join(root, 'authorized_keys')
            try:
                with open(authorized_keys_path, 'r') as f:
                    for line in f:
                        line = line.strip()
                        if line and not line.startswith('#'):
                            parts = line.split()
                            if len(parts) >= 2:
                                ssh_keys.append({
                                    "user": os.path.basename(root),
                                    "key_type": parts[0],
                                    "key_data": parts[1],
                                    "comment": parts[2] if len(parts) > 2 else "",
                                    "file_path": authorized_keys_path
                                })
            except Exception as e:
                self.logger.error(f"Error reading {authorized_keys_path}: {e}")
    
    return ssh_keys
```

## Data Storage and Export

### JSON Data Storage
**File**: `/var/lib/cmdb/data/system-info.json`

```json
{
    "collection_timestamp": "2025-01-03T14:35:00Z",
    "hostname": "manage-node-1",
    "system_info": {
        "hostname": "manage-node-1",
        "fqdn": "manage-node-1.ec2.internal",
        "operating_system": "Linux",
        "kernel_version": "5.15.0-1028-aws",
        "architecture": "x86_64",
        "uptime": 86400,
        "boot_time": "2025-01-02T14:35:00Z"
    },
    "hardware": {
        "cpu_cores": 1,
        "cpu_model": "Intel(R) Xeon(R) CPU E5-2676 v3 @ 2.40GHz",
        "memory_total": 1073741824,
        "memory_available": 536870912,
        "disk_devices": [
            {
                "device": "/dev/xvda1",
                "mountpoint": "/",
                "fstype": "ext4",
                "total": 8589934592,
                "used": 4294967296,
                "free": 4294967296
            }
        ],
        "network_interfaces": [
            {
                "name": "eth0",
                "addresses": [
                    {
                        "family": "AddressFamily.AF_INET",
                        "address": "18.234.152.228",
                        "netmask": "255.255.255.0"
                    }
                ]
            }
        ]
    },
    "software": {
        "installed_packages": [
            {
                "name": "openssh-server",
                "version": "1:8.2p1-4ubuntu0.5",
                "status": "ii",
                "package_manager": "dpkg"
            }
        ],
        "running_services": [
            {
                "name": "ssh",
                "status": "running",
                "type": "systemd"
            }
        ],
        "environment_variables": {
            "PATH": "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
            "HOME": "/root"
        },
        "cron_jobs": [
            {
                "user": "root",
                "schedule": "0 2 * * *",
                "command": "/usr/bin/aide --check"
            }
        ]
    },
    "network": {
        "interfaces": [
            {
                "name": "eth0",
                "addresses": [
                    {
                        "family": "AddressFamily.AF_INET",
                        "address": "18.234.152.228",
                        "netmask": "255.255.255.0"
                    }
                ]
            }
        ],
        "routing_table": [
            {
                "destination": "0.0.0.0",
                "gateway": "18.234.152.1",
                "interface": "eth0"
            }
        ],
        "dns_servers": ["8.8.8.8", "8.8.4.4"],
        "open_ports": [
            {
                "port": 22,
                "address": "0.0.0.0",
                "protocol": "tcp",
                "process": "sshd"
            }
        ]
    },
    "security": {
        "users": [
            {
                "username": "ec2-user",
                "uid": 1000,
                "gid": 1000,
                "home_directory": "/home/ec2-user",
                "shell": "/bin/bash",
                "description": "EC2 Default User"
            }
        ],
        "groups": [
            {
                "name": "sudo",
                "gid": 27,
                "members": ["ec2-user"]
            }
        ],
        "sudoers": [
            {
                "user": "ec2-user",
                "privileges": "ALL=(ALL) NOPASSWD:ALL"
            }
        ],
        "ssh_keys": [
            {
                "user": "ec2-user",
                "key_type": "ssh-rsa",
                "key_data": "AAAAB3NzaC1yc2EAAAADAQABAAABgQC...",
                "comment": "ec2-user@key-p3",
                "file_path": "/home/ec2-user/.ssh/authorized_keys"
            }
        ]
    }
}
```

### Prometheus Metrics Integration
**File**: `cmdb/cmdb-collector-prometheus.py`

```python
from prometheus_client import Counter, Gauge, start_http_server

# Prometheus metrics
cmdb_collections_total = Counter('cmdb_collections_total', 'Total CMDB collections')
system_packages_total = Gauge('system_packages_total', 'Total installed packages')
system_cpu_cores = Gauge('system_cpu_cores', 'Number of CPU cores')
system_memory_total = Gauge('system_memory_total', 'Total system memory in bytes')
system_processes_total = Gauge('system_processes_total', 'Total running processes')
system_users_total = Gauge('system_users_total', 'Total user accounts')
system_services_total = Gauge('system_services_total', 'Total running services')

def update_metrics(self, data):
    """Update Prometheus metrics with collected data"""
    cmdb_collections_total.inc()
    system_packages_total.set(len(data.get('software', {}).get('installed_packages', [])))
    system_cpu_cores.set(data.get('hardware', {}).get('cpu_cores', 0))
    system_memory_total.set(data.get('hardware', {}).get('memory_total', 0))
    system_processes_total.set(len(psutil.pids()))
    system_users_total.set(len(data.get('security', {}).get('users', [])))
    system_services_total.set(len(data.get('software', {}).get('running_services', [])))
```

## Automated Collection and Scheduling

### Systemd Timer Configuration
**File**: `ansible/playbooks/templates/cmdb-collector.timer.j2`

```ini
[Unit]
Description=CMDB Data Collection Timer
Requires=cmdb-collector.service

[Timer]
OnCalendar=hourly
Persistent=true
AccuracySec=1min

[Install]
WantedBy=timers.target
```

### Systemd Service Configuration
**File**: `ansible/playbooks/templates/cmdb-collector.service.j2`

```ini
[Unit]
Description=CMDB Data Collector
After=network.target

[Service]
Type=oneshot
User=root
ExecStart=/opt/lab-env/bin/python /opt/lab-environment/cmdb-collector.py
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

### Collection Scheduling
```bash
# Enable and start CMDB collection timer
ansible aws_instances -i ansible/inventory/aws-instances -m systemd -a "name=cmdb-collector.timer enabled=yes state=started"

# Check timer status
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "systemctl status cmdb-collector.timer"

# List timer jobs
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "systemctl list-timers cmdb-collector.timer"
```

## Drift Detection and Reconciliation

### Baseline Comparison
```python
def compare_with_baseline(self, current_data, baseline_data):
    """Compare current data with baseline"""
    differences = {
        "new_packages": [],
        "removed_packages": [],
        "new_services": [],
        "stopped_services": [],
        "new_users": [],
        "removed_users": [],
        "new_ports": [],
        "closed_ports": []
    }
    
    # Compare packages
    current_packages = {pkg['name']: pkg for pkg in current_data.get('software', {}).get('installed_packages', [])}
    baseline_packages = {pkg['name']: pkg for pkg in baseline_data.get('software', {}).get('installed_packages', [])}
    
    for pkg_name in current_packages:
        if pkg_name not in baseline_packages:
            differences["new_packages"].append(current_packages[pkg_name])
    
    for pkg_name in baseline_packages:
        if pkg_name not in current_packages:
            differences["removed_packages"].append(baseline_packages[pkg_name])
    
    return differences
```

### Automated Reconciliation
```python
def reconcile_drift(self, differences):
    """Reconcile detected drift"""
    if differences["new_packages"]:
        self.logger.warning(f"New packages detected: {[pkg['name'] for pkg in differences['new_packages']]}")
    
    if differences["removed_packages"]:
        self.logger.warning(f"Packages removed: {[pkg['name'] for pkg in differences['removed_packages']]}")
    
    if differences["new_services"]:
        self.logger.warning(f"New services running: {[svc['name'] for svc in differences['new_services']]}")
    
    if differences["stopped_services"]:
        self.logger.warning(f"Services stopped: {[svc['name'] for svc in differences['stopped_services']]}")
    
    # Update baseline if changes are legitimate
    if self.is_legitimate_change(differences):
        self.update_baseline()
```

## Testing and Validation

### CMDB Collection Test
```bash
# Run CMDB collection manually
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "/opt/lab-env/bin/python /opt/lab-environment/cmdb-collector.py"

# Verify data collection
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "ls -la /var/lib/cmdb/data/"

# Check data format
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "python3 -m json.tool /var/lib/cmdb/data/system-info.json | head -20"
```

### Prometheus Metrics Test
```bash
# Test CMDB metrics endpoint
curl -s http://localhost:8081/metrics | grep cmdb_

# Expected output:
# cmdb_collections_total 1
# system_packages_total 516
# system_cpu_cores 1
# system_memory_total 1073741824
# system_processes_total 105
# system_users_total 1
# system_services_total 15
```

### Data Validation Test
```bash
# Validate collected data
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "python3 -c \"
import json
with open('/var/lib/cmdb/data/system-info.json', 'r') as f:
    data = json.load(f)
    print(f'Hostname: {data[\"hostname\"]}')
    print(f'OS: {data[\"system_info\"][\"operating_system\"]}')
    print(f'CPU Cores: {data[\"hardware\"][\"cpu_cores\"]}')
    print(f'Memory: {data[\"hardware\"][\"memory_total\"]} bytes')
    print(f'Packages: {len(data[\"software\"][\"installed_packages\"])}')
    print(f'Services: {len(data[\"software\"][\"running_services\"])}')
    print(f'Users: {len(data[\"security\"][\"users\"])}')
\""
```

## Performance and Scalability

### Collection Optimization
```python
def optimize_collection(self):
    """Optimize data collection performance"""
    # Use multiprocessing for parallel collection
    import multiprocessing as mp
    
    with mp.Pool(processes=4) as pool:
        results = pool.map(self.collect_data_parallel, [
            'system_info',
            'hardware_info', 
            'software_info',
            'network_info'
        ])
    
    return dict(zip(['system_info', 'hardware_info', 'software_info', 'network_info'], results))
```

### Data Retention
```python
def cleanup_old_data(self, retention_days=30):
    """Clean up old CMDB data files"""
    cutoff_date = datetime.now() - timedelta(days=retention_days)
    
    for file_path in self.output_dir.glob('*.json'):
        if file_path.stat().st_mtime < cutoff_date.timestamp():
            file_path.unlink()
            self.logger.info(f"Removed old data file: {file_path}")
```

This CMDB implementation provides comprehensive asset discovery, configuration tracking, and drift detection capabilities with automated collection, Prometheus integration, and robust data validation for enterprise configuration management requirements.
