#!/bin/bash
set -e

# Path to log file
LOG_FILE="/var/log/cert-renewal.log"
CERT_DIR="/etc/nginx/ssl"
ACME_SH="/root/.acme.sh/acme.sh"  # Path to acme.sh

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

# Ensure log file and certificate directory exist
install -m 644 /dev/null $LOG_FILE
mkdir -p $CERT_DIR

# Check if environment variables are set
if [[ -z "$NAMECOM_USERNAME" || -z "$NAMECOM_TOKEN" ]]; then
    log_message "ERROR: Name.com credentials not found in environment variables"
    exit 1
fi

# Export Name.com API credentials for acme.sh
export Namecom_Username="${NAMECOM_USERNAME}"
export Namecom_Token="${NAMECOM_TOKEN}"

log_message "Starting certificate issuance/renewal process"
log_message "Certificates will be saved to: $CERT_DIR"
log_message "Name.com username $NAMECOM_USERNAME"

# Issue/renew the certificate
$ACME_SH --issue \
    --dns dns_namecom \
    -d xurl.fyi \
    -d "*.xurl.fyi" \
    --server letsencrypt \
    --key-file "$CERT_DIR/xurl.fyi.key" \
    --fullchain-file "$CERT_DIR/xurl.fyi.fullchain.pem" \
    --reloadcmd "nginx -s reload" \
    >> $LOG_FILE 2>&1 || exit 1

log_message "Certificate renewal completed successfully"

# List generated certificate files
log_message "Generated certificate files:"
ls -l $CERT_DIR | tee -a $LOG_FILE

# Show certificate expiry date
log_message "Certificate details:"
openssl x509 -in "$CERT_DIR/xurl.fyi.fullchain.pem" -text -noout | grep "Not After" | tee -a $LOG_FILE

# Reload Nginx with new certificates
nginx -s reload || log_message "WARNING: Nginx reload failed!"

echo "
Certificate files are available at:
- Inside container: $CERT_DIR
- On your host machine: ./ssl/

You can verify them with:
docker-compose exec nginx ls -la $CERT_DIR
"
