# Generated by Django 5.1.4 on 2024-12-11 07:09

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('base', '0009_rename_accepted_privacy_microgigposttask_accepted_condition'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='microgigposttask',
            name='approved',
        ),
        migrations.RemoveField(
            model_name='microgigposttask',
            name='completed',
        ),
        migrations.RemoveField(
            model_name='microgigposttask',
            name='rejected',
        ),
        migrations.AddField(
            model_name='microgigposttask',
            name='status',
            field=models.CharField(choices=[('PENDING', 'Pending'), ('APPROVED', 'Approved'), ('REJECTED', 'Rejected'), ('COMPLETED', 'Completed')], default='PENDING', max_length=10),
        ),
        migrations.AlterField(
            model_name='microgigposttask',
            name='medias',
            field=models.ManyToManyField(blank=True, to='base.microgigpostmedia'),
        ),
    ]
