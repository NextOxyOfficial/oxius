from django.urls import path
from . import views

urlpatterns = [
    path('program/', views.get_active_program, name='active-program'),
    path('my-claims/', views.get_my_claims, name='my-claims'),
    path('check-conditions/', views.check_conditions, name='check-conditions'),
    path('claim/<int:claim_id>/', views.claim_reward, name='claim-reward'),
]
