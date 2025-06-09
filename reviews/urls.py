from django.urls import path
from . import views

app_name = 'reviews'

urlpatterns = [
    # Product reviews
    path('products/<uuid:product_id>/reviews/', 
         views.ProductReviewListCreateView.as_view(), 
         name='product-reviews'),
    
    # Product rating stats
    path('products/<uuid:product_id>/stats/', 
         views.ProductRatingStatsView.as_view(), 
         name='product-rating-stats'),
    
    # Individual review operations
    path('reviews/<uuid:pk>/', 
         views.ReviewDetailView.as_view(), 
         name='review-detail'),
    
    # Review helpful votes
    path('reviews/<uuid:review_id>/helpful/', 
         views.toggle_review_helpful, 
         name='toggle-review-helpful'),
    
    # User's review for a specific product
    path('products/<uuid:product_id>/my-review/', 
         views.user_review_for_product, 
         name='user-review-for-product'),
    
    # User's all reviews
    path('my-reviews/', 
         views.UserReviewsListView.as_view(), 
         name='user-reviews'),
    
    # Store owner's reviews (reviews on their products)
    path('store-reviews/', 
         views.StoreReviewsListView.as_view(), 
         name='store-reviews'),
    
    # Store reviews count
    path('store-reviews/count/', 
         views.store_reviews_count, 
         name='store-reviews-count'),
]
