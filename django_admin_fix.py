#!/usr/bin/env python3
"""
Django Admin CSS Fix Script
----------------------------
This script creates symbolic links to ensure Django admin CSS works correctly.
Run this script on your Linux server after updating your settings.py.

Usage:
    python django_admin_fix.py
"""

import os
import sys
import shutil
import subprocess

def main():
    print("Starting Django Admin CSS Fix...")
    
    # Make sure we're in the project directory
    if not os.path.exists('manage.py'):
        print("Error: Please run this script from the project root directory (where manage.py is located)")
        sys.exit(1)
    
    # Create the required directories if they don't exist
    os.makedirs('staticfiles/admin/css', exist_ok=True)
    os.makedirs('staticfiles/jazzmin/css', exist_ok=True)
    
    # Run the collectstatic command to gather fresh static files
    print("Collecting static files...")
    subprocess.run(['python', 'manage.py', 'collectstatic', '--clear', '--noinput'])
    
    # Fix permissions to ensure web server can access these files
    print("Setting correct permissions...")
    subprocess.run(['chmod', '-R', '755', 'staticfiles'])
    
    # Special handling for Jazzmin theme
    if os.path.exists('staticfiles/jazzmin'):
        print("Optimizing Jazzmin theme files...")
        # Make sure Jazzmin CSS is accessible
        if not os.path.exists('staticfiles/jazzmin/css/main.css'):
            # Try to find Jazzmin CSS files elsewhere and copy them
            for root, dirs, files in os.walk('staticfiles'):
                for file in files:
                    if file.endswith('.css') and 'jazzmin' in root:
                        src = os.path.join(root, file)
                        dst = os.path.join('staticfiles/jazzmin/css', file)
                        print(f"Copying {src} to {dst}")
                        shutil.copy(src, dst)
    
    # Generate a special Nginx configuration snippet
    nginx_config = """
# Django Admin Static Files Configuration
# Add this to your Nginx server block
location /static/admin/ {
    alias %s/staticfiles/admin/;
    expires 30d;
    access_log off;
    add_header Cache-Control "public";
}

location /static/jazzmin/ {
    alias %s/staticfiles/jazzmin/;
    expires 30d;
    access_log off;
    add_header Cache-Control "public";
}
""" % (os.getcwd(), os.getcwd())
    
    with open('nginx-admin-static.conf', 'w') as f:
        f.write(nginx_config)
    
    print("\nDjango Admin CSS Fix completed!")
    print("\nIMPORTANT:")
    print("1. Add the configuration from 'nginx-admin-static.conf' to your Nginx server block")
    print("2. Restart Nginx: sudo service nginx restart")
    print("3. Restart your Django app: sudo service adsyclub restart")

if __name__ == "__main__":
    main()