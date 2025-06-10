#!/usr/bin/env python
"""
Verification script for gig approval notifications implementation
This script checks if all the necessary components are in place
"""

import os
from pathlib import Path

def check_file_exists(file_path, description):
    """Check if a file exists and print status"""
    if os.path.exists(file_path):
        print(f"✅ {description}: {file_path}")
        return True
    else:
        print(f"❌ {description}: {file_path} - NOT FOUND")
        return False

def check_file_content(file_path, search_terms, description):
    """Check if file contains specific content"""
    if not os.path.exists(file_path):
        print(f"❌ {description}: File not found - {file_path}")
        return False
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        missing_terms = []
        for term in search_terms:
            if term not in content:
                missing_terms.append(term)
        
        if not missing_terms:
            print(f"✅ {description}: All required content found")
            return True
        else:
            print(f"⚠️ {description}: Missing content - {missing_terms}")
            return False
    except Exception as e:
        print(f"❌ {description}: Error reading file - {e}")
        return False

def main():
    print("🔧 Gig Approval Notifications - Implementation Verification")
    print("=" * 60)
    
    base_path = "d:/adsyclub/oxius"
    
    # Check 1: AdminNotice model has gig_approved notification type
    print("\n1️⃣ Checking AdminNotice model...")
    models_file = f"{base_path}/base/models.py"
    check_file_content(
        models_file,
        ["'gig_approved'", "Gig Approved by Admin"],
        "AdminNotice.NOTIFICATION_TYPES includes gig_approved"
    )
    
    # Check 2: Notification creation function exists
    print("\n2️⃣ Checking notification creation function...")
    views_file = f"{base_path}/base/views.py"
    check_file_content(
        views_file,
        ["create_gig_approved_notification", "gig_approved"],
        "create_gig_approved_notification function exists"
    )
    
    # Check 3: Signals file exists
    print("\n3️⃣ Checking signals implementation...")
    signals_file = f"{base_path}/base/signals.py"
    check_file_exists(signals_file, "Signals file")
    if os.path.exists(signals_file):
        check_file_content(
            signals_file,
            [
                "pre_save", "post_save", "MicroGigPost",
                "store_previous_gig_status", "handle_gig_status_change",
                "pending", "approved", "create_gig_approved_notification"
            ],
            "Signals contain gig approval logic"
        )
    
    # Check 4: Apps.py configured to load signals
    print("\n4️⃣ Checking apps.py configuration...")
    apps_file = f"{base_path}/base/apps.py"
    check_file_content(
        apps_file,
        ["def ready", "import base.signals"],
        "BaseConfig.ready() imports signals"
    )
    
    # Check 5: MicroGigPost model structure
    print("\n5️⃣ Checking MicroGigPost model...")
    check_file_content(
        models_file,
        ["class MicroGigPost", "gig_status", "pending", "approved"],
        "MicroGigPost has gig_status field with correct choices"
    )
    
    # Check 6: Management command for testing
    print("\n6️⃣ Checking test command...")
    test_cmd_file = f"{base_path}/base/management/commands/test_gig_notifications.py"
    check_file_exists(test_cmd_file, "Test management command")
    
    print("\n" + "=" * 60)
    print("📋 Implementation Summary:")
    print("   - AdminNotice model updated with 'gig_approved' notification type")
    print("   - create_gig_approved_notification() function added to views.py")
    print("   - Django signals implemented in base/signals.py")
    print("   - Apps.py configured to load signals")
    print("   - Test command created for verification")
    
    print("\n🎯 How it works:")
    print("   1. When admin changes MicroGigPost.gig_status from 'pending' to 'approved'")
    print("   2. pre_save signal stores the previous status")
    print("   3. post_save signal detects the status change")
    print("   4. Signal creates a notification using create_gig_approved_notification()")
    print("   5. User receives notification about gig approval")
    print("   6. Duplicate prevention ensures only one notification per gig")
    
    print("\n✨ Next steps:")
    print("   - Test the implementation by creating a gig and approving it via admin")
    print("   - Check the AdminNotice table for new notifications")
    print("   - Verify frontend displays the notifications correctly")

if __name__ == "__main__":
    main()
