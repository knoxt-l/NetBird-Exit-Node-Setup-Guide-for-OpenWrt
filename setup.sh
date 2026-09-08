#!/bin/bash

################################################################################
# NetBird OpenWrt Exit Node Setup Script
# 
# This script automates the installation and configuration of NetBird as an
# exit node on your OpenWrt router.
#
# Usage: ./setup.sh --setup-key NBSK_XXXXXXXXXXXXXXXXXXXXXXXX
#
# Prerequisites:
#   - OpenWrt router with SSH access
#   - NetBird account and setup key
#   - Bash shell (standard on most systems)
################################################################################

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
SETUP_KEY=""
WAN_INTERFACE="wan"
VERBOSE=0

################################################################################
# Helper Functions
################################################################################

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_step() {
    echo -e "${BLUE}→ $1${NC}"
}

# Display usage
show_usage() {
    cat << EOF
Usage: $0 --setup-key NBSK_XXXXXXXXXXXXXXXXXXXXXXXX [options]

Required:
  --setup-key KEY         NetBird setup key (from dashboard)

Optional:
  --wan-interface IFACE   WAN interface name (default: wan)
  --verbose              Enable verbose output
  --help                 Show this help message

Examples:
  $0 --setup-key NBSK_abc123xyz789
  $0 --setup-key NBSK_abc123xyz789 --wan-interface pppoe-wan
  $0 --setup-key NBSK_abc123xyz789 --wan-interface eth0 --verbose

Get your setup key:
  1. Visit https://app.netbird.io/
  2. Navigate to Dashboard → Peers → Add agent
  3. Click "Create a New Setup Key"
  4. Copy the NBSK_... key

EOF
}

# Parse command line arguments
parse_arguments() {
    if [[ $# -eq 0 ]]; then
        print_error "No arguments provided"
        show_usage
        exit 1
    fi

    while [[ $# -gt 0 ]]; do
        case $1 in
            --setup-key)
                SETUP_KEY="$2"
                shift 2
                ;;
            --wan-interface)
                WAN_INTERFACE="$2"
                shift 2
                ;;
            --verbose)
                VERBOSE=1
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # Validate setup key
    if [[ -z "$SETUP_KEY" ]]; then
        print_error "Setup key is required"
        show_usage
        exit 1
    fi

    if [[ ! $SETUP_KEY =~ ^NBSK_ ]]; then
        print_error "Invalid setup key format. Must start with NBSK_"
        exit 1
    fi
}

# Check if running on OpenWrt
check_openwrt() {
    print_step "Checking if this is OpenWrt..."
    
    if [[ ! -f /etc/os-release ]]; then
        print_error "Cannot determine OS. This doesn't appear to be OpenWrt"
        exit 1
    fi

    if ! grep -q "OpenWrt\|LEDE" /etc/os-release; then
        print_warning "This doesn't appear to be OpenWrt. Proceeding anyway..."
    else
        print_success "OpenWrt detected"
    fi
}

# Check for required tools
check_requirements() {
    print_step "Checking for required tools..."
    
    local missing_tools=()
    
    for tool in uci ip sysctl /etc/init.d; do
        if [[ ! -x "$tool" && ! -d "$tool" ]]; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        exit 1
    fi
    
    print_success "All required tools found"
}

# Install NetBird
install_netbird() {
    print_header "Step 1: Installing NetBird"
    
    print_step "Updating package manager..."
    apk update || {
        print_error "Failed to update package manager"
        exit 1
    }
    print_success "Package manager updated"
    
    print_step "Installing NetBird package..."
    apk add netbird || {
        print_error "Failed to install NetBird"
        exit 1
    }
    print_success "NetBird installed"
    
    print_step "Enabling NetBird service..."
    /etc/init.d/netbird enable || {
        print_error "Failed to enable NetBird service"
        exit 1
    }
    print_success "NetBird service enabled"
    
    print_step "Starting NetBird service..."
    /etc/init.d/netbird start || {
        print_error "Failed to start NetBird service"
        exit 1
    }
    print_success "NetBird service started"
}

# Register with dashboard
register_dashboard() {
    print_header "Step 2: Registering with NetBird Dashboard"
    
    print_step "Registering router with setup key..."
    netbird up --setup-key "$SETUP_KEY" || {
        print_error "Failed to register with dashboard"
        exit 1
    }
    print_success "Router registered with NetBird dashboard"
    
    print_info "Remember to configure this router as an exit node in the dashboard:"
    print_info "1. Go to Network Routing → Routes"
    print_info "2. Toggle 'Exit node' for your router"
    print_info "3. Set Distribution group to 'All'"
}

# Configure network
configure_network() {
    print_header "Step 3: Configuring Network"
    
    print_step "Enabling IP forwarding..."
    sysctl -w net.ipv4.ip_forward=1 > /dev/null || {
        print_error "Failed to enable IP forwarding"
        exit 1
    }
    print_success "IP forwarding enabled"
    
    print_step "Creating NetBird interface in UCI..."
    uci set network.netbird='interface' || {
        print_error "Failed to create netbird interface"
        exit 1
    }
    uci set network.netbird.proto='none' || {
        print_error "Failed to set interface protocol"
        exit 1
    }
    uci set network.netbird.device='wt0' || {
        print_error "Failed to set interface device"
        exit 1
    }
    print_success "NetBird interface configured"
}

# Configure firewall
configure_firewall() {
    print_header "Step 4: Configuring Firewall"
    
    print_step "Creating NetBird firewall zone..."
    uci add firewall zone || {
        print_error "Failed to create firewall zone"
        exit 1
    }
    uci set firewall.@zone[-1].name='netbird' || {
        print_error "Failed to set zone name"
        exit 1
    }
    uci set firewall.@zone[-1].network='netbird' || {
        print_error "Failed to set zone network"
        exit 1
    }
    uci set firewall.@zone[-1].input='ACCEPT' || {
        print_error "Failed to set zone input policy"
        exit 1
    }
    uci set firewall.@zone[-1].output='ACCEPT' || {
        print_error "Failed to set zone output policy"
        exit 1
    }
    uci set firewall.@zone[-1].forward='ACCEPT' || {
        print_error "Failed to set zone forward policy"
        exit 1
    }
    print_success "Firewall zone created"
    
    print_step "Enabling masquerading..."
    uci set firewall.@zone[-1].masq='1' || {
        print_error "Failed to enable masquerading"
        exit 1
    }
    print_success "Masquerading enabled"
    
    print_step "Adding firewall forwarding rule..."
    uci add firewall forwarding || {
        print_error "Failed to add forwarding rule"
        exit 1
    }
    uci set firewall.@forwarding[-1].src='netbird' || {
        print_error "Failed to set forwarding source"
        exit 1
    }
    uci set firewall.@forwarding[-1].dest="$WAN_INTERFACE" || {
        print_error "Failed to set forwarding destination"
        exit 1
    }
    print_success "Firewall forwarding rule added (→ $WAN_INTERFACE)"
}

# Apply configuration
apply_configuration() {
    print_header "Step 5: Applying Configuration"
    
    print_step "Committing network configuration..."
    uci commit network || {
        print_error "Failed to commit network configuration"
        exit 1
    }
    print_success "Network configuration committed"
    
    print_step "Committing firewall configuration..."
    uci commit firewall || {
        print_error "Failed to commit firewall configuration"
        exit 1
    }
    print_success "Firewall configuration committed"
    
    print_step "Reloading network..."
    /etc/init.d/network reload || {
        print_error "Failed to reload network"
        exit 1
    }
    print_success "Network reloaded"
    
    print_step "Reloading firewall..."
    /etc/init.d/firewall reload || {
        print_error "Failed to reload firewall"
        exit 1
    }
    print_success "Firewall reloaded"
}

# Restart NetBird
restart_netbird() {
    print_header "Step 6: Finalizing"
    
    print_step "Restarting NetBird service..."
    /etc/init.d/netbird restart || {
        print_error "Failed to restart NetBird"
        exit 1
    }
    
    print_step "Waiting for NetBird to initialize (10 seconds)..."
    sleep 10
    print_success "NetBird restarted"
}

# Verify configuration
verify_configuration() {
    print_header "Verification Results"
    
    local errors=0
    
    # Check NetBird status
    print_step "Checking NetBird status..."
    if netbird status > /dev/null 2>&1; then
        print_success "NetBird is running"
    else
        print_error "NetBird is not running"
        errors=$((errors + 1))
    fi
    
    # Check wt0 interface
    print_step "Checking wt0 interface..."
    if ip addr show wt0 > /dev/null 2>&1; then
        local netbird_ip=$(ip addr show wt0 | grep -oP '(?<=inet\s)\d+\.\d+\.\d+\.\d+')
        print_success "NetBird interface configured: $netbird_ip/16"
    else
        print_error "NetBird interface (wt0) not found"
        errors=$((errors + 1))
    fi
    
    # Check routing
    print_step "Checking routes..."
    if ip route | grep -q "100."; then
        print_success "NetBird routes configured"
    else
        print_error "NetBird routes not found"
        errors=$((errors + 1))
    fi
    
    # Check IP forwarding
    print_step "Checking IP forwarding..."
    local ip_forward=$(sysctl -n net.ipv4.ip_forward)
    if [[ "$ip_forward" == "1" ]]; then
        print_success "IP forwarding enabled"
    else
        print_error "IP forwarding not enabled"
        errors=$((errors + 1))
    fi
    
    # Check firewall configuration
    print_step "Checking firewall configuration..."
    if uci show firewall | grep -q "name='netbird'"; then
        print_success "Firewall zone configured"
    else
        print_error "Firewall zone not configured"
        errors=$((errors + 1))
    fi
    
    return $errors
}

# Display summary
show_summary() {
    local errors=$1
    
    echo ""
    print_header "Setup Summary"
    
    if [[ $errors -eq 0 ]]; then
        print_success "NetBird exit node setup completed successfully!"
        echo ""
        echo "Next steps:"
        echo "  1. Visit https://app.netbird.io/"
        echo "  2. Go to Network Routing → Routes"
        echo "  3. Toggle 'Exit node' for your router"
        echo "  4. Set Distribution group to 'All'"
        echo ""
        echo "Testing:"
        echo "  • From another NetBird peer, run: ping 100.x.x.x"
        echo "  • Check status anytime with: netbird status"
        echo ""
        print_success "Your exit node is ready!"
    else
        print_error "Setup completed with $errors warning(s)"
        echo ""
        echo "Please check the errors above and run troubleshooting commands:"
        echo "  • netbird status -d (detailed diagnostics)"
        echo "  • logread | grep netbird (check logs)"
        echo "  • uci show firewall (check firewall config)"
    fi
    
    echo ""
    echo "For more information, see: README.md"
}

# Cleanup on error
cleanup_on_error() {
    print_error "Setup interrupted"
    echo ""
    print_info "To rollback, run:"
    echo "  # This will require manual configuration review"
    exit 1
}

trap cleanup_on_error SIGINT SIGTERM

################################################################################
# Main Execution
################################################################################

main() {
    clear
    print_header "NetBird OpenWrt Exit Node Setup"
    echo ""
    
    # Parse arguments
    parse_arguments "$@"
    
    # Pre-flight checks
    check_openwrt
    check_requirements
    
    echo ""
    print_info "Setup Key: $SETUP_KEY (first 8 chars)"
    print_info "WAN Interface: $WAN_INTERFACE"
    echo ""
    
    # Run installation steps
    install_netbird
    register_dashboard
    configure_network
    configure_firewall
    apply_configuration
    restart_netbird
    
    # Verify
    echo ""
    verify_configuration
    local result=$?
    
    # Summary
    echo ""
    show_summary $result
    
    exit $result
}

# Run main function
main "$@"
