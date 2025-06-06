# Generated by Django 5.1.4 on 2025-05-13 11:12

import django.db.models.deletion
import sale.models
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('sale', '0005_alter_salepostimage_options_and_more'),
    ]

    operations = [
        migrations.CreateModel(
            name='SaleCategory',
            fields=[
                ('id', models.BigIntegerField(default=sale.models.generate_unique_id, editable=False, primary_key=True, serialize=False)),
                ('name', models.CharField(max_length=255)),
                ('icon', models.ImageField(blank=True, null=True, upload_to='sale_categories/')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
            ],
            options={
                'verbose_name': 'Sale Category',
                'verbose_name_plural': 'Sale Categories',
                'ordering': ['name'],
            },
        ),
        migrations.CreateModel(
            name='SaleChildCategory',
            fields=[
                ('id', models.BigIntegerField(default=sale.models.generate_unique_id, editable=False, primary_key=True, serialize=False)),
                ('name', models.CharField(max_length=255)),
                ('icon', models.ImageField(blank=True, null=True, upload_to='sale_child_categories/')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('parent', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='child_categories', to='sale.salecategory')),
            ],
            options={
                'verbose_name': 'Sale Child Category',
                'verbose_name_plural': 'Sale Child Categories',
                'ordering': ['name'],
            },
        ),
        migrations.CreateModel(
            name='SaleImage',
            fields=[
                ('id', models.BigIntegerField(default=sale.models.generate_unique_id, editable=False, primary_key=True, serialize=False)),
                ('image', models.ImageField(upload_to='sale_posts_images/')),
                ('is_main', models.BooleanField(default=False)),
                ('order', models.PositiveIntegerField(default=0)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
            ],
            options={
                'verbose_name': 'Sale Image',
                'verbose_name_plural': 'Sale Images',
                'ordering': ['order'],
            },
        ),
        migrations.DeleteModel(
            name='ForSaleBanner',
        ),
        migrations.RemoveField(
            model_name='salepost',
            name='images',
        ),
        migrations.RemoveField(
            model_name='salepost',
            name='age_unit',
        ),
        migrations.RemoveField(
            model_name='salepost',
            name='age_value',
        ),
        migrations.RemoveField(
            model_name='salepost',
            name='amenities',
        ),
        migrations.RemoveField(
            model_name='salepost',
            name='bathrooms',
        ),
        migrations.RemoveField(
            model_name='salepost',
            name='bedrooms',
        ),
        migrations.RemoveField(
            model_name='salepost',
            name='brand',
        ),
        migrations.RemoveField(
            model_name='salepost',
            name='electronics_type',
        ),
        migrations.RemoveField(
            model_name='salepost',
            name='expires_at',
        ),
        migrations.RemoveField(
            model_name='salepost',
            name='featured',
        ),
        migrations.RemoveField(
            model_name='salepost',
            name='fuel_type',
        ),
        migrations.RemoveField(
            model_name='salepost',
            name='item_quality',
        ),
        migrations.RemoveField(
            model_name='salepost',
            name='item_type',
        ),
        migrations.RemoveField(
            model_name='salepost',
            name='make',
        ),
        migrations.RemoveField(
            model_name='salepost',
            name='mileage',
        ),
        migrations.RemoveField(
            model_name='salepost',
            name='model',
        ),
        migrations.RemoveField(
            model_name='salepost',
            name='property_type',
        ),
        migrations.RemoveField(
            model_name='salepost',
            name='registration_year',
        ),
        migrations.RemoveField(
            model_name='salepost',
            name='size',
        ),
        migrations.RemoveField(
            model_name='salepost',
            name='transmission',
        ),
        migrations.RemoveField(
            model_name='salepost',
            name='unit',
        ),
        migrations.RemoveField(
            model_name='salepost',
            name='vehicle_type',
        ),
        migrations.RemoveField(
            model_name='salepost',
            name='warranty',
        ),
        migrations.RemoveField(
            model_name='salepost',
            name='year',
        ),
        migrations.AlterField(
            model_name='salepost',
            name='id',
            field=models.BigIntegerField(default=sale.models.generate_unique_id, editable=False, primary_key=True, serialize=False),
        ),
        migrations.AlterField(
            model_name='salepost',
            name='status',
            field=models.CharField(choices=[('pending', 'Pending Review'), ('active', 'Active'), ('sold', 'Sold'), ('expired', 'Expired')], default='pending', max_length=20),
        ),
        migrations.AlterField(
            model_name='salepost',
            name='category',
            field=models.ForeignKey(null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='posts', to='sale.salecategory'),
        ),
        migrations.AddField(
            model_name='salepost',
            name='child_category',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='posts', to='sale.salechildcategory'),
        ),
        migrations.AddField(
            model_name='saleimage',
            name='post',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='images', to='sale.salepost'),
        ),
        migrations.DeleteModel(
            name='ForSaleSubCategory',
        ),
        migrations.DeleteModel(
            name='SalePostImage',
        ),
        migrations.DeleteModel(
            name='ForSaleCategory',
        ),
    ]
