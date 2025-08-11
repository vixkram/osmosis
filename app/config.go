package app

import (
	"github.com/osmosis-labs/osmosis/v30/app/config"
)

// Config defines the application configuration
type Config struct {
	// GovernanceSafeguards configuration
	GovernanceSafeguards config.GovernanceSafeguardsConfig `mapstructure:"governance-safeguards"`
	// SpotOnly configuration for the spot-only fork
	SpotOnly config.SpotOnlyConfig `mapstructure:"spot-only"`
	// Deployment configuration
	Deployment config.DeploymentConfig `mapstructure:"deployment"`
}

// DefaultConfig returns the default application configuration
func DefaultConfig() Config {
	return Config{
		GovernanceSafeguards: config.DefaultGovernanceSafeguardsConfig(),
		SpotOnly:             config.DefaultSpotOnlyConfig(),
		Deployment:           config.DefaultDeploymentConfig(),
	}
}