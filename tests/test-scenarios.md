# Lab Test Scenarios

This document outlines various test scenarios to validate the functionality of the Ansible Baseline, FIM, and CMDB lab environment.

## Test Environment Setup

### Prerequisites
- Virtual machines or containers for testing
- Network connectivity between test systems
- SSH key-based authentication configured
- Python 3.7+ installed on all systems

### Test Systems
- **Control Node**: Ansible control machine
- **Target Nodes**: 2-3 test systems (web servers, database, monitoring)
- **FIM Agent**: Systems with FIM monitoring enabled
- **CMDB Server**: Central data collection point

## Test Scenarios

### 1. Ansible Baseline Configuration

#### Scenario 1.1: Initial System Baseline
**Objective**: Verify that Ansible can establish a secure baseline on new systems

**Steps**:
1. Deploy a fresh Ubuntu/CentOS system
2. Run the baseline playbook: `ansible-playbook -i inventory/hosts playbooks/setup-baseline.yml`
3. Verify system configuration

**Expected Results**:
- Essential packages installed
- Security hardening applied
- Firewall configured
- SSH security settings applied
- System services properly configured
- Baseline completion marker created

**Validation Commands**:
```bash
# Check installed packages
dpkg -l | grep -E "(curl|wget|vim|htop|fail2ban|ufw)"

# Verify firewall status
sudo ufw status

# Check SSH configuration
sudo sshd -T | grep -E "(PermitRootLogin|PasswordAuthentication|PubkeyAuthentication)"

# Verify system services
systemctl is-enabled ssh
systemctl is-enabled cron
systemctl is-enabled rsyslog
```

#### Scenario 1.2: Configuration Drift Detection
**Objective**: Test Ansible's ability to detect and correct configuration drift

**Steps**:
1. Manually modify system configuration (disable firewall, change SSH settings)
2. Re-run the baseline playbook
3. Verify corrections are applied

**Expected Results**:
- Ansible detects changes
- Configuration is restored to baseline
- No errors during remediation

### 2. File Integrity Monitoring (FIM)

#### Scenario 2.1: FIM Agent Deployment
**Objective**: Deploy and configure FIM agents on target systems

**Steps**:
1. Install FIM agent on test systems
2. Configure monitoring paths
3. Initialize baseline
4. Start continuous monitoring

**Expected Results**:
- FIM agent running without errors
- Baseline database created
- Monitoring paths configured
- Log files generated

**Validation Commands**:
```bash
# Check FIM agent status
ps aux | grep fim-agent

# Verify baseline exists
ls -la /var/lib/fim/baseline.json

# Check FIM logs
tail -f /var/log/fim-agent.log
```

#### Scenario 2.2: File Change Detection
**Objective**: Test FIM's ability to detect file changes

**Steps**:
1. Create a test file in monitored directory
2. Modify an existing system file
3. Delete a monitored file
4. Check FIM reports

**Expected Results**:
- All changes detected and logged
- Alerts generated (if configured)
- Reports updated with change details

**Test Commands**:
```bash
# Create test file
sudo touch /etc/test-fim-file

# Modify system file
sudo echo "# Test modification" >> /etc/hosts

# Delete test file
sudo rm /etc/test-fim-file

# Check FIM reports
cat /var/log/fim-reports.json
```

#### Scenario 2.3: False Positive Handling
**Objective**: Verify FIM handles expected changes without false alerts

**Steps**:
1. Update system packages
2. Rotate log files
3. Update system configuration through Ansible
4. Verify FIM behavior

**Expected Results**:
- Expected changes logged but not flagged as suspicious
- No false positive alerts
- Baseline updated appropriately

### 3. Configuration Management Database (CMDB)

#### Scenario 3.1: Data Collection
**Objective**: Test CMDB data collection functionality

**Steps**:
1. Run CMDB collector on test systems
2. Verify data collection completeness
3. Check data format and structure

**Expected Results**:
- All data categories collected
- JSON format valid
- No collection errors
- Data files created in expected location

**Validation Commands**:
```bash
# Run CMDB collector
python3 cmdb/scripts/cmdb-collector.py

# Verify data files
ls -la /var/lib/cmdb/data/

# Validate JSON structure
python3 -m json.tool /var/lib/cmdb/data/cmdb-data-*.json
```

#### Scenario 3.2: Data Analysis
**Objective**: Test CMDB data analysis and reporting

**Steps**:
1. Collect data from multiple systems
2. Generate comparison reports
3. Identify configuration differences
4. Create compliance reports

**Expected Results**:
- Data comparison successful
- Differences identified and reported
- Compliance status determined
- Reports generated in expected format

#### Scenario 3.3: Change Tracking
**Objective**: Track configuration changes over time

**Steps**:
1. Collect baseline data
2. Make system changes
3. Collect updated data
4. Compare and identify changes

**Expected Results**:
- Changes tracked accurately
- Timestamps preserved
- Change history maintained
- Impact analysis possible

### 4. Integration Testing

#### Scenario 4.1: End-to-End Workflow
**Objective**: Test complete workflow from baseline to monitoring

**Steps**:
1. Deploy new system
2. Apply Ansible baseline
3. Deploy FIM agent
4. Start CMDB collection
5. Make test changes
6. Verify all components detect changes

**Expected Results**:
- All components work together
- Changes detected by multiple systems
- Consistent reporting across tools
- No conflicts between components

#### Scenario 4.2: Alert Integration
**Objective**: Test alerting and notification systems

**Steps**:
1. Configure alert destinations
2. Trigger test alerts
3. Verify alert delivery
4. Test alert escalation

**Expected Results**:
- Alerts generated for critical events
- Notifications delivered successfully
- Escalation rules followed
- Alert history maintained

### 5. Performance Testing

#### Scenario 5.1: System Impact
**Objective**: Measure impact of monitoring on system performance

**Steps**:
1. Measure baseline system performance
2. Deploy monitoring components
3. Measure performance impact
4. Optimize if necessary

**Expected Results**:
- Minimal performance impact
- Resource usage within acceptable limits
- No system instability
- Monitoring continues during high load

#### Scenario 5.2: Scalability Testing
**Objective**: Test system behavior with multiple monitored hosts

**Steps**:
1. Deploy monitoring to 10+ systems
2. Generate simultaneous changes
3. Monitor system performance
4. Test data collection efficiency

**Expected Results**:
- System handles multiple hosts
- Data collection scales appropriately
- No performance degradation
- Alert processing remains timely

### 6. Security Testing

#### Scenario 6.1: Access Control
**Objective**: Verify proper access controls and permissions

**Steps**:
1. Test unauthorized access attempts
2. Verify privilege escalation prevention
3. Check data encryption
4. Validate audit logging

**Expected Results**:
- Unauthorized access blocked
- Privilege escalation prevented
- Sensitive data encrypted
- All access attempts logged

#### Scenario 6.2: Data Protection
**Objective**: Test data protection and privacy measures

**Steps**:
1. Verify data encryption at rest
2. Test data transmission security
3. Check data retention policies
4. Validate data sanitization

**Expected Results**:
- Data encrypted in storage
- Secure transmission protocols
- Proper data retention
- Sensitive data sanitized

## Test Execution

### Automated Testing
```bash
# Run all tests
./tests/run-all-tests.sh

# Run specific test suite
./tests/run-tests.sh ansible
./tests/run-tests.sh fim
./tests/run-tests.sh cmdb
```

### Manual Testing
1. Follow individual test scenarios
2. Document results and issues
3. Report findings
4. Update test cases as needed

### Test Reporting
- Generate test reports after each run
- Track test coverage and results
- Maintain test history
- Document known issues and limitations

## Troubleshooting

### Common Issues
1. **SSH Connection Problems**: Check SSH keys and connectivity
2. **Permission Errors**: Verify sudo access and file permissions
3. **Service Failures**: Check service status and logs
4. **Data Collection Errors**: Verify Python dependencies and paths

### Debug Commands
```bash
# Check Ansible connectivity
ansible all -m ping

# Verify FIM agent status
systemctl status fim-agent

# Check CMDB collector logs
tail -f /var/log/cmdb-collector.log

# Validate configuration files
ansible-playbook --syntax-check playbooks/setup-baseline.yml
```

## Success Criteria

### Functional Requirements
- [ ] All test scenarios pass
- [ ] No critical errors or failures
- [ ] Performance within acceptable limits
- [ ] Security requirements met

### Non-Functional Requirements
- [ ] System stability maintained
- [ ] Documentation complete and accurate
- [ ] User experience satisfactory
- [ ] Maintenance procedures documented

