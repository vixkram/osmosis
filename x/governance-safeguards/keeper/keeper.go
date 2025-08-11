package keeper

import (
	"context"

	"cosmossdk.io/log"
	storetypes "cosmossdk.io/store/types"
	"github.com/cosmos/cosmos-sdk/codec"
	sdk "github.com/cosmos/cosmos-sdk/types"
	govtypes "github.com/cosmos/cosmos-sdk/x/gov/types"
	govtypesv1 "github.com/cosmos/cosmos-sdk/x/gov/types/v1"

	"github.com/osmosis-labs/osmosis/v30/x/governance-safeguards/types"
)

// Keeper provides governance safeguards functionality
type Keeper struct {
	cdc    codec.Codec
	key    storetypes.StoreKey
	config types.Config
	logger log.Logger
}

// NewKeeper creates a new governance safeguards keeper
func NewKeeper(
	cdc codec.Codec,
	key storetypes.StoreKey,
	config types.Config,
	logger log.Logger,
) Keeper {
	return Keeper{
		cdc:    cdc,
		key:    key,
		config: config,
		logger: logger,
	}
}

// ValidateProposal validates a governance proposal against leverage restrictions
func (k Keeper) ValidateProposal(ctx context.Context, proposal govtypesv1.Proposal) error {
	k.logger.Info("Validating governance proposal for leverage restrictions",
		"proposal_id", proposal.Id,
		"title", proposal.Title)

	if err := k.config.ValidateProposal(proposal); err != nil {
		k.logger.Error("Proposal validation failed",
			"proposal_id", proposal.Id,
			"error", err.Error())
		return err
	}

	k.logger.Info("Proposal validation passed",
		"proposal_id", proposal.Id)

	return nil
}

// GetConfig returns the current configuration
func (k Keeper) GetConfig() types.Config {
	return k.config
}

// SetConfig updates the configuration
func (k Keeper) SetConfig(config types.Config) {
	k.config = config
}

// IsLeverageModuleDisabled returns whether leverage modules are disabled
func (k Keeper) IsLeverageModuleDisabled() bool {
	return k.config.DisableLeverageModules
}

// Logger returns the keeper's logger
func (k Keeper) Logger() log.Logger {
	return k.logger
}