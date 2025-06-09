from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import Review, ReviewHelpful, ProductRatingStats

User = get_user_model()


class ReviewUserSerializer(serializers.ModelSerializer):
    """Serializer for user information in reviews"""
    display_name = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = ['id', 'username', 'name', 'display_name', 'image']
    
    def get_display_name(self, obj):
        return obj.name or obj.first_name or obj.username


class ReviewSerializer(serializers.ModelSerializer):
    """Serializer for Review model"""
    user = ReviewUserSerializer(read_only=True)
    reviewer_name = serializers.ReadOnlyField()
    is_helpful = serializers.SerializerMethodField()
    formatted_date = serializers.SerializerMethodField()
    
    class Meta:
        model = Review
        fields = [
            'id', 'product', 'user', 'rating', 'title', 'comment',
            'is_verified_purchase', 'is_approved', 'helpful_count',
            'reviewer_name', 'is_helpful', 'formatted_date',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['helpful_count', 'is_verified_purchase', 'created_at', 'updated_at']
    
    def get_is_helpful(self, obj):
        """Check if current user found this review helpful"""
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return ReviewHelpful.objects.filter(
                review=obj, 
                user=request.user
            ).exists()
        return False
    
    def get_formatted_date(self, obj):
        """Get a human-readable date format"""
        from django.utils import timezone
        from datetime import timedelta
        
        now = timezone.now()
        diff = now - obj.created_at
        
        if diff < timedelta(minutes=1):
            return "Just now"
        elif diff < timedelta(hours=1):
            minutes = int(diff.total_seconds() / 60)
            return f"{minutes} minute{'s' if minutes != 1 else ''} ago"
        elif diff < timedelta(days=1):
            hours = int(diff.total_seconds() / 3600)
            return f"{hours} hour{'s' if hours != 1 else ''} ago"
        elif diff < timedelta(days=7):
            days = diff.days
            return f"{days} day{'s' if days != 1 else ''} ago"
        elif diff < timedelta(days=30):
            weeks = diff.days // 7
            return f"{weeks} week{'s' if weeks != 1 else ''} ago"
        elif diff < timedelta(days=365):
            months = diff.days // 30
            return f"{months} month{'s' if months != 1 else ''} ago"
        else:
            years = diff.days // 365
            return f"{years} year{'s' if years != 1 else ''} ago"
    
    def validate_rating(self, value):
        """Validate rating is between 1 and 5"""
        if value < 1 or value > 5:
            raise serializers.ValidationError("Rating must be between 1 and 5.")
        return value
    
    def validate(self, data):
        """Check if user has already reviewed this product"""
        request = self.context.get('request')
        if request and request.user.is_authenticated and not self.instance:
            # Only check for duplicates when creating (not updating)
            if Review.objects.filter(
                product=data['product'],
                user=request.user
            ).exists():
                raise serializers.ValidationError(
                    "You have already reviewed this product."
                )
        return data


class ReviewCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating reviews"""
    
    class Meta:
        model = Review
        fields = ['rating', 'title', 'comment']
    
    def validate_rating(self, value):
        """Validate rating is between 1 and 5"""
        if value < 1 or value > 5:
            raise serializers.ValidationError("Rating must be between 1 and 5.")
        return value
    def validate(self, data):
        """Check if user has already reviewed this product"""
        request = self.context.get('request')
        view = self.context.get('view')
        
        if request and request.user.is_authenticated and view:
            # Get product from URL parameter
            product_id = view.kwargs.get('product_id')
            if product_id and Review.objects.filter(
                product_id=product_id,
                user=request.user
            ).exists():
                raise serializers.ValidationError(
                    "You have already reviewed this product."
                )
        return data
    def create(self, validated_data):
        """Create review with current user"""
        request = self.context.get('request')
        validated_data['user'] = request.user
        
        # Check if this is a verified purchase
        # Product will be set by the view's perform_create method
        product = validated_data.get('product')
        if product:
            from base.models import OrderItem
            is_verified = OrderItem.objects.filter(
                order__user=request.user,
                product=product
            ).exists()
            validated_data['is_verified_purchase'] = is_verified
        
        return super().create(validated_data)


class ProductRatingStatsSerializer(serializers.ModelSerializer):
    """Serializer for ProductRatingStats"""
    rating_percentages = serializers.SerializerMethodField()
    
    class Meta:
        model = ProductRatingStats
        fields = [
            'total_reviews', 'average_rating',
            'rating_5_count', 'rating_4_count', 'rating_3_count',
            'rating_2_count', 'rating_1_count', 'rating_percentages',
            'updated_at'
        ]
    
    def get_rating_percentages(self, obj):
        """Get percentage distribution for all ratings"""
        return {
            '5': obj.get_rating_percentage(5),
            '4': obj.get_rating_percentage(4),
            '3': obj.get_rating_percentage(3),
            '2': obj.get_rating_percentage(2),
            '1': obj.get_rating_percentage(1),
        }


class ReviewHelpfulSerializer(serializers.ModelSerializer):
    """Serializer for ReviewHelpful model"""
    
    class Meta:
        model = ReviewHelpful
        fields = ['id', 'review', 'user', 'created_at']
        read_only_fields = ['user', 'created_at']
    
    def create(self, validated_data):
        """Create helpful vote with current user"""
        request = self.context.get('request')
        validated_data['user'] = request.user
        return super().create(validated_data)
