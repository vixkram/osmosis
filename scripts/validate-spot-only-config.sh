#!/bin/bash

# Osmosis Spot-Only Fork Configuration Validation Script
# This script validates that the deployment is properly configured for spot-only trading

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration paths
OSMOSISD_HOME="${OSMOSISD_HOME:-$HOME/.osmosisd}"
CONFIG_DIR="$OSMOSISD_HOME/config"
APP_CONFIG="$CONFIG_DIR/app.toml"
NODE_CONFIG="$CONFIG_DIR/config.toml"
GENESIS_FILE="$CONFIG_DIR/genesis.json"
SPOT_ONLY_CONFIG="config/spot-only-fork.toml"

echo "🔍 Validating Osmosis Spot-Only Fork Configuration..."
echo "=================================================="

# Function to print status
print_status() {
    local status=$1
    local message=$2
    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}✅ PASS${NC}: $message"
    elif [ "$status" = "FAIL" ]; then
        echo -e "${RED}❌ FAIL${NC}: $message"
        exit 1
    elif [ "$status" = "WARN" ]; then
        echo -e "${YELLOW}⚠️  WARN${NC}: $message"
    else
        echo -e "ℹ️  INFO: $message"
    fi
}

# Check if osmosisd binary exists
check_binary() {
    echo "Checking binary..."
    if command -v osmosisd &> /dev/null; then
        print_status "PASS" "osmosisd binary found"
        
        # Check version info
        VERSION=$(osmosisd version 2>/dev/null || echo "unknown")
        echo "  Version: $VERSION"
    else
        print_status "FAIL" "osmosisd binary not found in PATH"
    fi
}

# Check configuration files
check_config_files() {
    echo -e "\nChecking configuration files..."
    
    if [ -f "$APP_CONFIG" ]; then
        print_status "PASS" "app.toml found"
    else
        print_status "FAIL" "app.toml not found at $APP_CONFIG"
    fi
    
    if [ -f "$NODE_CONFIG" ]; then
        print_status "PASS" "config.toml found"
    else
        print_status "FAIL" "config.toml not found at $NODE_CONFIG"
    fi
    
    if [ -f "$GENESIS_FILE" ]; then
        print_status "PASS" "genesis.json found"
    else
        print_status "WARN" "genesis.json not found (may need to be downloaded)"
    fi
    
    if [ -f "$SPOT_ONLY_CONFIG" ]; then
        print_status "PASS" "spot-only-fork.toml found"
    else
        print_status "WARN" "spot-only-fork.toml not found (using defaults)"
    fi
}

# Check governance safeguards configuration
check_governance_safeguards() {
    echo -e "\nChecking governance safeguards..."
    
    if [ -f "$APP_CONFIG" ]; then
        # Check if governance safeguards are enabled
        if grep -q "^\[governance-safeguards\]" "$APP_CONFIG"; then
            print_status "PASS" "governance-safeguards section found"
            
            # Check if enabled
            if grep -A 10 "^\[governance-safeguards\]" "$APP_CONFIG" | grep -q "enabled.*=.*true"; then
                print_status "PASS" "governance safeguards enabled"
            else
                print_status "FAIL" "governance safeguards not enabled"
            fi
            
            # Check if leverage modules are disabled
            if grep -A 10 "^\[governance-safeguards\]" "$APP_CONFIG" | grep -q "disable_leverage_modules.*=.*true"; then
                print_status "PASS" "leverage modules disabled"
            else
                print_status "FAIL" "leverage modules not disabled"
            fi
        else
            print_status "FAIL" "governance-safeguards section not found in app.toml"
        fi
    fi
}

# Check spot-only configuration
check_spot_only_config() {
    echo -e "\nChecking spot-only configuration..."
    
    if [ -f "$APP_CONFIG" ]; then
        # Check if spot-only section exists
        if grep -q "^\[spot-only\]" "$APP_CONFIG"; then
            print_status "PASS" "spot-only section found"
            
            # Check if enabled
            if grep -A 10 "^\[spot-only\]" "$APP_CONFIG" | grep -q "enabled.*=.*true"; then
                print_status "PASS" "spot-only mode enabled"
            else
                print_status "FAIL" "spot-only mode not enabled"
            fi
            
            # Check max leverage
            if grep -A 10 "^\[spot-only\]" "$APP_CONFIG" | grep -q "max_leverage.*=.*[\"']0[\"']"; then
                print_status "PASS" "max leverage set to 0"
            else
                print_status "FAIL" "max leverage not set to 0"
            fi
            
            # Check margin trading disabled
            if grep -A 10 "^\[spot-only\]" "$APP_CONFIG" | grep -q "disable_margin_trading.*=.*true"; then
                print_status "PASS" "margin trading disabled"
            else
                print_status "FAIL" "margin trading not disabled"
            fi
            
            # Check perpetual contracts disabled
            if grep -A 10 "^\[spot-only\]" "$APP_CONFIG" | grep -q "disable_perpetual_contracts.*=.*true"; then
                print_status "PASS" "perpetual contracts disabled"
            else
                print_status "FAIL" "perpetual contracts not disabled"
            fi
        else
            print_status "WARN" "spot-only section not found (using defaults)"
        fi
    fi
}

# Check network configuration
check_network_config() {
    echo -e "\nChecking network configuration..."
    
    if [ -f "$NODE_CONFIG" ]; then
        # Check chain ID
        if grep -q "osmosis-spot" "$NODE_CONFIG"; then
            print_status "PASS" "spot-only chain ID detected"
        else
            print_status "WARN" "chain ID may not be set for spot-only fork"
        fi
        
        # Check P2P port
        P2P_PORT=$(grep "laddr.*26656" "$NODE_CONFIG" | head -1 | sed 's/.*:\([0-9]*\)".*/\1/')
        if [ "$P2P_PORT" = "26656" ]; then
            print_status "PASS" "P2P port configured (26656)"
        else
            print_status "WARN" "P2P port may be non-standard: $P2P_PORT"
        fi
        
        # Check RPC port
        RPC_PORT=$(grep "laddr.*26657" "$NODE_CONFIG" | head -1 | sed 's/.*:\([0-9]*\)".*/\1/')
        if [ "$RPC_PORT" = "26657" ]; then
            print_status "PASS" "RPC port configured (26657)"
        else
            print_status "WARN" "RPC port may be non-standard: $RPC_PORT"
        fi
    fi
}

# Check API configuration
check_api_config() {
    echo -e "\nChecking API configuration..."
    
    if [ -f "$APP_CONFIG" ]; then
        # Check if API is enabled
        if grep -A 5 "^\[api\]" "$APP_CONFIG" | grep -q "enable.*=.*true"; then
            print_status "PASS" "API enabled"
            
            # Check API port
            API_PORT=$(grep -A 10 "^\[api\]" "$APP_CONFIG" | grep "address" | sed 's/.*:\([0-9]*\)".*/\1/')
            if [ "$API_PORT" = "1317" ]; then
                print_status "PASS" "API port configured (1317)"
            else
                print_status "WARN" "API port may be non-standard: $API_PORT"
            fi
        else
            print_status "WARN" "API not enabled"
        fi
        
        # Check if gRPC is enabled
        if grep -A 5 "^\[grpc\]" "$APP_CONFIG" | grep -q "enable.*=.*true"; then
            print_status "PASS" "gRPC enabled"
            
            # Check gRPC port
            GRPC_PORT=$(grep -A 10 "^\[grpc\]" "$APP_CONFIG" | grep "address" | sed 's/.*:\([0-9]*\)".*/\1/')
            if [ "$GRPC_PORT" = "9090" ]; then
                print_status "PASS" "gRPC port configured (9090)"
            else
                print_status "WARN" "gRPC port may be non-standard: $GRPC_PORT"
            fi
        else
            print_status "WARN" "gRPC not enabled"
        fi
    fi
}

# Check for leverage-related modules (should not exist)
check_leverage_modules() {
    echo -e "\nChecking for leverage-related modules..."
    
    # Check binary for leverage-related commands
    LEVERAGE_COMMANDS=$(osmosisd --help 2>/dev/null | grep -i -E "(perpetual|margin|leverage|futures|derivatives)" || true)
    if [ -z "$LEVERAGE_COMMANDS" ]; then
        print_status "PASS" "No leverage-related commands found in binary"
    else
        print_status "FAIL" "Leverage-related commands found: $LEVERAGE_COMMANDS"
    fi
    
    # Check for leverage-related modules in genesis
    if [ -f "$GENESIS_FILE" ]; then
        LEVERAGE_MODULES=$(jq -r '.app_state | keys[]' "$GENESIS_FILE" 2>/dev/null | grep -i -E "(perpetual|margin|leverage|futures|derivatives)" || true)
        if [ -z "$LEVERAGE_MODULES" ]; then
            print_status "PASS" "No leverage-related modules found in genesis"
        else
            print_status "FAIL" "Leverage-related modules found in genesis: $LEVERAGE_MODULES"
        fi
    fi
}

# Check system resources
check_system_resources() {
    echo -e "\nChecking system resources..."
    
    # Check CPU cores
    CPU_CORES=$(nproc)
    if [ "$CPU_CORES" -ge 4 ]; then
        print_status "PASS" "CPU cores: $CPU_CORES (minimum 4)"
    else
        print_status "WARN" "CPU cores: $CPU_CORES (recommended minimum: 4)"
    fi
    
    # Check RAM
    RAM_GB=$(free -g | awk '/^Mem:/{print $2}')
    if [ "$RAM_GB" -ge 16 ]; then
        print_status "PASS" "RAM: ${RAM_GB}GB (minimum 16GB)"
    else
        print_status "WARN" "RAM: ${RAM_GB}GB (recommended minimum: 16GB)"
    fi
    
    # Check disk space
    DISK_GB=$(df -BG "$OSMOSISD_HOME" | awk 'NR==2{print $4}' | sed 's/G//')
    if [ "$DISK_GB" -ge 500 ]; then
        print_status "PASS" "Available disk space: ${DISK_GB}GB (minimum 500GB)"
    else
        print_status "WARN" "Available disk space: ${DISK_GB}GB (recommended minimum: 500GB)"
    fi
}

# Test node functionality (if running)
test_node_functionality() {
    echo -e "\nTesting node functionality..."
    
    # Check if node is running
    if pgrep -f "osmosisd.*start" > /dev/null; then
        print_status "PASS" "Node process is running"
        
        # Test RPC endpoint
        if curl -s http://localhost:26657/status > /dev/null 2>&1; then
            print_status "PASS" "RPC endpoint responding"
            
            # Get node info
            NODE_INFO=$(curl -s http://localhost:26657/status | jq -r '.result.node_info.network' 2>/dev/null || echo "unknown")
            echo "  Network: $NODE_INFO"
        else
            print_status "WARN" "RPC endpoint not responding (node may be starting)"
        fi
        
        # Test API endpoint
        if curl -s http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info > /dev/null 2>&1; then
            print_status "PASS" "API endpoint responding"
        else
            print_status "WARN" "API endpoint not responding"
        fi
    else
        print_status "INFO" "Node is not currently running"
    fi
}

# Main validation function
main() {
    check_binary
    check_config_files
    check_governance_safeguards
    check_spot_only_config
    check_network_config
    check_api_config
    check_leverage_modules
    check_system_resources
    test_node_functionality
    
    echo -e "\n🎉 Configuration validation completed!"
    echo "=================================================="
    echo "If all checks passed, your Osmosis Spot-Only Fork is properly configured."
    echo "If there were any failures, please address them before starting the node."
    echo ""
    echo "To start the node:"
    echo "  osmosisd start"
    echo ""
    echo "To check node status:"
    echo "  osmosisd status"
    echo ""
    echo "To view logs:"
    echo "  tail -f ~/.osmosisd/logs/osmosisd.log"
}

# Run main function
main "$@"