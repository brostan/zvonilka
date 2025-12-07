#!/bin/bash

# This script obtains SSL certificates using Certbot

# Define the domain for which to obtain the SSL certificate
DOMAIN="your_domain.com"

# Install Certbot if not already installed
if ! command -v certbot &> /dev/null; then
    echo "Certbot not found. Installing..."
    apt-get update
    apt-get install -y certbot
fi

# Obtain the SSL certificate
echo "Obtaining SSL certificate for $DOMAIN..."
certbot certonly --standalone -d $DOMAIN --non-interactive --agree-tos --email your_email@example.com

# Check if the certificate was obtained successfully
if [ $? -eq 0 ]; then
    echo "SSL certificate obtained successfully."
else
    echo "Failed to obtain SSL certificate."
    exit 1
fi

# Restart the web server to apply the new certificate
echo "Restarting web server..."
systemctl restart nginx

echo "SSL setup complete."