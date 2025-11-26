#!/bin/bash

# DSC Scanner - Extract existing categories and series from Digital Sovereignty Chronicle
# Used by frontmatter.sh to provide selection options

# Load configuration
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$LIB_DIR/../config/sites.json"

# Load DSC path from config
DSC_PATH=$(jq -r '.sites.dsc.path' "$CONFIG_FILE" 2>/dev/null)
if [ -z "$DSC_PATH" ] || [ "$DSC_PATH" = "null" ]; then
    DSC_PATH="/path/to/digital-sovereignty"
fi

DSC_CONTENT_DIR="$DSC_PATH/content/posts"

# Scan for existing categories
scan_dsc_categories() {
    if [ ! -d "$DSC_CONTENT_DIR" ]; then
        echo "Error: DSC content directory not found at $DSC_CONTENT_DIR" >&2
        return 1
    fi

    # Extract categories from published posts only (draft: false or no draft field)
    local categories=$(find "$DSC_CONTENT_DIR" -name "*.md" -exec awk '
        /^---/ { if (frontmatter_count == 0) { frontmatter_count++; in_frontmatter = 1; next } else if (frontmatter_count == 1) { in_frontmatter = 0; frontmatter_count++; next } }
        in_frontmatter && /^draft: true/ { is_draft = 1 }
        in_frontmatter && /^categories:/ { in_categories = 1; next }
        in_frontmatter && in_categories && /^  - "/ {
            gsub(/^  - "/, "");
            gsub(/"$/, "");
            if ($0 != "") category_list[++cat_count] = $0
        }
        in_frontmatter && in_categories && /^[a-zA-Z]/ { in_categories = 0 }
        END {
            if (!is_draft) {
                for (i = 1; i <= cat_count; i++) {
                    print category_list[i]
                }
            }
        }
    ' {} \; 2>/dev/null | \
        sort | uniq | \
        grep -v "^$" | \
        tr '\n' ',' | \
        sed 's/,$//')

    if [ -z "$categories" ]; then
        echo "No existing categories found in DSC posts" >&2
        return 1
    fi

    echo "$categories"
}

# Scan for existing series
scan_dsc_series() {
    if [ ! -d "$DSC_CONTENT_DIR" ]; then
        echo "Error: DSC content directory not found at $DSC_CONTENT_DIR" >&2
        return 1
    fi

    # Extract series from published posts only (draft: false or no draft field)
    local series_list=$(find "$DSC_CONTENT_DIR" -name "*.md" -exec awk '
        /^---/ { if (frontmatter_count == 0) { frontmatter_count++; in_frontmatter = 1; next } else if (frontmatter_count == 1) { in_frontmatter = 0; frontmatter_count++; next } }
        in_frontmatter && /^draft: true/ { is_draft = 1 }
        in_frontmatter && /^series:/ { in_series = 1; next }
        in_frontmatter && in_series && /^  - "/ {
            gsub(/^  - "/, "");
            gsub(/"$/, "");
            if ($0 != "") series_list[++series_count] = $0
        }
        in_frontmatter && in_series && /^[a-zA-Z]/ { in_series = 0 }
        END {
            if (!is_draft) {
                for (i = 1; i <= series_count; i++) {
                    print series_list[i]
                }
            }
        }
    ' {} \; 2>/dev/null | \
        sort | uniq | \
        grep -v "^$" | \
        tr '\n' ',' | \
        sed 's/,$//')

    echo "$series_list"  # Can be empty, that's fine for series
}

# Present category selection menu
select_dsc_category() {
    local categories=$(scan_dsc_categories)
    if [ $? -ne 0 ]; then
        printf "${RED}Unable to scan existing categories.${NC}\n" >&2
        printf "${GREEN}Please enter category manually:${NC} " >&2
        read -r manual_category
        echo "$manual_category"
        return
    fi

    echo -e "${GREEN}Category${NC} ${GRAY}(choose from existing):${NC}" >&2

    # Convert comma-separated to array
    IFS=',' read -ra cat_array <<< "$categories"

    # Display options
    local i=1
    for cat in "${cat_array[@]}"; do
        printf "  %d) %-15s" "$i" "$cat" >&2
        if [ $((i % 4)) -eq 0 ]; then
            echo "" >&2
        fi
        ((i++))
    done
    if [ $((${#cat_array[@]} % 4)) -ne 0 ]; then
        echo "" >&2
    fi

    echo "  $((${#cat_array[@]}+1)) Enter new category" >&2
    printf "${GREEN}Choice [1-$((${#cat_array[@]}+1))] or type custom:${NC} " >&2
    read -r cat_choice

    # Process choice
    if [[ "$cat_choice" =~ ^[0-9]+$ ]] && [ "$cat_choice" -ge 1 ] && [ "$cat_choice" -le "${#cat_array[@]}" ]; then
        echo "${cat_array[$((cat_choice-1))]}"
    elif [ "$cat_choice" = "$((${#cat_array[@]}+1))" ]; then
        printf "${GREEN}Enter new category${NC} ${GRAY}(e.g., 'Web3 Tools', 'DeFi Analysis', 'Tech Reviews'):${NC} " >&2
        read -r new_category
        echo "$new_category"
    elif [ -n "$cat_choice" ]; then
        echo "$cat_choice"
    else
        echo "${cat_array[0]}" # default to first option
    fi
}

# Present series selection menu
select_dsc_series() {
    local series_list=$(scan_dsc_series)

    echo -e "${GREEN}Series${NC} ${GRAY}(optional - choose from existing):${NC}" >&2

    if [ -n "$series_list" ]; then
        # Convert comma-separated to array
        IFS=',' read -ra series_array <<< "$series_list"

        # Display options
        echo "  0) None (skip series)" >&2
        local i=1
        for series in "${series_array[@]}"; do
            printf "  %d) %s\n" "$i" "$series" >&2
            ((i++))
        done

        echo "  $((${#series_array[@]}+1)) Enter new series" >&2
        printf "${GREEN}Choice [0-$((${#series_array[@]}+1))] or type custom:${NC} " >&2
        read -r series_choice

        # Process choice
        if [ "$series_choice" = "0" ]; then
            echo "" # no series
        elif [[ "$series_choice" =~ ^[0-9]+$ ]] && [ "$series_choice" -ge 1 ] && [ "$series_choice" -le "${#series_array[@]}" ]; then
            echo "${series_array[$((series_choice-1))]}"
        elif [ "$series_choice" = "$((${#series_array[@]}+1))" ]; then
            printf "${GREEN}Enter new series${NC} ${GRAY}(e.g., 'Weekly Roundup', 'Deep Dive Series', 'Beginner's Guide'):${NC} " >&2
            read -r new_series
            echo "$new_series"
        elif [ -n "$series_choice" ]; then
            echo "$series_choice"
        else
            echo "" # default to no series
        fi
    else
        printf "${GREEN}Series name${NC} ${GRAY}(e.g., 'Weekly Roundup', 'Deep Dive Series', 'Beginner's Guide' or Enter to skip):${NC} " >&2
        read -r series_choice
        echo "$series_choice"
    fi
}

# Export functions for use by frontmatter.sh
export -f scan_dsc_categories
export -f scan_dsc_series
export -f select_dsc_category
export -f select_dsc_series