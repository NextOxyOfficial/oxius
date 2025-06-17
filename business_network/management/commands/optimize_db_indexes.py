from django.core.management.base import BaseCommand
from django.db import connection


class Command(BaseCommand):
    help = 'Add database indexes for business network performance optimization'

    def handle(self, *args, **options):
        with connection.cursor() as cursor:
            # Add indexes for better query performance
            indexes = [
                # Index for post priority queries
                "CREATE INDEX IF NOT EXISTS idx_bn_post_author_created ON business_network_businessnetworkpost(author_id, created_at DESC);",
                
                # Index for follower relationships
                "CREATE INDEX IF NOT EXISTS idx_bn_follower_relationship ON business_network_businessnetworkfollowermodel(follower_id, following_id);",
                
                # Index for post likes count
                "CREATE INDEX IF NOT EXISTS idx_bn_post_likes ON business_network_businessnetworkpostlike(post_id);",
                
                # Index for post comments count
                "CREATE INDEX IF NOT EXISTS idx_bn_post_comments ON business_network_businessnetworkpostcomment(post_id);",
                
                # Index for post follows
                "CREATE INDEX IF NOT EXISTS idx_bn_post_follows ON business_network_businessnetworkpostfollow(post_id);",
                
                # Index for user location-based queries
                "CREATE INDEX IF NOT EXISTS idx_user_location ON base_user(city, state);",
                
                # Index for post created_at for better ordering
                "CREATE INDEX IF NOT EXISTS idx_bn_post_created_at ON business_network_businessnetworkpost(created_at DESC);",
            ]
            
            for index_sql in indexes:
                try:
                    cursor.execute(index_sql)
                    self.stdout.write(
                        self.style.SUCCESS(f'Successfully created index: {index_sql[:50]}...')
                    )
                except Exception as e:
                    self.stdout.write(
                        self.style.WARNING(f'Index might already exist or error: {e}')
                    )

        self.stdout.write(
            self.style.SUCCESS('Database optimization indexes have been applied!')
        )
