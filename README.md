# OpenSUSE Tumbleweed Provisioning

Ansible playbook for automated OpenSUSE Tumbleweed setup with bspwm, Hyprland, CLI tools, and dotfiles.

## Structure
- `ansible.cfg` - Ansible configuration settings
- `inventory.ini` - Target hosts definition
- `group_vars/all.yml` - Global variables
- `playbooks/site.yml` - Main playbook
- `roles/` - Task organization by function
- `run.sh` - Execution wrapper script

## Quick Start
```bash
# Run full provisioning
./run.sh

# Run specific roles only
ansible-playbook -i inventory.ini playbooks/site.yml -K --tags "base,cli"
```

## Roles
- **base** - System setup, hostname, and display manager
- **cli** - Terminal, shell, and development tools
- **desktop** - Window managers and desktop applications
- **multimedia** - Media playback and audio configuration
- **files** - User directory setup and dotfiles installation
