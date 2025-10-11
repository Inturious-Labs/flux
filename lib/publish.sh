#!/bin/bash

# Zettelkasten Writer - Publishing & Draft Management
# For Digital Sovereignty Chronicle

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

DSC_PATH="/Users/zire/matrix/github_zire/digital-sovereignty"

save_draft_progress() {
    local post_title="$1"
    
    if [ -z "$post_title" ]; then
        echo -e "${RED}❌ Post title required${NC}"
        return 1
    fi
    
    echo -e "${BLUE}💾 Saving draft progress: $post_title${NC}"
    
    # Generate slug from title
    local slug=$(echo "$post_title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')
    
    # Find the post file - first try by slug in both content/posts and drafts
    local post_file=$(find "$DSC_PATH/content/posts" "$DSC_PATH/drafts" -name "index.md" -exec grep -l "slug: $slug" {} \; 2>/dev/null | head -1)
    
    # If not found by slug, try searching by title
    if [ -z "$post_file" ]; then
        post_file=$(find "$DSC_PATH/content/posts" "$DSC_PATH/drafts" -name "index.md" -exec grep -l "title: \"$post_title\"" {} \; 2>/dev/null | head -1)
    fi
    
    if [ -z "$post_file" ]; then
        echo -e "${RED}❌ Post not found: $post_title${NC}"
        echo -e "${YELLOW}💡 Searched for slug '$slug' and title '$post_title' in both content/posts and drafts${NC}"
        return 1
    fi
    
    local post_dir=$(dirname "$post_file")
    
    # Verify it's still a draft
    if ! grep -q "draft: true" "$post_file"; then
        echo -e "${YELLOW}⚠️  Post is not marked as draft${NC}"
    fi
    
    # Change to DSC directory
    cd "$DSC_PATH" || return 1
    
    # Git operations
    echo -e "${BLUE}🔄 Git operations...${NC}"
    
    # Add the post directory
    git add "$post_dir"
    
    # Check if there are changes
    if git diff --staged --quiet; then
        echo -e "${YELLOW}⚠️  No changes to save${NC}"
    else
        # Get word count
        local word_count=$(wc -w < "$post_file" | tr -d ' ')
        
        # Commit with progress info
        git commit -m "Draft progress: $post_title ($word_count words)

🚧 Work in progress - not ready for publication

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
        
        echo -e "${BLUE}📤 Pushing to remote...${NC}"
        git push origin HEAD
        
        echo -e "${GREEN}✅ Draft progress saved successfully!${NC}"
        echo -e "${BLUE}📊 Word count: $word_count${NC}"
    fi
    
    return 0
}

publish_post() {
    local post_title="$1"
    local site_code="${2:-dsc}"  # Default to DSC for backwards compatibility

    if [ -z "$post_title" ]; then
        echo -e "${RED}❌ Post title required${NC}"
        return 1
    fi

    echo -e "${BLUE}🚀 Publishing post: $post_title${NC}"

    # Set site path based on site code
    local site_path
    case "$site_code" in
        "sb")
            site_path="/Users/zire/matrix/github_zire/sundayblender"
            ;;
        "hy")
            site_path="/Users/zire/matrix/github_zire/herbertyang.xyz"
            ;;
        "dsc"|*)
            site_path="$DSC_PATH"
            ;;
    esac

    # Generate slug from title
    local slug=$(echo "$post_title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')

    # Find the post file - search in content/posts for all sites
    local post_file=$(find "$site_path/content/posts" -name "index.md" -exec grep -l "slug: $slug" {} \; 2>/dev/null | head -1)

    if [ -z "$post_file" ]; then
        echo -e "${RED}❌ Post not found: $post_title${NC}"
        echo -e "${YELLOW}💡 Searched for slug '$slug' in $site_path/content/posts${NC}"
        return 1
    fi
    
    local post_dir=$(dirname "$post_file")
    
    echo -e "${BLUE}📁 Location: $post_dir${NC}"
    
    # Set draft to false
    if grep -q "draft: true" "$post_file"; then
        echo -e "${BLUE}📝 Setting draft: false${NC}"
        sed -i '' 's/draft: true/draft: false/' "$post_file"
    fi
    
    # Verify required fields
    echo -e "${BLUE}🔍 Verifying post...${NC}"
    
    local errors=0
    
    if ! grep -q "title:" "$post_file"; then
        echo -e "${RED}❌ Missing title${NC}"
        errors=$((errors + 1))
    fi
    
    if ! grep -q "date:" "$post_file"; then
        echo -e "${RED}❌ Missing date${NC}"
        errors=$((errors + 1))
    fi
    
    if ! grep -q "categories:" "$post_file"; then
        echo -e "${YELLOW}⚠️  No categories found${NC}"
    fi
    
    # Check word count
    local word_count=$(wc -w < "$post_file" | tr -d ' ')
    if [ "$word_count" -lt 100 ]; then
        echo -e "${YELLOW}⚠️  Post is very short ($word_count words)${NC}"
        echo -ne "${BLUE}Continue publishing? [y/N]:${NC} "
        read -r confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Publication cancelled${NC}"
            return 1
        fi
    fi
    
    if [ "$errors" -gt 0 ]; then
        echo -e "${RED}❌ Cannot publish with $errors error(s)${NC}"
        return 1
    fi
    
    # Check for images
    local image_count=$(find "$post_dir" -name "*.webp" -o -name "*.jpg" -o -name "*.png" 2>/dev/null | wc -l | tr -d ' ')
    echo -e "${BLUE}🖼️  Images found: $image_count${NC}"
    
    # Final confirmation
    echo ""
    echo -e "${PURPLE}📊 Publication Summary:${NC}"
    echo -e "  Title: $(grep 'title:' "$post_file" | sed 's/title: "//' | sed 's/"//')"
    echo -e "  Category: $(grep -A1 'categories:' "$post_file" | tail -1 | sed 's/.*"\(.*\)".*/\1/' 2>/dev/null || echo 'none')"
    echo -e "  Word count: $word_count"
    echo -e "  Images: $image_count"
    echo ""
    echo -ne "${BLUE}Publish this post? [Y/n]:${NC} "
    read -r final_confirm
    
    if [[ "$final_confirm" =~ ^[Nn]$ ]]; then
        echo -e "${YELLOW}Publication cancelled${NC}"
        # Restore draft status
        sed -i '' 's/draft: false/draft: true/' "$post_file"
        return 1
    fi
    
    # Change to site directory
    cd "$site_path" || return 1

    # Git operations
    echo -e "${BLUE}🔄 Publishing...${NC}"

    # Add the post directory
    git add "$post_dir"

    # Check for related PDF in static/pdf/ and add if exists
    local pdf_pattern="static/pdf/*${slug}*.pdf"
    if ls $pdf_pattern 2>/dev/null | grep -q .; then
        echo -e "${BLUE}📄 Found related PDF files, adding to commit...${NC}"
        git add static/pdf/*${slug}*.pdf 2>/dev/null || true
    fi

    # Stage any deletions (like old draft posts)
    echo -e "${BLUE}🗑️  Staging deletions...${NC}"
    git add -u .

    # Commit
    git commit -m "Publish: $post_title

📝 $word_count words
🖼️ $image_count images
🏷️ $(grep -A1 'categories:' "$post_file" | tail -1 | sed 's/.*"\(.*\)".*/\1/' 2>/dev/null || echo 'general')

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"

    echo -e "${BLUE}📤 Pushing to remote...${NC}"
    git push origin HEAD

    echo -e "${GREEN}✅ Post published successfully!${NC}"
    echo -e "${GREEN}🚀 GitHub Actions will deploy automatically${NC}"

    # Show post URL based on site
    local post_slug=$(grep "slug:" "$post_file" | sed 's/slug: //' | tr -d ' ')
    case "$site_code" in
        "sb")
            echo -e "${GREEN}📧 RSS feed will update and trigger Buttondown${NC}"
            echo -e "${GREEN}🌐 Post URL: https://weekly.sundayblender.com/p/$post_slug${NC}"
            ;;
        "hy")
            echo -e "${GREEN}🌐 Post URL: https://herbertyang.xyz/blog/$post_slug${NC}"
            ;;
        "dsc"|*)
            echo -e "${GREEN}📧 RSS feed will update and trigger Buttondown${NC}"
            echo -e "${GREEN}🌐 Post URL: https://digitalsovereignty.herbertyang.xyz/p/$post_slug${NC}"
            ;;
    esac
    
    return 0
}

delete_draft() {
    local post_dir="$1"
    
    if [ -z "$post_dir" ]; then
        echo -e "${RED}❌ Post directory required${NC}"
        return 1
    fi
    
    if [ ! -d "$post_dir" ]; then
        echo -e "${RED}❌ Directory not found: $post_dir${NC}"
        return 1
    fi
    
    # Get post title for commit message
    local post_file="$post_dir/index.md"
    local title="Unknown"
    if [ -f "$post_file" ]; then
        title=$(grep 'title:' "$post_file" | sed 's/title: "//' | sed 's/"//' | head -1)
    fi
    
    echo -e "${RED}🗑️  Deleting draft: $title${NC}"
    echo -e "${BLUE}📁 Location: $post_dir${NC}"
    
    # Change to DSC directory
    cd "$DSC_PATH" || return 1
    
    # Convert absolute path to relative path for git
    local relative_path=$(realpath --relative-to="$DSC_PATH" "$post_dir" 2>/dev/null || echo "${post_dir#$DSC_PATH/}")
    
    echo -e "${BLUE}🔄 Git operations...${NC}"
    
    # Check if the directory is tracked by git
    if git ls-files --error-unmatch "$relative_path" >/dev/null 2>&1; then
        # Directory is tracked, use git rm
        git rm -r "$relative_path"
        
        # Commit the deletion
        git commit -m "Delete draft: $title

🗑️ Draft removed from version control

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
        
        echo -e "${BLUE}📤 Pushing to remote...${NC}"
        git push origin HEAD
        
        echo -e "${GREEN}✅ Draft deleted and changes pushed!${NC}"
    else
        # Directory is not tracked, just remove it
        rm -rf "$post_dir"
        echo -e "${GREEN}✅ Untracked draft deleted!${NC}"
    fi
    
    return 0
}

start_preview() {
    echo -e "${BLUE}🌐 Starting local preview server...${NC}"
    echo -e "${PURPLE}💡 Preview will be available at: http://localhost:1313${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop the preview server${NC}"
    echo ""
    
    cd "$DSC_PATH" || return 1
    hugo server -D --bind 0.0.0.0 --baseURL http://localhost:1313
}

promote_draft() {
    local draft_dir="$1"
    
    if [ -z "$draft_dir" ] || [ ! -d "$draft_dir" ]; then
        echo -e "${RED}❌ Invalid draft directory${NC}"
        return 1
    fi
    
    local draft_file="$draft_dir/index.md"
    if [ ! -f "$draft_file" ]; then
        echo -e "${RED}❌ Draft file not found: $draft_file${NC}"
        return 1
    fi
    
    # Extract title and slug from draft
    local title=$(grep 'title:' "$draft_file" | sed 's/title: "//' | sed 's/"//' | head -1)
    local slug=$(grep 'slug:' "$draft_file" | sed 's/slug: //' | head -1)
    
    if [ -z "$title" ] || [ -z "$slug" ]; then
        echo -e "${RED}❌ Could not extract title or slug from draft${NC}"
        return 1
    fi
    
    echo -e "${CYAN}⬆️  Promoting draft: ${BOLD}$title${NC}"
    echo ""
    
    # Ask for publication date
    echo -e "${BLUE}📅 Set publication date for this post:${NC}"
    echo -ne "${BLUE}Enter date (YYYY-MM-DD) or press Enter for today:${NC} "
    read -r pub_date
    
    if [ -z "$pub_date" ]; then
        pub_date=$(date +%Y-%m-%d)
    fi
    
    # Validate date format
    if ! date -j -f "%Y-%m-%d" "$pub_date" >/dev/null 2>&1; then
        echo -e "${RED}❌ Invalid date format. Use YYYY-MM-DD${NC}"
        return 1
    fi
    
    # Create target directory path
    local year=$(echo "$pub_date" | cut -d'-' -f1)
    local month=$(echo "$pub_date" | cut -d'-' -f2)
    local day=$(echo "$pub_date" | cut -d'-' -f3)
    local target_dir="$DSC_PATH/content/posts/$year/$month/$day-$slug"
    
    # Check if target already exists
    if [ -d "$target_dir" ]; then
        echo -e "${RED}❌ Target directory already exists: $target_dir${NC}"
        return 1
    fi
    
    echo -e "${BLUE}📂 Creating: $target_dir${NC}"
    mkdir -p "$target_dir"
    
    # Update date in frontmatter and set draft: false
    echo -e "${BLUE}📝 Updating frontmatter...${NC}"
    sed -i '' "s/^date: .*/date: ${pub_date}T$(date +%H:%M:%S)+00:00/" "$draft_file"
    sed -i '' 's/^draft: true/draft: false/' "$draft_file"
    
    # Copy all files from draft directory to target
    echo -e "${BLUE}📋 Copying files...${NC}"
    cp -r "$draft_dir"/* "$target_dir/"
    
    # Confirm the move
    echo ""
    echo -e "${YELLOW}⚠️  Ready to complete promotion. This will:${NC}"
    echo -e "  • Move draft from: ${DIM}$draft_dir${NC}"
    echo -e "  • To publish location: ${DIM}$target_dir${NC}"
    echo -e "  • Delete original draft folder${NC}"
    echo ""
    echo -ne "${BLUE}Continue with promotion? [Y/n]:${NC} "
    read -r confirm
    
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        echo -e "${YELLOW}❌ Promotion cancelled. Cleaning up...${NC}"
        rm -rf "$target_dir"
        # Revert changes to draft file
        git checkout -- "$draft_file" 2>/dev/null || true
        return 1
    fi
    
    # Remove original draft directory
    echo -e "${BLUE}🗑️  Removing original draft...${NC}"
    rm -rf "$draft_dir"
    
    # Stage the changes but DON'T commit yet - let the user publish when ready
    echo -e "${BLUE}📚 Staging changes (ready for publish)...${NC}"
    cd "$DSC_PATH" || return 1
    
    git add "$target_dir"
    git add -u . # Stage deletions
    
    echo ""
    echo -e "${GREEN}✅ Draft promoted successfully!${NC}"
    echo -e "${PURPLE}📂 New location: $target_dir${NC}"
    echo -e "${PURPLE}📅 Publication date: $pub_date${NC}"
    
    return 0
}

# Export functions
export -f save_draft_progress
export -f publish_post
export -f delete_draft
export -f start_preview
export -f promote_draft