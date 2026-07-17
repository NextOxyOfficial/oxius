from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('adsyconnect', '0010_groupmessage_media_types'),
    ]

    operations = [
        migrations.AlterField(
            model_name='groupmessage',
            name='message_type',
            field=models.CharField(
                choices=[
                    ('text', 'Text'),
                    ('voice', 'Voice'),
                    ('image', 'Image'),
                    ('video', 'Video'),
                    ('document', 'Document'),
                    ('system', 'System'),
                ],
                default='text',
                max_length=20,
            ),
        ),
    ]
