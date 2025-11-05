#!/usr/bin/env python
"""
Check Firebase configuration on production server
Run this on your production server to diagnose the issue
"""
import os
import sys
import json

print("\n🔍 Firebase Production Server Check")
print("=" * 60)

# Check if running in production
print("\n1. Environment Check:")
print(f"   Python version: {sys.version}")
print(f"   Current directory: {os.getcwd()}")

# Check for firebase-adminsdk.json
print("\n2. Checking Firebase credentials file:")
possible_paths = [
    'firebase-adminsdk.json',
    '/app/firebase-adminsdk.json',
    '/home/app/firebase-adminsdk.json',
    os.path.join(os.path.dirname(__file__), 'firebase-adminsdk.json'),
]

found = False
for path in possible_paths:
    print(f"   Checking: {path}")
    if os.path.exists(path):
        print(f"   ✅ Found at: {path}")
        found = True
        
        # Check if readable
        if os.access(path, os.R_OK):
            print(f"   ✅ File is readable")
            
            # Validate JSON
            try:
                with open(path, 'r') as f:
                    data = json.load(f)
                print(f"   ✅ Valid JSON file")
                print(f"   Project ID: {data.get('project_id', 'NOT FOUND')}")
                print(f"   Client Email: {data.get('client_email', 'NOT FOUND')}")
            except Exception as e:
                print(f"   ❌ Error reading file: {e}")
        else:
            print(f"   ❌ File is not readable - check permissions")
        break
    else:
        print(f"   ❌ Not found")

if not found:
    print("\n❌ Firebase credentials file NOT FOUND!")
    print("\n💡 Solution:")
    print("   1. Upload firebase-adminsdk.json to your production server")
    print("   2. Place it in the project root directory")
    print("   3. Ensure it has read permissions (chmod 644)")

# Check Django settings
print("\n3. Checking Django settings:")
try:
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
    import django
    django.setup()
    
    from django.conf import settings
    print(f"   ✅ Django loaded successfully")
    print(f"   BASE_DIR: {settings.BASE_DIR}")
    print(f"   DEBUG: {settings.DEBUG}")
    
    # Check expected path
    expected_path = os.path.join(settings.BASE_DIR, 'firebase-adminsdk.json')
    print(f"\n   Expected path: {expected_path}")
    if os.path.exists(expected_path):
        print(f"   ✅ File exists at expected location")
    else:
        print(f"   ❌ File NOT found at expected location")
        
except Exception as e:
    print(f"   ❌ Error loading Django: {e}")

# Check Firebase Admin SDK
print("\n4. Checking Firebase Admin SDK:")
try:
    import firebase_admin
    from firebase_admin import credentials, messaging
    print(f"   ✅ firebase-admin package installed")
    print(f"   Version: {firebase_admin.__version__}")
    
    # Check if initialized
    if firebase_admin._apps:
        print(f"   ✅ Firebase Admin SDK is initialized")
        print(f"   Apps: {list(firebase_admin._apps.keys())}")
    else:
        print(f"   ⚠️ Firebase Admin SDK NOT initialized")
        print(f"   This is the problem!")
        
except ImportError as e:
    print(f"   ❌ firebase-admin not installed: {e}")
except Exception as e:
    print(f"   ❌ Error: {e}")

# Check FCM service
print("\n5. Checking FCM service initialization:")
try:
    from base.fcm_service import FIREBASE_INITIALIZED, FIREBASE_ERROR
    
    if FIREBASE_INITIALIZED:
        print(f"   ✅ FCM service initialized successfully")
    else:
        print(f"   ❌ FCM service NOT initialized")
        if FIREBASE_ERROR:
            print(f"   Error: {FIREBASE_ERROR}")
        
except Exception as e:
    print(f"   ❌ Error importing FCM service: {e}")

print("\n" + "=" * 60)
print("Check complete!")
print("=" * 60 + "\n")
