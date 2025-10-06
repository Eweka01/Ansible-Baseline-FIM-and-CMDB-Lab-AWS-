# Baseline Configurations

This directory contains the baseline (known good) configurations for the Ansible Baseline, FIM, and CMDB Lab.

## Purpose

These baseline configurations serve as the reference point for:
- **Drift Detection**: Comparing current state against known good state
- **Automated Remediation**: Restoring configurations when unauthorized changes are detected
- **Version Control**: Tracking configuration changes over time
- **Compliance**: Ensuring systems maintain approved configurations

## Files

### System Configurations
- `hosts.baseline` - Baseline /etc/hosts file
- `sshd_config.baseline` - Baseline SSH daemon configuration
- `sudoers.baseline` - Baseline sudoers configuration

### System State
- `packages.baseline` - Baseline package list
- `services.baseline` - Baseline service list
- `users.baseline` - Baseline user list
- `groups.baseline` - Baseline group list
- `network.baseline` - Baseline network configuration

### Management
- `manage-baseline.sh` - Script to backup, restore, and create baselines
- `README.md` - This documentation

## Usage

### Backup Current Configurations
```bash
sudo ./manage-baseline.sh backup
```

### Restore from Baseline
```bash
sudo ./manage-baseline.sh restore
```

### Create New Baseline
```bash
sudo ./manage-baseline.sh create
```

## Integration with Automated Remediation

When FIM alerts are triggered, the automated remediation system will:
1. Detect unauthorized changes
2. Compare current state against baseline
3. Restore configurations from baseline files
4. Log all remediation actions
5. Generate audit reports

## Version Control

These baseline files should be committed to version control to:
- Track configuration changes over time
- Enable rollback to previous configurations
- Maintain audit trail of approved changes
- Support compliance requirements

## Security Considerations

- Baseline files should be stored securely
- Access to baseline files should be restricted
- Changes to baseline files should require approval
- All baseline changes should be logged and audited

## Maintenance

Baseline configurations should be updated when:
- Approved system changes are made
- Security patches are applied
- New software is installed
- Configuration standards change

## Author

Gabriel Eweka  
Date: October 6, 2025
