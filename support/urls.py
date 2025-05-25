from django.urls import path
from .views import (
    SupportTicketListCreateView,
    SupportTicketDetailView,
    TicketReplyCreateView,
    UpdateTicketStatusView
)

app_name = 'support'

urlpatterns = [
    path('tickets/', SupportTicketListCreateView.as_view(), name='ticket-list'),
    path('tickets/<str:pk>/', SupportTicketDetailView.as_view(), name='ticket-detail'),
    path('tickets/<str:ticket_id>/replies/', TicketReplyCreateView.as_view(), name='ticket-reply'),
    path('tickets/<str:ticket_id>/status/', UpdateTicketStatusView.as_view(), name='update-ticket-status'),
]
