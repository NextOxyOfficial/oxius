from django.utils import timezone
from django.conf import settings
from rest_framework import serializers
from .models import Operator, Package, Recharge

class OperatorSerializer(serializers.ModelSerializer):
    icon = serializers.SerializerMethodField()
    
    class Meta:
        model = Operator
        fields = ['id', 'name', 'icon', 'bg_color', 'icon_color']
    
    def get_icon(self, obj):
        if obj.icon:
            request = self.context.get("request")
            if request:
                return request.build_absolute_uri(obj.icon.url)
            # Fallback to absolute URL in production
            if not settings.DEBUG:
                return f"https://adsyclub.com{obj.icon.url}"
            return obj.icon.url
        return None

class PackageSerializer(serializers.ModelSerializer):
    operator = serializers.PrimaryKeyRelatedField(
        queryset=Operator.objects.all(),
        help_text="The ID of the selected operator"
    )
    
    operator_details = OperatorSerializer(
        source='operator',
        read_only=True
    )
    class Meta:
        model = Package
        fields = '__all__'

class RechargeSerializer(serializers.ModelSerializer):
    package = serializers.PrimaryKeyRelatedField(
        queryset=Package.objects.all(),
        help_text="The ID of the selected package"
    )
    
    package_details = PackageSerializer(
        source='package',
        read_only=True
    )
    operator = serializers.PrimaryKeyRelatedField(
        queryset=Operator.objects.all(),
        help_text="The ID of the selected operator"
    )
    
    operator_details = OperatorSerializer(
        source='operator',
        read_only=True
    )
    
    class Meta:
        model = Recharge
        fields = '__all__'
        read_only_fields = ['user', 'transaction_id']

    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        validated_data['transaction_id'] = f"TXN-{timezone.now().strftime('%Y%m%d%H%M%S')}"
        return super().create(validated_data)