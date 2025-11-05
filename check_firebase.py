#!/usr/bin/env python
"""
Check Firebase Admin SDK configuration
"""
import os
import sys
import json

# Add project to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

print("\n🔍 Firebase Admin SDK Configuration Check")
print("=" * 60)

# Check if firebase-adminsdk.json exists
cred_path = os.path.join(os.path.dirname(__file__), 'firebase-adminsdk.json')
print(f"\n1. Checking credentials file...")
print(f"   Path: {cred_path}")

if os.path.exists(cred_path):
    print(f"   ✅ File exists")
    
    # Check file permissions
    if os.access(cred_path, os.R_OK):
        print(f"   ✅ File is readable")
    else:
        print(f"   ❌ File is not readable - check permissions")
        sys.exit(1)
    
    # Validate JSON structure
    try:
        with open(cred_path, 'r') as f:
            cred_data = json.load(f)
        
        print(f"   ✅ Valid JSON file")
        
        # Check required fields
        required_fields = ['type', 'project_id', 'private_key_id', 'private_key', 'client_email']
        missing_fields = [field for field in required_fields if field not in cred_data]
        
        if missing_fields:
            print(f"   ❌ Missing required fields: {', '.join(missing_fields)}")
            sys.exit(1)
        else:
            print(f"   ✅ All required fields present")
            print(f"   Project ID: {cred_data.get('project_id')}")
            print(f"   Client Email: {cred_data.get('client_email')}")
    
    except json.JSONDecodeError as e:
        print(f"   ❌ Invalid JSON: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"   ❌ Error reading file: {e}")
        sys.exit(1)
else:
    print(f"   ❌ File not found!")
    print(f"\n💡 Solution:")
    print(f"   1. Go to Firebase Console: https://console.firebase.google.com/")
    print(f"   2. Select your project")
    print(f"   3. Go to Project Settings > Service Accounts")
    print(f"   4. Click 'Generate New Private Key'")
    print(f"   5. Save the file as 'firebase-adminsdk.json' in: {os.path.dirname(__file__)}")
    sys.exit(1)

# Try to initialize Firebase Admin SDK
print(f"\n2. Testing Firebase Admin SDK initialization...")
try:
    import firebase_admin
    from firebase_admin import credentials, messaging
    
    if not firebase_admin._apps:
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
        print(f"   ✅ Firebase Admin SDK initialized successfully")
    else:
        print(f"   ✅ Firebase Admin SDK already initialized")
    
    # Test messaging module
    print(f"\n3. Testing Firebase Messaging module...")
    print(f"   ✅ Messaging module imported successfully")
    
except ImportError as e:
    print(f"   ❌ Missing Python package: {e}")
    print(f"\n💡 Solution:")
    print(f"   pip install firebase-admin")
    sys.exit(1)
except Exception as e:
    print(f"   ❌ Error: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

# Check Django setup
print(f"\n4. Checking Django integration...")
try:
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
    import django
    django.setup()
    
    from base.models import FCMToken
    from django.contrib.auth import get_user_model
    
    User = get_user_model()
    
    print(f"   ✅ Django setup successful")
    
    # Check database
    total_tokens = FCMToken.objects.filter(is_active=True).count()
    total_users = User.objects.filter(fcm_tokens__is_active=True).distinct().count()
    
    print(f"\n5. Database statistics:")
    print(f"   Active FCM tokens: {total_tokens}")
    print(f"   Users with tokens: {total_users}")
    
    if total_tokens == 0:
        print(f"\n   ⚠️ No active FCM tokens found!")
        print(f"   💡 Make sure:")
        print(f"      1. User is logged into the mobile app")
        print(f"      2. App has requested notification permissions")
        print(f"      3. FCM token is being saved to database")
    else:
        print(f"   ✅ Tokens found in database")
        
        # Show recent token
        recent_token = FCMToken.objects.filter(is_active=True).first()
        if recent_token:
            print(f"\n   Most recent token:")
            print(f"   - User: {recent_token.user.email}")
            print(f"   - Device: {recent_token.device_type}")
            print(f"   - Updated: {recent_token.updated_at}")

except Exception as e:
    print(f"   ❌ Django setup failed: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

print(f"\n" + "=" * 60)
print(f"✅ All checks passed! Firebase is configured correctly.")
print(f"\n💡 If notifications still fail, check:")
print(f"   1. Django server logs when sending notification")
print(f"   2. Firebase Console > Cloud Messaging for errors")
print(f"   3. Mobile app logs for FCM token registration")
print(f"=" * 60 + "\n")
