#!/bin/bash

# Flux - Git Management Module
# Handles git operations for enhanced flux workflow

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
MAGENTA='\033[1;95m'  # Bright magenta for prominent display
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

# Configuration - load from sites.json
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$LIB_DIR/../config/sites.json"

# Get site path from config
get_site_path() {
    local site_code="$1"
    python3 -c "
import json
with open('$CONFIG_FILE') as f:
    config = json.load(f)
    print(config['sites']['$site_code']['path'])
" 2>/dev/null
}

# Check git status of a project
check_git_status() {
    local site_code="$1"
    local site_path=$(get_site_path "$site_code")

    if [ ! -d "$site_path" ]; then
        echo -e "${RED}❌ Site path not found: $site_path${NC}" >&2
        return 1
    fi

    if [ ! -d "$site_path/.git" ]; then
        echo -e "${YELLOW}⚠️  Not a git repository: $site_path${NC}" >&2
        return 1
    fi

    cd "$site_path" || return 1

    echo -e "${BLUE}📍 Git Status for $site_code at $site_path${NC}"
    echo ""

    # Current branch
    local current_branch=$(git branch --show-current 2>/dev/null)
    echo -e "${GREEN}Current branch:${NC} ${BOLD}${MAGENTA}$current_branch${NC}"

    # List recent branches (useful for finding drafts)
    echo -e "${GREEN}Recent branches:${NC}"
    git for-each-ref --sort=-committerdate refs/heads --format='  %(refname:short) (%(committerdate:relative))' | head -5

    # Check if there are uncommitted changes (both tracked and untracked)
    local status_output=$(git status --porcelain 2>/dev/null)
    if [ -n "$status_output" ]; then
        echo -e "${YELLOW}⚠️  Uncommitted changes detected:${NC}"
        echo "$status_output"
    else
        echo -e "${GREEN}✅ Working directory clean${NC}"
    fi

    # Check if ahead/behind remote
    local remote_status=$(git status --porcelain -b 2>/dev/null | head -1)
    if [[ "$remote_status" =~ \[ahead.*\] ]]; then
        echo -e "${YELLOW}⬆️  Local commits ahead of remote${NC}"
    elif [[ "$remote_status" =~ \[behind.*\] ]]; then
        echo -e "${YELLOW}⬇️  Local branch behind remote${NC}"
    fi

    echo ""
}

# Find latest draft branch or create new one
find_or_create_draft_branch() {
    local site_code="$1"
    local site_path=$(get_site_path "$site_code")

    cd "$site_path" || return 1

    # Remove stale remote branch references before displaying branches
    git remote prune origin &>/dev/null

    # Look for existing draft branches
    local draft_branches=$(git branch -a | grep -E "(draft|feature|post)" | head -5)

    if [ -n "$draft_branches" ]; then
        echo -e "${BLUE}🌿 Available draft/feature branches:${NC}"
        echo "$draft_branches"
        echo ""
        echo -e "${GREEN}1)${NC} Switch to existing branch"
        echo -e "${GREEN}2)${NC} Create new draft branch"
        echo -e "${GREEN}3)${NC} Stay on current branch"
        echo ""
        echo -ne "${BLUE}Choice [1-3]:${NC} "
        read -r branch_choice

        case "$branch_choice" in
            1)
                switch_to_existing_branch
                ;;
            2)
                create_new_draft_branch "$site_code"
                ;;
            3)
                echo -e "${BLUE}💡 Staying on current branch${NC}"
                ;;
        esac
    else
        echo -e "${YELLOW}🌿 No existing draft branches found${NC}"
        echo -e "${GREEN}1)${NC} Create new draft branch"
        echo -e "${GREEN}2)${NC} Stay on current branch"
        echo ""
        echo -ne "${BLUE}Choice [1-2]:${NC} "
        read -r choice

        if [ "$choice" = "1" ]; then
            create_new_draft_branch "$site_code"
        fi
    fi
}

# Switch to existing branch with selection menu
switch_to_existing_branch() {
    echo ""
    echo -e "${BLUE}🌿 Available branches:${NC}"
    echo ""

    # Get all local branches, exclude current branch
    local current_branch=$(git branch --show-current)
    local branches=($(git branch --format='%(refname:short)' | grep -v "^$current_branch$"))

    if [ ${#branches[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠️  No other branches available${NC}"
        return 1
    fi

    # Display numbered list of branches with commit info
    for i in "${!branches[@]}"; do
        local branch="${branches[$i]}"
        local last_commit=$(git log -1 --format="%cr" "$branch" 2>/dev/null)
        echo -e "  ${GREEN}$((i+1)))${NC} $branch ${GRAY}($last_commit)${NC}"
    done

    echo ""
    echo -e "  ${GREEN}q)${NC} Cancel"
    echo ""
    echo -ne "${BLUE}Select branch [1-${#branches[@]}, q]:${NC} "
    read -r selection

    # Handle selection
    if [[ "$selection" == "q" ]]; then
        echo -e "${BLUE}💡 Branch switch cancelled${NC}"
        return 0
    fi

    # Validate numeric input
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt ${#branches[@]} ]; then
        echo -e "${RED}❌ Invalid selection${NC}"
        return 1
    fi

    # Switch to selected branch
    local target_branch="${branches[$((selection-1))]}"
    git checkout "$target_branch" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Switched to branch: $target_branch${NC}"
    else
        echo -e "${RED}❌ Failed to switch to branch: $target_branch${NC}"
        return 1
    fi
}

# Create new draft branch
create_new_draft_branch() {
    local site_code="$1"
    local site_path=$(get_site_path "$site_code")

    cd "$site_path" || return 1

    # Generate branch name suggestion
    local date_stamp=$(date +%Y%m%d)
    local suggested_name="draft/$date_stamp"

    echo -ne "${BLUE}Draft branch name [${suggested_name}]:${NC} "
    read -r branch_name

    if [ -z "$branch_name" ]; then
        branch_name="$suggested_name"
    fi

    git checkout -b "$branch_name" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Created and switched to branch: $branch_name${NC}"
    else
        echo -e "${RED}❌ Failed to create branch: $branch_name${NC}"
    fi
}

# Auto-commit and push changes
auto_commit_session() {
    local site_code="$1"
    local session_type="$2"  # "draft" or "publish"
    local article_title="$3"
    local site_path=$(get_site_path "$site_code")

    cd "$site_path" || return 1

    # Check if there are changes to commit (both tracked and untracked)
    local status_output=$(git status --porcelain 2>/dev/null)
    if [ -z "$status_output" ]; then
        echo -e "${YELLOW}⚠️  No changes to commit${NC}"
        return 0
    fi

    echo -e "${BLUE}💾 Auto-committing session changes...${NC}"

    # Stage all changes
    git add -A

    # Generate commit message based on session type
    local commit_msg
    case "$session_type" in
        "draft")
            commit_msg="Draft progress: ${article_title:-Untitled}"
            ;;
        "publish")
            commit_msg="Ready for publish: ${article_title:-Untitled}"
            ;;
        *)
            commit_msg="Writing session: ${article_title:-Untitled}"
            ;;
    esac

    # Add standard footer
    commit_msg="${commit_msg}

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

    # Commit changes
    git commit -m "$commit_msg"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Changes committed successfully${NC}"

        # Ask about pushing
        echo -ne "${BLUE}Push to remote? [Y/n]:${NC} "
        read -r push_choice

        if [[ ! "$push_choice" =~ ^[Nn]$ ]]; then
            local current_branch=$(git branch --show-current)
            echo -e "${BLUE}📤 Pushing to remote...${NC}"
            git push -u origin "$current_branch" 2>/dev/null
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✅ Successfully pushed to remote repository${NC}"
                echo -e "${MAGENTA}${BOLD}🎯 Your commit is ready for merging!${NC}"
                echo -e "${CYAN}   Next step: Create a Pull Request on GitHub${NC}"
            else
                echo -e "${RED}❌ Failed to push to remote repository${NC}"
                echo -e "${YELLOW}⚠️  Changes are committed locally but not pushed${NC}"
            fi
        fi
    else
        echo -e "${RED}❌ Commit failed${NC}"
        return 1
    fi
}

# Enhanced session end with git operations
enhanced_session_end() {
    local post_file="$1"
    local site_code="$2"

    # Extract article title
    local article_title=""
    if [ -f "$post_file" ]; then
        article_title=$(grep 'title:' "$post_file" | sed 's/title: "//' | sed 's/"//' | head -1)
    fi

    echo ""
    echo -e "${PURPLE}📝 Enhanced writing session completed${NC}"
    echo -e "${GREEN}Article:${NC} ${article_title:-Untitled}"
    echo ""
    echo -e "${BLUE}🔧 Session completion options:${NC}"
    echo -e "  ${GREEN}1)${NC} Save draft progress (commit + push)"
    echo -e "  ${GREEN}2)${NC} Mark ready for publish (commit + push)"
    echo -e "  ${GREEN}3)${NC} Continue writing (no git action)"
    echo -e "  ${GREEN}4)${NC} Manual git operations"
    echo -e "  ${GREEN}q)${NC} End session (restore coding theme)"
    echo ""
    echo -ne "${BLUE}Your choice [1-4, q]:${NC} "
    read -r choice

    case "$choice" in
        1)
            auto_commit_session "$site_code" "draft" "$article_title"
            ;;
        2)
            # Mark ready for publish - handle date and draft flag for DSC
            if [[ "$site_code" == "dsc" ]]; then
                echo ""
                echo -e "${BLUE}📅 Preparing post for publication...${NC}"

                # Prompt for publication date
                printf "${GREEN}Publication date${NC} ${GRAY}(YYYY-MM-DD format):${NC} "
                read -r pub_date

                # Validate date format
                if ! date -j -f "%Y-%m-%d" "$pub_date" "+%Y-%m-%d" >/dev/null 2>&1; then
                    echo -e "${RED}❌ Invalid date format. Use YYYY-MM-DD${NC}"
                    echo -e "${YELLOW}⚠️  Skipping date update. You can set draft: false manually.${NC}"
                else
                    # Update frontmatter: replace placeholder date with real date and set draft: false
                    local iso_date="${pub_date}T12:00:00+08:00"
                    local temp_file=$(mktemp)

                    # Remove old date line, add new date after title, and set draft: false
                    sed -e "/^date:/d" -e "/^title:/a\\
date: $iso_date" -e "s/^draft: true$/draft: false/" "$post_file" > "$temp_file"

                    mv "$temp_file" "$post_file"

                    echo -e "${GREEN}✅ Frontmatter updated:${NC}"
                    echo -e "   - Publication date set to: $pub_date"
                    echo -e "   - ${MAGENTA}${BOLD}Draft flag changed to: false${NC}"
                fi
            else
                # For non-DSC sites, just change draft: false
                sed -i '' "s/^draft: true$/draft: false/" "$post_file" 2>/dev/null
                echo -e "${MAGENTA}${BOLD}✅ Draft flag changed to false${NC}"
            fi

            echo ""
            auto_commit_session "$site_code" "publish" "$article_title"
            ;;
        3)
            echo -e "${BLUE}💡 Continuing writing session...${NC}"
            echo -ne "${BLUE}Press any key when done writing...${NC}"
            read -r
            # After continuing, show the menu again
            enhanced_session_end "$post_file" "$site_code"
            return 0
            ;;
        4)
            echo -e "${BLUE}🔧 Opening git status for manual operations...${NC}"
            check_git_status "$site_code"
            echo ""
            echo -ne "${BLUE}Press any key when done with manual git operations...${NC}"
            read -r
            ;;
        q|*)
            echo -e "${YELLOW}📝 Session ended without git operations${NC}"
            ;;
    esac

    # Always end the writing session and restore theme (unless user chose to continue)
    source "$LIB_DIR/session.sh"
    end_writing_session
}

# Git-aware site selection
git_aware_site_selection() {
    local site_code="$1"

    echo -e "${CYAN}🌿 Initializing git-aware workflow for $site_code...${NC}"
    echo ""

    # Check git status
    check_git_status "$site_code"

    # Find or create draft branch
    find_or_create_draft_branch "$site_code"

    echo ""
    echo -e "${GREEN}✅ Git workflow initialized${NC}"
    echo -ne "${BLUE}Press any key to continue...${NC}"
    read -r
}

# Export functions
export -f get_site_path
export -f check_git_status
export -f find_or_create_draft_branch
export -f switch_to_existing_branch
export -f create_new_draft_branch
export -f auto_commit_session
export -f enhanced_session_end
export -f git_aware_site_selection