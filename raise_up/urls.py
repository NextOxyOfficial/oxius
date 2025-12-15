from django.urls import path
from . import views

urlpatterns = [
    # Main CRUD endpoints
    path('posts/', views.RaiseUpPostListView.as_view(), name='raise_up_posts'),
    path('posts/<int:pk>/', views.RaiseUpPostDetailView.as_view(), name='raise_up_post_detail'),
    
    # Special endpoints
    path('featured/', views.featured_posts, name='featured_posts'),
    path('stats/', views.post_stats, name='post_stats'),
    
    # Investment/Donation endpoints
    path('posts/<int:post_id>/invest/', views.invest_in_post, name='invest_in_post'),
    path('posts/<int:post_id>/donate/', views.donate_to_post, name='donate_to_post'),
]
