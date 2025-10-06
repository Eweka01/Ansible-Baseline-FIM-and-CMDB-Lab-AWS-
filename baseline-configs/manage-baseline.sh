#!/bin/bash
# Baseline Configuration Management Script
# Author: Gabriel Eweka
# Date: October 6, 2025

set -e

BASELINE_DIR="/Users/osamudiameneweka/Desktop/Ansible Baseline, FIM, and CMDB Lab/baseline-configs"
LOG_FILE="/var/log/baseline-management.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

backup_config() {
    local config_file="$1"
    local backup_file="$config_file.backup.$(date +%Y%m%d_%H%M%S)"
    
    if [ -f "$config_file" ]; then
        cp "$config_file" "$backup_file"
        log "Backed up $config_file to $backup_file"
    else
        log "Warning: $config_file does not exist"
    fi
}

restore_config() {
    local config_file="$1"
    local baseline_file="$2"
    
    if [ -f "$baseline_file" ]; then
        backup_config "$config_file"
        cp "$baseline_file" "$config_file"
        log "Restored $config_file from baseline"
    else
        log "Error: Baseline file $baseline_file does not exist"
        return 1
    fi
}

create_baseline() {
    local config_file="$1"
    local baseline_file="$2"
    
    if [ -f "$config_file" ]; then
        cp "$config_file" "$baseline_file"
        log "Created baseline for $config_file"
    else
        log "Error: Source file $config_file does not exist"
        return 1
    fi
}

case "$1" in
    "backup")
        log "Starting configuration backup"
        backup_config "/etc/hosts"
        backup_config "/etc/ssh/sshd_config"
        backup_config "/etc/sudoers"
        log "Configuration backup completed"
        ;;
    "restore")
        log "Starting configuration restore"
        restore_config "/etc/hosts" "$BASELINE_DIR/hosts.baseline"
        restore_config "/etc/ssh/sshd_config" "$BASELINE_DIR/sshd_config.baseline"
        restore_config "/etc/sudoers" "$BASELINE_DIR/sudoers.baseline"
        log "Configuration restore completed"
        ;;
    "create")
        log "Starting baseline creation"
        create_baseline "/etc/hosts" "$BASELINE_DIR/hosts.baseline"
        create_baseline "/etc/ssh/sshd_config" "$BASELINE_DIR/sshd_config.baseline"
        create_baseline "/etc/sudoers" "$BASELINE_DIR/sudoers.baseline"
        log "Baseline creation completed"
        ;;
    *)
        echo "Usage: $0 {backup|restore|create}"
        echo "  backup  - Backup current configurations"
        echo "  restore - Restore configurations from baseline"
        echo "  create  - Create new baseline from current configurations"
        exit 1
        ;;
esac
