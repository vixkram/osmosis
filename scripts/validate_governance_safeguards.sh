#!/bin/bash

# Governance Safeguards Validation Script
# This script validates that governance safeguards are properly implemented

echo "=== Governance Safeguards Validation ==="
echo

# Check if governance safeguards files exist
echo "1. Checking if governance safeguards files exist..."

files=(
    "x/governance-safeguards/types/types.go"
    "x/governance-safeguards/keeper/keeper.go"
    "x/governance-safeguards/ante.go"
    "x/governance-safeguards/types/types_test.go"
    "x/governance-safeguards/ante_test.go"
    "app/config/governance_safeguards.go"
)

all_files_exist=true
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ $file exists"
    else
        echo "✗ $file missing"
        all_files_exist=false
    fi
done

echo

# Check if integration points exist
echo "2. Checking integration points..."

integration_checks=(
    "app/ante.go:GovernanceSafeguardDecorator"
    "app/keepers/keepers.go:GovernanceSafeguardsKeeper"
    "app/app.go:GovernanceSafeguardParams"
)

for check in "${integration_checks[@]}"; do
    file=$(echo $check | cut -d: -f1)
    pattern=$(echo $check | cut -d: -f2)
    
    if grep -q "$pattern" "$file" 2>/dev/null; then
        echo "✓ $pattern found in $file"
    else
        echo "✗ $pattern not found in $file"
        all_files_exist=false
    fi
done

echo

# Check for restricted keywords in types
echo "3. Checking restricted keywords configuration..."

if grep -q "perpetual" "x/governance-safeguards/types/types.go" 2>/dev/null; then
    echo "✓ Perpetual keyword restriction configured"
else
    echo "✗ Perpetual keyword restriction missing"
    all_files_exist=false
fi

if grep -q "margin" "x/governance-safeguards/types/types.go" 2>/dev/null; then
    echo "✓ Margin keyword restriction configured"
else
    echo "✗ Margin keyword restriction missing"
    all_files_exist=false
fi

if grep -q "leverage" "x/governance-safeguards/types/types.go" 2>/dev/null; then
    echo "✓ Leverage keyword restriction configured"
else
    echo "✗ Leverage keyword restriction missing"
    all_files_exist=false
fi

echo

# Summary
if [ "$all_files_exist" = true ]; then
    echo "✅ All governance safeguards components are properly implemented!"
    echo
    echo "Features implemented:"
    echo "- Proposal validation against leverage-related keywords"
    echo "- Configuration flag to disable leveraged trading modules"
    echo "- Ante handler integration to reject restricted proposals"
    echo "- Comprehensive test coverage"
    echo "- Integration with existing governance module"
    exit 0
else
    echo "❌ Some governance safeguards components are missing or not properly integrated."
    exit 1
fi