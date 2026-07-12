"""Auto-renew safety net for IAP subscriptions.

Re-verifies every subscription purchase against Google and re-derives the
entitlement from the authoritative expiry time. This keeps Pro / Gold Sponsor
in sync even without RTDN (Pub/Sub): a renewed subscription's expiry moves
forward, an expired/cancelled one lapses.

Run on a schedule (e.g. every 6 hours) via cron:
    */360 min: manage.py sync_iap_subscriptions
"""
from django.core.management.base import BaseCommand
from django.utils import timezone

from iap import grants, verify
from iap.models import IapProduct, IapPurchase


class Command(BaseCommand):
    help = "Re-verify active IAP subscriptions; extend or lapse entitlements."

    def handle(self, *args, **options):
        now = timezone.now()
        subs = IapPurchase.objects.filter(is_subscription=True).exclude(
            purchase_token=""
        )
        checked = extended = lapsed = skipped = 0

        for p in subs:
            google_data = verify.verify_subscription(p.purchase_token)
            if not google_data:
                skipped += 1
                continue
            checked += 1
            expiry = grants._subscription_expiry(google_data)
            product = IapProduct.objects.filter(
                google_product_id=p.google_product_id
            ).first()

            if expiry and expiry > now:
                # Still entitled (active / cancelled-but-not-yet-expired / grace).
                if product:
                    grants.grant(p, product, google_data)
                p.status = "granted"
                p.raw = google_data
                p.expiry_at = expiry
                p.save()
                extended += 1
            elif expiry and expiry <= now:
                grants.revoke(p, reason="expired")
                p.status = "expired"
                p.raw = google_data
                p.save()
                lapsed += 1
            else:
                skipped += 1

        self.stdout.write(
            "IAP_SUBS_SYNC checked=%d extended=%d lapsed=%d skipped=%d"
            % (checked, extended, lapsed, skipped)
        )
