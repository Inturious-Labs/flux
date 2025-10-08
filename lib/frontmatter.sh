#!/bin/bash

# Zettelkasten Writer - Smart Frontmatter Wizard
# Multi-site support

# Source previous issues generator for Sunday Blender
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/previous_issues.sh"

# Source DSC scanner for categories and series
source "$LIB_DIR/dsc_scanner.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
GRAY='\033[0;90m'
NC='\033[0m'
BOLD='\033[1m'

create_dsc_frontmatter() {
    echo -e "${BLUE}📝 Creating new post for Digital Sovereignty Chronicle${NC}"
    echo ""
    
    # Title
    printf "${GREEN}Title:${NC} "
    read -r title
    if [ -z "$title" ]; then
        echo -e "${RED}Title is required.${NC}"
        return 1
    fi
    
    # Generate slug from title
    local slug=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')
    printf "${GREEN}Slug${NC} ${GRAY}(auto-generated):${NC} $slug ${GRAY}[Enter to accept, or type new]:${NC} "
    read -r custom_slug
    if [ -n "$custom_slug" ]; then
        slug="$custom_slug"
    fi
    
    # Skip date for drafts - will be set during publishing
    
    # Description
    printf "${GREEN}Description${NC} ${GRAY}(brief summary):${NC} "
    read -r description
    if [ -z "$description" ]; then
        description="Brief description of the post"
    fi
    
    # Category - use scanner to get existing categories
    local category=$(select_dsc_category)
    
    # Series (optional) - use scanner to get existing series
    local series=$(select_dsc_series)
    
    # Keywords (optional for SEO)
    printf "${GREEN}Keywords${NC} ${GRAY}(optional, comma-separated for SEO - can be added later):${NC} "
    read -r keywords
    
    # Generate directory structure for drafts
    local post_dir="/Users/zire/matrix/github_zire/digital-sovereignty/content/posts/drafts/$slug"
    
    # Check if directory exists
    if [ -d "$post_dir" ]; then
        echo -e "${YELLOW}⚠️  Directory already exists: $post_dir${NC}"
        printf "${BLUE}Continue anyway? [y/N]:${NC} "
        read -r confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    # Create directory
    mkdir -p "$post_dir"
    
    # Create frontmatter
    local post_file="$post_dir/index.md"
    cat > "$post_file" << EOF
---
title: "$title"
slug: $slug
draft: true
description: "$description"
categories:
  - "$category"
images: [""]
EOF
    
    # Add series if provided
    if [ -n "$series" ]; then
        cat >> "$post_file" << EOF
series:
  - "$series"
EOF
    fi
    
    # Process and add keywords (always include field, even if empty)
    if [ -n "$keywords" ]; then
        # Convert comma-separated keywords to YAML array format
        local keyword_array=""
        IFS=',' read -ra keyword_list <<< "$keywords"
        for keyword in "${keyword_list[@]}"; do
            keyword=$(echo "$keyword" | sed 's/^[ \t]*//;s/[ \t]*$//')  # trim whitespace
            if [ -n "$keyword_array" ]; then
                keyword_array="${keyword_array}, \"$keyword\""
            else
                keyword_array="\"$keyword\""
            fi
        done
        cat >> "$post_file" << EOF
keywords: [$keyword_array]
EOF
    else
        cat >> "$post_file" << EOF
keywords: []
EOF
    fi
    
    cat >> "$post_file" << EOF
---

<!-- Featured image for social media -->
![Featured Image](./featured-image.webp)

## Introduction

## Main Content

## Conclusion

---

*Published in [Digital Sovereignty Chronicle](https://digitalsovereignty.herbertyang.xyz/) - Breaking down complex crypto concepts, exploring digital sovereignty, and sharing insights from the frontier of decentralized technology.*
EOF
    
    echo ""
    echo -e "${GREEN}✅ Draft created successfully!${NC}"
    echo -e "${BLUE}📁 Location:${NC} $post_dir"
    echo -e "${BLUE}📝 File:${NC} $post_file"
    echo ""
    echo -e "${PURPLE}Next steps:${NC}"
    echo -e "  1. Add images to the post directory"
    echo -e "  2. Write your content"
    echo -e "  3. Preview: cd /Users/zire/matrix/github_zire/digital-sovereignty && hugo server -D"
    echo -e "  4. Use 'Publish Draft' option when ready to publish"
    
    # Return the post file path for opening in editor
    POST_FILE_RESULT="$post_file"
    return 0
}

publish_dsc_draft() {
    echo -e "${BLUE}📤 Publishing DSC Draft${NC}"
    echo ""

    # List available drafts
    local drafts_dir="/Users/zire/matrix/github_zire/digital-sovereignty/content/posts/drafts"
    if [ ! -d "$drafts_dir" ] || [ -z "$(ls -A "$drafts_dir" 2>/dev/null)" ]; then
        echo -e "${RED}❌ No drafts found in $drafts_dir${NC}"
        return 1
    fi

    echo -e "${GREEN}Available drafts:${NC}"
    local draft_folders=()
    local count=1
    for draft in "$drafts_dir"/*; do
        if [ -d "$draft" ]; then
            local draft_name=$(basename "$draft")
            draft_folders+=("$draft_name")
            echo -e "  ${BLUE}$count.${NC} $draft_name"
            ((count++))
        fi
    done

    if [ ${#draft_folders[@]} -eq 0 ]; then
        echo -e "${RED}❌ No draft folders found${NC}"
        return 1
    fi

    echo ""
    printf "${GREEN}Select draft to publish (1-${#draft_folders[@]}):${NC} "
    read -r draft_choice

    # Validate choice
    if ! [[ "$draft_choice" =~ ^[0-9]+$ ]] || [ "$draft_choice" -lt 1 ] || [ "$draft_choice" -gt ${#draft_folders[@]} ]; then
        echo -e "${RED}❌ Invalid selection${NC}"
        return 1
    fi

    local selected_draft="${draft_folders[$((draft_choice-1))]}"
    local draft_path="$drafts_dir/$selected_draft"
    local draft_file="$draft_path/index.md"

    if [ ! -f "$draft_file" ]; then
        echo -e "${RED}❌ Draft file not found: $draft_file${NC}"
        return 1
    fi

    echo ""
    echo -e "${BLUE}Selected draft:${NC} $selected_draft"

    # Get publication date
    printf "${GREEN}Publication date${NC} ${GRAY}(YYYY-MM-DD format):${NC} "
    read -r pub_date

    # Validate date format
    if ! date -j -f "%Y-%m-%d" "$pub_date" "+%Y-%m-%d" >/dev/null 2>&1; then
        echo -e "${RED}❌ Invalid date format. Use YYYY-MM-DD${NC}"
        return 1
    fi

    # Extract date components
    local pub_year=$(echo "$pub_date" | cut -d'-' -f1)
    local pub_month=$(echo "$pub_date" | cut -d'-' -f2)
    local pub_day=$(echo "$pub_date" | cut -d'-' -f3)

    # Create target directory
    local target_dir="/Users/zire/matrix/github_zire/digital-sovereignty/content/posts/$pub_year/$pub_month/$pub_day-$selected_draft"

    # Check if target already exists
    if [ -d "$target_dir" ]; then
        echo -e "${RED}❌ Target directory already exists: $target_dir${NC}"
        echo -e "${YELLOW}💡 You may already have a post scheduled for this date${NC}"
        return 1
    fi

    # Create target directory
    mkdir -p "$target_dir"
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to create target directory${NC}"
        return 1
    fi

    # Copy draft content to target
    cp -r "$draft_path"/* "$target_dir/"
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to copy draft content${NC}"
        return 1
    fi

    # Update frontmatter with publication date and set draft: false
    local target_file="$target_dir/index.md"
    local iso_date="${pub_date}T12:00:00+00:00"

    # Read current frontmatter and content
    local temp_file=$(mktemp)

    # Add date field and set draft: false
    sed -e "/^title:/a\\
date: $iso_date" -e "s/^draft: true$/draft: false/" "$target_file" > "$temp_file"

    mv "$temp_file" "$target_file"

    echo ""
    echo -e "${GREEN}✅ Draft published successfully!${NC}"
    echo -e "${BLUE}📁 Published to:${NC} $target_dir"
    echo -e "${BLUE}📅 Publication date:${NC} $pub_date"
    echo ""

    # Ask if user wants to remove the draft
    printf "${YELLOW}Remove draft folder? [y/N]:${NC} "
    read -r remove_draft
    if [[ "$remove_draft" =~ ^[Yy]$ ]]; then
        rm -rf "$draft_path"
        echo -e "${GREEN}✅ Draft folder removed${NC}"
    else
        echo -e "${BLUE}ℹ️  Draft folder kept at: $draft_path${NC}"
    fi

    return 0
}

create_sb_frontmatter() {
    echo -e "${BLUE}📝 Creating new post for The Sunday Blender${NC}"
    echo ""
    
    # Title
    printf "${GREEN}Title:${NC} "
    read -r title
    if [ -z "$title" ]; then
        echo -e "${RED}Title is required.${NC}"
        return 1
    fi
    
    # Generate slug from title  
    local slug=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')
    printf "${GREEN}Slug${NC} ${GRAY}(auto-generated):${NC} $slug ${GRAY}[Enter to accept, or type new]:${NC} "
    read -r custom_slug
    if [ -n "$custom_slug" ]; then
        slug="$custom_slug"
    fi
    
    # Date (for Saturday publication)
    printf "${GREEN}Date${NC} ${GRAY}(YYYY-MM-DD format, or Enter for today):${NC} "
    read -r input_date
    
    if [ -z "$input_date" ]; then
        current_date=$(date +"%Y-%m-%d")
    else
        # Validate YYYY-MM-DD format and show day of week
        if date -j -f "%Y-%m-%d" "$input_date" "+%A, %B %d, %Y" >/dev/null 2>&1; then
            local day_info=$(date -j -f "%Y-%m-%d" "$input_date" "+%A, %B %d, %Y")
            echo -e "${BLUE}Publishing on: $day_info${NC}"
            current_date="$input_date"
        else
            echo -e "${RED}Invalid date format. Using today.${NC}"
            current_date=$(date +"%Y-%m-%d")
        fi
    fi
    
    # Description (optional for SB)
    printf "${GREEN}Description${NC} ${GRAY}(brief summary, optional):${NC} "
    read -r description
    
    # Tags (manual entry)
    echo ""
    printf "${GREEN}Tags${NC} ${GRAY}(comma-separated, default: news):${NC} "
    read -r tags
    if [ -z "$tags" ]; then
        tags="news"
    fi
    
    # Keywords (optional for SEO)
    printf "${GREEN}Keywords${NC} ${GRAY}(optional, comma-separated for SEO - can be added later):${NC} "
    read -r keywords
    
    # Generate directory structure (SB uses YYYY/MM/MMDD format)
    local current_year=$(date +%Y)
    local current_month=$(date +%m) 
    local current_day=$(date +%d)
    local post_dir="/Users/zire/matrix/github_zire/sundayblender/content/posts/$current_year/$current_month$current_day"
    
    # Check if directory exists
    if [ -d "$post_dir" ]; then
        echo -e "${YELLOW}⚠️  Directory already exists: $post_dir${NC}"
        printf "${BLUE}Continue anyway? [y/N]:${NC} "
        read -r continue_choice
        if [[ ! "$continue_choice" =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    # Create directory
    mkdir -p "$post_dir"
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to create directory: $post_dir${NC}"
        return 1
    fi
    
    # Create the post file
    local post_file="$post_dir/index.md"
    
    # Generate frontmatter and content with Previous Issues
    local previous_issues_content=$(generate_previous_issues)
    
    # Process keywords for frontmatter
    local keyword_field=""
    if [ -n "$keywords" ]; then
        # Convert comma-separated keywords to proper array format
        local keyword_array=""
        IFS=',' read -ra keyword_list <<< "$keywords"
        for keyword in "${keyword_list[@]}"; do
            keyword=$(echo "$keyword" | sed 's/^[ \t]*//;s/[ \t]*$//')  # trim whitespace
            if [ -n "$keyword_array" ]; then
                keyword_array="${keyword_array}, \"$keyword\""
            else
                keyword_array="\"$keyword\""
            fi
        done
        keyword_field="[$keyword_array]"
    else
        keyword_field="[]"
    fi

    cat > "$post_file" << POSTEOF
---
title: "$title"
date: $current_date
slug: $slug
description: "$description"
tags: [$tags]
keywords: $keyword_field
featured_image: ""
images: [""]
draft: true
---

## Tech

## Global

## Economy & Finance

## Nature & Environment

## Science

## Lifestyle, Entertainment & Culture

## Sports

## This Day in History

## Art of the Week

## Funny
$previous_issues_content

---

Thanks for reading! If you enjoy this newsletter, please share it with friends who might also find it interesting and refreshing, if not for themselves, at least for their kids.

POSTEOF
    
    echo -e "${GREEN}✅ Post created successfully!${NC}"
    echo -e "${BLUE}📁 Location: $post_dir${NC}"
    echo ""
    echo -e "${GRAY}Next steps:${NC}"
    echo -e "  1. Write your content in the editor"
    echo -e "  2. Set ${YELLOW}draft: false${NC} when ready to publish"
    echo -e "  3. Preview: cd $post_dir && hugo server -D"
    echo -e "  4. Publish when ready"
    
    # Return the post file path for opening in editor
    POST_FILE_RESULT="$post_file"
    return 0
}

create_hy_frontmatter() {
    echo -e "${BLUE}📝 Creating new post for Herbert Yang (Personal)${NC}"
    echo ""
    
    # Title
    printf "${GREEN}Title:${NC} "
    read -r title
    if [ -z "$title" ]; then
        echo -e "${RED}Title is required.${NC}"
        return 1
    fi
    
    # Generate slug from title
    local slug=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')
    printf "${GREEN}Slug${NC} ${GRAY}(auto-generated):${NC} $slug ${GRAY}[Enter to accept, or type new]:${NC} "
    read -r custom_slug
    if [ -n "$custom_slug" ]; then
        slug="$custom_slug"
    fi
    
    # Date (default to now)
    local current_date=$(date +"%Y-%m-%d")
    printf "${GREEN}Date${NC} ${GRAY}(YYYY-MM-DD, default: today):${NC} $current_date ${GRAY}[Enter to accept, or type new]:${NC} "
    read -r custom_date
    if [ -n "$custom_date" ]; then
        current_date="$custom_date"
    fi
    
    # Description
    printf "${GREEN}Description${NC} ${GRAY}(brief summary, optional):${NC} "
    read -r description
    
    # Tags (default: personal)
    printf "${GREEN}Tags${NC} ${GRAY}(comma-separated, default: personal):${NC} "
    read -r tags
    if [ -z "$tags" ]; then
        tags="personal"
    fi
    
    # Keywords (optional for SEO)
    printf "${GREEN}Keywords${NC} ${GRAY}(optional, comma-separated for SEO - can be added later):${NC} "
    read -r keywords
    
    # Convert comma-separated tags to array format
    local tag_array=""
    IFS=',' read -ra tag_list <<< "$tags"
    for tag in "${tag_list[@]}"; do
        tag=$(echo "$tag" | sed 's/^[ \t]*//;s/[ \t]*$//')  # trim whitespace
        if [ -n "$tag_array" ]; then
            tag_array="${tag_array}, \"$tag\""
        else
            tag_array="\"$tag\""
        fi
    done
    
    # Convert comma-separated keywords to array format
    local keyword_array=""
    if [ -n "$keywords" ]; then
        IFS=',' read -ra keyword_list <<< "$keywords"
        for keyword in "${keyword_list[@]}"; do
            keyword=$(echo "$keyword" | sed 's/^[ \t]*//;s/[ \t]*$//')  # trim whitespace
            if [ -n "$keyword_array" ]; then
                keyword_array="${keyword_array}, \"$keyword\""
            else
                keyword_array="\"$keyword\""
            fi
        done
    fi
    
    # Create directory structure based on date and slug (like DSC)
    local hy_path="/Users/zire/matrix/github_zire/herbertyang.xyz"
    local year=$(echo "$current_date" | cut -d'-' -f1)
    local post_dir="$hy_path/docusaurus/blog/$year/$current_date-$slug"
    local post_file="$post_dir/index.md"
    
    # Ensure post directory exists
    mkdir -p "$post_dir"
    
    # Create the post file with Docusaurus frontmatter
    cat > "$post_file" << EOF
---
title: $title
date: $current_date
tags: [$tag_array]
keywords: [$keyword_array]
draft: true
EOF
    
    # Add description if provided
    if [ -n "$description" ]; then
        cat >> "$post_file" << EOF
description: $description
EOF
    fi
    
    cat >> "$post_file" << EOF
---



---

*Originally published on [herbertyang.xyz/blog](https://herbertyang.xyz/blog)*
EOF
    
    echo ""
    echo -e "${GREEN}✅ Post created successfully!${NC}"
    echo -e "${BLUE}📝 File:${NC} $post_file"
    echo ""
    echo -e "${PURPLE}Next steps:${NC}"
    echo -e "  1. Write your content"
    echo -e "  2. Set ${YELLOW}draft: false${NC} when ready to publish"
    echo -e "  3. Preview: cd $hy_path/docusaurus && npm start"
    echo -e "  4. Publish when ready"
    
    # Return the post file path for opening in editor
    POST_FILE_RESULT="$post_file"
    return 0
}

# Export functions
export -f create_dsc_frontmatter
export -f publish_dsc_draft
export -f create_sb_frontmatter
export -f create_hy_frontmatter