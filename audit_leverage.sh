#!/bin/bash

# Leverage-related keyword audit script for Osmosis codebase
# This script scans for perpetual/margin keywords and related functionality

echo "=== Osmosis Codebase Leverage Audit ==="
echo "Scanning for perpetual/margin keywords..."
echo "Generated on: $(date)"
echo ""

# Define keywords to search for
KEYWORDS=(
    "perpetual"
    "margin"
    "leverage"
    "leveraged"
    "position"
    "long"
    "short"
    "futures"
    "derivative"
    "collateral"
    "liquidation"
    "liquidate"
    "pnl"
    "unrealized"
    "mark_price"
    "funding_rate"
    "maintenance_margin"
    "initial_margin"
)

# Create output file
OUTPUT_FILE="leverage_audit_results.md"
echo "# Leverage Audit Results" > $OUTPUT_FILE
echo "" >> $OUTPUT_FILE
echo "Generated on: $(date)" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# Function to search for keywords
search_keyword() {
    local keyword=$1
    echo "## Searching for: $keyword"
    echo "## Results for keyword: $keyword" >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE
    
    # Search in Go files, excluding vendor and .git directories
    results=$(grep -r -i --include="*.go" --exclude-dir=".git" --exclude-dir="vendor" "$keyword" . 2>/dev/null || true)
    
    if [ -n "$results" ]; then
        echo "Found matches for '$keyword':"
        echo "$results" | head -20  # Limit to first 20 matches for console output
        echo ""
        
        # Write all results to file
        echo '```' >> $OUTPUT_FILE
        echo "$results" >> $OUTPUT_FILE
        echo '```' >> $OUTPUT_FILE
        echo "" >> $OUTPUT_FILE
    else
        echo "No matches found for '$keyword'"
        echo "No matches found." >> $OUTPUT_FILE
        echo "" >> $OUTPUT_FILE
    fi
}

# Search for each keyword
for keyword in "${KEYWORDS[@]}"; do
    search_keyword "$keyword"
done

echo "=== Module Analysis ==="
echo "## Module Analysis" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# Analyze app.go for module imports
echo "### Analyzing app.go for module imports"
echo "### Module imports from app.go:" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

if [ -f "app/app.go" ]; then
    echo "Found app.go, analyzing imports..."
    echo '```go' >> $OUTPUT_FILE
    grep -n "import\|ModuleManager\|NewApp\|RegisterModules" app/app.go | head -50 >> $OUTPUT_FILE
    echo '```' >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE
else
    echo "app.go not found in expected location"
    echo "app.go not found in expected location" >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE
fi

# Check for x/ modules that might contain leverage functionality
echo "### Checking x/ modules for leverage-related functionality"
echo "### x/ modules analysis:" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

if [ -d "x" ]; then
    echo "Found x/ directory, listing modules:"
    echo '```' >> $OUTPUT_FILE
    ls -la x/ >> $OUTPUT_FILE
    echo '```' >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE
    
    # Check each module for leverage-related files
    for module in x/*/; do
        if [ -d "$module" ]; then
            module_name=$(basename "$module")
            echo "Analyzing module: $module_name"
            echo "#### Module: $module_name" >> $OUTPUT_FILE
            
            # Look for leverage-related files in the module
            leverage_files=$(find "$module" -name "*.go" -exec grep -l -i "perpetual\|margin\|leverage\|position\|liquidat" {} \; 2>/dev/null || true)
            
            if [ -n "$leverage_files" ]; then
                echo "Found potential leverage-related files in $module_name:"
                echo "$leverage_files"
                echo '```' >> $OUTPUT_FILE
                echo "$leverage_files" >> $OUTPUT_FILE
                echo '```' >> $OUTPUT_FILE
            else
                echo "No leverage-related files found in $module_name"
                echo "No leverage-related files found." >> $OUTPUT_FILE
            fi
            echo "" >> $OUTPUT_FILE
        fi
    done
else
    echo "x/ directory not found"
    echo "x/ directory not found" >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE
fi

echo "=== Dependency Analysis ==="
echo "## Dependency Analysis" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# Check go.mod for leverage-related dependencies
if [ -f "go.mod" ]; then
    echo "### Analyzing go.mod for leverage-related dependencies"
    echo "### go.mod dependencies:" >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE
    
    leverage_deps=$(grep -i "perpetual\|margin\|leverage\|futures\|derivative" go.mod || true)
    if [ -n "$leverage_deps" ]; then
        echo "Found potential leverage-related dependencies:"
        echo "$leverage_deps"
        echo '```' >> $OUTPUT_FILE
        echo "$leverage_deps" >> $OUTPUT_FILE
        echo '```' >> $OUTPUT_FILE
    else
        echo "No obvious leverage-related dependencies found in go.mod"
        echo "No obvious leverage-related dependencies found in go.mod" >> $OUTPUT_FILE
    fi
    echo "" >> $OUTPUT_FILE
fi

echo "=== Summary ==="
echo "## Summary" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE
echo "Audit completed. Results saved to: $OUTPUT_FILE"
echo "Please review the detailed results in the output file."
echo "" >> $OUTPUT_FILE
echo "### Key Findings:" >> $OUTPUT_FILE
echo "- Detailed keyword search results above" >> $OUTPUT_FILE
echo "- Module analysis completed" >> $OUTPUT_FILE
echo "- Dependency analysis completed" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE
echo "### Recommendations:" >> $OUTPUT_FILE
echo "1. Review all flagged occurrences of keywords" >> $OUTPUT_FILE
echo "2. Verify that 'perpetual' references are related to gauge types, not trading" >> $OUTPUT_FILE
echo "3. Confirm no hidden leverage functionality exists" >> $OUTPUT_FILE
echo "4. Document any legitimate uses of flagged keywords" >> $OUTPUT_FILE

echo ""
echo "Audit script completed successfully!"