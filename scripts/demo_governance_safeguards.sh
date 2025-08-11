#!/bin/bash

# Governance Safeguards Demo Script
# This script demonstrates how the governance safeguards prevent leverage-related proposals

echo "=== Governance Safeguards Demo ==="
echo
echo "This demo shows how the governance safeguards prevent leverage-related proposals"
echo "from being submitted to the Osmosis DEX fork."
echo

# Show restricted keywords
echo "1. Restricted Keywords:"
echo "   The following keywords are automatically rejected in governance proposals:"
echo "   - perpetual, margin, leverage, futures, derivatives"
echo "   - perp, leveraged, borrow, lending, collateral"
echo

# Show restricted modules
echo "2. Restricted Modules:"
echo "   The following module names are blocked from installation:"
echo "   - perpetuals, margins, leverage, futures, derivatives"
echo "   - lending, borrowing"
echo

# Show configuration
echo "3. Configuration:"
echo "   The safeguards can be configured via app.toml:"
echo "   [governance-safeguards]"
echo "   enabled = true"
echo "   disable_leverage_modules = true"
echo "   additional_restricted_types = []"
echo "   additional_restricted_modules = []"
echo

# Show examples
echo "4. Example Proposals:"
echo

echo "   ✅ ALLOWED: 'Update Pool Parameters'"
echo "      Description: 'This proposal updates the pool parameters for better efficiency'"
echo "      → This proposal would be accepted"
echo

echo "   ❌ REJECTED: 'Enable Perpetual Trading'"
echo "      Description: 'This proposal enables perpetual trading functionality'"
echo "      → This proposal would be rejected with error: 'proposal contains restricted leverage-related content: perpetual'"
echo

echo "   ❌ REJECTED: 'Add Margin Trading'"
echo "      Description: 'This proposal adds margin trading capabilities to the DEX'"
echo "      → This proposal would be rejected with error: 'proposal contains restricted leverage-related content: margin'"
echo

echo "5. Implementation Details:"
echo "   - Validation occurs in the ante handler before proposal submission"
echo "   - Case-insensitive keyword matching"
echo "   - Checks both proposal title and description"
echo "   - Validates upgrade proposals for restricted module installations"
echo "   - Can be disabled via configuration if needed"
echo

echo "6. Testing:"
echo "   Run the validation script to verify implementation:"
echo "   ./scripts/validate_governance_safeguards.sh"
echo

echo "✅ Governance safeguards are active and protecting against leverage-related proposals!"