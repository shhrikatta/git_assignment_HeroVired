#!/bin/bash

# System Monitoring Script for Development Environment
# Author: Development Team
# Date: $(date +%Y-%m-%d)
# Purpose: Monitor system health, performance, and support capacity planning

set -euo pipefail

# Configuration
LOG_DIR="$HOME/system_monitoring"
LOG_FILE="$LOG_DIR/system_monitor_$(date +%Y%m%d).log"
REPORT_FILE="$LOG_DIR/daily_report_$(date +%Y%m%d).txt"
ALERT_THRESHOLD_CPU=80
ALERT_THRESHOLD_MEMORY=85
ALERT_THRESHOLD_DISK=90

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install monitoring tools
install_monitoring_tools() {
    print_header "Installing Monitoring Tools"
    
    # Detect package manager
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if ! command_exists brew; then
            print_error "Homebrew not found. Please install Homebrew first."
            exit 1
        fi
        
        # Install htop if not present
        if ! command_exists htop; then
            print_status "Installing htop..."
            brew install htop
        else
            print_status "htop already installed"
        fi
        
        # Install nmon if not present
        if ! command_exists nmon; then
            print_status "Installing nmon..."
            brew install nmon
        else
            print_status "nmon already installed"
        fi
        
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command_exists apt-get; then
            # Ubuntu/Debian
            sudo apt-get update
            sudo apt-get install -y htop nmon
        elif command_exists yum; then
            # RHEL/CentOS
            sudo yum install -y htop nmon
        elif command_exists dnf; then
            # Fedora
            sudo dnf install -y htop nmon
        else
            print_error "Unsupported Linux distribution"
            exit 1
        fi
    else
        print_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
    
    log_message "Monitoring tools installation completed"
}

# Function to create directory structure
setup_directories() {
    print_status "Setting up monitoring directories..."
    mkdir -p "$LOG_DIR"
    mkdir -p "$LOG_DIR/archives"
    log_message "Directory structure created: $LOG_DIR"
}

# Function to monitor CPU usage
monitor_cpu() {
    print_header "CPU Monitoring"
    
    # Get CPU usage using iostat or ps
    if [[ "$OSTYPE" == "darwin"* ]]; then
        CPU_USAGE=$(ps aux | awk '{sum += $3} END {printf "%.1f", sum}')
    else
        CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
    fi
    
    echo "Current CPU Usage: ${CPU_USAGE}%"
    
    # Check for high CPU usage
    if (( $(echo "$CPU_USAGE > $ALERT_THRESHOLD_CPU" | bc -l) )); then
        print_warning "High CPU usage detected: ${CPU_USAGE}%"
        log_message "ALERT: High CPU usage - ${CPU_USAGE}%"
    fi
    
    # Get top CPU consuming processes
    echo -e "\nTop 5 CPU consuming processes:"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        ps aux -r | head -n 6
    else
        ps aux --sort=-%cpu | head -n 6
    fi
    
    log_message "CPU usage: ${CPU_USAGE}%"
}

# Function to monitor memory usage
monitor_memory() {
    print_header "Memory Monitoring"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS memory monitoring
        VM_STAT=$(vm_stat)
        TOTAL_MEM=$(sysctl hw.memsize | awk '{print $2/1024/1024/1024}')
        FREE_PAGES=$(echo "$VM_STAT" | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
        INACTIVE_PAGES=$(echo "$VM_STAT" | grep "Pages inactive" | awk '{print $3}' | sed 's/\.//')
        FREE_MEM=$(echo "($FREE_PAGES + $INACTIVE_PAGES) * 4096 / 1024 / 1024 / 1024" | bc -l)
        USED_MEM=$(echo "$TOTAL_MEM - $FREE_MEM" | bc -l)
        MEM_USAGE=$(echo "$USED_MEM / $TOTAL_MEM * 100" | bc -l | cut -c1-5)
        
        printf "Total Memory: %.2f GB\n" "$TOTAL_MEM"
        printf "Used Memory: %.2f GB\n" "$USED_MEM"
        printf "Free Memory: %.2f GB\n" "$FREE_MEM"
        printf "Memory Usage: %.1f%%\n" "$MEM_USAGE"
    else
        # Linux memory monitoring
        MEM_INFO=$(free -m)
        echo "$MEM_INFO"
        MEM_USAGE=$(free | grep Mem | awk '{printf("%.1f", $3/$2 * 100.0)}')
    fi
    
    # Check for high memory usage
    if (( $(echo "$MEM_USAGE > $ALERT_THRESHOLD_MEMORY" | bc -l) )); then
        print_warning "High memory usage detected: ${MEM_USAGE}%"
        log_message "ALERT: High memory usage - ${MEM_USAGE}%"
    fi
    
    echo -e "\nTop 5 memory consuming processes:"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        ps aux -m | head -n 6
    else
        ps aux --sort=-%mem | head -n 6
    fi
    
    log_message "Memory usage: ${MEM_USAGE}%"
}

# Function to monitor disk usage
monitor_disk() {
    print_header "Disk Usage Monitoring"
    
    echo "Disk space usage by filesystem:"
    df -h 2>/dev/null || df -h /
    
    echo -e "\nDisk usage alerts:"
    (df -h 2>/dev/null || df -h /) | awk 'NR>1 {
        usage = substr($5, 1, length($5)-1)
        if (usage > '$ALERT_THRESHOLD_DISK') {
            print "WARNING: " $6 " is " $5 " full (" $4 " available)"
        }
    }'
    
    echo -e "\nLargest directories in current filesystem:"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        du -h -d 1 . 2>/dev/null | sort -hr | head -10
    else
        du -h --max-depth=1 . 2>/dev/null | sort -hr | head -10
    fi
    
    # Log disk usage
    DISK_USAGE=$(df -h / 2>/dev/null | awk 'NR==2 {print $5}')
    log_message "Root disk usage: $DISK_USAGE"
}

# Function to monitor processes
monitor_processes() {
    print_header "Process Monitoring"
    
    echo "Total number of processes: $(ps aux | wc -l)"
    
    echo -e "\nProcesses by state:"
    ps aux | awk 'NR>1 {count[$8]++} END {for (state in count) print state ": " count[state]}'
    
    echo -e "\nResource-intensive processes (CPU > 10% or MEM > 5%):"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        ps aux | awk 'NR>1 && ($3>10 || $4>5) {printf "PID: %-8s CPU: %-6s%% MEM: %-6s%% CMD: %s\n", $2, $3, $4, $11}'
    else
        ps aux | awk 'NR>1 && ($3>10 || $4>5) {printf "PID: %-8s CPU: %-6s%% MEM: %-6s%% CMD: %s\n", $2, $3, $4, $11}'
    fi
    
    log_message "Process monitoring completed - $(ps aux | wc -l) total processes"
}

# Function to monitor network connections
monitor_network() {
    print_header "Network Connection Monitoring"
    
    echo "Active network connections:"
    if command_exists netstat; then
        netstat -an | grep ESTABLISHED | wc -l | awk '{print "Established connections: " $1}'
        netstat -an | grep LISTEN | wc -l | awk '{print "Listening ports: " $1}'
    elif command_exists ss; then
        ss -an | grep ESTAB | wc -l | awk '{print "Established connections: " $1}'
        ss -an | grep LISTEN | wc -l | awk '{print "Listening ports: " $1}'
    fi
    
    log_message "Network monitoring completed"
}

# Function to generate system report
generate_report() {
    print_header "Generating System Report"
    
    # Create report file first
    cat > "$REPORT_FILE" << EOF
=== SYSTEM MONITORING REPORT ===
Generated: $(date)
Hostname: $(hostname)
Uptime: $(uptime)

=== SYSTEM OVERVIEW ===
$(uname -a)

=== RESOURCE ALERTS ===
EOF
    
    # Add alerts section
    if [ -f "$LOG_FILE" ]; then
        if grep -q "ALERT" "$LOG_FILE" 2>/dev/null; then
            grep "ALERT" "$LOG_FILE" 2>/dev/null | tail -10 >> "$REPORT_FILE"
        else
            echo "No alerts found in current log." >> "$REPORT_FILE"
        fi
    else
        echo "No log file found ($LOG_FILE), so no alerts to report." >> "$REPORT_FILE"
    fi
    
    # Add disk usage section
    echo -e "\n=== DISK USAGE SUMMARY ===" >> "$REPORT_FILE"
    (df -h 2>/dev/null || df -h / 2>/dev/null || echo "Disk usage information unavailable") >> "$REPORT_FILE"
    
    # Add memory section
    echo -e "\n=== MEMORY SUMMARY ===" >> "$REPORT_FILE"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        (vm_stat 2>/dev/null | head -5 || echo "Memory information unavailable") >> "$REPORT_FILE"
    else
        (free -h 2>/dev/null || echo "Memory information unavailable") >> "$REPORT_FILE"
    fi
    
    # Add process sections
    echo -e "\n=== TOP PROCESSES BY CPU ===" >> "$REPORT_FILE"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        (ps aux 2>/dev/null | head -n 6 || echo "Process information unavailable") >> "$REPORT_FILE"
    else
        (ps aux --sort=-%cpu 2>/dev/null | head -n 6 || echo "Process information unavailable") >> "$REPORT_FILE"
    fi
    
    echo -e "\n=== TOP PROCESSES BY MEMORY ===" >> "$REPORT_FILE"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        (ps aux 2>/dev/null | head -n 6 || echo "Process information unavailable") >> "$REPORT_FILE"
    else
        (ps aux --sort=-%mem 2>/dev/null | head -n 6 || echo "Process information unavailable") >> "$REPORT_FILE"
    fi
    
    print_status "Report generated: $REPORT_FILE"
    log_message "System report generated: $REPORT_FILE"
}

# Function to archive old logs
archive_old_logs() {
    print_status "Archiving old logs..."
    
    # Archive logs older than 7 days
    find "$LOG_DIR" -name "*.log" -mtime +7 -exec mv {} "$LOG_DIR/archives/" \;
    find "$LOG_DIR" -name "*.txt" -mtime +7 -exec mv {} "$LOG_DIR/archives/" \;
    
    # Compress archived logs older than 30 days
    find "$LOG_DIR/archives" -name "*.log" -mtime +30 -exec gzip {} \;
    find "$LOG_DIR/archives" -name "*.txt" -mtime +30 -exec gzip {} \;
    
    log_message "Log archival completed"
}

# Function to create monitoring cron job
setup_cron_job() {
    print_header "Setting up Automated Monitoring"
    
    SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
    CRON_ENTRY="0 */6 * * * $SCRIPT_PATH --monitor-only >> $LOG_DIR/cron.log 2>&1"
    
    # Check if cron job already exists
    if crontab -l 2>/dev/null | grep -q "$SCRIPT_PATH"; then
        print_status "Cron job already exists"
    else
        # Add cron job to run every 6 hours
        (crontab -l 2>/dev/null; echo "$CRON_ENTRY") | crontab -
        print_status "Cron job added: Monitor every 6 hours"
    fi
    
    log_message "Cron job setup completed"
}

# Function to display help
show_help() {
    cat << EOF
System Monitor Script

Usage: $0 [OPTIONS]

Options:
    --install           Install monitoring tools and setup directories
    --monitor           Run full system monitoring
    --report            Generate system report only
    --setup-cron        Setup automated monitoring cron job
    --help              Show this help message

Examples:
    $0 --install        # First time setup
    $0 --monitor        # Run complete monitoring
    $0 --report         # Generate report only

Log files are stored in: $LOG_DIR
EOF
}

# Main execution logic
main() {
    case "${1:-}" in
        --install)
            setup_directories
            install_monitoring_tools
            # setup_cron_job
            print_status "Installation completed successfully!"
            ;;
        --monitor)
            setup_directories
            install_monitoring_tools
            log_message "=== MONITORING SESSION STARTED ==="
            monitor_cpu
            monitor_memory
            monitor_disk
            monitor_processes
            monitor_network
            generate_report
            archive_old_logs
            log_message "=== MONITORING SESSION COMPLETED ==="
            print_status "Monitoring completed. Check $REPORT_FILE for details."
            ;;
        --monitor-only)
            monitor_cpu >> "$LOG_FILE" 2>&1
            monitor_memory >> "$LOG_FILE" 2>&1
            monitor_disk >> "$LOG_FILE" 2>&1
            monitor_processes >> "$LOG_FILE" 2>&1
            monitor_network >> "$LOG_FILE" 2>&1
            generate_report
            ;;
        --report)
            generate_report
            ;;
        --setup-cron)
            setup_cron_job
            ;;
        --help|*)
            show_help
            ;;
    esac
}

# Ensure bc is available for calculations
if ! command_exists bc; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command_exists brew; then
            brew install bc
        fi
    elif command_exists apt-get; then
        sudo apt-get install -y bc
    fi
fi

# Run main function with all arguments
main "$@"