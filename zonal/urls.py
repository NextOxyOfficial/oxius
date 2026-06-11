from django.urls import path

from .views import zonal_dashboard, zonal_me

urlpatterns = [
    path("me/", zonal_me, name="zonal-me"),
    path("dashboard/", zonal_dashboard, name="zonal-dashboard"),
]
