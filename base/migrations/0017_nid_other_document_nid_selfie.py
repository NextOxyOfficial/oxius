# Generated by Django 5.1.4 on 2024-12-30 13:25

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('base', '0016_remove_user_refer_user_refer'),
    ]

    operations = [
        migrations.AddField(
            model_name='nid',
            name='other_document',
            field=models.ImageField(blank=True, null=True, upload_to='images/'),
        ),
        migrations.AddField(
            model_name='nid',
            name='selfie',
            field=models.ImageField(blank=True, null=True, upload_to='images/'),
        ),
    ]