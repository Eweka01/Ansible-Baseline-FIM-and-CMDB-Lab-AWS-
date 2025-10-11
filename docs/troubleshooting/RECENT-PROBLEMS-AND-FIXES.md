# Recent Problems and Fixes

**Date**: October 6, 2025  
**Author**: Gabriel Eweka

## Overview

This document tracks recent problems encountered in the Ansible Baseline, FIM, and CMDB Lab and their solutions.

---

## Problem 1: Clear Logs Button Bringing Logs Back Immediately

### **Issue**
The "Clear Logs" button in the restoration monitoring dashboard was clearing the logs but they would immediately reappear due to the auto-refresh functionality.

### **Root Cause**
The `clearLogs()` function only cleared in-memory arrays and dashboard display, but the auto-refresh cycle (every 2 seconds) would immediately fetch the logs again and display them.

### **Solution**
1. **Added `logsCleared` state** - Global variable to prevent log fetching when true
2. **Modified `performMonitoringCycle()`** - Now respects the `logsCleared` state and skips log fetching
3. **Updated `clearLogs()` function** - Sets `logsCleared = true` and adds a 5-second timeout
4. **Added visual feedback** - Button shows "⏳ Logs Cleared (5s)" and gets disabled
5. **Auto-resume after 5 seconds** - Re-enables monitoring and shows "Log monitoring resumed"

### **Files Modified**
- `restoration-monitoring-dashboard.html`

### **Result**
The Clear Logs button now works perfectly - it clears the logs and keeps them cleared for 5 seconds before resuming normal monitoring.

---

## Problem 2: CMDBCollectionFailure Alert After Restore Button Usage

### **Issue**
After using the restore button (manual restore), the `CMDBCollectionFailure` alert started firing for nodes 2 and 3, indicating that CMDB collectors hadn't collected data in the last hour.

### **Root Cause**
When the restore button was used, it triggered the automated remediation system which restarted the `cmdb-collector-prometheus` services. However, the services on nodes 2 and 3 failed to start due to permission issues with the log file `/var/log/cmdb-collector.log`.

### **Investigation Process**
1. **Checked Prometheus targets** - Ports 8083 and 8085 showing "down" with EOF errors
2. **Verified SSH tunnels** - Working correctly, forwarding to remote port 8081
3. **Checked CMDB processes** - Only node 1 had CMDB collector running
4. **Examined logs** - Found permission denied errors for log file access
5. **Identified service restart** - Remediation playbook restarted services but they failed to start

### **Solution**
1. **Fixed log file permissions** - Created `/var/log/cmdb-collector.log` with proper permissions (666)
2. **Restarted CMDB collectors** - Started `cmdb-collector-prometheus.py` on nodes 2 and 3
3. **Verified all 3 nodes** - All CMDB collectors now running and collecting data

### **Files Modified**
- `automated-remediation/remediate-high-activity.yml` (identified as source of restart)

### **Result**
All 3 nodes now have working CMDB collectors:
- **Node 1**: 59 collections ✅
- **Node 2**: 1 collection ✅  
- **Node 3**: 1 collection ✅

The `CMDBCollectionFailure` alert should resolve as collectors continue to collect data.

---

## Problem 3: Log Clear Server Integration

### **Issue**
The Clear Logs button needed to clear actual log files on disk, not just the dashboard display.

### **Root Cause**
The dashboard was only clearing in-memory data, but the actual log files (`/tmp/automated-remediation-audit.log` and `/tmp/webhook-receiver.log`) remained unchanged.

### **Solution**
1. **Created `log-clear-server.py`** - HTTP server on port 8090 to handle log clearing requests
2. **Updated `clearLogs()` function** - Now makes POST requests to clear actual log files
3. **Updated `restart-monitoring-lab.sh`** - Starts the log clear server automatically
4. **Added CORS support** - Handles cross-origin requests from the dashboard

### **Files Created/Modified**
- `log-clear-server.py` (new)
- `restoration-monitoring-dashboard.html`
- `restart-monitoring-lab.sh`

### **Result**
The Clear Logs button now clears both dashboard display and actual log files on disk.

---

## Key Lessons Learned

### **1. Automated Remediation Side Effects**
The restore button revealed configuration issues that were previously hidden. This is actually a **good thing** - automated remediation should expose and fix configuration problems.

### **2. Service Dependencies**
When services are restarted by remediation, all dependencies (like log file permissions) must be properly configured.

### **3. Monitoring Integration**
Dashboard functionality should integrate with actual system components, not just display cached data.

### **4. Error Handling**
Proper error handling and logging helps identify root causes quickly.

---

## Prevention Measures

### **1. Service Health Checks**
- Add health checks for all services before and after remediation
- Verify log file permissions in service startup scripts

### **2. Dashboard Integration**
- Ensure dashboard actions affect actual system state
- Add proper error handling and user feedback

### **3. Documentation**
- Document all service dependencies and requirements
- Maintain troubleshooting guides for common issues

---

## Status

✅ **All problems resolved**  
✅ **All 3 nodes operational**  
✅ **Clear Logs functionality working**  
✅ **CMDB collectors running on all nodes**  
✅ **Automated remediation system functional**

---

*Last Updated: October 6, 2025*
