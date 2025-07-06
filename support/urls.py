from django.urls import path
from .views import (
    SupportTicketListCreateView,
    SupportTicketDetailView,
    TicketReplyCreateView,
    UpdateTicketStatusView,
    PublicContactCreateView,
    PublicContactListView,
    PublicContactDetailView,
)
from .read_status_views import MarkTicketReadView, MarkTicketUnreadView

app_name = "support"

urlpatterns = [
    # Public contact endpoints
    path(
        "public-contact/",
        PublicContactCreateView.as_view(),
        name="public-contact-create",
    ),
    path(
        "public-contacts/", PublicContactListView.as_view(), name="public-contact-list"
    ),
    path(
        "public-contacts/<str:pk>/",
        PublicContactDetailView.as_view(),
        name="public-contact-detail",
    ),
    # Support ticket endpoints
    path("tickets/", SupportTicketListCreateView.as_view(), name="ticket-list"),
    path("tickets/<str:pk>/", SupportTicketDetailView.as_view(), name="ticket-detail"),
    path(
        "tickets/<str:ticket_id>/replies/",
        TicketReplyCreateView.as_view(),
        name="ticket-reply",
    ),
    path(
        "tickets/<str:ticket_id>/status/",
        UpdateTicketStatusView.as_view(),
        name="update-ticket-status",
    ),
    path(
        "tickets/<str:ticket_id>/mark-read/",
        MarkTicketReadView.as_view(),
        name="mark-ticket-read",
    ),
    path(
        "tickets/<str:ticket_id>/mark-unread/",
        MarkTicketUnreadView.as_view(),
        name="mark-ticket-unread",
    ),
]
