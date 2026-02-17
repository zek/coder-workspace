FROM codercom/enterprise-base:ubuntu

USER root

# ============================================
# Layer 1: APT repositories (rarely changes)
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
# Layer 2: APT packages + databases (rarely changes)
# ============================================
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      watchman ripgrep jq unzip python3-pip pipx \
      zsh fzf bat fd-find eza gh \
      openjdk-17-jdk-headless \
      postgresql postgresql-client \
      redis-server \
      mysql-server mysql-client && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ============================================
# Layer 3: Database directories & permissions (rarely changes)
# ============================================
RUN mkdir -p /var/run/postgresql && chown postgres:postgres /var/run/postgresql && chmod 2775 /var/run/postgresql && \
    usermod -aG postgres coder && \
    mkdir -p /home/coder/.local/share/postgresql && \
    chown -R coder:coder /home/coder/.local/share/postgresql && \
    mkdir -p /var/run/redis && chown coder:coder /var/run/redis && \
    mkdir -p /var/run/mysqld && chown coder:coder /var/run/mysqld && \
    mkdir -p /home/coder/.local/share/mysql && \
    chown -R coder:coder /home/coder/.local/share/mysql

# ============================================
# Layer 4: Symlinks (rarely changes)
# ============================================
RUN [ -f /usr/bin/batcat ] && ln -sf /usr/bin/batcat /usr/local/bin/bat || true && \
    [ -f /usr/bin/fdfind ] && ln -sf /usr/bin/fdfind /usr/local/bin/fd || true

# ============================================
# Layer 5: fnm + Node.js (changes on Node major version bump)
# ============================================
ENV FNM_DIR=/opt/fnm
RUN curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir /usr/local/bin --skip-shell && \
    fnm install 24 && \
    fnm default 24 && \
    ln -s $(fnm exec --using=24 -- which node) /usr/local/bin/node && \
    ln -s $(fnm exec --using=24 -- which npm) /usr/local/bin/npm && \
    ln -s $(fnm exec --using=24 -- which npx) /usr/local/bin/npx && \
    chmod -R a+rwx /opt/fnm

# ============================================
# Layer 6: Binary tools (rarely changes)
# ============================================
RUN curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash && \
    install -m 755 /root/.local/bin/zoxide /usr/local/bin/zoxide && \
    curl -sS https://starship.rs/install.sh | sh -s -- -y && \
    curl -LsSf https://astral.sh/uv/install.sh | sh && \
    install -m 755 /root/.local/bin/uv /usr/local/bin/uv && \
    install -m 755 /root/.local/bin/uvx /usr/local/bin/uvx && \
    rm -rf /root/.local/bin/uv /root/.local/bin/uvx

# ============================================
# Layer 7: AgentAPI (changes on version bump)
# ============================================
ARG AGENTAPI_VERSION=v0.11.8
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then BINARY="agentapi-linux-amd64"; \
    elif [ "$ARCH" = "aarch64" ]; then BINARY="agentapi-linux-arm64"; \
    else echo "Unsupported arch: $ARCH" && exit 1; fi && \
    curl -fsSL -o /usr/local/bin/agentapi \
      "https://github.com/coder/agentapi/releases/download/${AGENTAPI_VERSION}/${BINARY}" && \
    chmod 755 /usr/local/bin/agentapi

# ============================================
# Layer 8: code-server (rarely changes)
# ============================================
RUN curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=/opt/code-server && \
    chmod -R a+rx /opt/code-server

# ============================================
# Layer 9: Maestro CLI (rarely changes)
# ============================================
RUN curl -fsSL "https://get.maestro.mobile.dev" | bash && \
    mv /root/.maestro /opt/maestro && \
    ln -s /opt/maestro/bin/maestro /usr/local/bin/maestro && \
    chmod -R a+rx /opt/maestro

# ============================================
# Layer 10: Claude Code native installer
# ============================================
RUN curl -fsSL https://claude.ai/install.sh | bash

# ============================================
# Layer 11: npm global packages (changes most often)
# ============================================
RUN npm install -g \
      pnpm \
      eas-cli \
      playwriter \
      playwright-core \
      @playwright/cli \
      agentation-mcp && \
    ln -s $(fnm exec --using=24 -- which pnpm) /usr/local/bin/pnpm && \
    ln -s $(fnm exec --using=24 -- which eas) /usr/local/bin/eas && \
    ln -s $(fnm exec --using=24 -- which playwriter) /usr/local/bin/playwriter && \
    ln -s $(fnm exec --using=24 -- which playwright-cli) /usr/local/bin/playwright-cli && \
    ln -s $(fnm exec --using=24 -- which agentation-mcp) /usr/local/bin/agentation-mcp

# ============================================
# Layer 11: VS Code extensions (changes occasionally)
# ============================================
RUN EXTENSIONS="anthropic.claude-code msjsdiag.vscode-react-native dbaeumer.vscode-eslint \
      esbenp.prettier-vscode dsznajder.es7-react-js-snippets formulahendry.auto-rename-tag \
      bradlc.vscode-tailwindcss highagency.pencildev" && \
    for ext in $EXTENSIONS; do \
      /opt/code-server/bin/code-server \
        --extensions-dir /etc/skel/.local/share/code-server/extensions \
        --install-extension "$ext" || true; \
    done && \
    chmod -R a+rX /etc/skel/.local

# ============================================
# Layer 12: Skel dotfiles (changes occasionally)
# ============================================
COPY skel/.zshenv   /etc/skel/.zshenv
COPY skel/.zimrc    /etc/skel/.zimrc
COPY skel/.zshrc    /etc/skel/.zshrc
COPY skel/.config/  /etc/skel/.config/
COPY skel/.claude/  /etc/skel/.claude/

# ============================================
# Layer 13: zimfw plugins (rarely changes)
# ============================================
RUN mkdir -p /etc/skel/.zim && \
    curl -fsSL --create-dirs -o /etc/skel/.zim/zimfw.zsh \
      https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh && \
    HOME=/etc/skel zsh -c 'source /etc/skel/.zim/zimfw.zsh && zimfw install' 2>/dev/null || true

# ============================================
# Layer 14: Shell config (rarely changes)
# ============================================
RUN printf '\n# Switch to ZSH for interactive sessions\nif [ -t 1 ] && [ -x /usr/bin/zsh ] && [ -z "$ZSH_VERSION" ]; then\n  exec /usr/bin/zsh -l\nfi\n' >> /etc/skel/.bashrc

RUN chsh -s /usr/bin/zsh coder

USER coder
