#!/usr/bin/env python3
"""
CMDB Data Collector
Collects system configuration and asset information for the CMDB
"""

import os
import sys
import json
import subprocess
import platform
import socket
import psutil
import uuid
from datetime import datetime
import argparse
import logging
from pathlib import Path

class CMDBCollector:
    def __init__(self, output_dir='/var/lib/cmdb/data'):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.setup_logging()
        self.collection_timestamp = datetime.now().isoformat()
    
    def setup_logging(self):
        """Setup logging configuration"""
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler('/var/log/cmdb-collector.log'),
                logging.StreamHandler(sys.stdout)
            ]
        )
        self.logger = logging.getLogger('CMDBCollector')
    
    def run_command(self, command, shell=True):
        """Run a shell command and return output"""
        try:
            result = subprocess.run(
                command,
                shell=shell,
                capture_output=True,
                text=True,
                timeout=30
            )
            return {
                'stdout': result.stdout.strip(),
                'stderr': result.stderr.strip(),
                'returncode': result.returncode,
                'success': result.returncode == 0
            }
        except subprocess.TimeoutExpired:
            self.logger.error(f"Command timeout: {command}")
            return {'success': False, 'error': 'timeout'}
        except Exception as e:
            self.logger.error(f"Command error: {command} - {e}")
            return {'success': False, 'error': str(e)}
    
    def collect_system_info(self):
        """Collect basic system information"""
        self.logger.info("Collecting system information")
        
        system_info = {
            'hostname': socket.gethostname(),
            'fqdn': socket.getfqdn(),
            'platform': platform.platform(),
            'system': platform.system(),
            'release': platform.release(),
            'version': platform.version(),
            'machine': platform.machine(),
            'processor': platform.processor(),
            'architecture': platform.architecture(),
            'python_version': platform.python_version(),
            'boot_time': datetime.fromtimestamp(psutil.boot_time()).isoformat(),
            'collection_timestamp': self.collection_timestamp
        }
        
        # Get additional system info
        try:
            system_info['uptime_seconds'] = int(time.time() - psutil.boot_time())
        except:
            system_info['uptime_seconds'] = None
        
        return system_info
    
    def collect_hardware_info(self):
        """Collect hardware information"""
        self.logger.info("Collecting hardware information")
        
        hardware_info = {
            'cpu': {
                'count': psutil.cpu_count(),
                'count_logical': psutil.cpu_count(logical=True),
                'freq': psutil.cpu_freq()._asdict() if psutil.cpu_freq() else None,
                'usage_percent': psutil.cpu_percent(interval=1)
            },
            'memory': {
                'total': psutil.virtual_memory().total,
                'available': psutil.virtual_memory().available,
                'used': psutil.virtual_memory().used,
                'free': psutil.virtual_memory().free,
                'percent': psutil.virtual_memory().percent
            },
            'disk': [],
            'network': []
        }
        
        # Disk information
        for partition in psutil.disk_partitions():
            try:
                partition_usage = psutil.disk_usage(partition.mountpoint)
                hardware_info['disk'].append({
                    'device': partition.device,
                    'mountpoint': partition.mountpoint,
                    'fstype': partition.fstype,
                    'total': partition_usage.total,
                    'used': partition_usage.used,
                    'free': partition_usage.free,
                    'percent': (partition_usage.used / partition_usage.total) * 100
                })
            except PermissionError:
                pass
        
        # Network interfaces
        for interface, addrs in psutil.net_if_addrs().items():
            interface_info = {
                'name': interface,
                'addresses': []
            }
            
            for addr in addrs:
                interface_info['addresses'].append({
                    'family': str(addr.family),
                    'address': addr.address,
                    'netmask': addr.netmask,
                    'broadcast': addr.broadcast
                })
            
            # Get interface statistics
            try:
                stats = psutil.net_if_stats()[interface]
                interface_info['stats'] = {
                    'isup': stats.isup,
                    'duplex': stats.duplex,
                    'speed': stats.speed,
                    'mtu': stats.mtu
                }
            except:
                pass
            
            hardware_info['network'].append(interface_info)
        
        return hardware_info
    
    def collect_software_info(self):
        """Collect installed software information"""
        self.logger.info("Collecting software information")
        
        software_info = {
            'packages': [],
            'services': [],
            'processes': []
        }
        
        # Get installed packages (Debian/Ubuntu)
        if os.path.exists('/usr/bin/dpkg'):
            result = self.run_command('dpkg -l | grep "^ii" | awk \'{print $2, $3}\'')
            if result['success']:
                for line in result['stdout'].split('\n'):
                    if line.strip():
                        parts = line.split(' ', 1)
                        if len(parts) == 2:
                            software_info['packages'].append({
                                'name': parts[0],
                                'version': parts[1],
                                'manager': 'dpkg'
                            })
        
        # Get installed packages (RedHat/CentOS)
        elif os.path.exists('/usr/bin/rpm'):
            result = self.run_command('rpm -qa --queryformat "%{NAME} %{VERSION}-%{RELEASE}\n"')
            if result['success']:
                for line in result['stdout'].split('\n'):
                    if line.strip():
                        parts = line.split(' ', 1)
                        if len(parts) == 2:
                            software_info['packages'].append({
                                'name': parts[0],
                                'version': parts[1],
                                'manager': 'rpm'
                            })
        
        # Get running services
        try:
            for service in psutil.win_service_iter() if platform.system() == 'Windows' else []:
                software_info['services'].append({
                    'name': service.name(),
                    'display_name': service.display_name(),
                    'status': service.status(),
                    'start_type': service.start_type()
                })
        except:
            # For Unix-like systems, get systemd services
            result = self.run_command('systemctl list-units --type=service --state=running --no-pager')
            if result['success']:
                for line in result['stdout'].split('\n')[1:]:  # Skip header
                    if '.service' in line:
                        parts = line.split()
                        if len(parts) >= 4:
                            software_info['services'].append({
                                'name': parts[0],
                                'status': 'running',
                                'manager': 'systemd'
                            })
        
        # Get running processes
        for proc in psutil.process_iter(['pid', 'name', 'cmdline', 'cpu_percent', 'memory_percent']):
            try:
                proc_info = proc.info
                software_info['processes'].append({
                    'pid': proc_info['pid'],
                    'name': proc_info['name'],
                    'cmdline': ' '.join(proc_info['cmdline']) if proc_info['cmdline'] else '',
                    'cpu_percent': proc_info['cpu_percent'],
                    'memory_percent': proc_info['memory_percent']
                })
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                pass
        
        return software_info
    
    def collect_network_info(self):
        """Collect network configuration information"""
        self.logger.info("Collecting network information")
        
        network_info = {
            'interfaces': [],
            'connections': [],
            'routing': [],
            'dns': []
        }
        
        # Network interfaces (already collected in hardware_info, but keeping separate)
        for interface, addrs in psutil.net_if_addrs().items():
            interface_info = {
                'name': interface,
                'addresses': []
            }
            
            for addr in addrs:
                interface_info['addresses'].append({
                    'family': str(addr.family),
                    'address': addr.address,
                    'netmask': addr.netmask,
                    'broadcast': addr.broadcast
                })
            
            network_info['interfaces'].append(interface_info)
        
        # Network connections
        for conn in psutil.net_connections(kind='inet'):
            network_info['connections'].append({
                'fd': conn.fd,
                'family': str(conn.family),
                'type': str(conn.type),
                'laddr': f"{conn.laddr.ip}:{conn.laddr.port}" if conn.laddr else None,
                'raddr': f"{conn.raddr.ip}:{conn.raddr.port}" if conn.raddr else None,
                'status': conn.status,
                'pid': conn.pid
            })
        
        # Routing table
        result = self.run_command('ip route show')
        if result['success']:
            for line in result['stdout'].split('\n'):
                if line.strip():
                    network_info['routing'].append(line.strip())
        
        # DNS configuration
        result = self.run_command('cat /etc/resolv.conf')
        if result['success']:
            for line in result['stdout'].split('\n'):
                if line.startswith('nameserver'):
                    network_info['dns'].append(line.split()[1])
        
        return network_info
    
    def collect_security_info(self):
        """Collect security-related information"""
        self.logger.info("Collecting security information")
        
        security_info = {
            'users': [],
            'groups': [],
            'sudoers': [],
            'ssh_keys': [],
            'firewall': {},
            'selinux': {}
        }
        
        # User accounts
        result = self.run_command('getent passwd')
        if result['success']:
            for line in result['stdout'].split('\n'):
                if line.strip():
                    parts = line.split(':')
                    if len(parts) >= 7:
                        security_info['users'].append({
                            'username': parts[0],
                            'uid': parts[2],
                            'gid': parts[3],
                            'home': parts[5],
                            'shell': parts[6]
                        })
        
        # Groups
        result = self.run_command('getent group')
        if result['success']:
            for line in result['stdout'].split('\n'):
                if line.strip():
                    parts = line.split(':')
                    if len(parts) >= 4:
                        security_info['groups'].append({
                            'name': parts[0],
                            'gid': parts[2],
                            'members': parts[3].split(',') if parts[3] else []
                        })
        
        # Sudoers
        result = self.run_command('sudo -l')
        if result['success']:
            security_info['sudoers'] = result['stdout'].split('\n')
        
        # SSH keys
        ssh_dir = Path.home() / '.ssh'
        if ssh_dir.exists():
            for key_file in ssh_dir.glob('*.pub'):
                try:
                    with open(key_file, 'r') as f:
                        key_content = f.read().strip()
                        security_info['ssh_keys'].append({
                            'file': str(key_file),
                            'type': key_content.split()[0] if key_content else 'unknown',
                            'fingerprint': key_content.split()[1] if len(key_content.split()) > 1 else 'unknown'
                        })
                except:
                    pass
        
        # Firewall status
        result = self.run_command('ufw status')
        if result['success']:
            security_info['firewall']['ufw'] = result['stdout']
        
        # SELinux status
        result = self.run_command('getenforce')
        if result['success']:
            security_info['selinux']['status'] = result['stdout']
        
        return security_info
    
    def collect_environment_info(self):
        """Collect environment and configuration information"""
        self.logger.info("Collecting environment information")
        
        env_info = {
            'environment_variables': dict(os.environ),
            'cron_jobs': [],
            'systemd_timers': [],
            'log_files': []
        }
        
        # Cron jobs
        result = self.run_command('crontab -l')
        if result['success']:
            env_info['cron_jobs'] = result['stdout'].split('\n')
        
        # Systemd timers
        result = self.run_command('systemctl list-timers --no-pager')
        if result['success']:
            env_info['systemd_timers'] = result['stdout'].split('\n')
        
        # Log files
        log_dirs = ['/var/log', '/var/log/audit']
        for log_dir in log_dirs:
            if os.path.exists(log_dir):
                for root, dirs, files in os.walk(log_dir):
                    for file in files:
                        if file.endswith('.log'):
                            env_info['log_files'].append(os.path.join(root, file))
        
        return env_info
    
    def save_data(self, data, filename):
        """Save collected data to JSON file"""
        output_file = self.output_dir / filename
        try:
            with open(output_file, 'w') as f:
                json.dump(data, f, indent=2, default=str)
            self.logger.info(f"Data saved to {output_file}")
            return True
        except Exception as e:
            self.logger.error(f"Error saving data to {output_file}: {e}")
            return False
    
    def collect_all(self):
        """Collect all CMDB data"""
        self.logger.info("Starting CMDB data collection")
        
        # Collect all data types
        data = {
            'metadata': {
                'collection_timestamp': self.collection_timestamp,
                'collector_version': '1.0.0',
                'hostname': socket.gethostname()
            },
            'system_info': self.collect_system_info(),
            'hardware_info': self.collect_hardware_info(),
            'software_info': self.collect_software_info(),
            'network_info': self.collect_network_info(),
            'security_info': self.collect_security_info(),
            'environment_info': self.collect_environment_info()
        }
        
        # Save complete dataset
        self.save_data(data, f"cmdb-data-{datetime.now().strftime('%Y%m%d-%H%M%S')}.json")
        
        # Save individual components
        for component, component_data in data.items():
            if component != 'metadata':
                self.save_data(component_data, f"{component}-{datetime.now().strftime('%Y%m%d-%H%M%S')}.json")
        
        self.logger.info("CMDB data collection completed")
        return data

def main():
    parser = argparse.ArgumentParser(description='CMDB Data Collector')
    parser.add_argument('--output-dir', default='/var/lib/cmdb/data',
                       help='Output directory for collected data')
    parser.add_argument('--component', choices=['system', 'hardware', 'software', 'network', 'security', 'environment'],
                       help='Collect specific component only')
    parser.add_argument('--format', choices=['json', 'yaml'], default='json',
                       help='Output format')
    
    args = parser.parse_args()
    
    collector = CMDBCollector(args.output_dir)
    
    if args.component:
        # Collect specific component
        method_name = f"collect_{args.component}_info"
        if hasattr(collector, method_name):
            data = getattr(collector, method_name)()
            collector.save_data(data, f"{args.component}-{datetime.now().strftime('%Y%m%d-%H%M%S')}.json")
        else:
            collector.logger.error(f"Unknown component: {args.component}")
            sys.exit(1)
    else:
        # Collect all data
        collector.collect_all()

if __name__ == '__main__':
    main()

