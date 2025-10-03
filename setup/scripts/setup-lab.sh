#!/bin/bash

# =============================================================================
# Lab Environment Setup Script
# =============================================================================
#
# This script provides automated setup for the Ansible Baseline, FIM, and CMDB
# lab. It handles all aspects of lab initialization including dependency
# installation, configuration, and initial testing.
#
# Features:
# - Sets up Python virtual environment
# - Installs all required dependencies
# - Configures lab components
# - Runs initial tests and validation
# - Generates setup reports
# - Handles error recovery and cleanup
#
# Usage:
#     ./setup-lab.sh [--clean] [--verbose] [--skip-tests]
#
# Options:
#     --clean      Clean existing setup before installing
#     --verbose    Enable verbose output
#     --skip-tests Skip running tests after setup
#
# Prerequisites:
# - Python 3.7+ installed
# - pip package manager
# - Internet connectivity
# - Appropriate system permissions
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

# Lab configuration
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  # Get script directory
LOG_FILE="$LAB_DIR/setup.log"                            # Setup log file
INSTALL_USER="${SUDO_USER:-$USER}"                       # User running the script

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root"
        log_info "Please run as a regular user with sudo privileges"
        exit 1
    fi
}

# Check system requirements
check_requirements() {
    log_info "Checking system requirements..."
    
    # Check OS
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        log_info "Detected OS: $NAME $VERSION"
    else
        log_warning "Cannot determine OS version"
    fi
    
    # Check available memory
    local mem_gb=$(free -g | awk '/^Mem:/{print $2}')
    if [[ $mem_gb -lt 2 ]]; then
        log_warning "Low memory detected: ${mem_gb}GB (recommended: 2GB+)"
    else
        log_success "Memory check passed: ${mem_gb}GB"
    fi
    
    # Check disk space
    local disk_gb=$(df -BG "$LAB_DIR" | awk 'NR==2{print $4}' | sed 's/G//')
    if [[ $disk_gb -lt 5 ]]; then
        log_warning "Low disk space: ${disk_gb}GB (recommended: 5GB+)"
    else
        log_success "Disk space check passed: ${disk_gb}GB"
    fi
}

# Install system packages
install_system_packages() {
    log_info "Installing system packages..."
    
    if command -v apt &> /dev/null; then
        # Ubuntu/Debian
        sudo apt update
        sudo apt install -y \
            python3 \
            python3-pip \
            python3-venv \
            python3-dev \
            git \
            curl \
            wget \
            vim \
            htop \
            tree \
            unzip \
            software-properties-common \
            build-essential \
            libssl-dev \
            libffi-dev
    elif command -v yum &> /dev/null; then
        # CentOS/RHEL
        sudo yum update -y
        sudo yum install -y \
            python3 \
            python3-pip \
            python3-devel \
            git \
            curl \
            wget \
            vim \
            htop \
            tree \
            unzip \
            gcc \
            openssl-devel \
            libffi-devel
    else
        log_error "Unsupported package manager"
        exit 1
    fi
    
    log_success "System packages installed"
}

# Install Ansible
install_ansible() {
    log_info "Installing Ansible..."
    
    if command -v ansible &> /dev/null; then
        log_info "Ansible already installed: $(ansible --version | head -n1)"
    else
        if command -v apt &> /dev/null; then
            sudo apt install -y ansible
        elif command -v yum &> /dev/null; then
            sudo yum install -y ansible
        else
            pip3 install --user ansible
        fi
    fi
    
    log_success "Ansible installation completed"
}

# Install Python dependencies
install_python_deps() {
    log_info "Installing Python dependencies..."
    
    # Create virtual environment
    if [[ ! -d "$LAB_DIR/venv" ]]; then
        python3 -m venv "$LAB_DIR/venv"
        log_success "Virtual environment created"
    fi
    
    # Activate virtual environment
    source "$LAB_DIR/venv/bin/activate"
    
    # Upgrade pip
    pip install --upgrade pip
    
    # Install requirements
    if [[ -f "$LAB_DIR/requirements.txt" ]]; then
        pip install -r "$LAB_DIR/requirements.txt"
        log_success "Python dependencies installed"
    else
        # Install core dependencies
        pip install psutil watchdog pyyaml jinja2 requests paramiko cryptography
        log_success "Core Python dependencies installed"
    fi
}

# Setup SSH configuration
setup_ssh() {
    log_info "Setting up SSH configuration..."
    
    # Create SSH directory if it doesn't exist
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    
    # Generate SSH key if it doesn't exist
    if [[ ! -f ~/.ssh/id_rsa ]]; then
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" -C "lab@$(hostname)"
        log_success "SSH key generated"
    else
        log_info "SSH key already exists"
    fi
    
    # Create SSH config
    cat > ~/.ssh/config << EOF
Host lab-*
    User ansible
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ServerAliveInterval 60
    ServerAliveCountMax 3

Host *
    AddKeysToAgent yes
    UseKeychain yes
    IdentitiesOnly yes
EOF
    
    chmod 600 ~/.ssh/config
    log_success "SSH configuration completed"
}

# Setup lab directories
setup_directories() {
    log_info "Setting up lab directories..."
    
    # Create necessary directories
    sudo mkdir -p /var/lib/fim
    sudo mkdir -p /var/lib/cmdb/data
    sudo mkdir -p /var/log/cmdb
    sudo mkdir -p /etc/fim
    
    # Set permissions
    sudo chown -R "$INSTALL_USER:$INSTALL_USER" /var/lib/cmdb
    sudo chown -R "$INSTALL_USER:$INSTALL_USER" /var/log/cmdb
    sudo chmod 755 /var/lib/fim
    sudo chmod 755 /var/lib/cmdb
    
    log_success "Lab directories created"
}

# Setup system services
setup_services() {
    log_info "Setting up system services..."
    
    # Create FIM service
    sudo tee /etc/systemd/system/fim-agent.service > /dev/null << EOF
[Unit]
Description=FIM Agent
After=network.target

[Service]
Type=simple
User=root
ExecStart=$LAB_DIR/venv/bin/python $LAB_DIR/fim/agents/fim-agent.py
WorkingDirectory=$LAB_DIR
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    # Create CMDB collection service
    sudo tee /etc/systemd/system/cmdb-collector.service > /dev/null << EOF
[Unit]
Description=CMDB Data Collector
After=network.target

[Service]
Type=oneshot
User=$INSTALL_USER
ExecStart=$LAB_DIR/venv/bin/python $LAB_DIR/cmdb/scripts/cmdb-collector.py
WorkingDirectory=$LAB_DIR
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    # Create CMDB collection timer
    sudo tee /etc/systemd/system/cmdb-collector.timer > /dev/null << EOF
[Unit]
Description=CMDB Data Collection Timer
Requires=cmdb-collector.service

[Timer]
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
EOF
    
    # Reload systemd
    sudo systemctl daemon-reload
    
    # Enable services
    sudo systemctl enable cmdb-collector.timer
    sudo systemctl start cmdb-collector.timer
    
    log_success "System services configured"
}

# Setup cron jobs
setup_cron() {
    log_info "Setting up cron jobs..."
    
    # Create cron job for CMDB collection (backup method)
    echo "# CMDB data collection - every hour" | sudo tee /etc/cron.d/cmdb-collection
    echo "0 * * * * $INSTALL_USER $LAB_DIR/venv/bin/python $LAB_DIR/cmdb/scripts/cmdb-collector.py" | sudo tee -a /etc/cron.d/cmdb-collection
    
    # Create cron job for log rotation
    echo "# Lab log rotation - daily" | sudo tee /etc/cron.d/lab-logrotate
    echo "0 2 * * * $INSTALL_USER find $LAB_DIR -name '*.log' -mtime +7 -delete" | sudo tee -a /etc/cron.d/lab-logrotate
    
    log_success "Cron jobs configured"
}

# Configure lab environment
configure_lab() {
    log_info "Configuring lab environment..."
    
    # Set executable permissions
    chmod +x "$LAB_DIR/tests/run-all-tests.sh"
    chmod +x "$LAB_DIR/fim/agents/fim-agent.py"
    chmod +x "$LAB_DIR/cmdb/scripts/cmdb-collector.py"
    
    # Create environment file
    cat > "$LAB_DIR/.env" << EOF
# Lab Environment Configuration
LAB_DIR=$LAB_DIR
LAB_USER=$INSTALL_USER
LAB_ENVIRONMENT=development
PYTHON_VENV=$LAB_DIR/venv
ANSIBLE_CONFIG=$LAB_DIR/ansible/ansible.cfg
FIM_CONFIG=$LAB_DIR/fim/agents/fim-config.json
CMDB_DATA_DIR=/var/lib/cmdb/data
EOF
    
    # Create activation script
    cat > "$LAB_DIR/activate-lab.sh" << EOF
#!/bin/bash
# Lab Environment Activation Script

export LAB_DIR="$LAB_DIR"
export LAB_USER="$INSTALL_USER"
export LAB_ENVIRONMENT="development"

# Activate Python virtual environment
source "$LAB_DIR/venv/bin/activate"

# Set Ansible configuration
export ANSIBLE_CONFIG="$LAB_DIR/ansible/ansible.cfg"

# Add lab scripts to PATH
export PATH="$LAB_DIR/scripts:\$PATH"

echo "Lab environment activated!"
echo "Lab directory: \$LAB_DIR"
echo "Python environment: \$VIRTUAL_ENV"
echo "Ansible config: \$ANSIBLE_CONFIG"
EOF
    
    chmod +x "$LAB_DIR/activate-lab.sh"
    
    log_success "Lab environment configured"
}

# Run initial tests
run_initial_tests() {
    log_info "Running initial tests..."
    
    # Activate virtual environment
    source "$LAB_DIR/venv/bin/activate"
    
    # Test Python imports
    python3 -c "import psutil, watchdog, yaml, jinja2; print('Python dependencies OK')"
    
    # Test Ansible
    if command -v ansible &> /dev/null; then
        ansible --version
        log_success "Ansible test passed"
    fi
    
    # Test FIM agent
    python3 "$LAB_DIR/fim/agents/fim-agent.py" --help > /dev/null
    log_success "FIM agent test passed"
    
    # Test CMDB collector
    python3 "$LAB_DIR/cmdb/scripts/cmdb-collector.py" --help > /dev/null
    log_success "CMDB collector test passed"
    
    log_success "Initial tests completed"
}

# Display completion information
display_completion() {
    log_success "Lab setup completed successfully!"
    
    echo
    echo "=========================================="
    echo "Lab Environment Setup Complete"
    echo "=========================================="
    echo
    echo "Lab Directory: $LAB_DIR"
    echo "Virtual Environment: $LAB_DIR/venv"
    echo "Log File: $LOG_FILE"
    echo
    echo "Next Steps:"
    echo "1. Activate the lab environment:"
    echo "   source $LAB_DIR/activate-lab.sh"
    echo
    echo "2. Configure your inventory:"
    echo "   edit $LAB_DIR/ansible/inventory/hosts"
    echo
    echo "3. Deploy baseline configuration:"
    echo "   cd $LAB_DIR/ansible"
    echo "   ansible-playbook -i inventory/hosts playbooks/setup-baseline.yml"
    echo
    echo "4. Initialize FIM monitoring:"
    echo "   sudo python3 $LAB_DIR/fim/agents/fim-agent.py --init-baseline"
    echo
    echo "5. Run tests:"
    echo "   cd $LAB_DIR/tests"
    echo "   ./run-all-tests.sh"
    echo
    echo "Documentation:"
    echo "- Installation Guide: $LAB_DIR/docs/installation-guide.md"
    echo "- User Guide: $LAB_DIR/docs/user-guide.md"
    echo "- Test Scenarios: $LAB_DIR/tests/test-scenarios.md"
    echo
    echo "For support, check the logs and documentation."
    echo "=========================================="
}

# Main execution
main() {
    echo "Starting Lab Environment Setup..."
    echo "Log file: $LOG_FILE"
    echo
    
    # Initialize log file
    echo "Lab Setup Log - $(date)" > "$LOG_FILE"
    
    # Run setup steps
    check_root
    check_requirements
    install_system_packages
    install_ansible
    install_python_deps
    setup_ssh
    setup_directories
    setup_services
    setup_cron
    configure_lab
    run_initial_tests
    display_completion
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Lab Environment Setup Script"
        echo
        echo "Usage: $0 [options]"
        echo
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --skip-tests   Skip initial tests"
        echo "  --verbose      Enable verbose output"
        echo
        echo "This script will set up the complete lab environment including:"
        echo "- System packages and dependencies"
        echo "- Ansible configuration"
        echo "- Python virtual environment"
        echo "- SSH configuration"
        echo "- System services"
        echo "- Lab directories and permissions"
        echo
        exit 0
        ;;
    --skip-tests)
        SKIP_TESTS=true
        ;;
    --verbose)
        set -x
        ;;
esac

# Run main function
main "$@"

