# Flux

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/Inturious-Labs/flux/graphs/commit-activity)
[![Made with Bash](https://img.shields.io/badge/Made%20with-Bash-1f425f.svg)](https://www.gnu.org/software/bash/)

> A unified CLI workflow for managing multiple Hugo-based websites

## What is Flux?

Flux is an interactive command-line tool that centralizes writing and publishing across multiple Hugo websites. Write in Cursor with automatic theme switching, manage drafts with visual status indicators, and publish with one-click git automation.

## Features

- **Multi-site management** - Handle multiple Hugo sites from one interface
- **Interactive menus** - Direct selection by numbers (drafts) or letters (completed posts)
- **Draft status tracking** - Visual indicators: 🔴 (< 100 words), 🟡 (100-599 words), 🟢 (600+ words)
- **Git automation** - Auto-commit, branch management, and PR creation
- **Cursor integration** - Automatic theme switching for writing sessions
- **TSB workflow** - 16-step automated publishing for The Sunday Blender

## Quick Start

```bash
./flux                      # Interactive mode
./flux save "Title"         # Quick save draft
./flux publish "Title"      # Publish post
./flux status               # Show all drafts
```

## Installation

1. **Clone and setup**
   ```bash
   git clone https://github.com/Inturious-Labs/flux.git
   cd flux
   cp config/sites.json.example config/sites.json
   chmod +x flux lib/*.sh
   ```

2. **Configure sites**

   Edit `config/sites.json` with your Hugo repository paths:
   ```json
   {
     "sites": {
       "dsc": {
         "path": "/path/to/your/hugo-site",
         "name": "Your Site Name",
         ...
       }
     }
   }
   ```

3. **Install dependencies**
   - [Cursor editor](https://cursor.sh)
   - Hugo (for your sites)
   - `jq` for JSON parsing

## Workflow

1. **Launch** - `./flux`
2. **Select site** - Choose from configured websites
3. **Create/Edit** - New post (`n`), edit draft (`1-9`), or publish (`a-z`)
4. **Write** - Opens in Cursor with automatic theme switching
5. **Save** - Auto-commit progress or mark ready for publish
6. **Publish** - One-click git workflow with PR creation

### Draft Status Flow

```
🔴 New (< 100 words) → 🟡 In Progress (100-599) → 🟢 Substantial (600+) → ✅ Ready → 🚀 Published
```

## Configuration

### Site Structure

Flux expects Hugo sites with this structure:
```
your-hugo-site/
└── content/
    └── posts/
        ├── drafts/              # Work-in-progress (DSC only)
        └── YYYY/MM/DD-slug/     # Published posts
```

### Multi-Site Support

Currently supports:
- **Digital Sovereignty Chronicle** - Crypto, AI, and digital sovereignty
- **The Sunday Blender** - News for kids (with 16-step automation)
- **Herbert Yang** - Personal blog

## TSB Enhanced Workflow

The Sunday Blender has a special 16-step workflow (access via `t` key):

- PDF generation (`tsb-make-pdf`)
- Podcast processing (`tsb-process-podcast`)
- Show notes generation (`tsb-generate-shownotes`)
- Automated PR merge and cleanup
- Social media posting templates

**Prerequisites**: Install TSB-specific commands and GitHub CLI (`gh`) for full automation.

## Requirements

- macOS/Linux
- Hugo-based websites with git repositories
- Cursor editor
- `jq` (JSON processor)

## Architecture

```
flux                    # Main orchestrator
├── lib/
│   ├── menu.sh        # Interactive menus
│   ├── frontmatter.sh # Post creation
│   ├── publish.sh     # Git operations
│   ├── git_manager.sh # Branch management
│   └── tsb_workflow.sh # TSB automation
└── config/
    └── sites.json     # Site configuration
```

## License

MIT - Adapt freely for your own workflow.

---

*Built for writers who think in networks, not silos.*
