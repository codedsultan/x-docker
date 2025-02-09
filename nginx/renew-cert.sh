#!/bin/bash
set -e

# Path to log file
LOG_FILE="/var/log/cert-renewal.log"
CERT_DIR="/etc/letsencrypt/live"
ACME_SH="/root/.acme.sh/acme.sh"  # Path to acme.sh
SLACK_WEBHOOK_URL="${SLACK_MONITORING_WEB_HOOK}"  # Replace with your Slack webhook URL

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

send_slack_notification() {
    local message="$1"
    log_message "Sending Slack notification: $message"
    curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"${message}\"}" "$SLACK_WEBHOOK_URL"
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

log_message "Starting certificate issuance/renewal processes"
send_slack_notification ":hourglass: Starting SSL certificate issuance/renewal for xurl.fyi"

log_message "Removing old DNS challenge records..."
send_slack_notification ":hourglass: Removing old DNS challenge records..."

$ACME_SH --remove-dns-dv -d xurl.fyi
$ACME_SH --remove-dns-dv -d "*.xurl.fyi"

# Ensure removal before proceeding
log_message "Checking for existing _acme-challenge TXT records..."
send_slack_notification ":hourglass: Checking for existing _acme-challenge TXT records..."
dig TXT _acme-challenge.xurl.fyi +short

# Wait a few seconds to allow DNS propagation (adjust as needed)
sleep 10
# Issue/renew the certificate
if $ACME_SH --issue \
    --dns dns_namecom \
    -d xurl.fyi \
    -d "*.xurl.fyi" \
    --server letsencrypt \
    --key-file "$CERT_DIR/xurl.fyi.key" \
    --fullchain-file "$CERT_DIR/xurl.fyi.fullchain.pem" \
    --reloadcmd "nginx -s reload" \
    --force \
    >> $LOG_FILE 2>&1; then
    log_message "Certificate renewal completed successfully"
    send_slack_notification ":white_check_mark: SSL certificate renewed successfully for xurl.fyi"

    # Show certificate expiry date
    EXPIRY_DATE=$(openssl x509 -in "$CERT_DIR/xurl.fyi.fullchain.pem" -noout -enddate | cut -d= -f2 || echo "")
    
    if [[ -n "$EXPIRY_DATE" ]]; then  # Check if EXPIRY_DATE is set before sending notification
        send_slack_notification ":calendar: Certificate expires on: $EXPIRY_DATE"
    else
        log_message "WARNING: Unable to fetch certificate expiry date"
        send_slack_notification ":warning: Unable to fetch SSL certificate expiry date."
    fi

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
