#!/bin/sh
set -a
# Load the environment variables from the .env file at the root of the project
source ../.env
# Disable exporting environment variables after loading
set +a

SLACK_WEBHOOK_URL="${SLACK_MONITORING_WEB_HOOK}"  # Replace with your Slack webhook URL
LOG_FILE="./log/deploy-monitoring.log"
NGINX_MONITORING_CONF="./nginx/conf.d/monitoring.conf"
# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

send_slack_notification() {
    local message="$1"
    log_message "Sending Slack notification: $message"
    curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"${message}\"}" "$SLACK_WEBHOOK_URL"
}

log_message "Setting up monitoring configuration for Nginx..."
send_slack_notification "🔄 Setting up monitoring configuration for Nginx..."





cat <<EOL | tee $NGINX_MONITORING_CONF > /dev/null
server {
    listen 80;
    server_name monitoring.xurl.fyi;

    location / {
        proxy_pass http://localhost:3000;  # Grafana
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    location /prometheus/ {
        proxy_pass http://localhost:9090;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    location /loki/ {
        proxy_pass http://localhost:3100;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOL

# Restart the Nginx container
log_message "Restarting Nginx container..."
send_slack_notification "🚀 Restarting Nginx container..."

docker-compose restart nginx

log_message "Nginx container restarted!"
send_slack_notification "✅ Nginx container restarted!"

