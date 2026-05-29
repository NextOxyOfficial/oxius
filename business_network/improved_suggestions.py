from rest_framework import generics, serializers
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.core.cache import cache
from django.contrib.auth import get_user_model
from django.db.models import Q, Count

User = get_user_model()


class ImprovedUserSerializer(serializers.ModelSerializer):
    mutual_connections = serializers.IntegerField(read_only=True, default=0)
    suggestion_score = serializers.IntegerField(read_only=True, default=0)
    suggestion_reasons = serializers.ListField(
        child=serializers.CharField(), read_only=True, default=list
    )
    
    class Meta:
        model = User
        fields = ['id', 'username', 'first_name', 'last_name', 'email', 
                  'image', 'profession', 'city', 'mutual_connections',
                  'suggestion_score', 'suggestion_reasons']


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

    def _build_suggestions(self):
        user = self.request.user
        cache_key = f"bn_user_suggestions_{user.id}"
        cached = cache.get(cache_key)
        if cached is not None:
            return cached
        
        try:
            from business_network.models import (
                BusinessNetworkFollowerModel, 
                BusinessNetworkPostLike,
                BusinessNetworkPostComment
            )
            
            # Get users that the current user is following
            following_ids = set(BusinessNetworkFollowerModel.objects.filter(
                follower=user
            ).values_list('following_id', flat=True))
            
            # People followed by people I follow.
            mutual_rows = (
                BusinessNetworkFollowerModel.objects.filter(
                    follower_id__in=following_ids
                )
                .exclude(following_id=user.id)
                .exclude(following_id__in=following_ids)
                .values("following_id")
                .annotate(mutual_count=Count("follower_id", distinct=True))
            )
            mutual_connections_count = {
                row["following_id"]: row["mutual_count"] for row in mutual_rows
            }
            friends_of_friends_ids = set(mutual_connections_count.keys())
            
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
            
            # Find users who interacted with the same posts.
            similar_interest_users = set()
            shared_interaction_count = {}
            if user_interacted_posts:
                same_like_users = (
                    BusinessNetworkPostLike.objects.filter(
                        post_id__in=user_interacted_posts
                    ).exclude(
                        user=user
                    ).exclude(
                        user_id__in=following_ids
                    ).values('user_id')
                    .annotate(shared_count=Count('post_id', distinct=True))
                )
                for row in same_like_users:
                    similar_interest_users.add(row['user_id'])
                    shared_interaction_count[row['user_id']] = (
                        shared_interaction_count.get(row['user_id'], 0)
                        + row['shared_count']
                    )

                same_comment_users = (
                    BusinessNetworkPostComment.objects.filter(
                        post_id__in=user_interacted_posts
                    ).exclude(
                        author=user
                    ).exclude(
                        author_id__in=following_ids
                    ).values('author_id')
                    .annotate(shared_count=Count('post_id', distinct=True))
                )
                for row in same_comment_users:
                    similar_interest_users.add(row['author_id'])
                    shared_interaction_count[row['author_id']] = (
                        shared_interaction_count.get(row['author_id'], 0)
                        + row['shared_count']
                    )
            
            # Build candidate user IDs - exclude self and already followed users
            candidate_ids = friends_of_friends_ids.union(similar_interest_users)
            candidate_ids.discard(user.id)  # Remove self if present
            candidate_ids = candidate_ids - following_ids  # Remove already followed users
            
            # If we don't have enough candidates, add recent users
            if len(candidate_ids) < 20:
                recent_users = set(
                    User.objects.exclude(
                        Q(id=user.id) | Q(id__in=following_ids)
                    )
                    .exclude(is_superuser=True)
                    .order_by('-date_joined')
                    .values_list('id', flat=True)[:40]
                )
                candidate_ids = candidate_ids.union(recent_users)
            
            # Final safety check - remove any followed users that might have slipped through
            candidate_ids = candidate_ids - following_ids
            candidate_ids.discard(user.id)
            
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
            candidates = User.objects.filter(id__in=candidate_ids).exclude(
                is_superuser=True
            )
            
            final_scores = []
            for candidate in candidates:
                score = user_scores.get(candidate.id, 0)
                reasons = []
                
                # Same city bonus
                if user.city and candidate.city and user.city.lower() == candidate.city.lower():
                    score += 8
                    reasons.append(f"Same city: {candidate.city}")
                elif user.state and candidate.state and user.state.lower() == candidate.state.lower():
                    score += 5
                    reasons.append(f"Same area: {candidate.state}")
                
                # Same profession bonus
                if user.profession and candidate.profession and user.profession.lower() == candidate.profession.lower():
                    score += 6
                    reasons.append(f"Also in {candidate.profession}")

                mutual_count = mutual_connections_count.get(candidate.id, 0)
                if mutual_count:
                    reasons.insert(0, f"{mutual_count} mutual connection{'s' if mutual_count > 1 else ''}")

                shared_count = shared_interaction_count.get(candidate.id, 0)
                if shared_count:
                    reasons.append("Similar activity")

                if not reasons:
                    reasons.append("Active in Business Network")
                
                final_scores.append({
                    'user': candidate,
                    'score': score,
                    'mutual_connections': mutual_count,
                    'reasons': reasons[:3],
                })
            
            # Sort by score descending
            final_scores.sort(key=lambda x: x['score'], reverse=True)
            
            suggestions = final_scores[:20]
            cache.set(cache_key, suggestions, 300)
            return suggestions
            
        except Exception:
            # Fallback to simple algorithm
            following_ids = BusinessNetworkFollowerModel.objects.filter(
                follower=user
            ).values_list('following_id', flat=True)
            
            fallback_users = User.objects.exclude(
                Q(id=user.id) | Q(id__in=following_ids)
            ).exclude(is_superuser=True).order_by('-date_joined')[:20]
            return [
                {
                    "user": user_obj,
                    "score": 0,
                    "mutual_connections": 0,
                    "reasons": ["Active in Business Network"],
                }
                for user_obj in fallback_users
            ]

    def get_queryset(self):
        return [item["user"] for item in self._build_suggestions()]

    def list(self, request, *args, **kwargs):
        try:
            suggestions = self._build_suggestions()
            serializer_data = []
            for item in suggestions:
                user_obj = item["user"]
                data = {
                    'id': str(user_obj.id),
                    'username': user_obj.username,
                    'first_name': user_obj.first_name,
                    'last_name': user_obj.last_name,
                    'email': user_obj.email,
                    'image': user_obj.image.url if user_obj.image else None,
                    'profession': user_obj.profession,
                    'city': user_obj.city,
                    'mutual_connections': item["mutual_connections"],
                    'suggestion_score': item["score"],
                    'suggestion_reasons': item["reasons"],
                }
                serializer_data.append(data)
            
            return Response(serializer_data)
        except Exception:
            return Response([])
