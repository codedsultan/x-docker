#!/bin/sh
set -e

# Path to log file
LOG_FILE="/var/log/cert-renewal.log"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

# Ensure log file exists
touch $LOG_FILE

# Try to renew the certificate
log_message "Starting certificate renewal process"

certbot renew \
    --dns-namecom \
    --dns-namecom-credentials /etc/letsencrypt/namecom/credentials.ini \
    --non-interactive \
    --post-hook "nginx -s reload" \
    >> $LOG_FILE 2>&1

if [ $? -eq 0 ]; then
    log_message "Certificate renewal completed successfully"
else
    log_message "Certificate renewal failed"
    exit 1
fi