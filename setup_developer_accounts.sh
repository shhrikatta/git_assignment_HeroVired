#!/bin/bash

# Developer Account Setup Script with Secure Access Controls
# This script creates user accounts with isolated workspaces and security policies

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

# Color codes for output formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
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

# Check if script is run with sudo privileges
check_privileges() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Validate username format
validate_username() {
    local username=$1
    if [[ ! $username =~ ^[a-z][a-z0-9_-]{2,31}$ ]]; then
        log_error "Invalid username format. Use lowercase letters, numbers, hyphens, underscores. 3-32 characters."
        return 1
    fi
    return 0
}

# Check if user already exists
user_exists() {
    local username=$1
    if id "$username" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Validate password complexity
validate_password() {
    local password=$1
    local min_length=8
    
    # Check minimum length
    if [[ ${#password} -lt $min_length ]]; then
        log_error "Password must be at least $min_length characters long"
        return 1
    fi
    
    # Check for uppercase letter
    if [[ ! $password =~ [A-Z] ]]; then
        log_error "Password must contain at least one uppercase letter"
        return 1
    fi
    
    # Check for lowercase letter
    if [[ ! $password =~ [a-z] ]]; then
        log_error "Password must contain at least one lowercase letter"
        return 1
    fi
    
    # Check for digit
    if [[ ! $password =~ [0-9] ]]; then
        log_error "Password must contain at least one digit"
        return 1
    fi
    
    # Check for special character
    if [[ ! $password =~ [^a-zA-Z0-9] ]]; then
        log_error "Password must contain at least one special character"
        return 1
    fi
    
    return 0
}

# Create user account
create_user() {
    local username=$1
    local password=$2
    
    log_info "Creating user account for $username..."
    
    # Create user with home directory
    if useradd -m -s /bin/bash "$username"; then
        log_success "User $username created successfully"
    else
        log_error "Failed to create user $username"
        return 1
    fi
    
    # Set password
    echo "$username:$password" | chpasswd
    log_success "Password set for user $username"
    
    # Force password change on first login
    # chage -d 0 "$username"
    # log_info "User $username will be required to change password on first login"
}

# Set up password policy
setup_password_policy() {
    local username=$1
    
    log_info "Setting up password policy for $username..."
    
    # Set password expiration to 30 days
    chage -M 30 "$username"
    
    # Set warning 7 days before expiration
    chage -W 7 "$username"
    
    # Set minimum days between password changes
    chage -m 1 "$username"
    
    log_success "Password policy configured for $username (30-day expiration, 7-day warning)"
}

# Create workspace directory
create_workspace() {
    local username=$1
    local workspace_dir="/home/$username/workspace"
    
    log_info "Creating workspace directory for $username..."
    
    # Create workspace directory
    mkdir -p "$workspace_dir"
    
    # Set ownership to user
    chown "$username:$username" "$workspace_dir"
    
    # Set permissions: owner has full access, no access for group/others
    chmod 700 "$workspace_dir"
    
    # Create additional subdirectories
    mkdir -p "$workspace_dir"/{projects,tools,configs}
    chown -R "$username:$username" "$workspace_dir"
    
    log_success "Workspace created at $workspace_dir with secure permissions"
}

# Configure user groups and permissions
configure_user_permissions() {
    local username=$1
    
    log_info "Configuring permissions for $username..."
    
    # Add user to developers group (create if doesn't exist)
    if ! getent group developers >/dev/null; then
        groupadd developers
        log_info "Created 'developers' group"
    fi
    
    usermod -aG developers "$username"
    log_success "Added $username to developers group"
    
    # Set up sudo restrictions (optional - uncomment if needed)
    # echo "$username ALL=(ALL) NOPASSWD:/usr/bin/git, /usr/bin/vim, /usr/bin/nano" >> /etc/sudoers.d/$username
}

# Create a welcome file with security guidelines
create_welcome_file() {
    local username=$1
    local welcome_file="/home/$username/SECURITY_GUIDELINES.txt"
    
    cat > "$welcome_file" << EOF
Welcome to the Development Environment!
=====================================

Security Guidelines:
-------------------
1. Your password expires every 30 days - you'll receive a warning 7 days before expiration
2. Use strong passwords with uppercase, lowercase, numbers, and special characters
3. Never share your credentials with anyone
4. Your workspace directory is private - only you can access it
5. Report any security concerns to the system administrator

Your workspace is located at: /home/$username/workspace

Subdirectories created for you:
- projects/  (for your development projects)
- tools/     (for development tools and utilities)
- configs/   (for configuration files)

Best Practices:
--------------
- Regularly backup your work
- Use version control (git) for your projects
- Keep your workspace organized
- Follow company coding standards

For support, contact: sysadmin@company.com
EOF

    chown "$username:$username" "$welcome_file"
    chmod 600 "$welcome_file"
    log_success "Security guidelines created for $username"
}

# Main setup function for a single user
setup_developer() {
    local username password
    
    # Get username
    while true; do
        read -p "Enter username for the new developer: " username
        username=$(echo "$username" | tr '[:upper:]' '[:lower:]')  # Convert to lowercase
        
        if validate_username "$username"; then
            if user_exists "$username"; then
                log_warning "User $username already exists. Please choose a different username."
            else
                break
            fi
        fi
    done
    
    # Get password
    while true; do
        read -s -p "Enter password for $username: " password
        echo
        read -s -p "Confirm password: " password_confirm
        echo
        
        if [[ "$password" != "$password_confirm" ]]; then
            log_error "Passwords do not match. Please try again."
            continue
        fi
        
        if validate_password "$password"; then
            break
        fi
    done
    
    # Create the user and set up everything
    if create_user "$username" "$password"; then
        setup_password_policy "$username"
        create_workspace "$username"
        configure_user_permissions "$username"
        create_welcome_file "$username"
        
        log_success "Developer account setup completed for $username"
        echo
        echo "Summary for $username:"
        echo "- Home directory: /home/$username"
        echo "- Workspace: /home/$username/workspace"
        echo "- Password policy: 30-day expiration, 7-day warning"
        echo "- Group membership: developers"
        echo
    else
        log_error "Failed to set up account for $username"
        return 1
    fi
}

# Main script execution
main() {
    echo "================================="
    echo "Developer Account Setup Script"
    echo "================================="
    echo
    
    check_privileges
    
    log_info "This script will help you create secure developer accounts"
    echo
    
    while true; do
        setup_developer
        echo
        read -p "Do you want to create another developer account? (y/N): " continue_setup
        if [[ ! "$continue_setup" =~ ^[Yy]$ ]]; then
            break
        fi
        echo
    done
    
    echo
    log_success "All developer accounts have been set up successfully!"
    echo
    echo "Additional Security Recommendations:"
    echo "- Configure SSH key-based authentication"
    echo "- Set up fail2ban for brute force protection"
    echo "- Enable firewall rules"
    echo "- Regular security audits"
    echo "- Monitor user activity logs"
}

# Run the main function
main "$@"