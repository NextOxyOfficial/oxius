from rest_framework import serializers
from .models import (
    BusinessNetworkPost, 
    BusinessNetworkMedia, 
    BusinessNetworkPostLike, 
    BusinessNetworkPostFollow,
    BusinessNetworkPostComment,
    BusinessNetworkPostTag
)
from base.serializers import UserSerializer

class BusinessNetworkPostTagSerializer(serializers.ModelSerializer):
    class Meta:
        model = BusinessNetworkPostTag
        fields = '__all__'
        read_only_fields = ['id', 'created_at']

class BusinessNetworkPostCommentSerializer(serializers.ModelSerializer):
    author_details = UserSerializer(source='author', read_only=True)
    
    class Meta:
        model = BusinessNetworkPostComment
        fields = ['id', 'post', 'author', 'author_details', 'content', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']

class BusinessNetworkMediaSerializer(serializers.ModelSerializer):
    class Meta:
        model = BusinessNetworkMedia
        fields = '__all__'
        read_only_fields = ['id', 'created_at']

class BusinessNetworkPostLikeSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source='user', read_only=True)
    
    class Meta:
        model = BusinessNetworkPostLike
        fields = ['id', 'post', 'user', 'user_details', 'created_at']
        read_only_fields = ['id', 'created_at']

class BusinessNetworkPostFollowSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source='user', read_only=True)
    
    class Meta:
        model = BusinessNetworkPostFollow
        fields = ['id', 'post', 'user', 'user_details', 'created_at']
        read_only_fields = ['id', 'created_at']

class BusinessNetworkPostSerializer(serializers.ModelSerializer):
    author_details = UserSerializer(source='author', read_only=True)
    post_media = BusinessNetworkMediaSerializer(source='media',many=True, read_only=True)
    post_likes = serializers.SerializerMethodField()
    post_comments = BusinessNetworkPostCommentSerializer(many=True, read_only=True)
    post_tags = BusinessNetworkPostTagSerializer(many=True, read_only=True,source='tags')
    post_followers = BusinessNetworkPostFollowSerializer(many=True, read_only=True)
    like_count = serializers.SerializerMethodField()
    comment_count = serializers.SerializerMethodField()
    follower_count = serializers.SerializerMethodField()
    
    class Meta:
        model = BusinessNetworkPost
        fields = [
            'id', 'slug', 'author', 'author_details', 'title', 
            'content', 'created_at', 'updated_at', 'post_media',
            'post_likes', 'post_comments', 'post_tags', 'post_followers',
            'like_count', 'comment_count', 'follower_count'
        ]
        read_only_fields = ['id', 'slug', 'created_at', 'updated_at']
    
    def get_post_likes(self, obj):
        # Can be limited or paginated for performance in real-world scenarios
        return BusinessNetworkPostLikeSerializer(obj.post_likes.all()[:5], many=True).data
    
    def get_like_count(self, obj):
        return obj.post_likes.count()
    
    def get_comment_count(self, obj):
        return obj.post_comments.count()
    
    def get_follower_count(self, obj):
        return obj.post_followers.count()