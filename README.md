# System Monitoring Script

A comprehensive system monitoring script for development environments that provides real-time system health monitoring, performance analysis, and automated reporting capabilities.

## Features

- **Real-time Monitoring**: CPU, memory, disk usage, and process monitoring
- **Automated Reporting**: Generates detailed system reports with alerts
- **Cross-platform Support**: Works on macOS and Linux systems
- **Alert System**: Configurable thresholds for CPU, memory, and disk usage
- **Automated Scheduling**: Built-in cron job setup for continuous monitoring
- **Log Management**: Automatic log archival and compression
- **Network Monitoring**: Active connection and port monitoring

## Requirements

- **macOS**: Requires Homebrew for tool installation
- **Linux**: Supports Ubuntu/Debian, RHEL/CentOS, and Fedora
- **Dependencies**: `bc` calculator (auto-installed if missing)
- **Optional Tools**: `htop`, `nmon` (installed automatically with `--install`)

## Installation

1. Make the script executable:
   ```bash
   chmod +x system_monitor.sh
   ```

2. Run first-time setup:
   ```bash
   ./system_monitor.sh --install
   ```

   This will:
   - Create monitoring directories
   - Install required monitoring tools
   - Set up automated cron jobs

## Usage

### Basic Commands

```bash
# Generate system report only
./system_monitor.sh --report

# Run complete system monitoring
./system_monitor.sh --monitor

# Setup automated monitoring cron job
./system_monitor.sh --setup-cron

# Show help
./system_monitor.sh --help
```

### Output Locations

- **Log Directory**: `~/system_monitoring/`
- **Daily Logs**: `~/system_monitoring/system_monitor_YYYYMMDD.log`
- **Reports**: `~/system_monitoring/daily_report_YYYYMMDD.txt`
- **Archives**: `~/system_monitoring/archives/`

## Configuration

### Alert Thresholds

The script uses the following default alert thresholds:

```bash
ALERT_THRESHOLD_CPU=80     # CPU usage percentage
ALERT_THRESHOLD_MEMORY=85  # Memory usage percentage
ALERT_THRESHOLD_DISK=90    # Disk usage percentage
```

To modify thresholds, edit the variables at the top of the script.

### Automated Monitoring

The cron job runs monitoring every 6 hours:
```
0 */6 * * * /path/to/system_monitor.sh --monitor-only >> ~/system_monitoring/cron.log 2>&1
```

## Monitoring Features

### CPU Monitoring
- Current CPU usage percentage
- Top CPU-consuming processes
- High usage alerts (>80% by default)

### Memory Monitoring
- Total, used, and free memory
- Memory usage percentage
- Top memory-consuming processes
- High usage alerts (>85% by default)

### Disk Monitoring
- Disk space usage by filesystem
- Disk usage alerts for filesystems >90% full
- Largest directories in current filesystem

### Process Monitoring
- Total process count
- Process state distribution
- Resource-intensive process identification

### Network Monitoring
- Active network connections count
- Listening ports count

## Log Management

- **Daily Logs**: New log file created each day
- **Auto-archival**: Logs older than 7 days moved to archives
- **Compression**: Archived logs older than 30 days are compressed
- **Alert Logging**: All alerts are logged with timestamps

## Report Format

Generated reports include:

1. **System Overview**: Hostname, uptime, OS information
2. **Resource Alerts**: Recent alert history
3. **Disk Usage Summary**: Filesystem usage statistics
4. **Memory Summary**: Current memory statistics
5. **Top Processes**: By CPU and memory usage

---

# Developer Account Setup Script

A secure shell script for creating developer accounts with isolated workspaces and comprehensive security policies.

## Overview

The `setup_developer_accounts.sh` script automates the creation of developer user accounts with:
- Secure password policies and complexity requirements
- Isolated workspace directories with proper permissions
- Group-based access controls
- Security guidelines and best practices

## Features

### Security Features
- **Password Policy**: 30-day expiration with 7-day warning
- **Password Complexity**: Enforces uppercase, lowercase, numbers, and special characters
- **Secure Workspaces**: Private directories with 700 permissions (owner-only access)
- **Group Management**: Adds users to 'developers' group for collaboration
- **First Login Security**: Forces password change on first login

### User Management
- **Interactive Setup**: Prompts for usernames and passwords with validation
- **Duplicate Prevention**: Checks for existing users before creation
- **Input Validation**: Validates username format and password complexity
- **Multi-user Support**: Create multiple accounts in one session

### Workspace Organization
- **Structured Directories**: Creates organized workspace with subdirectories:
  - `projects/` - for development projects
  - `tools/` - for development utilities
  - `configs/` - for configuration files
- **Proper Ownership**: All directories owned by respective users
- **Security Guidelines**: Creates welcome file with security best practices

## Requirements

- **Root Access**: Must be run with `sudo` privileges
- **Linux System**: Uses standard Linux user management tools (`useradd`, `chage`, `chpasswd`)
- **Bash Shell**: Compatible with bash scripting environment

## Installation

1. Make the script executable:
   ```bash
   chmod +x setup_developer_accounts.sh
   ```

## Usage

### Basic Usage

```bash
sudo ./setup_developer_accounts.sh
```

### Script Workflow

1. **Privilege Check**: Verifies script is run with sudo
2. **Username Input**: Prompts for developer username with validation
3. **Password Setup**: Secure password input with complexity verification
4. **Account Creation**: Creates user account with home directory
5. **Security Configuration**: Applies password policies and permissions
6. **Workspace Setup**: Creates organized workspace directories
7. **Documentation**: Generates security guidelines for the user

### Input Requirements

#### Username Format
- Must start with lowercase letter
- 3-32 characters long
- Can contain lowercase letters, numbers, hyphens, underscores
- Automatically converted to lowercase

#### Password Requirements
- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one digit
- At least one special character

## Security Policies

### Password Management
```bash
# Password expiration: 30 days
chage -M 30 username

# Warning period: 7 days before expiration
chage -W 7 username

# Minimum days between password changes: 1 day
chage -m 1 username

# Force password change on first login
chage -d 0 username
```

### Directory Permissions
```bash
# Workspace directory: Owner-only access
chmod 700 /home/username/workspace

# All subdirectories inherit secure permissions
chown -R username:username /home/username/workspace
```

### Group Configuration
- Creates 'developers' group if it doesn't exist
- Adds all developer users to the group
- Enables collaboration while maintaining security

## Directory Structure

For each user, the script creates:

```
/home/username/
├── workspace/           # Main workspace (700 permissions)
│   ├── projects/        # Development projects
│   ├── tools/          # Development utilities
│   └── configs/        # Configuration files
└── SECURITY_GUIDELINES.txt  # Security best practices (600 permissions)
```

## Script Features

### Error Handling
- **Input Validation**: Comprehensive validation for usernames and passwords
- **Duplicate Detection**: Prevents creation of existing users
- **Privilege Verification**: Ensures proper permissions before execution
- **Error Logging**: Colored output with detailed error messages

### User Experience
- **Interactive Prompts**: User-friendly input collection
- **Password Confirmation**: Prevents typos with password verification
- **Multiple Users**: Option to create additional accounts in same session
- **Progress Feedback**: Colored status messages and completion summaries

### Logging and Output
- **Color-coded Messages**: Different colors for info, success, warning, and error
- **Progress Tracking**: Real-time feedback during account creation
- **Summary Reports**: Complete setup summary for each user

## Security Guidelines Generated

Each user receives a personalized `SECURITY_GUIDELINES.txt` file containing:

1. **Password Policy Information**: Expiration and complexity requirements
2. **Workspace Security**: Private directory access information
3. **Best Practices**: Development security recommendations
4. **Directory Structure**: Explanation of workspace organization
5. **Support Information**: Contact details for system administration

## Example Usage Session

```bash
$ sudo ./setup_developer_accounts.sh

=================================
Developer Account Setup Script
=================================

[INFO] This script will help you create secure developer accounts

Enter username for the new developer: sarah
Enter password for sarah: [hidden]
Confirm password: [hidden]

[INFO] Creating user account for sarah...
[SUCCESS] User sarah created successfully
[SUCCESS] Password set for user sarah
[INFO] User sarah will be required to change password on first login
[INFO] Setting up password policy for sarah...
[SUCCESS] Password policy configured for sarah (30-day expiration, 7-day warning)
[INFO] Creating workspace directory for sarah...
[SUCCESS] Workspace created at /home/sarah/workspace with secure permissions
[INFO] Configuring permissions for sarah...
[SUCCESS] Added sarah to developers group
[SUCCESS] Security guidelines created for sarah
[SUCCESS] Developer account setup completed for sarah

Summary for sarah:
- Home directory: /home/sarah
- Workspace: /home/sarah/workspace
- Password policy: 30-day expiration, 7-day warning
- Group membership: developers

Do you want to create another developer account? (y/N): y

[Process repeats for additional users]
```

## Additional Security Recommendations

The script provides recommendations for further security hardening:

- **SSH Key Authentication**: Set up key-based authentication
- **Fail2ban**: Configure brute force protection
- **Firewall Rules**: Enable and configure firewall
- **Security Audits**: Regular security assessments
- **Activity Monitoring**: User activity log monitoring

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure script is run with `sudo`
2. **User Already Exists**: Script will detect and prompt for different username
3. **Password Complexity**: Follow all password requirements for successful creation
4. **Directory Creation**: Verify sufficient disk space and proper permissions

### Debug Mode

Run with debug output for troubleshooting:
```bash
sudo bash -x ./setup_developer_accounts.sh
```

## Integration with System Monitoring

This script complements the system monitoring capabilities by:
- Creating secure user environments that can be monitored
- Establishing proper user isolation for security auditing
- Providing structured workspaces for development activity tracking

---

## Contributing

Contributions are welcome. Please ensure:
- Cross-platform compatibility
- Proper error handling
- Updated documentation
- Test on both macOS and Linux systems
