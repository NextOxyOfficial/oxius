# Generated by Django 5.1.4 on 2024-12-09 10:14

import django.db.models.deletion
import uuid
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('base', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='ClassifiedCategoryPostMedia',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('image', models.ImageField(blank=True, null=True, upload_to='images/')),
                ('video', models.FileField(blank=True, null=True, upload_to='videos/')),
            ],
        ),
        migrations.CreateModel(
            name='ClassifiedCategoryPost',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('title', models.CharField(max_length=256)),
                ('location', models.TextField(max_length=512)),
                ('price', models.DecimalField(decimal_places=2, default=0.0, max_digits=8)),
                ('image', models.ImageField(blank=True, null=True, upload_to='images/')),
                ('instructions', models.TextField(blank=True, default='', null=True)),
                ('accepted_terms', models.BooleanField(default=True)),
                ('accepted_privacy', models.BooleanField(default=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('category', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='classified_categories_posts', to='base.classifiedcategory')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='classified_categories_posts', to=settings.AUTH_USER_MODEL)),
                ('medias', models.ManyToManyField(blank=True, null=True, to='base.classifiedcategorypostmedia')),
            ],
        ),
    ]
