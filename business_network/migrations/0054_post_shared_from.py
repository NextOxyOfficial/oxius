import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('business_network', '0053_postseen'),
    ]

    operations = [
        migrations.AddField(
            model_name='businessnetworkpost',
            name='shared_from',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='reshares',
                to='business_network.businessnetworkpost',
            ),
        ),
        migrations.AlterField(
            model_name='businessnetworknotification',
            name='type',
            field=models.CharField(
                choices=[
                    ('follow', 'Follow'),
                    ('like_post', 'Like Post'),
                    ('like_comment', 'Like Comment'),
                    ('comment', 'Comment'),
                    ('reply', 'Reply'),
                    ('mention', 'Mention'),
                    ('solution', 'Solution'),
                    ('share', 'Share'),
                ],
                max_length=20,
            ),
        ),
    ]
