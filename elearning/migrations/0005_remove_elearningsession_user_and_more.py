# Generated by Django 5.1.4 on 2025-05-29 07:36

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('elearning', '0004_rename_elearning_d_device__84ceaf_idx_elearning_d_device__ac3812_idx_and_more'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='elearningsession',
            name='user',
        ),
        migrations.RemoveField(
            model_name='sessionactivitylog',
            name='session',
        ),
        migrations.RemoveField(
            model_name='suspiciousactivity',
            name='user',
        ),
        migrations.DeleteModel(
            name='DeviceSession',
        ),
        migrations.DeleteModel(
            name='ELearningSession',
        ),
        migrations.DeleteModel(
            name='SessionActivityLog',
        ),
        migrations.DeleteModel(
            name='SuspiciousActivity',
        ),
    ]
