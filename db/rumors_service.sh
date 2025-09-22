#!/bin/bash

# Script to populate the database with initial rumor data if it's empty
# Usage: ./scripts/populate-db.sh

set -e

API_URL="http://localhost:3000"
SCRIPT_DIR="$(dirname "$0")"
DATA_FILE="$SCRIPT_DIR/rumor-data.json"

check_api() {
    if ! curl -s "$API_URL/rumors" > /dev/null 2>&1; then
        echo "API not reachable at $API_URL"
        echo "Make sure your service is running first:"
        echo "  ./scripts/start.sh"
        exit 1
    fi
}

is_database_empty() {
    local count=$(curl -s "$API_URL/rumors" | jq '. | length' 2>/dev/null || echo "0")
    [ "$count" -eq 0 ]
}

create_rumors() {
    local category=$1
    echo "Creating $category rumors..."
    
    jq -r ".${category}[] | @json" "$DATA_FILE" | while read -r rumor; do
        curl -s -X POST "$API_URL/rumors" \
            -H "Content-Type: application/json" \
            -d "$rumor" > /dev/null
        echo "  ✓ Created: $(echo "$rumor" | jq -r '.content' | cut -c1-50)..."
    done
}

echo "Database Population Script"
echo "========================="

if [ ! -f "$DATA_FILE" ]; then
    echo "Data file not found: $DATA_FILE"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "jq is required but not installed"
    echo "Install with: brew install jq"
    exit 1
fi

check_api

if is_database_empty; then
    echo "Database is empty, populating with initial data..."
    echo ""
    
    create_rumors "role"
    create_rumors "task" 
    create_rumors "location"
    create_rumors "appearance"
    
    echo ""
    echo "✅ Database populated successfully!"
    
    local total=$(curl -s "$API_URL/rumors" | jq '. | length')
    echo "📈 Total rumors created: $total"
    
else
    echo "ℹ️  Database already contains data, skipping population"
    local existing=$(curl -s "$API_URL/rumors" | jq '. | length')
    echo "📊 Existing rumors: $existing"
fi

