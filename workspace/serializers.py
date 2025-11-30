from rest_framework import serializers
from .models import (
    Gig, GigReview, GigFavorite, GigOrder, OrderMessage,
    GigCategory, GigSkill, GigDeliveryTime, GigRevisionOption
)
from base.models import User


# ============================================
# Gig Options Serializers
# ============================================

class GigCategorySerializer(serializers.ModelSerializer):
    """Serializer for gig categories"""
    class Meta:
        model = GigCategory
        fields = ('id', 'name', 'slug', 'icon', 'description')


class GigSkillSerializer(serializers.ModelSerializer):
    """Serializer for gig skills"""
    category_name = serializers.CharField(source='category.name', read_only=True)
    
    class Meta:
        model = GigSkill
        fields = ('id', 'name', 'slug', 'category', 'category_name')


class GigDeliveryTimeSerializer(serializers.ModelSerializer):
    """Serializer for delivery time options"""
    class Meta:
        model = GigDeliveryTime
        fields = ('id', 'label', 'days')


class GigRevisionOptionSerializer(serializers.ModelSerializer):
    """Serializer for revision options"""
    class Meta:
        model = GigRevisionOption
        fields = ('id', 'label', 'count')


class GigOptionsSerializer(serializers.Serializer):
    """Combined serializer for all gig options"""
    categories = GigCategorySerializer(many=True)
    skills = GigSkillSerializer(many=True)
    delivery_times = GigDeliveryTimeSerializer(many=True)
    revision_options = GigRevisionOptionSerializer(many=True)


# ============================================
# User & Gig Serializers
# ============================================

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
            'skills', 'features', 'status', 'is_featured', 'views_count', 'orders_count',
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
    skills = serializers.JSONField(required=False, default=list)
    features = serializers.JSONField(required=False, default=list)
    
    class Meta:
        model = Gig
        fields = (
            'title', 'description', 'category', 'price',
            'image', 'delivery_time', 'revisions', 'skills', 'features'
        )
    
    def to_internal_value(self, data):
        # Handle JSON strings from FormData
        import json
        mutable_data = data.copy() if hasattr(data, 'copy') else dict(data)
        
        # Parse skills if it's a JSON string
        if 'skills' in mutable_data and isinstance(mutable_data['skills'], str):
            try:
                mutable_data['skills'] = json.loads(mutable_data['skills'])
            except (json.JSONDecodeError, TypeError):
                mutable_data['skills'] = []
        
        # Parse features if it's a JSON string
        if 'features' in mutable_data and isinstance(mutable_data['features'], str):
            try:
                mutable_data['features'] = json.loads(mutable_data['features'])
            except (json.JSONDecodeError, TypeError):
                mutable_data['features'] = []
        
        return super().to_internal_value(mutable_data)
    
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


class OrderMessageSerializer(serializers.ModelSerializer):
    """Serializer for order messages"""
    sender = GigUserSerializer(read_only=True)
    media_url = serializers.SerializerMethodField()
    
    class Meta:
        model = OrderMessage
        fields = ('id', 'sender', 'content', 'message_type', 'media_url', 'file_name', 'file_size', 'is_read', 'created_at')
        read_only_fields = ('id', 'sender', 'is_read', 'created_at')
    
    def get_media_url(self, obj):
        if obj.media:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.media.url)
            return obj.media.url
        return None
