package types

import (
	"testing"

	govtypesv1 "github.com/cosmos/cosmos-sdk/x/gov/types/v1"
	"github.com/stretchr/testify/require"
)

func TestDefaultConfig(t *testing.T) {
	config := DefaultConfig()
	
	require.True(t, config.DisableLeverageModules)
	require.NotEmpty(t, config.RestrictedProposalTypes)
	require.NotEmpty(t, config.RestrictedModules)
	require.Contains(t, config.RestrictedProposalTypes, "perpetual")
	require.Contains(t, config.RestrictedProposalTypes, "margin")
	require.Contains(t, config.RestrictedProposalTypes, "leverage")
}

func TestValidateProposal_AllowedProposal(t *testing.T) {
	config := DefaultConfig()
	
	proposal := govtypesv1.Proposal{
		Id:      1,
		Title:   "Update Pool Parameters",
		Summary: "This proposal updates the pool parameters for better efficiency",
	}
	
	err := config.ValidateProposal(proposal)
	require.NoError(t, err)
}

func TestValidateProposal_RestrictedTitle(t *testing.T) {
	config := DefaultConfig()
	
	proposal := govtypesv1.Proposal{
		Id:      1,
		Title:   "Enable Perpetual Trading",
		Summary: "This proposal enables perpetual trading functionality",
	}
	
	err := config.ValidateProposal(proposal)
	require.Error(t, err)
	require.Contains(t, err.Error(), "perpetual")
}

func TestValidateProposal_RestrictedDescription(t *testing.T) {
	config := DefaultConfig()
	
	proposal := govtypesv1.Proposal{
		Id:      1,
		Title:   "Update Trading Features",
		Summary: "This proposal adds margin trading capabilities to the DEX",
	}
	
	err := config.ValidateProposal(proposal)
	require.Error(t, err)
	require.Contains(t, err.Error(), "margin")
}

func TestValidateProposal_DisabledSafeguards(t *testing.T) {
	config := Config{
		DisableLeverageModules:  false,
		RestrictedProposalTypes: LeverageRestrictedProposalTypes,
		RestrictedModules:       LeverageRestrictedModules,
	}
	
	proposal := govtypesv1.Proposal{
		Id:      1,
		Title:   "Enable Perpetual Trading",
		Summary: "This proposal enables perpetual trading functionality",
	}
	
	err := config.ValidateProposal(proposal)
	require.NoError(t, err)
}

func TestIsLeverageRelated(t *testing.T) {
	testCases := []struct {
		content  string
		expected bool
	}{
		{"Enable perpetual trading", true},
		{"Add margin functionality", true},
		{"Update leverage settings", true},
		{"Enable futures trading", true},
		{"Add derivatives support", true},
		{"Update pool parameters", false},
		{"Enable spot trading", false},
		{"Add liquidity incentives", false},
	}
	
	for _, tc := range testCases {
		t.Run(tc.content, func(t *testing.T) {
			result := IsLeverageRelated(tc.content)
			require.Equal(t, tc.expected, result)
		})
	}
}

func TestValidateProposal_CaseInsensitive(t *testing.T) {
	config := DefaultConfig()
	
	testCases := []string{
		"Enable PERPETUAL trading",
		"Add Margin functionality",
		"Update LEVERAGE settings",
		"Enable Futures Trading",
	}
	
	for _, title := range testCases {
		t.Run(title, func(t *testing.T) {
			proposal := govtypesv1.Proposal{
				Id:      1,
				Title:   title,
				Summary: "Test proposal",
			}
			
			err := config.ValidateProposal(proposal)
			require.Error(t, err)
		})
	}
}