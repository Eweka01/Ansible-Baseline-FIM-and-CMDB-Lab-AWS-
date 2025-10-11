# 🔧 Updated SSH Commands for New AWS Instances

## 📋 **New IP Addresses**
- **manage-node-1**: `18.207.193.228` (Amazon Linux - ec2-user)
- **manage-node-2**: `34.229.187.190` (Ubuntu - ubuntu)
- **manage-node-3**: `52.207.162.175` (Ubuntu - ubuntu)

## 🚀 **Direct SSH Access**

### **Connect to Individual Nodes**
```bash
# Amazon Linux (manage-node-1)
ssh -i /Users/osamudiameneweka/Desktop/key-p3.pem ec2-user@18.207.193.228

# Ubuntu (manage-node-2)
ssh -i /Users/osamudiameneweka/Desktop/key-p3.pem ubuntu@34.229.187.190

# Ubuntu (manage-node-3)
ssh -i /Users/osamudiameneweka/Desktop/key-p3.pem ubuntu@52.207.162.175
```

## 🔗 **SSH Tunnels for Monitoring**

### **Node Exporter Tunnels (System Metrics)**
```bash
ssh -f -N -L 9101:localhost:9100 -i /Users/osamudiameneweka/Desktop/key-p3.pem ec2-user@18.207.193.228
ssh -f -N -L 9102:localhost:9100 -i /Users/osamudiameneweka/Desktop/key-p3.pem ubuntu@34.229.187.190
ssh -f -N -L 9103:localhost:9100 -i /Users/osamudiameneweka/Desktop/key-p3.pem ubuntu@52.207.162.175
```

### **FIM Agent Tunnels (File Integrity Monitoring)**
```bash
ssh -f -N -L 8080:localhost:8080 -i /Users/osamudiameneweka/Desktop/key-p3.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ec2-user@18.207.193.228
ssh -f -N -L 8082:localhost:8080 -i /Users/osamudiameneweka/Desktop/key-p3.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@34.229.187.190
ssh -f -N -L 8084:localhost:8080 -i /Users/osamudiameneweka/Desktop/key-p3.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@52.207.162.175
```

### **CMDB Collector Tunnels (Asset Management)**
```bash
ssh -f -N -L 8081:localhost:8081 -i /Users/osamudiameneweka/Desktop/key-p3.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ec2-user@18.207.193.228
ssh -f -N -L 8083:localhost:8081 -i /Users/osamudiameneweka/Desktop/key-p3.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@34.229.187.190
ssh -f -N -L 8085:localhost:8081 -i /Users/osamudiameneweka/Desktop/key-p3.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR ubuntu@52.207.162.175
```

## 🧪 **Quick Test Commands**

### **Test SSH Connectivity**
```bash
ssh -i /Users/osamudiameneweka/Desktop/key-p3.pem ec2-user@18.207.193.228 "echo 'Node 1 connected'"
ssh -i /Users/osamudiameneweka/Desktop/key-p3.pem ubuntu@34.229.187.190 "echo 'Node 2 connected'"
ssh -i /Users/osamudiameneweka/Desktop/key-p3.pem ubuntu@52.207.162.175 "echo 'Node 3 connected'"
```

### **Test FIM Alert (Create Test File)**
```bash
ssh -i /Users/osamudiameneweka/Desktop/key-p3.pem ec2-user@18.207.193.228 "echo 'test' | sudo tee /etc/test-alert.txt"
```

### **Test High CPU Load**
```bash
ssh -i /Users/osamudiameneweka/Desktop/key-p3.pem ec2-user@18.207.193.228 "stress --cpu 4 --timeout 300s"
```

### **Stop FIM Agent (Test Service Down Alert)**
```bash
ssh -i /Users/osamudiameneweka/Desktop/key-p3.pem ec2-user@18.207.193.228 "sudo systemctl stop fim-agent-prometheus"
```

### **Restart FIM Agent**
```bash
ssh -i /Users/osamudiameneweka/Desktop/key-p3.pem ec2-user@18.207.193.228 "sudo systemctl restart fim-agent-prometheus"
```

## 📊 **Access URLs**
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000
- **Main Dashboard**: http://localhost:8088/simple-monitoring-dashboard.html
- **Restoration Dashboard**: http://localhost:8089/restoration-monitoring-dashboard.html

## 🔧 **Tunnel Management**
```bash
# Kill all SSH tunnels
pkill -f "ssh.*-L"

# Check tunnel status
ps aux | grep "ssh.*-L" | grep -v grep

# Restart all tunnels
./restart-monitoring-lab.sh
```

---
**Last Updated**: $(date)
**Status**: ✅ All IP addresses updated and verified
