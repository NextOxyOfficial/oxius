from django.utils import timezone
from rest_framework import serializers
from .models import Operator, Package, Recharge

class OperatorSerializer(serializers.ModelSerializer):
    class Meta:
        model = Operator
        fields = ['id', 'name', 'icon', 'bg_color', 'icon_color']

class PackageSerializer(serializers.ModelSerializer):
    class Meta:
        model = Package
        fields = ['id', 'operator', 'type', 'price', 'data', 'validity', 'calls', 'popular']

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