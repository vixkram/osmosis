package governance_safeguards

import (
	"fmt"

	sdk "github.com/cosmos/cosmos-sdk/types"
	sdkerrors "github.com/cosmos/cosmos-sdk/types/errors"
	govtypes "github.com/cosmos/cosmos-sdk/x/gov/types"
	govtypesv1 "github.com/cosmos/cosmos-sdk/x/gov/types/v1"

	"	"github.com/osmosis-labs/osmosis/v30/x/governance-safeguards/keeper"
	"github.com/osmosis-labs/osmosis/v30/x/governance-safeguards/types""
)

// GovernanceSafeguardDecorator validates governance proposals to prevent leverage-related functionality
type GovernanceSafeguardDecorator struct {
	keeper keeper.Keeper
}

// NewGovernanceSafeguardDecorator creates a new governance safeguard decorator
func NewGovernanceSafeguardDecorator(k keeper.Keeper) GovernanceSafeguardDecorator {
	return GovernanceSafeguardDecorator{
		keeper: k,
	}
}

// AnteHandle validates governance proposals before they are processed
func (gsd GovernanceSafeguardDecorator) AnteHandle(
	ctx sdk.Context,
	tx sdk.Tx,
	simulate bool,
	next sdk.AnteHandler,
) (newCtx sdk.Context, err error) {
	// Only validate if leverage modules are disabled
	if !gsd.keeper.IsLeverageModuleDisabled() {
		return next(ctx, tx, simulate)
	}

	// Check each message in the transaction
	for _, msg := range tx.GetMsgs() {
		switch m := msg.(type) {
		case *govtypesv1.MsgSubmitProposal:
			if err := gsd.validateSubmitProposal(ctx, m); err != nil {
				return ctx, err
			}
		}
	}

	return next(ctx, tx, simulate)
}

// validateSubmitProposal validates a submit proposal message
func (gsd GovernanceSafeguardDecorator) validateSubmitProposal(ctx sdk.Context, msg *govtypesv1.MsgSubmitProposal) error {
	// Create a proposal object for validation
	proposal := govtypesv1.Proposal{
		Id:       0, // ID not needed for validation
		Messages: msg.Messages,
		Title:    msg.Title,
		Summary:  msg.Summary,
	}

	if err := gsd.keeper.ValidateProposal(ctx, proposal); err != nil {
		return sdkerrors.Wrapf(
			sdkerrors.ErrInvalidRequest,
			"governance proposal validation failed: %s",
			err.Error(),
		)
	}

	return nil
}

// ValidateProposalContent validates proposal content for leverage-related keywords
func ValidateProposalContent(title, description string) error {
	config := types.DefaultConfig()
	
	// Create a minimal proposal for validation
	proposal := govtypesv1.Proposal{
		Title:   title,
		Summary: description,
	}

	return config.ValidateProposal(proposal)
}