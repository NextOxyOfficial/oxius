from django.urls import path
from .views import (
    GigListView, GigDetailView, GigCreateView, GigUpdateView, GigDeleteView,
    MyGigsView, toggle_favorite, MyFavoritesView,
    GigReviewListView, create_review,
    MyOrdersView, MySellerOrdersView, create_order,
    gig_categories
)

urlpatterns = [
    # Gig endpoints
    path('gigs/', GigListView.as_view(), name='gig-list'),
    path('gigs/create/', GigCreateView.as_view(), name='gig-create'),
    path('gigs/my/', MyGigsView.as_view(), name='my-gigs'),
    path('gigs/categories/', gig_categories, name='gig-categories'),
    path('gigs/<uuid:id>/', GigDetailView.as_view(), name='gig-detail'),
    path('gigs/<uuid:id>/update/', GigUpdateView.as_view(), name='gig-update'),
    path('gigs/<uuid:id>/delete/', GigDeleteView.as_view(), name='gig-delete'),
    
    # Favorite endpoints
    path('gigs/<uuid:gig_id>/favorite/', toggle_favorite, name='gig-favorite'),
    path('favorites/', MyFavoritesView.as_view(), name='my-favorites'),
    
    # Review endpoints
    path('gigs/<uuid:gig_id>/reviews/', GigReviewListView.as_view(), name='gig-reviews'),
    path('gigs/<uuid:gig_id>/reviews/create/', create_review, name='create-review'),
    
    # Order endpoints
    path('gigs/<uuid:gig_id>/order/', create_order, name='create-order'),
    path('orders/', MyOrdersView.as_view(), name='my-orders'),
    path('orders/seller/', MySellerOrdersView.as_view(), name='seller-orders'),
]
