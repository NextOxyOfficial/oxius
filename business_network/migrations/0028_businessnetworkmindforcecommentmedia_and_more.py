# Generated by Django 5.1.4 on 2025-05-06 10:32

from django.db import migrations, models


def clear_media_relations(apps, schema_editor):
    """
    This function clears existing media relations before changing the model structure.
    We need to do this to avoid foreign key constraint violations.
    """
    BusinessNetworkMindforceComment = apps.get_model('business_network', 'BusinessNetworkMindforceComment')
    # Clear all media relations to avoid FK constraint errors 
    for comment in BusinessNetworkMindforceComment.objects.all():
        comment.media.clear()


class Migration(migrations.Migration):

    dependencies = [
        ('business_network', '0027_businessnetworkmindforcecomment_media'),
    ]

    operations = [
        # First clear out all the existing media relations to avoid FK violations
        migrations.RunPython(clear_media_relations, migrations.RunPython.noop),
        
        # Then create the new model
        migrations.CreateModel(
            name='BusinessNetworkMindforceCommentMedia',
            fields=[
                ('id', models.CharField(editable=False, max_length=20, primary_key=True, serialize=False, unique=True)),
                ('image', models.ImageField(blank=True, null=True, upload_to='business_network/mindforce/comment/')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
            ],
        ),
        
        # After clearing relations and creating the new model, we can safely alter the field
        migrations.AlterField(
            model_name='businessnetworkmindforcecomment',
            name='media',
            field=models.ManyToManyField(blank=True, related_name='mindforce_comments', to='business_network.businessnetworkmindforcecommentmedia'),
        ),
    ]
