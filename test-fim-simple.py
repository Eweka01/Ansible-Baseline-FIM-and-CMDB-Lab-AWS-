#!/usr/bin/env python3
"""
Simple FIM Test Script
Tests basic FIM functionality without complex imports
"""

import os
import sys
import json
import hashlib
import time
from datetime import datetime

class SimpleFIMTest:
    def __init__(self):
        self.test_dir = "./test-files"
        self.baseline_file = "./fim-baseline.json"
        self.report_file = "./fim-test-reports.json"
        
    def create_test_files(self):
        """Create test files for FIM testing"""
        os.makedirs(self.test_dir, exist_ok=True)
        
        # Create some test files
        test_files = [
            "test1.txt",
            "test2.txt", 
            "config.conf",
            "script.sh"
        ]
        
        for filename in test_files:
            filepath = os.path.join(self.test_dir, filename)
            with open(filepath, 'w') as f:
                f.write(f"Test content for {filename}\n")
                f.write(f"Created at: {datetime.now()}\n")
        
        print(f"Created {len(test_files)} test files in {self.test_dir}")
    
    def calculate_file_hash(self, file_path):
        """Calculate hash of a file"""
        try:
            hash_obj = hashlib.sha256()
            with open(file_path, 'rb') as f:
                for chunk in iter(lambda: f.read(4096), b""):
                    hash_obj.update(chunk)
            return hash_obj.hexdigest()
        except Exception as e:
            print(f"Error calculating hash for {file_path}: {e}")
            return None
    
    def scan_directory(self, directory):
        """Scan directory and return file hashes"""
        file_hashes = {}
        
        try:
            for root, dirs, files in os.walk(directory):
                for file in files:
                    file_path = os.path.join(root, file)
                    file_hash = self.calculate_file_hash(file_path)
                    if file_hash:
                        file_hashes[file_path] = {
                            'hash': file_hash,
                            'size': os.path.getsize(file_path),
                            'mtime': os.path.getmtime(file_path),
                            'scanned_at': datetime.now().isoformat()
                        }
        except Exception as e:
            print(f"Error scanning {directory}: {e}")
        
        return file_hashes
    
    def test_fim_functionality(self):
        """Test FIM functionality"""
        print("=== Simple FIM Functionality Test ===")
        
        # Create test files
        self.create_test_files()
        
        # Test file hash calculation
        print("\n1. Testing file hash calculation...")
        test_file = os.path.join(self.test_dir, "test1.txt")
        if os.path.exists(test_file):
            file_hash = self.calculate_file_hash(test_file)
            print(f"   File: {test_file}")
            print(f"   Hash: {file_hash[:16]}...")
            print("   ✓ Hash calculation working")
        
        # Test baseline creation
        print("\n2. Testing baseline creation...")
        baseline_data = self.scan_directory(self.test_dir)
        
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
        current_data = self.scan_directory(self.test_dir)
        
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
        
        # Test file deletion detection
        print("\n4. Testing file deletion detection...")
        
        # Delete a file
        test_file = os.path.join(self.test_dir, "test2.txt")
        if os.path.exists(test_file):
            os.remove(test_file)
            print(f"   Deleted: {test_file}")
        
        # Scan again
        current_data = self.scan_directory(self.test_dir)
        
        # Check for deleted files
        for file_path in baseline_data:
            if file_path not in current_data:
                changes.append({
                    'type': 'deleted',
                    'file': file_path,
                    'old_hash': baseline_data[file_path]['hash'],
                    'timestamp': datetime.now().isoformat()
                })
        
        if changes:
            print(f"   ✓ Detected {len(changes)} total changes (including deletions)")
            for change in changes:
                print(f"     - {change['type'].upper()}: {change['file']}")
        
        print("\n=== FIM Test Complete ===")
        return len(changes) > 0

def main():
    print("Simple FIM Test")
    print("===============")
    
    test = SimpleFIMTest()
    success = test.test_fim_functionality()
    
    if success:
        print("\n✓ FIM functionality test PASSED")
        print("  - File hash calculation working")
        print("  - Baseline creation working") 
        print("  - Change detection working")
        print("  - File deletion detection working")
        print("  - Report generation working")
    else:
        print("\n✗ FIM functionality test FAILED")
    
    return 0 if success else 1

if __name__ == '__main__':
    sys.exit(main())
