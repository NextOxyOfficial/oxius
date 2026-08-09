import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):
    """Per-person departure times for the original pair of a call.

    A one-to-one call needs neither field: whoever hangs up, it is over. Once
    a third person is invited that stops being true, and 'status' alone
    cannot say "the caller is gone but the call is not".
    """

    dependencies = [
        ('adsyconnect', '0017_callparticipant'),
    ]

    operations = [
        migrations.AddField(
            model_name='callsession',
            name='caller_left_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='callsession',
            name='callee_left_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='callsession',
            name='chat_group',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='call_sessions',
                to='adsyconnect.chatgroup',
            ),
        ),
    ]
