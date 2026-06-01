FROM python:3.11-slim

# Install system dependencies (curl, wget, rclone for session sync)
RUN apt-get update && apt-get install -y git curl wget unzip rclone tzdata && \
    wget https://github.com/benbjohnson/litestream/releases/download/v0.3.13/litestream-v0.3.13-linux-amd64.tar.gz && \
    tar -xzf litestream-v0.3.13-linux-amd64.tar.gz && mv litestream /usr/local/bin/ && \
    rm litestream-v0.3.13-linux-amd64.tar.gz && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Create user and set environment
RUN useradd -m -u 1000 user
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:/home/user/app/.venv/bin:$PATH \
    HERMES_HOME=/home/user/.hermes

WORKDIR /home/user/app

# Copy the local repository into the container
COPY . .

# Install dependencies using uv
RUN pip install uv && uv venv && uv sync --extra all

# Ensure hermes directory exists and MAKE EVERYTHING WRITABLE
# Heroku runs containers as a random non-root UID. It must have write access to the app and hermes dirs.
RUN mkdir -p $HERMES_HOME && \
    chmod +x /home/user/app/start_heroku.sh && \
    chmod -R 777 /home/user

# Switch to non-root user (Heroku overrides the UID at runtime)
USER user

# Set the entrypoint to the Heroku script
ENTRYPOINT ["/home/user/app/start_heroku.sh"]
