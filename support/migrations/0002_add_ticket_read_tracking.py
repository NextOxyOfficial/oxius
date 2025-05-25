# Generated manually

from django.db import migrations, models
import django.db.models.deletion
import django.utils.timezone


class Migration(migrations.Migration):

    dependencies = [
        ('base', '0001_initial'),  # Adjust this if your User model has a different dependency
        ('support', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='TicketReadStatus',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('last_read_at', models.DateTimeField(default=django.utils.timezone.now)),
                ('ticket', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='read_statuses', to='support.supportticket')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='ticket_read_statuses', to='base.user')),
            ],
            options={
                'verbose_name': 'Ticket Read Status',
                'verbose_name_plural': 'Ticket Read Statuses',
                'unique_together': {('ticket', 'user')},
            },
        ),
    ]