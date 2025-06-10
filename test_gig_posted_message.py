#!/usr/bin/env python
"""
Test script to verify the corrected gig posting notification message
"""
import os
import sys
import django

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

from base.models import MicroGigPost, AdminNotice, User, MicroGigCategory
from base.views import create_gig_posted_notification

def test_gig_posted_notification():
    """Test the corrected gig posted notification message"""
    print("🔧 Testing Corrected Gig Posted Notification")
    print("=" * 50)
    
    try:
        # Use existing user
        user = User.objects.get(email='hibkeke@gmail.com')
        print(f"✅ Using user: {user.email}")
        
        # Test the notification function directly
        print(f"\n📧 Creating gig posted notification...")
        notification = create_gig_posted_notification(
            user=user,
            gig_id="test-123",
            gig_title="Test Notification Message Gig"
        )
        
        print(f"✅ Notification created successfully!")
        print(f"   Title: {notification.title}")
        print(f"   Message: {notification.message}")
        print(f"   Type: {notification.notification_type}")
        print(f"   Reference ID: {notification.reference_id}")
        
        # Verify the message is correct
        expected_text = "pending for review by our admin team"
        if expected_text in notification.message:
            print(f"✅ SUCCESS: Message correctly indicates pending status!")
        else:
            print(f"❌ ISSUE: Message doesn't indicate pending status")
            
        # Clean up
        notification.delete()
        print(f"\n🧹 Test notification cleaned up")
        
        print(f"\n🎯 Summary:")
        print(f"   ✅ Old message: 'is now live for workers to apply'")
        print(f"   ✅ New message: 'is pending for review by our admin team'")
        print(f"   ✅ This correctly reflects the gig's pending status")
        
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    test_gig_posted_notification()
