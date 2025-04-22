from rest_framework import serializers
from .models import *
from base.serializers import UserSerializer

class NewsMediaSerializer(serializers.ModelSerializer):
    class Meta:
        model = NewsMedia
        fields = '__all__'

class NewsPostTagSerializer(serializers.ModelSerializer):
    class Meta:
        model = NewsPostTag
        fields = '__all__'

class NewsPostCommentSerializer(serializers.ModelSerializer):
    author_details = UserSerializer(source='author', read_only=True)
    
    class Meta:
        model = NewsPostComment
        fields = '__all__'
        read_only_fields = ['post', 'author']
        
class NewsPostListSerializer(serializers.ModelSerializer):
    author_details = UserSerializer(source='author', read_only=True)
    post_media = NewsMediaSerializer(many=True, read_only=True)
    post_tags = NewsPostTagSerializer(many=True, read_only=True)
    comment_count = serializers.SerializerMethodField()
    
    class Meta:
        model = NewsPost
        fields = '__all__'
        read_only_fields = ['slug']
    
    def get_comment_count(self, obj):
        return obj.post_comments.count()

class NewsPostDetailSerializer(serializers.ModelSerializer):
    author_details = UserSerializer(source='author', read_only=True)
    post_media = NewsMediaSerializer(many=True, read_only=True)
    post_tags = NewsPostTagSerializer(many=True, read_only=True)
    post_comments = NewsPostCommentSerializer(many=True, read_only=True)
    
    class Meta:
        model = NewsPost
        fields = '__all__'
        read_only_fields = ['slug']