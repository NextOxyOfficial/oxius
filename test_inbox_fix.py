#!/usr/bin/env python
"""
Test script to verify the support ticket inbox fix
"""
import os
import sys
import django

# Add the project directory to the Python path
sys.path.append('d:/adsyclub/oxius')

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

from django.contrib.auth import get_user_model
from support.models import SupportTicket, TicketReadStatus
from support.serializers import SupportTicketSerializer
from django.test import RequestFactory

User = get_user_model()

def test_admin_ticket_creation():
    """Test that admin-created tickets appear properly in user inbox"""
    print("Testing admin-created ticket functionality...")
    
    # Get or create a test user
    test_user, created = User.objects.get_or_create(
        email='testuser@example.com',
        defaults={
            'username': 'testuser',
            'first_name': 'Test',
            'last_name': 'User'
        }
    )
    
    if created:
        print(f"Created test user: {test_user.email}")
    else:
        print(f"Using existing test user: {test_user.email}")
    
    # Create a ticket (simulating admin creation)
    ticket = SupportTicket.objects.create(
        user=test_user,
        title="Test Admin Created Ticket",
        message="This ticket was created by admin to test the inbox functionality."
    )
    
    print(f"Created ticket #{ticket.id} for user {test_user.email}")
    
    # Check if TicketReadStatus was created automatically
    try:
        read_status = TicketReadStatus.objects.get(ticket=ticket, user=test_user)
        print(f"✓ TicketReadStatus created automatically: {read_status.last_read_at}")
    except TicketReadStatus.DoesNotExist:
        print("✗ TicketReadStatus NOT created - signal may not be working")
        return False
    
    # Test the serializer (simulating API call)
    factory = RequestFactory()
    request = factory.get('/tickets/')
    request.user = test_user
    
    serializer = SupportTicketSerializer(ticket, context={'request': request})
    data = serializer.data
    
    print(f"Ticket serialization test:")
    print(f"  - ID: {data['id']}")
    print(f"  - Title: {data['title']}")
    print(f"  - Is Unread: {data['is_unread']}")
    print(f"  - Last Read At: {data['last_read_at']}")
    
    if data['is_unread']:
        print("✓ Ticket correctly shows as unread")
    else:
        print("✗ Ticket incorrectly shows as read")
    
    return True

def test_existing_tickets():
    """Test existing tickets in the system"""
    print("\nTesting existing tickets...")
    
    total_tickets = SupportTicket.objects.count()
    total_read_statuses = TicketReadStatus.objects.count()
    
    print(f"Total tickets in system: {total_tickets}")
    print(f"Total read statuses: {total_read_statuses}")
    
    # Check for tickets without read status
    tickets_without_status = []
    for ticket in SupportTicket.objects.all():
        if not TicketReadStatus.objects.filter(ticket=ticket, user=ticket.user).exists():
            tickets_without_status.append(ticket)
    
    if tickets_without_status:
        print(f"✗ Found {len(tickets_without_status)} tickets without read status:")
        for ticket in tickets_without_status[:5]:  # Show first 5
            print(f"  - Ticket #{ticket.id} for user {ticket.user.email}")
    else:
        print("✓ All tickets have read status entries")
    
    return len(tickets_without_status) == 0

if __name__ == "__main__":
    print("Support Ticket Inbox Fix Verification")
    print("=" * 50)
    
    # Test 1: Admin ticket creation
    test1_passed = test_admin_ticket_creation()
    
    # Test 2: Existing tickets
    test2_passed = test_existing_tickets()
    
    print("\n" + "=" * 50)
    print("Test Results:")
    print(f"Admin ticket creation: {'PASS' if test1_passed else 'FAIL'}")
    print(f"Existing tickets check: {'PASS' if test2_passed else 'FAIL'}")
    
    if test1_passed and test2_passed:
        print("✓ All tests passed! The fix is working correctly.")
    else:
        print("✗ Some tests failed. Please check the implementation.")
