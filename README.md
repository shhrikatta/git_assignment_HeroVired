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

## Recent Fixes (v2.0)

### Issues Resolved

1. **Script Execution Failures**: Fixed exit code 1 errors caused by:
   - Grep operations failing when no alerts were found
   - SIGPIPE errors from complex command pipelines
   - Permission denied errors with system directories

2. **Command Improvements**:
   - Replaced problematic `top` command chains with reliable `ps aux` commands
   - Added proper error handling for all system commands
   - Implemented fallback mechanisms for failed operations

3. **Enhanced Robustness**:
   - Added error suppression for commands accessing restricted directories
   - Improved report generation with individual command execution
   - Better handling of missing or inaccessible system resources

### Technical Changes

- Rewrote report generation function for better error handling
- Added comprehensive error suppression (`2>/dev/null`) where needed
- Simplified process monitoring commands
- Enhanced grep operations with proper exit code handling

## Troubleshooting

### Common Issues

1. **Permission Errors**: Run with appropriate permissions for system directories
2. **Missing Tools**: Use `--install` to install required monitoring tools
3. **Cron Job Issues**: Check cron logs in `~/system_monitoring/cron.log`

### Debug Mode

Run with debug output:
```bash
bash -x ./system_monitor.sh --report
```

## Platform-Specific Notes

### macOS
- Uses `vm_stat` for memory information
- Requires Homebrew for tool installation
- Uses `ps aux` for process monitoring

### Linux
- Uses `/proc/meminfo` and `free` for memory information
- Uses package managers (apt, yum, dnf) for tool installation
- Supports `ps aux --sort` for advanced process sorting

## License

This script is provided as-is for development environment monitoring purposes.

## Contributing

Contributions are welcome. Please ensure:
- Cross-platform compatibility
- Proper error handling
- Updated documentation
- Test on both macOS and Linux systems