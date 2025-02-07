#!/bin/bash
set -e

# Path to log file
LOG_FILE="/var/log/cert-renewal.log"
CERT_DIR="/etc/nginx/ssl"
ACME_SH="/root/.acme.sh/acme.sh"  # Path to acme.sh
SLACK_WEBHOOK_URL="${SLACK_MONITORING_WEB_HOOK}"  # Replace with your Slack webhook URL

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

# Function to send Slack notification
send_slack_notification() {
    local message="$1"
    curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"$message\"}" "$SLACK_WEBHOOK_URL"
}

# Ensure log file and certificate directory exist
install -m 644 /dev/null $LOG_FILE
mkdir -p $CERT_DIR

# Check if environment variables are set
if [[ -z "$NAMECOM_USERNAME" || -z "$NAMECOM_TOKEN" ]]; then
    log_message "ERROR: Name.com credentials not found in environment variables"
    send_slack_notification ":x: ERROR: Name.com credentials not found in environment variables"
    exit 1
fi

# Export Name.com API credentials for acme.sh
export Namecom_Username="${NAMECOM_USERNAME}"
export Namecom_Token="${NAMECOM_TOKEN}"

log_message "Starting certificate issuance/renewal process"
send_slack_notification ":hourglass: Starting SSL certificate issuance/renewal for xurl.fyi"

# Issue/renew the certificate
if $ACME_SH --issue \
    --dns dns_namecom \
    -d xurl.fyi \
    -d "*.xurl.fyi" \
    --server letsencrypt \
    --key-file "$CERT_DIR/xurl.fyi.key" \
    --fullchain-file "$CERT_DIR/xurl.fyi.fullchain.pem" \
    --reloadcmd "nginx -s reload" \
    >> $LOG_FILE 2>&1; then
    log_message "Certificate renewal completed successfully"
    send_slack_notification ":white_check_mark: SSL certificate renewed successfully for xurl.fyi"

    # Show certificate expiry date
    EXPIRY_DATE=$(openssl x509 -in "$CERT_DIR/xurl.fyi.fullchain.pem" -noout -enddate | cut -d= -f2)
    send_slack_notification ":calendar: Certificate expires on: $EXPIRY_DATE"

    # Reload Nginx with new certificates
    if nginx -s reload; then
        log_message "Nginx reloaded successfully"
        send_slack_notification ":rocket: Nginx reloaded successfully with the new certificate"
    else
        log_message "WARNING: Nginx reload failed!"
        send_slack_notification ":warning: Nginx reload failed!"
    fi
else
    log_message "ERROR: Certificate renewal failed"
    send_slack_notification ":x: ERROR: SSL certificate renewal failed for xurl.fyi. Check logs for details."
    exit 1
fi
