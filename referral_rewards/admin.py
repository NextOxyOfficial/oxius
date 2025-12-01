from django.contrib import admin
from .models import ReferralRewardProgram, ReferralRewardClaim


@admin.register(ReferralRewardProgram)
class ReferralRewardProgramAdmin(admin.ModelAdmin):
    list_display = ('name', 'referrer_reward', 'referee_reward', 'is_active', 'start_date', 'end_date')
    list_filter = ('is_active',)
    search_fields = ('name',)


@admin.register(ReferralRewardClaim)
class ReferralRewardClaimAdmin(admin.ModelAdmin):
    list_display = ('user', 'claim_type', 'status', 'reward_amount', 'has_posted_bn', 
                    'has_completed_microgig', 'has_kyc_verified', 'claimed_at')
    list_filter = ('status', 'claim_type', 'has_posted_bn', 'has_completed_microgig', 'has_kyc_verified')
    search_fields = ('user__email', 'user__username')
    raw_id_fields = ('user', 'referred_user', 'program')
