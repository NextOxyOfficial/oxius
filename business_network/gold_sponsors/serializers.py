from rest_framework import serializers
from business_network.models import SponsorshipPackage, GoldSponsor

class SponsorshipPackageSerializer(serializers.ModelSerializer):
    class Meta:
        model = SponsorshipPackage
        fields = ['id', 'name', 'description', 'price', 'duration_months', 'is_active']

class GoldSponsorCreateSerializer(serializers.ModelSerializer):
    package_id = serializers.IntegerField(write_only=True)
    
    class Meta:
        model = GoldSponsor
        fields = [
            'business_name', 'business_description', 'contact_email', 
            'phone_number', 'website', 'profile_url', 'logo', 'package_id'
        ]
    
    def validate_package_id(self, value):
        try:
            package = SponsorshipPackage.objects.get(id=value, is_active=True)
            return package
        except SponsorshipPackage.DoesNotExist:
            raise serializers.ValidationError("Selected package does not exist or is inactive.")
    
    def create(self, validated_data):
        package = validated_data.pop('package_id')
        validated_data['package'] = package
        return super().create(validated_data)

class GoldSponsorSerializer(serializers.ModelSerializer):
    package = SponsorshipPackageSerializer(read_only=True)
    
    class Meta:
        model = GoldSponsor
        fields = [
            'id', 'business_name', 'business_description', 'contact_email',
            'phone_number', 'website', 'profile_url', 'logo', 'package',
            'start_date', 'end_date', 'status', 'is_featured', 'created_at'
        ]
        read_only_fields = ['id', 'start_date', 'end_date', 'status', 'is_featured', 'created_at']
