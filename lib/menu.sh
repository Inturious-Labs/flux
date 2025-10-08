#!/bin/bash

# Zettelkasten Writer - Interactive Menu System
# Focus: Digital Sovereignty Chronicle (other sites coming soon)

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color
BOLD='\033[1m'
DIM='\033[2m'

# Configuration
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$LIB_DIR/../config/sites.json"

show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}✍️  Zettelkasten Writer${NC} ${GRAY}- Multi-Site Content Management${NC}     ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_site_menu() {
    echo -e "${BLUE}📚 Select your publication:${NC}"
    echo ""
    echo -e "  ${GREEN}1)${NC} ${BOLD}Digital Sovereignty Chronicle${NC}"
    echo -e "     ${GRAY}└─ Crypto, AI, and digital sovereignty insights${NC}"
    echo ""
    echo -e "  ${GREEN}2)${NC} ${BOLD}The Sunday Blender${NC}"
    echo -e "     ${GRAY}└─ Making news interesting for kids${NC}"
    echo ""
    echo -e "  ${GREEN}3)${NC} ${BOLD}Herbert Yang (Personal)${NC}"
    echo -e "     ${GRAY}└─ Personal blog and thoughts${NC}"
    echo ""
    echo -e "  ${GRAY}4) Remnants of Globalization${NC} ${DIM}(coming soon)${NC}"
    echo -e "     ${GRAY}└─ Newsletter about global changes${NC}"
    echo ""
    echo -e "  ${YELLOW}q)${NC} Quit"
    echo ""
    echo -ne "${BLUE}Your choice [1-4, q]:${NC} "
}

get_dsc_drafts() {
    local dsc_path="/Users/zire/matrix/github_zire/digital-sovereignty"
    local drafts=()
    local count=0
    
    # Find all draft posts and collect with dates for sorting
    local temp_drafts=()
    
    # Search in both content/posts and content/posts/drafts folders
    local search_paths=(
        "$dsc_path/content/posts"
        "$dsc_path/content/posts/drafts"
    )
    
    for search_path in "${search_paths[@]}"; do
        if [ -d "$search_path" ]; then
            while IFS= read -r -d '' file; do
                if grep -q "draft: true" "$file" 2>/dev/null; then
                    local title=$(grep 'title:' "$file" | sed 's/title: "//' | sed 's/"//' | head -1)
                    local post_dir=$(dirname "$file")
                    local word_count=$(wc -w < "$file" | tr -d ' ')
                    
                    # Get creation date from frontmatter
                    local date_line=$(grep 'date:' "$file" | head -1)
                    local creation_date=$(echo "$date_line" | sed 's/date: //' | cut -d'T' -f1)
                    if [ -z "$creation_date" ]; then
                        creation_date="Unknown"
                    fi
                    
                    # Status icon based on word count
                    local icon="🟡"
                    if [ $word_count -lt 100 ]; then
                        icon="🔴"
                    elif [ $word_count -ge 600 ]; then
                        icon="🟢"
                    fi
                    
                    # Add location indicator - 💡 for content/posts/drafts/, 📅 for content/posts/
                    local location_icon="📅"
                    if [[ "$post_dir" == *"/content/posts/drafts/"* ]]; then
                        location_icon="💡"
                    fi
                    
                    # Check git status for this file
                    local git_status_icon=""
                    cd "$dsc_path" || continue
                    local relative_file="${file#$dsc_path/}"
                    local git_status=$(git status --porcelain "$relative_file" 2>/dev/null)
                    
                    if [ -n "$git_status" ]; then
                        # File has uncommitted changes
                        git_status_icon="*"
                    fi
                    
                    # Store with date for sorting: "date|title|word_count|icon|location_icon|git_status_icon|post_dir"
                    temp_drafts+=("$creation_date|$title|$word_count|$icon|$location_icon|$git_status_icon|$post_dir")
                fi
            done < <(find "$search_path" -name "index.md" -print0 2>/dev/null)
        fi
    done
    
    # Sort by date (newest first) and add sequential numbers
    count=0
    while IFS= read -r line; do
        count=$((count + 1))
        IFS='|' read -r date title word_count icon location_icon git_status_icon post_dir <<< "$line"
        drafts+=("$count|$title|$date|$word_count|$icon|$location_icon|$git_status_icon|$post_dir")
    done < <(printf '%s\n' "${temp_drafts[@]}" | sort -r)
    
    printf '%s\n' "${drafts[@]}"
}

get_sb_drafts() {
    local sb_path="/Users/zire/matrix/github_zire/sundayblender"
    local drafts=()
    local count=0
    
    # Find all draft posts and collect with dates for sorting
    local temp_drafts=()
    while IFS= read -r -d '' file; do
        if grep -q "draft: true" "$file" 2>/dev/null; then
            local title=$(grep 'title:' "$file" | sed 's/title: "//' | sed 's/"//' | head -1)
            local post_dir=$(dirname "$file")
            local word_count=$(wc -w < "$file" | tr -d ' ')
            
            # Get creation date from frontmatter
            local date_line=$(grep 'date:' "$file" | head -1)
            local creation_date=$(echo "$date_line" | sed 's/date: //' | cut -d'T' -f1)
            if [ -z "$creation_date" ]; then
                creation_date="Unknown"
            fi
            
            # Status icon based on word count (tailored for Sunday Blender's longer posts)
            local icon="🟡"
            if [ $word_count -lt 1000 ]; then
                icon="🔴"
            elif [ $word_count -ge 2000 ]; then
                icon="🟢"
            fi
            
            # Store with date for sorting: "date|title|word_count|icon|post_dir"
            temp_drafts+=("$creation_date|$title|$word_count|$icon|$post_dir")
        fi
    done < <(find "$sb_path/content/posts" -name "index.md" -print0 2>/dev/null)
    
    # Sort by date (newest first) and add sequential numbers
    count=0
    while IFS= read -r line; do
        count=$((count + 1))
        IFS='|' read -r date title word_count icon post_dir <<< "$line"
        drafts+=("$count|$title|$date|$word_count|$icon|$post_dir")
    done < <(printf '%s\n' "${temp_drafts[@]}" | sort -r)
    
    printf '%s\n' "${drafts[@]}"
}

get_dsc_completed() {
    local dsc_path="/Users/zire/matrix/github_zire/digital-sovereignty"
    local completed=()
    local count=0
    
    # Get list of files that have changes according to git status
    local modified_files=()
    
    # Get modified/tracked files from git status
    while IFS= read -r line; do
        # Parse git status output (format: "XY filename")
        local status_code="${line:0:2}"
        local filename="${line:3}"
        
        # Check if it's a modified index.md file
        if [[ "$filename" == *"index.md" && ("$status_code" == " M" || "$status_code" == "MM" || "$status_code" == "M " || "$status_code" == "A ") ]]; then
            modified_files+=("$dsc_path/$filename")
        fi
    done < <(cd "$dsc_path" && git status --porcelain 2>/dev/null)
    
    # Handle untracked directories that contain index.md files
    while IFS= read -r line; do
        local status_code="${line:0:2}"
        local filename="${line:3}"
        
        # If it's an untracked directory, check for index.md files inside
        if [[ "$status_code" == "??" && -d "$dsc_path/$filename" ]]; then
            while IFS= read -r -d '' file; do
                if [[ "$file" == *"/index.md" ]]; then
                    modified_files+=("$file")
                fi
            done < <(find "$dsc_path/$filename" -name "index.md" -print0 2>/dev/null)
        fi
    done < <(cd "$dsc_path" && git status --porcelain 2>/dev/null)
    
    # Check which modified files are marked as draft: false (completed but not published)
    local temp_completed=()
    for file in "${modified_files[@]}"; do
        if [ -f "$file" ] && grep -q "draft: false" "$file" 2>/dev/null; then
            local title=$(grep 'title:' "$file" | sed 's/title: "//' | sed 's/"//' | head -1)
            local post_dir=$(dirname "$file")
            local word_count=$(wc -w < "$file" | tr -d ' ')
            
            # Get creation date from frontmatter
            local date_line=$(grep 'date:' "$file" | head -1)
            local creation_date=$(echo "$date_line" | sed 's/date: //' | cut -d'T' -f1)
            if [ -z "$creation_date" ]; then
                creation_date="Unknown"
            fi
            
            # Green checkmark for completed posts ready to publish
            local icon="✅"
            
            # Store with date for sorting: "date|title|word_count|icon|post_dir"
            temp_completed+=("$creation_date|$title|$word_count|$icon|$post_dir")
        fi
    done
    
    # Sort by date (newest first) and add sequential numbers
    if [ ${#temp_completed[@]} -gt 0 ]; then
        count=0
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                count=$((count + 1))
                IFS='|' read -r date title word_count icon post_dir <<< "$line"
                completed+=("$count|$title|$date|$word_count|$icon|$post_dir")
            fi
        done < <(printf '%s\n' "${temp_completed[@]}" | sort -r)
    fi
    
    # Only print if we have actual completed posts
    if [ ${#completed[@]} -gt 0 ]; then
        printf '%s\n' "${completed[@]}"
    fi
}

get_sb_completed() {
    local sb_path="/Users/zire/matrix/github_zire/sundayblender"
    local completed=()
    local count=0
    
    # Get list of files that have changes according to git status
    local modified_files=()
    
    # Get modified/tracked files from git status
    while IFS= read -r line; do
        # Parse git status output (format: "XY filename")
        local status_code="${line:0:2}"
        local filename="${line:3}"
        
        # Check if it's a modified index.md file
        if [[ "$filename" == *"index.md" && ("$status_code" == " M" || "$status_code" == "MM" || "$status_code" == "M " || "$status_code" == "A ") ]]; then
            modified_files+=("$sb_path/$filename")
        fi
    done < <(cd "$sb_path" && git status --porcelain 2>/dev/null)
    
    # Handle untracked directories that contain index.md files
    while IFS= read -r line; do
        local status_code="${line:0:2}"
        local filename="${line:3}"
        
        # If it's an untracked directory, check for index.md files inside
        if [[ "$status_code" == "??" && -d "$sb_path/$filename" ]]; then
            while IFS= read -r -d '' file; do
                if [[ "$file" == *"/index.md" ]]; then
                    modified_files+=("$file")
                fi
            done < <(find "$sb_path/$filename" -name "index.md" -print0 2>/dev/null)
        fi
    done < <(cd "$sb_path" && git status --porcelain 2>/dev/null)
    
    # Check which modified files are marked as draft: false (completed but not published)
    local temp_completed=()
    for file in "${modified_files[@]}"; do
        if [ -f "$file" ] && grep -q "draft: false" "$file" 2>/dev/null; then
            local title=$(grep 'title:' "$file" | sed 's/title: "//' | sed 's/"//' | head -1)
            local post_dir=$(dirname "$file")
            local word_count=$(wc -w < "$file" | tr -d ' ')
            
            # Get creation date from frontmatter
            local date_line=$(grep 'date:' "$file" | head -1)
            local creation_date=$(echo "$date_line" | sed 's/date: //' | cut -d'T' -f1)
            if [ -z "$creation_date" ]; then
                creation_date="Unknown"
            fi
            
            # Green checkmark for completed posts ready to publish
            local icon="✅"
            
            # Store with date for sorting: "date|title|word_count|icon|post_dir"
            temp_completed+=("$creation_date|$title|$word_count|$icon|$post_dir")
        fi
    done
    
    # Sort by date (newest first) and add sequential numbers
    if [ ${#temp_completed[@]} -gt 0 ]; then
        count=0
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                count=$((count + 1))
                IFS='|' read -r date title word_count icon post_dir <<< "$line"
                completed+=("$count|$title|$date|$word_count|$icon|$post_dir")
            fi
        done < <(printf '%s\n' "${temp_completed[@]}" | sort -r)
    fi
    
    # Only print if we have actual completed posts
    if [ ${#completed[@]} -gt 0 ]; then
        printf '%s\n' "${completed[@]}"
    fi
}

get_hy_drafts() {
    local hy_path="/Users/zire/matrix/github_zire/herbertyang.xyz"
    local drafts=()
    local count=0
    
    # Find all draft posts and collect with dates for sorting
    local temp_drafts=()
    while IFS= read -r -d '' file; do
        if grep -q "draft: true" "$file" 2>/dev/null; then
            local title=$(grep 'title:' "$file" | sed 's/title: "//' | sed 's/"//' | head -1)
            local word_count=$(wc -w < "$file" | tr -d ' ')
            
            # Get creation date from frontmatter
            local date_line=$(grep 'date:' "$file" | head -1)
            local creation_date=$(echo "$date_line" | sed 's/date: //' | cut -d'T' -f1)
            if [ -z "$creation_date" ]; then
                creation_date="Unknown"
            fi
            
            # Status icon based on word count (tailored for personal blog posts)
            local icon="🟡"
            if [ $word_count -lt 200 ]; then
                icon="🔴"
            elif [ $word_count -ge 800 ]; then
                icon="🟢"
            fi
            
            # Store with date for sorting: "date|title|word_count|icon|post_dir"
            local post_dir=$(dirname "$file")
            temp_drafts+=("$creation_date|$title|$word_count|$icon|$post_dir")
        fi
    done < <(find "$hy_path/docusaurus/blog" -name "index.md" -print0 2>/dev/null)
    
    # Sort by date (newest first) and add sequential numbers
    count=0
    while IFS= read -r line; do
        count=$((count + 1))
        IFS='|' read -r date title word_count icon post_dir <<< "$line"
        drafts+=("$count|$title|$date|$word_count|$icon|$post_dir")
    done < <(printf '%s\n' "${temp_drafts[@]}" | sort -r)
    
    printf '%s\n' "${drafts[@]}"
}

get_hy_completed() {
    local hy_path="/Users/zire/matrix/github_zire/herbertyang.xyz"
    local completed=()
    local count=0
    
    # Get list of files that have changes according to git status
    local modified_files=()
    
    # Get modified/tracked files from git status
    while IFS= read -r line; do
        # Parse git status output (format: "XY filename")
        local status_code="${line:0:2}"
        local filename="${line:3}"
        
        # Check if it's a modified index.md file in docusaurus/blog directory
        if [[ "$filename" == docusaurus/blog/*/index.md && ("$status_code" == " M" || "$status_code" == "MM" || "$status_code" == "M " || "$status_code" == "A ") ]]; then
            modified_files+=("$hy_path/$filename")
        fi
    done < <(cd "$hy_path" && git status --porcelain 2>/dev/null)
    
    # Handle untracked directories that contain index.md files
    while IFS= read -r line; do
        local status_code="${line:0:2}"
        local filename="${line:3}"
        
        # If it's an untracked directory, check for index.md files inside
        if [[ "$status_code" == "??" && -d "$hy_path/$filename" && "$filename" == docusaurus/blog/* ]]; then
            while IFS= read -r -d '' file; do
                if [[ "$file" == *"/index.md" ]]; then
                    modified_files+=("$file")
                fi
            done < <(find "$hy_path/$filename" -name "index.md" -print0 2>/dev/null)
        fi
    done < <(cd "$hy_path" && git status --porcelain 2>/dev/null)
    
    # Check which modified files are marked as draft: false (completed but not published)
    local temp_completed=()
    for file in "${modified_files[@]}"; do
        if [ -f "$file" ] && grep -q "draft: false" "$file" 2>/dev/null; then
            local title=$(grep 'title:' "$file" | sed 's/title: "//' | sed 's/"//' | head -1)
            local word_count=$(wc -w < "$file" | tr -d ' ')
            
            # Get creation date from frontmatter
            local date_line=$(grep 'date:' "$file" | head -1)
            local creation_date=$(echo "$date_line" | sed 's/date: //' | cut -d'T' -f1)
            if [ -z "$creation_date" ]; then
                creation_date="Unknown"
            fi
            
            # Green checkmark for completed posts ready to publish
            local icon="✅"
            
            # Store with date for sorting: "date|title|word_count|icon|post_dir"
            local post_dir=$(dirname "$file")
            temp_completed+=("$creation_date|$title|$word_count|$icon|$post_dir")
        fi
    done
    
    # Sort by date (newest first) and add sequential numbers
    if [ ${#temp_completed[@]} -gt 0 ]; then
        count=0
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                count=$((count + 1))
                IFS='|' read -r date title word_count icon post_dir <<< "$line"
                completed+=("$count|$title|$date|$word_count|$icon|$post_dir")
            fi
        done < <(printf '%s\n' "${temp_completed[@]}" | sort -r)
    fi
    
    # Only print if we have actual completed posts
    if [ ${#completed[@]} -gt 0 ]; then
        printf '%s\n' "${completed[@]}"
    fi
}

show_action_menu() {
    local site_name="$1"
    local site_code="$2"
    
    echo -e "${PURPLE}📝 What would you like to do with ${CYAN}${BOLD}$site_name${NC}${PURPLE}?${NC}"
    echo ""
    
    # Show current drafts (site-specific)
    local drafts=()
    if [[ "$site_code" == "dsc" ]]; then
        while IFS= read -r line; do
            drafts+=("$line")
        done < <(get_dsc_drafts)
    elif [[ "$site_code" == "sb" ]]; then
        while IFS= read -r line; do
            drafts+=("$line")
        done < <(get_sb_drafts)
    elif [[ "$site_code" == "hy" ]]; then
        while IFS= read -r line; do
            drafts+=("$line")
        done < <(get_hy_drafts)
    fi
    
    
    if [ ${#drafts[@]} -gt 0 ]; then
        echo -e "${BLUE}📄 Select a draft to edit:${NC}"
        local j=1
        for draft in "${drafts[@]}"; do
            if [[ "$site_code" == "dsc" ]]; then
                IFS='|' read -r num title date words icon location_icon git_status_icon post_dir <<< "$draft"
                # Use red color for uncommitted drafts
                if [ -n "$git_status_icon" ]; then
                    printf "  ${GREEN}%2d)${NC} %s %s ${RED}${BOLD}%s${NC} ${RED}%s${NC} ${DIM}(%s words, created %s)${NC}\n" "$j" "$location_icon" "$icon" "$title" "$git_status_icon" "$words" "$date"
                else
                    printf "  ${GREEN}%2d)${NC} %s %s ${BOLD}%s${NC}%s ${DIM}(%s words, created %s)${NC}\n" "$j" "$location_icon" "$icon" "$title" "$git_status_icon" "$words" "$date"
                fi
            elif [[ "$site_code" == "sb" || "$site_code" == "hy" ]]; then
                IFS='|' read -r num title date words icon post_dir <<< "$draft"
                printf "  ${GREEN}%2d)${NC} %s ${BOLD}%s${NC} ${DIM}(%s words, created %s)${NC}\n" "$j" "$icon" "$title" "$words" "$date"
            fi
            j=$((j + 1))
        done
        echo ""
    fi
    
    # Show completed posts ready for publishing (site-specific)
    local completed=()
    if [[ "$site_code" == "dsc" ]]; then
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                completed+=("$line")
            fi
        done < <(get_dsc_completed)
    elif [[ "$site_code" == "sb" ]]; then
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                completed+=("$line")
            fi
        done < <(get_sb_completed)
    elif [[ "$site_code" == "hy" ]]; then
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                completed+=("$line")
            fi
        done < <(get_hy_completed)
    fi
    
    if [ ${#completed[@]} -gt 0 ]; then
        echo -e "${GREEN}✅ Posts ready to publish:${NC}"
        local letters="abcdefghijklmnopqrstuvwxyz"
        local letter_idx=0
        for comp in "${completed[@]}"; do
            if [ -n "$comp" ]; then
                IFS='|' read -r num title date words icon post_dir <<< "$comp"
                local letter="${letters:$letter_idx:1}"
                printf "  ${GREEN}%s)${NC} %s ${BOLD}%s${NC} ${DIM}(%s words, created %s)${NC}\n" "$letter" "$icon" "$title" "$words" "$date"
                letter_idx=$((letter_idx + 1))
            fi
        done
        echo ""
    fi
    
    echo -e "  ${GREEN}n)${NC} Create new post"
    if [ ${#completed[@]} -gt 0 ]; then
        echo -e "  ${GREEN}p)${NC} Publish completed post"
    fi
    if [ ${#drafts[@]} -gt 0 ]; then
        echo -e "  ${GREEN}d)${NC} Delete draft"
    fi
    
    # Check if there are drafts in drafts/ folder (DSC only)
    if [[ "$site_code" == "dsc" ]]; then
        local drafts_folder_count=0
        for draft in "${drafts[@]}"; do
            if [ -n "$draft" ]; then
                IFS='|' read -r num title date words icon location_icon git_status_icon post_dir <<< "$draft"
                if [[ "$post_dir" == *"/content/posts/drafts/"* ]]; then
                    drafts_folder_count=$((drafts_folder_count + 1))
                fi
            fi
        done
        
        if [ $drafts_folder_count -gt 0 ]; then
            echo -e "  ${CYAN}m)${NC} Publish draft (move to dated folder)"
        fi
    fi
    
    echo -e "  ${YELLOW}b)${NC} Back to site selection"
    echo -e "  ${YELLOW}q)${NC} Quit"
    echo ""
    echo -ne "${BLUE}Your choice:${NC} "
}

select_draft() {
    local action="$1" # "edit" or "publish"
    local site_code="$2" # "dsc", "sb", or "hy"
    # Re-get the drafts to ensure we have the current list (site-specific)
    local drafts=()
    if [[ "$site_code" == "dsc" ]]; then
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                drafts+=("$line")
            fi
        done < <(get_dsc_drafts)
    elif [[ "$site_code" == "sb" ]]; then
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                drafts+=("$line")
            fi
        done < <(get_sb_drafts)
    elif [[ "$site_code" == "hy" ]]; then
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                drafts+=("$line")
            fi
        done < <(get_hy_drafts)
    fi
    
    
    if [ ${#drafts[@]} -eq 0 ]; then
        echo -e "${YELLOW}No drafts found.${NC}"
        echo -ne "${BLUE}Press any key to continue...${NC}"
        read -r
        return 1
    fi
    
    echo -e "${BLUE}Select a draft to $action:${NC}" >&2
    echo "" >&2
    local i=1
    for draft in "${drafts[@]}"; do
        if [ -n "$draft" ]; then
            if [[ "$site_code" == "dsc" ]]; then
                IFS='|' read -r orig_num title date words icon location_icon git_status_icon post_dir <<< "$draft"
                # Use red color for uncommitted drafts
                if [ -n "$git_status_icon" ]; then
                    printf "  ${GREEN}%2d)${NC} %s %s ${RED}${BOLD}%s${NC} ${RED}%s${NC} ${DIM}(%s words, created %s)${NC}\n" "$i" "$location_icon" "$icon" "$title" "$git_status_icon" "$words" "$date" >&2
                else
                    printf "  ${GREEN}%2d)${NC} %s %s ${BOLD}%s${NC}%s ${DIM}(%s words, created %s)${NC}\n" "$i" "$location_icon" "$icon" "$title" "$git_status_icon" "$words" "$date" >&2
                fi
            elif [[ "$site_code" == "sb" || "$site_code" == "hy" ]]; then
                IFS='|' read -r orig_num title date words icon post_dir <<< "$draft"
                printf "  ${GREEN}%2d)${NC} %s ${BOLD}%s${NC} ${DIM}(%s words, created %s)${NC}\n" "$i" "$icon" "$title" "$words" "$date" >&2
            fi
            i=$((i + 1))
        fi
    done
    
    echo -e "  ${YELLOW}b)${NC} Back" >&2
    echo "" >&2
    echo -ne "${BLUE}Your choice [1-${#drafts[@]}, b]:${NC} " >&2
    
    read -r choice
    
    if [[ "$choice" == "b" || "$choice" == "back" ]]; then
        return 1
    elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#drafts[@]} ]; then
        local selected_draft="${drafts[$((choice-1))]}"
        if [ -z "$selected_draft" ]; then
            return 1
        fi
        if [[ "$site_code" == "dsc" ]]; then
            IFS='|' read -r num title date word_count icon location_icon git_status_icon post_dir <<< "$selected_draft"
            echo "$post_dir/index.md"
        elif [[ "$site_code" == "sb" ]]; then
            IFS='|' read -r num title date word_count icon post_dir <<< "$selected_draft"
            echo "$post_dir/index.md"
        elif [[ "$site_code" == "hy" ]]; then
            IFS='|' read -r num title date word_count icon post_dir <<< "$selected_draft"
            # For HY site, post_dir now contains the folder path, need index.md
            echo "$post_dir/index.md"
        fi
        return 0
    else
        echo -e "${RED}Invalid selection.${NC}" >&2
        echo -ne "${BLUE}Press any key to continue...${NC}" >&2
        read -r
        return 1
    fi
}

select_completed() {
    local site_code="$1"
    # Get the list of completed posts ready for publishing (site-specific)
    local completed=()
    if [[ "$site_code" == "dsc" ]]; then
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                completed+=("$line")
            fi
        done < <(get_dsc_completed)
    elif [[ "$site_code" == "sb" ]]; then
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                completed+=("$line")
            fi
        done < <(get_sb_completed)
    elif [[ "$site_code" == "hy" ]]; then
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                completed+=("$line")
            fi
        done < <(get_hy_completed)
    fi
    
    if [ ${#completed[@]} -eq 0 ]; then
        echo -e "${YELLOW}No completed posts ready for publishing.${NC}"
        echo -ne "${BLUE}Press any key to continue...${NC}"
        read -r
        return 1
    fi
    
    echo -e "${BLUE}Select a post to publish:${NC}" >&2
    echo "" >&2
    local i=1
    for post in "${completed[@]}"; do
        if [ -n "$post" ]; then
            IFS='|' read -r orig_num title date words icon post_dir <<< "$post"
            printf "  ${GREEN}%2d)${NC} %s %s (%s words, created %s)\n" "$i" "$icon" "$title" "$words" "$date" >&2
            i=$((i + 1))
        fi
    done
    
    echo -e "  ${YELLOW}b)${NC} Back" >&2
    echo "" >&2
    echo -ne "${BLUE}Your choice [1-${#completed[@]}, b]:${NC} " >&2
    
    read -r choice
    
    if [[ "$choice" == "b" || "$choice" == "back" ]]; then
        return 1
    elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#completed[@]} ]; then
        local selected_post="${completed[$((choice-1))]}"
        if [ -z "$selected_post" ]; then
            return 1
        fi
        if [[ "$site_code" == "hy" ]]; then
            IFS='|' read -r num title date words icon post_dir <<< "$selected_post"
            echo "$post_dir/index.md"
        else
            IFS='|' read -r num title date words icon post_dir <<< "$selected_post"
            echo "$post_dir/index.md"
        fi
        return 0
    else
        echo -e "${RED}Invalid selection.${NC}" >&2
        echo -ne "${BLUE}Press any key to continue...${NC}" >&2
        read -r
        return 1
    fi
}

select_draft_for_deletion() {
    local site_code="$1"
    # Get the list of drafts (site-specific)
    local drafts=()
    if [[ "$site_code" == "dsc" ]]; then
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                drafts+=("$line")
            fi
        done < <(get_dsc_drafts)
    elif [[ "$site_code" == "sb" ]]; then
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                drafts+=("$line")
            fi
        done < <(get_sb_drafts)
    elif [[ "$site_code" == "hy" ]]; then
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                drafts+=("$line")
            fi
        done < <(get_hy_drafts)
    fi
    
    if [ ${#drafts[@]} -eq 0 ]; then
        echo -e "${YELLOW}No drafts found to delete.${NC}"
        echo -ne "${BLUE}Press any key to continue...${NC}"
        read -r
        return 1
    fi
    
    echo -e "${RED}⚠️  Select a draft to DELETE (this cannot be undone):${NC}" >&2
    echo "" >&2
    local i=1
    for draft in "${drafts[@]}"; do
        if [ -n "$draft" ]; then
            IFS='|' read -r orig_num title date words icon post_dir <<< "$draft"
            printf "  ${GREEN}%2d)${NC} %s %s (%s words, created %s)\n" "$i" "$icon" "$title" "$words" "$date" >&2
            i=$((i + 1))
        fi
    done
    
    echo -e "  ${YELLOW}b)${NC} Back" >&2
    echo "" >&2
    echo -ne "${BLUE}Your choice [1-${#drafts[@]}, b]:${NC} " >&2
    
    read -r choice
    
    if [[ "$choice" == "b" || "$choice" == "back" ]]; then
        return 1
    elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#drafts[@]} ]; then
        local selected_draft="${drafts[$((choice-1))]}"
        if [ -z "$selected_draft" ]; then
            return 1
        fi
        if [[ "$site_code" == "dsc" ]]; then
            IFS='|' read -r num title date words icon location_icon git_status_icon post_dir <<< "$selected_draft"
            local path_to_delete="$post_dir"
        elif [[ "$site_code" == "hy" ]]; then
            IFS='|' read -r num title date words icon post_dir <<< "$selected_draft"
            local path_to_delete="$post_dir"
        else
            IFS='|' read -r num title date words icon post_dir <<< "$selected_draft"
            local path_to_delete="$post_dir"
        fi
        
        # Confirmation prompt
        echo "" >&2
        echo -e "${RED}⚠️  Are you sure you want to DELETE this draft?${NC}" >&2
        echo -e "     ${BOLD}Title:${NC} $title" >&2
        echo -e "     ${BOLD}Path:${NC} $path_to_delete" >&2
        echo "" >&2
        echo -ne "${RED}Type 'DELETE' to confirm (or anything else to cancel):${NC} " >&2
        read -r confirm
        
        if [[ "$confirm" == "DELETE" ]]; then
            echo "$path_to_delete"
            return 0
        else
            echo -e "${BLUE}Deletion cancelled.${NC}" >&2
            echo -ne "${BLUE}Press any key to continue...${NC}" >&2
            read -r
            return 1
        fi
    else
        echo -e "${RED}Invalid selection.${NC}" >&2
        echo -ne "${BLUE}Press any key to continue...${NC}" >&2
        read -r
        return 1
    fi
}

select_draft_for_promotion() {
    local site_code="$1"
    # Only works for DSC currently
    if [[ "$site_code" != "dsc" ]]; then
        echo -e "${RED}Draft promotion is only available for Digital Sovereignty Chronicle${NC}"
        return 1
    fi
    
    # Get drafts that are in the drafts/ folder only
    local dsc_path="/Users/zire/matrix/github_zire/digital-sovereignty"
    local drafts=()
    local count=0
    
    while IFS= read -r -d '' file; do
        local post_dir=$(dirname "$file")
        # Only include drafts from content/posts/drafts/ folder
        if [[ "$post_dir" == *"/content/posts/drafts/"* ]] && grep -q "draft: true" "$file" 2>/dev/null; then
            local title=$(grep 'title:' "$file" | sed 's/title: "//' | sed 's/"//' | head -1)
            local word_count=$(wc -w < "$file" | tr -d ' ')
            
            local date_line=$(grep 'date:' "$file" | head -1)
            local creation_date=$(echo "$date_line" | sed 's/date: //' | cut -d'T' -f1)
            if [ -z "$creation_date" ]; then
                creation_date="Unknown"
            fi
            
            local icon="🟡"
            if [ $word_count -lt 100 ]; then
                icon="🔴"
            elif [ $word_count -ge 600 ]; then
                icon="🟢"
            fi
            
            # Check git status for this file
            local git_status_icon=""
            cd "$dsc_path" || continue
            local relative_file="${file#$dsc_path/}"
            local git_status=$(git status --porcelain "$relative_file" 2>/dev/null)
            
            if [ -n "$git_status" ]; then
                git_status_icon="*"
            fi
            
            count=$((count + 1))
            drafts+=("$count|$title|$creation_date|$word_count|$icon|💡|$git_status_icon|$post_dir")
        fi
    done < <(find "$dsc_path/content/posts/drafts" -name "index.md" -print0 2>/dev/null)
    
    if [ ${#drafts[@]} -eq 0 ]; then
        echo -e "${YELLOW}No drafts found in drafts/ folder for promotion.${NC}"
        echo -ne "${BLUE}Press any key to continue...${NC}"
        read -r
        return 1
    fi
    
    echo -e "${CYAN}⬆️  Select a draft to promote to content/posts/:${NC}" >&2
    echo "" >&2
    local i=1
    for draft in "${drafts[@]}"; do
        if [ -n "$draft" ]; then
            IFS='|' read -r orig_num title date words icon location_icon git_status_icon post_dir <<< "$draft"
            # Use red color for uncommitted drafts
            if [ -n "$git_status_icon" ]; then
                printf "  ${GREEN}%2d)${NC} %s %s ${RED}${BOLD}%s${NC} ${RED}%s${NC} ${DIM}(%s words, created %s)${NC}\n" "$i" "$location_icon" "$icon" "$title" "$git_status_icon" "$words" "$date" >&2
            else
                printf "  ${GREEN}%2d)${NC} %s %s ${BOLD}%s${NC}%s ${DIM}(%s words, created %s)${NC}\n" "$i" "$location_icon" "$icon" "$title" "$git_status_icon" "$words" "$date" >&2
            fi
            i=$((i + 1))
        fi
    done
    
    echo -e "  ${YELLOW}b)${NC} Back" >&2
    echo "" >&2
    echo -ne "${BLUE}Your choice [1-${#drafts[@]}, b]:${NC} " >&2
    
    read -r choice
    
    if [[ "$choice" == "b" || "$choice" == "back" ]]; then
        return 1
    elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#drafts[@]} ]; then
        local selected_draft="${drafts[$((choice-1))]}"
        if [ -z "$selected_draft" ]; then
            return 1
        fi
        IFS='|' read -r num title date word_count icon location_icon git_status_icon post_dir <<< "$selected_draft"
        echo "$post_dir"
        return 0
    else
        echo -e "${RED}Invalid selection.${NC}" >&2
        echo -ne "${BLUE}Press any key to continue...${NC}" >&2
        read -r
        return 1
    fi
}

# Export functions for use by main script
export -f show_header
export -f show_site_menu  
export -f show_action_menu
export -f get_dsc_drafts
export -f get_dsc_completed
export -f get_sb_drafts
export -f get_sb_completed
export -f get_hy_drafts
export -f get_hy_completed
export -f select_draft
export -f select_completed
export -f select_draft_for_deletion
export -f select_draft_for_promotion