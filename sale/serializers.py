from rest_framework import serializers
from .models import *



class ForSaleCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = ForSaleCategory
        fields = ['id', 'name', 'icon']

class ForSaleBannerSerializer(serializers.ModelSerializer):
    class Meta:
        model = ForSaleBanner
        fields = ['id', 'title', 'image', 'link']
        
class ForSaleSubCategorySerializer(serializers.ModelSerializer):
    category_details = ForSaleCategorySerializer(source='category', read_only=True)
    class Meta:
        model = ForSaleSubCategory
        fields = '__all__'


class SalePostImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = SalePostImage
        fields = ['id', 'image', 'is_main', 'order', 'created_at']
        read_only_fields = ['id', 'created_at']


class SalePostSerializer(serializers.ModelSerializer):
    images = SalePostImageSerializer(many=True, read_only=True)
    
    class Meta:
        model = SalePost
        fields = [
            'id', 'title', 'slug', 'description', 'condition', 'category',
            'price', 'negotiable', 'division', 'district', 'area', 
            'detailed_address', 'phone', 'email', 
            'property_type', 'size', 'unit', 'bedrooms', 'bathrooms', 'amenities',
            'vehicle_type', 'make', 'model', 'year', 'mileage', 'fuel_type', 
            'transmission', 'registration_year',
            'electronics_type', 'brand', 'age_value', 'age_unit', 'warranty',
            'item_type', 'item_quality',
            'status', 'featured', 'view_count', 'created_at', 'updated_at', 'expires_at',
            'images',
        ]
        read_only_fields = [
            'id', 'slug', 'user', 'status', 'featured', 'view_count', 
            'created_at', 'updated_at', 'expires_at'
        ]


class SalePostCreateSerializer(serializers.ModelSerializer):
    # Make price and size fields accept string values
    price = serializers.DecimalField(max_digits=12, decimal_places=2, required=False, allow_null=True)
    size = serializers.DecimalField(max_digits=10, decimal_places=2, required=False, allow_null=True)
    category = serializers.PrimaryKeyRelatedField(queryset=ForSaleCategory.objects.all())
    
    class Meta:
        model = SalePost
        fields = [
            'title', 'description', 'condition', 'category',
            'price', 'negotiable', 'division', 'district', 'area', 
            'detailed_address', 'phone', 'email', 
            'property_type', 'size', 'unit', 'bedrooms', 'bathrooms', 'amenities',
            'vehicle_type', 'make', 'model', 'year', 'mileage', 'fuel_type', 
            'transmission', 'registration_year',
            'electronics_type', 'brand', 'age_value', 'age_unit', 'warranty',
            'item_type', 'item_quality',
        ]

    def validate(self, data):
        """
        Custom validation to ensure required fields based on category
        """
        import logging
        logger = logging.getLogger(__name__)
        logger.info(f"Validating data: {data}")
        
        # Check for required fields
        required_fields = ['title', 'description', 'condition', 'category', 'division', 'district', 'area', 'detailed_address', 'phone']
        
        # Validate price and negotiable (one must be present)
        if not data.get('price') and not data.get('negotiable'):
            raise serializers.ValidationError({"price": "Either price or negotiable must be provided"})
        
        # Check all required fields
        for field in required_fields:
            if field not in data or data[field] is None or data[field] == '':
                raise serializers.ValidationError({field: f"{field} is required"})
        
        return data
    
    def create(self, validated_data):
        import json
        import logging
        logger = logging.getLogger(__name__)
        logger.info(f"Creating sale post with validated data: {validated_data}")
        
        user = self.context['request'].user
        validated_data['user'] = user
        
        # Handle empty price when negotiable is True
        if validated_data.get('negotiable') and (not validated_data.get('price') or validated_data.get('price') == ''):
            validated_data['price'] = None
        
        # Handle amenities JSON data if it comes as a string
        amenities = validated_data.get('amenities')
        if amenities:
            if isinstance(amenities, str):
                try:
                    validated_data['amenities'] = json.loads(amenities)
                    logger.info(f"Parsed amenities JSON: {validated_data['amenities']}")
                except json.JSONDecodeError as e:
                    logger.error(f"Invalid JSON format for amenities: {e}")
                    raise serializers.ValidationError({"amenities": f"Invalid JSON format: {str(e)}"})
            elif not isinstance(amenities, dict):
                logger.error(f"Amenities is not a dict or JSON string: {type(amenities)}")
                validated_data['amenities'] = {}
        else:
            validated_data['amenities'] = {}
        
        try:
            instance = super().create(validated_data)
            logger.info(f"Sale post created successfully with ID: {instance.id}")
            return instance
        except Exception as e:
            logger.exception(f"Error creating sale post: {e}")
            raise serializers.ValidationError({"detail": str(e)})


class SalePostListSerializer(serializers.ModelSerializer):
    main_image = serializers.SerializerMethodField()
    image_count = serializers.SerializerMethodField()
    user_name = serializers.SerializerMethodField()
    
    class Meta:
        model = SalePost
        fields = [
            'id', 'title', 'slug', 'description', 'condition', 'category',
            'price', 'negotiable', 'division', 'district', 'area', 
            'status', 'featured', 'view_count', 'created_at', 
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