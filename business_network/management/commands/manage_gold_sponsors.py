from django.core.management.base import BaseCommand
from django.utils import timezone
from business_network.models import GoldSponsor
from datetime import timedelta

class Command(BaseCommand):
    help = 'Manage Gold Sponsor statuses and cleanup expired sponsorships'

    def add_arguments(self, parser):
        parser.add_argument(
            '--check-expired',
            action='store_true',
            help='Check and mark expired sponsorships',
        )
        parser.add_argument(
            '--activate',
            type=int,
            help='Activate a sponsor by ID',
        )
        parser.add_argument(
            '--deactivate',
            type=int,
            help='Deactivate a sponsor by ID',
        )
        parser.add_argument(
            '--list-pending',
            action='store_true',
            help='List all pending sponsor applications',
        )

    def handle(self, *args, **options):
        if options['check_expired']:
            self.check_expired_sponsors()
        
        if options['activate']:
            self.activate_sponsor(options['activate'])
        
        if options['deactivate']:
            self.deactivate_sponsor(options['deactivate'])
        
        if options['list_pending']:
            self.list_pending_sponsors()

    def check_expired_sponsors(self):
        now = timezone.now()
        expired_sponsors = GoldSponsor.objects.filter(
            status='active',
            end_date__lt=now
        )
        
        count = expired_sponsors.count()
        if count > 0:
            expired_sponsors.update(status='expired')
            self.stdout.write(
                self.style.SUCCESS(f'Marked {count} sponsorships as expired')
            )
        else:
            self.stdout.write('No expired sponsorships found')

    def activate_sponsor(self, sponsor_id):
        try:
            sponsor = GoldSponsor.objects.get(id=sponsor_id)
            sponsor.status = 'active'
            sponsor.save()
            self.stdout.write(
                self.style.SUCCESS(f'Activated sponsor: {sponsor.business_name}')
            )
        except GoldSponsor.DoesNotExist:
            self.stdout.write(
                self.style.ERROR(f'Sponsor with ID {sponsor_id} not found')
            )

    def deactivate_sponsor(self, sponsor_id):
        try:
            sponsor = GoldSponsor.objects.get(id=sponsor_id)
            sponsor.status = 'inactive'
            sponsor.save()
            self.stdout.write(
                self.style.WARNING(f'Deactivated sponsor: {sponsor.business_name}')
            )
        except GoldSponsor.DoesNotExist:
            self.stdout.write(
                self.style.ERROR(f'Sponsor with ID {sponsor_id} not found')
            )

    def list_pending_sponsors(self):
        pending_sponsors = GoldSponsor.objects.filter(status='pending').order_by('-created_at')
        
        if pending_sponsors.exists():
            self.stdout.write(self.style.WARNING('Pending Gold Sponsor Applications:'))
            self.stdout.write('-' * 60)
            for sponsor in pending_sponsors:
                self.stdout.write(
                    f'ID: {sponsor.id:3} | {sponsor.business_name:30} | {sponsor.contact_email:25} | {sponsor.created_at.strftime("%Y-%m-%d")}'
                )
        else:
            self.stdout.write('No pending sponsor applications found')
