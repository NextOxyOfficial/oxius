# Generated manually for Support app
from django.db import migrations, models
import django.db.models.deletion
from django.conf import settings
import uuid

def create_uuid_ids(apps, schema_editor):
    SupportTicket = apps.get_model('support', 'SupportTicket')
    TicketReply = apps.get_model('support', 'TicketReply')
    
    for ticket in SupportTicket.objects.all():
        ticket.id = str(uuid.uuid4())[:20]
        ticket.save()
    
    for reply in TicketReply.objects.all():
        reply.id = str(uuid.uuid4())[:20]
        reply.save()

class Migration(migrations.Migration):

    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='SupportTicket',
            fields=[
                ('id', models.CharField(editable=False, max_length=20, primary_key=True, serialize=False, unique=True)),
                ('title', models.CharField(max_length=255)),
                ('message', models.TextField()),
                ('status', models.CharField(choices=[('open', 'Open'), ('in_progress', 'In Progress'), ('resolved', 'Resolved'), ('closed', 'Closed')], default='open', max_length=20)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='tickets', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'ordering': ['-created_at'],
            },
        ),
        migrations.CreateModel(
            name='TicketReply',
            fields=[
                ('id', models.CharField(editable=False, max_length=20, primary_key=True, serialize=False, unique=True)),
                ('message', models.TextField()),
                ('is_from_admin', models.BooleanField(default=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('ticket', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='replies', to='support.supportticket')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='ticket_replies', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'ordering': ['created_at'],
            },
        ),
    ]
