#!/usr/bin/env python3
"""
FIM Events Audit and Investigation Tool
Provides detailed analysis of File Integrity Monitoring events
"""

import requests
import json
import sys
from datetime import datetime, timedelta
import argparse
from collections import defaultdict

class FIMAuditor:
    def __init__(self, prometheus_url="http://localhost:9090"):
        self.prometheus_url = prometheus_url
        self.session = requests.Session()
    
    def query_prometheus(self, query):
        """Query Prometheus API"""
        try:
            response = self.session.get(
                f"{self.prometheus_url}/api/v1/query",
                params={'query': query}
            )
            response.raise_for_status()
            return response.json()
        except requests.RequestException as e:
            print(f"Error querying Prometheus: {e}")
            return None
    
    def get_fim_events_summary(self):
        """Get summary of FIM events"""
        print("🔍 FIM Events Summary")
        print("=" * 50)
        
        # Get total events by type
        query = "fim_events_total"
        result = self.query_prometheus(query)
        
        if not result or result['status'] != 'success':
            print("❌ Failed to query FIM events")
            return
        
        events_by_type = defaultdict(int)
        events_by_instance = defaultdict(lambda: defaultdict(int))
        
        for metric in result['data']['result']:
            event_type = metric['metric'].get('event_type', 'unknown')
            instance = metric['metric'].get('instance', 'unknown')
            count = int(metric['value'][1])
            
            events_by_type[event_type] += count
            events_by_instance[instance][event_type] += count
        
        print(f"📊 Total Events by Type:")
        for event_type, count in events_by_type.items():
            print(f"  {event_type}: {count:,} events")
        
        print(f"\n📊 Events by Instance:")
        for instance, events in events_by_instance.items():
            print(f"  {instance}:")
            for event_type, count in events.items():
                print(f"    {event_type}: {count:,} events")
        
        return events_by_type, events_by_instance
    
    def get_fim_rate_analysis(self, time_range="1h"):
        """Analyze FIM event rates"""
        print(f"\n📈 FIM Event Rate Analysis (last {time_range})")
        print("=" * 50)
        
        # Get event rate
        query = f"rate(fim_events_total[{time_range}]) * 60"
        result = self.query_prometheus(query)
        
        if not result or result['status'] != 'success':
            print("❌ Failed to query FIM event rates")
            return
        
        print("📊 Event Rate (events per minute):")
        for metric in result['data']['result']:
            event_type = metric['metric'].get('event_type', 'unknown')
            instance = metric['metric'].get('instance', 'unknown')
            rate = float(metric['value'][1])
            print(f"  {instance} - {event_type}: {rate:.2f} events/min")
    
    def get_files_monitored(self):
        """Get files currently being monitored"""
        print(f"\n👁️ Files Currently Monitored")
        print("=" * 50)
        
        query = "fim_files_monitored"
        result = self.query_prometheus(query)
        
        if not result or result['status'] != 'success':
            print("❌ Failed to query monitored files")
            return
        
        total_files = 0
        for metric in result['data']['result']:
            instance = metric['metric'].get('instance', 'unknown')
            count = int(metric['value'][1])
            total_files += count
            print(f"  {instance}: {count:,} files")
        
        print(f"\n📊 Total Files Monitored: {total_files:,}")
    
    def get_agent_status(self):
        """Get FIM and CMDB agent status"""
        print(f"\n🤖 Agent Status")
        print("=" * 50)
        
        # Check FIM agents
        query = "up{job=\"fim-agents\"}"
        result = self.query_prometheus(query)
        
        if result and result['status'] == 'success':
            print("🔒 FIM Agents:")
            for metric in result['data']['result']:
                instance = metric['metric'].get('instance', 'unknown')
                status = "UP" if int(metric['value'][1]) == 1 else "DOWN"
                print(f"  {instance}: {status}")
        
        # Check CMDB collectors
        query = "up{job=\"cmdb-collectors\"}"
        result = self.query_prometheus(query)
        
        if result and result['status'] == 'success':
            print("\n📊 CMDB Collectors:")
            for metric in result['data']['result']:
                instance = metric['metric'].get('instance', 'unknown')
                status = "UP" if int(metric['value'][1]) == 1 else "DOWN"
                print(f"  {instance}: {status}")
    
    def get_system_inventory(self):
        """Get system inventory from CMDB"""
        print(f"\n💻 System Inventory")
        print("=" * 50)
        
        queries = {
            "CPU Cores": "system_cpu_cores",
            "System Packages": "system_packages_total",
            "System Processes": "system_processes_total",
            "System Users": "system_users_total"
        }
        
        for name, query in queries.items():
            result = self.query_prometheus(query)
            if result and result['status'] == 'success':
                print(f"\n{name}:")
                for metric in result['data']['result']:
                    instance = metric['metric'].get('instance', 'unknown')
                    value = int(metric['value'][1])
                    print(f"  {instance}: {value:,}")
    
    def detect_anomalies(self):
        """Detect potential security anomalies"""
        print(f"\n🚨 Security Anomaly Detection")
        print("=" * 50)
        
        # Check for high event rates
        query = "rate(fim_events_total[5m]) * 60 > 10"
        result = self.query_prometheus(query)
        
        if result and result['status'] == 'success' and result['data']['result']:
            print("⚠️ High FIM Event Rate Detected:")
            for metric in result['data']['result']:
                event_type = metric['metric'].get('event_type', 'unknown')
                instance = metric['metric'].get('instance', 'unknown')
                rate = float(metric['value'][1])
                print(f"  {instance} - {event_type}: {rate:.2f} events/min (threshold: 10)")
        else:
            print("✅ No high event rates detected")
        
        # Check for file deletions
        query = "increase(fim_events_total{event_type=\"deleted\"}[1h]) > 0"
        result = self.query_prometheus(query)
        
        if result and result['status'] == 'success' and result['data']['result']:
            print("\n⚠️ File Deletions Detected:")
            for metric in result['data']['result']:
                instance = metric['metric'].get('instance', 'unknown')
                count = int(metric['value'][1])
                print(f"  {instance}: {count} files deleted in last hour")
        else:
            print("\n✅ No file deletions detected in last hour")
    
    def generate_report(self, output_file=None):
        """Generate comprehensive audit report"""
        print("📋 Generating Comprehensive FIM Audit Report")
        print("=" * 60)
        
        report = {
            "timestamp": datetime.now().isoformat(),
            "summary": {},
            "details": {}
        }
        
        # Get summary data
        events_by_type, events_by_instance = self.get_fim_events_summary()
        report["summary"]["events_by_type"] = dict(events_by_type)
        report["summary"]["events_by_instance"] = {k: dict(v) for k, v in events_by_instance.items()}
        
        # Get agent status
        self.get_agent_status()
        
        # Get system inventory
        self.get_system_inventory()
        
        # Detect anomalies
        self.detect_anomalies()
        
        if output_file:
            with open(output_file, 'w') as f:
                json.dump(report, f, indent=2)
            print(f"\n📄 Report saved to: {output_file}")
        
        return report

def main():
    parser = argparse.ArgumentParser(description='FIM Events Audit and Investigation Tool')
    parser.add_argument('--prometheus-url', default='http://localhost:9090',
                       help='Prometheus server URL')
    parser.add_argument('--time-range', default='1h',
                       help='Time range for rate analysis (e.g., 1h, 24h)')
    parser.add_argument('--output', help='Output file for audit report')
    parser.add_argument('--summary-only', action='store_true',
                       help='Show only summary information')
    
    args = parser.parse_args()
    
    auditor = FIMAuditor(args.prometheus_url)
    
    if args.summary_only:
        auditor.get_fim_events_summary()
    else:
        auditor.generate_report(args.output)

if __name__ == '__main__':
    main()
