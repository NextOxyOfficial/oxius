# Generated manually for Gold Sponsor updates

import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models
import uuid  # Add import for UUID


def assign_default_user_to_sponsors(apps, schema_editor):
    """Assign a default user to existing sponsors"""
    GoldSponsor = apps.get_model('business_network', 'GoldSponsor')
    User = apps.get_model('base', 'User')  # Changed from 'auth' to 'base'
    
    # Check if there are any GoldSponsors that need a user assignment
    if GoldSponsor.objects.filter(user__isnull=True).exists():
        # First try to find an existing admin user
        try:
            admin_user = User.objects.get(is_superuser=True)
        except User.DoesNotExist:
            try:
                # Try to get any user
                admin_user = User.objects.first()
            except User.DoesNotExist:
                # If no users exist, create one with unique values
                unique_phone = f'admin-{uuid.uuid4().hex[:8]}'
                unique_email = f'admin-{uuid.uuid4().hex[:8]}@example.com'
                
                admin_user = User.objects.create(
                    username='admin',
                    email=unique_email,
                    is_staff=True,
                    is_superuser=True,
                    phone=unique_phone,                )
        
        # Assign the admin user to all existing sponsors that don't have a user
        GoldSponsor.objects.filter(user__isnull=True).update(user=admin_user)


def reverse_assign_user(apps, schema_editor):
    """Reverse operation - set user field to null"""
    GoldSponsor = apps.get_model('business_network', 'GoldSponsor')
    GoldSponsor.objects.all().update(user=None)


class Migration(migrations.Migration):

    dependencies = [
        ('business_network', '0033_sponsorshippackage_goldsponsor'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        # Step 1: Add the user field as nullable
        migrations.AddField(
            model_name='goldsponsor',
            name='user',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='gold_sponsors', to=settings.AUTH_USER_MODEL, null=True),
        ),        # Step 2: Populate existing records with a default user
        migrations.RunPython(assign_default_user_to_sponsors, reverse_assign_user),
        # Step 3: Make the user field non-nullable
        migrations.AlterField(
            model_name='goldsponsor',
            name='user',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='gold_sponsors', to=settings.AUTH_USER_MODEL),        ),
        # Step 4: Add views field
        migrations.AddField(
            model_name='goldsponsor',
            name='views',
            field=models.PositiveIntegerField(default=0),
        ),
        # Step 5: Create GoldSponsorBanner model
        migrations.CreateModel(
            name='GoldSponsorBanner',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('title', models.CharField(blank=True, max_length=255, null=True)),
                ('image', models.ImageField(upload_to='business_network/gold_sponsors/banners/')),
                ('link_url', models.URLField(blank=True, null=True)),
                ('order', models.PositiveIntegerField(default=0)),
                ('is_active', models.BooleanField(default=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('sponsor', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='banners', to='business_network.goldsponsor')),
            ],            options={
                'verbose_name': 'Gold Sponsor Banner',
                'verbose_name_plural': 'Gold Sponsor Banners',
                'ordering': ['order', '-created_at'],
            },
        ),
    ]
