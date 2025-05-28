from rest_framework import serializers
from business_network.models import SponsorshipPackage, GoldSponsor, GoldSponsorBanner
from django.core.exceptions import ValidationError as DjangoValidationError

class SponsorshipPackageSerializer(serializers.ModelSerializer):
    class Meta:
        model = SponsorshipPackage
        fields = ['id', 'name', 'description', 'price', 'duration_months', 'is_active']

class GoldSponsorBannerSerializer(serializers.ModelSerializer):
    class Meta:
        model = GoldSponsorBanner
        fields = ['id', 'title', 'image', 'link_url', 'order', 'is_active']

class GoldSponsorCreateSerializer(serializers.ModelSerializer):
    package_id = serializers.IntegerField(write_only=True)
    banners = GoldSponsorBannerSerializer(many=True, required=False)
    class Meta:
        model = GoldSponsor
        fields = [
            'business_name', 'business_description', 'contact_email', 
            'phone_number', 'website', 'profile_url', 'logo', 'package_id', 'banners'
        ]
    
    def validate_package_id(self, value):
        try:
            package = SponsorshipPackage.objects.get(id=value, is_active=True)
            return package
        except SponsorshipPackage.DoesNotExist:
            raise serializers.ValidationError("Selected package does not exist or is inactive.")
    
    def create(self, validated_data):
        request = self.context.get('request')
        if not request or not request.user or not request.user.is_authenticated:
            raise serializers.ValidationError("Authentication required")
            
        banners_data = validated_data.pop('banners', [])
        package = validated_data.pop('package_id')
        validated_data['package'] = package
        validated_data['user'] = request.user
        
        # Extract banner data from FormData format
        banner_count = int(request.data.get('banner_count', 0))
        banner_list = []
        
        for i in range(banner_count):
            banner_data = {}
            title = request.data.get(f'banner_{i}_title')
            link_url = request.data.get(f'banner_{i}_link_url')
            image = request.data.get(f'banner_{i}_image')
            order = request.data.get(f'banner_{i}_order', i + 1)
            is_active = request.data.get(f'banner_{i}_is_active', 'true').lower() == 'true'
            
            if title:
                banner_data['title'] = title
            if link_url:
                banner_data['link_url'] = link_url
            if image:
                banner_data['image'] = image
            banner_data['order'] = int(order)
            banner_data['is_active'] = is_active
            
            # Only add banner if it has at least a title or image
            if title or image:
                banner_list.append(banner_data)
        
        try:
            sponsor = super().create(validated_data)
            
            # Create banners from FormData
            for banner_data in banner_list:
                GoldSponsorBanner.objects.create(sponsor=sponsor, **banner_data)
            
            return sponsor
        except DjangoValidationError as e:            raise serializers.ValidationError(str(e))
    
    def update(self, instance, validated_data):
        banners_data = validated_data.pop('banners', [])
        package_id = validated_data.pop('package_id', None)
        
        if package_id:
            validated_data['package'] = package_id
        
        sponsor = super().update(instance, validated_data)
        
        # Extract banner data from FormData format for updates
        request = self.context.get('request')
        if request:
            banner_count = int(request.data.get('banner_count', 0))
            if banner_count > 0:
                # Clear existing banners
                sponsor.banners.all().delete()
                
                # Create new banners from FormData
                for i in range(banner_count):
                    banner_data = {}
                    title = request.data.get(f'banner_{i}_title')
                    link_url = request.data.get(f'banner_{i}_link_url')
                    image = request.data.get(f'banner_{i}_image')
                    order = request.data.get(f'banner_{i}_order', i + 1)
                    is_active = request.data.get(f'banner_{i}_is_active', 'true').lower() == 'true'
                    
                    if title:
                        banner_data['title'] = title
                    if link_url:
                        banner_data['link_url'] = link_url
                    if image:
                        banner_data['image'] = image
                    banner_data['order'] = int(order)
                    banner_data['is_active'] = is_active
                    
                    # Only add banner if it has at least a title or image
                    if title or image:
                        GoldSponsorBanner.objects.create(sponsor=sponsor, **banner_data)
        
        return sponsor

class GoldSponsorSerializer(serializers.ModelSerializer):
    package = SponsorshipPackageSerializer(read_only=True)
    banners = GoldSponsorBannerSerializer(many=True, read_only=True)
    user_username = serializers.CharField(source='user.username', read_only=True)
    days_remaining = serializers.SerializerMethodField()
    is_active_status = serializers.SerializerMethodField()
    
    class Meta:
        model = GoldSponsor
        fields = [
            'id', 'business_name', 'business_description', 'contact_email',
            'phone_number', 'website', 'profile_url', 'logo', 'package', 'banners',
            'start_date', 'end_date', 'status', 'is_featured', 'views', 'created_at',
            'user_username', 'days_remaining', 'is_active_status'
        ]
        read_only_fields = ['id', 'start_date', 'end_date', 'status', 'is_featured', 'views', 'created_at']
    
    def get_days_remaining(self, obj):
        return obj.days_remaining()
    
    def get_is_active_status(self, obj):
        return obj.is_active()
