from django.urls import path

from .views import ads_config

urlpatterns = [
    path("config/", ads_config, name="ads-config"),
]
