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
    share_count = serializers.SerializerMethodField()

    class Meta:
        model = NewsPost
        fields = '__all__'
        read_only_fields = ['slug']

    def get_comment_count(self, obj):
        return obj.post_comments.count()

    def get_share_count(self, obj):
        # Reshares of this story into the Business Network feed.
        return obj.bn_reshares.count()

class NewsPostDetailSerializer(serializers.ModelSerializer):
    author_details = UserSerializer(source='author', read_only=True)
    category_details = NewsCategorySerializer(many=True, read_only=True)
    post_comments = NewsPostCommentSerializer(many=True, read_only=True)
    
    class Meta:
        model = NewsPost
        fields = '__all__'
        # author pinned server-side (perform_create), never client-writable.
        read_only_fields = ['slug', 'author']

class TipsAndSuggestionSerializer(serializers.ModelSerializer):
    class Meta:
        model = TipsAndSuggestion
        fields = '__all__'

class BreakingNewsSerializer(serializers.ModelSerializer):
    news_slug = serializers.CharField(source='news.slug', read_only=True)
    news_title = serializers.CharField(source='news.title', read_only=True)
    news_image = serializers.ImageField(source='news.image', read_only=True)

    class Meta:
        model = BreakingNews
        fields = '__all__'
        
