from rest_framework import generics, status, serializers
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from django.db.models import Q

User = get_user_model()

class SimpleUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'first_name', 'last_name', 'email', 'date_joined']

class FixedUserSuggestionsView(generics.ListAPIView):
    serializer_class = SimpleUserSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        
        try:
            # Get users that the current user is following
            from business_network.models import BusinessNetworkFollowerModel
            
            following_users = BusinessNetworkFollowerModel.objects.filter(
                follower=user
            ).values_list('following_id', flat=True)
            
            # Return users excluding self and followed users, ordered by join date
            return User.objects.exclude(
                Q(id=user.id) | Q(id__in=following_users)
            ).order_by('-date_joined')[:10]
            
        except Exception as e:
            # If there's any error, just return recent users excluding current user
            return User.objects.exclude(id=user.id).order_by('-date_joined')[:10]
    
    def list(self, request, *args, **kwargs):
        try:
            queryset = self.get_queryset()
            serializer = self.get_serializer(queryset, many=True)
            
            # Return data directly as an array to match frontend expectations
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Exception as e:
            # Return empty array on error
            return Response([], status=status.HTTP_200_OK)
