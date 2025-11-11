# Multi-stage build for optimal image size
# Stage 1: Build stage with all dependencies
FROM node:20-alpine AS builder

# Install build dependencies
RUN apk add --no-cache \
    wget \
    git \
    python3 \
    py3-pip \
    make \
    g++ \
    ca-certificates \
    curl \
    && rm -rf /var/cache/apk/*

# Install global packages including Claude Code
RUN npm install -g @anthropic-ai/claude-code@latest typescript tsx nodemon npm-check-updates \
    && npm cache clean --force

# Stage 2: Runtime stage with minimal dependencies
FROM node:20-alpine AS runtime

# Install only runtime dependencies
RUN apk add --no-cache \
    git \
    python3 \
    py3-pip \
    ca-certificates \
    curl \
    docker-cli \
    dumb-init \
    bash \
    zsh \
    openssh \
    shadow \
    && rm -rf /var/cache/apk/* \
    && addgroup -g 1000 -S node \
    && adduser -u 1000 -S node -G node

# Copy installed packages from builder stage
COPY --from=builder /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=builder /usr/local/bin /usr/local/bin

# Create necessary directories and set permissions
RUN mkdir -p /commandhistory /workspace /home/node/.ssh /home/node/.claude \
    && chown -R node:node /commandhistory /workspace /home/node

USER node

WORKDIR /home/node

# Set up history file
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
    && touch /commandhistory/.bash_history \
    && echo "$SNIPPET" >> "/home/node/.bashrc" \
    && echo "$SNIPPET" >> "/home/node/.zshrc"

WORKDIR /workspace

# Copy entrypoint script
COPY --chown=node:node entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set up default claude configuration
RUN mkdir -p /home/node/.claude && chown -R node:node /home/node/.claude

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["sleep", "infinity"]
