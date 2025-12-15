from django.contrib import admin
from .models import RaiseUpPost, RaiseUpPostDetail, UserProfile, Donation

@admin.register(RaiseUpPost)
class RaiseUpPostAdmin(admin.ModelAdmin):
    list_display = ['title', 'poster', 'stage', 'funding_type', 'raised', 'goal', 'progress_percent', 'is_active', 'is_featured', 'created_at']
    list_filter = ['stage', 'funding_type', 'risk_level', 'is_active', 'is_featured', 'created_at']
    search_fields = ['title', 'summary', 'sector', 'city', 'poster__username']
    readonly_fields = ['progress_percent', 'created_at', 'updated_at']
    list_editable = ['is_active', 'is_featured']
    ordering = ['-created_at']

@admin.register(RaiseUpPostDetail)
class RaiseUpPostDetailAdmin(admin.ModelAdmin):
    list_display = ['post']
    search_fields = ['post__title', 'overview']

@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ['user', 'profession', 'is_pro', 'kyc_verified']
    list_filter = ['is_pro', 'kyc_verified']
    search_fields = ['user__username', 'profession']

@admin.register(Donation)
class DonationAdmin(admin.ModelAdmin):
    list_display = ['user', 'post', 'amount', 'payment_method', 'created_at']
    list_filter = ['payment_method', 'created_at']
    search_fields = ['user__username', 'post__title']
    readonly_fields = ['created_at']
    ordering = ['-created_at']
