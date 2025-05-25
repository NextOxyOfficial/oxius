from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404
from django.utils import timezone
from .models import SupportTicket, TicketReadStatus

class MarkTicketReadView(APIView):
    """
    Mark a ticket as read by the current user
    """
    permission_classes = [IsAuthenticated]
    
    def post(self, request, ticket_id):
        # Get the ticket
        ticket = get_object_or_404(SupportTicket, id=ticket_id)
        user = request.user
          # Check if user has access to this ticket (either owner or staff)
        if not (user.is_staff or user == ticket.user):
            return Response(
                {"error": "You don't have permission to access this ticket"},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Update or create read status - just update the timestamp to mark as read
        read_status, created = TicketReadStatus.objects.update_or_create(
            user=user,
            ticket=ticket,
            defaults={'last_read_at': timezone.now()}
        )
        
        # Update the ticket's last_read_at field if this is the owner
        if user == ticket.user:
            ticket.last_read_at = timezone.now()
            ticket.save(update_fields=['last_read_at'])
        
        return Response(
            {"status": "success", "message": "Ticket viewed"},
            status=status.HTTP_200_OK
        )


class MarkTicketUnreadView(APIView):
    """
    Mark a ticket as unread by the current user
    """
    permission_classes = [IsAuthenticated]
    
    def post(self, request, ticket_id):
        # Get the ticket
        ticket = get_object_or_404(SupportTicket, id=ticket_id)
        user = request.user
          # Check if user has access to this ticket (either owner or staff)
        if not (user.is_staff or user == ticket.user):
            return Response(
                {"error": "You don't have permission to access this ticket"},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # To mark as unread, we'll delete the read record if it exists
        # This will cause get_has_unread in serializer to return True
        try:
            TicketReadStatus.objects.filter(
                user=user,
                ticket=ticket
            ).delete()
        except:
            pass
        
        return Response(
            {"status": "success", "message": "Ticket marked as unread"},
            status=status.HTTP_200_OK
        )
