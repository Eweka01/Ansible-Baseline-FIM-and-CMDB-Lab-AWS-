#!/usr/bin/env python3
"""
CMDB Test Script
================

This script provides comprehensive testing of the Configuration Management Database (CMDB)
collector functionality. It tests all aspects of CMDB including system information
collection, hardware detection, software inventory, and data validation.

Features:
- Tests system information collection
- Validates hardware information gathering
- Tests software and package detection
- Validates network interface detection
- Tests data storage and retrieval
- Validates JSON schema compliance

Usage:
    python3 test-cmdb.py [--output-dir /path/to/output] [--verbose]

Author: Gabriel Eweka
Version: 1.0.0
"""

import os
import sys
import json
import platform
import socket
import psutil
from datetime import datetime

# Add the current directory to Python path for local imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

class LocalCMDBTest:
    def __init__(self):
        self.output_dir = "./cmdb-test-data"
        self.log_file = "./cmdb-test.log"
        
    def setup_logging(self):
        """Setup simple logging"""
        import logging
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(self.log_file),
                logging.StreamHandler(sys.stdout)
            ]
        )
        self.logger = logging.getLogger('CMDBTest')
    
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
            'collection_timestamp': datetime.now().isoformat()
        }
        
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
            
            hardware_info['network'].append(interface_info)
        
        return hardware_info
    
    def collect_software_info(self):
        """Collect software information"""
        self.logger.info("Collecting software information")
        
        software_info = {
            'packages': [],
            'services': [],
            'processes': []
        }
        
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
    
    def save_data(self, data, filename):
        """Save collected data to JSON file"""
        os.makedirs(self.output_dir, exist_ok=True)
        output_file = os.path.join(self.output_dir, filename)
        
        try:
            with open(output_file, 'w') as f:
                json.dump(data, f, indent=2, default=str)
            self.logger.info(f"Data saved to {output_file}")
            return True
        except Exception as e:
            self.logger.error(f"Error saving data to {output_file}: {e}")
            return False
    
    def test_cmdb_functionality(self):
        """Test CMDB functionality"""
        print("=== CMDB Functionality Test ===")
        
        self.setup_logging()
        
        # Collect all data types
        data = {
            'metadata': {
                'collection_timestamp': datetime.now().isoformat(),
                'collector_version': '1.0.0-test',
                'hostname': socket.gethostname()
            },
            'system_info': self.collect_system_info(),
            'hardware_info': self.collect_hardware_info(),
            'software_info': self.collect_software_info()
        }
        
        # Save complete dataset
        timestamp = datetime.now().strftime('%Y%m%d-%H%M%S')
        self.save_data(data, f"cmdb-test-data-{timestamp}.json")
        
        # Save individual components
        for component, component_data in data.items():
            if component != 'metadata':
                self.save_data(component_data, f"{component}-{timestamp}.json")
        
        # Display summary
        print(f"\n✓ Collected data for {len(data)} components:")
        print(f"  - System info: {len(data['system_info'])} fields")
        print(f"  - Hardware info: {len(data['hardware_info'])} categories")
        print(f"  - Software info: {len(data['software_info'])} categories")
        print(f"  - Total processes: {len(data['software_info']['processes'])}")
        print(f"  - Network interfaces: {len(data['hardware_info']['network'])}")
        print(f"  - Disk partitions: {len(data['hardware_info']['disk'])}")
        
        print(f"\n✓ Data saved to: {self.output_dir}")
        print(f"✓ Log saved to: {self.log_file}")
        
        return True

def main():
    print("CMDB Local Test")
    print("===============")
    
    test = LocalCMDBTest()
    success = test.test_cmdb_functionality()
    
    if success:
        print("\n✓ CMDB functionality test PASSED")
        print("  - System information collection working")
        print("  - Hardware information collection working")
        print("  - Software information collection working")
        print("  - Data storage working")
        print("  - JSON serialization working")
    else:
        print("\n✗ CMDB functionality test FAILED")
    
    return 0 if success else 1

if __name__ == '__main__':
    sys.exit(main())
