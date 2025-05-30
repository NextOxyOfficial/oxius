from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from support.models import SupportTicket, TicketReadStatus
from support.serializers import SupportTicketSerializer
from rest_framework.request import Request
from django.test import RequestFactory

User = get_user_model()


class Command(BaseCommand):
    help = 'Test the support ticket inbox functionality'

    def add_arguments(self, parser):
        parser.add_argument(
            '--user-id',
            type=int,
            help='User ID to test the inbox for',
        )
        parser.add_argument(
            '--create-test-ticket',
            action='store_true',
            help='Create a test ticket for the user',
        )

    def handle(self, *args, **options):
        user_id = options.get('user_id')
        create_test = options.get('create_test_ticket')

        if not user_id:
            # Show all users with tickets
            users_with_tickets = User.objects.filter(tickets__isnull=False).distinct()
            self.stdout.write("Users with support tickets:")
            for user in users_with_tickets:
                ticket_count = user.tickets.count()
                unread_count = 0
                for ticket in user.tickets.all():
                    try:
                        read_status = ticket.read_statuses.get(user=user)
                        latest_reply = ticket.replies.order_by('-created_at').first()
                        if latest_reply:
                            latest_activity_time = latest_reply.created_at
                        else:
                            latest_activity_time = ticket.created_at
                        if latest_activity_time > read_status.last_read_at:
                            unread_count += 1
                    except:
                        unread_count += 1
                
                self.stdout.write(f"  User ID {user.id} ({user.email}): {ticket_count} tickets, {unread_count} unread")
            return

        try:
            user = User.objects.get(id=user_id)
        except User.DoesNotExist:
            self.stdout.write(self.style.ERROR(f'User with ID {user_id} does not exist'))
            return

        if create_test:
            # Create a test ticket for the user (simulating admin creation)
            ticket = SupportTicket.objects.create(
                user=user,
                title="Test Ticket Created by Admin",
                message="This is a test ticket created by admin to verify the inbox functionality."
            )
            self.stdout.write(
                self.style.SUCCESS(f'Created test ticket #{ticket.id} for user {user.email}')
            )

        # Test the ticket serialization (simulating API call)
        factory = RequestFactory()
        request = factory.get('/tickets/')
        request.user = user

        tickets = SupportTicket.objects.filter(user=user)
        self.stdout.write(f"\nTickets for user {user.email} (ID: {user.id}):")
        
        for ticket in tickets:
            # Simulate serializer context
            class MockRequest:
                def __init__(self, user):
                    self.user = user
            
            mock_request = MockRequest(user)
            serializer = SupportTicketSerializer(ticket, context={'request': mock_request})
            data = serializer.data
            
            # Check read status
            try:
                read_status = ticket.read_statuses.get(user=user)
                read_status_info = f"Last read: {read_status.last_read_at}"
            except:
                read_status_info = "No read status found"
            
            self.stdout.write(f"  Ticket #{ticket.id}:")
            self.stdout.write(f"    Title: {ticket.title}")
            self.stdout.write(f"    Status: {ticket.status}")
            self.stdout.write(f"    Created: {ticket.created_at}")
            self.stdout.write(f"    Is Unread: {data['is_unread']}")
            self.stdout.write(f"    Read Status: {read_status_info}")
            self.stdout.write(f"    Replies: {data['reply_count']}")
            self.stdout.write("")
