from django.urls import path
from .views import *

urlpatterns = [
    path('mobile-recharge/operators/', OperatorListView.as_view(), name='operator-list'),
    path('mobile-recharge/operators/<int:pk>/', OperatorDetailView.as_view(), name='operator-detail'),
    path('mobile-recharge/packages/', PackageListView.as_view(), name='package-list'),
    path('mobile-recharge/packages/<int:pk>/', PackageDetailView.as_view(), name='package-detail'),
    path('mobile-recharge/recharges/', RechargeListCreateView.as_view(), name='recharge-list-create'),
    path('mobile-recharge/recharges/<int:pk>/', RechargeDetailView.as_view(), name='recharge-detail'),
]