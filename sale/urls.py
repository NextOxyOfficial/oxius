from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import SaleCategoryViewSet, SaleChildCategoryViewSet, SalePostViewSet

app_name = 'sale'

router = DefaultRouter()
router.register(r'categories', SaleCategoryViewSet, basename='categories')
router.register(r'child-categories', SaleChildCategoryViewSet, basename='child-categories')
router.register(r'posts', SalePostViewSet, basename='posts')

urlpatterns = [
    path('', include(router.urls)),
]