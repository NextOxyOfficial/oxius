from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import SalePostViewSet

app_name = 'sale'

router = DefaultRouter()
router.register(r'sale-posts', SalePostViewSet, basename='sale-posts')

urlpatterns = [
    path('', include(router.urls)),
]