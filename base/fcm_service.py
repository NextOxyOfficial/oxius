import firebase_admin
from firebase_admin import credentials, messaging
import os
from django.conf import settings

# Initialize Firebase Admin SDK
FIREBASE_INITIALIZED = False
FIREBASE_ERROR = None

try:
    cred_path = os.path.join(settings.BASE_DIR, 'firebase-adminsdk.json')
    
    # Check if file exists
    if not os.path.exists(cred_path):
        FIREBASE_ERROR = f'Firebase credentials file not found at: {cred_path}'
        print(f'❌ {FIREBASE_ERROR}')
    else:
        if not firebase_admin._apps:
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            FIREBASE_INITIALIZED = True
            print(f'✅ Firebase Admin SDK initialized successfully')
            print(f'   Credentials file: {cred_path}')
        else:
            FIREBASE_INITIALIZED = True
            print('✅ Firebase Admin SDK already initialized')
except Exception as e:
    FIREBASE_ERROR = str(e)
    print(f'❌ Error initializing Firebase Admin SDK: {e}')
    import traceback
    traceback.print_exc()


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
    # Check if Firebase is initialized
    if not FIREBASE_INITIALIZED:
        print(f'❌ Cannot send notification: Firebase Admin SDK not initialized')
        if FIREBASE_ERROR:
            print(f'   Error: {FIREBASE_ERROR}')
        return False
    
    try:
        # Validate token
        if not fcm_token or not isinstance(fcm_token, str):
            print(f'❌ Invalid FCM token: {fcm_token}')
            return False
        
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
    except messaging.UnregisteredError:
        print(f'❌ Token is invalid or unregistered: {fcm_token[:50]}...')
        return False
    except messaging.SenderIdMismatchError:
        print(f'❌ Token does not match Firebase project: {fcm_token[:50]}...')
        return False
    except Exception as e:
        print(f'❌ Error sending notification: {e}')
        print(f'   Token: {fcm_token[:50]}...')
        print(f'   Title: {title}')
        import traceback
        traceback.print_exc()
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
    # Check if Firebase is initialized
    if not FIREBASE_INITIALIZED:
        print(f'❌ Cannot send notification: Firebase Admin SDK not initialized')
        if FIREBASE_ERROR:
            print(f'   Error: {FIREBASE_ERROR}')
        return None
    
    try:
        # Filter out None and empty tokens
        valid_tokens = [token for token in fcm_tokens if token and isinstance(token, str)]
        
        if not valid_tokens:
            print('⚠️ No valid FCM tokens provided')
            return None
        
        print(f'📤 Sending multicast to {len(valid_tokens)} tokens')
        
        # Create individual messages for each token
        messages = []
        for token in valid_tokens:
            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data=data or {},
                token=token,
                android=messaging.AndroidConfig(
                    priority='high',
                    notification=messaging.AndroidNotification(
                        sound='default',
                        channel_id='oxius_messages',
                        color='#10B981',
                    ),
                ),
            )
            messages.append(message)
        
        # Use send_each_for_multicast (new API in firebase-admin 7.x)
        response = messaging.send_each(messages)
        
        # Count successes and failures
        success_count = sum(1 for r in response.responses if r.success)
        failure_count = len(response.responses) - success_count
        
        print(f'✅ Sent {success_count} notifications')
        if failure_count > 0:
            print(f'⚠️ Failed to send {failure_count} notifications')
            # Log first few failures for debugging
            for idx, resp in enumerate(response.responses[:3]):
                if not resp.success:
                    print(f'   Failure {idx+1}: {resp.exception}')
        
        # Create a compatible response object
        class CompatibleResponse:
            def __init__(self, responses):
                self.responses = responses
                self.success_count = sum(1 for r in responses if r.success)
                self.failure_count = len(responses) - self.success_count
        
        return CompatibleResponse(response.responses)
    except Exception as e:
        print(f'❌ Error sending multicast notification: {e}')
        print(f'   Title: {title}')
        print(f'   Token count: {len(fcm_tokens)}')
        import traceback
        traceback.print_exc()
        return None


def send_message_notification(recipient_user, sender_user, sender_name, message_text, chat_id):
    """
    Send notification when user receives a new message
    
    Args:
        recipient_user: User object who will receive the notification
        sender_user: User object who sent the message
        sender_name (str): Name of the message sender
        message_text (str): The message content
        chat_id (str): ID of the chat
    """
    from .models import FCMToken
    
    print(f'📨 send_message_notification called')
    print(f'   Recipient: {recipient_user.email}')
    print(f'   Sender: {sender_name} (ID: {sender_user.id})')
    print(f'   Chat ID: {chat_id}')
    
    # Get user's active FCM tokens
    fcm_tokens = FCMToken.objects.filter(
        user=recipient_user,
        is_active=True
    ).values_list('token', flat=True)
    
    token_count = len(fcm_tokens)
    print(f'   Found {token_count} active FCM tokens')
    
    if not fcm_tokens:
        print(f'   ⚠️ No FCM tokens found for user: {recipient_user.email}')
        return
    
    # Truncate long messages
    truncated_message = message_text[:100] + '...' if len(message_text) > 100 else message_text
    
    # Send notification to each token
    success_count = 0
    for token in fcm_tokens:
        print(f'   Sending to token: {token[:50]}...')
        result = send_fcm_notification(
            fcm_token=token,
            title=f'New message from {sender_name}',
            body=truncated_message,
            data={
                'type': 'message',
                'sender_name': sender_name,
                'sender_id': str(sender_user.id),
                'chat_id': str(chat_id),
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            }
        )
        if result:
            success_count += 1
    
    print(f'   ✅ Successfully sent {success_count}/{token_count} notifications')


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
