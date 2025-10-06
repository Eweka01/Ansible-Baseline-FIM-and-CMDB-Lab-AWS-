# Audit Logging System

This directory contains the audit logging system for the Ansible Baseline, FIM, and CMDB Lab.

## Purpose

The audit logging system provides comprehensive tracking of:
- **Configuration Changes**: File modifications, additions, deletions
- **Security Events**: Unauthorized access, suspicious activities
- **Remediation Actions**: Automated responses to alerts
- **System Events**: Service restarts, configuration updates

## Components

### Core Files
- `audit-logger.py` - Main audit logging system
- `manage-audit-logs.sh` - Management script for audit logs
- `README.md` - This documentation

### Log Files (on target systems)
- `/var/log/audit/audit.log` - Master audit log
- `/var/log/audit/changes.log` - Configuration change log
- `/var/log/audit/remediation.log` - Remediation action log
- `/var/log/audit/security.log` - Security event log

## Usage

### Setup Audit Logging
```bash
sudo ./manage-audit-logs.sh setup
```

### Generate Audit Report
```bash
./manage-audit-logs.sh report [output_file] [start_date] [end_date]
```

### Export Audit Logs
```bash
./manage-audit-logs.sh export [output_file] [start_date] [end_date]
```

### Cleanup Old Logs
```bash
./manage-audit-logs.sh cleanup [days_to_keep]
```

### Check Audit Status
```bash
./manage-audit-logs.sh status
```

## Integration with Automated Remediation

The audit logging system is integrated with:
- **Webhook Receiver**: Logs all incoming alerts
- **Ansible Playbooks**: Logs all remediation actions
- **FIM Agents**: Logs file changes and security events
- **CMDB Collectors**: Logs configuration changes

## Log Entry Format

All log entries are in JSON format with the following structure:

```json
{
  "timestamp": "2025-10-06T15:30:45.123456",
  "type": "change|alert|remediation|security_event",
  "details": {
    "file_path": "/etc/hosts",
    "old_hash": "abc123...",
    "new_hash": "def456...",
    "user": "root",
    "process": "vim"
  }
}
```

## Security Considerations

- Audit logs are stored with restricted permissions (644, root:root)
- Log entries include cryptographic hashes for integrity verification
- All log access is tracked and monitored
- Log files are regularly rotated and archived

## Compliance

The audit logging system supports compliance requirements for:
- **SOX**: Sarbanes-Oxley Act compliance
- **HIPAA**: Health Insurance Portability and Accountability Act
- **PCI DSS**: Payment Card Industry Data Security Standard
- **GDPR**: General Data Protection Regulation

## Monitoring and Alerting

Audit logs are monitored for:
- Unauthorized configuration changes
- Failed remediation attempts
- Security events and violations
- System integrity issues

## Backup and Recovery

- Audit logs are automatically backed up
- Log retention policies are enforced
- Recovery procedures are documented
- Log integrity is verified regularly

## Author

Gabriel Eweka  
Date: October 6, 2025
