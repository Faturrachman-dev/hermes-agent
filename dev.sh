#!/bin/bash
# Start Hermes in development mode with live-reload
# Ignores log files and databases to prevent infinite reload loops

echo "Starting Hermes Dev Server..."
source venv/bin/activate
watchfiles --ignore-paths "*.log" --ignore-paths "*.sqlite" --ignore-paths "*.json" "hermes" .
