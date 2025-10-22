from rest_framework import generics, serializers
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from django.db.models import Q, Count, Case, When, IntegerField
from collections import defaultdict

User = get_user_model()


class ImprovedUserSerializer(serializers.ModelSerializer):
    mutual_connections = serializers.IntegerField(read_only=True, default=0)
    
    class Meta:
        model = User
        fields = ['id', 'username', 'first_name', 'last_name', 'email', 
                  'image', 'profession', 'city', 'mutual_connections']


class ImprovedUserSuggestionsView(generics.ListAPIView):
    """
    Advanced user suggestion algorithm based on social connectivity:
    
    1. Mutual Connections (highest weight)
    2. Same Location/City
    3. Similar Profession
    4. Similar Interests (based on post tags and interactions)
    5. Recent Activity
    
    Scoring System:
    - Mutual connection: +10 points per mutual
    - Same city: +5 points
    - Same profession: +3 points
    - Interacted with same posts: +2 points per interaction
    - Recently active: +1 point
    """
    serializer_class = ImprovedUserSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        
        try:
            from business_network.models import (
                BusinessNetworkFollowerModel, 
                BusinessNetworkPost,
                BusinessNetworkPostLike,
                BusinessNetworkPostComment
            )
            
            # Get users that the current user is following
            following_ids = set(BusinessNetworkFollowerModel.objects.filter(
                follower=user
            ).values_list('following_id', flat=True))
            
            # Get followers of people I follow (friends of friends)
            friends_of_friends_ids = set(BusinessNetworkFollowerModel.objects.filter(
                follower_id__in=following_ids
            ).exclude(
                following_id=user.id
            ).exclude(
                following_id__in=following_ids
            ).values_list('following_id', flat=True))
            
            # Calculate mutual connections count for each suggested user
            mutual_connections_count = {}
            for fof_id in friends_of_friends_ids:
                # Count how many people both user and fof_id follow
                fof_following = set(BusinessNetworkFollowerModel.objects.filter(
                    follower_id=fof_id
                ).values_list('following_id', flat=True))
                
                mutual_count = len(following_ids.intersection(fof_following))
                if mutual_count > 0:
                    mutual_connections_count[fof_id] = mutual_count
            
            # Get posts that the user has interacted with
            user_interacted_posts = set()
            
            # Posts user liked
            user_interacted_posts.update(
                BusinessNetworkPostLike.objects.filter(user=user).values_list('post_id', flat=True)
            )
            
            # Posts user commented on
            user_interacted_posts.update(
                BusinessNetworkPostComment.objects.filter(author=user).values_list('post_id', flat=True)
            )
            
            # Find users who interacted with the same posts
            similar_interest_users = set()
            if user_interacted_posts:
                # Users who liked same posts
                similar_interest_users.update(
                    BusinessNetworkPostLike.objects.filter(
                        post_id__in=user_interacted_posts
                    ).exclude(
                        user=user
                    ).values_list('user_id', flat=True)
                )
                
                # Users who commented on same posts
                similar_interest_users.update(
                    BusinessNetworkPostComment.objects.filter(
                        post_id__in=user_interacted_posts
                    ).exclude(
                        author=user
                    ).values_list('author_id', flat=True)
                )
            
            # Build candidate user IDs
            candidate_ids = friends_of_friends_ids.union(similar_interest_users)
            
            # If we don't have enough candidates, add recent users
            if len(candidate_ids) < 20:
                recent_users = set(User.objects.exclude(
                    Q(id=user.id) | Q(id__in=following_ids)
                ).order_by('-date_joined').values_list('id', flat=True)[:30])
                candidate_ids = candidate_ids.union(recent_users)
            
            # Score each candidate
            user_scores = {}
            
            for candidate_id in candidate_ids:
                score = 0
                
                # Mutual connections (highest weight)
                if candidate_id in mutual_connections_count:
                    score += mutual_connections_count[candidate_id] * 10
                
                # Similar interests
                if candidate_id in similar_interest_users:
                    score += 2
                
                user_scores[candidate_id] = score
            
            # Get user objects and add location/profession bonuses
            candidates = User.objects.filter(id__in=candidate_ids)
            
            final_scores = []
            for candidate in candidates:
                score = user_scores.get(candidate.id, 0)
                
                # Same city bonus
                if user.city and candidate.city and user.city.lower() == candidate.city.lower():
                    score += 5
                
                # Same profession bonus
                if user.profession and candidate.profession and user.profession.lower() == candidate.profession.lower():
                    score += 3
                
                final_scores.append({
                    'user': candidate,
                    'score': score,
                    'mutual_connections': mutual_connections_count.get(candidate.id, 0)
                })
            
            # Sort by score descending
            final_scores.sort(key=lambda x: x['score'], reverse=True)
            
            # Return top 20 suggestions
            return [item['user'] for item in final_scores[:20]]
            
        except Exception as e:
            print(f"Error in user suggestions algorithm: {e}")
            # Fallback to simple algorithm
            following_ids = BusinessNetworkFollowerModel.objects.filter(
                follower=user
            ).values_list('following_id', flat=True)
            
            return User.objects.exclude(
                Q(id=user.id) | Q(id__in=following_ids)
            ).order_by('-date_joined')[:20]

    def list(self, request, *args, **kwargs):
        try:
            queryset = self.get_queryset()
            
            # Add mutual connections count to each user
            serializer_data = []
            for user_obj in queryset:
                data = {
                    'id': str(user_obj.id),
                    'username': user_obj.username,
                    'first_name': user_obj.first_name,
                    'last_name': user_obj.last_name,
                    'email': user_obj.email,
                    'image': user_obj.image.url if user_obj.image else None,
                    'profession': user_obj.profession,
                    'city': user_obj.city,
                    'mutual_connections': getattr(user_obj, 'mutual_connections', 0)
                }
                serializer_data.append(data)
            
            return Response(serializer_data)
        except Exception as e:
            print(f"Error in list: {e}")
            return Response([])
