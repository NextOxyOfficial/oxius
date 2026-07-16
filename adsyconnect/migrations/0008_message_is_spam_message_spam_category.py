from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('adsyconnect', '0007_chatroom_archived_by_user1_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='message',
            name='is_spam',
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name='message',
            name='spam_category',
            field=models.CharField(blank=True, default='', max_length=20),
        ),
    ]
