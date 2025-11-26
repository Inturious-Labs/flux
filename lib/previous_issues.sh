#!/bin/bash

# Sunday Blender Previous Issues Generator
# Automatically generates "Previous Issues" section for continuity

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'
BOLD='\033[1m'

# Load configuration
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$LIB_DIR/../config/sites.json"

generate_previous_issues() {
    # Load SB path from config
    local sb_path=$(jq -r '.sites.sb.path' "$CONFIG_FILE" 2>/dev/null)
    if [ -z "$sb_path" ] || [ "$sb_path" = "null" ]; then
        sb_path="/path/to/sundayblender"
    fi
    local temp_file="/tmp/sb_published_posts.txt"
    
    # Find all published posts (draft: false) that are committed to git
    # This ensures we only include posts that are actually live
    echo -n "" > "$temp_file"
    
    # Get all committed files that are published
    while IFS= read -r -d '' file; do
        # Check if it's published (draft: false)
        if grep -q "draft: false" "$file" 2>/dev/null; then
            # Check if it's committed (not in git status)
            local relative_path=${file#$sb_path/}
            if ! git -C "$sb_path" status --porcelain | grep -q "$relative_path"; then
                # Extract date and title
                local date_line=$(grep '^date:' "$file" | head -1)
                local title_line=$(grep '^title:' "$file" | head -1)
                local slug_line=$(grep '^slug:' "$file" | head -1)
                
                if [ -n "$date_line" ] && [ -n "$title_line" ]; then
                    local date=$(echo "$date_line" | sed 's/date: //' | cut -d'T' -f1)
                    local title=$(echo "$title_line" | sed 's/title: "//' | sed 's/"$//')
                    local slug=$(echo "$slug_line" | sed 's/slug: //' | tr -d '"')
                    
                    # Convert date to readable format (YYYY-MM-DD to Month DD, YYYY)
                    local formatted_date=$(date -j -f "%Y-%m-%d" "$date" "+%B %d, %Y" 2>/dev/null || echo "$date")
                    
                    # Store as "YYYY-MM-DD|formatted_date|title|slug" for sorting
                    echo "$date|$formatted_date|$title|$slug" >> "$temp_file"
                fi
            fi
        fi
    done < <(find "$sb_path/content/posts" -name "index.md" -print0 2>/dev/null)
    
    # Sort by date (newest first) and get the 3 most recent
    local previous_issues=""
    if [ -s "$temp_file" ]; then
        previous_issues=$(sort -r "$temp_file" | head -3)
    fi
    
    # Generate the Previous Issues section
    if [ -n "$previous_issues" ]; then
        echo ""
        echo "---"
        echo ""
        echo "## Previous Issues"
        echo ""
        echo "---"
        echo ""
        
        while IFS='|' read -r date formatted_date title slug; do
            if [ -n "$formatted_date" ] && [ -n "$title" ] && [ -n "$slug" ]; then
                # Create the URL (using the slug)
                local url="https://weekly.sundayblender.com/p/$slug"
                echo "$formatted_date, **[$title]($url)**"
                echo ""
            fi
        done <<< "$previous_issues"
    fi
    
    # Clean up
    rm -f "$temp_file"
}

# Export function
export -f generate_previous_issues