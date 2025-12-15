from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import RaiseUpPost, RaiseUpPostDetail, UserProfile

User = get_user_model()

class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserProfile
        fields = ['profession', 'avatar', 'is_pro', 'kyc_verified']

class PosterSerializer(serializers.ModelSerializer):
    profession = serializers.CharField(source='raise_up_profile.profession', read_only=True, default='')
    avatar = serializers.URLField(source='raise_up_profile.avatar', read_only=True, default='')
    is_pro = serializers.BooleanField(source='raise_up_profile.is_pro', read_only=True, default=False)
    kyc = serializers.BooleanField(source='raise_up_profile.kyc_verified', read_only=True, default=False)
    
    class Meta:
        model = User
        fields = ['id', 'username', 'first_name', 'last_name', 'profession', 'avatar', 'is_pro', 'kyc']
    
    def to_representation(self, instance):
        data = super().to_representation(instance)
        # Use full name if available, otherwise username
        if instance.first_name and instance.last_name:
            data['name'] = f"{instance.first_name} {instance.last_name}"
        else:
            data['name'] = instance.username
        
        # Handle missing profile gracefully
        try:
            profile = instance.raise_up_profile
            data['profession'] = profile.profession or ''
            data['avatar'] = profile.avatar or ''
            data['is_pro'] = profile.is_pro
            data['kyc'] = profile.kyc_verified
        except UserProfile.DoesNotExist:
            data['profession'] = ''
            data['avatar'] = ''
            data['is_pro'] = False
            data['kyc'] = False
            
        return data

class RaiseUpPostDetailSerializer(serializers.ModelSerializer):
    class Meta:
        model = RaiseUpPostDetail
        fields = ['overview', 'use_of_funds', 'milestones']

class RaiseUpPostSerializer(serializers.ModelSerializer):
    poster = PosterSerializer(read_only=True)
    details = RaiseUpPostDetailSerializer(read_only=True)
    progress_percent = serializers.ReadOnlyField()
    top_donator = serializers.SerializerMethodField()
    
    # Frontend expects these field names
    stageColor = serializers.CharField(source='stage_color', read_only=True)
    fundingType = serializers.CharField(source='funding_type', read_only=True)
    minInvestment = serializers.DecimalField(source='min_investment', max_digits=12, decimal_places=2, read_only=True)
    expectedReturn = serializers.CharField(source='expected_return', read_only=True)
    riskLevel = serializers.CharField(source='risk_level', read_only=True)
    videoEmbedUrl = serializers.URLField(source='video_embed_url', read_only=True)
    
    class Meta:
        model = RaiseUpPost
        fields = [
            'id', 'title', 'summary', 'sector', 'location', 'city', 'area',
            'stage', 'stageColor', 'fundingType', 'minInvestment', 'expectedReturn',
            'riskLevel', 'traction', 'raised', 'goal', 'thumbnail', 'videoEmbedUrl',
            'media_type', 'poster', 'details', 'progress_percent', 'top_donator', 'created_at', 'updated_at',
            'is_active', 'is_featured'
        ]
    
    def get_top_donator(self, obj):
        """Get the top donator for this post"""
        top_donation = obj.donations.order_by('-amount').first()
        if top_donation:
            return {
                'name': top_donation.user.first_name or top_donation.user.username,
                'amount': float(top_donation.amount),
                'user_id': top_donation.user.id
            }
        return None

class RaiseUpPostCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = RaiseUpPost
        fields = [
            'title', 'summary', 'sector', 'location', 'city', 'area',
            'stage', 'stage_color', 'funding_type', 'min_investment', 
            'expected_return', 'risk_level', 'traction', 'goal', 'thumbnail',
            'video_embed_url'
        ]
    
    def create(self, validated_data):
        validated_data['poster'] = self.context['request'].user
        return super().create(validated_data)
