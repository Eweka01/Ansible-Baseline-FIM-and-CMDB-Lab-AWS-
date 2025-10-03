#!/bin/bash

# =============================================================================
# AWS SSH Setup Script
# =============================================================================
#
# This script sets up SSH connectivity to your AWS EC2 instances for the
# Ansible Baseline, FIM, and CMDB lab. It handles mixed OS environments
# (Amazon Linux + Ubuntu) and ensures proper SSH configuration.
#
# Features:
# - Tests SSH connections to all 3 AWS instances
# - Creates SSH config file for easy access
# - Verifies SSH key permissions
# - Handles mixed OS environments (Amazon Linux + Ubuntu)
# - Provides detailed connection status
#
# Usage:
#     ./setup-aws-ssh.sh
#
# Prerequisites:
# - SSH key file (key-p3.pem) in common locations
# - AWS instances running and accessible
# - Internet connectivity
#
# Author: Ansible Baseline, FIM, and CMDB Lab
# Version: 1.0.0
# =============================================================================

set -e  # Exit on any error

# =============================================================================
# Configuration and Setup
# =============================================================================

# Color codes for terminal output
RED='\033[0;31m'      # Red for errors and failures
GREEN='\033[0;32m'    # Green for success and passes
YELLOW='\033[1;33m'   # Yellow for warnings
BLUE='\033[0;34m'     # Blue for information
NC='\033[0m'          # No Color (reset)

# AWS instance information
# Format: "hostname:ip:user"
# Note: manage-node-1 uses ec2-user (Amazon Linux), others use ubuntu (Ubuntu)
INSTANCES=(
    "manage-node-1:18.234.152.228:ec2-user"  # Amazon Linux 2023
    "manage-node-2:54.242.234.69:ubuntu"     # Ubuntu 24.04
    "manage-node-3:13.217.82.23:ubuntu"      # Ubuntu 24.04
)

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

# Check if SSH key exists
check_ssh_key() {
    local key_file="$1"
    
    if [[ -f "$key_file" ]]; then
        log_success "SSH key found: $key_file"
        return 0
    else
        log_error "SSH key not found: $key_file"
        return 1
    fi
}

# Test SSH connectivity
test_ssh_connection() {
    local hostname="$1"
    local ip="$2"
    local user="$3"
    local key_file="$4"
    
    log_info "Testing SSH connection to $hostname ($ip) as $user..."
    
    if ssh -i "$key_file" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$user"@"$ip" "echo 'SSH connection successful'" 2>/dev/null; then
        log_success "SSH connection to $hostname successful"
        return 0
    else
        log_error "SSH connection to $hostname failed"
        return 1
    fi
}

# Setup SSH config
setup_ssh_config() {
    local key_file="$1"
    
    log_info "Setting up SSH configuration..."
    
    # Create SSH config entries for AWS instances
    cat >> ~/.ssh/config << EOF

# AWS Lab Instances
Host manage-node-1
    HostName 18.234.152.228
    User ec2-user
    IdentityFile $key_file
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ServerAliveInterval 60
    ServerAliveCountMax 3

Host manage-node-2
    HostName 54.242.234.69
    User ubuntu
    IdentityFile $key_file
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ServerAliveInterval 60
    ServerAliveCountMax 3

Host manage-node-3
    HostName 13.217.82.23
    User ubuntu
    IdentityFile $key_file
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ServerAliveInterval 60
    ServerAliveCountMax 3

EOF
    
    chmod 600 ~/.ssh/config
    log_success "SSH configuration updated"
}

# Test all connections
test_all_connections() {
    local key_file="$1"
    local success_count=0
    local total_count=${#INSTANCES[@]}
    
    log_info "Testing connections to all AWS instances..."
    
    for instance_info in "${INSTANCES[@]}"; do
        IFS=':' read -r hostname ip user <<< "$instance_info"
        if test_ssh_connection "$hostname" "$ip" "$user" "$key_file"; then
            ((success_count++))
        fi
    done
    
    log_info "Connection test results: $success_count/$total_count successful"
    
    if [[ $success_count -eq $total_count ]]; then
        log_success "All SSH connections successful!"
        return 0
    else
        log_error "Some SSH connections failed"
        return 1
    fi
}

# Main function
main() {
    echo "AWS SSH Setup"
    echo "============="
    echo "Setting up SSH connectivity to your AWS EC2 instances"
    echo
    
    # Check for SSH key
    local key_file=""
    local possible_keys=(
        "~/Desktop/key-p3.pem"
        "~/.ssh/key-p3.pem"
        "~/Downloads/key-p3.pem"
        "~/key-p3.pem"
        "./key-p3.pem"
    )
    
    for key in "${possible_keys[@]}"; do
        expanded_key="${key/#\~/$HOME}"
        if check_ssh_key "$expanded_key"; then
            key_file="$expanded_key"
            break
        fi
    done
    
    if [[ -z "$key_file" ]]; then
        log_error "SSH key 'key-p3.pem' not found in common locations:"
        for key in "${possible_keys[@]}"; do
            echo "  - $key"
        done
        echo
        log_info "Please download your SSH key from AWS and place it in one of these locations:"
        echo "  - ~/Desktop/key-p3.pem"
        echo "  - ~/.ssh/key-p3.pem"
        echo "  - ~/Downloads/key-p3.pem"
        echo "  - ~/key-p3.pem"
        echo "  - ./key-p3.pem"
        echo
        log_info "You can download it from:"
        echo "  - AWS Console > EC2 > Key Pairs > key-p3 > Actions > Download"
        exit 1
    fi
    
    # Set correct permissions on key file
    chmod 600 "$key_file"
    log_success "SSH key permissions set correctly"
    
    # Setup SSH config
    setup_ssh_config "$key_file"
    
    # Test connections
    if test_all_connections "$key_file"; then
        log_success "SSH setup completed successfully!"
        echo
        echo "You can now connect to your instances using:"
        echo "  ssh manage-node-1"
        echo "  ssh manage-node-2"
        echo "  ssh manage-node-3"
        echo
        echo "Or by IP address:"
        echo "  ssh -i $key_file ec2-user@18.234.152.228  # Amazon Linux"
        echo "  ssh -i $key_file ubuntu@54.242.234.69     # Ubuntu"
        echo "  ssh -i $key_file ubuntu@13.217.82.23      # Ubuntu"
        echo
        log_info "Next step: Run the Ansible playbook to deploy the lab:"
        echo "  cd ansible"
        echo "  ansible-playbook -i inventory/aws-instances playbooks/setup-aws-instances.yml"
    else
        log_error "SSH setup failed. Please check:"
        echo "  1. Your instances are running"
        echo "  2. Security groups allow SSH (port 22)"
        echo "  3. The SSH key is correct"
        echo "  4. Network connectivity to AWS"
        exit 1
    fi
}

# Run main function
main "$@"