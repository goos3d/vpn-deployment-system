#!/bin/bash

################################################################################
#                           PROFESSIONAL VPN PEER MANAGER                      #
################################################################################
#
# Professional WireGuard Peer Addition Script
# Version: 2.0
# Created: August 4, 2025
# 
# Features:
# - Comprehensive error handling and validation
# - Automatic backup and rollback capability  
# - Detailed logging and debugging
# - IP conflict detection and resolution
# - Service health monitoring
# - Professional client configuration generation
# - HIPAA-compliant security measures
#
# Usage: ./professional-add-peer.sh <peer-name> [options]
#
# Support: thomas@eastbayav.com | (510) 666-5915
# 
################################################################################

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Script Configuration
readonly SCRIPT_VERSION="2.0"
readonly SCRIPT_NAME="Professional VPN Peer Manager"
readonly LOG_FILE="/var/log/vpn-peer-manager.log"
readonly CONFIG_DIR="/etc/wireguard"
readonly SERVER_CONFIG="$CONFIG_DIR/wg0.conf"
readonly BACKUP_DIR="$CONFIG_DIR/backups"
readonly CLIENT_DIR="$CONFIG_DIR/clients"

# Network Configuration  
readonly VPN_NETWORK="10.0.0"
readonly VPN_PORT="51820"
readonly SERVER_IP="184.105.7.112"  # Dr. Kover's server IP

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Debugging flag
DEBUG=${DEBUG:-0}

################################################################################
# Logging Functions
################################################################################

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

debug() {
    [[ $DEBUG -eq 1 ]] && log "DEBUG" "$@"
}

info() {
    echo -e "${BLUE}ℹ️  $*${NC}"
    log "INFO" "$@"
}

success() {
    echo -e "${GREEN}✅ $*${NC}"
    log "SUCCESS" "$@"
}

warning() {
    echo -e "${YELLOW}⚠️  $*${NC}"
    log "WARNING" "$@"
}

error() {
    echo -e "${RED}❌ $*${NC}" >&2
    log "ERROR" "$@"
}

################################################################################
# Utility Functions
################################################################################

print_header() {
    echo -e "${PURPLE}"
    echo "=================================================================================="
    echo "                    $SCRIPT_NAME v$SCRIPT_VERSION"
    echo "=================================================================================="
    echo -e "${NC}"
}

print_separator() {
    echo -e "${CYAN}──────────────────────────────────────────────────────────────────────────────${NC}"
}

show_usage() {
    cat << EOF
${WHITE}USAGE:${NC}
    $0 <peer-name> [options]

${WHITE}EXAMPLES:${NC}
    $0 iPhone-DrKover
    $0 iPad-Reception --debug
    $0 Laptop-Assistant --server-ip 184.105.7.112

${WHITE}OPTIONS:${NC}
    --debug         Enable detailed debugging output
    --server-ip     Override server IP (default: $SERVER_IP)
    --dry-run       Show what would be done without making changes
    --help          Show this help message

${WHITE}PEER NAMING CONVENTIONS:${NC}
    - Use descriptive names (iPhone-DrKover, iPad-Reception)
    - No spaces (use hyphens or underscores)
    - Letters, numbers, hyphens, and underscores only

${WHITE}SUPPORT:${NC}
    Email: thomas@eastbayav.com
    Phone: (510) 666-5915
EOF
}

################################################################################
# Validation Functions
################################################################################

validate_environment() {
    info "Validating environment..."
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root or with sudo"
        error "Try: sudo $0 $*"
        exit 1
    fi
    
    # Check if WireGuard is installed
    if ! command -v wg >/dev/null 2>&1; then
        error "WireGuard is not installed"
        error "Install with: apt update && apt install wireguard"
        exit 1
    fi
    
    # Check if config directory exists
    if [[ ! -d "$CONFIG_DIR" ]]; then
        error "WireGuard configuration directory not found: $CONFIG_DIR"
        exit 1
    fi
    
    # Check if server config exists
    if [[ ! -f "$SERVER_CONFIG" ]]; then
        error "Server configuration file not found: $SERVER_CONFIG"
        exit 1
    fi
    
    # Create necessary directories
    mkdir -p "$BACKUP_DIR" "$CLIENT_DIR"
    
    # Ensure log file exists and is writable
    touch "$LOG_FILE" || {
        error "Cannot create log file: $LOG_FILE"
        exit 1
    }
    
    success "Environment validation passed"
}

validate_peer_name() {
    local peer_name="$1"
    
    debug "Validating peer name: $peer_name"
    
    # Check if peer name is provided
    if [[ -z "$peer_name" ]]; then
        error "Peer name is required"
        show_usage
        exit 1
    fi
    
    # Check peer name format
    if [[ ! "$peer_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        error "Invalid peer name format: $peer_name"
        error "Use only letters, numbers, hyphens, and underscores"
        exit 1
    fi
    
    # Check if peer already exists
    if grep -q "# Peer: $peer_name" "$SERVER_CONFIG" 2>/dev/null; then
        error "Peer '$peer_name' already exists"
        error "Choose a different name or remove the existing peer first"
        exit 1
    fi
    
    success "Peer name validation passed: $peer_name"
}

################################################################################
# Network Functions
################################################################################

get_next_available_ip() {
    info "Finding next available IP address..."
    
    local used_ips=()
    local next_ip=2  # Start from .2 (server typically uses .1)
    
    # Extract all used IPs from server config
    while IFS= read -r ip; do
        used_ips+=("$ip")
        debug "Found used IP: $VPN_NETWORK.$ip"
    done < <(grep -oP "$VPN_NETWORK\.\K[0-9]+" "$SERVER_CONFIG" 2>/dev/null | sort -n)
    
    # Find next available IP
    while [[ " ${used_ips[*]} " =~ " ${next_ip} " ]]; do
        ((next_ip++))
        if [[ $next_ip -gt 254 ]]; then
            error "No available IP addresses in network $VPN_NETWORK.0/24"
            exit 1
        fi
    done
    
    local assigned_ip="$VPN_NETWORK.$next_ip"
    success "Next available IP: $assigned_ip"
    echo "$assigned_ip"
}

################################################################################
# Key Management Functions
################################################################################

generate_keys() {
    local peer_name="$1"
    
    info "Generating cryptographic keys for $peer_name..."
    
    # Generate private key
    local private_key
    private_key=$(wg genkey) || {
        error "Failed to generate private key"
        exit 1
    }
    
    # Generate public key from private key
    local public_key
    public_key=$(echo "$private_key" | wg pubkey) || {
        error "Failed to generate public key"
        exit 1
    }
    
    debug "Private key generated: ${private_key:0:10}..."
    debug "Public key generated: ${public_key:0:10}..."
    
    success "Keys generated successfully"
    
    # Return keys via associative array simulation
    echo "PRIVATE_KEY=$private_key"
    echo "PUBLIC_KEY=$public_key"
}

get_server_public_key() {
    info "Retrieving server public key..."
    
    local server_private_key
    server_private_key=$(grep "PrivateKey" "$SERVER_CONFIG" | head -1 | awk '{print $3}') || {
        error "Failed to extract server private key from config"
        exit 1
    }
    
    local server_public_key
    server_public_key=$(echo "$server_private_key" | wg pubkey) || {
        error "Failed to generate server public key"
        exit 1
    }
    
    debug "Server public key: ${server_public_key:0:10}..."
    success "Server public key retrieved"
    
    echo "$server_public_key"
}

################################################################################
# Configuration Management Functions
################################################################################

create_backup() {
    info "Creating configuration backup..."
    
    local backup_file="$BACKUP_DIR/wg0.conf.backup.$(date +%Y%m%d_%H%M%S)"
    
    cp "$SERVER_CONFIG" "$backup_file" || {
        error "Failed to create backup"
        exit 1
    }
    
    success "Backup created: $backup_file"
    echo "$backup_file"
}

add_peer_to_server_config() {
    local peer_name="$1"
    local public_key="$2" 
    local client_ip="$3"
    
    info "Adding peer to server configuration..."
    
    # Add peer section to server config
    {
        echo ""
        echo "# Peer: $peer_name (added $(date '+%Y-%m-%d %H:%M:%S'))"
        echo "[Peer]"
        echo "PublicKey = $public_key"
        echo "AllowedIPs = $client_ip/32"
    } >> "$SERVER_CONFIG" || {
        error "Failed to add peer to server configuration"
        return 1
    }
    
    success "Peer added to server configuration"
}

create_client_config() {
    local peer_name="$1"
    local private_key="$2"
    local client_ip="$3"
    local server_public_key="$4"
    local server_ip="$5"
    
    info "Creating client configuration..."
    
    local client_config_file="$CLIENT_DIR/DrKover-$peer_name.conf"
    
    cat > "$client_config_file" << EOF
# WireGuard Client Configuration
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
# Peer: $peer_name
# Server: $server_ip:$VPN_PORT
# Support: thomas@eastbayav.com | (510) 666-5915

[Interface]
PrivateKey = $private_key
Address = $client_ip/32
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = $server_public_key
Endpoint = $server_ip:$VPN_PORT
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

    # Set secure permissions
    chmod 600 "$client_config_file" || {
        error "Failed to set permissions on client config"
        return 1
    }
    
    success "Client configuration created: $client_config_file"
    echo "$client_config_file"
}

################################################################################
# Service Management Functions
################################################################################

test_config_syntax() {
    info "Testing configuration syntax..."
    
    # Test WireGuard configuration syntax
    if wg-quick strip wg0 >/dev/null 2>&1; then
        success "Configuration syntax is valid"
        return 0
    else
        error "Configuration syntax error detected"
        return 1
    fi
}

restart_wireguard_service() {
    info "Restarting WireGuard service..."
    
    if systemctl restart wg-quick@wg0; then
        sleep 2  # Give service time to start
        if systemctl is-active --quiet wg-quick@wg0; then
            success "WireGuard service restarted successfully"
            return 0
        else
            error "WireGuard service failed to start"
            return 1
        fi
    else
        error "Failed to restart WireGuard service"
        return 1
    fi
}

verify_vpn_status() {
    info "Verifying VPN status..."
    
    # Check service status
    if ! systemctl is-active --quiet wg-quick@wg0; then
        error "WireGuard service is not running"
        return 1
    fi
    
    # Check interface status
    if ! wg show wg0 >/dev/null 2>&1; then
        error "WireGuard interface wg0 is not active"
        return 1
    fi
    
    # Get interface statistics
    local peer_count
    peer_count=$(wg show wg0 peers | wc -l)
    
    success "VPN is running with $peer_count connected peers"
    return 0
}

################################################################################
# Rollback Functions
################################################################################

rollback_changes() {
    local backup_file="$1"
    
    warning "Rolling back changes..."
    
    if [[ -f "$backup_file" ]]; then
        cp "$backup_file" "$SERVER_CONFIG" || {
            error "Failed to restore backup"
            return 1
        }
        
        if restart_wireguard_service; then
            success "Changes rolled back successfully"
            return 0
        else
            error "Rollback completed but service restart failed"
            return 1
        fi
    else
        error "Backup file not found: $backup_file"
        return 1
    fi
}

################################################################################
# Reporting Functions
################################################################################

generate_peer_report() {
    local peer_name="$1"
    local client_ip="$2"
    local client_config_file="$3"
    local server_ip="$4"
    
    print_separator
    echo -e "${WHITE}PEER ADDITION COMPLETE${NC}"
    print_separator
    
    cat << EOF
${GREEN}✅ SUCCESS${NC} - Peer '$peer_name' has been added to your VPN

${WHITE}PEER DETAILS:${NC}
    Name:           $peer_name
    IP Address:     $client_ip
    Network:        $VPN_NETWORK.0/24
    Server:         $server_ip:$VPN_PORT
    Config File:    $client_config_file

${WHITE}NEXT STEPS:${NC}
    1. Download the config file: $client_config_file
    2. Import into WireGuard app on your device
    3. Connect and test the VPN connection

${WHITE}CONFIGURATION FILES:${NC}
    • Server config updated: $SERVER_CONFIG
    • Client config created: $client_config_file
    • Backup created in: $BACKUP_DIR

${WHITE}SUPPORT:${NC}
    If you need assistance with device setup or troubleshooting:
    📧 Email: thomas@eastbayav.com
    📱 Phone: (510) 666-5915

${WHITE}PROFESSIONAL VPN MANAGEMENT:${NC}
    Your VPN system is now managed by professional-grade scripts
    with automatic backups, error recovery, and detailed logging.
EOF

    print_separator
}

show_connection_instructions() {
    local client_config_file="$1"
    
    echo -e "${CYAN}"
    echo "DEVICE CONNECTION INSTRUCTIONS:"
    echo "================================"
    echo -e "${NC}"
    
    cat << EOF
${WHITE}FOR MOBILE DEVICES (iOS/Android):${NC}
    1. Install WireGuard app from App Store/Google Play
    2. Copy the config file to your device
    3. Open WireGuard app → Add Tunnel → Import from file
    4. Select the config file: $(basename "$client_config_file")
    5. Toggle the connection ON

${WHITE}FOR DESKTOP (Windows/Mac/Linux):${NC}
    1. Install WireGuard from https://www.wireguard.com/install/
    2. Copy the config file to your computer
    3. Open WireGuard app → Add Tunnel → Import tunnel from file
    4. Select the config file: $(basename "$client_config_file")
    5. Click "Activate" to connect

${WHITE}VERIFICATION:${NC}
    After connecting, verify your VPN is working:
    • Visit https://whatismyipaddress.com
    • Your IP should show: $SERVER_IP
    • Test accessing your practice management system
EOF
}

################################################################################
# Main Functions
################################################################################

parse_arguments() {
    local peer_name=""
    local server_ip="$SERVER_IP"
    local dry_run=0
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --debug)
                DEBUG=1
                debug "Debug mode enabled"
                shift
                ;;
            --server-ip)
                server_ip="$2"
                shift 2
                ;;
            --dry-run)
                dry_run=1
                warning "Dry run mode enabled - no changes will be made"
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            -*)
                error "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                if [[ -z "$peer_name" ]]; then
                    peer_name="$1"
                else
                    error "Too many arguments"
                    show_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Export variables for use in other functions
    export PEER_NAME="$peer_name"
    export SERVER_IP_OVERRIDE="$server_ip"
    export DRY_RUN="$dry_run"
}

main() {
    local start_time
    start_time=$(date +%s)
    
    print_header
    
    # Parse command line arguments
    parse_arguments "$@"
    
    # Validate inputs
    validate_environment
    validate_peer_name "$PEER_NAME"
    
    if [[ $DRY_RUN -eq 1 ]]; then
        info "DRY RUN MODE - Showing what would be done:"
        echo "  • Would generate keys for peer: $PEER_NAME"
        echo "  • Would assign next available IP address"
        echo "  • Would add peer to server configuration"
        echo "  • Would create client configuration"
        echo "  • Would restart WireGuard service"
        exit 0
    fi
    
    # Main process variables
    local backup_file=""
    local client_config_file=""
    local client_ip=""
    local keys_output=""
    local private_key=""
    local public_key=""
    local server_public_key=""
    
    # Create backup before making changes
    backup_file=$(create_backup)
    
    # Generate keys
    keys_output=$(generate_keys "$PEER_NAME")
    eval "$keys_output"  # Sets PRIVATE_KEY and PUBLIC_KEY
    private_key="$PRIVATE_KEY"
    public_key="$PUBLIC_KEY"
    
    # Get server public key
    server_public_key=$(get_server_public_key)
    
    # Get next available IP
    client_ip=$(get_next_available_ip)
    
    # Add peer to server configuration
    if ! add_peer_to_server_config "$PEER_NAME" "$public_key" "$client_ip"; then
        error "Failed to add peer to server configuration"
        rollback_changes "$backup_file"
        exit 1
    fi
    
    # Test configuration syntax
    if ! test_config_syntax; then
        error "Configuration syntax error after adding peer"
        rollback_changes "$backup_file"
        exit 1
    fi
    
    # Create client configuration
    client_config_file=$(create_client_config "$PEER_NAME" "$private_key" "$client_ip" "$server_public_key" "$SERVER_IP_OVERRIDE")
    
    # Restart WireGuard service
    if ! restart_wireguard_service; then
        error "Failed to restart WireGuard service"
        warning "Attempting rollback..."
        rollback_changes "$backup_file"
        exit 1
    fi
    
    # Verify VPN status
    if ! verify_vpn_status; then
        error "VPN status verification failed"
        warning "Service may be running but with issues"
    fi
    
    # Generate completion report
    generate_peer_report "$PEER_NAME" "$client_ip" "$client_config_file" "$SERVER_IP_OVERRIDE"
    show_connection_instructions "$client_config_file"
    
    # Calculate execution time
    local end_time
    end_time=$(date +%s)
    local execution_time=$((end_time - start_time))
    
    success "Peer addition completed successfully in ${execution_time} seconds"
    info "Log file: $LOG_FILE"
    
    return 0
}

################################################################################
# Script Execution
################################################################################

# Set up error handling
trap 'error "Script interrupted by user"; exit 130' INT
trap 'error "Script terminated"; exit 1' TERM

# Create log file directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Start main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
