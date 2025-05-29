#!/bin/bash

# Pre-Migration Check Script
# Run this first to understand the current state of your database and migrations

echo "=== Pre-Migration Diagnostic Check ==="
echo "Checking current state before applying migration fix..."

echo "1. Current Django migration status:"
python manage.py showmigrations elearning

echo ""
echo "2. Checking if problematic tables exist in database:"
python manage.py shell << 'PYEOF'
from django.db import connection

def check_table_exists(table_name):
    with connection.cursor() as cursor:
        cursor.execute("""
            SELECT COUNT(*)
            FROM information_schema.tables 
            WHERE table_schema = DATABASE() 
            AND table_name = %s
        """, [table_name])
        return cursor.fetchone()[0] > 0

def check_column_exists(table_name, column_name):
    with connection.cursor() as cursor:
        cursor.execute("""
            SELECT COUNT(*)
            FROM information_schema.columns 
            WHERE table_schema = DATABASE() 
            AND table_name = %s 
            AND column_name = %s
        """, [table_name, column_name])
        return cursor.fetchone()[0] > 0

print("=== Database State Check ===")
print(f"elearning_elearningsession table exists: {check_table_exists('elearning_elearningsession')}")
print(f"elearning_userpersonalinfo table exists: {check_table_exists('elearning_userpersonalinfo')}")

if check_table_exists('elearning_elearningsession'):
    print(f"  - user_id column exists: {check_column_exists('elearning_elearningsession', 'user_id')}")
    print(f"  - whatsapp column exists: {check_column_exists('elearning_elearningsession', 'whatsapp')}")
else:
    print("  - Cannot check columns because table doesn't exist")

print("=== Check Complete ===")
PYEOF

echo ""
echo "3. Checking if there are any pending migrations:"
python manage.py migrate --check

echo ""
echo "=== Diagnostic Complete ==="
echo "Now you can run the complete_migration_fix.sh script if needed."
