# Flux

> A unified, interactive workflow for writing and publishing across multiple websites simultaneously

## Overview

Flux is a centralized writing workflow that manages content creation across multiple Hugo-based websites with a single command-line interface. Inspired by the Zettelkasten method of interconnected knowledge management, it provides a seamless experience for writers who maintain multiple publication channels.

## Features

### 🌐 Multi-Site Management
- Handle multiple websites from one interface
- Supports Digital Sovereignty Chronicle, The Sunday Blender, and Herbert Yang sites
- Centralized configuration and workflow

### 📝 Interactive Menus
- Step-by-step guided workflow
- Direct selection by numbers (drafts) and letters (completed posts)
- Consistent color-coded interface (green for actions, yellow for navigation)

### 🤖 Smart Content Management
- **Create** (`n`) - New posts with frontmatter wizard and sensible defaults
- **Edit** (`1-99`) - Direct draft selection by number for immediate editing
- **Publish** (`a-z`) - Direct completed post selection by letter for publishing
- **Delete** (`d`) - Safe deletion with git history and confirmation

### 📁 Draft Management
- Visual status indicators: 🔴 (< 100 words), 🟡 (100-599 words), 🟢 (600+ words)
- Date-based sorting (newest first)
- Word count tracking and creation date display
- Git-based detection for publish-ready posts (draft: false + uncommitted changes)

### 🌿 **NEW: Enhanced Git Integration**
- **Automatic git status checking** when selecting sites
- **Smart branch management** - find existing draft branches or create new ones
- **Auto-commit & push** with pre-canned commit messages
- **Session-aware workflow** - commit progress or mark ready for publish
- **Real-time change detection** for both tracked and untracked files
- **Branch history display** showing recent branches with timestamps

### 🚀 One-Click Publishing
- Automated git workflow with descriptive commits
- Automatic deployment via existing CI/CD pipelines
- Post validation and confirmation prompts
- SEO-optimized URLs and metadata

### ✏️ Cursor Integration
- **Session-based theme switching**: Paper theme for writing, code theme for development
- Automated side-by-side markdown preview setup
- AppleScript automation for optimal writing layout
- Auto-save and spell checking integration

### 💾 Version Control
- Git integration for all operations (create, edit, publish, delete)
- Descriptive commit messages with Claude Code attribution
- Proper handling of tracked and untracked files
- Full history preservation for content lifecycle

## Supported Sites

- **✅ Digital Sovereignty Chronicle** - Crypto, AI, and digital sovereignty insights
- **✅ The Sunday Blender** - Making news interesting for kids (with enhanced 16-step workflow automation)
- **✅ Herbert Yang (Personal)** - Personal blog and thoughts
- **🔄 Remnants of Globalization** - Newsletter about global changes *(coming soon)*

## Quick Start

```bash
# Interactive writing session (with automatic git management)
./flux

# Quick commands
./flux save "Post Title"     # Save draft progress to git
./flux publish "Post Title"  # Publish completed post
./flux status               # Show all drafts across sites
./flux git [site]           # Check git status for specific site (dsc|sb|hy)
./flux help                 # Show all available commands
```

## Installation

1. **Clone this repository**
   ```bash
   git clone https://github.com/zire/flux.git
   cd flux
   ```

2. **Make scripts executable**
   ```bash
   chmod +x flux
   chmod +x lib/*.sh
   ```

3. **Configure your site paths**
   Edit `config/sites.json` with your website repository paths and settings

4. **Install Cursor editor**
   Download from [cursor.sh](https://cursor.sh) and install the Code Spell Checker extension

5. **Start writing**
   ```bash
   ./flux
   ```

## Workflow

### Complete Writing Lifecycle

1. **Launch** - Run `./flux` from anywhere
2. **Select Site** - Choose from your configured websites with automatic git status check
3. **Branch Management** - Automatically find existing draft branches or create new ones
4. **Choose Action**:
   - **New post** (`n`) - Create with frontmatter wizard
   - **Edit draft** (`1-99`) - Direct number selection
   - **Publish** (`a-z`) - Direct letter selection for completed posts
   - **Delete draft** (`d`) - Safe removal with git history
5. **Write in Cursor** - Automatic theme switching and layout setup
6. **Session Completion** - Enhanced options with automatic git operations:
   - Save draft progress (auto-commit + push)
   - Mark ready for publish (auto-commit + push)
   - Continue writing (no git action)
   - Manual git operations (for advanced users)

### Draft Status Flow

```
🔴 New Draft (< 100 words)
    ↓ (continue writing)
🟡 In Progress (100-599 words)
    ↓ (continue writing)
🟢 Substantial Draft (600+ words)
    ↓ (set draft: false)
✅ Ready to Publish (appears in completed section)
    ↓ (press a-z or use 'p' menu)
🚀 Published (committed to git, deployed automatically)
```

### 🆕 Draft-First Workflow for DSC

Digital Sovereignty Chronicle now supports a **draft-first workflow** designed for Zettelkasten-style parallel writing:

#### Writing Workshop Branch Structure
```
main (infrastructure + published content)
├── feature/infrastructure-changes (Hugo themes, configs, etc.)
└── drafts/writing-pad (persistent writing branch)
    ├── content/posts/drafts/crypto-regulation-analysis/
    ├── content/posts/drafts/ai-sovereignty-framework/
    ├── content/posts/drafts/decentralized-identity-deep-dive/
    └── ... (multiple parallel drafts)
```

#### Workflow Steps

1. **Draft Creation** - Posts start in `content/posts/drafts/slug/` without date constraints
2. **Parallel Writing** - Work on 10+ articles simultaneously based on mood/inspiration
3. **Version Control** - All draft progress committed to `drafts/writing-pad` branch
4. **Publishing** - Use `m` key to publish drafts:
   - Prompts for publication date (YYYY-MM-DD)
   - Validates no conflicts with existing posts
   - Moves from `drafts/slug/` to `posts/YYYY/MM/DD-slug/`
   - Updates frontmatter with date and sets `draft: false`
5. **Main Branch Integration** - Published content merged to main via squash commits

#### Git Workflow
```bash
# Daily writing cycle in drafts/writing-pad branch
git add content/posts/drafts/
git commit -m "Draft progress: AI sovereignty - added regulatory framework"

# Publishing ready articles (via flux 'm' command)
git commit -m "Publish: AI Sovereignty Analysis - moved to dated folder"

# Squash merge to main (creates clean publication history)
git checkout main
git merge --squash drafts/writing-pad
git commit -m "Publish: AI Sovereignty in the Age of Regulation

Comprehensive analysis of digital autonomy in emerging regulatory frameworks."
```

#### Benefits
- **No time pressure** - drafts live without imposed dates
- **Parallel creativity** - switch between articles freely
- **Clean main branch** - only shows published content
- **Rich draft history** - detailed writing journey preserved
- **Conflict prevention** - publication date validation

### 🆕 The Sunday Blender Enhanced Publishing Workflow

The Sunday Blender now features a comprehensive **16-step automated publishing workflow** that streamlines the entire newsletter production process from content creation to social media distribution.

#### Workflow Overview

The enhanced TSB workflow automates the complete publishing pipeline:

```
Step 1-2:  Edit content + Hugo preview (manual)
Step 3:    Generate PDF (tsb-make-pdf)
Step 4:    Create podcast via NotebookLM (manual)
Step 5:    Process podcast audio (tsb-process-podcast)
Step 6:    Generate show notes (tsb-generate-shownotes)
Step 7:    Update frontmatter (draft: false)
Step 8:    Reorganize to date-based structure
Step 9:    Commit and push to draft branch
Step 10:   Create pull request
Step 11:   Merge PR automatically
Step 12:   Delete remote and local branches
Step 13:   Post announcement tweet
Step 14:   Execute Twitter bot scheduler
Step 15:   Update progress tracking table
Step 16:   Final verification and cleanup
```

#### Using the TSB Enhanced Workflow

1. **Start the workflow**:
   ```bash
   ./flux
   # Select "2) The Sunday Blender"
   # Press "t" for TSB Enhanced Publish
   ```

2. **Enter post title** when prompted

3. **Follow the automated steps**:
   - PDF generation happens automatically
   - Upload to NotebookLM and download podcast (manual pause)
   - Podcast processing and show notes generation (automated)
   - Git operations, PR creation, and merge (automated)
   - Social media posting templates provided
   - Progress tracking updated

#### Prerequisites

For full automation, install these TSB-specific commands:
- `tsb-make-pdf` - PDF generation from Hugo content
- `tsb-process-podcast` - Audio processing (m4a → mp3, metadata)
- `tsb-generate-shownotes` - AI-enhanced RSS content generation
- `gh` - GitHub CLI for PR automation
- Twitter CLI (optional) - For automated tweet posting

#### Graceful Degradation

The workflow gracefully handles missing tools:
- **Missing TSB commands**: Provides manual step instructions
- **No GitHub CLI**: Shows PR creation commands
- **No Twitter CLI**: Displays tweet template for manual posting

Each step can be skipped or performed manually if automation fails, ensuring you can always complete the publishing process.

### Session-Based Theme Switching

- **Writing Mode**: Quiet Light theme with Georgia font, optimized for prose
- **Coding Mode**: Community Material Theme, optimized for development
- **Automatic**: Switches when opening posts, restores when session ends

## Architecture

### Modular Design
```
flux                      # Main orchestrator script
├── lib/
│   ├── menu.sh          # Interactive menus and draft/completion detection
│   ├── frontmatter.sh   # Post creation and metadata management
│   ├── editor.sh        # Cursor integration and theme switching
│   ├── publish.sh       # Git operations and publishing workflow
│   ├── session.sh       # Session management and cleanup
│   ├── git_manager.sh   # Enhanced git integration and automation
│   ├── themes.sh        # Theme switching functionality
│   └── tsb_workflow.sh  # The Sunday Blender 16-step automation
└── config/
    └── sites.json       # Multi-site configuration
```

### Enhanced Git Integration
- **Automatic git status checking** when selecting sites
- **Smart branch detection** and management for draft workflows
- **Real-time change detection** for both tracked and untracked files
- **Auto-commit sessions** with standardized commit messages:
  - `Draft progress: Article Title` for work-in-progress
  - `Ready for publish: Article Title` for completed posts
- **Automatic push to remote** with user confirmation
- **Claude Code attribution** in all commit messages
- **Branch history display** showing recent activity
- **Session-aware workflow** that reduces manual git operations

## Requirements

- **Hugo-based websites** with standard content structure
- **Git repositories** with CI/CD for automated deployment
- **Cursor editor** with Code Spell Checker extension
- **macOS/Linux** (AppleScript automation requires macOS)
- **jq** for JSON manipulation (usually pre-installed)

## Configuration

### Site Configuration (`config/sites.json`)
```json
{
  "sites": {
    "dsc": {
      "name": "Digital Sovereignty Chronicle",
      "path": "/Users/username/github/digital-sovereignty",
      "description": "Crypto, AI, and digital sovereignty insights",
      "url": "https://digitalsovereignty.herbertyang.xyz",
      "active": true,
      "frontmatter_defaults": {
        "categories": ["Technology"],
        "tags": ["AI", "Crypto", "Digital Sovereignty"],
        "author": "Herbert Yang"
      }
    }
  }
}
```

### Cursor Settings
The theme switching functionality modifies your Cursor `settings.json` temporarily during writing sessions. Your original settings are preserved and restored when sessions end.

## Advanced Usage

### Command Line Interface
```bash
# Interactive mode with git-aware workflow (recommended)
./flux

# Quick draft saving
./flux save "My Draft Title"

# Quick publishing
./flux publish "Completed Post Title"

# Status overview
./flux status

# Git status checking
./flux git dsc    # Check Digital Sovereignty Chronicle
./flux git sb     # Check The Sunday Blender
./flux git hy     # Check Herbert Yang site

# Help
./flux help
```

### Enhanced Git Workflow Integration
All operations create meaningful git commits with Claude Code attribution:

```bash
# Draft progress commits (auto-generated during sessions)
"Draft progress: Post Title

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

# Ready for publish commits
"Ready for publish: Post Title

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"

# Publishing commits (traditional workflow)
"Publish: Post Title
📝 1,200 words
🖼️ 3 images
🏷️ Technology"
```

### Git Status Information
When you select a site, Flux automatically shows:
- Current branch and recent branch history
- Uncommitted changes (both tracked and untracked files)
- Remote synchronization status (ahead/behind)
- Available draft branches for switching

## Troubleshooting

### Common Issues

**Theme not switching**
- Ensure Cursor is properly installed and can be launched from command line
- Check that `jq` is available for JSON manipulation

**Posts not found**
- Verify your site path in `config/sites.json`
- Ensure Hugo content structure: `content/posts/YYYY/MM/DD-slug/index.md`

**Git operations failing**
- Check that you're in a git repository
- Ensure you have commit access to the repository
- Verify remote repository is configured

**Cursor automation not working**
- AppleScript automation requires macOS
- Ensure Cursor has necessary accessibility permissions
- Manual layout setup instructions are provided as fallback

## Contributing

This is a personal workflow tool, but contributions are welcome:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with your own Hugo sites
5. Submit a pull request

## License

MIT License - feel free to adapt for your own writing workflow.

## Acknowledgments

- Inspired by the Zettelkasten method of knowledge management
- Built with the assistance of [Claude Code](https://claude.ai/code)
- Optimized for Hugo static site generators
- Designed for Cursor editor integration

---

*Built for writers who think in networks, not silos.*