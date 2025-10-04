#!/usr/bin/env python3
"""
Configuration Management Database (CMDB) Collector with Prometheus Metrics
Collects system information and exposes Prometheus metrics
"""

import os
import sys
import json
import time
import logging
import argparse
import subprocess
import platform
import psutil
from datetime import datetime
from pathlib import Path

# Prometheus client imports
from prometheus_client import Counter, Gauge, Histogram, start_http_server, generate_latest

class CMDBCollector:
    def __init__(self, config_file='/etc/cmdb/cmdb-config.json', metrics_port=8081):
        self.config_file = config_file
        self.config = self.load_config()
        self.setup_logging()
        self.metrics_port = metrics_port
        
        # Prometheus metrics
        self.cmdb_collections_total = Counter('cmdb_collections_total', 'Total number of CMDB data collections')
        self.cmdb_collection_duration = Histogram('cmdb_collection_duration_seconds', 'Time spent collecting CMDB data')
        self.cmdb_last_collection_time = Gauge('cmdb_last_collection_timestamp', 'Timestamp of last CMDB collection')
        self.cmdb_agent_uptime = Gauge('cmdb_agent_uptime_seconds', 'CMDB agent uptime in seconds')
        
        # System metrics
        self.system_cpu_cores = Gauge('system_cpu_cores', 'Number of CPU cores')
        self.system_memory_total = Gauge('system_memory_total_bytes', 'Total system memory in bytes')
        self.system_disk_total = Gauge('system_disk_total_bytes', 'Total disk space in bytes')
        self.system_uptime = Gauge('system_uptime_seconds', 'System uptime in seconds')
        self.system_processes = Gauge('system_processes_total', 'Total number of processes')
        self.system_users = Gauge('system_users_total', 'Total number of users')
        self.system_packages = Gauge('system_packages_total', 'Total number of installed packages')
        
        # Initialize metrics
        self.start_time = time.time()
    
    def load_config(self):
        """Load CMDB configuration from JSON file"""
        default_config = {
            "data_directory": "/var/lib/cmdb/data",
            "log_file": "/var/log/cmdb-collector.log",
            "collection_interval": 3600,  # 1 hour
            "retention_days": 30
        }
        
        try:
            if os.path.exists(self.config_file):
                with open(self.config_file, 'r') as f:
                    config = json.load(f)
                    # Merge with defaults
                    for key, value in default_config.items():
                        if key not in config:
                            config[key] = value
                    return config
            else:
                # Create config directory if it doesn't exist
                os.makedirs(os.path.dirname(self.config_file), exist_ok=True)
                with open(self.config_file, 'w') as f:
                    json.dump(default_config, f, indent=2)
                return default_config
        except Exception as e:
            print(f"Error loading config: {e}")
            return default_config
    
    def setup_logging(self):
        """Setup logging configuration"""
        log_file = self.config.get('log_file', '/var/log/cmdb-collector.log')
        log_dir = os.path.dirname(log_file)
        os.makedirs(log_dir, exist_ok=True)
        
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger('CMDBCollector')
    
    def collect_system_info(self):
        """Collect system information"""
        system_info = {
            'hostname': platform.node(),
            'os': platform.system(),
            'os_version': platform.release(),
            'architecture': platform.machine(),
            'processor': platform.processor(),
            'python_version': platform.python_version(),
            'timestamp': datetime.now().isoformat()
        }
        
        # CPU information
        system_info['cpu_cores'] = psutil.cpu_count()
        system_info['cpu_freq'] = psutil.cpu_freq()._asdict() if psutil.cpu_freq() else {}
        
        # Memory information
        memory = psutil.virtual_memory()
        system_info['memory'] = {
            'total': memory.total,
            'available': memory.available,
            'used': memory.used,
            'free': memory.free,
            'percent': memory.percent
        }
        
        # Disk information
        disk = psutil.disk_usage('/')
        system_info['disk'] = {
            'total': disk.total,
            'used': disk.used,
            'free': disk.free,
            'percent': (disk.used / disk.total) * 100
        }
        
        # System uptime
        boot_time = psutil.boot_time()
        system_info['uptime'] = time.time() - boot_time
        
        # Process information
        system_info['processes'] = len(psutil.pids())
        
        # User information
        system_info['users'] = len(psutil.users())
        
        # Update Prometheus metrics
        self.system_cpu_cores.set(system_info['cpu_cores'])
        self.system_memory_total.set(system_info['memory']['total'])
        self.system_disk_total.set(system_info['disk']['total'])
        self.system_uptime.set(system_info['uptime'])
        self.system_processes.set(system_info['processes'])
        self.system_users.set(system_info['users'])
        
        return system_info
    
    def collect_hardware_info(self):
        """Collect hardware information"""
        hardware_info = {
            'timestamp': datetime.now().isoformat()
        }
        
        try:
            # CPU information
            with open('/proc/cpuinfo', 'r') as f:
                cpu_info = f.read()
                hardware_info['cpu_info'] = cpu_info
            
            # Memory information
            with open('/proc/meminfo', 'r') as f:
                mem_info = f.read()
                hardware_info['memory_info'] = mem_info
            
            # Disk information
            result = subprocess.run(['lsblk', '-J'], capture_output=True, text=True)
            if result.returncode == 0:
                hardware_info['disk_info'] = json.loads(result.stdout)
            
            # Network interfaces
            result = subprocess.run(['ip', 'addr', 'show'], capture_output=True, text=True)
            if result.returncode == 0:
                hardware_info['network_info'] = result.stdout
            
        except Exception as e:
            self.logger.error(f"Error collecting hardware info: {e}")
            hardware_info['error'] = str(e)
        
        return hardware_info
    
    def collect_software_info(self):
        """Collect software information"""
        software_info = {
            'timestamp': datetime.now().isoformat()
        }
        
        try:
            # Check if it's Ubuntu/Debian
            if os.path.exists('/usr/bin/dpkg'):
                result = subprocess.run(['dpkg', '-l'], capture_output=True, text=True)
                if result.returncode == 0:
                    packages = []
                    for line in result.stdout.split('\n'):
                        if line.startswith('ii'):
                            parts = line.split()
                            if len(parts) >= 3:
                                packages.append({
                                    'name': parts[1],
                                    'version': parts[2],
                                    'description': ' '.join(parts[3:]) if len(parts) > 3 else ''
                                })
                    software_info['packages'] = packages
                    software_info['package_count'] = len(packages)
                    
                    # Update Prometheus metric
                    self.system_packages.set(len(packages))
            
            # Check if it's Amazon Linux/RHEL/CentOS
            elif os.path.exists('/usr/bin/rpm'):
                result = subprocess.run(['rpm', '-qa'], capture_output=True, text=True)
                if result.returncode == 0:
                    packages = []
                    for line in result.stdout.split('\n'):
                        if line.strip():
                            packages.append(line.strip())
                    software_info['packages'] = packages
                    software_info['package_count'] = len(packages)
                    
                    # Update Prometheus metric
                    self.system_packages.set(len(packages))
            
            # Python packages
            result = subprocess.run(['pip', 'list', '--format=json'], capture_output=True, text=True)
            if result.returncode == 0:
                try:
                    python_packages = json.loads(result.stdout)
                    software_info['python_packages'] = python_packages
                except json.JSONDecodeError:
                    pass
            
        except Exception as e:
            self.logger.error(f"Error collecting software info: {e}")
            software_info['error'] = str(e)
        
        return software_info
    
    def collect_network_info(self):
        """Collect network information"""
        network_info = {
            'timestamp': datetime.now().isoformat()
        }
        
        try:
            # Network interfaces
            network_info['interfaces'] = {}
            for interface, addrs in psutil.net_if_addrs().items():
                network_info['interfaces'][interface] = []
                for addr in addrs:
                    network_info['interfaces'][interface].append({
                        'family': str(addr.family),
                        'address': addr.address,
                        'netmask': addr.netmask,
                        'broadcast': addr.broadcast
                    })
            
            # Network statistics
            network_info['stats'] = psutil.net_io_counters()._asdict()
            
        except Exception as e:
            self.logger.error(f"Error collecting network info: {e}")
            network_info['error'] = str(e)
        
        return network_info
    
    def collect_process_info(self):
        """Collect process information"""
        process_info = {
            'timestamp': datetime.now().isoformat(),
            'processes': []
        }
        
        try:
            for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent', 'status']):
                try:
                    process_info['processes'].append(proc.info)
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    pass
        except Exception as e:
            self.logger.error(f"Error collecting process info: {e}")
            process_info['error'] = str(e)
        
        return process_info
    
    def save_data(self, data_type, data):
        """Save collected data to file"""
        data_dir = self.config.get('data_directory', '/var/lib/cmdb/data')
        os.makedirs(data_dir, exist_ok=True)
        
        timestamp = datetime.now().strftime('%Y%m%d-%H%M%S')
        filename = f"{data_type}-{timestamp}.json"
        filepath = os.path.join(data_dir, filename)
        
        try:
            with open(filepath, 'w') as f:
                json.dump(data, f, indent=2)
            self.logger.info(f"Saved {data_type} data to {filepath}")
        except Exception as e:
            self.logger.error(f"Error saving {data_type} data: {e}")
    
    def start_metrics_server(self):
        """Start Prometheus metrics HTTP server"""
        try:
            start_http_server(self.metrics_port)
            self.logger.info(f"Prometheus metrics server started on port {self.metrics_port}")
        except Exception as e:
            self.logger.error(f"Failed to start metrics server: {e}")
    
    def collect_all_data(self):
        """Collect all CMDB data"""
        with self.cmdb_collection_duration.time():
            self.logger.info("Starting CMDB data collection...")
            
            # Collect system information
            system_info = self.collect_system_info()
            self.save_data('system_info', system_info)
            
            # Collect hardware information
            hardware_info = self.collect_hardware_info()
            self.save_data('hardware_info', hardware_info)
            
            # Collect software information
            software_info = self.collect_software_info()
            self.save_data('software_info', software_info)
            
            # Collect network information
            network_info = self.collect_network_info()
            self.save_data('network_info', network_info)
            
            # Collect process information
            process_info = self.collect_process_info()
            self.save_data('process_info', process_info)
            
            # Update Prometheus metrics
            self.cmdb_collections_total.inc()
            self.cmdb_last_collection_time.set(time.time())
            
            self.logger.info("CMDB data collection completed")
    
    def run(self):
        """Main CMDB collector loop"""
        self.logger.info("Starting CMDB Collector with Prometheus metrics...")
        
        # Start metrics server
        self.start_metrics_server()
        
        # Initial collection
        self.collect_all_data()
        
        collection_interval = self.config.get('collection_interval', 3600)
        
        while True:
            try:
                # Update uptime metric
                self.cmdb_agent_uptime.set(time.time() - self.start_time)
                
                # Wait for next collection
                time.sleep(collection_interval)
                
                # Perform data collection
                self.collect_all_data()
                
            except KeyboardInterrupt:
                self.logger.info("Received keyboard interrupt, shutting down...")
                break
            except Exception as e:
                self.logger.error(f"Error in main loop: {e}")
                time.sleep(60)  # Wait before retrying

def main():
    parser = argparse.ArgumentParser(description='CMDB Collector with Prometheus Metrics')
    parser.add_argument('--config', default='/etc/cmdb/cmdb-config.json', help='Configuration file path')
    parser.add_argument('--metrics-port', type=int, default=8081, help='Prometheus metrics port')
    parser.add_argument('--collect-once', action='store_true', help='Run single collection and exit')
    
    args = parser.parse_args()
    
    collector = CMDBCollector(args.config, args.metrics_port)
    
    if args.collect_once:
        collector.collect_all_data()
    else:
        collector.run()

if __name__ == '__main__':
    main()
