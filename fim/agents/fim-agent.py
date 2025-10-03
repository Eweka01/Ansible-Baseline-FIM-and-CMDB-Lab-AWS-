#!/usr/bin/env python3
"""
File Integrity Monitoring (FIM) Agent
A lightweight Python-based FIM solution for the lab environment
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

class FIMAgent:
    def __init__(self, config_file='/etc/fim/fim-config.json'):
        self.config_file = config_file
        self.config = self.load_config()
        self.setup_logging()
        self.observer = Observer()
        self.running = False
        
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
            "scan_interval": 300,  # 5 minutes
            "report_interval": 3600,  # 1 hour
            "alert_on_change": True,
            "log_file": "/var/log/fim-agent.log",
            "report_file": "/var/log/fim-reports.json",
            "hash_algorithm": "sha256"
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
                return default_config
        except Exception as e:
            print(f"Error loading config: {e}")
            return default_config
    
    def setup_logging(self):
        """Setup logging configuration"""
        log_level = logging.INFO
        log_format = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        
        logging.basicConfig(
            level=log_level,
            format=log_format,
            handlers=[
                logging.FileHandler(self.config['log_file']),
                logging.StreamHandler(sys.stdout)
            ]
        )
        self.logger = logging.getLogger('FIMAgent')
    
    def calculate_file_hash(self, file_path):
        """Calculate hash of a file"""
        try:
            hash_obj = hashlib.new(self.config['hash_algorithm'])
            with open(file_path, 'rb') as f:
                for chunk in iter(lambda: f.read(4096), b""):
                    hash_obj.update(chunk)
            return hash_obj.hexdigest()
        except Exception as e:
            self.logger.error(f"Error calculating hash for {file_path}: {e}")
            return None
    
    def should_monitor_path(self, path):
        """Check if a path should be monitored based on inclusion/exclusion rules"""
        path_str = str(path)
        
        # Check exclusions first
        for excluded in self.config['excluded_paths']:
            if excluded.endswith('*'):
                # Wildcard pattern
                if path_str.startswith(excluded[:-1]):
                    return False
            else:
                # Exact match
                if path_str == excluded or path_str.startswith(excluded + '/'):
                    return False
        
        # Check inclusions
        for included in self.config['monitored_paths']:
            if path_str.startswith(included):
                return True
        
        return False
    
    def scan_directory(self, directory):
        """Perform initial scan of a directory"""
        self.logger.info(f"Scanning directory: {directory}")
        file_hashes = {}
        
        try:
            for root, dirs, files in os.walk(directory):
                for file in files:
                    file_path = os.path.join(root, file)
                    if self.should_monitor_path(file_path):
                        file_hash = self.calculate_file_hash(file_path)
                        if file_hash:
                            file_hashes[file_path] = {
                                'hash': file_hash,
                                'size': os.path.getsize(file_path),
                                'mtime': os.path.getmtime(file_path),
                                'scanned_at': datetime.now().isoformat()
                            }
        except Exception as e:
            self.logger.error(f"Error scanning {directory}: {e}")
        
        return file_hashes
    
    def save_baseline(self, baseline_data):
        """Save baseline file hashes"""
        baseline_file = '/var/lib/fim/baseline.json'
        os.makedirs(os.path.dirname(baseline_file), exist_ok=True)
        
        try:
            with open(baseline_file, 'w') as f:
                json.dump(baseline_data, f, indent=2)
            self.logger.info(f"Baseline saved to {baseline_file}")
        except Exception as e:
            self.logger.error(f"Error saving baseline: {e}")
    
    def load_baseline(self):
        """Load baseline file hashes"""
        baseline_file = '/var/lib/fim/baseline.json'
        
        try:
            if os.path.exists(baseline_file):
                with open(baseline_file, 'r') as f:
                    return json.load(f)
        except Exception as e:
            self.logger.error(f"Error loading baseline: {e}")
        
        return {}
    
    def compare_with_baseline(self, current_hashes):
        """Compare current file hashes with baseline"""
        baseline = self.load_baseline()
        changes = []
        
        # Check for modified files
        for file_path, current_info in current_hashes.items():
            if file_path in baseline:
                baseline_info = baseline[file_path]
                if current_info['hash'] != baseline_info['hash']:
                    changes.append({
                        'type': 'modified',
                        'file': file_path,
                        'old_hash': baseline_info['hash'],
                        'new_hash': current_info['hash'],
                        'timestamp': datetime.now().isoformat()
                    })
            else:
                changes.append({
                    'type': 'new',
                    'file': file_path,
                    'hash': current_info['hash'],
                    'timestamp': datetime.now().isoformat()
                })
        
        # Check for deleted files
        for file_path in baseline:
            if file_path not in current_hashes:
                changes.append({
                    'type': 'deleted',
                    'file': file_path,
                    'old_hash': baseline[file_path]['hash'],
                    'timestamp': datetime.now().isoformat()
                })
        
        return changes
    
    def report_changes(self, changes):
        """Report detected changes"""
        if not changes:
            return
        
        self.logger.warning(f"FIM detected {len(changes)} changes:")
        for change in changes:
            self.logger.warning(f"  {change['type'].upper()}: {change['file']}")
        
        # Save report
        report_file = self.config['report_file']
        try:
            report_data = {
                'timestamp': datetime.now().isoformat(),
                'changes': changes,
                'total_changes': len(changes)
            }
            
            # Append to existing reports
            reports = []
            if os.path.exists(report_file):
                with open(report_file, 'r') as f:
                    reports = json.load(f)
            
            reports.append(report_data)
            
            with open(report_file, 'w') as f:
                json.dump(reports, f, indent=2)
                
        except Exception as e:
            self.logger.error(f"Error saving report: {e}")
    
    def perform_scan(self):
        """Perform a complete scan of all monitored paths"""
        self.logger.info("Starting FIM scan")
        all_hashes = {}
        
        for path in self.config['monitored_paths']:
            if os.path.exists(path):
                path_hashes = self.scan_directory(path)
                all_hashes.update(path_hashes)
            else:
                self.logger.warning(f"Monitored path does not exist: {path}")
        
        # Compare with baseline
        changes = self.compare_with_baseline(all_hashes)
        
        if changes:
            self.report_changes(changes)
            if self.config['alert_on_change']:
                self.send_alert(changes)
        
        # Update baseline
        self.save_baseline(all_hashes)
        self.logger.info(f"FIM scan completed. Scanned {len(all_hashes)} files")
    
    def send_alert(self, changes):
        """Send alert about detected changes"""
        # Simple alert implementation - can be extended
        alert_message = f"FIM Alert: {len(changes)} file changes detected"
        self.logger.critical(alert_message)
        
        # Could integrate with email, Slack, etc.
        # For now, just log critical level
    
    def signal_handler(self, signum, frame):
        """Handle shutdown signals"""
        self.logger.info(f"Received signal {signum}, shutting down...")
        self.running = False
        self.observer.stop()
    
    def run(self):
        """Main execution loop"""
        self.logger.info("Starting FIM Agent")
        self.running = True
        
        # Perform initial scan
        self.perform_scan()
        
        # Start periodic scanning
        while self.running:
            time.sleep(self.config['scan_interval'])
            if self.running:
                self.perform_scan()

def main():
    parser = argparse.ArgumentParser(description='File Integrity Monitoring Agent')
    parser.add_argument('--config', default='/etc/fim/fim-config.json',
                       help='Configuration file path')
    parser.add_argument('--scan-once', action='store_true',
                       help='Perform single scan and exit')
    parser.add_argument('--init-baseline', action='store_true',
                       help='Initialize baseline and exit')
    
    args = parser.parse_args()
    
    agent = FIMAgent(args.config)
    
    if args.init_baseline:
        agent.perform_scan()
        agent.logger.info("Baseline initialized")
        return
    
    if args.scan_once:
        agent.perform_scan()
        return
    
    # Run continuously
    try:
        agent.run()
    except KeyboardInterrupt:
        agent.logger.info("Shutdown requested by user")
    except Exception as e:
        agent.logger.error(f"Fatal error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()

