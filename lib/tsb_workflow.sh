#!/bin/bash

# Flux - The Sunday Blender Workflow Automation
# Automates the 16-step publishing workflow for TSB

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

TSB_PATH="/Users/zire/matrix/github_zire/sundayblender"

# Check if required TSB commands are available
check_tsb_commands() {
    local missing=()

    if ! command -v tsb-make-pdf >/dev/null 2>&1; then
        missing+=("tsb-make-pdf")
    fi

    if ! command -v tsb-process-podcast >/dev/null 2>&1; then
        missing+=("tsb-process-podcast")
    fi

    if ! command -v tsb-generate-shownotes >/dev/null 2>&1; then
        missing+=("tsb-generate-shownotes")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Missing TSB commands: ${missing[*]}${NC}"
        echo -e "${YELLOW}💡 Install these commands to enable full automation${NC}"
        return 1
    fi

    return 0
}

# Step 3: Generate PDF using tsb-make-pdf command
generate_pdf() {
    local post_dir="$1"

    echo -e "${BLUE}📄 Step 3: Generating PDF...${NC}"

    cd "$post_dir" || return 1

    if ! command -v tsb-make-pdf >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  tsb-make-pdf command not found${NC}"
        echo -e "${BLUE}💡 Please generate PDF manually and press Enter when ready${NC}"
        read -r
        return 0
    fi

    if tsb-make-pdf; then
        echo -e "${GREEN}✅ PDF generated successfully${NC}"
        return 0
    else
        echo -e "${RED}❌ PDF generation failed${NC}"
        echo -ne "${BLUE}Continue anyway? [y/N]:${NC} "
        read -r confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            return 0
        else
            return 1
        fi
    fi
}

# Step 5: Process podcast audio
process_podcast() {
    local post_dir="$1"

    echo -e "${BLUE}🎙️  Step 5: Processing podcast audio...${NC}"

    cd "$post_dir" || return 1

    if ! command -v tsb-process-podcast >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  tsb-process-podcast command not found${NC}"
        echo -e "${BLUE}💡 Please process podcast manually and press Enter when ready${NC}"
        read -r
        return 0
    fi

    # Check if podcast file exists (look for .m4a or .mp3 files)
    local podcast_file=$(find "$post_dir" -name "*.m4a" -o -name "*.mp3" 2>/dev/null | head -1)

    if [ -z "$podcast_file" ]; then
        echo -e "${YELLOW}⚠️  No podcast audio file found (.m4a or .mp3)${NC}"
        echo -ne "${BLUE}Skip podcast processing? [Y/n]:${NC} "
        read -r skip
        if [[ ! "$skip" =~ ^[Nn]$ ]]; then
            return 0
        fi
    fi

    if tsb-process-podcast; then
        echo -e "${GREEN}✅ Podcast processed successfully${NC}"
        return 0
    else
        echo -e "${RED}❌ Podcast processing failed${NC}"
        echo -ne "${BLUE}Continue anyway? [y/N]:${NC} "
        read -r confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            return 0
        else
            return 1
        fi
    fi
}

# Step 6: Generate show notes
generate_shownotes() {
    local post_dir="$1"

    echo -e "${BLUE}📝 Step 6: Generating show notes...${NC}"

    cd "$post_dir" || return 1

    if ! command -v tsb-generate-shownotes >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  tsb-generate-shownotes command not found${NC}"
        echo -e "${BLUE}💡 Please generate show notes manually and press Enter when ready${NC}"
        read -r
        return 0
    fi

    if tsb-generate-shownotes; then
        echo -e "${GREEN}✅ Show notes generated successfully${NC}"
        return 0
    else
        echo -e "${RED}❌ Show notes generation failed${NC}"
        echo -ne "${BLUE}Continue anyway? [y/N]:${NC} "
        read -r confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            return 0
        else
            return 1
        fi
    fi
}

# Step 11: Merge PR automatically
merge_pr() {
    local pr_url="$1"

    echo -e "${BLUE}🔀 Step 11: Merging Pull Request...${NC}"

    if ! command -v gh >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  GitHub CLI (gh) not found${NC}"
        echo -e "${BLUE}💡 Please merge the PR manually at: $pr_url${NC}"
        echo -ne "${BLUE}Press Enter when PR is merged...${NC}"
        read -r
        return 0
    fi

    # Extract PR number from URL or use the latest PR
    cd "$TSB_PATH" || return 1

    echo -e "${BLUE}🔍 Finding PR to merge...${NC}"
    local pr_number=$(gh pr list --state open --limit 1 --json number --jq '.[0].number')

    if [ -z "$pr_number" ]; then
        echo -e "${YELLOW}⚠️  No open PR found${NC}"
        return 0
    fi

    echo -e "${BLUE}📋 PR #$pr_number details:${NC}"
    gh pr view "$pr_number"
    echo ""

    echo -ne "${BLUE}Merge PR #$pr_number now? [Y/n]:${NC} "
    read -r confirm

    if [[ ! "$confirm" =~ ^[Nn]$ ]]; then
        if gh pr merge "$pr_number" --squash --delete-branch; then
            echo -e "${GREEN}✅ PR merged successfully${NC}"
            return 0
        else
            echo -e "${RED}❌ PR merge failed${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  PR merge skipped${NC}"
        return 0
    fi
}

# Step 12: Delete remote and local branches
cleanup_branches() {
    local branch_name="$1"

    echo -e "${BLUE}🗑️  Step 12: Cleaning up branches...${NC}"

    cd "$TSB_PATH" || return 1

    # Switch to main branch first
    echo -e "${BLUE}🔄 Switching to main branch...${NC}"
    git checkout main || return 1

    # Pull latest changes
    echo -e "${BLUE}⬇️  Pulling latest changes...${NC}"
    git pull origin main || return 1

    # Delete local branch
    if git branch --list "$branch_name" | grep -q "$branch_name"; then
        echo -e "${BLUE}🗑️  Deleting local branch: $branch_name${NC}"
        git branch -D "$branch_name"
        echo -e "${GREEN}✅ Local branch deleted${NC}"
    fi

    # Check if remote branch still exists and delete
    if git ls-remote --heads origin "$branch_name" | grep -q "$branch_name"; then
        echo -e "${BLUE}🗑️  Deleting remote branch: $branch_name${NC}"
        git push origin --delete "$branch_name" 2>/dev/null || echo -e "${YELLOW}⚠️  Remote branch already deleted${NC}"
    fi

    return 0
}

# Step 13: Post announcement tweet
post_announcement_tweet() {
    local post_title="$1"
    local post_url="$2"

    echo -e "${BLUE}🐦 Step 13: Posting announcement tweet...${NC}"

    # Check if Twitter CLI is configured
    if ! command -v twitter >/dev/null 2>&1 && ! command -v twurl >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Twitter CLI not found (twitter or twurl)${NC}"
        echo -e "${BLUE}💡 Tweet template:${NC}"
        echo -e "${CYAN}New @SundayBlender edition: $post_title${NC}"
        echo -e "${CYAN}$post_url${NC}"
        echo ""
        echo -e "${BLUE}💡 Please post this tweet manually to @SundayBlender${NC}"
        echo -ne "${BLUE}Press Enter when done...${NC}"
        read -r
        return 0
    fi

    # TODO: Implement actual Twitter posting when credentials are configured
    echo -e "${YELLOW}⚠️  Automatic Twitter posting not yet configured${NC}"
    echo -e "${BLUE}💡 Tweet template:${NC}"
    echo -e "${CYAN}New @SundayBlender edition: $post_title${NC}"
    echo -e "${CYAN}$post_url${NC}"
    echo ""
    echo -ne "${BLUE}Post this tweet manually and press Enter when done...${NC}"
    read -r

    return 0
}

# Step 14: Execute Twitter bot scheduler
run_twitter_scheduler() {
    echo -e "${BLUE}🤖 Step 14: Running Twitter bot scheduler...${NC}"

    cd "$TSB_PATH" || return 1

    if [ ! -f "./scripts/schedule_tweets.sh" ]; then
        echo -e "${YELLOW}⚠️  Twitter scheduler script not found${NC}"
        echo -e "${BLUE}💡 Expected: $TSB_PATH/scripts/schedule_tweets.sh${NC}"
        echo -ne "${BLUE}Skip this step? [Y/n]:${NC} "
        read -r skip
        if [[ ! "$skip" =~ ^[Nn]$ ]]; then
            return 0
        else
            return 1
        fi
    fi

    echo -e "${BLUE}🚀 Executing ./scripts/schedule_tweets.sh...${NC}"

    if ./scripts/schedule_tweets.sh; then
        echo -e "${GREEN}✅ Twitter scheduler executed successfully${NC}"
        return 0
    else
        echo -e "${RED}❌ Twitter scheduler failed${NC}"
        echo -ne "${BLUE}Continue anyway? [y/N]:${NC} "
        read -r confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            return 0
        else
            return 1
        fi
    fi
}

# Step 15: Update progress tracking table
update_progress_tracking() {
    local post_date="$1"
    local post_title="$2"

    echo -e "${BLUE}📊 Step 15: Updating progress tracking table...${NC}"

    cd "$TSB_PATH" || return 1

    if [ ! -f "README.md" ]; then
        echo -e "${YELLOW}⚠️  README.md not found${NC}"
        return 0
    fi

    # TODO: Implement README progress table update
    # This would require parsing the README and adding a new row
    echo -e "${YELLOW}⚠️  Automatic progress tracking not yet implemented${NC}"
    echo -e "${BLUE}💡 Please update the progress tracking table in README.md manually${NC}"
    echo -e "${BLUE}📅 Date: $post_date${NC}"
    echo -e "${BLUE}📝 Title: $post_title${NC}"
    echo ""
    echo -ne "${BLUE}Press Enter when done...${NC}"
    read -r

    return 0
}

# Main TSB publish workflow
publish_tsb_edition() {
    local post_title="$1"

    if [ -z "$post_title" ]; then
        echo -e "${RED}❌ Post title required${NC}"
        return 1
    fi

    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║  ${BOLD}The Sunday Blender - Enhanced Publishing Workflow${NC}${PURPLE}              ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Generate slug from title
    local slug=$(echo "$post_title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')

    # Find the post file
    local post_file=$(find "$TSB_PATH/content/posts" -name "index.md" -exec grep -l "title: \"$post_title\"" {} \; 2>/dev/null | head -1)

    if [ -z "$post_file" ]; then
        echo -e "${RED}❌ Post not found: $post_title${NC}"
        return 1
    fi

    local post_dir=$(dirname "$post_file")
    echo -e "${BLUE}📁 Found post at: $post_dir${NC}"
    echo ""

    # Get publication date from frontmatter
    local pub_date=$(grep '^date:' "$post_file" | head -1 | sed 's/date: //' | sed 's/T.*//')

    # Workflow summary
    echo -e "${CYAN}📋 Workflow Steps:${NC}"
    echo -e "  ${GREEN}✓${NC} Step 1-2: Edit and preview (already done)"
    echo -e "  ${BLUE}→${NC} Step 3: Generate PDF"
    echo -e "  ${BLUE}→${NC} Step 4: Create podcast via NotebookLM (manual)"
    echo -e "  ${BLUE}→${NC} Step 5: Process podcast audio"
    echo -e "  ${BLUE}→${NC} Step 6: Generate show notes"
    echo -e "  ${BLUE}→${NC} Step 7-9: Update frontmatter, reorganize, commit & push"
    echo -e "  ${BLUE}→${NC} Step 10: Create pull request"
    echo -e "  ${BLUE}→${NC} Step 11: Merge PR"
    echo -e "  ${BLUE}→${NC} Step 12: Delete branches"
    echo -e "  ${BLUE}→${NC} Step 13: Post announcement tweet"
    echo -e "  ${BLUE}→${NC} Step 14: Execute Twitter bot scheduler"
    echo -e "  ${BLUE}→${NC} Step 15: Update progress tracking"
    echo ""
    echo -ne "${BLUE}Ready to start? [Y/n]:${NC} "
    read -r start_confirm

    if [[ "$start_confirm" =~ ^[Nn]$ ]]; then
        echo -e "${YELLOW}Workflow cancelled${NC}"
        return 1
    fi

    echo ""

    # Step 3: Generate PDF
    if ! generate_pdf "$post_dir"; then
        return 1
    fi
    echo ""

    # Step 4: Podcast creation (manual)
    echo -e "${BLUE}🎙️  Step 4: Create podcast via Google NotebookLM${NC}"
    echo -e "${YELLOW}💡 This is a manual step:${NC}"
    echo -e "  1. Upload the PDF to Google NotebookLM"
    echo -e "  2. Generate the audio podcast (.m4a)"
    echo -e "  3. Download and save to: $post_dir"
    echo ""
    echo -ne "${BLUE}Press Enter when podcast file is ready...${NC}"
    read -r
    echo ""

    # Step 5: Process podcast
    if ! process_podcast "$post_dir"; then
        return 1
    fi
    echo ""

    # Step 6: Generate show notes
    if ! generate_shownotes "$post_dir"; then
        return 1
    fi
    echo ""

    # Steps 7-9: Use existing publish_post function
    echo -e "${BLUE}📝 Steps 7-9: Finalizing post and publishing...${NC}"

    # Call the existing publish_post function from lib/publish.sh
    if ! publish_post "$post_title" "sb"; then
        echo -e "${RED}❌ Publishing failed${NC}"
        return 1
    fi
    echo ""

    # Step 10 is handled by publish_post (creates PR)
    # Capture the PR URL from the previous step
    local pr_url=$(gh pr list --limit 1 --json url --jq '.[0].url' 2>/dev/null)

    # Step 11: Merge PR
    if ! merge_pr "$pr_url"; then
        echo -e "${YELLOW}⚠️  PR merge failed or skipped${NC}"
        echo -e "${BLUE}💡 You can merge manually and run the remaining steps later${NC}"
        return 1
    fi
    echo ""

    # Step 12: Cleanup branches
    local current_branch=$(git branch --show-current)
    if ! cleanup_branches "$current_branch"; then
        echo -e "${YELLOW}⚠️  Branch cleanup failed${NC}"
    fi
    echo ""

    # Step 13: Post announcement tweet
    local post_url="https://weekly.sundayblender.com/p/$slug"
    if ! post_announcement_tweet "$post_title" "$post_url"; then
        echo -e "${YELLOW}⚠️  Tweet posting failed${NC}"
    fi
    echo ""

    # Step 14: Run Twitter scheduler
    if ! run_twitter_scheduler; then
        echo -e "${YELLOW}⚠️  Twitter scheduler failed${NC}"
    fi
    echo ""

    # Step 15: Update progress tracking
    if ! update_progress_tracking "$pub_date" "$post_title"; then
        echo -e "${YELLOW}⚠️  Progress tracking update failed${NC}"
    fi
    echo ""

    # Final summary
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ${BOLD}✅ Sunday Blender Edition Published Successfully!${NC}${GREEN}               ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${PURPLE}📊 Publication Summary:${NC}"
    echo -e "  📝 Title: $post_title"
    echo -e "  📅 Date: $pub_date"
    echo -e "  🌐 URL: $post_url"
    echo ""

    return 0
}

# Export functions
export -f check_tsb_commands
export -f generate_pdf
export -f process_podcast
export -f generate_shownotes
export -f merge_pr
export -f cleanup_branches
export -f post_announcement_tweet
export -f run_twitter_scheduler
export -f update_progress_tracking
export -f publish_tsb_edition
