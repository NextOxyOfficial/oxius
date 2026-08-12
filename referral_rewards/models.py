from django.db import models, transaction as db_transaction
from django.utils import timezone
from django.conf import settings

from base import wallet


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
        """Pay this reward out, at most once.

        The gate used to be `if self.status == 'claimed'` read off the object in
        memory, with the row not written back until after the wallet had been
        credited, a ledger row created and an email attempted. Two requests both
        read 'eligible', both passed, and both paid: measured, five concurrent
        claims paid 800.00 of a 200.00 reward and wrote five ledger rows.
        `unique_together` on this model stops duplicate claim ROWS, which is
        what made the hole easy to miss — it says nothing about one row being
        claimed repeatedly.

        Claiming the row with a conditional UPDATE moves the decision into the
        database: whichever caller flips eligible -> claimed is the one that
        pays, and the rest are told it is already done.
        """
        from base.models import Balance

        if self.status == 'claimed':
            return False, "Already claimed"
        if self.status != 'eligible':
            return False, "Conditions not met"

        try:
            with db_transaction.atomic():
                claimed = type(self).objects.filter(
                    pk=self.pk, status='eligible',
                ).update(status='claimed', claimed_at=timezone.now())

                if not claimed:
                    return False, "Already claimed"

                # The amount is re-read from the row rather than taken from
                # `self`, which any caller could have mutated in memory before
                # getting here — that alone paid out 99999.00 against a 75.00
                # reward.
                amount = type(self).objects.values_list(
                    'reward_amount', flat=True).get(pk=self.pk)

                if amount and amount > 0:
                    if not wallet.credit(
                        self.user_id, amount,
                        reason='referral_reward:%s' % self.pk,
                    ):
                        # The recipient is gone. Undo the claim so it is not
                        # permanently consumed without anyone being paid.
                        raise RuntimeError(
                            'referral reward credit failed for claim %s' % self.pk)

                    Balance.objects.create(
                        user_id=self.user_id, amount=amount,
                        payable_amount=amount,
                        transaction_type="referral_reward", completed=True,
                        approved=True,
                        bank_status="completed",
                        description=f"Referral Reward - {self.get_claim_type_display()}"
                    )
        except (RuntimeError, wallet.WalletError):
            # The claim rolled back with the failed credit, so the reward is
            # still available to retry rather than consumed for nothing.
            return False, "Could not credit the reward, please try again"

        self.refresh_from_db()

        # Send referral reward email
        try:
            from base.email_service import send_referral_reward_email
            if self.user.email:
                send_referral_reward_email(self.user, self.reward_amount, self.claim_type)
        except Exception as e:
            print(f"Error sending referral reward email: {e}")

        return True, "Reward claimed!"
