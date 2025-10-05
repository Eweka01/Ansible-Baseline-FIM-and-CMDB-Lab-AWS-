# Operations Runbook

## 🎯 **Current Lab Status: FULLY OPERATIONAL**

### **Live Monitoring Status:**
- ✅ **Prometheus Targets**: 8/9 UP (collecting live metrics)
- ✅ **FIM Metrics**: 324+ events available (14,000+ total events)
- ✅ **CMDB Metrics**: 3 collections available (11+ total collections)
- ✅ **SSH Tunnels**: 11 active tunnels for secure monitoring
- ✅ **Real-time Dashboard**: http://localhost:8088/simple-monitoring-dashboard.html
- ✅ **Real-time Updates**: Every 15 seconds

### **Quick Access:**
- **Start Everything**: `./start-monitoring-lab.sh`
- **Stop Everything**: `./stop-monitoring-lab.sh`
- **Dashboard Only**: `./start_dashboard.sh`
- **Tunnel Management**: `./manage-tunnels.sh`

---

## Day-2 Operations

### Adding New Nodes

#### 1. Add Node to Inventory
**File**: `ansible/inventory/aws-instances`

```ini
# Add new node to appropriate group
[webservers]
manage-node-1 ansible_host=18.234.152.228 ansible_user=ec2-user
manage-node-4 ansible_host=NEW_IP_ADDRESS ansible_user=ubuntu

# Update aws_instances group if needed
[aws_instances:children]
webservers
databases
monitoring
```

#### 2. Deploy to New Node
```bash
# Deploy to specific new node
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml --limit manage-node-4

# Verify deployment
ansible manage-node-4 -i ansible/inventory/aws-instances -m ping
```

#### 3. Setup SSH Tunnel for New Node
```bash
# Add tunnel configuration to setup-ssh-tunnel-monitoring.sh
# Port mapping: 9104 for Node Exporter, 8086 for FIM, 8087 for CMDB

# Update prometheus.yml with new targets
# Add to aws-nodes job: 'host.docker.internal:9104'
# Add to fim-agents job: 'host.docker.internal:8086'  
# Add to cmdb-collectors job: 'host.docker.internal:8087'

# Restart monitoring stack
docker compose -f docker-compose.yml restart prometheus
```

### Key Rotation

#### SSH Key Rotation
```bash
# Generate new SSH key pair
ssh-keygen -t rsa -b 4096 -f ~/Desktop/key-p4.pem

# Update inventory with new key
# File: ansible/inventory/aws-instances
ansible_ssh_private_key_file=~/Desktop/key-p4.pem

# Deploy new key to all instances
ansible aws_instances -i ansible/inventory/aws-instances -m authorized_key -a "user=ec2-user key='{{ lookup('file', '~/Desktop/key-p4.pub') }}'"

# Test new key
ansible aws_instances -i ansible/inventory/aws-instances -m ping

# Remove old key (after verification)
ansible aws_instances -i ansible/inventory/aws-instances -m authorized_key -a "user=ec2-user key='{{ lookup('file', '~/Desktop/key-p3.pub') }}' state=absent"
```

#### Service Account Key Rotation
```bash
# Rotate node_exporter user password
ansible aws_instances -i ansible/inventory/aws-instances -m user -a "name=node_exporter password='{{ vaulted_password }}'"

# Restart affected services
ansible aws_instances -i ansible/inventory/aws-instances -m systemd -a "name=node_exporter state=restarted"
```

### Patching and Updates

#### System Package Updates
```bash
# Update all packages
ansible aws_instances -i ansible/inventory/aws-instances -m apt -a "upgrade=dist update_cache=yes" --become

# Update specific packages
ansible aws_instances -i ansible/inventory/aws-instances -m apt -a "name=openssh-server state=latest" --become

# Reboot if kernel updated
ansible aws_instances -i ansible/inventory/aws-instances -m reboot --become
```

#### Application Updates
```bash
# Update FIM agent
ansible aws_instances -i ansible/inventory/aws-instances -m copy -a "src=fim/agents/fim-agent.py dest=/opt/lab-environment/fim-agent.py mode=0755" --become

# Restart FIM service
ansible aws_instances -i ansible/inventory/aws-instances -m systemd -a "name=fim-agent state=restarted" --become

# Update CMDB collector
ansible aws_instances -i ansible/inventory/aws-instances -m copy -a "src=cmdb/scripts/cmdb-collector.py dest=/opt/lab-environment/cmdb-collector.py mode=0755" --become
```

### Rolling Back Changes

#### Configuration Rollback
```bash
# Rollback using Ansible checkpoints
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml --check --diff

# Restore from backup
ansible aws_instances -i ansible/inventory/aws-instances -m copy -a "src=/backup/ssh/sshd_config.backup dest=/etc/ssh/sshd_config" --become

# Restart services after rollback
ansible aws_instances -i ansible/inventory/aws-instances -m systemd -a "name=ssh state=restarted" --become
```

#### Service Rollback
```bash
# Stop problematic service
ansible aws_instances -i ansible/inventory/aws-instances -m systemd -a "name=fim-agent state=stopped" --become

# Restore previous version
ansible aws_instances -i ansible/inventory/aws-instances -m copy -a "src=/backup/fim-agent.py dest=/opt/lab-environment/fim-agent.py" --become

# Start service
ansible aws_instances -i ansible/inventory/aws-instances -m systemd -a "name=fim-agent state=started" --become
```

## Drift Detection and Correction

### Configuration Drift Scenarios

#### SSH Configuration Drift
**Symptom**: SSH access fails or security settings changed
**Detection**: FIM alerts on `/etc/ssh/sshd_config` changes
**Correction**:
```bash
# Check current configuration
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "sshd -T | grep -E '(PermitRootLogin|PasswordAuthentication)'"

# Restore correct configuration
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml --tags security

# Verify correction
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "systemctl reload ssh"
```

#### Firewall Rule Drift
**Symptom**: Unexpected network access or blocked legitimate traffic
**Detection**: CMDB shows changed firewall rules
**Correction**:
```bash
# Check current firewall status
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "ufw status verbose"

# Reset firewall to baseline
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "ufw --force reset" --become

# Reapply baseline rules
ansible-playbook -i ansible/inventory/aws-instances ansible/playbooks/setup-aws-instances.yml --tags security
```

#### Service Configuration Drift
**Symptom**: Services not running or misconfigured
**Detection**: Systemd service status checks
**Correction**:
```bash
# Check service status
ansible aws_instances -i ansible/inventory/aws-instances -m systemd -a "name=fim-agent"

# Restore service configuration
ansible aws_instances -i ansible/inventory/aws-instances -m copy -a "src=ansible/playbooks/templates/fim-agent.service.j2 dest=/etc/systemd/system/fim-agent.service" --become

# Reload and restart
ansible aws_instances -i ansible/inventory/aws-instances -m systemd -a "daemon_reload=yes"
ansible aws_instances -i ansible/inventory/aws-instances -m systemd -a "name=fim-agent state=restarted"
```

### Automated Drift Correction

#### FIM Baseline Update
```bash
# Update FIM baseline after legitimate changes
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "/opt/lab-env/bin/python /opt/lab-environment/fim-agent.py --update-baseline"

# Verify baseline update
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "ls -la /var/lib/fim/baseline.json"
```

#### CMDB Reconciliation
```bash
# Force CMDB data refresh
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "/opt/lab-env/bin/python /opt/lab-environment/cmdb-collector.py"

# Compare with expected baseline
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "diff /var/lib/cmdb/data/system-info.json /etc/system-info"
```

## Troubleshooting Matrix

### SSH Connection Issues

| Symptom | Probable Cause | Verification | Fix Command |
|---------|----------------|--------------|-------------|
| Connection timeout | Security group blocking | `telnet IP 22` | Update AWS security group |
| Permission denied | Wrong SSH key | `ssh -i key.pem user@IP` | Check key path in inventory |
| Host key verification failed | New instance | `ssh-keygen -R IP` | Add to known_hosts or use `-o StrictHostKeyChecking=no` |

### Service Issues

| Symptom | Probable Cause | Verification | Fix Command |
|---------|----------------|--------------|-------------|
| FIM agent not running | Python environment issue | `systemctl status fim-agent` | `systemctl restart fim-agent` |
| CMDB collector failing | Permission issue | `journalctl -u cmdb-collector` | Check `/var/lib/cmdb/data/` permissions |
| Node Exporter down | Port conflict | `netstat -tlnp \| grep 9100` | `systemctl restart node_exporter` |

### Monitoring Issues

| Symptom | Probable Cause | Verification | Fix Command |
|---------|----------------|--------------|-------------|
| No metrics in Prometheus | SSH tunnel down | `netstat -an \| grep 9101` | `./setup-ssh-tunnel-monitoring.sh` |
| Grafana dashboards empty | Data source issue | Check Grafana data sources | Restart Grafana container |
| Alerts not firing | Rule configuration | Check Prometheus rules | Update `prometheus-alerts.yml` |

### Performance Issues

| Symptom | Probable Cause | Verification | Fix Command |
|---------|----------------|--------------|-------------|
| High CPU usage | FIM scanning too frequent | `top -p $(pgrep fim-agent)` | Adjust `fim_scan_interval` |
| Memory exhaustion | CMDB data accumulation | `du -sh /var/lib/cmdb/data/` | Clean old data files |
| Slow Ansible runs | Network latency | `ansible aws_instances -m ping` | Use `-f` for parallel execution |

## Log Locations and Monitoring

### Log File Locations

#### System Logs
```bash
# Ansible execution logs
tail -f ansible/ansible.log

# System service logs
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "journalctl -u fim-agent -f"
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "journalctl -u node_exporter -f"
```

#### Application Logs
```bash
# FIM agent logs
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "tail -f /var/log/fim-agent.log"

# CMDB collector logs
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "tail -f /var/log/cmdb-collector.log"

# Security audit logs
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "tail -f /var/log/audit/audit.log"
```

#### Monitoring Logs
```bash
# Prometheus logs
docker logs ansiblebaselinefimandcmdblab-prometheus-1 -f

# Grafana logs
docker logs ansiblebaselinefimandcmdblab-grafana-1 -f

# SSH tunnel logs
tail -f /var/log/ssh-tunnels.log
```

### Log Querying and Analysis

#### Real-time Log Monitoring
```bash
# Monitor all FIM events across instances
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "tail -f /var/log/fim-agent.log" | grep -E "(CHANGED|NEW|DELETED)"

# Monitor security events
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "tail -f /var/log/audit/audit.log" | grep -E "(sshd|sudo|su)"

# Monitor system performance
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "iostat -x 1"
```

#### Log Analysis Commands
```bash
# Count FIM events by type
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "grep -c 'CHANGED' /var/log/fim-agent.log"

# Find failed SSH attempts
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "grep 'Failed password' /var/log/auth.log | wc -l"

# Check CMDB collection frequency
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "ls -la /var/lib/cmdb/data/ | wc -l"
```

### Metrics and Alerting

#### Prometheus Queries
```bash
# Check target health
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health != "up")'

# Query FIM events
curl -s 'http://localhost:9090/api/v1/query?query=fim_events_total' | jq '.data.result'

# Check system metrics
curl -s 'http://localhost:9090/api/v1/query?query=node_cpu_seconds_total' | jq '.data.result'
```

#### Grafana Dashboard Access
```bash
# Access main dashboards
open http://localhost:3000/d/lab-dashboard
open http://localhost:3000/d/fim-cmdb-dashboard

# Check alert status
curl -u admin:admin http://localhost:3000/api/alerts
```

## Emergency Procedures

### Service Recovery
```bash
# Emergency service restart
ansible aws_instances -i ansible/inventory/aws-instances -m systemd -a "name=fim-agent state=restarted" --become

# Emergency monitoring restart
docker compose -f docker-compose.yml restart

# Emergency tunnel restart
./setup-ssh-tunnel-monitoring.sh
```

### Data Recovery
```bash
# Restore FIM baseline from backup
ansible aws_instances -i ansible/inventory/aws-instances -m copy -a "src=/backup/fim/baseline.json dest=/var/lib/fim/baseline.json" --become

# Restore CMDB data
ansible aws_instances -i ansible/inventory/aws-instances -m copy -a "src=/backup/cmdb/ dest=/var/lib/cmdb/data/" --become
```

### Security Incident Response
```bash
# Immediate security lockdown
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "ufw --force enable" --become

# Check for unauthorized changes
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "/opt/lab-env/bin/python /opt/lab-environment/fim-agent.py --scan-once"

# Review audit logs
ansible aws_instances -i ansible/inventory/aws-instances -m shell -a "ausearch -m USER_LOGIN -ts today"
```

This runbook provides comprehensive operational procedures for maintaining and troubleshooting the lab environment in production scenarios.
