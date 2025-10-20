#!/bin/bash

# Setup script for automated Apache and Nginx backups
# This script configures cron jobs and sets up necessary permissions

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APACHE_SCRIPT="$SCRIPT_DIR/apache_backup.sh"
NGINX_SCRIPT="$SCRIPT_DIR/nginx_backup.sh"
BACKUP_DIR="/backups"
LOG_DIR="/var/log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if script exists
check_script() {
    if [ ! -f "$1" ]; then
        print_message $RED "ERROR: Script $1 not found!"
        exit 1
    fi
}

# Function to create directory with proper permissions
create_directory() {
    local dir=$1
    if [ ! -d "$dir" ]; then
        print_message $YELLOW "Creating directory: $dir"
        sudo mkdir -p "$dir"
        sudo chmod 755 "$dir"
        print_message $GREEN "Directory created successfully: $dir"
    else
        print_message $GREEN "Directory already exists: $dir"
    fi
}

# Function to add cron job
add_cron_job() {
    local script_path=$1
    local job_name=$2
    local cron_schedule="0 0 * * 2"  # Every Tuesday at 12:00 AM
    
    # Check if cron job already exists
    if crontab -l 2>/dev/null | grep -q "$script_path"; then
        print_message $YELLOW "Cron job for $job_name already exists"
        return
    fi
    
    # Add new cron job
    (crontab -l 2>/dev/null; echo "$cron_schedule $script_path >> /var/log/${job_name}_cron.log 2>&1") | crontab -
    
    if [ $? -eq 0 ]; then
        print_message $GREEN "Cron job added successfully for $job_name"
        print_message $GREEN "Schedule: Every Tuesday at 12:00 AM"
    else
        print_message $RED "Failed to add cron job for $job_name"
        exit 1
    fi
}

# Main setup function
main() {
    print_message $GREEN "=== Apache and Nginx Backup Automation Setup ==="
    echo
    
    # Check if running as root for some operations
    if [ "$EUID" -ne 0 ]; then
        print_message $YELLOW "Note: Some operations may require sudo privileges"
        echo
    fi
    
    # Check if backup scripts exist
    print_message $YELLOW "Checking backup scripts..."
    check_script "$APACHE_SCRIPT"
    check_script "$NGINX_SCRIPT"
    print_message $GREEN "✓ All backup scripts found"
    echo
    
    # Make scripts executable
    print_message $YELLOW "Making backup scripts executable..."
    chmod +x "$APACHE_SCRIPT"
    chmod +x "$NGINX_SCRIPT"
    print_message $GREEN "✓ Scripts made executable"
    echo
    
    # Create backup directory
    print_message $YELLOW "Setting up backup directory..."
    create_directory "$BACKUP_DIR"
    echo
    
    # Create log directory if needed
    print_message $YELLOW "Ensuring log directory exists..."
    if [ ! -d "$LOG_DIR" ]; then
        create_directory "$LOG_DIR"
    else
        print_message $GREEN "✓ Log directory exists: $LOG_DIR"
    fi
    echo
    
    # Add cron jobs
    print_message $YELLOW "Setting up cron jobs..."
    add_cron_job "$APACHE_SCRIPT" "apache_backup"
    add_cron_job "$NGINX_SCRIPT" "nginx_backup"
    echo
    
    # Display current crontab
    print_message $GREEN "Current cron jobs:"
    crontab -l | grep -E "(apache_backup|nginx_backup)" || print_message $YELLOW "No backup cron jobs found"
    echo
    
    print_message $GREEN "=== Setup Complete ==="
    print_message $GREEN "Backup scripts are now scheduled to run every Tuesday at 12:00 AM"
    print_message $GREEN "Backups will be stored in: $BACKUP_DIR"
    print_message $GREEN "Logs will be stored in: $LOG_DIR"
    echo
    print_message $YELLOW "To test the scripts manually, run:"
    print_message $YELLOW "  sudo $APACHE_SCRIPT"
    print_message $YELLOW "  sudo $NGINX_SCRIPT"
    echo
    print_message $YELLOW "To view cron logs:"
    print_message $YELLOW "  tail -f /var/log/apache_backup_cron.log"
    print_message $YELLOW "  tail -f /var/log/nginx_backup_cron.log"
}

# Execute main function
main