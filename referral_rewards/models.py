from django.db import models
from django.utils import timezone
from django.conf import settings


class ReferralRewardProgram(models.Model):
    """New Year Referral Reward Program - Admin configurable"""
    name = models.CharField(max_length=100, default="New Year 2025 Referral Reward")
    referrer_reward = models.DecimalField(max_digits=8, decimal_places=2, default=50.00)
    referee_reward = models.DecimalField(max_digits=8, decimal_places=2, default=50.00)
    is_active = models.BooleanField(default=True)
    start_date = models.DateTimeField(null=True, blank=True)
    end_date = models.DateTimeField(null=True, blank=True)
    description = models.TextField(blank=True, default="")
    banner_image = models.ImageField(upload_to="referral_banners/", blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.name} - ৳{self.referrer_reward}/৳{self.referee_reward}"

    @classmethod
    def get_active(cls):
        now = timezone.now()
        return cls.objects.filter(
            is_active=True
        ).filter(
            models.Q(start_date__isnull=True) | models.Q(start_date__lte=now)
        ).filter(
            models.Q(end_date__isnull=True) | models.Q(end_date__gte=now)
        ).first()


class ReferralRewardClaim(models.Model):
    """Track reward claims - Conditions: 1 BN post, 1 microgig task, KYC verified"""
    CLAIM_TYPES = [('referrer', 'Referrer'), ('referee', 'Referee')]
    STATUSES = [('pending', 'Pending'), ('eligible', 'Eligible'), ('claimed', 'Claimed')]
    
    program = models.ForeignKey(ReferralRewardProgram, on_delete=models.CASCADE, related_name='claims')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='reward_claims')
    referred_user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, 
                                       related_name='referrer_claims', null=True, blank=True)
    claim_type = models.CharField(max_length=20, choices=CLAIM_TYPES)
    status = models.CharField(max_length=20, choices=STATUSES, default='pending')
    reward_amount = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    has_posted_bn = models.BooleanField(default=False)
    has_completed_microgig = models.BooleanField(default=False)
    has_kyc_verified = models.BooleanField(default=False)
    claimed_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        unique_together = [['program', 'user', 'claim_type', 'referred_user']]

    def check_conditions(self):
        from business_network.models import BusinessNetworkPost
        from base.models import MicroGigPostTask
        
        target = self.user if self.claim_type == 'referee' else self.referred_user
        if not target:
            return False
        
        self.has_posted_bn = BusinessNetworkPost.objects.filter(author=target).exists()
        self.has_completed_microgig = MicroGigPostTask.objects.filter(user=target, approved=True).exists()
        self.has_kyc_verified = target.kyc
        
        if self.has_posted_bn and self.has_completed_microgig and self.has_kyc_verified:
            if self.status == 'pending':
                self.status = 'eligible'
        self.save()
        return self.status == 'eligible'

    def claim_reward(self):
        from base.models import Balance
        
        if self.status == 'claimed':
            return False, "Already claimed"
        if self.status != 'eligible':
            return False, "Conditions not met"
        
        self.user.balance += self.reward_amount
        self.user.save()
        
        Balance.objects.create(
            user=self.user, amount=self.reward_amount,
            transaction_type="referral_reward", completed=True,
            bank_status="completed", description=f"Referral Reward - {self.get_claim_type_display()}"
        )
        
        self.status = 'claimed'
        self.claimed_at = timezone.now()
        self.save()
        return True, "Reward claimed!"
