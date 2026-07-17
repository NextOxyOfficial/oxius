from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('adsyconnect', '0009_chatgroup_groupmessage'),
    ]

    operations = [
        migrations.AddField(
            model_name='groupmessage',
            name='file_name',
            field=models.CharField(blank=True, max_length=255, null=True),
        ),
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
                ],
                default='text',
                max_length=20,
            ),
        ),
    ]
