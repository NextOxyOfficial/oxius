from django.urls import path
from .views import *

app_name = 'subscription'

urlpatterns = [
    # Public subscription plan endpoints
    path('plans/', SubscriptionPlanListView.as_view(), name='plan-list'),
    path('plans/<int:pk>/', SubscriptionPlanDetailView.as_view(), name='plan-detail'),
    
    # User subscription endpoints
    path('', UserSubscriptionListCreateView.as_view(), name='subscription-list-create'),
    path('<int:pk>/', UserSubscriptionDetailView.as_view(), name='subscription-detail'),
    path('<int:pk>/activate/', SubscriptionActivateView.as_view(), name='subscription-activate'),
    path('<int:pk>/cancel/', SubscriptionCancelView.as_view(), name='subscription-cancel'),
    path('active/', ActiveSubscriptionView.as_view(), name='active-subscription'),
    
    # Admin endpoints
    path('admin/all/', AdminSubscriptionListView.as_view(), name='admin-subscription-list'),
    path('admin/<int:pk>/', AdminSubscriptionDetailView.as_view(), name='admin-subscription-detail'),
    path('admin/expiring-soon/', ExpiringSoonSubscriptionsView.as_view(), name='expiring-soon'),
    path('admin/recently-expired/', RecentlyExpiredSubscriptionsView.as_view(), name='recently-expired'),
]