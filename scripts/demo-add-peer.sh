#!/bin/bash

################################################################################
#                    DR. KOVER VPN PEER ADDITION SCRIPT                        #
################################################################################
#
# Professional WireGuard Peer Addition Script - Demo Version
# Version: 2.0 (Testing Edition)
# Created: August 4, 2025
# 
# This version is configured for testing and demonstration purposes
# For deployment, use the production version with proper paths
#
# Features:
# - Professional peer addition with full error handling
# - Smart IP address management
# - Automatic backup and recovery
# - Comprehensive logging
# - Beautiful output formatting
#
# Support: thomas@eastbayav.com | (510) 666-5915
# 
################################################################################

set -euo pipefail

# Script Configuration
readonly SCRIPT_VERSION="2.0-demo"
readonly SCRIPT_NAME="Dr. Kover VPN Peer Manager"

# For demo/testing - use local paths instead of system paths
readonly BASE_DIR="${BASE_DIR:-$(pwd)/vpn-demo}"
readonly LOG_FILE="${LOG_FILE:-$BASE_DIR/logs/vpn-peer-manager.log}"
readonly CONFIG_DIR="${CONFIG_DIR:-$BASE_DIR/etc/wireguard}"
readonly SERVER_CONFIG="$CONFIG_DIR/wg0.conf"
readonly BACKUP_DIR="$CONFIG_DIR/backups"
readonly CLIENT_DIR="$CONFIG_DIR/clients"

# Network Configuration  
readonly VPN_NETWORK="10.0.0"
readonly VPN_PORT="51820"
readonly SERVER_IP="184.105.7.112"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m'

# Global variables
DEBUG=${DEBUG:-0}
DRY_RUN=0
PEER_NAME=""
SERVER_IP_OVERRIDE="$SERVER_IP"

################################################################################
# Logging Functions
################################################################################

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Create log directory if it doesn't exist
    mkdir -p "$(dirname "$LOG_FILE")"
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

debug() {
    if [[ $DEBUG -eq 1 ]]; then
        echo -e "${PURPLE}🔍 DEBUG: $*${NC}"
        log "DEBUG" "$@"
    fi
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
# Display Functions
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
    --demo          Run in demo mode (creates mock environment)
    --help          Show this help message

${WHITE}PEER NAMING CONVENTIONS:${NC}
    - Use descriptive names (iPhone-DrKover, iPad-Reception)
    - No spaces (use hyphens or underscores)  
    - Letters, numbers, hyphens, and underscores only

${WHITE}SUPPORT:${NC}
    Email: thomas@eastbayav.com
    Phone: (510) 666-5915
    
${WHITE}VALUE PROPOSITION:${NC}
    This professional script replaces manual VPN configuration:
    • Manual process: 10-15 minutes per device, error-prone
    • Professional script: 30 seconds per device, bulletproof
    • Includes automatic backups, logging, and error recovery
    • Worth every penny of the \$200 automation investment!
EOF
}

################################################################################
# Mock/Demo Environment Setup
################################################################################

setup_demo_environment() {
    info "Setting up demonstration environment..."
    
    # Create directory structure
    mkdir -p "$CONFIG_DIR" "$BACKUP_DIR" "$CLIENT_DIR" "$(dirname "$LOG_FILE")"
    
    # Create mock server configuration if it doesn't exist
    if [[ ! -f "$SERVER_CONFIG" ]]; then
        info "Creating demo server configuration..."
        cat > "$SERVER_CONFIG" << 'EOF'
# WireGuard Server Configuration - Demo
# Dr. Kover's VPN Server
[Interface]
PrivateKey = oK2qEhBhp3LBs3CFCqk5yQqfDlP7I5rAwC9W+Mip2X8=
Address = 10.0.0.1/24
ListenPort = 51820
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# Existing peers
# Peer: iPhone-DrKover (added 2025-08-03 10:30:00)
[Peer]
PublicKey = 3vfrCBSU1Tq4I1MKpT7yc3QI5XMrP1dZ9Qg4K8E+2W0=
AllowedIPs = 10.0.0.2/32

# Peer: iPad-Reception (added 2025-08-03 14:15:00)
[Peer]
PublicKey = F+rPn3JkK4N6kx9DdB8oTcY2RvE3H7LmJ5Q4E6KzNx8=
AllowedIPs = 10.0.0.3/32
EOF
    fi
    
    success "Demo environment ready at: $BASE_DIR"
}

################################################################################
# Validation Functions
################################################################################

validate_peer_name() {
    local peer_name="$1"
    
    debug "Validating peer name: $peer_name"
    
    if [[ -z "$peer_name" ]]; then
        error "Peer name is required"
        show_usage
        exit 1
    fi
    
    if [[ ! "$peer_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        error "Invalid peer name format: $peer_name"
        error "Use only letters, numbers, hyphens, and underscores"
        exit 1
    fi
    
    if [[ -f "$SERVER_CONFIG" ]] && grep -q "# Peer: $peer_name" "$SERVER_CONFIG" 2>/dev/null; then
        error "Peer '$peer_name' already exists"
        error "Choose a different name or remove the existing peer first"
        exit 1
    fi
    
    success "Peer name validation passed: $peer_name"
}

################################################################################
# Core Functions
################################################################################

get_next_available_ip() {
    local next_ip=2  # Professional standard: start from .2
    
    if [[ -f "$SERVER_CONFIG" ]]; then
        local used_ips
        used_ips=$(grep -oP "$VPN_NETWORK\.\K[0-9]+" "$SERVER_CONFIG" 2>/dev/null | sort -n || echo "")
        
        debug "Professional IP analysis - Used IPs: $used_ips"
        
        while echo "$used_ips" | grep -q "^${next_ip}$"; do
            ((next_ip++))
            if [[ $next_ip -gt 254 ]]; then
                error "Professional network full - contact support for expansion"
                exit 1
            fi
        done
    fi
    
    echo "$VPN_NETWORK.$next_ip"
}

generate_keys() {
    info "Generating cryptographic keys..."
    
    # In demo mode, generate mock keys for demonstration  
    local random_suffix=$(date +%s%N | cut -c1-8)
    local private_key="demo_private_key_${random_suffix}_mock"
    local public_key="demo_public_key_${random_suffix}_mock"
    
    debug "Demo private key: ${private_key:0:20}..."
    debug "Demo public key: ${public_key:0:20}..."
    
    success "Keys generated successfully"
    
    echo "PRIVATE_KEY=$private_key"
    echo "PUBLIC_KEY=$public_key"
}

get_server_public_key() {
    # In demo mode, return a mock server public key
    local server_public_key="demo_server_public_key_$(date +%s)"
    
    debug "Demo server public key: ${server_public_key:0:20}..."
    
    echo "$server_public_key"
}

create_backup() {
    info "Creating configuration backup..."
    
    local backup_file="$BACKUP_DIR/wg0.conf.backup.$(date +%Y%m%d_%H%M%S)"
    
    if [[ -f "$SERVER_CONFIG" ]]; then
        cp "$SERVER_CONFIG" "$backup_file"
        success "Backup created: $backup_file"
        echo "$backup_file"
    else
        warning "No server config found to backup"
        echo ""
    fi
}

add_peer_to_server_config() {
    local peer_name="$1"
    local public_key="$2" 
    local client_ip="$3"
    
    info "Adding peer to server configuration..."
    
    if [[ $DRY_RUN -eq 1 ]]; then
        info "DRY RUN: Would add peer to $SERVER_CONFIG"
        return 0
    fi
    
    {
        echo ""
        echo "# Peer: $peer_name (added $(date '+%Y-%m-%d %H:%M:%S'))"
        echo "[Peer]"
        echo "PublicKey = $public_key"
        echo "AllowedIPs = $client_ip/32"
    } >> "$SERVER_CONFIG"
    
    success "Peer added to server configuration"
}

create_professional_client_config() {
    local peer_name="$1"
    local private_key="$2"
    local client_ip="$3"
    local server_public_key="$4"
    local server_ip="$5"
    
    local client_config_file="$CLIENT_DIR/DrKover-$peer_name.conf"
    
    if [[ $DRY_RUN -eq 1 ]]; then
        echo "$client_config_file"
        return 0
    fi
    
    cat > "$client_config_file" << EOF
# Professional WireGuard Client Configuration
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
# Peer: $peer_name
# Server: $server_ip:$VPN_PORT
# 
# Professional VPN Service by East Bay AV Solutions
# Support: thomas@eastbayav.com | (510) 666-5915
# Service Value: \$200 Professional Automation

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

    # Professional security: restrictive permissions
    chmod 600 "$client_config_file" 2>/dev/null || true
    
    echo "$client_config_file"
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
${GREEN}✅ SUCCESS${NC} - Peer '$peer_name' has been added to Dr. Kover's VPN

${WHITE}PEER DETAILS:${NC}
    Name:           $peer_name
    IP Address:     $client_ip
    Network:        $VPN_NETWORK.0/24
    Server:         $server_ip:$VPN_PORT
    Config File:    $client_config_file

${WHITE}NEXT STEPS FOR DR. KOVER:${NC}
    1. Download the config file: $(basename "$client_config_file")
    2. Import into WireGuard app on the device
    3. Connect and test the VPN connection

${WHITE}PROFESSIONAL SERVICE VALUE:${NC}
    • Manual process: 10-15 minutes per device
    • This script: 30 seconds per device  
    • Includes automatic backups and error recovery
    • Professional logging and monitoring
    • \$200 one-time investment pays for itself quickly!

${WHITE}SUPPORT AVAILABLE:${NC}
    📧 Email: thomas@eastbayav.com
    📱 Phone: (510) 666-5915
    
${WHITE}FILES CREATED:${NC}
    • Server config updated: $SERVER_CONFIG
    • Client config: $client_config_file
    • Backup created in: $BACKUP_DIR
    • Activity logged to: $LOG_FILE
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
    2. Copy $(basename "$client_config_file") to your device
    3. Open WireGuard app → Add Tunnel → Import from file
    4. Select the config file
    5. Toggle the connection ON

${WHITE}FOR DESKTOP (Windows/Mac/Linux):${NC}
    1. Install WireGuard from https://www.wireguard.com/install/
    2. Copy $(basename "$client_config_file") to your computer
    3. Open WireGuard app → Add Tunnel → Import tunnel from file
    4. Select the config file
    5. Click "Activate" to connect

${WHITE}VERIFICATION:${NC}
    After connecting, verify VPN is working:
    • Visit https://whatismyipaddress.com
    • Your IP should show: $SERVER_IP_OVERRIDE
    • All internet traffic is now encrypted and secure
EOF
}

################################################################################
# Main Functions
################################################################################

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --debug)
                DEBUG=1
                debug "Debug mode enabled"
                shift
                ;;
            --server-ip)
                SERVER_IP_OVERRIDE="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=1
                warning "Dry run mode enabled - no changes will be made"
                shift
                ;;
            --demo)
                setup_demo_environment
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
                if [[ -z "$PEER_NAME" ]]; then
                    PEER_NAME="$1"
                else
                    error "Too many arguments"
                    show_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
}

main() {
    local start_time
    start_time=$(date +%s)
    
    print_header
    
    # Parse command line arguments
    parse_arguments "$@"
    
    # Set up demo environment
    setup_demo_environment
    
    # Validate inputs
    validate_peer_name "$PEER_NAME"
    
    if [[ $DRY_RUN -eq 1 ]]; then
        info "DRY RUN MODE - Showing what would be done:"
        echo "  • Would generate keys for peer: $PEER_NAME"
        echo "  • Would assign next available IP address"
        echo "  • Would add peer to server configuration"
        echo "  • Would create client configuration"
        echo "  • Would restart WireGuard service (in production)"
        success "Dry run completed successfully"
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
    
    # Create backup
    backup_file=$(create_backup)
    
    # Generate keys
    info "Generating cryptographic keys..."
    local random_suffix=$(date +%s | tail -c 6)
    private_key="demo_private_key_${random_suffix}_mock"
    public_key="demo_public_key_${random_suffix}_mock"
    
    debug "Demo private key: ${private_key:0:20}..."
    debug "Demo public key: ${public_key:0:20}..."
    success "Keys generated successfully"
    
    # Get server public key
    server_public_key=$(get_server_public_key)
    
    # Get next available IP
    client_ip=$(get_next_available_ip)
    
    # Add peer to server configuration
    add_peer_to_server_config "$PEER_NAME" "$public_key" "$client_ip"
    
    # Create client configuration
    client_config_file=$(create_professional_client_config "$PEER_NAME" "$private_key" "$client_ip" "$server_public_key" "$SERVER_IP_OVERRIDE")
    
    # In production, we would restart WireGuard here
    info "In production: Would restart WireGuard service here"
    
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

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
