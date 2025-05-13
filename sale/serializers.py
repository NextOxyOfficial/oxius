from rest_framework import serializers
from .models import SaleCategory, SaleChildCategory, SalePost, SaleImage, SaleBanner

class SaleCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = SaleCategory
        fields = ['id', 'name', 'icon']

class SaleChildCategorySerializer(serializers.ModelSerializer):
    parent_category = SaleCategorySerializer(source='parent', read_only=True)
    
    class Meta:
        model = SaleChildCategory
        fields = ['id', 'name', 'icon', 'parent', 'parent_category']
        
class SaleImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = SaleImage
        fields = ['id', 'image', 'is_main', 'order']
        read_only_fields = ['id']

class SaleBannerSerializer(serializers.ModelSerializer):
    class Meta:
        model = SaleBanner
        fields = ['id', 'title', 'image', 'link', 'order']
        read_only_fields = ['id']

class SalePostListSerializer(serializers.ModelSerializer):
    """Serializer for listing sale posts with minimal information"""
    category_name = serializers.CharField(source='category.name', read_only=True)
    child_category_name = serializers.CharField(source='child_category.name', read_only=True, allow_null=True)
    main_image = serializers.SerializerMethodField()
    image_count = serializers.SerializerMethodField()
    user_name = serializers.SerializerMethodField()
    
    class Meta:
        model = SalePost
        fields = [
            'id', 'title', 'slug', 'category', 'category_name', 
            'child_category', 'child_category_name', 'price', 
            'negotiable', 'condition', 'division', 'district', 
            'area', 'status', 'view_count', 'created_at', 
            'main_image', 'image_count', 'user_name'
        ]
    
    def get_main_image(self, obj):
        main_image = obj.images.filter(is_main=True).first()
        if not main_image:
            main_image = obj.images.first()
        
        if main_image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(main_image.image.url)
            return main_image.image.url
        return None
    
    def get_image_count(self, obj):
        return obj.images.count()
    
    def get_user_name(self, obj):
        return obj.user.get_full_name() or obj.user.username

class SalePostDetailSerializer(serializers.ModelSerializer):
    """Serializer for detailed view of a sale post"""
    images = SaleImageSerializer(many=True, read_only=True)
    category_details = SaleCategorySerializer(source='category', read_only=True)
    child_category_details = SaleChildCategorySerializer(source='child_category', read_only=True)
    user_name = serializers.SerializerMethodField()
    
    class Meta:
        model = SalePost
        fields = [
            'id', 'title', 'slug', 'description', 'condition', 
            'category', 'category_details', 'child_category', 'child_category_details',
            'price', 'negotiable', 'division', 'district', 'area', 
            'detailed_address', 'phone', 'email', 'status',
            'view_count', 'created_at', 'updated_at', 'images',
            'user_name'
        ]
        read_only_fields = [
            'id', 'slug', 'status', 'view_count', 
            'created_at', 'updated_at'
        ]
    
    def get_user_name(self, obj):
        return obj.user.get_full_name() or obj.user.username

class SalePostCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating a sale post"""
    images = serializers.ListField(
        child=serializers.ImageField(allow_empty_file=False),
        required=False, write_only=True
    )
    
    class Meta:
        model = SalePost
        fields = [
            'title', 'description', 'condition', 'category', 'child_category',
            'price', 'negotiable', 'division', 'district', 'area', 
            'detailed_address', 'phone', 'email', 'images'
        ]
        
    def validate(self, data):
        """Validate required fields"""
        required_fields = ['title', 'description', 'condition', 'category', 
                          'division', 'district', 'area', 'detailed_address', 'phone']
        
        # Validate price and negotiable (one must be present)
        if not data.get('price') and not data.get('negotiable'):
            raise serializers.ValidationError({"price": "Either price or negotiable must be provided"})
        
        # Check all required fields
        for field in required_fields:
            if field not in data or data[field] is None or data[field] == '':
                raise serializers.ValidationError({field: f"{field} is required"})
        
        return data
    
    def create(self, validated_data):
        images_data = validated_data.pop('images', [])
        user = self.context['request'].user
        validated_data['user'] = user
        
        # Handle negotiable price
        if validated_data.get('negotiable') and not validated_data.get('price'):
            validated_data['price'] = None
            
        # Create the post
        post = SalePost.objects.create(**validated_data)
        
        # Process images
        for i, image_data in enumerate(images_data):
            SaleImage.objects.create(
                post=post,
                image=image_data,
                is_main=(i == 0),  # First image is main
                order=i
            )
            
        return post