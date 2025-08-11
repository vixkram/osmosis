package config

import (
	"github.com/osmosis-labs/osmosis/v30/x/governance-safeguards/types"
)

// GovernanceSafeguardsConfig defines the configuration for governance safeguards
type GovernanceSafeguardsConfig struct {
	// Enable governance safeguards
	Enabled bool `mapstructure:"enabled"`
	// Disable leverage modules installation
	DisableLeverageModules bool `mapstructure:"disable_leverage_modules"`
	// Additional restricted proposal types
	AdditionalRestrictedTypes []string `mapstructure:"additional_restricted_types"`
	// Additional restricted modules
	AdditionalRestrictedModules []string `mapstructure:"additional_restricted_modules"`
}

// DefaultGovernanceSafeguardsConfig returns the default configuration
func DefaultGovernanceSafeguardsConfig() GovernanceSafeguardsConfig {
	return GovernanceSafeguardsConfig{
		Enabled:                     true,
		DisableLeverageModules:      true,
		AdditionalRestrictedTypes:   []string{},
		AdditionalRestrictedModules: []string{},
	}
}

// ToSafeguardsConfig converts the app config to the safeguards types config
func (c GovernanceSafeguardsConfig) ToSafeguardsConfig() types.Config {
	config := types.DefaultConfig()
	
	if !c.Enabled {
		config.DisableLeverageModules = false
		return config
	}
	
	config.DisableLeverageModules = c.DisableLeverageModules
	
	// Add additional restricted types
	config.RestrictedProposalTypes = append(config.RestrictedProposalTypes, c.AdditionalRestrictedTypes...)
	
	// Add additional restricted modules
	config.RestrictedModules = append(config.RestrictedModules, c.AdditionalRestrictedModules...)
	
	return config
}