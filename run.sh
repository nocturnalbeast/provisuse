#!/bin/bash
#
# OpenSUSE Tumbleweed Provisioning Script
# This script provisions an openSUSE Tumbleweed system with a customized environment.
# Can be run directly with: curl -fsSL https://raw.githubusercontent.com/yourusername/yourrepo/main/run.sh | bash

set -e

REPO_URL="https://github.com/nocturnalbeast/provisuse"
INSTALL_DIR="/opt/provision"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

OpenSUSE Tumbleweed Provisioning Script
This script automatically provisions an openSUSE Tumbleweed system.

Requirements:
  - openSUSE Tumbleweed system
  - Root privileges (sudo)
  - Internet connection

Options:
    -h, --help    Show this help message
EOF
}

log() {
    printf "%b\n" "$@"
}

info() {
    log "\033[0;34m[INFO]\033[0m $@"
}

success() {
    log "\033[0;32m[SUCCESS]\033[0m $@"
}

warning() {
    log "\033[0;33m[WARNING]\033[0m $@"
}

error() {
    log "\033[0;31m[ERROR]\033[0m $@"
}

is_remote_script() {
    [[ "${BASH_SOURCE[0]}" == *"http"* ]] || [[ "${BASH_SOURCE[0]}" == *"raw.githubusercontent.com"* ]]
}

setup_repository() {
    info "Setting up repository..."
    
    if [ ! -d "$INSTALL_DIR" ]; then
        log "Cloning repository to $INSTALL_DIR"
        sudo git clone "$REPO_URL" "$INSTALL_DIR"
        sudo chmod 0777 "$INSTALL_DIR"
    else
        log "Repository already exists at $INSTALL_DIR"
        log "Updating repository..."
        cd "$INSTALL_DIR"
        git pull origin main
    fi
    
    cd "$INSTALL_DIR"
    success "Repository ready at: $(pwd)"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        warning "This script requires root privileges to install packages."
        log "Please run with sudo or as root."
        exit 1
    fi
}

check_distribution() {
    info "Checking system distribution..."
    
    if [ ! -f /etc/os-release ]; then
        error "Error: Cannot determine system distribution. This script only supports openSUSE Tumbleweed."
        exit 1
    fi
    
    . /etc/os-release
    
    if [[ "$ID" != "opensuse-tumbleweed" ]]; then
        error "Error: This script only supports openSUSE Tumbleweed."
        log "Detected system: $PRETTY_NAME"
        log "Distribution ID: $ID"
        log "Please run this script on an openSUSE Tumbleweed system."
        exit 1
    fi
    
    success "Detected openSUSE Tumbleweed: $PRETTY_NAME"
}

install_ansible() {
    info "Installing Ansible..."
    
    sudo zypper refresh
    sudo zypper --non-interactive install ansible python3-pip
    
    if command -v ansible >/dev/null 2>&1; then
        success "Ansible installed successfully!"
        ansible --version | head -n1
    else
        error "Failed to install Ansible. Please install it manually:"
        log "sudo zypper install ansible python3-pip"
        exit 1
    fi

    info "Installing required Ansible collections..."
    ansible-galaxy collection install community.general
}

run_playbook() {
    info "Running Ansible playbook..."
    
    if [ ! -f "inventory.ini" ]; then
        printf "[local]\nlocalhost ansible_connection=local" > inventory.ini
        success "Created local inventory file."
    fi
    
    PLAYBOOK="playbooks/site.yml"
    
    if [ -f "$PLAYBOOK" ]; then
        log "Running playbook: $PLAYBOOK"
        
        if [ "$EUID" -eq 0 ]; then
            ACTUAL_USER=$(logname 2>/dev/null || echo $SUDO_USER)
            if [ -z "$ACTUAL_USER" ]; then
                warning "Cannot determine the actual user. Running with root user."
                ansible-playbook -i inventory.ini "$PLAYBOOK"
            else
                log "Running playbook as user: $ACTUAL_USER"
                su - "$ACTUAL_USER" -c "cd $(pwd) && ansible-playbook -i inventory.ini $PLAYBOOK"
            fi
        else
            ansible-playbook -i inventory.ini "$PLAYBOOK"
        fi
        
        if [ $? -eq 0 ]; then
            success "Playbook execution completed successfully!"
        else
            error "Playbook execution failed."
            exit 1
        fi
    else
        error "Playbook file '$PLAYBOOK' not found."
        exit 1
    fi
}

main() {
    case "$1" in
        -h | --help)
            usage
            exit 0
            ;;
    esac
    
    if is_remote_script; then
        warning "Detected remote execution. Setting up repository..."
        setup_repository
    else
        success "Running from local directory: $SCRIPT_DIR"
        cd "$SCRIPT_DIR"
    fi
    
    check_root
    check_distribution
    install_ansible
    run_playbook
    
    success "System provisioning completed successfully!"
    info "Reboot your system and log in with your user account."
}

main "$@"
