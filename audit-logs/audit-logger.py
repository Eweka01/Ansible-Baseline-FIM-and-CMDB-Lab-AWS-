#!/usr/bin/env python3
"""
Audit Logger for Automated Drift Detection and Remediation
Tracks all changes, alerts, and remediation actions

Author: Gabriel Eweka
Date: October 6, 2025
"""

import json
import logging
import os
import sys
from datetime import datetime
from pathlib import Path
import hashlib
import subprocess

class AuditLogger:
    """Comprehensive audit logging system"""
    
    def __init__(self, log_dir="/var/log/audit"):
        self.log_dir = Path(log_dir)
        self.log_dir.mkdir(exist_ok=True)
        
        # Set up logging
        self.setup_logging()
        
        # Audit log files
        self.audit_log = self.log_dir / "audit.log"
        self.change_log = self.log_dir / "changes.log"
        self.remediation_log = self.log_dir / "remediation.log"
        self.security_log = self.log_dir / "security.log"
        
    def setup_logging(self):
        """Set up logging configuration"""
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(self.log_dir / 'audit.log'),
                logging.StreamHandler(sys.stdout)
            ]
        )
        self.logger = logging.getLogger(__name__)
    
    def log_change(self, change_type, file_path, old_hash=None, new_hash=None, 
                   user=None, process=None, details=None):
        """Log a configuration change"""
        change_entry = {
            'timestamp': datetime.now().isoformat(),
            'type': change_type,
            'file_path': file_path,
            'old_hash': old_hash,
            'new_hash': new_hash,
            'user': user or 'unknown',
            'process': process or 'unknown',
            'details': details or {}
        }
        
        # Write to change log
        with open(self.change_log, 'a') as f:
            f.write(json.dumps(change_entry) + '\n')
        
        # Write to audit log
        with open(self.audit_log, 'a') as f:
            f.write(json.dumps(change_entry) + '\n')
        
        self.logger.info(f"Change logged: {change_type} - {file_path}")
    
    def log_alert(self, alert_name, alert_state, instance, severity, 
                  description=None, remediation_triggered=False):
        """Log a Prometheus alert"""
        alert_entry = {
            'timestamp': datetime.now().isoformat(),
            'type': 'alert',
            'alert_name': alert_name,
            'alert_state': alert_state,
            'instance': instance,
            'severity': severity,
            'description': description,
            'remediation_triggered': remediation_triggered
        }
        
        # Write to audit log
        with open(self.audit_log, 'a') as f:
            f.write(json.dumps(alert_entry) + '\n')
        
        self.logger.info(f"Alert logged: {alert_name} - {alert_state} - {instance}")
    
    def log_remediation(self, remediation_type, target_node, playbook_name, 
                       return_code, details=None):
        """Log a remediation action"""
        remediation_entry = {
            'timestamp': datetime.now().isoformat(),
            'type': 'remediation',
            'remediation_type': remediation_type,
            'target_node': target_node,
            'playbook_name': playbook_name,
            'return_code': return_code,
            'status': 'success' if return_code == 0 else 'failed',
            'details': details or {}
        }
        
        # Write to remediation log
        with open(self.remediation_log, 'a') as f:
            f.write(json.dumps(remediation_entry) + '\n')
        
        # Write to audit log
        with open(self.audit_log, 'a') as f:
            f.write(json.dumps(remediation_entry) + '\n')
        
        self.logger.info(f"Remediation logged: {remediation_type} - {target_node} - {playbook_name}")
    
    def log_security_event(self, event_type, severity, description, 
                          source_ip=None, user=None, details=None):
        """Log a security event"""
        security_entry = {
            'timestamp': datetime.now().isoformat(),
            'type': 'security_event',
            'event_type': event_type,
            'severity': severity,
            'description': description,
            'source_ip': source_ip,
            'user': user,
            'details': details or {}
        }
        
        # Write to security log
        with open(self.security_log, 'a') as f:
            f.write(json.dumps(security_entry) + '\n')
        
        # Write to audit log
        with open(self.audit_log, 'a') as f:
            f.write(json.dumps(security_entry) + '\n')
        
        self.logger.info(f"Security event logged: {event_type} - {severity} - {description}")
    
    def calculate_file_hash(self, file_path):
        """Calculate SHA-256 hash of a file"""
        try:
            with open(file_path, 'rb') as f:
                return hashlib.sha256(f.read()).hexdigest()
        except Exception as e:
            self.logger.error(f"Error calculating hash for {file_path}: {str(e)}")
            return None
    
    def get_file_metadata(self, file_path):
        """Get file metadata"""
        try:
            stat = os.stat(file_path)
            return {
                'size': stat.st_size,
                'mtime': datetime.fromtimestamp(stat.st_mtime).isoformat(),
                'ctime': datetime.fromtimestamp(stat.st_ctime).isoformat(),
                'mode': oct(stat.st_mode),
                'uid': stat.st_uid,
                'gid': stat.st_gid
            }
        except Exception as e:
            self.logger.error(f"Error getting metadata for {file_path}: {str(e)}")
            return None
    
    def log_file_change(self, file_path, change_type='modified'):
        """Log a file change with full metadata"""
        old_hash = None
        new_hash = self.calculate_file_hash(file_path)
        metadata = self.get_file_metadata(file_path)
        
        # Try to get old hash from previous log entry
        try:
            with open(self.change_log, 'r') as f:
                for line in reversed(f.readlines()):
                    entry = json.loads(line.strip())
                    if entry.get('file_path') == file_path:
                        old_hash = entry.get('new_hash')
                        break
        except:
            pass
        
        self.log_change(
            change_type=change_type,
            file_path=file_path,
            old_hash=old_hash,
            new_hash=new_hash,
            details={'metadata': metadata}
        )
    
    def generate_audit_report(self, start_date=None, end_date=None, 
                            event_types=None, severity_levels=None):
        """Generate an audit report"""
        report = {
            'generated_at': datetime.now().isoformat(),
            'start_date': start_date,
            'end_date': end_date,
            'event_types': event_types,
            'severity_levels': severity_levels,
            'summary': {},
            'events': []
        }
        
        # Read audit log
        try:
            with open(self.audit_log, 'r') as f:
                for line in f:
                    entry = json.loads(line.strip())
                    
                    # Filter by date range
                    if start_date and entry['timestamp'] < start_date:
                        continue
                    if end_date and entry['timestamp'] > end_date:
                        continue
                    
                    # Filter by event types
                    if event_types and entry.get('type') not in event_types:
                        continue
                    
                    # Filter by severity
                    if severity_levels and entry.get('severity') not in severity_levels:
                        continue
                    
                    report['events'].append(entry)
        except Exception as e:
            self.logger.error(f"Error generating audit report: {str(e)}")
            return None
        
        # Generate summary
        event_counts = {}
        for event in report['events']:
            event_type = event.get('type', 'unknown')
            event_counts[event_type] = event_counts.get(event_type, 0) + 1
        
        report['summary'] = {
            'total_events': len(report['events']),
            'event_counts': event_counts
        }
        
        return report
    
    def export_audit_log(self, output_file, start_date=None, end_date=None):
        """Export audit log to file"""
        try:
            with open(self.audit_log, 'r') as f_in, open(output_file, 'w') as f_out:
                for line in f_in:
                    entry = json.loads(line.strip())
                    
                    # Filter by date range
                    if start_date and entry['timestamp'] < start_date:
                        continue
                    if end_date and entry['timestamp'] > end_date:
                        continue
                    
                    f_out.write(line)
            
            self.logger.info(f"Audit log exported to {output_file}")
            return True
        except Exception as e:
            self.logger.error(f"Error exporting audit log: {str(e)}")
            return False
    
    def cleanup_old_logs(self, days_to_keep=30):
        """Clean up old log entries"""
        cutoff_date = datetime.now().timestamp() - (days_to_keep * 24 * 60 * 60)
        
        for log_file in [self.audit_log, self.change_log, self.remediation_log, self.security_log]:
            if log_file.exists():
                try:
                    # Read all entries
                    entries = []
                    with open(log_file, 'r') as f:
                        for line in f:
                            entry = json.loads(line.strip())
                            entry_date = datetime.fromisoformat(entry['timestamp']).timestamp()
                            if entry_date > cutoff_date:
                                entries.append(line)
                    
                    # Write back filtered entries
                    with open(log_file, 'w') as f:
                        f.writelines(entries)
                    
                    self.logger.info(f"Cleaned up old entries from {log_file}")
                except Exception as e:
                    self.logger.error(f"Error cleaning up {log_file}: {str(e)}")

def main():
    """Main function for command-line usage"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Audit Logger')
    parser.add_argument('--log-dir', default='/var/log/audit', help='Log directory')
    parser.add_argument('--action', choices=['log-change', 'log-alert', 'log-remediation', 
                                           'log-security', 'generate-report', 'export', 'cleanup'],
                       required=True, help='Action to perform')
    parser.add_argument('--file', help='File path for change logging')
    parser.add_argument('--alert-name', help='Alert name')
    parser.add_argument('--alert-state', help='Alert state')
    parser.add_argument('--instance', help='Instance name')
    parser.add_argument('--severity', help='Severity level')
    parser.add_argument('--description', help='Description')
    parser.add_argument('--output', help='Output file for export/report')
    parser.add_argument('--start-date', help='Start date for filtering')
    parser.add_argument('--end-date', help='End date for filtering')
    parser.add_argument('--days', type=int, default=30, help='Days to keep for cleanup')
    
    args = parser.parse_args()
    
    logger = AuditLogger(args.log_dir)
    
    if args.action == 'log-change' and args.file:
        logger.log_file_change(args.file)
    elif args.action == 'log-alert':
        logger.log_alert(args.alert_name, args.alert_state, args.instance, args.severity, args.description)
    elif args.action == 'log-remediation':
        logger.log_remediation('manual', 'unknown', 'unknown', 0, {'description': args.description})
    elif args.action == 'log-security':
        logger.log_security_event('manual', args.severity, args.description)
    elif args.action == 'generate-report':
        report = logger.generate_audit_report(args.start_date, args.end_date)
        if report and args.output:
            with open(args.output, 'w') as f:
                json.dump(report, f, indent=2)
        elif report:
            print(json.dumps(report, indent=2))
    elif args.action == 'export':
        logger.export_audit_log(args.output, args.start_date, args.end_date)
    elif args.action == 'cleanup':
        logger.cleanup_old_logs(args.days)

if __name__ == '__main__':
    main()
