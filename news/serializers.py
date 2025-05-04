from rest_framework import serializers
from .models import *
from base.serializers import UserSerializer

class NewsCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = NewsCategory
        fields = '__all__'

class NewsPostCommentSerializer(serializers.ModelSerializer):
    author_details = UserSerializer(source='author', read_only=True)
    
    class Meta:
        model = NewsPostComment
        fields = '__all__'
        read_only_fields = ['post', 'author']
        
class NewsPostListSerializer(serializers.ModelSerializer):
    author_details = UserSerializer(source='author', read_only=True)
    category_details = NewsCategorySerializer(many=True, read_only=True)
    comment_count = serializers.SerializerMethodField()
    
    class Meta:
        model = NewsPost
        fields = '__all__'
        read_only_fields = ['slug']
    
    def get_comment_count(self, obj):
        return obj.post_comments.count()

class NewsPostDetailSerializer(serializers.ModelSerializer):
    author_details = UserSerializer(source='author', read_only=True)
    category_details = NewsCategorySerializer(many=True, read_only=True)
    post_comments = NewsPostCommentSerializer(many=True, read_only=True)
    
    class Meta:
        model = NewsPost
        fields = '__all__'
        read_only_fields = ['slug']

class TipsAndSuggestionSerializer(serializers.ModelSerializer):
    class Meta:
        model = TipsAndSuggestion
        fields = '__all__'

class BreakingNewsSerializer(serializers.ModelSerializer):
    class Meta:
        model = BreakingNews
        fields = '__all__'
        