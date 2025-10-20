#!/bin/bash

# Nginx Server Backup Script
# Backs up Nginx configuration and document root
# Usage: ./nginx_backup.sh

# Configuration
BACKUP_DIR="/backups"
DATE=$(date +%Y-%m-%d)
BACKUP_FILE="nginx_backup_${DATE}.tar.gz"
LOG_FILE="/var/log/nginx_backup.log"

# Nginx paths
NGINX_CONFIG_DIR="/etc/nginx"
NGINX_DOCUMENT_ROOT="/usr/share/nginx/html"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to check if directory exists
check_directory() {
    if [ ! -d "$1" ]; then
        log_message "ERROR: Directory $1 does not exist"
        return 1
    fi
    return 0
}

# Main backup function
perform_backup() {
    log_message "Starting Nginx backup process"
    
    # Create backup directory if it doesn't exist
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        log_message "Created backup directory: $BACKUP_DIR"
    fi
    
    # Check if source directories exist
    if ! check_directory "$NGINX_CONFIG_DIR" || ! check_directory "$NGINX_DOCUMENT_ROOT"; then
        log_message "ERROR: Required directories missing. Backup aborted."
        exit 1
    fi
    
    # Create temporary directory for staging
    TEMP_DIR="/tmp/nginx_backup_$$"
    mkdir -p "$TEMP_DIR"
    
    # Copy Nginx configuration
    log_message "Copying Nginx configuration from $NGINX_CONFIG_DIR"
    cp -r "$NGINX_CONFIG_DIR" "$TEMP_DIR/nginx" 2>/dev/null
    if [ $? -eq 0 ]; then
        log_message "Nginx configuration copied successfully"
    else
        log_message "WARNING: Failed to copy Nginx configuration"
    fi
    
    # Copy document root
    log_message "Copying document root from $NGINX_DOCUMENT_ROOT"
    cp -r "$NGINX_DOCUMENT_ROOT" "$TEMP_DIR/html" 2>/dev/null
    if [ $? -eq 0 ]; then
        log_message "Document root copied successfully"
    else
        log_message "WARNING: Failed to copy document root"
    fi
    
    # Create compressed backup
    log_message "Creating compressed backup: $BACKUP_FILE"
    cd "$TEMP_DIR"
    tar -czf "$BACKUP_DIR/$BACKUP_FILE" * 2>/dev/null
    
    if [ $? -eq 0 ]; then
        log_message "Backup created successfully: $BACKUP_DIR/$BACKUP_FILE"
        
        # Verify backup integrity
        log_message "Verifying backup integrity..."
        tar -tzf "$BACKUP_DIR/$BACKUP_FILE" > /dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            log_message "Backup integrity verified successfully"
            log_message "Backup contents:"
            tar -tzf "$BACKUP_DIR/$BACKUP_FILE" | head -20 | while read line; do
                log_message "  $line"
            done
            
            # Get file size
            BACKUP_SIZE=$(du -sh "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)
            log_message "Backup size: $BACKUP_SIZE"
        else
            log_message "ERROR: Backup integrity check failed"
            rm -f "$BACKUP_DIR/$BACKUP_FILE"
            exit 1
        fi
    else
        log_message "ERROR: Failed to create backup"
        exit 1
    fi
    
    # Cleanup temporary directory
    rm -rf "$TEMP_DIR"
    log_message "Nginx backup process completed successfully"
}

# Execute backup
perform_backup

# Optional: Remove old backups (keep last 7 days)
find "$BACKUP_DIR" -name "nginx_backup_*.tar.gz" -mtime +7 -delete 2>/dev/null
log_message "Old backups cleaned up (older than 7 days)"