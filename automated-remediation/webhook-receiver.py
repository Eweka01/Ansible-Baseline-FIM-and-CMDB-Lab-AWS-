#!/usr/bin/env python3
"""
Prometheus Alert Webhook Receiver
Automated Drift Detection and Remediation System

This webhook receiver processes Prometheus alerts and triggers
automated remediation actions via Ansible playbooks.

Author: Gabriel Eweka
Date: October 6, 2025
"""

import json
import logging
import subprocess
import os
import sys
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import threading
import time

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/tmp/automated-remediation.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

class AlertWebhookHandler(BaseHTTPRequestHandler):
    """HTTP request handler for Prometheus alert webhooks"""
    
    def end_headers(self):
        """Add CORS headers to allow cross-origin requests"""
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        super().end_headers()
    
    def do_OPTIONS(self):
        """Handle preflight OPTIONS requests for CORS"""
        self.send_response(200)
        self.end_headers()
    
    def do_POST(self):
        """Handle POST requests from Alertmanager"""
        try:
            # Parse the request
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            
            # Parse JSON payload
            alert_data = json.loads(post_data.decode('utf-8'))
            
            logger.info(f"Received alert webhook: {len(alert_data.get('alerts', []))} alerts")
            
            # Process each alert
            for alert in alert_data.get('alerts', []):
                self.process_alert(alert)
            
            # Send success response
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'status': 'success'}).encode())
            
        except Exception as e:
            logger.error(f"Error processing webhook: {str(e)}")
            self.send_response(500)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'error': str(e)}).encode())
    
    def process_alert(self, alert):
        """Process individual alert and trigger remediation if needed"""
        try:
            alert_name = alert.get('labels', {}).get('alertname', 'unknown')
            alert_state = alert.get('status', {}).get('state', 'unknown')
            severity = alert.get('labels', {}).get('severity', 'unknown')
            instance = alert.get('labels', {}).get('instance', 'unknown')
            
            logger.info(f"Processing alert: {alert_name} ({alert_state}) - {severity} - {instance}")
            
            # Only process firing alerts
            if alert_state != 'firing':
                logger.info(f"Alert {alert_name} is not firing, skipping")
                return
            
            # Route alerts to appropriate remediation actions
            if alert_name == 'FIMFileChange':
                self.handle_fim_file_change(alert)
            elif alert_name == 'FIMHighActivity':
                self.handle_fim_high_activity(alert)
            elif alert_name == 'FIMAgentDown':
                self.handle_fim_agent_down(alert)
            elif alert_name == 'CMDBCollectionFailure':
                self.handle_cmdb_collection_failure(alert)
            elif alert_name == 'CMDBCollectorDown':
                self.handle_cmdb_collector_down(alert)
            else:
                logger.info(f"No remediation action defined for alert: {alert_name}")
                
        except Exception as e:
            logger.error(f"Error processing alert {alert.get('labels', {}).get('alertname', 'unknown')}: {str(e)}")
    
    def handle_fim_file_change(self, alert):
        """Handle FIM file change alerts"""
        instance = alert.get('labels', {}).get('instance', '')
        description = alert.get('annotations', {}).get('description', '')
        
        logger.info(f"FIM File Change detected on {instance}: {description}")
        
        # Determine which node this is
        node_name = self.get_node_name_from_instance(instance)
        
        if node_name:
            # Trigger remediation playbook
            self.run_ansible_playbook('remediate-fim-changes.yml', node_name, {
                'alert_type': 'FIMFileChange',
                'instance': instance,
                'description': description,
                'timestamp': datetime.now().isoformat()
            })
        else:
            logger.warning(f"Could not determine node name for instance: {instance}")
    
    def handle_fim_high_activity(self, alert):
        """Handle FIM high activity alerts"""
        instance = alert.get('labels', {}).get('instance', '')
        description = alert.get('annotations', {}).get('description', '')
        
        logger.warning(f"FIM High Activity detected on {instance}: {description}")
        
        node_name = self.get_node_name_from_instance(instance)
        
        if node_name:
            # Trigger high-priority remediation
            self.run_ansible_playbook('remediate-high-activity.yml', node_name, {
                'alert_type': 'FIMHighActivity',
                'instance': instance,
                'description': description,
                'timestamp': datetime.now().isoformat(),
                'priority': 'critical'
            })
        else:
            logger.warning(f"Could not determine node name for instance: {instance}")
    
    def handle_fim_agent_down(self, alert):
        """Handle FIM agent down alerts"""
        instance = alert.get('labels', {}).get('instance', '')
        
        logger.error(f"FIM Agent down on {instance}")
        
        node_name = self.get_node_name_from_instance(instance)
        
        if node_name:
            # Restart FIM agent
            self.run_ansible_playbook('restart-fim-agent.yml', node_name, {
                'alert_type': 'FIMAgentDown',
                'instance': instance,
                'timestamp': datetime.now().isoformat()
            })
        else:
            logger.warning(f"Could not determine node name for instance: {instance}")
    
    def handle_cmdb_collection_failure(self, alert):
        """Handle CMDB collection failure alerts"""
        instance = alert.get('labels', {}).get('instance', '')
        
        logger.warning(f"CMDB Collection failure on {instance}")
        
        node_name = self.get_node_name_from_instance(instance)
        
        if node_name:
            # Restart CMDB collector
            self.run_ansible_playbook('restart-cmdb-collector.yml', node_name, {
                'alert_type': 'CMDBCollectionFailure',
                'instance': instance,
                'timestamp': datetime.now().isoformat()
            })
        else:
            logger.warning(f"Could not determine node name for instance: {instance}")
    
    def handle_cmdb_collector_down(self, alert):
        """Handle CMDB collector down alerts"""
        instance = alert.get('labels', {}).get('instance', '')
        
        logger.error(f"CMDB Collector down on {instance}")
        
        node_name = self.get_node_name_from_instance(instance)
        
        if node_name:
            # Restart CMDB collector
            self.run_ansible_playbook('restart-cmdb-collector.yml', node_name, {
                'alert_type': 'CMDBCollectorDown',
                'instance': instance,
                'timestamp': datetime.now().isoformat()
            })
        else:
            logger.warning(f"Could not determine node name for instance: {instance}")
    
    def get_node_name_from_instance(self, instance):
        """Map instance to node name"""
        # Map host.docker.internal ports to node names
        port_mapping = {
            'host.docker.internal:8080': 'manage-node-1',
            'host.docker.internal:8081': 'manage-node-1',
            'host.docker.internal:8082': 'manage-node-2',
            'host.docker.internal:8083': 'manage-node-2',
            'host.docker.internal:8084': 'manage-node-3',
            'host.docker.internal:8085': 'manage-node-3',
            'host.docker.internal:9101': 'manage-node-1',
            'host.docker.internal:9102': 'manage-node-2',
            'host.docker.internal:9103': 'manage-node-3'
        }
        
        return port_mapping.get(instance, None)
    
    def run_ansible_playbook(self, playbook_name, target_node, extra_vars=None):
        """Run Ansible playbook for remediation"""
        try:
            # Change to the lab directory
            lab_dir = "/Users/osamudiameneweka/Desktop/Ansible Baseline, FIM, and CMDB Lab"
            playbook_path = os.path.join(lab_dir, "automated-remediation", playbook_name)
            
            # Build ansible-playbook command
            cmd = [
                'ansible-playbook',
                '-i', os.path.join(lab_dir, 'ansible/inventory/aws-instances'),
                '--limit', target_node,
                playbook_path
            ]
            
            # Add extra variables if provided
            if extra_vars:
                cmd.extend(['--extra-vars', json.dumps(extra_vars)])
            
            logger.info(f"Running remediation playbook: {' '.join(cmd)}")
            
            # Run the playbook
            result = subprocess.run(
                cmd,
                cwd=lab_dir,
                capture_output=True,
                text=True,
                timeout=300  # 5 minute timeout
            )
            
            if result.returncode == 0:
                logger.info(f"Remediation playbook {playbook_name} completed successfully")
                logger.info(f"Output: {result.stdout}")
            else:
                logger.error(f"Remediation playbook {playbook_name} failed")
                logger.error(f"Error: {result.stderr}")
                
            # Log the remediation attempt
            self.log_remediation_attempt(playbook_name, target_node, extra_vars, result.returncode)
            
        except subprocess.TimeoutExpired:
            logger.error(f"Remediation playbook {playbook_name} timed out")
        except Exception as e:
            logger.error(f"Error running remediation playbook {playbook_name}: {str(e)}")
    
    def log_remediation_attempt(self, playbook_name, target_node, extra_vars, return_code):
        """Log remediation attempt to audit trail"""
        try:
            log_entry = {
                'timestamp': datetime.now().isoformat(),
                'playbook': playbook_name,
                'target_node': target_node,
                'extra_vars': extra_vars,
                'return_code': return_code,
                'status': 'success' if return_code == 0 else 'failed'
            }
            
            # Write to audit log
            audit_log_path = '/tmp/automated-remediation-audit.log'
            with open(audit_log_path, 'a') as f:
                f.write(json.dumps(log_entry) + '\n')
                
            logger.info(f"Logged remediation attempt to {audit_log_path}")
            
        except Exception as e:
            logger.error(f"Error logging remediation attempt: {str(e)}")
    
    def log_message(self, format, *args):
        """Override to reduce noise in logs"""
        pass

def start_webhook_server(port=5001):
    """Start the webhook server"""
    try:
        server = HTTPServer(('0.0.0.0', port), AlertWebhookHandler)
        logger.info(f"Starting automated remediation webhook server on port {port}")
        logger.info("Ready to receive Prometheus alerts...")
        server.serve_forever()
    except KeyboardInterrupt:
        logger.info("Shutting down webhook server...")
        server.shutdown()
    except Exception as e:
        logger.error(f"Error starting webhook server: {str(e)}")

if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 5001
    start_webhook_server(port)
