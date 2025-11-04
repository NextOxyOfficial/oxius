import firebase_admin
from firebase_admin import credentials, messaging
import os
from django.conf import settings

# Initialize Firebase Admin SDK
try:
    cred_path = os.path.join(settings.BASE_DIR, 'firebase-adminsdk.json')
    if not firebase_admin._apps:
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
        print('✅ Firebase Admin SDK initialized')
except Exception as e:
    print(f'❌ Error initializing Firebase Admin SDK: {e}')


def send_fcm_notification(fcm_token, title, body, data=None):
    """
    Send FCM notification to a single device
    
    Args:
        fcm_token (str): The FCM token of the device
        title (str): Notification title
        body (str): Notification body
        data (dict): Additional data payload
    
    Returns:
        bool: True if successful, False otherwise
    """
    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data or {},
            token=fcm_token,
            android=messaging.AndroidConfig(
                priority='high',
                notification=messaging.AndroidNotification(
                    sound='default',
                    channel_id='oxius_messages',
                    color='#10B981',
                ),
            ),
        )
        
        response = messaging.send(message)
        print(f'✅ Notification sent successfully: {response}')
        return True
    except Exception as e:
        print(f'❌ Error sending notification: {e}')
        return False


def send_fcm_notification_multicast(fcm_tokens, title, body, data=None):
    """
    Send FCM notification to multiple devices
    
    Args:
        fcm_tokens (list): List of FCM tokens
        title (str): Notification title
        body (str): Notification body
        data (dict): Additional data payload
    
    Returns:
        BatchResponse: Response object with success/failure counts
    """
    try:
        # Filter out None and empty tokens
        valid_tokens = [token for token in fcm_tokens if token]
        
        if not valid_tokens:
            print('⚠️ No valid FCM tokens provided')
            return None
        
        message = messaging.MulticastMessage(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data or {},
            tokens=valid_tokens,
            android=messaging.AndroidConfig(
                priority='high',
                notification=messaging.AndroidNotification(
                    sound='default',
                    channel_id='oxius_messages',
                    color='#10B981',
                ),
            ),
        )
        
        response = messaging.send_multicast(message)
        print(f'✅ Sent {response.success_count} notifications')
        if response.failure_count > 0:
            print(f'⚠️ Failed to send {response.failure_count} notifications')
        return response
    except Exception as e:
        print(f'❌ Error sending multicast notification: {e}')
        return None


def send_message_notification(recipient_user, sender_name, message_text, chat_id):
    """
    Send notification when user receives a new message
    
    Args:
        recipient_user: User object who will receive the notification
        sender_name (str): Name of the message sender
        message_text (str): The message content
        chat_id (str): ID of the chat
    """
    from .models import FCMToken
    
    # Get user's active FCM tokens
    fcm_tokens = FCMToken.objects.filter(
        user=recipient_user,
        is_active=True
    ).values_list('token', flat=True)
    
    if not fcm_tokens:
        print(f'⚠️ No FCM tokens found for user: {recipient_user.email}')
        return
    
    # Truncate long messages
    truncated_message = message_text[:100] + '...' if len(message_text) > 100 else message_text
    
    # Send notification to each token
    for token in fcm_tokens:
        send_fcm_notification(
            fcm_token=token,
            title=f'New message from {sender_name}',
            body=truncated_message,
            data={
                'type': 'message',
                'sender_name': sender_name,
                'chat_id': str(chat_id),
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            }
        )


def send_order_notification(user, order_id, title, body):
    """
    Send notification for order updates
    
    Args:
        user: User object
        order_id (str): Order ID
        title (str): Notification title
        body (str): Notification body
    """
    from .models import FCMToken
    
    fcm_tokens = FCMToken.objects.filter(
        user=user,
        is_active=True
    ).values_list('token', flat=True)
    
    if not fcm_tokens:
        return
    
    for token in fcm_tokens:
        send_fcm_notification(
            fcm_token=token,
            title=title,
            body=body,
            data={
                'type': 'order',
                'order_id': str(order_id),
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            }
        )


def send_wallet_notification(user, amount, transaction_type):
    """
    Send notification for wallet transactions
    
    Args:
        user: User object
        amount (Decimal): Transaction amount
        transaction_type (str): Type of transaction (transfer, deposit, withdraw)
    """
    from .models import FCMToken
    
    fcm_tokens = FCMToken.objects.filter(
        user=user,
        is_active=True
    ).values_list('token', flat=True)
    
    if not fcm_tokens:
        return
    
    title = 'Wallet Update'
    if transaction_type == 'transfer':
        body = f'You received ৳{amount}'
    elif transaction_type == 'deposit':
        body = f'Deposit of ৳{amount} successful'
    elif transaction_type == 'withdraw':
        body = f'Withdrawal of ৳{amount} processed'
    else:
        body = f'Transaction of ৳{amount} completed'
    
    for token in fcm_tokens:
        send_fcm_notification(
            fcm_token=token,
            title=title,
            body=body,
            data={
                'type': 'wallet',
                'amount': str(amount),
                'transaction_type': transaction_type,
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            }
        )
