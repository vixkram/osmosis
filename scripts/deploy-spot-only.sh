#!/bin/bash

# Osmosis Spot-Only Fork Deployment Script
# This script automates the deployment of the Osmosis Spot-Only Fork

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default configuration
CHAIN_ID="${CHAIN_ID:-osmosis-spot-1}"
MONIKER="${MONIKER:-osmosis-spot-node}"
NETWORK_TYPE="${NETWORK_TYPE:-mainnet}"
OSMOSISD_HOME="${OSMOSISD_HOME:-$HOME/.osmosisd}"
BINARY_NAME="${BINARY_NAME:-osmosisd}"

# Function to print colored output
print_step() {
    echo -e "${BLUE}🔧 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

# Function to check prerequisites
check_prerequisites() {
    print_step "Checking prerequisites..."
    
    # Check if Go is installed
    if ! command -v go &> /dev/null; then
        print_error "Go is not installed. Please install Go 1.23 or higher."
    fi
    
    # Check Go version
    GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
    GO_MAJOR=$(echo $GO_VERSION | cut -d. -f1)
    GO_MINOR=$(echo $GO_VERSION | cut -d. -f2)
    
    if [ "$GO_MAJOR" -lt 1 ] || ([ "$GO_MAJOR" -eq 1 ] && [ "$GO_MINOR" -lt 23 ]); then
        print_error "Go version $GO_VERSION is too old. Please install Go 1.23 or higher."
    fi
    
    print_success "Go version $GO_VERSION is compatible"
    
    # Check if Git is installed
    if ! command -v git &> /dev/null; then
        print_error "Git is not installed. Please install Git."
    fi
    
    print_success "Prerequisites check completed"
}

# Function to build the binary
build_binary() {
    print_step "Building Osmosis Spot-Only binary..."
    
    # Clean previous builds
    make clean 2>/dev/null || true
    
    # Build the binary
    make build
    
    # Install the binary
    make install
    
    # Verify installation
    if command -v $BINARY_NAME &> /dev/null; then
        VERSION=$($BINARY_NAME version 2>/dev/null || echo "unknown")
        print_success "Binary built and installed successfully (version: $VERSION)"
    else
        print_error "Binary installation failed"
    fi
}

# Function to initialize the node
initialize_node() {
    print_step "Initializing node..."
    
    # Remove existing configuration if it exists
    if [ -d "$OSMOSISD_HOME" ]; then
        print_warning "Existing configuration found at $OSMOSISD_HOME"
        read -p "Do you want to remove it and start fresh? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$OSMOSISD_HOME"
            print_success "Existing configuration removed"
        else
            print_warning "Using existing configuration"
            return
        fi
    fi
    
    # Initialize the node
    $BINARY_NAME init "$MONIKER" --chain-id "$CHAIN_ID" --home "$OSMOSISD_HOME"
    
    print_success "Node initialized with chain-id: $CHAIN_ID, moniker: $MONIKER"
}

# Function to configure the node
configure_node() {
    print_step "Configuring node for spot-only mode..."
    
    local CONFIG_DIR="$OSMOSISD_HOME/config"
    local APP_CONFIG="$CONFIG_DIR/app.toml"
    local NODE_CONFIG="$CONFIG_DIR/config.toml"
    
    # Backup original configs
    cp "$APP_CONFIG" "$APP_CONFIG.backup"
    cp "$NODE_CONFIG" "$NODE_CONFIG.backup"
    
    # Configure app.toml for spot-only mode
    cat >> "$APP_CONFIG" << EOF

###############################################################################
###                        Spot-Only Configuration                         ###
###############################################################################

[spot-only]
enabled = true
chain_id = "$CHAIN_ID"
chain_name = "Osmosis Spot-Only DEX"
description = "A spot-only decentralized exchange fork of Osmosis"
max_leverage = "0"
disable_margin_trading = true
disable_perpetual_contracts = true
enforce_spot_only_validation = true

[governance-safeguards]
enabled = true
disable_leverage_modules = true
additional_restricted_types = ["perpetuals", "margin", "leverage", "futures", "derivatives"]
additional_restricted_modules = ["x/perpetuals", "x/margin", "x/leverage", "x/futures", "x/derivatives"]

[deployment]
binary_name = "$BINARY_NAME"
service_name = "osmosis-spot-dex"
network_type = "$NETWORK_TYPE"
EOF
    
    # Configure API and gRPC
    sed -i.bak 's/enable = false/enable = true/g' "$APP_CONFIG"
    
    print_success "Node configured for spot-only mode"
}

# Function to setup genesis
setup_genesis() {
    print_step "Setting up genesis..."
    
    local GENESIS_FILE="$OSMOSISD_HOME/config/genesis.json"
    
    if [ "$NETWORK_TYPE" = "testnet" ]; then
        print_step "Preparing testnet genesis..."
        $BINARY_NAME prepare-genesis testnet "$CHAIN_ID" --home "$OSMOSISD_HOME"
    elif [ "$NETWORK_TYPE" = "mainnet" ]; then
        print_step "Preparing mainnet genesis..."
        $BINARY_NAME prepare-genesis mainnet "$CHAIN_ID" --home "$OSMOSISD_HOME"
    else
        print_warning "Custom network type. You may need to provide your own genesis file."
    fi
    
    # Validate genesis
    if [ -f "$GENESIS_FILE" ]; then
        $BINARY_NAME validate-genesis --home "$OSMOSISD_HOME"
        print_success "Genesis file validated"
    else
        print_warning "Genesis file not found. You may need to download it manually."
    fi
}

# Function to create systemd service
create_systemd_service() {
    print_step "Creating systemd service..."
    
    if [ "$EUID" -ne 0 ]; then
        print_warning "Not running as root. Skipping systemd service creation."
        print_warning "To create the service manually, run this script with sudo or copy deployment/systemd/osmosis-spot.service to /etc/systemd/system/"
        return
    fi
    
    # Create osmosis user if it doesn't exist
    if ! id "osmosis" &>/dev/null; then
        useradd -r -s /bin/false osmosis
        print_success "Created osmosis user"
    fi
    
    # Set ownership
    chown -R osmosis:osmosis "$OSMOSISD_HOME"
    
    # Copy service file
    cp deployment/systemd/osmosis-spot.service /etc/systemd/system/
    
    # Update service file with correct paths
    sed -i "s|/home/osmosis/.osmosisd|$OSMOSISD_HOME|g" /etc/systemd/system/osmosis-spot.service
    sed -i "s|/usr/local/bin/osmosisd|$(which $BINARY_NAME)|g" /etc/systemd/system/osmosis-spot.service
    
    # Reload systemd
    systemctl daemon-reload
    
    # Enable service
    systemctl enable osmosis-spot
    
    print_success "Systemd service created and enabled"
}

# Function to run validation
run_validation() {
    print_step "Running configuration validation..."
    
    if [ -f "scripts/validate-spot-only-config.sh" ]; then
        bash scripts/validate-spot-only-config.sh
    else
        print_warning "Validation script not found. Skipping validation."
    fi
}

# Function to display next steps
display_next_steps() {
    echo
    echo "🎉 Deployment completed successfully!"
    echo "=================================="
    echo
    echo "Next steps:"
    echo "1. Review the configuration files in $OSMOSISD_HOME/config/"
    echo "2. Add peers to config.toml if needed"
    echo "3. Download genesis file if not already present"
    echo "4. Start the node:"
    echo "   - Manual: $BINARY_NAME start --home $OSMOSISD_HOME"
    echo "   - Systemd: sudo systemctl start osmosis-spot"
    echo
    echo "Useful commands:"
    echo "- Check status: $BINARY_NAME status --home $OSMOSISD_HOME"
    echo "- View logs: tail -f $OSMOSISD_HOME/logs/osmosisd.log"
    echo "- Systemd logs: sudo journalctl -u osmosis-spot -f"
    echo
    echo "Configuration files:"
    echo "- Node config: $OSMOSISD_HOME/config/config.toml"
    echo "- App config: $OSMOSISD_HOME/config/app.toml"
    echo "- Genesis: $OSMOSISD_HOME/config/genesis.json"
    echo
    echo "For more information, see DEPLOYMENT_GUIDE.md"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -c, --chain-id CHAIN_ID     Set chain ID (default: osmosis-spot-1)"
    echo "  -m, --moniker MONIKER       Set node moniker (default: osmosis-spot-node)"
    echo "  -n, --network TYPE          Set network type: mainnet|testnet (default: mainnet)"
    echo "  -h, --home HOME_DIR         Set home directory (default: ~/.osmosisd)"
    echo "  -b, --binary BINARY_NAME    Set binary name (default: osmosisd)"
    echo "  --skip-build                Skip building the binary"
    echo "  --skip-systemd              Skip creating systemd service"
    echo "  --help                      Show this help message"
    echo
    echo "Examples:"
    echo "  $0                                    # Deploy with defaults"
    echo "  $0 -c osmosis-spot-testnet-1 -n testnet  # Deploy testnet"
    echo "  $0 -m my-node --skip-systemd         # Deploy without systemd service"
}

# Parse command line arguments
SKIP_BUILD=false
SKIP_SYSTEMD=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--chain-id)
            CHAIN_ID="$2"
            shift 2
            ;;
        -m|--moniker)
            MONIKER="$2"
            shift 2
            ;;
        -n|--network)
            NETWORK_TYPE="$2"
            shift 2
            ;;
        -h|--home)
            OSMOSISD_HOME="$2"
            shift 2
            ;;
        -b|--binary)
            BINARY_NAME="$2"
            shift 2
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --skip-systemd)
            SKIP_SYSTEMD=true
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main deployment function
main() {
    echo "🚀 Osmosis Spot-Only Fork Deployment"
    echo "===================================="
    echo "Chain ID: $CHAIN_ID"
    echo "Moniker: $MONIKER"
    echo "Network: $NETWORK_TYPE"
    echo "Home: $OSMOSISD_HOME"
    echo "Binary: $BINARY_NAME"
    echo
    
    check_prerequisites
    
    if [ "$SKIP_BUILD" = false ]; then
        build_binary
    else
        print_warning "Skipping binary build"
    fi
    
    initialize_node
    configure_node
    setup_genesis
    
    if [ "$SKIP_SYSTEMD" = false ]; then
        create_systemd_service
    else
        print_warning "Skipping systemd service creation"
    fi
    
    run_validation
    display_next_steps
}

# Run main function
main "$@"