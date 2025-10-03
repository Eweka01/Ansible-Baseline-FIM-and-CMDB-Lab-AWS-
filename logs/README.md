# Logs Directory

This directory contains all log files from the lab components, organized by service.

## 📁 Structure

```
logs/
├── ansible/          # Ansible execution logs
├── fim/             # File Integrity Monitoring logs
├── cmdb/            # Configuration Management Database logs
└── deployment/      # Deployment and setup logs
```

## 📊 Log Files

### Ansible Logs
- `ansible.log` - Main Ansible execution log with all playbook runs

### FIM Logs
- `fim-agent.log` - File Integrity Monitoring agent logs
- Contains file change detection events and alerts

### CMDB Logs
- `cmdb-test.log` - CMDB collector test logs
- Contains data collection events and errors

### Deployment Logs
- Deployment-specific logs and setup outputs

## 🔍 How to Use

### View Recent Logs
```bash
# View latest Ansible logs
tail -f logs/ansible/ansible.log

# View FIM agent logs
tail -f logs/fim/fim-agent.log

# View CMDB logs
tail -f logs/cmdb/cmdb-test.log
```

### Search Logs
```bash
# Search for errors in Ansible logs
grep -i error logs/ansible/ansible.log

# Search for file changes in FIM logs
grep -i "file changed" logs/fim/fim-agent.log

# Search for collection events in CMDB logs
grep -i "collected" logs/cmdb/cmdb-test.log
```

## 📝 Log Rotation

Logs are automatically managed by the system. For manual cleanup:

```bash
# Clean old logs (keep last 30 days)
find logs/ -name "*.log" -mtime +30 -delete

# Compress old logs
gzip logs/ansible/ansible.log.old
```

## 🚨 Troubleshooting

If you encounter issues:

1. Check the relevant log file for error messages
2. Look for timestamps around the time of the issue
3. Check for repeated error patterns
4. Use the troubleshooting guide for common issues

## 📊 Log Analysis

For advanced log analysis:

```bash
# Count errors by type
grep -i error logs/ansible/ansible.log | sort | uniq -c

# Find most active FIM events
grep -i "scan" logs/fim/fim-agent.log | tail -20

# Monitor real-time activity
tail -f logs/ansible/ansible.log logs/fim/fim-agent.log
```
