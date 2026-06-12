from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    OutreachDraftViewSet,
    alliance_login,
    donate_context,
    donate_initiate,
    donate_verify,
)

router = DefaultRouter()
router.register(r"drafts", OutreachDraftViewSet, basename="alliance-drafts")

urlpatterns = [
    path("login/", alliance_login, name="alliance-login"),
    path("", include(router.urls)),
    path("donate/context/", donate_context, name="alliance-donate-context"),
    path("donate/initiate/", donate_initiate, name="alliance-donate-initiate"),
    path("donate/verify/", donate_verify, name="alliance-donate-verify"),
]
