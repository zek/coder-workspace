FROM codercom/enterprise-base:ubuntu

USER root

# ============================================
# APT repositories (GitHub CLI, eza)
# ============================================
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
      https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list && \
    mkdir -p /etc/apt/keyrings && \
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
      | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg 2>/dev/null && \
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
      > /etc/apt/sources.list.d/gierens.list

# ============================================
# APT packages
# ============================================
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      watchman ripgrep jq unzip python3-pip pipx \
      zsh fzf bat fd-find eza gh \
      openjdk-17-jdk-headless && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ============================================
# Symlinks (Ubuntu names differ from upstream)
# ============================================
RUN [ -f /usr/bin/batcat ] && ln -sf /usr/bin/batcat /usr/local/bin/bat || true && \
    [ -f /usr/bin/fdfind ] && ln -sf /usr/bin/fdfind /usr/local/bin/fd || true

# ============================================
# fnm (Fast Node Manager) + Node.js 24
# ============================================
ENV FNM_DIR=/opt/fnm
RUN curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir /usr/local/bin --skip-shell && \
    fnm install 24 && \
    fnm default 24 && \
    ln -s $(fnm exec --using=24 -- which node) /usr/local/bin/node && \
    ln -s $(fnm exec --using=24 -- which npm) /usr/local/bin/npm && \
    ln -s $(fnm exec --using=24 -- which npx) /usr/local/bin/npx && \
    chmod -R a+rx /opt/fnm

# ============================================
# npm global packages
# ============================================
RUN npm install -g \
      eas-cli \
      @anthropic-ai/claude-code \
      playwriter \
      agentation-mcp

# ============================================
# Binary tools (installed to /usr/local/bin)
# ============================================
RUN curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh \
      | BIN_DIR=/usr/local/bin sh && \
    curl -sS https://starship.rs/install.sh | sh -s -- -y && \
    curl -LsSf https://astral.sh/uv/install.sh | sh && \
    install -m 755 /root/.local/bin/uv /usr/local/bin/uv && \
    install -m 755 /root/.local/bin/uvx /usr/local/bin/uvx && \
    rm -rf /root/.local/bin/uv /root/.local/bin/uvx

# ============================================
# Maestro CLI (E2E testing for Android/iOS/Web)
# ============================================
RUN curl -fsSL "https://get.maestro.mobile.dev" | bash && \
    install -m 755 /root/.maestro/bin/maestro /usr/local/bin/maestro && \
    rm -rf /root/.maestro

# ============================================
# Skel: dotfiles staged for first-start copy
# ============================================
COPY skel/.zshenv   /etc/skel/.zshenv
COPY skel/.zimrc    /etc/skel/.zimrc
COPY skel/.zshrc    /etc/skel/.zshrc
COPY skel/.config/  /etc/skel/.config/
COPY skel/.claude/  /etc/skel/.claude/

# ============================================
# zimfw: download manager + install plugins
# ============================================
RUN mkdir -p /etc/skel/.zim && \
    curl -fsSL --create-dirs -o /etc/skel/.zim/zimfw.zsh \
      https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh && \
    HOME=/etc/skel zsh -c 'source /etc/skel/.zim/zimfw.zsh && zimfw install' 2>/dev/null || true

# ============================================
# Auto-switch bash to zsh (append to skel .bashrc)
# ============================================
RUN printf '\n# Switch to ZSH for interactive sessions\nif [ -t 1 ] && [ -x /usr/bin/zsh ] && [ -z "$ZSH_VERSION" ]; then\n  exec /usr/bin/zsh -l\nfi\n' >> /etc/skel/.bashrc

USER coder
