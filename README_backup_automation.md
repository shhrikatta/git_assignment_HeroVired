# Apache and Nginx Automated Backup Solution

This solution provides comprehensive automated backup scripts for both Apache and Nginx web servers with cron job scheduling for disaster recovery purposes.

## 📋 Overview

The backup automation includes:
- **Apache Server**: Configuration (`/etc/httpd/`) and document root (`/var/www/html/`)
- **Nginx Server**: Configuration (`/etc/nginx/`) and document root (`/usr/share/nginx/html/`)
- **Scheduling**: Every Tuesday at 12:00 AM
- **Storage**: Compressed `.tar.gz` files in `/backups/` directory
- **Integrity Verification**: Automatic backup verification after creation
- **Logging**: Comprehensive logging for monitoring and troubleshooting

## 📁 File Structure

```
├── apache_backup.sh           # Apache backup script
├── nginx_backup.sh            # Nginx backup script
└── README_backup_automation.md # This documentation
```

## 🚀 Quick Setup

### Method 1: Automated Setup (Recommended)

```bash
# Make setup script executable
chmod +x setup_backup_automation.sh

# Run the setup script
sudo ./setup_backup_automation.sh
```

### Method 2: Manual Setup

1. **Make scripts executable:**
   ```bash
   chmod +x apache_backup.sh nginx_backup.sh
   ```

2. **Create backup directory:**
   ```bash
   sudo mkdir -p /backups
   sudo chmod 755 /backups
   ```

3. **Add cron jobs:**
   ```bash
   crontab -e
   ```
   Add these lines:
   ```
   0 0 * * 2 /path/to/apache_backup.sh >> /var/log/apache_backup_cron.log 2>&1
   0 0 * * 2 /path/to/nginx_backup.sh >> /var/log/nginx_backup_cron.log 2>&1
   ```

## 📋 Requirements

- **Operating System**: Linux (RHEL/CentOS, Ubuntu/Debian compatible)
- **Permissions**: Root or sudo access for accessing system directories
- **Dependencies**: `tar`, `gzip`, `find`, `cron`
- **Disk Space**: Sufficient space in `/backups/` directory

## 🔧 Configuration

### Backup Locations

**Apache:**
- Config: `/etc/httpd/` → backed up as `httpd/`
- Document Root: `/var/www/html/` → backed up as `html/`

**Nginx:**
- Config: `/etc/nginx/` → backed up as `nginx/`
- Document Root: `/usr/share/nginx/html/` → backed up as `html/`

### File Naming Convention

```
apache_backup_YYYY-MM-DD.tar.gz
nginx_backup_YYYY-MM-DD.tar.gz
```

Example: `apache_backup_2024-03-15.tar.gz`

### Cron Schedule

```
0 0 * * 2  # Every Tuesday at 12:00 AM (midnight)
```

## 📊 Features

### ✅ Backup Features
- **Complete Configuration Backup**: All server configuration files
- **Document Root Backup**: All website files and content
- **Compression**: `gzip` compression to minimize storage space
- **Date Stamping**: Unique filenames with date stamps
- **Integrity Verification**: Automatic verification of backup archives
- **Error Handling**: Comprehensive error checking and logging

### 📝 Logging Features
- **Timestamped Logs**: All operations logged with timestamps
- **Separate Log Files**: Individual logs for Apache and Nginx
- **Cron Logging**: Separate cron execution logs
- **Content Verification**: Backup contents listed in logs

### 🧹 Maintenance Features
- **Old Backup Cleanup**: Automatic removal of backups older than 7 days
- **Temporary File Cleanup**: Automatic cleanup of temporary staging files
- **Space Management**: Built-in disk usage reporting

## 🔍 Usage Examples

### Manual Execution

```bash
# Run Apache backup manually
sudo ./apache_backup.sh

# Run Nginx backup manually  
sudo ./nginx_backup.sh
```

### View Backup Contents

```bash
# List contents of Apache backup
tar -tzf /backups/apache_backup_2024-03-15.tar.gz

# List contents of Nginx backup
tar -tzf /backups/nginx_backup_2024-03-15.tar.gz
```

### Extract Backup for Recovery

```bash
# Extract Apache backup
cd /tmp
tar -xzf /backups/apache_backup_2024-03-15.tar.gz

# Extract Nginx backup
cd /tmp
tar -xzf /backups/nginx_backup_2024-03-15.tar.gz
```

## 📋 Monitoring and Logs

### Log Locations

```bash
# Script execution logs
/var/log/apache_backup.log
/var/log/nginx_backup.log

# Cron execution logs
/var/log/apache_backup_cron.log
/var/log/nginx_backup_cron.log
```

### Monitor Backups

```bash
# View recent backup activity
tail -f /var/log/apache_backup.log
tail -f /var/log/nginx_backup.log

# Check cron execution
tail -f /var/log/apache_backup_cron.log
tail -f /var/log/nginx_backup_cron.log

# List backup files
ls -la /backups/
```

### Verify Cron Jobs

```bash
# List current cron jobs
crontab -l

# Check cron service status
sudo systemctl status cron    # Debian/Ubuntu
sudo systemctl status crond   # RHEL/CentOS
```

## 🛠️ Troubleshooting

### Common Issues

1. **Permission Denied**
   ```bash
   # Ensure scripts are executable
   chmod +x *.sh
   
   # Run with sudo for system directories
   sudo ./apache_backup.sh
   ```

2. **Directory Not Found**
   ```bash
   # Check if Apache/Nginx directories exist
   ls -la /etc/httpd/
   ls -la /etc/nginx/
   ls -la /var/www/html/
   ls -la /usr/share/nginx/html/
   ```

3. **Backup Directory Issues**
   ```bash
   # Create backup directory
   sudo mkdir -p /backups
   sudo chmod 755 /backups
   ```

4. **Cron Jobs Not Running**
   ```bash
   # Check cron service
   sudo systemctl status cron
   sudo systemctl start cron
   
   # Verify cron jobs
   crontab -l
   ```

### Testing

```bash
# Test backup scripts
sudo ./apache_backup.sh
sudo ./nginx_backup.sh

# Check backup creation
ls -la /backups/

# Verify backup integrity
tar -tzf /backups/apache_backup_$(date +%Y-%m-%d).tar.gz
tar -tzf /backups/nginx_backup_$(date +%Y-%m-%d).tar.gz
```

## 🔒 Security Considerations

- **File Permissions**: Backup files are readable by root only
- **Log Security**: Log files contain system information
- **Storage Security**: Consider encrypting backup storage location
- **Network Security**: For remote backups, use secure protocols

## 📈 Customization

### Modify Backup Frequency

Edit cron schedule in `/etc/crontab` or user crontab:
```bash
# Daily at 2:00 AM
0 2 * * *

# Weekly on Sunday at 1:00 AM  
0 1 * * 0

# Monthly on 1st day at 3:00 AM
0 3 1 * *
```

### Change Backup Retention

Modify the cleanup commands in the scripts:
```bash
# Keep 30 days instead of 7
find "$BACKUP_DIR" -name "apache_backup_*.tar.gz" -mtime +30 -delete
```

### Add Email Notifications

Add to cron jobs:
```bash
0 0 * * 2 /path/to/apache_backup.sh | mail -s "Apache Backup Status" admin@example.com
```

## 📞 Support

For issues or questions:
1. Check log files for detailed error messages
2. Verify file permissions and paths
3. Ensure sufficient disk space
4. Test scripts manually before relying on cron execution

---

**Note**: Always test backup and recovery procedures in a non-production environment before implementing in production systems.