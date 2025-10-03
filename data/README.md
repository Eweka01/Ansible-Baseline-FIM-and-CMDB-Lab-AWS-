# Data Directory

This directory contains all data files, test results, and reports from the lab components.

## 📁 Structure

```
data/
├── test-results/    # FIM baseline data and test results
├── backups/         # Backup files and snapshots
├── reports/         # Generated reports and summaries
├── test-files/      # Test files for FIM monitoring
└── cmdb-test-data/  # CMDB collected data files
```

## 📊 Data Files

### Test Results
- `fim-baseline.json` - File Integrity Monitoring baseline data
- `fim-reports.json` - FIM change reports and alerts
- `fim-test-reports.json` - Test-specific FIM reports

### Reports
- `lab-test-report-*.txt` - Comprehensive lab test reports
- Contains test results, validation data, and status summaries

### Test Files
- `test1.txt` - Sample text file for FIM testing
- `config.conf` - Sample configuration file
- `script.sh` - Sample shell script

### CMDB Data
- `system_info-*.json` - System information collections
- `hardware_info-*.json` - Hardware information data
- `software_info-*.json` - Software and package information
- `integration-test.json` - Integration test results

## 🔍 How to Use

### View FIM Data
```bash
# View baseline data
cat data/test-results/fim-baseline.json | jq .

# View change reports
cat data/test-results/fim-reports.json | jq .

# Search for specific file changes
grep -i "modified" data/test-results/fim-reports.json
```

### View CMDB Data
```bash
# View system information
cat data/cmdb-test-data/system_info-*.json | jq '.system_info'

# View hardware information
cat data/cmdb-test-data/hardware_info-*.json | jq '.hardware_info'

# View software information
cat data/cmdb-test-data/software_info-*.json | jq '.software_info'
```

### View Reports
```bash
# View lab test reports
cat data/reports/lab-test-report-*.txt

# View specific test results
grep -i "success" data/reports/lab-test-report-*.txt
```

## 📈 Data Analysis

### FIM Analysis
```bash
# Count file changes by type
grep -o '"type":"[^"]*"' data/test-results/fim-reports.json | sort | uniq -c

# Find most changed files
grep -o '"path":"[^"]*"' data/test-results/fim-reports.json | sort | uniq -c
```

### CMDB Analysis
```bash
# Compare system information over time
diff data/cmdb-test-data/system_info-*.json

# Find system changes
grep -i "change" data/cmdb-test-data/*.json
```

## 🧹 Data Management

### Cleanup Old Data
```bash
# Remove old test files (keep last 7 days)
find data/ -name "*.json" -mtime +7 -delete

# Archive old reports
tar -czf data/backups/reports-$(date +%Y%m%d).tar.gz data/reports/
```

### Backup Important Data
```bash
# Backup FIM baseline
cp data/test-results/fim-baseline.json data/backups/

# Backup CMDB data
tar -czf data/backups/cmdb-data-$(date +%Y%m%d).tar.gz data/cmdb-test-data/
```

## 📊 Data Validation

### Validate JSON Files
```bash
# Validate FIM data
jq empty data/test-results/fim-baseline.json

# Validate CMDB data
jq empty data/cmdb-test-data/system_info-*.json
```

### Check Data Integrity
```bash
# Verify FIM baseline integrity
jq '.files | length' data/test-results/fim-baseline.json

# Check CMDB data completeness
jq '.system_info | keys' data/cmdb-test-data/system_info-*.json
```

## 🚨 Data Recovery

If data is corrupted or missing:

1. Check backup files in `data/backups/`
2. Re-run FIM baseline: `/opt/lab-env/bin/python /opt/lab-environment/fim-agent.py --init-baseline`
3. Re-run CMDB collection: `/opt/lab-env/bin/python /opt/lab-environment/cmdb-collector.py`
4. Check logs for error messages

## 📝 Data Retention

- **FIM Data**: Keep baseline and recent reports (30 days)
- **CMDB Data**: Keep daily snapshots (90 days)
- **Test Results**: Keep for analysis (7 days)
- **Reports**: Archive monthly (1 year)
