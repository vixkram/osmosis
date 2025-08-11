# Governance Safeguards Module

The Governance Safeguards module provides protection against leverage-related governance proposals in the Osmosis DEX fork. This module ensures that the DEX remains focused on spot trading by preventing the installation or activation of perpetuals, margins, and other leveraged trading functionality through governance proposals.

## Features

- **Proposal Validation**: Automatically validates governance proposals against leverage-related keywords
- **Module Restrictions**: Prevents installation of leverage-related modules through upgrade proposals
- **Configurable**: Can be enabled/disabled and customized via configuration
- **Comprehensive Coverage**: Checks proposal titles, descriptions, and message content
- **Case-Insensitive**: Performs case-insensitive keyword matching

## Restricted Keywords

The following keywords are automatically rejected in governance proposals:

### Proposal Types
- `perpetual`
- `margin`
- `leverage`
- `futures`
- `derivatives`
- `perp`
- `leveraged`
- `borrow`
- `lending`
- `collateral`

### Module Names
- `perpetuals`
- `margins`
- `leverage`
- `futures`
- `derivatives`
- `lending`
- `borrowing`

## Configuration

The governance safeguards can be configured in your `app.toml` file:

```toml
[governance-safeguards]
enabled = true
disable_leverage_modules = true
additional_restricted_types = []
additional_restricted_modules = []
```

### Configuration Options

- `enabled`: Enable or disable governance safeguards (default: `true`)
- `disable_leverage_modules`: Prevent installation of leverage-related modules (default: `true`)
- `additional_restricted_types`: Additional proposal keywords to restrict
- `additional_restricted_modules`: Additional module names to restrict

## Implementation

### Components

1. **Types** (`types/types.go`): Core types and validation logic
2. **Keeper** (`keeper/keeper.go`): Keeper for managing configuration and state
3. **Ante Handler** (`ante.go`): Ante handler decorator for proposal validation
4. **Configuration** (`app/config/governance_safeguards.go`): Configuration management

### Integration

The module integrates with the existing governance system through:

1. **Ante Handler Chain**: Validates proposals before they are processed
2. **Governance Keeper**: Works alongside the existing governance module
3. **Configuration System**: Uses the standard app configuration system

## Usage Examples

### Allowed Proposals

```go
// This proposal would be accepted
proposal := govtypesv1.Proposal{
    Title:   "Update Pool Parameters",
    Summary: "This proposal updates the pool parameters for better efficiency",
}
```

### Rejected Proposals

```go
// This proposal would be rejected
proposal := govtypesv1.Proposal{
    Title:   "Enable Perpetual Trading",
    Summary: "This proposal enables perpetual trading functionality",
}
// Error: "proposal contains restricted leverage-related content: perpetual"
```

## Testing

The module includes comprehensive tests:

```bash
# Run type tests
go test ./x/governance-safeguards/types -v

# Run ante handler tests
go test ./x/governance-safeguards -v

# Validate implementation
./scripts/validate_governance_safeguards.sh

# Demo functionality
./scripts/demo_governance_safeguards.sh
```

## Security Considerations

- **Bypass Prevention**: The ante handler runs early in the transaction processing pipeline
- **Comprehensive Validation**: Checks multiple aspects of proposals (title, description, messages)
- **Configuration Protection**: Configuration changes require code updates, not just governance proposals
- **Logging**: All validation attempts are logged for audit purposes

## Disabling Safeguards

If you need to disable the safeguards (not recommended for production):

1. Set `enabled = false` in configuration
2. Or set `disable_leverage_modules = false`
3. Restart the node

## Development

### Adding New Restrictions

To add new restricted keywords:

1. Update `LeverageRestrictedProposalTypes` in `types/types.go`
2. Update `LeverageRestrictedModules` for module restrictions
3. Add corresponding tests
4. Update documentation

### Custom Validation

For custom validation logic, extend the `validateMessage` function in `types/types.go`.

## License

This module is part of the Osmosis DEX fork and follows the same licensing terms.