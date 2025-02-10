#!/bin/sh
set -a
# Load the environment variables from the .env file at the root of the project
source ./.env
# Disable exporting environment variables after loading
set +a
mkdir -p ./log

if [ ! -f ./log/deploy-monitoring.log ]; then
    touch ./log/deploy-monitoring.log
fi
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

# HTTP redirect to HTTPS
server {
    listen 80;
    server_name monitoring.xurl.fyi;
    
    # Redirect all HTTP traffic to HTTPS
    return 301 https://\$host\$request_uri;
}

# HTTPS server block with SSL
server {
    listen 443 ssl;
    server_name monitoring.xurl.fyi;

    # SSL certificate and key paths
    ssl_certificate /etc/letsencrypt/live/xurl.fyi.fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/xurl.fyi.key;

    # SSL settings (adjust according to security best practices)
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    # Resolver for Docker container name resolution
    resolver 127.0.0.11 valid=30s;

    # Prometheus location
    # location /prometheus {
    #     proxy_pass http://prometheus:9090;  # Adjust the container name if needed
    #     proxy_set_header Host \$host;
    #     proxy_set_header X-Real-IP \$remote_addr;
    #     proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    # }

    # Grafana location
    location / {
        proxy_pass http://grafana:3000;  # Adjust the container name if needed
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    # Loki location
    # location /loki {
    #     proxy_pass http://loki:3100;  # Adjust the container name if needed
    #     proxy_set_header Host \$host;
    #     proxy_set_header X-Real-IP \$remote_addr;
    #     proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    # }
}

EOL

# Restart the Nginx container
log_message "Restarting Nginx container..."
send_slack_notification "🚀 Restarting Nginx container..."

docker-compose restart nginx

log_message "Nginx container restarted!"
send_slack_notification "✅ Nginx container restarted!"

