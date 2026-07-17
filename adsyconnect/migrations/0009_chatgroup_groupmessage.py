import uuid

import django.db.models.deletion
import django.utils.timezone
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('adsyconnect', '0008_message_is_spam_message_spam_category'),
    ]

    operations = [
        migrations.CreateModel(
            name='ChatGroup',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('name', models.CharField(max_length=80)),
                ('image', models.ImageField(blank=True, null=True, upload_to='adsyconnect/groups/')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('last_message_at', models.DateTimeField(default=django.utils.timezone.now)),
                ('last_message_preview', models.TextField(blank=True, null=True)),
                ('creator', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='adsy_groups_created', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'db_table': 'adsyconnect_chat_groups',
                'ordering': ['-last_message_at'],
            },
        ),
        migrations.CreateModel(
            name='ChatGroupMembership',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('role', models.CharField(choices=[('admin', 'Admin'), ('member', 'Member')], default='member', max_length=10)),
                ('joined_at', models.DateTimeField(auto_now_add=True)),
                ('cleared_at', models.DateTimeField(blank=True, null=True)),
                ('muted', models.BooleanField(default=False)),
                ('typing_at', models.DateTimeField(blank=True, null=True)),
                ('group', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='memberships', to='adsyconnect.chatgroup')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='adsy_group_memberships', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'db_table': 'adsyconnect_chat_group_memberships',
                'unique_together': {('group', 'user')},
            },
        ),
        migrations.CreateModel(
            name='GroupMessage',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('message_type', models.CharField(choices=[('text', 'Text'), ('voice', 'Voice'), ('image', 'Image')], default='text', max_length=20)),
                ('content', models.TextField(blank=True, null=True)),
                ('media_file', models.FileField(blank=True, null=True, upload_to='adsyconnect/group_media/%Y/%m/%d/')),
                ('voice_duration', models.IntegerField(blank=True, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('is_deleted', models.BooleanField(default=False)),
                ('group', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='messages', to='adsyconnect.chatgroup')),
                ('sender', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='adsy_group_messages', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'db_table': 'adsyconnect_group_messages',
                'ordering': ['created_at'],
            },
        ),
        migrations.AddIndex(
            model_name='groupmessage',
            index=models.Index(fields=['group', 'created_at'], name='adsy_grpmsg_grp_created_idx'),
        ),
    ]
