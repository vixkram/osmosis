package types

import (
	"fmt"
	"strings"

	sdk "github.com/cosmos/cosmos-sdk/types"
	govtypes "github.com/cosmos/cosmos-sdk/x/gov/types"
	govtypesv1 "github.com/cosmos/cosmos-sdk/x/gov/types/v1"
)

// LeverageRestrictedProposalTypes defines proposal types that are restricted
// to prevent leveraged trading functionality
var LeverageRestrictedProposalTypes = []string{
	"perpetual",
	"margin",
	"leverage",
	"futures",
	"derivatives",
	"perp",
	"leveraged",
	"borrow",
	"lending",
	"collateral",
}

// LeverageRestrictedModules defines module names that are restricted
// to prevent leveraged trading functionality
var LeverageRestrictedModules = []string{
	"perpetuals",
	"margins",
	"leverage",
	"futures",
	"derivatives",
	"lending",
	"borrowing",
}

// Config holds the configuration for governance safeguards
type Config struct {
	// DisableLeverageModules prevents installation of leverage-related modules
	DisableLeverageModules bool `json:"disable_leverage_modules"`
	// RestrictedProposalTypes contains proposal types that should be rejected
	RestrictedProposalTypes []string `json:"restricted_proposal_types"`
	// RestrictedModules contains module names that should be rejected
	RestrictedModules []string `json:"restricted_modules"`
}

// DefaultConfig returns the default configuration for governance safeguards
func DefaultConfig() Config {
	return Config{
		DisableLeverageModules:  true,
		RestrictedProposalTypes: LeverageRestrictedProposalTypes,
		RestrictedModules:       LeverageRestrictedModules,
	}
}

// ValidateProposal validates a governance proposal against leverage restrictions
func (c Config) ValidateProposal(proposal govtypesv1.Proposal) error {
	if !c.DisableLeverageModules {
		return nil
	}

	// Check proposal title and description for restricted keywords
	title := strings.ToLower(proposal.Title)
	description := strings.ToLower(proposal.Summary)

	for _, restrictedType := range c.RestrictedProposalTypes {
		if strings.Contains(title, restrictedType) || strings.Contains(description, restrictedType) {
			return fmt.Errorf("proposal contains restricted leverage-related content: %s", restrictedType)
		}
	}

	// Check for software upgrade proposals that might install leverage modules
	for _, msg := range proposal.Messages {
		if err := c.validateMessage(msg); err != nil {
			return err
		}
	}

	return nil
}

// validateMessage validates individual proposal messages
func (c Config) validateMessage(msg *govtypes.Any) error {
	// Check for software upgrade proposals
	if strings.Contains(msg.TypeUrl, "upgrade") {
		// Additional validation for upgrade proposals could be added here
		// For now, we'll check the message content for restricted keywords
		msgStr := strings.ToLower(string(msg.Value))
		for _, restrictedModule := range c.RestrictedModules {
			if strings.Contains(msgStr, restrictedModule) {
				return fmt.Errorf("upgrade proposal contains restricted module: %s", restrictedModule)
			}
		}
	}

	// Check for parameter change proposals
	if strings.Contains(msg.TypeUrl, "params") {
		msgStr := strings.ToLower(string(msg.Value))
		for _, restrictedType := range c.RestrictedProposalTypes {
			if strings.Contains(msgStr, restrictedType) {
				return fmt.Errorf("parameter change proposal contains restricted content: %s", restrictedType)
			}
		}
	}

	return nil
}

// IsLeverageRelated checks if a string contains leverage-related keywords
func IsLeverageRelated(content string) bool {
	content = strings.ToLower(content)
	for _, keyword := range LeverageRestrictedProposalTypes {
		if strings.Contains(content, keyword) {
			return true
		}
	}
	return false
}