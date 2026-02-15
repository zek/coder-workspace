# ============================================
# ZSH Config — zimfw + Starship
# ============================================

# -- zimfw bootstrap --
ZIM_HOME=${ZDOTDIR:-${HOME}}/.zim
if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
  curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh \
    https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
fi
if [[ ! ${ZIM_HOME}/init.zsh -nt ${ZDOTDIR:-${HOME}}/.zimrc ]]; then
  source ${ZIM_HOME}/zimfw.zsh init
fi
source ${ZIM_HOME}/init.zsh

# -- Plugin tuning --
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

# History substring search keybindings
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# -- History --
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS

# -- PATH --
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.maestro/bin:$PATH"
[ -d "$HOME/Android/Sdk" ] && export ANDROID_HOME="$HOME/Android/Sdk" && export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"

# -- fnm (Fast Node Manager) --
command -v fnm &>/dev/null && eval "$(fnm env --use-on-cd)"

# -- Modern CLI aliases --
command -v eza &>/dev/null && alias ls='eza --color=auto --icons=auto' && alias ll='eza -la --icons=auto --git' && alias lt='eza --tree --level=2 --icons=auto'
command -v bat &>/dev/null && export BAT_THEME="TwoDark" && export MANPAGER="sh -c 'col -bx | bat -l man -p'" && alias cat='bat --paging=never'
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# fzf integration
[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
[ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh
command -v fd &>/dev/null && export FZF_DEFAULT_COMMAND='fd --hidden --strip-cwd-prefix --exclude .git' && export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND" && export FZF_ALT_C_COMMAND='fd --type=d --hidden --strip-cwd-prefix --exclude .git'

# -- Git aliases --
alias gs='git status'
alias gd='git diff'
alias gp='git pull'
alias gc='git commit'
alias ga='git add'
alias gco='git checkout'
alias gl='git log --oneline -20'

# -- Docker aliases --
alias d='docker'
alias dc='docker compose'

# -- Claude Code --
alias claude='claude --allow-dangerously-skip-permissions'

# -- Auto-ls on cd --
auto-ls() { eza --color=auto --icons=auto 2>/dev/null || ls --color=auto; }
chpwd_functions=(auto-ls $chpwd_functions)

# -- Starship prompt (must be last) --
eval "$(starship init zsh)"
