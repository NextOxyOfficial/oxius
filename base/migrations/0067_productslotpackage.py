# Generated manually

import uuid
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('base', '0066_diamondpackages'),
    ]

    operations = [
        migrations.CreateModel(
            name='ProductSlotPackage',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('slots', models.IntegerField(help_text='Number of product slots in this package')),
                ('price', models.DecimalField(decimal_places=2, max_digits=8)),
                ('original_price', models.DecimalField(blank=True, decimal_places=2, help_text='Original price before discount', max_digits=8, null=True)),
                ('is_featured', models.BooleanField(default=False, help_text='Highlight this package as best value')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
            ],
            options={
                'ordering': ['slots'],
            },
        ),
    ]
