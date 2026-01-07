#!/usr/bin/env sh

# grype-explainer.sh - Run grype and explain all found vulnerabilities
# This script scans for vulnerabilities and automatically explains each one found

# Step 1: Run grype and save JSON output
# Check for --exclude flag
if [ "$1" = "--exclude" ]; then
    EXCLUDE_ARGS="--exclude './data/**'"
    echo "Scanning for vulnerabilities (excluding data/**)"
    grype . -o json $EXCLUDE_ARGS > .tmp.grype.json 2>/dev/null
else
    echo "Scanning for vulnerabilities..."
    grype . -o json > .tmp.grype.json 2>/dev/null
fi

# Step 2: Extract vulnerability IDs
jq -r '.matches[].vulnerability.id' .tmp.grype.json > .tmp.grype.ids.json

# Check if any vulnerabilities were found
if [ ! -s .tmp.grype.ids.json ]; then
    echo "No vulnerabilities found."
    rm -f .tmp.grype.json .tmp.grype.ids.json
    exit 0
fi

# Step 3: Format IDs as --id arguments
cat .tmp.grype.ids.json | sed 's/^/--id /' > .tmp.grype.explain

# Step 4: Use the arguments with grype explain
echo "Explaining vulnerabilities..."
cat .tmp.grype.json | grype explain $(cat .tmp.grype.explain | xargs) 2>/dev/null

# Step 5: Clean up temporary files
rm -f .tmp.grype.json .tmp.grype.ids.json .tmp.grype.explain