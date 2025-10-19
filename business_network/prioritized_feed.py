from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.db.models import Count, Q, Case, When, IntegerField, Value, Subquery
from base.models import User
from .models import BusinessNetworkPost, BusinessNetworkFollowerModel, HiddenPost

class PrioritizedFeedView(APIView):
    """
    API endpoint to get prioritized business network posts
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        user = request.user
        
        # Priority 1: Posts from users I'm following
        users_i_follow_subquery = BusinessNetworkFollowerModel.objects.filter(
            follower=user
        ).values('following_id')
        
        # Priority 2: Posts from followers of users I'm following  
        followers_of_my_followings_subquery = BusinessNetworkFollowerModel.objects.filter(
            following_id__in=Subquery(users_i_follow_subquery)
        ).values('follower_id')
        
        # Priority 3: Posts from my followers
        my_followers_subquery = BusinessNetworkFollowerModel.objects.filter(
            following=user
        ).values('follower_id')
        
        # Priority 4: Posts from users that my followings are following
        followings_of_my_followings_subquery = BusinessNetworkFollowerModel.objects.filter(
            follower_id__in=Subquery(users_i_follow_subquery)
        ).values('following_id')
        
        # Priority 5: Posts from nearby cities
        nearby_users_conditions = Q()
        if user.city:
            nearby_users_conditions |= Q(city__iexact=user.city)
            if user.state and user.state != user.city:
                nearby_users_conditions |= Q(state__iexact=user.state)
        
        nearby_users_subquery = User.objects.filter(
            nearby_users_conditions
        ).exclude(id=user.id).values('id')        # Create prioritized queryset
        # Only prioritize user's own posts from the last 24 hours to maintain feed freshness
        from django.utils import timezone
        from datetime import timedelta
        
        recent_threshold = timezone.now() - timedelta(hours=24)
        
        # Get hidden post IDs for this user
        hidden_post_ids = HiddenPost.objects.filter(user=user).values_list('post_id', flat=True)
        
        queryset = BusinessNetworkPost.objects.exclude(
            id__in=hidden_post_ids  # Exclude hidden posts
        ).annotate(
            priority=Case(
                # Priority 1: User's own recent posts (last 24 hours only)
                When(author=user, created_at__gte=recent_threshold, then=Value(1)),
                When(author_id__in=Subquery(users_i_follow_subquery), then=Value(2)),
                When(author_id__in=Subquery(followers_of_my_followings_subquery), then=Value(3)),
                When(author_id__in=Subquery(my_followers_subquery), then=Value(4)),
                When(author_id__in=Subquery(followings_of_my_followings_subquery), then=Value(5)),
                When(author_id__in=Subquery(nearby_users_subquery), then=Value(6)),
                default=Value(7),
                output_field=IntegerField()
            )
        ).select_related('author').order_by('priority', '-created_at')
        
        # Get statistics
        total_posts = queryset.count()
        priority_stats = queryset.values('priority').annotate(count=Count('id')).order_by('priority')
        
        # Get first 20 posts for display
        posts = queryset[:20].values(
            'id', 'title', 'content', 'created_at', 'priority',            'author__username', 'author__first_name', 'author__last_name',            'author__city', 'author__state'
        )
        
        priority_descriptions = {
            1: "User's own recent posts (last 24 hours)",
            2: "Posts from users I follow",
            3: "Posts from followers of my followings",
            4: "Posts from my followers", 
            5: "Posts from followings of my followings",
            6: "Posts from nearby cities",
            7: "Other posts (including user's older posts)"
        }
        
        response_data = {
            "user_info": {
                "username": user.username,
                "city": user.city,
                "state": user.state,
                "following_count": BusinessNetworkFollowerModel.objects.filter(follower=user).count(),
                "followers_count": BusinessNetworkFollowerModel.objects.filter(following=user).count()
            },
            "feed_stats": {
                "total_posts": total_posts,
                "priority_breakdown": [
                    {
                        "priority": stat['priority'],
                        "count": stat['count'],
                        "description": priority_descriptions.get(stat['priority'], "Unknown")
                    }
                    for stat in priority_stats
                ]
            },
            "posts": list(posts)
        }
        
        return Response(response_data, status=status.HTTP_200_OK)
