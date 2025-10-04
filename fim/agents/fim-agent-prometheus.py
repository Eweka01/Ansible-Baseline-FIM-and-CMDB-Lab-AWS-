#!/usr/bin/env python3
"""
File Integrity Monitoring (FIM) Agent with Prometheus Metrics
A lightweight Python-based FIM solution with Prometheus instrumentation
"""

import os
import sys
import json
import hashlib
import time
import logging
import argparse
from datetime import datetime
from pathlib import Path
import threading
import signal
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# Prometheus client imports
from prometheus_client import Counter, Gauge, Histogram, start_http_server, generate_latest
import http.server
import socketserver

class FIMAgent:
    def __init__(self, config_file='/etc/fim/fim-config.json', metrics_port=8080):
        self.config_file = config_file
        self.config = self.load_config()
        self.setup_logging()
        self.observer = Observer()
        self.running = False
        self.metrics_port = metrics_port
        
        # Prometheus metrics
        self.fim_events_total = Counter('fim_events_total', 'Total number of FIM events detected', ['event_type', 'path'])
        self.fim_files_monitored = Gauge('fim_files_monitored', 'Number of files currently being monitored')
        self.fim_directories_monitored = Gauge('fim_directories_monitored', 'Number of directories currently being monitored')
        self.fim_scan_duration = Histogram('fim_scan_duration_seconds', 'Time spent scanning files')
        self.fim_last_scan_time = Gauge('fim_last_scan_timestamp', 'Timestamp of last FIM scan')
        self.fim_agent_uptime = Gauge('fim_agent_uptime_seconds', 'FIM agent uptime in seconds')
        
        # Initialize metrics
        self.start_time = time.time()
        self.fim_files_monitored.set(0)
        self.fim_directories_monitored.set(0)
        
        # Setup signal handlers for graceful shutdown
        signal.signal(signal.SIGINT, self.signal_handler)
        signal.signal(signal.SIGTERM, self.signal_handler)
    
    def load_config(self):
        """Load FIM configuration from JSON file"""
        default_config = {
            "monitored_paths": [
                "/etc",
                "/usr/bin",
                "/usr/sbin",
                "/var/log",
                "/home",
                "/opt"
            ],
            "excluded_paths": [
                "/tmp",
                "/var/tmp",
                "/var/cache",
                "/var/log/*.log",
                "/proc",
                "/sys",
                "/dev"
            ],
            "log_file": "/var/log/fim-agent.log",
            "baseline_file": "/var/lib/fim/baseline.json",
            "report_file": "/var/log/fim-reports.json",
            "scan_interval": 300,  # 5 minutes
            "alert_threshold": 10
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
        log_file = self.config.get('log_file', '/var/log/fim-agent.log')
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
        self.logger = logging.getLogger('FIMAgent')
    
    def signal_handler(self, signum, frame):
        """Handle shutdown signals"""
        self.logger.info(f"Received signal {signum}, shutting down...")
        self.running = False
        self.observer.stop()
        self.observer.join()
        sys.exit(0)
    
    def calculate_file_hash(self, file_path):
        """Calculate SHA256 hash of a file"""
        try:
            hash_sha256 = hashlib.sha256()
            with open(file_path, "rb") as f:
                for chunk in iter(lambda: f.read(4096), b""):
                    hash_sha256.update(chunk)
            return hash_sha256.hexdigest()
        except Exception as e:
            self.logger.error(f"Error calculating hash for {file_path}: {e}")
            return None
    
    def is_excluded_path(self, path):
        """Check if path should be excluded from monitoring"""
        for excluded in self.config.get('excluded_paths', []):
            if excluded.endswith('*'):
                if path.startswith(excluded[:-1]):
                    return True
            elif path == excluded or path.startswith(excluded + '/'):
                return True
        return False
    
    def create_baseline(self):
        """Create initial baseline of monitored files"""
        baseline = {}
        monitored_paths = self.config.get('monitored_paths', [])
        
        self.logger.info("Creating FIM baseline...")
        
        for path in monitored_paths:
            if not os.path.exists(path):
                self.logger.warning(f"Monitored path does not exist: {path}")
                continue
                
            if os.path.isfile(path):
                # Single file
                if not self.is_excluded_path(path):
                    file_hash = self.calculate_file_hash(path)
                    if file_hash:
                        baseline[path] = {
                            'hash': file_hash,
                            'size': os.path.getsize(path),
                            'mtime': os.path.getmtime(path),
                            'type': 'file'
                        }
            else:
                # Directory
                for root, dirs, files in os.walk(path):
                    for file in files:
                        file_path = os.path.join(root, file)
                        if not self.is_excluded_path(file_path):
                            try:
                                file_hash = self.calculate_file_hash(file_path)
                                if file_hash:
                                    baseline[file_path] = {
                                        'hash': file_hash,
                                        'size': os.path.getsize(file_path),
                                        'mtime': os.path.getmtime(file_path),
                                        'type': 'file'
                                    }
                            except Exception as e:
                                self.logger.error(f"Error processing {file_path}: {e}")
        
        # Save baseline
        baseline_file = self.config.get('baseline_file', '/var/lib/fim/baseline.json')
        os.makedirs(os.path.dirname(baseline_file), exist_ok=True)
        
        with open(baseline_file, 'w') as f:
            json.dump(baseline, f, indent=2)
        
        self.logger.info(f"Baseline created with {len(baseline)} files")
        
        # Update Prometheus metrics
        self.fim_files_monitored.set(len(baseline))
        self.fim_directories_monitored.set(len(monitored_paths))
        
        return baseline
    
    def load_baseline(self):
        """Load existing baseline"""
        baseline_file = self.config.get('baseline_file', '/var/lib/fim/baseline.json')
        
        if os.path.exists(baseline_file):
            try:
                with open(baseline_file, 'r') as f:
                    baseline = json.load(f)
                self.logger.info(f"Loaded baseline with {len(baseline)} files")
                
                # Update Prometheus metrics
                self.fim_files_monitored.set(len(baseline))
                self.fim_directories_monitored.set(len(self.config.get('monitored_paths', [])))
                
                return baseline
            except Exception as e:
                self.logger.error(f"Error loading baseline: {e}")
                return {}
        else:
            self.logger.info("No baseline found, creating new one...")
            return self.create_baseline()
    
    def scan_files(self):
        """Perform FIM scan and detect changes"""
        with self.fim_scan_duration.time():
            baseline = self.load_baseline()
            changes = []
            new_files = []
            deleted_files = []
            modified_files = []
            
            monitored_paths = self.config.get('monitored_paths', [])
            
            for path in monitored_paths:
                if not os.path.exists(path):
                    continue
                    
                if os.path.isfile(path):
                    # Single file
                    if not self.is_excluded_path(path):
                        self.check_file(path, baseline, changes, new_files, modified_files)
                else:
                    # Directory
                    for root, dirs, files in os.walk(path):
                        for file in files:
                            file_path = os.path.join(root, file)
                            if not self.is_excluded_path(file_path):
                                self.check_file(file_path, baseline, changes, new_files, modified_files)
            
            # Check for deleted files
            for file_path in baseline:
                if not os.path.exists(file_path):
                    deleted_files.append(file_path)
                    changes.append({
                        'type': 'DELETED',
                        'path': file_path,
                        'timestamp': datetime.now().isoformat()
                    })
            
            # Update Prometheus metrics
            self.fim_events_total.labels(event_type='new', path='total').inc(len(new_files))
            self.fim_events_total.labels(event_type='modified', path='total').inc(len(modified_files))
            self.fim_events_total.labels(event_type='deleted', path='total').inc(len(deleted_files))
            
            self.fim_last_scan_time.set(time.time())
            
            if changes:
                self.logger.warning(f"FIM detected {len(changes)} changes:")
                for change in changes:
                    self.logger.warning(f"  {change['type']}: {change['path']}")
                    # Update specific path metrics
                    self.fim_events_total.labels(event_type=change['type'].lower(), path=change['path']).inc()
                
                if len(changes) >= self.config.get('alert_threshold', 10):
                    self.logger.critical(f"FIM Alert: {len(changes)} file changes detected")
                
                self.save_report(changes)
                self.update_baseline()
            
            self.logger.info(f"FIM scan completed. Scanned {len(baseline)} files")
    
    def check_file(self, file_path, baseline, changes, new_files, modified_files):
        """Check individual file for changes"""
        try:
            if file_path in baseline:
                # Existing file - check for modifications
                current_hash = self.calculate_file_hash(file_path)
                if current_hash and current_hash != baseline[file_path]['hash']:
                    modified_files.append(file_path)
                    changes.append({
                        'type': 'MODIFIED',
                        'path': file_path,
                        'old_hash': baseline[file_path]['hash'],
                        'new_hash': current_hash,
                        'timestamp': datetime.now().isoformat()
                    })
            else:
                # New file
                file_hash = self.calculate_file_hash(file_path)
                if file_hash:
                    new_files.append(file_path)
                    changes.append({
                        'type': 'NEW',
                        'path': file_path,
                        'hash': file_hash,
                        'timestamp': datetime.now().isoformat()
                    })
        except Exception as e:
            self.logger.error(f"Error checking file {file_path}: {e}")
    
    def save_report(self, changes):
        """Save FIM report"""
        report_file = self.config.get('report_file', '/var/log/fim-reports.json')
        
        report = {
            'timestamp': datetime.now().isoformat(),
            'changes': changes,
            'total_changes': len(changes)
        }
        
        try:
            with open(report_file, 'w') as f:
                json.dump(report, f, indent=2)
        except Exception as e:
            self.logger.error(f"Error saving report: {e}")
    
    def update_baseline(self):
        """Update baseline after changes detected"""
        self.logger.info("Updating baseline...")
        baseline = self.create_baseline()
        self.logger.info("Baseline updated")
    
    def start_metrics_server(self):
        """Start Prometheus metrics HTTP server"""
        try:
            start_http_server(self.metrics_port)
            self.logger.info(f"Prometheus metrics server started on port {self.metrics_port}")
        except Exception as e:
            self.logger.error(f"Failed to start metrics server: {e}")
    
    def run(self):
        """Main FIM agent loop"""
        self.logger.info("Starting FIM Agent with Prometheus metrics...")
        
        # Start metrics server
        self.start_metrics_server()
        
        # Create initial baseline
        self.create_baseline()
        
        self.running = True
        scan_interval = self.config.get('scan_interval', 300)
        
        while self.running:
            try:
                # Update uptime metric
                self.fim_agent_uptime.set(time.time() - self.start_time)
                
                # Perform FIM scan
                self.scan_files()
                
                # Wait for next scan
                time.sleep(scan_interval)
                
            except KeyboardInterrupt:
                self.logger.info("Received keyboard interrupt, shutting down...")
                break
            except Exception as e:
                self.logger.error(f"Error in main loop: {e}")
                time.sleep(60)  # Wait before retrying
        
        self.logger.info("FIM Agent stopped")

def main():
    parser = argparse.ArgumentParser(description='FIM Agent with Prometheus Metrics')
    parser.add_argument('--config', default='/etc/fim/fim-config.json', help='Configuration file path')
    parser.add_argument('--metrics-port', type=int, default=8080, help='Prometheus metrics port')
    parser.add_argument('--scan-once', action='store_true', help='Run single scan and exit')
    
    args = parser.parse_args()
    
    agent = FIMAgent(args.config, args.metrics_port)
    
    if args.scan_once:
        agent.scan_files()
    else:
        agent.run()

if __name__ == '__main__':
    main()
