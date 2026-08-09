from django.db import migrations, models


class Migration(migrations.Migration):
    """Which groups exist only because a call needed one.

    Those grow with the call. A group somebody made deliberately does not:
    pulling an outsider into a call started from it must not hand them
    permanent membership of the conversation.
    """

    dependencies = [
        ('adsyconnect', '0018_callsession_member_left_timestamps'),
    ]

    operations = [
        migrations.AddField(
            model_name='chatgroup',
            name='created_from_call',
            field=models.BooleanField(default=False),
        ),
    ]
