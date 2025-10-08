#!/bin/bash

# Zettelkasten Writer - Cursor Editor Integration
# Optimized for Cursor with markdown preview and writing theme

# Load theme management
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/themes.sh"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
RED='\033[0;31m'
NC='\033[0m'

open_in_cursor() {
    local file_path="$1"
    
    if [ ! -f "$file_path" ]; then
        echo -e "${RED}❌ File not found: $file_path${NC}"
        return 1
    fi
    
    echo -e "${BLUE}📝 Opening in Cursor with side-by-side markdown preview...${NC}"
    echo -e "${PURPLE}💡 Setting up optimal writing environment${NC}"
    echo ""
    
    # Switch to writing theme first
    switch_to_writing_theme
    
    # Check if Cursor is installed
    if command -v cursor > /dev/null 2>&1; then
        # Open file in Cursor editor (not agent)
        cursor editor "$file_path"
        
        # Give Cursor a moment to start
        sleep 2
        
        # Try to set up side-by-side view via AppleScript (macOS)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            osascript -e 'tell application "Cursor" to activate' 2>/dev/null || true
            sleep 1

            # Reload window to apply theme changes (Cmd+R)
            osascript -e 'tell application "System Events" to keystroke "r" using {command down}' 2>/dev/null || true
            sleep 1

            # Hide explorer panel (Cmd+Shift+E)
            osascript -e 'tell application "System Events" to keystroke "e" using {command down, shift down}' 2>/dev/null || true
            sleep 1

            # Open markdown preview to the side (Cmd+K V) - this opens preview in a new editor group to the right
            osascript -e 'tell application "System Events" to keystroke "k" using {command down}' 2>/dev/null || true
            sleep 0.5
            osascript -e 'tell application "System Events" to keystroke "v"' 2>/dev/null || true
            sleep 1

            # Focus back to left pane (Cmd+1)
            osascript -e 'tell application "System Events" to keystroke "1" using {command down}' 2>/dev/null || true
        fi
        
        echo -e "${GREEN}✅ Cursor opened with side-by-side preview${NC}"
        
    else
        echo -e "${RED}❌ Cursor not found!${NC}"
        echo -e "${YELLOW}Please install Cursor from https://cursor.sh/${NC}"
        echo -e "${BLUE}📝 File location: $file_path${NC}"
        return 1
    fi
    
    echo ""
    echo -e "${PURPLE}📋 Writing environment ready:${NC}"
    echo -e "  • Normal window size with clean interface"
    echo -e "  • Editor on left, preview on right"
    echo -e "  • Explorer panel hidden for focus"
    echo -e "  • 💡 Close the redundant index.md tab in right pane"
    echo -e "  • Type 'img' + Tab for image insertion"
    echo -e "  • Type 'figure' + Tab for captioned images"  
    echo -e "  • AI assistance with Cmd+K"
    echo -e "  • Code Spell Checker for grammar and spelling"
    echo ""
    echo -e "${BLUE}💾 Auto-save is enabled - your changes are preserved${NC}"
    
    return 0
}

show_writing_session_commands() {
    echo -e "${PURPLE}📝 Writing Session Active${NC}"
    echo ""
    echo -e "${BLUE}💡 When you're done writing, return to this terminal and use the session options to save or publish.${NC}"
    echo ""
    echo -e "${GREEN}✨ Single-window workflow - no need for multiple terminals!${NC}"
}

# Export functions
export -f open_in_cursor
export -f show_writing_session_commands