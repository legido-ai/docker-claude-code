FROM node:20-alpine

# Install dependencies including docker CLI

RUN apk add --no-cache  \
wget \
git \
python3 \
py3-pip \
make \
g++ \
ca-certificates \
curl \
docker-cli \
dumb-init \
bash \
zsh \
openssh \
shadow \
&& rm -rf /var/cache/apk/*

#Install claude-code globally

RUN npm install -g @anthropic-ai/claude-code@latest typescript tsx nodemon npm-check-updates \
&& npm cache clean --force

# Create necessary directories and set permissions

RUN mkdir -p /commandhistory /workspace /home/node/.ssh /home/node/.claude \
&& chown -R node:node /commandhistory /workspace /home/node

WORKDIR /home/node

# Set up history file

RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
&& touch /commandhistory/.bash_history \
&& echo "$SNIPPET" >> "/home/node/.bashrc" \
&& echo "$SNIPPET" >> "/home/node/.zshrc"

# Copy entrypoint script
COPY --chown=node:node entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

# Set up default claude configuration

RUN mkdir -p /home/node/.claude && chown -R node:node /home/node/.claude

USER node

WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["sleep", "infinity"]
