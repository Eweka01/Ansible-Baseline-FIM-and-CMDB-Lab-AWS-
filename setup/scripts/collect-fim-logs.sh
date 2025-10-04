#!/bin/bash

# =============================================================================
# Centralized FIM Log Collection Script
# =============================================================================
#
# This script collects FIM logs from all AWS instances to your local machine
# for centralized monitoring and analysis. Perfect for master node operations.
#
# Features:
# - Collects FIM agent logs from all AWS instances
# - Collects FIM reports from all AWS instances
# - Organizes logs by instance and timestamp
# - Creates summary reports
# - Allows centralized log analysis
#
# Usage:
#     ./collect-fim-logs.sh [--all] [--recent] [--summary]
#
# Options:
#     --all      Collect all log files (may be large)
#     --recent   Collect only recent logs (last 100 lines)
#     --summary  Generate summary report only
#
# Author: Gabriel Eweka
# Version: 1.0.0
# =============================================================================

set -e

# Color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
ANSIBLE_DIR="../../ansible"
LOG_DIR="../../logs/aws-fim-logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Create log directory
mkdir -p "$LOG_DIR"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to collect FIM logs from all instances
collect_fim_logs() {
    local mode=${1:-"recent"}
    
    log_info "Collecting FIM logs from all AWS instances..."
    
    cd "$ANSIBLE_DIR"
    
    # Collect FIM agent logs
    log_info "Collecting FIM agent logs..."
    ansible aws_instances -i inventory/aws-instances -m shell -a "tail -100 /var/log/fim-agent.log" > "../logs/aws-fim-logs/fim-agent-logs-$TIMESTAMP.txt" 2>/dev/null || {
        log_error "Failed to collect FIM agent logs"
        return 1
    }
    
    # Collect FIM reports
    log_info "Collecting FIM reports..."
    ansible aws_instances -i inventory/aws-instances -m shell -a "tail -50 /var/log/fim-reports.json" > "../logs/aws-fim-logs/fim-reports-$TIMESTAMP.txt" 2>/dev/null || {
        log_error "Failed to collect FIM reports"
        return 1
    }
    
    # Collect individual instance logs
    log_info "Collecting individual instance logs..."
    for instance in manage-node-1 manage-node-2 manage-node-3; do
        log_info "Collecting logs from $instance..."
        ansible "$instance" -i inventory/aws-instances -m shell -a "tail -50 /var/log/fim-agent.log" > "../logs/aws-fim-logs/$instance-fim-logs-$TIMESTAMP.txt" 2>/dev/null || {
            log_warning "Failed to collect logs from $instance"
        }
    done
    
    cd ..
    log_success "FIM logs collected successfully!"
}

# Function to generate summary report
generate_summary() {
    log_info "Generating FIM summary report..."
    
    local summary_file="$LOG_DIR/fim-summary-$TIMESTAMP.txt"
    
    cat > "$summary_file" << EOF
# FIM Log Summary Report
Generated: $(date)
Timestamp: $TIMESTAMP

## AWS Instances Status
EOF

    cd "$ANSIBLE_DIR"
    
    # Get FIM service status
    echo "### FIM Service Status" >> "../$summary_file"
    ansible aws_instances -i inventory/aws-instances -m shell -a "systemctl is-active fim-agent" >> "../$summary_file" 2>/dev/null || echo "Failed to get service status" >> "../$summary_file"
    
    # Get recent FIM activity
    echo -e "\n### Recent FIM Activity" >> "../$summary_file"
    ansible aws_instances -i inventory/aws-instances -m shell -a "tail -5 /var/log/fim-agent.log | grep -E '(CRITICAL|WARNING|INFO)'" >> "../$summary_file" 2>/dev/null || echo "Failed to get recent activity" >> "../$summary_file"
    
    # Get log file sizes
    echo -e "\n### Log File Sizes" >> "../$summary_file"
    ansible aws_instances -i inventory/aws-instances -m shell -a "ls -lh /var/log/fim*" >> "../$summary_file" 2>/dev/null || echo "Failed to get log sizes" >> "../$summary_file"
    
    cd ..
    
    log_success "Summary report generated: $summary_file"
}

# Function to display collected logs
display_logs() {
    log_info "Displaying collected FIM logs..."
    
    echo -e "\n${BLUE}=== FIM LOG COLLECTION RESULTS ===${NC}\n"
    
    # Show summary
    if [ -f "$LOG_DIR/fim-summary-$TIMESTAMP.txt" ]; then
        echo -e "${GREEN}📊 Summary Report:${NC}"
        cat "$LOG_DIR/fim-summary-$TIMESTAMP.txt"
        echo -e "\n"
    fi
    
    # Show recent logs
    if [ -f "$LOG_DIR/fim-agent-logs-$TIMESTAMP.txt" ]; then
        echo -e "${GREEN}📋 Recent FIM Agent Logs:${NC}"
        tail -20 "$LOG_DIR/fim-agent-logs-$TIMESTAMP.txt"
        echo -e "\n"
    fi
    
    # Show individual instance logs
    for instance in manage-node-1 manage-node-2 manage-node-3; do
        if [ -f "$LOG_DIR/$instance-fim-logs-$TIMESTAMP.txt" ]; then
            echo -e "${GREEN}🖥️  $instance Logs:${NC}"
            tail -10 "$LOG_DIR/$instance-fim-logs-$TIMESTAMP.txt"
            echo -e "\n"
        fi
    done
}

# Main function
main() {
    echo -e "${BLUE}🔍 Centralized FIM Log Collection${NC}"
    echo -e "${BLUE}===================================${NC}\n"
    
    case "${1:-recent}" in
        "all")
            log_info "Collecting all FIM logs..."
            collect_fim_logs "all"
            ;;
        "recent")
            log_info "Collecting recent FIM logs..."
            collect_fim_logs "recent"
            ;;
        "summary")
            log_info "Generating summary only..."
            generate_summary
            ;;
        *)
            log_info "Collecting recent FIM logs and generating summary..."
            collect_fim_logs "recent"
            generate_summary
            ;;
    esac
    
    display_logs
    
    log_success "FIM log collection completed!"
    log_info "Logs saved to: $LOG_DIR"
    log_info "Latest timestamp: $TIMESTAMP"
}

# Run main function with all arguments
main "$@"
