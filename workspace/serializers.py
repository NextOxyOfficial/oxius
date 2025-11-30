from rest_framework import serializers
from .models import Gig, GigReview, GigFavorite, GigOrder
from base.models import User


class GigUserSerializer(serializers.ModelSerializer):
    """Minimal user serializer for gig listings"""
    name = serializers.SerializerMethodField()
    avatar = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = ('id', 'name', 'avatar', 'is_pro', 'kyc')
    
    def get_name(self, obj):
        if obj.first_name and obj.last_name:
            return f"{obj.first_name} {obj.last_name}"
        return obj.first_name or obj.username or "User"
    
    def get_avatar(self, obj):
        if obj.image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.image.url)
            return obj.image.url
        return None


class GigReviewSerializer(serializers.ModelSerializer):
    """Serializer for gig reviews"""
    user = GigUserSerializer(read_only=True)
    
    class Meta:
        model = GigReview
        fields = ('id', 'user', 'rating', 'comment', 'created_at')
        read_only_fields = ('id', 'created_at')


class GigSerializer(serializers.ModelSerializer):
    """Serializer for gig listings"""
    user = GigUserSerializer(read_only=True)
    rating = serializers.SerializerMethodField()
    reviews = serializers.SerializerMethodField()
    is_favorited = serializers.SerializerMethodField()
    image_url = serializers.SerializerMethodField()
    category_display = serializers.SerializerMethodField()
    
    class Meta:
        model = Gig
        fields = (
            'id', 'title', 'description', 'category', 'category_display',
            'price', 'image', 'image_url', 'delivery_time', 'revisions',
            'skills', 'status', 'is_featured', 'views_count', 'orders_count',
            'user', 'rating', 'reviews', 'is_favorited',
            'created_at', 'updated_at'
        )
        read_only_fields = ('id', 'views_count', 'orders_count', 'created_at', 'updated_at')
    
    def get_rating(self, obj):
        return obj.average_rating
    
    def get_reviews(self, obj):
        return obj.reviews_count
    
    def get_is_favorited(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return GigFavorite.objects.filter(gig=obj, user=request.user).exists()
        return False
    
    def get_image_url(self, obj):
        if obj.image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.image.url)
            return obj.image.url
        return None
    
    def get_category_display(self, obj):
        return obj.get_category_display()


class GigCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating gigs"""
    
    class Meta:
        model = Gig
        fields = (
            'title', 'description', 'category', 'price',
            'image', 'delivery_time', 'revisions', 'skills'
        )
    
    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)


class GigOrderSerializer(serializers.ModelSerializer):
    """Serializer for gig orders"""
    gig = GigSerializer(read_only=True)
    buyer = GigUserSerializer(read_only=True)
    seller = GigUserSerializer(read_only=True)
    status_display = serializers.SerializerMethodField()
    
    class Meta:
        model = GigOrder
        fields = (
            'id', 'gig', 'buyer', 'seller', 'price', 'requirements',
            'status', 'status_display', 'delivery_date', 'completed_at',
            'created_at', 'updated_at'
        )
        read_only_fields = ('id', 'created_at', 'updated_at')
    
    def get_status_display(self, obj):
        return obj.get_status_display()


class GigFavoriteSerializer(serializers.ModelSerializer):
    """Serializer for gig favorites"""
    gig = GigSerializer(read_only=True)
    
    class Meta:
        model = GigFavorite
        fields = ('id', 'gig', 'created_at')
        read_only_fields = ('id', 'created_at')
