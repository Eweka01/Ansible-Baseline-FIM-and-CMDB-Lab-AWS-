#!/bin/bash
# Audit Log Management Script
# Author: Gabriel Eweka
# Date: October 6, 2025

set -e

AUDIT_DIR="/var/log/audit"
LAB_DIR="/Users/osamudiameneweka/Desktop/Ansible Baseline, FIM, and CMDB Lab"
AUDIT_LOGGER="$LAB_DIR/audit-logs/audit-logger.py"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

create_audit_directories() {
    log "Creating audit directories"
    sudo mkdir -p "$AUDIT_DIR"
    sudo chmod 755 "$AUDIT_DIR"
    sudo chown root:root "$AUDIT_DIR"
}

setup_audit_logging() {
    log "Setting up audit logging"
    
    # Create audit log files
    sudo touch "$AUDIT_DIR/audit.log"
    sudo touch "$AUDIT_DIR/changes.log"
    sudo touch "$AUDIT_DIR/remediation.log"
    sudo touch "$AUDIT_DIR/security.log"
    
    # Set permissions
    sudo chmod 644 "$AUDIT_DIR"/*.log
    sudo chown root:root "$AUDIT_DIR"/*.log
}

generate_audit_report() {
    local output_file="$1"
    local start_date="$2"
    local end_date="$3"
    
    log "Generating audit report"
    
    if [ -z "$output_file" ]; then
        output_file="/tmp/audit-report-$(date +%Y%m%d_%H%M%S).json"
    fi
    
    python3 "$AUDIT_LOGGER" --action generate-report --output "$output_file" --start-date "$start_date" --end-date "$end_date"
    
    log "Audit report generated: $output_file"
}

export_audit_logs() {
    local output_file="$1"
    local start_date="$2"
    local end_date="$3"
    
    log "Exporting audit logs"
    
    if [ -z "$output_file" ]; then
        output_file="/tmp/audit-export-$(date +%Y%m%d_%H%M%S).json"
    fi
    
    python3 "$AUDIT_LOGGER" --action export --output "$output_file" --start-date "$start_date" --end-date "$end_date"
    
    log "Audit logs exported: $output_file"
}

cleanup_old_logs() {
    local days="$1"
    
    if [ -z "$days" ]; then
        days=30
    fi
    
    log "Cleaning up logs older than $days days"
    
    python3 "$AUDIT_LOGGER" --action cleanup --days "$days"
    
    log "Log cleanup completed"
}

show_audit_status() {
    log "Audit system status:"
    
    if [ -d "$AUDIT_DIR" ]; then
        echo "  Audit directory: $AUDIT_DIR (exists)"
        echo "  Audit log files:"
        for log_file in "$AUDIT_DIR"/*.log; do
            if [ -f "$log_file" ]; then
                size=$(du -h "$log_file" | cut -f1)
                lines=$(wc -l < "$log_file")
                echo "    $(basename "$log_file"): $size ($lines lines)"
            fi
        done
    else
        echo "  Audit directory: $AUDIT_DIR (not found)"
    fi
    
    if [ -f "$AUDIT_LOGGER" ]; then
        echo "  Audit logger: $AUDIT_LOGGER (exists)"
    else
        echo "  Audit logger: $AUDIT_LOGGER (not found)"
    fi
}

case "$1" in
    "setup")
        create_audit_directories
        setup_audit_logging
        log "Audit logging setup completed"
        ;;
    "report")
        generate_audit_report "$2" "$3" "$4"
        ;;
    "export")
        export_audit_logs "$2" "$3" "$4"
        ;;
    "cleanup")
        cleanup_old_logs "$2"
        ;;
    "status")
        show_audit_status
        ;;
    *)
        echo "Usage: $0 {setup|report|export|cleanup|status}"
        echo "  setup                    - Set up audit logging system"
        echo "  report [output] [start] [end] - Generate audit report"
        echo "  export [output] [start] [end] - Export audit logs"
        echo "  cleanup [days]           - Clean up old logs (default: 30 days)"
        echo "  status                   - Show audit system status"
        exit 1
        ;;
esac
