from django.core.management.base import BaseCommand
from django.db import connection

class Command(BaseCommand):
    help = 'Check if the elearning tables exist in the database'

    def handle(self, *args, **options):
        with connection.cursor() as cursor:
            # Check if the elearning_batch table exists
            cursor.execute("""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_name='elearning_batch'
                )
            """)
            batch_exists = cursor.fetchone()[0]
            self.stdout.write(f"elearning_batch table exists: {batch_exists}")

            # Check if the elearning_division table exists
            cursor.execute("""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_name='elearning_division'
                )
            """)
            division_exists = cursor.fetchone()[0]
            self.stdout.write(f"elearning_division table exists: {division_exists}")

            # Check if the elearning_subject table exists
            cursor.execute("""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_name='elearning_subject'
                )
            """)
            subject_exists = cursor.fetchone()[0]
            self.stdout.write(f"elearning_subject table exists: {subject_exists}")

            # Check if the elearning_videolesson table exists
            cursor.execute("""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_name='elearning_videolesson'
                )
            """)
            videolesson_exists = cursor.fetchone()[0]
            self.stdout.write(f"elearning_videolesson table exists: {videolesson_exists}")
