from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import timedelta
from adsyconnect.models import ChatRoom, Message, OnlineStatus
import random

User = get_user_model()


class Command(BaseCommand):
    help = 'Creates dummy chat rooms and messages for testing AdsyConnect'

    def add_arguments(self, parser):
        parser.add_argument(
            '--user-id',
            type=int,
            help='ID of the user to create chats for (required)',
        )
        parser.add_argument(
            '--count',
            type=int,
            default=5,
            help='Number of chat rooms to create (default: 5)',
        )

    def handle(self, *args, **options):
        user_id = options.get('user_id')
        count = options['count']

        if not user_id:
            self.stdout.write(self.style.ERROR('Please provide --user-id'))
            return

        try:
            main_user = User.objects.get(id=user_id)
        except User.DoesNotExist:
            self.stdout.write(self.style.ERROR(f'User with ID {user_id} does not exist'))
            return

        self.stdout.write(f'Creating {count} dummy chats for user: {main_user.username}')

        # Get or create dummy users
        dummy_users = []
        dummy_user_data = [
            {'username': 'john_doe', 'first_name': 'John', 'last_name': 'Doe', 
             'email': 'john@example.com', 'profession': 'Software Engineer'},
            {'username': 'sarah_smith', 'first_name': 'Sarah', 'last_name': 'Smith', 
             'email': 'sarah@example.com', 'profession': 'Marketing Manager'},
            {'username': 'mike_johnson', 'first_name': 'Mike', 'last_name': 'Johnson', 
             'email': 'mike@example.com', 'profession': 'Business Owner'},
            {'username': 'emily_davis', 'first_name': 'Emily', 'last_name': 'Davis', 
             'email': 'emily@example.com', 'profession': 'Designer'},
            {'username': 'david_wilson', 'first_name': 'David', 'last_name': 'Wilson', 
             'email': 'david@example.com', 'profession': 'Sales Manager'},
            {'username': 'lisa_brown', 'first_name': 'Lisa', 'last_name': 'Brown', 
             'email': 'lisa@example.com', 'profession': 'Product Manager'},
            {'username': 'james_taylor', 'first_name': 'James', 'last_name': 'Taylor', 
             'email': 'james@example.com', 'profession': 'Developer'},
            {'username': 'maria_garcia', 'first_name': 'Maria', 'last_name': 'Garcia', 
             'email': 'maria@example.com', 'profession': 'Entrepreneur'},
        ]

        for data in dummy_user_data[:count]:
            user, created = User.objects.get_or_create(
                username=data['username'],
                defaults={
                    'first_name': data['first_name'],
                    'last_name': data['last_name'],
                    'email': data['email'],
                }
            )
            
            # Set profession if user has that field
            if hasattr(user, 'profession'):
                user.profession = data['profession']
                user.save()

            dummy_users.append(user)
            
            # Create online status
            online_status, _ = OnlineStatus.objects.get_or_create(user=user)
            online_status.is_online = random.choice([True, False])
            online_status.last_seen = timezone.now() - timedelta(
                minutes=random.randint(1, 120)
            )
            online_status.save()

            if created:
                self.stdout.write(f'  Created dummy user: {user.username}')

        # Create chat rooms and messages
        sample_messages = [
            "Hey, is the product still available?",
            "Thanks for the quick response!",
            "Can we schedule a meeting?",
            "I'm interested in your service",
            "What's the best price you can offer?",
            "Do you ship internationally?",
            "Can you send more details?",
            "Is this still available?",
            "Let me know when you're free",
            "Thanks, I'll get back to you",
        ]

        for i, other_user in enumerate(dummy_users):
            # Check if chat room already exists
            existing_room = ChatRoom.objects.filter(
                user1=main_user, user2=other_user
            ).first() or ChatRoom.objects.filter(
                user1=other_user, user2=main_user
            ).first()

            if existing_room:
                chatroom = existing_room
                self.stdout.write(f'  Chat room with {other_user.username} already exists')
            else:
                # Create chat room
                chatroom = ChatRoom.objects.create(
                    user1=main_user,
                    user2=other_user,
                    last_message_at=timezone.now() - timedelta(minutes=i * 10)
                )
                self.stdout.write(self.style.SUCCESS(
                    f'  Created chat room with {other_user.username}'
                ))

            # Create 2-5 messages
            num_messages = random.randint(2, 5)
            for j in range(num_messages):
                is_from_main_user = j % 2 == 0
                sender = main_user if is_from_main_user else other_user
                receiver = other_user if is_from_main_user else main_user

                message = Message.objects.create(
                    chatroom=chatroom,
                    sender=sender,
                    receiver=receiver,
                    message_type='text',
                    content=random.choice(sample_messages),
                    is_read=random.choice([True, False]) if not is_from_main_user else True,
                    created_at=timezone.now() - timedelta(
                        minutes=i * 10 + j * 2,
                        seconds=random.randint(0, 59)
                    )
                )

                # Update chatroom's last message
                if j == num_messages - 1:
                    chatroom.last_message_at = message.created_at
                    chatroom.last_message_preview = message.get_preview()
                    chatroom.save()

            self.stdout.write(f'    Created {num_messages} messages')

        self.stdout.write(self.style.SUCCESS(
            f'\nSuccessfully created {count} dummy chats for {main_user.username}!'
        ))
        self.stdout.write('\nTo test in the app, log in as the user and open AdsyConnect.')
