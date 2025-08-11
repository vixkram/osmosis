package governance_safeguards

import (
	"testing"

	"cosmossdk.io/log"
	storetypes "cosmossdk.io/store/types"
	"github.com/cosmos/cosmos-sdk/codec"
	"github.com/cosmos/cosmos-sdk/codec/types"
	sdk "github.com/cosmos/cosmos-sdk/types"
	govtypesv1 "github.com/cosmos/cosmos-sdk/x/gov/types/v1"
	"github.com/stretchr/testify/require"

	"github.com/osmosis-labs/osmosis/v30/x/governance-safeguards/keeper"
	safeguardstypes "github.com/osmosis-labs/osmosis/v30/x/governance-safeguards/types"
)

func TestGovernanceSafeguardDecorator_AllowedProposal(t *testing.T) {
	// Setup
	interfaceRegistry := types.NewInterfaceRegistry()
	cdc := codec.NewProtoCodec(interfaceRegistry)
	
	storeKey := storetypes.NewKVStoreKey("governance-safeguards")
	config := safeguardstypes.DefaultConfig()
	k := keeper.NewKeeper(cdc, storeKey, config, log.NewNopLogger())
	
	decorator := NewGovernanceSafeguardDecorator(k)
	
	// Create a valid proposal message
	msg := &govtypesv1.MsgSubmitProposal{
		Messages: []*types.Any{},
		Title:    "Update Pool Parameters",
		Summary:  "This proposal updates pool parameters for better efficiency",
	}
	
	// Create mock transaction
	tx := &mockTx{msgs: []sdk.Msg{msg}}
	ctx := sdk.Context{}
	
	// Test
	nextCalled := false
	next := func(ctx sdk.Context, tx sdk.Tx, simulate bool) (sdk.Context, error) {
		nextCalled = true
		return ctx, nil
	}
	
	_, err := decorator.AnteHandle(ctx, tx, false, next)
	
	// Assertions
	require.NoError(t, err)
	require.True(t, nextCalled)
}

func TestGovernanceSafeguardDecorator_RestrictedProposal(t *testing.T) {
	// Setup
	interfaceRegistry := types.NewInterfaceRegistry()
	cdc := codec.NewProtoCodec(interfaceRegistry)
	
	storeKey := storetypes.NewKVStoreKey("governance-safeguards")
	config := safeguardstypes.DefaultConfig()
	k := keeper.NewKeeper(cdc, storeKey, config, log.NewNopLogger())
	
	decorator := NewGovernanceSafeguardDecorator(k)
	
	// Create a restricted proposal message
	msg := &govtypesv1.MsgSubmitProposal{
		Messages: []*types.Any{},
		Title:    "Enable Perpetual Trading",
		Summary:  "This proposal enables perpetual trading functionality",
	}
	
	// Create mock transaction
	tx := &mockTx{msgs: []sdk.Msg{msg}}
	ctx := sdk.Context{}
	
	// Test
	nextCalled := false
	next := func(ctx sdk.Context, tx sdk.Tx, simulate bool) (sdk.Context, error) {
		nextCalled = true
		return ctx, nil
	}
	
	_, err := decorator.AnteHandle(ctx, tx, false, next)
	
	// Assertions
	require.Error(t, err)
	require.Contains(t, err.Error(), "governance proposal validation failed")
	require.False(t, nextCalled)
}

func TestGovernanceSafeguardDecorator_DisabledSafeguards(t *testing.T) {
	// Setup
	interfaceRegistry := types.NewInterfaceRegistry()
	cdc := codec.NewProtoCodec(interfaceRegistry)
	
	storeKey := storetypes.NewKVStoreKey("governance-safeguards")
	config := safeguardstypes.Config{
		DisableLeverageModules:  false, // Disabled
		RestrictedProposalTypes: safeguardstypes.LeverageRestrictedProposalTypes,
		RestrictedModules:       safeguardstypes.LeverageRestrictedModules,
	}
	k := keeper.NewKeeper(cdc, storeKey, config, log.NewNopLogger())
	
	decorator := NewGovernanceSafeguardDecorator(k)
	
	// Create a restricted proposal message (should be allowed when safeguards are disabled)
	msg := &govtypesv1.MsgSubmitProposal{
		Messages: []*types.Any{},
		Title:    "Enable Perpetual Trading",
		Summary:  "This proposal enables perpetual trading functionality",
	}
	
	// Create mock transaction
	tx := &mockTx{msgs: []sdk.Msg{msg}}
	ctx := sdk.Context{}
	
	// Test
	nextCalled := false
	next := func(ctx sdk.Context, tx sdk.Tx, simulate bool) (sdk.Context, error) {
		nextCalled = true
		return ctx, nil
	}
	
	_, err := decorator.AnteHandle(ctx, tx, false, next)
	
	// Assertions
	require.NoError(t, err)
	require.True(t, nextCalled)
}

func TestValidateProposalContent(t *testing.T) {
	testCases := []struct {
		name        string
		title       string
		description string
		expectError bool
	}{
		{
			name:        "Valid proposal",
			title:       "Update Pool Parameters",
			description: "This proposal updates pool parameters",
			expectError: false,
		},
		{
			name:        "Restricted title",
			title:       "Enable Perpetual Trading",
			description: "Valid description",
			expectError: true,
		},
		{
			name:        "Restricted description",
			title:       "Valid title",
			description: "This proposal adds margin trading",
			expectError: true,
		},
	}
	
	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			err := ValidateProposalContent(tc.title, tc.description)
			if tc.expectError {
				require.Error(t, err)
			} else {
				require.NoError(t, err)
			}
		})
	}
}

// Mock transaction for testing
type mockTx struct {
	msgs []sdk.Msg
}

func (tx *mockTx) GetMsgs() []sdk.Msg {
	return tx.msgs
}

func (tx *mockTx) ValidateBasic() error {
	return nil
}