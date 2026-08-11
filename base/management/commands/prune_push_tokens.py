# -*- coding: utf-8 -*-
"""Retire push tokens that can no longer ring anything.

Two kinds accumulate, and neither is cleaned up on its own:

  * guest rows — registered before login so a new install can be sent a
    conversion nudge. Most convert within days; the rest are installs that
    were removed, and they sit in the table forever.
  * a signed-in account's older registrations. A token changes on reinstall,
    on a restore to a new phone, and whenever the OS rotates it. The provider
    reports the ones it knows are dead, but a wiped phone never produces that
    answer.

Deactivates rather than deletes: the row is the only record of which device
this was, and save_fcm_token revives it by token if the app comes back.

    manage.py prune_push_tokens              # what it would do
    manage.py prune_push_tokens --apply
"""
from django.core.management.base import BaseCommand
from django.db.models import Count
from django.utils import timezone

from base.models import FCMToken

#: A guest install that has not signed in within this long is not going to.
GUEST_MAX_AGE_DAYS = 45

#: Matches _MAX_TOKENS_PER_USER in base.views — the cap new registrations
#: already enforce. This applies it to accounts that grew past it earlier.
MAX_TOKENS_PER_USER = 8


class Command(BaseCommand):
    help = 'Deactivate push tokens that can no longer be delivered to.'

    def add_arguments(self, parser):
        parser.add_argument(
            '--apply', action='store_true',
            help='Write the changes. Without it, only report them.',
        )
        parser.add_argument(
            '--guest-days', type=int, default=GUEST_MAX_AGE_DAYS,
            help='How old a never-converted guest row must be (default %d).'
                 % GUEST_MAX_AGE_DAYS,
        )

    def handle(self, *args, **options):
        apply_changes = options['apply']
        guest_days = options['guest_days']
        now = timezone.now()

        self.stdout.write(
            'APPLYING' if apply_changes else 'DRY RUN — nothing will be written')
        active = FCMToken.objects.filter(is_active=True)
        self.stdout.write('active rows before ......... %d' % active.count())

        # ── guest rows nobody ever signed in on ───────────────────────────
        cutoff = now - timezone.timedelta(days=guest_days)
        stale_guests = FCMToken.objects.filter(
            is_active=True, user__isnull=True, updated_at__lt=cutoff)
        guest_count = stale_guests.count()
        self.stdout.write(
            'guest rows older than %dd .... %d' % (guest_days, guest_count))

        # ── accounts over the cap ─────────────────────────────────────────
        crowded = (
            FCMToken.objects.filter(is_active=True, user__isnull=False)
            .values('user')
            .annotate(n=Count('id'))
            .filter(n__gt=MAX_TOKENS_PER_USER)
        )
        over_cap_ids = []
        for row in crowded:
            keep_then_drop = list(
                FCMToken.objects.filter(user_id=row['user'], is_active=True)
                .order_by('-updated_at')
                .values_list('id', flat=True)
            )
            over_cap_ids.extend(keep_then_drop[MAX_TOKENS_PER_USER:])

        self.stdout.write(
            'rows over the %d-device cap .. %d  (across %d account(s))'
            % (MAX_TOKENS_PER_USER, len(over_cap_ids), len(crowded)))

        if not apply_changes:
            self.stdout.write('')
            self.stdout.write('Nothing written. Re-run with --apply.')
            return

        retired_guests = stale_guests.update(is_active=False)
        retired_over_cap = 0
        if over_cap_ids:
            retired_over_cap = FCMToken.objects.filter(
                id__in=over_cap_ids).update(is_active=False)

        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS(
            'retired %d guest row(s) and %d over-cap row(s); %d active remain'
            % (retired_guests, retired_over_cap,
               FCMToken.objects.filter(is_active=True).count())))
