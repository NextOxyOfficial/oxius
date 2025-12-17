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
    # Optional detail fields
    overview = serializers.CharField(required=False, allow_blank=True, default='')
    use_of_funds = serializers.ListField(child=serializers.CharField(), required=False, default=list)
    milestones = serializers.ListField(child=serializers.CharField(), required=False, default=list)
    
    # Make these fields optional to match frontend
    min_investment = serializers.DecimalField(max_digits=12, decimal_places=2, required=False, default=0)
    expected_return = serializers.CharField(max_length=100, required=False, allow_blank=True, default='')
    risk_level = serializers.CharField(max_length=20, required=False, default='medium')
    video_embed_url = serializers.CharField(max_length=500, required=False, allow_blank=True, default='')
    thumbnail = serializers.CharField(max_length=500, required=False, allow_blank=True, default='')
    area = serializers.CharField(max_length=100, required=False, allow_blank=True, default='')
    media_type = serializers.CharField(max_length=20, required=False, default='image')
    traction = serializers.CharField(max_length=200, required=False, allow_blank=True, default='')
    
    class Meta:
        model = RaiseUpPost
        fields = [
            'title', 'summary', 'sector', 'location', 'city', 'area',
            'stage', 'stage_color', 'funding_type', 'min_investment', 
            'expected_return', 'risk_level', 'traction', 'goal', 'thumbnail',
            'video_embed_url', 'media_type', 'overview', 'use_of_funds', 'milestones'
        ]
    
    def create(self, validated_data):
        # Extract detail fields
        overview = validated_data.pop('overview', '')
        use_of_funds = validated_data.pop('use_of_funds', [])
        milestones = validated_data.pop('milestones', [])
        
        # Set poster
        validated_data['poster'] = self.context['request'].user
        
        # Create post
        post = super().create(validated_data)
        
        # Create detail object if any detail data provided
        if overview or use_of_funds or milestones:
            RaiseUpPostDetail.objects.create(
                post=post,
                overview=overview,
                use_of_funds=use_of_funds,
                milestones=milestones
            )
        
        return post
