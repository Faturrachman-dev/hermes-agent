FROM python:3.11-slim

# Install system dependencies (curl, wget, rclone for session sync)
RUN apt-get update && apt-get install -y git curl wget unzip rclone tzdata && \
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb && \
    dpkg -i cloudflared-linux-amd64.deb && rm cloudflared-linux-amd64.deb && \
    wget https://github.com/benbjohnson/litestream/releases/download/v0.3.13/litestream-v0.3.13-linux-amd64.tar.gz && \
    tar -xzf litestream-v0.3.13-linux-amd64.tar.gz && mv litestream /usr/local/bin/ && \
    rm litestream-v0.3.13-linux-amd64.tar.gz && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Hugging Face Spaces require running as a non-root user (UID 1000)
RUN useradd -m -u 1000 user
USER user
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:/home/user/app/.venv/bin:$PATH \
    HERMES_HOME=/home/user/.hermes

WORKDIR /home/user/app

# Copy the local repository into the container with correct ownership
COPY --chown=user:user . .

# Install dependencies using uv
RUN pip install uv && uv venv && uv sync --extra all

# Ensure the hermes directory exists
RUN mkdir -p $HERMES_HOME

# Make the startup script executable
RUN chmod +x /home/user/app/start_hf.sh

# Set the entrypoint
ENTRYPOINT ["/home/user/app/start_hf.sh"]
