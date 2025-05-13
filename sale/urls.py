from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import *

app_name = 'sale'

router = DefaultRouter()
router.register(r'sale-posts', SalePostViewSet, basename='sale-posts')

urlpatterns = [
    path('', include(router.urls)),
    
    # For Sale API endpoints
    path('for-sale-categories/', ForSaleCategoryListView.as_view(), name='for-sale-categories'),
    path('for-sale-sub-categories/<str:category_id>/', ForSaleSubCategoryListView.as_view(), name='for-sale-sub-categories'),
    path('for-sale-banners/', ForSaleBannerListView.as_view(), name='for-sale-banners'),
]