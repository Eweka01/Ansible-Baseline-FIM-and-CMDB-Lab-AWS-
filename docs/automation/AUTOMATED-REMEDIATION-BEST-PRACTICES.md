# Automated Remediation Best Practices

**Date**: October 6, 2025  
**Author**: Gabriel Eweka

## Overview

This document outlines best practices for automated remediation systems, focusing on targeting, scope, and safety measures.

---

## Current System Analysis

### **How the Restore Button Currently Works**

1. **Alert Detection**: Fetches all active (firing) alerts from Prometheus
2. **Alert Processing**: Processes each alert individually
3. **Node Mapping**: Maps instance to specific node using port mapping
4. **Targeted Remediation**: Runs remediation playbook only on the affected node
5. **Audit Logging**: Logs all remediation actions

### **Current Node Mapping**
```python
port_mapping = {
    'host.docker.internal:8080': 'manage-node-1',  # FIM agent
    'host.docker.internal:8081': 'manage-node-1',  # CMDB collector
    'host.docker.internal:8082': 'manage-node-2',  # FIM agent
    'host.docker.internal:8083': 'manage-node-2',  # CMDB collector
    'host.docker.internal:8084': 'manage-node-3',  # FIM agent
    'host.docker.internal:8085': 'manage-node-3',  # CMDB collector
    'host.docker.internal:9101': 'manage-node-1',  # Node Exporter
    'host.docker.internal:9102': 'manage-node-2',  # Node Exporter
    'host.docker.internal:9103': 'manage-node-3',  # Node Exporter
}
```

---

## Best Practices for Automated Remediation

### **1. Targeted Remediation (Current Approach) ✅**

**Principle**: Only remediate the specific node(s) affected by the alert.

**Benefits**:
- **Minimal Impact**: Reduces risk of affecting healthy systems
- **Faster Response**: Focuses resources on the actual problem
- **Better Isolation**: Prevents cascading failures
- **Audit Trail**: Clear record of what was fixed where

**Example**:
```
Alert: FIMFileChange on host.docker.internal:8082
Action: Run remediation only on manage-node-2
Result: Only node 2 is affected, nodes 1 and 3 remain untouched
```

### **2. Scope-Based Remediation**

#### **Single Node Issues** (Current Implementation)
- **FIM Agent Down**: Restart FIM agent on affected node only
- **CMDB Collector Down**: Restart CMDB collector on affected node only
- **File Changes**: Restore files on affected node only

#### **Multi-Node Issues** (Should be implemented)
- **Network Connectivity**: Check all nodes if network issues detected
- **Security Breach**: Scan all nodes if security incident detected
- **Configuration Drift**: Compare all nodes against baseline

#### **System-Wide Issues** (Should be implemented)
- **Authentication Failures**: Check all nodes if auth system compromised
- **Time Synchronization**: Sync all nodes if NTP issues detected
- **Certificate Expiry**: Update certificates on all affected nodes

### **3. Alert Classification and Routing**

#### **Critical Alerts** (Immediate Action)
```yaml
FIMUnauthorizedChange:
  scope: single_node
  action: immediate_restore
  notification: high_priority

FIMHighActivity:
  scope: single_node
  action: investigate_and_restore
  notification: high_priority
```

#### **Warning Alerts** (Investigation First)
```yaml
FIMFileChange:
  scope: single_node
  action: log_and_investigate
  notification: normal

CMDBCollectionFailure:
  scope: single_node
  action: restart_service
  notification: normal
```

#### **System Alerts** (Multi-Node Action)
```yaml
NetworkConnectivityIssue:
  scope: all_nodes
  action: check_connectivity
  notification: high_priority

SecurityIncident:
  scope: all_nodes
  action: security_scan
  notification: critical
```

---

## Recommended Improvements

### **1. Enhanced Alert Routing**

```python
def get_remediation_scope(alert_name, alert_labels):
    """Determine remediation scope based on alert type and context"""
    
    # Single node issues
    single_node_alerts = [
        'FIMFileChange', 'FIMHighActivity', 'FIMAgentDown',
        'CMDBCollectionFailure', 'CMDBCollectorDown',
        'NodeExporterDown', 'HighCPUUsage', 'HighMemoryUsage'
    ]
    
    # Multi-node issues
    multi_node_alerts = [
        'NetworkConnectivityIssue', 'DNSServerDown',
        'TimeSyncIssue', 'CertificateExpiry'
    ]
    
    # System-wide issues
    system_wide_alerts = [
        'SecurityIncident', 'AuthenticationFailure',
        'DatabaseConnectionIssue', 'LoadBalancerDown'
    ]
    
    if alert_name in single_node_alerts:
        return 'single_node'
    elif alert_name in multi_node_alerts:
        return 'multi_node'
    elif alert_name in system_wide_alerts:
        return 'system_wide'
    else:
        return 'investigate'
```

### **2. Remediation Strategies**

#### **Single Node Remediation** (Current)
```yaml
strategy: targeted
target: affected_node_only
safety: high
impact: minimal
```

#### **Multi-Node Remediation** (Recommended)
```yaml
strategy: parallel
target: affected_nodes
safety: medium
impact: controlled
```

#### **System-Wide Remediation** (Recommended)
```yaml
strategy: coordinated
target: all_nodes
safety: low
impact: high
approval: required
```

### **3. Safety Measures**

#### **Pre-Remediation Checks**
```python
def pre_remediation_safety_check(node_name, alert_type):
    """Perform safety checks before remediation"""
    
    checks = [
        check_node_connectivity(node_name),
        check_service_dependencies(node_name),
        check_disk_space(node_name),
        check_backup_availability(node_name),
        check_maintenance_window(node_name)
    ]
    
    return all(checks)
```

#### **Rollback Capability**
```python
def create_rollback_point(node_name, alert_type):
    """Create rollback point before remediation"""
    
    rollback_data = {
        'timestamp': datetime.now().isoformat(),
        'node': node_name,
        'alert_type': alert_type,
        'system_state': capture_system_state(node_name),
        'service_status': get_service_status(node_name),
        'file_backups': create_file_backups(node_name)
    }
    
    save_rollback_data(rollback_data)
    return rollback_data
```

---

## Implementation Recommendations

### **1. Current System Strengths** ✅
- **Targeted Remediation**: Only affects the specific node with the issue
- **Clear Node Mapping**: Well-defined mapping from instances to nodes
- **Audit Logging**: Comprehensive logging of all actions
- **Alert Classification**: Different handling for different alert types

### **2. Recommended Enhancements**

#### **A. Add Scope Detection**
```python
def determine_remediation_scope(alert):
    """Determine if remediation should be single-node or multi-node"""
    
    alert_name = alert.get('labels', {}).get('alertname', '')
    instance = alert.get('labels', {}).get('instance', '')
    
    # Check if this is a systemic issue
    if is_systemic_issue(alert_name, instance):
        return 'multi_node'
    else:
        return 'single_node'
```

#### **B. Add Safety Checks**
```python
def safe_remediation(node_name, alert_type):
    """Perform remediation with safety checks"""
    
    # Pre-checks
    if not pre_remediation_safety_check(node_name, alert_type):
        logger.error(f"Safety checks failed for {node_name}")
        return False
    
    # Create rollback point
    rollback_data = create_rollback_point(node_name, alert_type)
    
    # Perform remediation
    try:
        result = run_remediation(node_name, alert_type)
        logger.info(f"Remediation successful for {node_name}")
        return True
    except Exception as e:
        logger.error(f"Remediation failed for {node_name}: {e}")
        # Trigger rollback
        rollback_remediation(rollback_data)
        return False
```

#### **C. Add User Confirmation for High-Impact Actions**
```python
def requires_user_confirmation(alert_type, scope):
    """Determine if user confirmation is required"""
    
    high_impact_actions = [
        'system_wide_remediation',
        'security_incident_response',
        'database_maintenance',
        'network_reconfiguration'
    ]
    
    return scope in high_impact_actions
```

---

## Current System Assessment

### **✅ What's Working Well**
1. **Targeted Approach**: Only affects the specific node with the issue
2. **Clear Mapping**: Well-defined instance-to-node mapping
3. **Comprehensive Logging**: All actions are logged and auditable
4. **Alert-Specific Handling**: Different remediation for different alert types

### **⚠️ Areas for Improvement**
1. **Scope Detection**: No automatic detection of systemic vs. single-node issues
2. **Safety Checks**: Limited pre-remediation validation
3. **Rollback Capability**: No automatic rollback on failure
4. **User Confirmation**: No confirmation for high-impact actions

### **🎯 Recommended Next Steps**
1. **Implement scope detection** for systemic issues
2. **Add safety checks** before remediation
3. **Create rollback capability** for failed remediations
4. **Add user confirmation** for high-impact actions
5. **Enhance monitoring** of remediation success/failure

---

## Conclusion

The current system follows **targeted remediation best practices** by only affecting the specific node with the issue. This is the **correct approach** for most scenarios and minimizes risk.

**Key Takeaway**: The restore button currently targets only the affected node(s), which is the best practice for automated remediation systems.

---

*Last Updated: October 6, 2025*
