# Generated by Django 5.1.4 on 2025-01-05 10:48

import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='Country',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name_eng', models.CharField(max_length=100)),
                ('name_ban', models.CharField(max_length=100)),
            ],
        ),
        migrations.CreateModel(
            name='Region',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name_eng', models.CharField(max_length=100)),
                ('name_ban', models.CharField(max_length=100)),
                ('country', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='cities.country')),
            ],
        ),
        migrations.CreateModel(
            name='City',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name_eng', models.CharField(max_length=100)),
                ('name_ban', models.CharField(max_length=100)),
                ('zip', models.CharField(max_length=100)),
                ('region', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='cities.region')),
            ],
        ),
        migrations.CreateModel(
            name='Upazila',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name_eng', models.CharField(max_length=100)),
                ('name_ban', models.CharField(max_length=100)),
                ('city', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='cities.city')),
            ],
        ),
    ]