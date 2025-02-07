FROM nginx:alpine

# Install required packages
RUN apk add --no-cache \
    curl \
    openssl \
    socat \
    tzdata \
    bash \
    dcron

USER root
# Install acme.sh
RUN curl https://get.acme.sh | sh 

# Add acme.sh to PATH
ENV PATH="/root/.acme.sh:$PATH"

# Verify acme.sh installation
RUN ls -l /root/.acme.sh
# RUN /root/.acme.sh/acme.sh --version
RUN /root/.acme.sh/acme.sh --version || echo "acme.sh failed to run"

# Create directory for SSL certificates
RUN mkdir -p /etc/nginx/ssl

# Copy and set up the renewal script
COPY renew-cert.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/renew-cert.sh

# Add a cron job for certificate renewal (Runs daily at 3 AM)
RUN echo "0 3 * * * /usr/local/bin/renew-cert.sh >> /var/log/cert-renewal.log 2>&1" > /etc/crontabs/root

# Start cron and Nginx
CMD ["sh", "-c", "crond & nginx -g 'daemon off;'"]
