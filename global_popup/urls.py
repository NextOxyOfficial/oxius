from django.urls import path
from .views import PopupDesktopView, PopupMobileView, PopupViewTrackingView

urlpatterns = [
    path('desktop/', PopupDesktopView.as_view(), name='popup-desktop'),
    path('mobile/', PopupMobileView.as_view(), name='popup-mobile'),
    path('track-view/', PopupViewTrackingView.as_view(), name='popup-track-view'),
]
