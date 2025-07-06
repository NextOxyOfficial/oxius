from rest_framework import generics, status, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.exceptions import PermissionDenied
from django.shortcuts import get_object_or_404
from django.utils import timezone
from .models import SupportTicket, TicketReadStatus, PublicContact
from .serializers import (
    SupportTicketSerializer,
    SupportTicketCreateSerializer,
    TicketReplyCreateSerializer,
    PublicContactSerializer,
    PublicContactListSerializer,
)


class SupportTicketListCreateView(generics.ListCreateAPIView):
    """
    List all support tickets for the current user or create a new one
    """

    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.is_staff:
            return SupportTicket.objects.all()
        return SupportTicket.objects.filter(user=user)

    def get_serializer_class(self):
        if self.request.method == "POST":
            return SupportTicketCreateSerializer
        return SupportTicketSerializer

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class SupportTicketDetailView(generics.RetrieveAPIView):
    """
    Retrieve a support ticket and its replies
    """

    permission_classes = [permissions.IsAuthenticated]
    serializer_class = SupportTicketSerializer

    def get_queryset(self):
        user = self.request.user
        if user.is_staff:
            return SupportTicket.objects.all()
        return SupportTicket.objects.filter(user=user)

    def get_serializer_context(self):
        context = super().get_serializer_context()
        return context

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        user = request.user

        # Update or create read status for this ticket
        # This will automatically remove the "unread" label when viewing the ticket
        read_status, created = TicketReadStatus.objects.update_or_create(
            ticket=instance, user=user, defaults={"last_read_at": timezone.now()}
        )

        serializer = self.get_serializer(instance)
        return Response(serializer.data)


class TicketReplyCreateView(generics.CreateAPIView):
    """
    Add a reply to a support ticket
    """

    permission_classes = [permissions.IsAuthenticated]
    serializer_class = TicketReplyCreateSerializer

    def perform_create(self, serializer):
        ticket_id = self.kwargs.get("ticket_id")
        ticket = get_object_or_404(SupportTicket, id=ticket_id)

        user = self.request.user
        # Check if user has access to this ticket
        if not user.is_staff and user != ticket.user:
            raise PermissionDenied("You don't have permission to reply to this ticket")

        # Mark replies from admin users
        is_admin = user.is_staff or user.is_superuser

        # If an admin is replying, update the ticket status to "in progress"
        if is_admin and ticket.status == "open":
            ticket.status = "in_progress"
            ticket.save()

        serializer.save(ticket=ticket, user=user, is_from_admin=is_admin)


class UpdateTicketStatusView(APIView):
    """
    Update the status of a support ticket
    """

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, ticket_id):
        ticket = get_object_or_404(SupportTicket, id=ticket_id)
        new_status = request.data.get("status")

        # Check permissions: Admin can update any status, users can only close their own resolved tickets
        if not request.user.is_staff:
            # Non-admin users can only close their own tickets that are resolved
            if ticket.user != request.user:
                return Response(
                    {"error": "You can only update your own tickets."},
                    status=status.HTTP_403_FORBIDDEN,
                )
            if new_status != "closed":
                return Response(
                    {"error": "You can only close tickets."},
                    status=status.HTTP_403_FORBIDDEN,
                )
            if ticket.status != "resolved":
                return Response(
                    {"error": "You can only close resolved tickets."},
                    status=status.HTTP_403_FORBIDDEN,
                )

        valid_statuses = [s[0] for s in SupportTicket.STATUS_CHOICES]
        if new_status not in valid_statuses:
            return Response(
                {
                    "error": f"Invalid status. Must be one of: {', '.join(valid_statuses)}"
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        ticket.status = new_status
        ticket.save()

        return Response(
            {"status": "success", "message": f"Ticket status updated to {new_status}"},
            status=status.HTTP_200_OK,
        )


class PublicContactCreateView(generics.CreateAPIView):
    """
    Create a new public contact submission (no authentication required)
    """

    queryset = PublicContact.objects.all()
    serializer_class = PublicContactSerializer
    permission_classes = [permissions.AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        # Create the contact
        contact = serializer.save()

        # You can add email notification logic here
        # send_contact_notification.delay(contact.id)

        return Response(
            {
                "success": True,
                "message": "Thank you for your message. We will get back to you soon!",
                "contact_id": contact.id,
            },
            status=status.HTTP_201_CREATED,
        )


class PublicContactListView(generics.ListAPIView):
    """
    List all public contacts (admin only)
    """

    queryset = PublicContact.objects.all()
    serializer_class = PublicContactListSerializer
    permission_classes = [permissions.IsAdminUser]

    def get_queryset(self):
        queryset = super().get_queryset()
        status_filter = self.request.query_params.get("status", None)
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        return queryset


class PublicContactDetailView(generics.RetrieveUpdateAPIView):
    """
    Retrieve or update a public contact (admin only)
    """

    queryset = PublicContact.objects.all()
    serializer_class = PublicContactListSerializer
    permission_classes = [permissions.IsAdminUser]

    def perform_update(self, serializer):
        # Track who responded
        if "status" in serializer.validated_data:
            new_status = serializer.validated_data["status"]
            if new_status == "responded" and self.get_object().status != "responded":
                serializer.save(
                    responded_by=self.request.user, responded_at=timezone.now()
                )
            else:
                serializer.save()
        else:
            serializer.save()
