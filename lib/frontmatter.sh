#!/bin/bash

# Flux - Smart Frontmatter Wizard
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
date: 2099-12-31T00:00:00+08:00
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
enable_rapport: true
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
    local iso_date="${pub_date}T12:00:00+08:00"

    # Read current frontmatter and content
    local temp_file=$(mktemp)

    # Remove any existing date field, then add the publication date and set draft: false
    sed -e "/^date:/d" -e "/^title:/a\\
date: $iso_date" -e "s/^draft: true$/draft: false/" "$target_file" > "$temp_file"

    mv "$temp_file" "$target_file"

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}  ${BOLD}✅ Article Published - Folder Moved${NC}                              ${GREEN}║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}📂 FROM:${NC} ${DIM}$draft_path${NC}"
    echo -e "${BLUE}📂 TO:${NC}   ${BOLD}$target_dir${NC}"
    echo ""
    echo -e "${BLUE}📅 Publication date:${NC} $pub_date"
    echo -e "${BLUE}📝 Status:${NC} draft: false"
    echo ""

    # Ask if user wants to empty the draft folder
    printf "${YELLOW}Empty drafts/ folder? [y/N]:${NC} "
    read -r remove_draft
    if [[ "$remove_draft" =~ ^[Yy]$ ]]; then
        rm -rf "$draft_path"
        echo -e "${GREEN}✅ Drafts folder emptied${NC}"
        echo ""
    else
        echo -e "${BLUE}ℹ️  Draft folder kept at: $draft_path${NC}"
        echo ""
    fi

    # Now perform automated git workflow
    echo -e "${BLUE}🔄 Starting automated git workflow...${NC}"
    echo ""

    # Change to the DSC repository
    cd "/Users/zire/matrix/github_zire/digital-sovereignty" || {
        echo -e "${RED}❌ Failed to change to DSC repository${NC}"
        return 1
    }

    # Get current branch
    local current_branch=$(git branch --show-current)
    echo -e "${BLUE}📍 Current branch:${NC} $current_branch"

    # Stage all changes (the new dated folder and deletion of draft folder if applicable)
    echo -e "${BLUE}📦 Staging changes...${NC}"
    git add "$target_dir"
    if [[ "$remove_draft" =~ ^[Yy]$ ]]; then
        git add -u .  # Stage deletions
    fi

    # Commit the changes
    local title=$(grep 'title:' "$target_file" | sed 's/title: "//' | sed 's/"//' | head -1)
    local word_count=$(wc -w < "$target_file" | tr -d ' ')

    echo -e "${BLUE}💾 Committing changes...${NC}"
    git commit -m "Ready for publish: $title

Moved from drafts/$selected_draft to dated folder for $pub_date publication.
📝 $word_count words
📅 Scheduled for $pub_date

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to commit changes${NC}"
        return 1
    fi

    # Push the current branch
    echo -e "${BLUE}📤 Pushing to remote...${NC}"
    git push -u origin "$current_branch"

    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to push to remote${NC}"
        return 1
    fi

    # Create PR from current branch to main
    echo ""
    echo -e "${BLUE}🔀 Creating Pull Request to main...${NC}"

    if ! command -v gh >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  GitHub CLI (gh) not found. Skipping automated workflow.${NC}"
        echo -e "${YELLOW}Please complete manually:${NC}"
        echo -e "${GRAY}  1. Create PR: $current_branch -> main${NC}"
        echo -e "${GRAY}  2. Wait for deployment to succeed${NC}"
        echo -e "${GRAY}  3. Merge the PR${NC}"
        echo -e "${GRAY}  4. git checkout main && git pull${NC}"
        echo -e "${GRAY}  5. git branch -d $current_branch${NC}"
        echo -e "${GRAY}  6. git checkout drafts/writing-pad && git merge main${NC}"
        return 0
    fi

    local pr_url=$(gh pr create --base main --head "$current_branch" \
        --title "Publish: $title" \
        --body "## Summary
Publishing article scheduled for $pub_date

- Moved from drafts to dated folder
- Word count: $word_count
- Publication date: $pub_date

## Checklist
- [x] Article moved to dated folder structure
- [x] Frontmatter updated with publication date
- [x] Draft status set to false

🤖 Generated with [Claude Code](https://claude.com/claude-code)" 2>&1 | grep -o 'https://github.com[^ ]*' | head -1)

    if [ -z "$pr_url" ]; then
        echo -e "${YELLOW}⚠️  Could not create PR automatically${NC}"
        echo -e "${YELLOW}Please create PR manually: ${BOLD}$current_branch -> main${NC}"
        return 0
    fi

    echo -e "${GREEN}✅ Pull Request created: $pr_url${NC}"
    echo ""

    # Poll GitHub Actions status
    echo -e "${BLUE}⏳ Waiting for GitHub Actions deployment to complete...${NC}"
    echo -e "${GRAY}   (typically takes 25-30 seconds)${NC}"
    echo ""

    local elapsed=0
    local check_interval=5
    local max_wait=180  # 3 minutes max

    while [ $elapsed -lt $max_wait ]; do
        sleep $check_interval
        elapsed=$((elapsed + check_interval))

        # Check PR checks status
        local checks_status=$(gh pr checks "$pr_url" --json state,name 2>/dev/null)

        if [ -z "$checks_status" ]; then
            printf "\r${BLUE}⏳ Waiting for checks to start... (${elapsed}s)${NC}                    "
            continue
        fi

        # Parse the status - check if all checks are successful or if any failed
        local failed_count=$(echo "$checks_status" | grep -c '"state":"FAILURE"' || true)
        local pending_count=$(echo "$checks_status" | grep -c '"state":"PENDING"' || true)
        local success_count=$(echo "$checks_status" | grep -c '"state":"SUCCESS"' || true)

        if [ "$failed_count" -gt 0 ]; then
            echo ""
            echo -e "${RED}❌ GitHub Actions deployment failed!${NC}"
            echo -e "${YELLOW}Please check: $pr_url${NC}"
            echo ""
            echo -e "${YELLOW}PR created but not merged. Fix issues and merge manually.${NC}"
            return 1
        elif [ "$pending_count" -eq 0 ] && [ "$success_count" -gt 0 ]; then
            echo ""
            echo -e "${GREEN}✅ GitHub Actions deployment successful! (${elapsed}s)${NC}"
            break
        else
            printf "\r${BLUE}⏳ Deployment in progress... (${elapsed}s)${NC}                    "
        fi
    done

    if [ $elapsed -ge $max_wait ]; then
        echo ""
        echo -e "${YELLOW}⚠️  Deployment is taking longer than expected${NC}"
        echo -e "${YELLOW}Please check status manually: $pr_url${NC}"
        return 1
    fi

    echo ""

    # Now safe to merge the PR
    echo -e "${BLUE}🔀 Merging Pull Request...${NC}"
    gh pr merge "$pr_url" --squash --delete-branch

    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to merge PR${NC}"
        echo -e "${YELLOW}Please merge manually: $pr_url${NC}"
        return 1
    fi

    echo -e "${GREEN}✅ Pull Request merged successfully${NC}"
    echo ""

    # Give GitHub a moment to process the merge and delete remote branch
    echo -e "${BLUE}⏳ Waiting for GitHub to process merge...${NC}"
    sleep 3

    # Switch to main branch
    echo -e "${BLUE}🌿 Switching to main branch...${NC}"
    git checkout main

    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to checkout main branch${NC}"
        return 1
    fi

    # Pull latest changes (includes the merged PR)
    echo -e "${BLUE}⬇️  Pulling latest changes from remote...${NC}"
    git pull

    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to pull from remote${NC}"
        return 1
    fi

    # Delete the local publish branch (remote already deleted by PR merge)
    if git show-ref --verify --quiet "refs/heads/$current_branch"; then
        echo -e "${BLUE}🗑️  Deleting local publish branch: $current_branch${NC}"
        git branch -d "$current_branch" 2>/dev/null || git branch -D "$current_branch"
    fi

    # Switch to drafts/writing-pad branch
    echo -e "${BLUE}🌿 Switching to drafts/writing-pad branch...${NC}"
    git checkout drafts/writing-pad

    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to checkout drafts/writing-pad branch${NC}"
        echo -e "${YELLOW}You may need to manually checkout and merge main${NC}"
        return 1
    fi

    # Merge main into drafts/writing-pad to keep it updated
    echo -e "${BLUE}🔄 Merging main into drafts/writing-pad...${NC}"
    git merge main -m "Merge main: Update drafts branch with published article

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to merge main into drafts/writing-pad${NC}"
        echo -e "${YELLOW}You may need to resolve conflicts manually${NC}"
        return 1
    fi

    # Push the updated drafts/writing-pad branch
    echo -e "${BLUE}📤 Pushing updated drafts/writing-pad branch...${NC}"
    git push origin drafts/writing-pad

    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to push drafts/writing-pad${NC}"
        return 1
    fi

    # Extract slug for the live URL
    local slug=$(grep '^slug:' "$target_file" | sed 's/slug: //' | tr -d ' ')

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}  ${BOLD}✅ Complete! Article Published & Git Workflow Done${NC}               ${GREEN}║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}✅ Article deployed successfully${NC}"
    echo -e "${GREEN}✅ PR merged to main${NC}"
    echo -e "${GREEN}✅ Remote publish branch deleted${NC}"
    echo -e "${GREEN}✅ Local branches cleaned up${NC}"
    echo -e "${GREEN}✅ drafts/writing-pad updated with latest changes${NC}"
    echo ""
    echo -e "${BLUE}📍 Current branch:${NC} drafts/writing-pad"
    echo -e "${BLUE}🌐 Article is live at:${NC} ${BOLD}https://digitalsovereignty.herbertyang.xyz/p/$slug${NC}"
    echo ""

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
    local post_dir="/Users/zire/matrix/github_zire/sundayblender/content/posts/$current_year/$current_month/$current_month$current_day"
    
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
enable_rapport: true
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

    # Create img/ subdirectory for images
    mkdir -p "$post_dir/img"

    # Create the post file with Docusaurus frontmatter
    cat > "$post_file" << EOF
---
title: $title
date: $current_date
tags: [$tag_array]
keywords: [$keyword_array]
draft: true
image: "./img/featured-image.jpg"
enable_rapport: true
EOF

    # Add description if provided
    if [ -n "$description" ]; then
        cat >> "$post_file" << EOF
description: $description
EOF
    fi

    cat >> "$post_file" << EOF
---

[Add your preview text here - this will appear on the blog index page]

![Image Description](./img/featured-image.jpg)

<!-- truncate -->

<!--
SOCIAL MEDIA PREVIEW IMAGE:
The 'image' field in the frontmatter (image: "./img/featured-image.jpg")
controls the preview image for Twitter/Facebook/LinkedIn sharing.

Image requirements for social media preview (Twitter/Open Graph):
- Recommended dimensions: 1200x630px (2:1 aspect ratio)
- Alternative: 1200x675px (16:9 aspect ratio)
- Minimum: 300x157px
- Maximum: 4096x4096px
- File size: Under 5MB
- Format: JPG, PNG, or WebP
-->

## Main Content

Write your article content here.

---

*Originally published on [herbertyang.xyz/blog](https://herbertyang.xyz/blog)*
EOF
    
    echo ""
    echo -e "${GREEN}✅ Post created successfully!${NC}"
    echo -e "${BLUE}📝 File:${NC} $post_file"
    echo -e "${BLUE}📁 Images folder:${NC} $post_dir/img"
    echo ""
    echo -e "${PURPLE}⚡ Twitter/OG Preview Image (set in frontmatter 'image' field):${NC}"
    echo -e "  ${YELLOW}Recommended:${NC} 1200x630px (2:1 ratio) or 1200x675px (16:9)"
    echo -e "  ${GRAY}Min: 300x157px | Max: 4096x4096px | Size: <5MB${NC}"
    echo -e "  ${GRAY}This image appears when sharing on Twitter, Facebook, LinkedIn, etc.${NC}"
    echo ""
    echo -e "${PURPLE}Next steps:${NC}"
    echo -e "  1. Add featured image to: ${YELLOW}$post_dir/img/featured-image.jpg${NC}"
    echo -e "     ${GRAY}(This is set as the social preview via frontmatter 'image' field)${NC}"
    echo -e "  2. Replace preview placeholder text"
    echo -e "  3. Write your article content"
    echo -e "  4. Set ${YELLOW}draft: false${NC} when ready to publish"
    echo -e "  5. Preview: cd $hy_path/docusaurus && npm start"
    
    # Return the post file path for opening in editor
    POST_FILE_RESULT="$post_file"
    return 0
}

# Export functions
export -f create_dsc_frontmatter
export -f publish_dsc_draft
export -f create_sb_frontmatter
export -f create_hy_frontmatter