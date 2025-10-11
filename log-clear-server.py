#!/usr/bin/env python3
"""
Log Clear Server - Handles clearing of log files via HTTP POST requests
Author: Gabriel Eweka
Date: October 6, 2025
"""

import os
import sys
from http.server import HTTPServer, BaseHTTPRequestHandler
import json
from urllib.parse import urlparse
from datetime import datetime

class LogClearHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        """Handle POST requests to clear log files"""
        try:
            parsed_path = urlparse(self.path)
            
            if parsed_path.path == '/clear-audit-log':
                self.clear_log_file('/tmp/automated-remediation-audit.log')
            elif parsed_path.path == '/clear-webhook-log':
                self.clear_log_file('/tmp/webhook-receiver.log')
            else:
                self.send_error(404, "Endpoint not found")
                return
                
        except Exception as e:
            self.send_error(500, f"Internal server error: {str(e)}")
    
    def clear_log_file(self, log_path):
        """Clear a specific log file"""
        try:
            # Create empty file or truncate existing file
            with open(log_path, 'w') as f:
                f.write('')
            
            # Send success response
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            
            response = {
                'status': 'success',
                'message': f'Log file cleared: {log_path}',
                'timestamp': datetime.now().isoformat()
            }
            
            self.wfile.write(json.dumps(response).encode())
            
        except FileNotFoundError:
            # File doesn't exist, that's fine - consider it "cleared"
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            
            response = {
                'status': 'success',
                'message': f'Log file already empty: {log_path}',
                'timestamp': datetime.now().isoformat()
            }
            
            self.wfile.write(json.dumps(response).encode())
            
        except Exception as e:
            self.send_error(500, f"Failed to clear log file: {str(e)}")
    
    def do_OPTIONS(self):
        """Handle CORS preflight requests"""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
    
    def log_message(self, format, *args):
        """Suppress default logging"""
        pass

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 log-clear-server.py <port>")
        sys.exit(1)
    
    port = int(sys.argv[1])
    
    try:
        server = HTTPServer(('127.0.0.1', port), LogClearHandler)
        print(f"Log Clear Server running on http://127.0.0.1:{port}")
        print("Endpoints:")
        print("  POST /clear-audit-log - Clear automated remediation audit log")
        print("  POST /clear-webhook-log - Clear webhook receiver log")
        print("Press Ctrl+C to stop")
        
        server.serve_forever()
        
    except KeyboardInterrupt:
        print("\nShutting down log clear server...")
        server.shutdown()
    except Exception as e:
        print(f"Error starting server: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
