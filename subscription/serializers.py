from rest_framework import serializers
from .models import SubscriptionPlan, Subscription, SubscriptionLog


class SubscriptionPlanSerializer(serializers.ModelSerializer):
    class Meta:
        model = SubscriptionPlan
        fields = '__all__'


class SubscriptionLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = SubscriptionLog
        fields = ['id', 'action', 'timestamp', 'details']
        read_only_fields = fields


class SubscriptionSerializer(serializers.ModelSerializer):
    logs = SubscriptionLogSerializer(many=True, read_only=True)
    days_remaining = serializers.SerializerMethodField()
    is_active_now = serializers.SerializerMethodField()
    plan_details = SubscriptionPlanSerializer(source='plan', read_only=True)
    
    class Meta:
        model = Subscription
        fields = '__all__'
        read_only_fields = ['start_date', 'end_date', 'created_at', 'updated_at']
    
    def get_days_remaining(self, obj):
        return obj.days_remaining()
    
    def get_is_active_now(self, obj):
        return obj.is_active()


class SubscriptionCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Subscription
        fields = '__all__'
    
    def create(self, validated_data):
        # Set user from request
        user = self.context['request'].user
        validated_data['user'] = user
        
        # Create the subscription
        subscription = Subscription.objects.create(**validated_data)
        
        # Create log entry for subscription creation
        SubscriptionLog.objects.create(
            subscription=subscription,
            action='created',
            details="Subscription created"
        )
        
        return subscription