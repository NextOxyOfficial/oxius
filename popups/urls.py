from django.urls import path
from . import views

app_name = 'popups'

urlpatterns = [
    path('api/get-popups/', views.get_active_popups, name='get_active_popups'),
    path('api/record-view/', views.record_popup_view, name='record_popup_view'),
    path('api/record-close/', views.record_popup_close, name='record_popup_close'),
]
