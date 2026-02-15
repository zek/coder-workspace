# coder-workspace

Custom Docker image for [Coder](https://coder.com) workspaces with pre-baked development tools.

Extends `codercom/enterprise-base:ubuntu` to eliminate per-workspace install time.

## Pre-installed Tools

| Category | Tools |
|----------|-------|
| **APT** | Node.js 20, watchman, ripgrep, jq, unzip, pipx, zsh, fzf, bat, fd, eza, gh |
| **npm** | eas-cli, claude-code, playwriter, agentation-mcp |
| **Binary** | zoxide, starship, uv |
| **Shell** | zimfw + plugins, starship prompt, modern CLI aliases |

## Pre-staged Dotfiles (`/etc/skel/`)

Copied to user home on first workspace start:

- `.zshrc` - ZSH config with zimfw, aliases, starship
- `.zimrc` - zimfw plugin manifest
- `.zshenv` - Skip global compinit
- `.config/starship.toml` - Minimal starship prompt
- `.claude/settings.json` - Shared skills directory
- `.claude/claude_desktop_config.json` - MCP server configs

## Usage

```
ghcr.io/zek/coder-workspace:latest
```

## Build

Automated via GitHub Actions on push to `main`. Manual trigger also available via `workflow_dispatch`.

Tags produced per build:
- `latest`
- `YYYYMMDD` (date)
- Short SHA
