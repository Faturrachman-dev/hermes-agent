#!/bin/bash
# Startup script for Hugging Face Space Docker Deployment

export HERMES_HOME="/home/user/.hermes"
mkdir -p $HERMES_HOME

echo "=> Setting up rclone for WhatsApp session sync..."
mkdir -p ~/.config/rclone
cat <<EOF > ~/.config/rclone/rclone.conf
[r2]
type = s3
provider = Cloudflare
access_key_id = ${R2_ACCESS_KEY_ID}
secret_access_key = ${R2_SECRET_ACCESS_KEY}
endpoint = ${R2_ENDPOINT_URL}
region = auto
EOF

echo "=> Restoring WhatsApp session from R2 (if exists)..."
mkdir -p $HERMES_HOME/whatsapp/session
rclone copy r2:${R2_BUCKET_NAME}/whatsapp_session $HERMES_HOME/whatsapp/session || echo "No existing WhatsApp session found."

echo "=> Restoring SQLite Database from Litestream..."
# This pulls the latest replica from R2 before the server starts
litestream restore -if-replica-exists -config /home/user/app/litestream.yml $HERMES_HOME/session_db.sqlite

echo "=> Starting Cloudflare Tunnel in the background..."
cloudflared tunnel run --token ${TUNNEL_TOKEN} &

echo "=> Starting background sync for WhatsApp session..."
(
  while true; do
    sleep 300
    rclone sync $HERMES_HOME/whatsapp/session r2:${R2_BUCKET_NAME}/whatsapp_session --ignore-errors
  done
) &

echo "=> Starting Hermes Gateway with Litestream Database Replication..."
# Execute litestream replicate which wraps the hermes gateway process.
# Litestream streams DB changes to R2 in real-time as long as the process is alive.
exec litestream replicate -exec "/home/user/app/.venv/bin/hermes gateway start --port 8000" -config /home/user/app/litestream.yml
