from django.urls import path

from .views import check_app_version


urlpatterns = [
    path("check/", check_app_version, name="app-version-check"),
]
