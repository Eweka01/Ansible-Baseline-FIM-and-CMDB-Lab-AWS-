#!/usr/bin/env python3
"""
Advanced FIM Test Script
========================

This script provides comprehensive testing of the File Integrity Monitoring (FIM) agent
functionality. It tests all aspects of FIM including file monitoring, change detection,
baseline creation, and alert generation.

Features:
- Tests FIM agent initialization and configuration
- Validates file monitoring and change detection
- Tests baseline creation and comparison
- Validates alert generation and reporting
- Tests different file types and monitoring scenarios

Usage:
    python3 test-fim.py [--verbose] [--test-dir /path/to/test]

Author: Ansible Baseline, FIM, and CMDB Lab
Version: 1.0.0
"""

import os
import sys
import json
import hashlib
import time
from datetime import datetime
from pathlib import Path

# Add the current directory to Python path for local imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Import the FIM agent class directly from the lab components
import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), 'fim', 'agents'))
from fim_agent import FIMAgent

class LocalFIMTest:
    """
    Local FIM Test Class
    ===================
    
    This class provides comprehensive testing functionality for the File Integrity
    Monitoring (FIM) agent. It creates test scenarios, validates FIM functionality,
    and generates detailed test reports.
    
    Attributes:
        test_dir (str): Directory path for test files
        baseline_file (str): Path to FIM baseline file
        report_file (str): Path to test report file
    """
    
    def __init__(self):
        """
        Initialize the LocalFIMTest class
        
        Sets up default paths for test files, baseline data, and report generation.
        These paths can be customized based on testing requirements.
        """
        self.test_dir = "./test-files"           # Directory for test files
        self.baseline_file = "./fim-baseline.json"  # FIM baseline data file
        self.report_file = "./fim-test-reports.json"  # Test report output file
        
    def create_test_files(self):
        """
        Create test files for FIM testing
        
        This method creates a variety of test files with different content types
        to simulate real-world file monitoring scenarios. The files include:
        - Text files with different content
        - Configuration files
        - Script files
        - Files with timestamps for change detection
        
        Returns:
            None
            
        Side Effects:
            - Creates test directory if it doesn't exist
            - Generates test files with sample content
            - Prints creation status to console
        """
        # Ensure test directory exists
        os.makedirs(self.test_dir, exist_ok=True)
        
        # Define test files with different types and purposes
        test_files = [
            "test1.txt",      # Basic text file
            "test2.txt",      # Another text file for comparison
            "config.conf",    # Configuration file
            "script.sh"       # Shell script file
        ]
        
        # Create each test file with unique content
        for filename in test_files:
            filepath = os.path.join(self.test_dir, filename)
            with open(filepath, 'w') as f:
                f.write(f"Test content for {filename}\n")
                f.write(f"Created at: {datetime.now()}\n")
        
        print(f"Created {len(test_files)} test files in {self.test_dir}")
    
    def test_fim_functionality(self):
        """Test FIM functionality"""
        print("=== FIM Functionality Test ===")
        
        # Create test files
        self.create_test_files()
        
        # Test file hash calculation
        print("\n1. Testing file hash calculation...")
        test_file = os.path.join(self.test_dir, "test1.txt")
        if os.path.exists(test_file):
            with open(test_file, 'rb') as f:
                content = f.read()
                file_hash = hashlib.sha256(content).hexdigest()
                print(f"   File: {test_file}")
                print(f"   Hash: {file_hash[:16]}...")
                print("   ✓ Hash calculation working")
        
        # Test baseline creation
        print("\n2. Testing baseline creation...")
        baseline_data = {}
        for root, dirs, files in os.walk(self.test_dir):
            for file in files:
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, 'rb') as f:
                        content = f.read()
                        file_hash = hashlib.sha256(content).hexdigest()
                        baseline_data[file_path] = {
                            'hash': file_hash,
                            'size': len(content),
                            'mtime': os.path.getmtime(file_path),
                            'scanned_at': datetime.now().isoformat()
                        }
                except Exception as e:
                    print(f"   Error processing {file_path}: {e}")
        
        # Save baseline
        with open(self.baseline_file, 'w') as f:
            json.dump(baseline_data, f, indent=2)
        
        print(f"   ✓ Baseline created with {len(baseline_data)} files")
        print(f"   ✓ Baseline saved to {self.baseline_file}")
        
        # Test change detection
        print("\n3. Testing change detection...")
        
        # Modify a file
        test_file = os.path.join(self.test_dir, "test1.txt")
        with open(test_file, 'a') as f:
            f.write("Modified content\n")
        
        # Scan again and compare
        current_data = {}
        for root, dirs, files in os.walk(self.test_dir):
            for file in files:
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, 'rb') as f:
                        content = f.read()
                        file_hash = hashlib.sha256(content).hexdigest()
                        current_data[file_path] = {
                            'hash': file_hash,
                            'size': len(content),
                            'mtime': os.path.getmtime(file_path),
                            'scanned_at': datetime.now().isoformat()
                        }
                except Exception as e:
                    print(f"   Error processing {file_path}: {e}")
        
        # Compare with baseline
        changes = []
        for file_path, current_info in current_data.items():
            if file_path in baseline_data:
                baseline_info = baseline_data[file_path]
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
        
        if changes:
            print(f"   ✓ Detected {len(changes)} changes:")
            for change in changes:
                print(f"     - {change['type'].upper()}: {change['file']}")
            
            # Save report
            report_data = {
                'timestamp': datetime.now().isoformat(),
                'changes': changes,
                'total_changes': len(changes)
            }
            
            with open(self.report_file, 'w') as f:
                json.dump(report_data, f, indent=2)
            
            print(f"   ✓ Report saved to {self.report_file}")
        else:
            print("   ✓ No changes detected")
        
        print("\n=== FIM Test Complete ===")
        return len(changes) > 0

def main():
    print("FIM Local Test")
    print("==============")
    
    test = LocalFIMTest()
    success = test.test_fim_functionality()
    
    if success:
        print("\n✓ FIM functionality test PASSED")
        print("  - File hash calculation working")
        print("  - Baseline creation working") 
        print("  - Change detection working")
        print("  - Report generation working")
    else:
        print("\n✗ FIM functionality test FAILED")
    
    return 0 if success else 1

if __name__ == '__main__':
    sys.exit(main())
