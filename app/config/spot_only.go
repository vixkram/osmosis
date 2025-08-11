package config

import (
	"time"

	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/osmosis-labs/osmosis/osmomath"
)

// SpotOnlyConfig defines the configuration for the spot-only fork
type SpotOnlyConfig struct {
	// Enable spot-only mode
	Enabled bool `mapstructure:"enabled"`
	// Chain identifier for the spot-only fork
	ChainID string `mapstructure:"chain_id"`
	// Human-readable name for the fork
	ChainName string `mapstructure:"chain_name"`
	// Description of the fork's purpose
	Description string `mapstructure:"description"`
	// Maximum leverage allowed (0 = spot only)
	MaxLeverage osmomath.Dec `mapstructure:"max_leverage"`
	// Disable margin trading
	DisableMarginTrading bool `mapstructure:"disable_margin_trading"`
	// Disable perpetual contracts
	DisablePerpetualContracts bool `mapstructure:"disable_perpetual_contracts"`
	// Additional safety checks
	EnforceSpotOnlyValidation bool `mapstructure:"enforce_spot_only_validation"`
}

// DefaultSpotOnlyConfig returns the default spot-only configuration
func DefaultSpotOnlyConfig() SpotOnlyConfig {
	return SpotOnlyConfig{
		Enabled:                   true,
		ChainID:                   "osmosis-spot-1",
		ChainName:                 "Osmosis Spot-Only DEX",
		Description:               "A spot-only decentralized exchange fork of Osmosis, focused on AMM trading without leveraged positions",
		MaxLeverage:               osmomath.ZeroDec(), // No leverage allowed
		DisableMarginTrading:      true,
		DisablePerpetualContracts: true,
		EnforceSpotOnlyValidation: true,
	}
}

// SpotOnlyGenesisParams returns genesis parameters optimized for spot-only trading
func SpotOnlyGenesisParams() SpotOnlyGenesisConfig {
	return SpotOnlyGenesisConfig{
		SpotOnlyMode:           true,
		DisableLeverageGenesis: true,
		MaxPositionSize:        osmomath.ZeroDec(), // No leveraged positions
		EnforceSpotLimits:      true,
		SafeguardsEnabled:      true,
	}
}

// SpotOnlyGenesisConfig defines genesis-specific configuration for spot-only mode
type SpotOnlyGenesisConfig struct {
	// Enable spot-only mode in genesis
	SpotOnlyMode bool `mapstructure:"spot_only_mode"`
	// Disable leverage-related genesis state
	DisableLeverageGenesis bool `mapstructure:"disable_leverage_genesis"`
	// Maximum position size (0 = spot only)
	MaxPositionSize osmomath.Dec `mapstructure:"max_position_size"`
	// Enforce spot trading limits
	EnforceSpotLimits bool `mapstructure:"enforce_spot_limits"`
	// Enable governance safeguards
	SafeguardsEnabled bool `mapstructure:"safeguards_enabled"`
}

// DeploymentConfig defines deployment-specific configuration
type DeploymentConfig struct {
	// Binary name for the spot-only fork
	BinaryName string `mapstructure:"binary_name"`
	// Service name for systemd/docker
	ServiceName string `mapstructure:"service_name"`
	// Network ports
	RPCPort  int `mapstructure:"rpc_port"`
	APIPort  int `mapstructure:"api_port"`
	GRPCPort int `mapstructure:"grpc_port"`
	P2PPort  int `mapstructure:"p2p_port"`
	// Hardware requirements
	MinCPUCores int `mapstructure:"min_cpu_cores"`
	MinRAMGB    int `mapstructure:"min_ram_gb"`
	MinDiskGB   int `mapstructure:"min_disk_gb"`
	// Network type
	NetworkType string `mapstructure:"network_type"`
}

// DefaultDeploymentConfig returns the default deployment configuration
func DefaultDeploymentConfig() DeploymentConfig {
	return DeploymentConfig{
		BinaryName:  "osmosisd-spot",
		ServiceName: "osmosis-spot-dex",
		RPCPort:     26657,
		APIPort:     1317,
		GRPCPort:    9090,
		P2PPort:     26656,
		MinCPUCores: 4,
		MinRAMGB:    16,
		MinDiskGB:   500,
		NetworkType: "mainnet",
	}
}

// ValidateSpotOnlyConfig validates the spot-only configuration
func (c SpotOnlyConfig) Validate() error {
	if c.Enabled {
		// Ensure leverage is disabled
		if c.MaxLeverage.GT(osmomath.ZeroDec()) {
			return ErrLeverageNotAllowedInSpotMode
		}
		
		// Ensure margin trading is disabled
		if !c.DisableMarginTrading {
			return ErrMarginTradingMustBeDisabled
		}
		
		// Ensure perpetual contracts are disabled
		if !c.DisablePerpetualContracts {
			return ErrPerpetualContractsMustBeDisabled
		}
	}
	
	return nil
}

// Validation errors
var (
	ErrLeverageNotAllowedInSpotMode        = sdk.NewError("spot-only", 1, "leverage is not allowed in spot-only mode")
	ErrMarginTradingMustBeDisabled         = sdk.NewError("spot-only", 2, "margin trading must be disabled in spot-only mode")
	ErrPerpetualContractsMustBeDisabled    = sdk.NewError("spot-only", 3, "perpetual contracts must be disabled in spot-only mode")
)