#!/bin/bash

################################################################################
#                    PROFESSIONAL VPN PEER ADDITION SCRIPT                    #
#                              PRODUCTION VERSION                              #
################################################################################
#
# Dr. Kover's VPN Professional Peer Management System
# Version: 2.0 Production
# Value: $200 Professional Automation Service
# 
# This script provides:
# • Professional peer addition in 30 seconds vs 15 minutes manual
# • Automatic backup and rollback capability
# • Smart IP address management  
# • Error handling and recovery
# • Professional client configuration generation
# • Comprehensive logging
#
# Support: thomas@eastbayav.com | (510) 666-5915
# 
################################################################################

set -euo pipefail

# Script Configuration
readonly SCRIPT_VERSION="2.0-production"
readonly SCRIPT_NAME="Dr. Kover VPN Professional Manager"
readonly LOG_FILE="/var/log/vpn-peer-manager.log"
readonly CONFIG_DIR="/etc/wireguard"
readonly SERVER_CONFIG="$CONFIG_DIR/wg0.conf"
readonly BACKUP_DIR="$CONFIG_DIR/backups"
readonly CLIENT_DIR="$CONFIG_DIR/clients"

# Network Configuration - Dr. Kover's Setup
readonly VPN_NETWORK="10.0.0"
readonly VPN_PORT="51820"
readonly SERVER_IP="184.105.7.112"

# Colors for professional output
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
# Professional Logging System
################################################################################

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE" 2>/dev/null || true
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
# Professional Display Functions
################################################################################

print_header() {
    echo -e "${PURPLE}"
    echo "=================================================================================="
    echo "                    $SCRIPT_NAME v$SCRIPT_VERSION"
    echo "                      Professional VPN Automation"
    echo "=================================================================================="
    echo -e "${NC}"
}

print_separator() {
    echo -e "${CYAN}──────────────────────────────────────────────────────────────────────────────${NC}"
}

show_usage() {
    cat << EOF
${WHITE}PROFESSIONAL VPN PEER ADDITION SERVICE${NC}

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

${WHITE}PROFESSIONAL SERVICE VALUE - \$200 INVESTMENT:${NC}
    • Manual process: 10-15 minutes per device, error-prone
    • This script: 30 seconds per device, bulletproof reliability
    • Automatic backups prevent data loss
    • Professional error handling and recovery
    • Detailed logging for troubleshooting
    • Pays for itself after 2-3 device additions!

${WHITE}SUPPORT:${NC}
    📧 Email: thomas@eastbayav.com
    📱 Phone: (510) 666-5915
    💰 Service: Professional VPN Management
EOF
}

################################################################################
# Professional Validation System
################################################################################

validate_environment() {
    info "Validating professional environment..."
    
    # Check root access
    if [[ $EUID -ne 0 ]]; then
        error "Professional script requires root access"
        error "Run with: sudo $0 $*"
        exit 1
    fi
    
    # Check WireGuard installation
    if ! command -v wg >/dev/null 2>&1; then
        error "WireGuard not installed - Professional setup required"
        error "Contact thomas@eastbayav.com for assistance"
        exit 1
    fi
    
    # Validate directory structure
    if [[ ! -d "$CONFIG_DIR" ]]; then
        error "WireGuard configuration directory missing: $CONFIG_DIR"
        exit 1
    fi
    
    if [[ ! -f "$SERVER_CONFIG" ]]; then
        error "Server configuration not found: $SERVER_CONFIG"
        exit 1
    fi
    
    # Create professional directory structure
    mkdir -p "$BACKUP_DIR" "$CLIENT_DIR"
    touch "$LOG_FILE" 2>/dev/null || true
    
    success "Professional environment validated"
}

validate_peer_name() {
    local peer_name="$1"
    
    debug "Validating peer name: $peer_name"
    
    if [[ -z "$peer_name" ]]; then
        error "Peer name is required for professional service"
        show_usage
        exit 1
    fi
    
    if [[ ! "$peer_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        error "Invalid peer name format: $peer_name"
        error "Professional naming: use only letters, numbers, hyphens, underscores"
        exit 1
    fi
    
    if grep -q "# Peer: $peer_name" "$SERVER_CONFIG" 2>/dev/null; then
        error "Peer '$peer_name' already exists in professional system"
        error "Choose different name or contact support for peer removal"
        exit 1
    fi
    
    success "Peer name professionally validated: $peer_name"
}

################################################################################
# Professional Network Management
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

################################################################################
# Professional Key Management
################################################################################

generate_professional_keys() {
    local peer_name="$1"
    
    # Generate cryptographically secure keys
    local private_key
    private_key=$(wg genkey) || {
        error "Professional key generation failed"
        exit 1
    }
    
    local public_key
    public_key=$(echo "$private_key" | wg pubkey) || {
        error "Professional public key generation failed"
        exit 1
    }
    
    debug "Professional keys generated for: $peer_name"
    
    echo "$private_key|$public_key"
}

get_server_public_key() {
    local server_private_key
    server_private_key=$(grep "PrivateKey" "$SERVER_CONFIG" | head -1 | awk '{print $3}') || {
        error "Cannot extract server private key from professional config"
        exit 1
    }
    
    local server_public_key
    server_public_key=$(echo "$server_private_key" | wg pubkey) || {
        error "Professional server key extraction failed"
        exit 1
    }
    
    echo "$server_public_key"
}

################################################################################
# Professional Configuration Management
################################################################################

create_professional_backup() {
    local backup_file="$BACKUP_DIR/wg0.conf.backup.$(date +%Y%m%d_%H%M%S)"
    
    cp "$SERVER_CONFIG" "$backup_file" || {
        error "Professional backup creation failed"
        exit 1
    }
    
    echo "$backup_file"
}

add_peer_to_professional_config() {
    local peer_name="$1"
    local public_key="$2"
    local client_ip="$3"
    
    if [[ $DRY_RUN -eq 1 ]]; then
        return 0
    fi
    
    {
        echo ""
        echo "# Peer: $peer_name (professionally added $(date '+%Y-%m-%d %H:%M:%S'))"
        echo "[Peer]"
        echo "PublicKey = $public_key"
        echo "AllowedIPs = $client_ip/32"
    } >> "$SERVER_CONFIG" || {
        error "Professional server configuration update failed"
        return 1
    }
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
    chmod 600 "$client_config_file" || {
        error "Professional security setup failed"
        return 1
    }
    
    echo "$client_config_file"
}

################################################################################
# Professional Service Management
################################################################################

restart_professional_service() {
    if [[ $DRY_RUN -eq 1 ]]; then
        return 0
    fi
    
    # Test configuration before restart
    if ! wg-quick strip wg0 >/dev/null 2>&1; then
        error "Professional configuration validation failed"
        return 1
    fi
    
    # Professional service restart
    if systemctl restart wg-quick@wg0; then
        sleep 2
        if systemctl is-active --quiet wg-quick@wg0; then
            return 0
        fi
    fi
    
    error "Professional service restart failed"
    return 1
}

################################################################################
# Professional Reporting System
################################################################################

generate_professional_report() {
    local peer_name="$1"
    local client_ip="$2"
    local client_config_file="$3"
    local server_ip="$4"
    
    print_separator
    echo -e "${WHITE}PROFESSIONAL PEER ADDITION - COMPLETE${NC}"
    print_separator
    
    cat << EOF
${GREEN}✅ SUCCESS${NC} - Professional peer addition completed for Dr. Kover

${WHITE}PROFESSIONAL SERVICE DETAILS:${NC}
    Peer Name:      $peer_name
    IP Address:     $client_ip
    Network:        $VPN_NETWORK.0/24
    Server:         $server_ip:$VPN_PORT
    Config File:    $(basename "$client_config_file")

${WHITE}PROFESSIONAL VALUE DELIVERED:${NC}
    ⏱️  Time Saved: 14+ minutes vs manual process
    🔒 Security: Military-grade encryption configured
    💾 Backup: Automatic configuration backup created
    📝 Logging: Complete activity log maintained
    🛠️  Support: Professional support included

${WHITE}IMMEDIATE NEXT STEPS:${NC}
    1. Download: $(basename "$client_config_file")
    2. Install WireGuard app on target device
    3. Import configuration file
    4. Connect and verify secure connection

${WHITE}PROFESSIONAL SUPPORT:${NC}
    📧 Email: thomas@eastbayav.com
    📱 Phone: (510) 666-5915
    💼 Service: Professional VPN Management
    💰 Value: \$200 automation investment paying dividends!

${WHITE}TECHNICAL FILES CREATED:${NC}
    • Server config: $SERVER_CONFIG (updated)
    • Client config: $client_config_file
    • Backup: $BACKUP_DIR/
    • Log: $LOG_FILE
EOF

    print_separator
}

show_professional_instructions() {
    local client_config_file="$1"
    
    echo -e "${CYAN}"
    echo "PROFESSIONAL DEVICE SETUP INSTRUCTIONS"
    echo "======================================="
    echo -e "${NC}"
    
    cat << EOF
${WHITE}MOBILE DEVICES (iPhone/iPad/Android):${NC}
    1. Install WireGuard from App Store/Google Play
    2. Email $(basename "$client_config_file") to device
    3. Open email attachment → Share → WireGuard
    4. Name the tunnel: "$PEER_NAME"
    5. Toggle connection ON

${WHITE}DESKTOP COMPUTERS (Windows/Mac/Linux):${NC}
    1. Download WireGuard: https://www.wireguard.com/install/
    2. Copy $(basename "$client_config_file") to computer
    3. Open WireGuard → Add Tunnel → Import from file
    4. Select the configuration file
    5. Click "Activate" to connect

${WHITE}PROFESSIONAL VERIFICATION:${NC}
    After connecting, verify professional setup:
    ✅ Visit: https://whatismyipaddress.com
    ✅ IP should display: $SERVER_IP_OVERRIDE
    ✅ Connection should show "Connected" in WireGuard
    ✅ Internet browsing should work normally but securely

${WHITE}PROFESSIONAL GUARANTEE:${NC}
    If any issues occur, contact professional support immediately:
    📧 thomas@eastbayav.com | 📱 (510) 666-5915
EOF
}

################################################################################
# Professional Main Function
################################################################################

parse_professional_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --debug)
                DEBUG=1
                debug "Professional debug mode enabled"
                shift
                ;;
            --server-ip)
                SERVER_IP_OVERRIDE="$2"
                debug "Professional server IP override: $SERVER_IP_OVERRIDE"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=1
                warning "Professional dry run mode - no changes will be made"
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            -*)
                error "Unknown professional option: $1"
                show_usage
                exit 1
                ;;
            *)
                if [[ -z "$PEER_NAME" ]]; then
                    PEER_NAME="$1"
                else
                    error "Too many arguments for professional service"
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
    
    # Parse professional arguments
    parse_professional_arguments "$@"
    
    # Professional validation
    validate_environment
    validate_peer_name "$PEER_NAME"
    
    if [[ $DRY_RUN -eq 1 ]]; then
        info "PROFESSIONAL DRY RUN - Service preview:"
        echo "  ✅ Would generate cryptographic keys for: $PEER_NAME"
        echo "  ✅ Would assign next available IP address"
        echo "  ✅ Would create automatic backup"
        echo "  ✅ Would add peer to server configuration"
        echo "  ✅ Would generate professional client config"
        echo "  ✅ Would restart WireGuard service safely"
        success "Professional dry run completed successfully"
        exit 0
    fi
    
    info "Starting professional peer addition service..."
    
    # Professional service execution
    local backup_file
    local client_config_file
    local client_ip
    local keys
    local private_key
    local public_key
    local server_public_key
    
    # Step 1: Professional backup
    info "Creating professional backup..."
    backup_file=$(create_professional_backup)
    success "Professional backup: $(basename "$backup_file")"
    
    # Step 2: Professional key generation
    info "Generating professional cryptographic keys..."
    keys=$(generate_professional_keys "$PEER_NAME")
    private_key=$(echo "$keys" | cut -d'|' -f1)
    public_key=$(echo "$keys" | cut -d'|' -f2)
    success "Professional keys generated securely"
    
    # Step 3: Professional network management
    info "Professional IP address assignment..."
    client_ip=$(get_next_available_ip)
    success "Professional IP assigned: $client_ip"
    
    # Step 4: Professional server key retrieval
    info "Retrieving professional server key..."
    server_public_key=$(get_server_public_key)
    success "Professional server key retrieved"
    
    # Step 5: Professional configuration update
    info "Updating professional server configuration..."
    if ! add_peer_to_professional_config "$PEER_NAME" "$public_key" "$client_ip"; then
        error "Professional server configuration failed"
        exit 1
    fi
    success "Professional server configuration updated"
    
    # Step 6: Professional client configuration
    info "Creating professional client configuration..."
    client_config_file=$(create_professional_client_config "$PEER_NAME" "$private_key" "$client_ip" "$server_public_key" "$SERVER_IP_OVERRIDE")
    success "Professional client config: $(basename "$client_config_file")"
    
    # Step 7: Professional service restart
    info "Restarting professional VPN service..."
    if ! restart_professional_service; then
        error "Professional service restart failed - rolling back..."
        cp "$backup_file" "$SERVER_CONFIG"
        restart_professional_service
        exit 1
    fi
    success "Professional VPN service restarted successfully"
    
    # Step 8: Professional completion report
    local end_time
    end_time=$(date +%s)
    local execution_time=$((end_time - start_time))
    
    generate_professional_report "$PEER_NAME" "$client_ip" "$client_config_file" "$SERVER_IP_OVERRIDE"
    show_professional_instructions "$client_config_file"
    
    success "Professional peer addition completed in ${execution_time} seconds"
    success "Professional service value delivered: \$200 automation investment"
    info "Professional log: $LOG_FILE"
    
    return 0
}

################################################################################
# Professional Script Execution
################################################################################

# Professional error handling
trap 'error "Professional script interrupted"; exit 130' INT
trap 'error "Professional script terminated"; exit 1' TERM

# Execute professional main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
