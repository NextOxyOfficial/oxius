"""
Add the force close endpoint to the session_manager
"""
from django.core.management.base import BaseCommand
from elearning.models import ELearningSession
from django.utils import timezone

class Command(BaseCommand):
    help = 'Sets up the force close endpoint for session management'

    def handle(self, *args, **options):
        # This is a dummy command file to add class method to session_manager.py
        # The actual code is added directly to session_manager.py and session_views.py
        self.stdout.write(self.style.SUCCESS('The force close endpoint has been added.'))
