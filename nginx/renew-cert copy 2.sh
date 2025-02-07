#!/bin/bash
set -e

# Path to log file
LOG_FILE="/var/log/cert-renewal.log"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

# Ensure log file exists
touch $LOG_FILE

# Check if environment variables are set
if [ -z "$NAMECOM_USERNAME" ] || [ -z "$NAMECOM_TOKEN" ]; then
    log_message "ERROR: Name.com credentials not found in environment variables"
    exit 1
fi

# Export Name.com API credentials for acme.sh
export Namecom_Username="${NAMECOM_USERNAME}"
export Namecom_Token="${NAMECOM_TOKEN}"

log_message "Starting certificate issuance/renewal process"

# Issue/renew the certificate
acme.sh --issue \
    --dns dns_namecom \
    -d xurl.fyi \
    -d "*.xurl.fyi" \
    --server letsencrypt \
    --key-file /etc/nginx/ssl/xurl.fyi.key \
    --fullchain-file /etc/nginx/ssl/xurl.fyi.fullchain.pem \
    --reloadcmd "nginx -s reload" \
    >> $LOG_FILE 2>&1

if [ $? -eq 0 ]; then
    log_message "Certificate renewal completed successfully"
    
    # Verify certificate files exist
    if [ -f "/etc/nginx/ssl/xurl.fyi.key" ] && [ -f "/etc/nginx/ssl/xurl.fyi.fullchain.pem" ]; then
        log_message "Certificate files verified"
        # Reload Nginx to apply new certificates
        nginx -s reload
    else
        log_message "ERROR: Certificate files not found after renewal"
        exit 1
    fi
else
    log_message "Certificate renewal failed"
    exit 1
fi