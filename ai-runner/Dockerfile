FROM node:22-bookworm AS final

ARG CODEX_VERSION=latest
ARG CLAUDE_CODE_VERSION=latest
ARG PNPM_VERSION=10.23.0

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
ENV NODE_ENV=local

# System tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    git \
    curl \
    jq \
    ca-certificates \
    openssh-client \
    unzip \
    tar \
    gzip \
    xz-utils \
    python3 \
    make \
    g++ \
    procps \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# GitHub CLI — useful if you want to create PRs from the runner
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# pnpm via corepack
RUN corepack enable \
    && corepack prepare pnpm@${PNPM_VERSION} --activate

# AI CLIs
RUN npm install -g \
    @openai/codex@${CODEX_VERSION} \
    @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

# Non-root user
RUN useradd -m -u 10001 runner

# Workspace
RUN mkdir -p /workspace /runner /prompts \
    && chown -R runner:runner /workspace /runner /prompts

WORKDIR /workspace

USER runner

ENTRYPOINT ["/bin/bash"]
