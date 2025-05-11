#!/bin/bash

# Script to fix Django admin CSS issues on Linux server
# Created to resolve static files serving issue

echo "Starting Django admin CSS fix..."

# Install whitenoise if not already installed
pip install whitenoise

# Create symbolic link to ensure admin files are accessible
cd /home/django/adsyclub/
mkdir -p staticfiles/admin

# Make sure jazzmin directory exists
mkdir -p staticfiles/jazzmin

# Collect static files fresh (force overwrite)
python manage.py collectstatic --clear --noinput

# Fix permissions
chmod -R 755 staticfiles/

# Create Nginx configuration for serving static files directly
echo "
# Add to your Nginx configuration
location /static/ {
    alias /home/django/adsyclub/staticfiles/;
    expires 30d;
    access_log off;
    add_header Cache-Control "public";
}
" > nginx_static_config.txt

echo "CSS fix completed! Please:"
echo "1. Add the Nginx configuration from nginx_static_config.txt to your server"
echo "2. Restart Nginx with: sudo service nginx restart"
echo "3. Restart Django app with: sudo service adsyclub restart"