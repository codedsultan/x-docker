#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root to set up system-wide configuration"
    exit 1
fi

# Create required directories
mkdir -p /var/www/apps/ssl
mkdir -p /var/log/acme.sh
chmod 755 /var/www/apps/ssl
chmod 755 /var/log/acme.sh

# Install required packages
apt-get update
apt-get install -y curl socat

# Set up Slack webhook (replace with your webhook URL)
SLACK_WEBHOOK="https://hooks.slack.com/services/T03TBNVQF6Z/B08BS0SRT8F/UPrQ9jERvRQvfLJ4"

# Function to send Slack notifications
send_slack_notification() {
    local message="$1"
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"$message\"}" \
        "$SLACK_WEBHOOK"
}

# Install acme.sh for all users
curl https://get.acme.sh | sh -s email=your-email@example.com

# Make acme.sh accessible to all users
cp -r ~/.acme.sh /usr/local/share/
chmod -R 755 /usr/local/share/.acme.sh

# Create global acme.sh wrapper script
cat > /usr/local/bin/acme.sh <<'EOF'
#!/bin/bash
export LE_WORKING_DIR=/usr/local/share/.acme.sh
/usr/local/share/.acme.sh/acme.sh --config-home "/var/www/apps/ssl/.acme.sh" "$@"
EOF

chmod 755 /usr/local/bin/acme.sh

# Configure acme.sh
acme.sh --set-default-ca --server letsencrypt
acme.sh --config-home "/var/www/apps/ssl/.acme.sh"

# Configure name.com API credentials

export Namecom_Username="codesultan"
export Namecom_Token="b4a79cac8dd128e88c15b1d92fea5421f70b031a"

# Set stronger key length (4096 bits)
acme.sh --keylength 4096

# Create renewal script
cat > /usr/local/bin/renew-certs.sh <<'EOF'
#!/bin/bash

LOG_FILE="/var/log/acme.sh/renewal.log"
SLACK_WEBHOOK="https://hooks.slack.com/services/T03TBNVQF6Z/B08BS0SRT8F/UPrQ9jERvRQvfLJ4"

echo "$(date): Starting certificate renewal" >> "$LOG_FILE"

# Run acme.sh renewal
acme.sh --cron --home /usr/local/share/.acme.sh \
    --config-home "/var/www/apps/ssl/.acme.sh" \
    >> "$LOG_FILE" 2>&1

RESULT=$?

if [ $RESULT -eq 0 ]; then
    MSG="Certificate renewal completed successfully"
    echo "$(date): $MSG" >> "$LOG_FILE"
    
    # Reload Nginx
    systemctl reload nginx
    NGINX_RESULT=$?
    
    if [ $NGINX_RESULT -eq 0 ]; then
        MSG="$MSG and Nginx reloaded successfully"
    else
        MSG="$MSG but Nginx reload failed"
    fi
    
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"$MSG\"}" \
        "$SLACK_WEBHOOK"
else
    MSG="Certificate renewal failed. Check logs at $LOG_FILE"
    echo "$(date): $MSG" >> "$LOG_FILE"
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"$MSG\"}" \
        "$SLACK_WEBHOOK"
fi
EOF

chmod 755 /usr/local/bin/renew-certs.sh

# Set up 30-day cron job for renewal
(crontab -l 2>/dev/null; echo "0 0 */30 * * /usr/local/bin/renew-certs.sh") | crontab -

# Create an example command file for reference
cat > /usr/local/bin/issue-cert-example.sh <<'EOF'
#!/bin/bash
# Example usage:
# ./issue-cert-example.sh example.com

if [ -z "$1" ]; then
    echo "Usage: $0 domain.com"
    exit 1
fi

DOMAIN=$1
CERT_DIR="/var/www/apps/ssl/$DOMAIN"

# Create certificate directory
mkdir -p "$CERT_DIR"

# Issue certificate
acme.sh --issue --dns dns_namecom -d "$DOMAIN" -d "*.$DOMAIN" \
    --keylength 4096 \
    --cert-file "$CERT_DIR/cert.pem" \
    --key-file "$CERT_DIR/key.pem" \
    --fullchain-file "$CERT_DIR/fullchain.pem" \
    --reloadcmd "systemctl reload nginx"
EOF

chmod 755 /usr/local/bin/issue-cert-example.sh



sudo acme.sh --issue --dns dns_namecom -d yourdomain.com -d *.yourdomain.com \
    --keylength 4096 \
    --cert-file "/var/www/apps/ssl/xurl.fyi/cert.pem" \
    --key-file "/var/www/apps/ssl/xurl.fyi/key.pem" \
    --fullchain-file "/var/www/apps/ssl/xurl.fyi/fullchain.pem" \
    # --reloadcmd "systemctl reload nginx"



# acme.sh --issue \
#     --dns dns_namecom \
#     -d "xurl.fyi" \
#     -d "*.xurl.fyi" \
#     --server letsencrypt \
#     --keylength 4096 \
#     --email "codesultan369@gmail.com" \
#     --key-file "/var/www/apps/ssl/xurl.fyi.key" \
#     --fullchain-file "/var/www/apps/ssl/xurl.fyi.fullchain.pem" \
#     --reloadcmd "nginx -s reload" \
#     --force


acme.sh --issue \
    --dns dns_namecom \
    -d "xurl.fyi" \
    -d "*.xurl.fyi" \
    --server letsencrypt \
    --keylength 4096 \
    --email "codesultan369@gmail.com" \
    --key-file "/var/www/apps/ssl/xurl.fyi.key" \
    --fullchain-file "/var/www/apps/ssl/xurl.fyi.fullchain.pem" \
    --force

    
    