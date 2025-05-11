#!/bin/bash
# Direct fix for Django admin CSS issues on Linux server
# Run this script directly on your server as the django user

# Step 1: Go to project directory
cd /home/django/adsyclub

# Step 2: Make a backup of current static files
echo "Creating backup of current static files..."
if [ -d "staticfiles_backup" ]; then
    rm -rf staticfiles_backup
fi
cp -r staticfiles staticfiles_backup

# Step 3: Clear the browser cache by creating a new version string in the static URL
current_date=$(date +%Y%m%d%H%M%S)
sed -i "s/STATIC_URL = '\/static\/'/STATIC_URL = '\/static\/$current_date\/'/g" backend/settings.py

# Step 4: Make sure whitenoise is installed
pip install whitenoise

# Step 5: Set correct static file settings
cat > static_fix_settings.py << EOL
# Insert this in your settings.py
STATIC_URL = '/static/${current_date}/'
STATICFILES_DIRS = []
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')
STATICFILES_FINDERS = [
    'django.contrib.staticfiles.finders.FileSystemFinder',
    'django.contrib.staticfiles.finders.AppDirectoriesFinder',
]
STATICFILES_STORAGE = 'django.contrib.staticfiles.storage.ManifestStaticFilesStorage'
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    # ... rest of your middleware
]
EOL
echo "Created static_fix_settings.py with correct settings. Add these to your settings.py file."

# Step 6: Force clear existing static files
rm -rf staticfiles/*

# Step 7: Collect static files fresh
echo "Collecting static files..."
python manage.py collectstatic --noinput

# Step 8: Fix permissions
echo "Setting permissions..."
chmod -R 755 staticfiles/

# Step 9: Create NGINX configuration
cat > nginx_admin_fix.conf << EOL
# Add this to your NGINX server block
location /static/${current_date}/ {
    alias /home/django/adsyclub/staticfiles/;
    expires 30d;
    add_header Cache-Control "public";
    try_files \$uri \$uri/ =404;
}

# Special rule for admin CSS
location ~ ^/static/${current_date}/admin/(.*)$ {
    alias /home/django/adsyclub/staticfiles/admin/\$1;
    expires 30d;
    add_header Cache-Control "public";
}

# Special rule for jazzmin CSS
location ~ ^/static/${current_date}/jazzmin/(.*)$ {
    alias /home/django/adsyclub/staticfiles/jazzmin/\$1;
    expires 30d;
    add_header Cache-Control "public";
}
EOL

echo ""
echo "========================================================"
echo "Django Admin CSS Fix Complete!"
echo "========================================================"
echo ""
echo "WHAT TO DO NEXT:"
echo "1. Update your settings.py with content from static_fix_settings.py"
echo "2. Update your NGINX config with content from nginx_admin_fix.conf"
echo "3. Run: sudo service nginx restart"
echo "4. Run: sudo service adsyclub restart"
echo ""
echo "This will force browsers to download fresh CSS files with the new URL pattern."
echo "========================================================"