import firebase_admin
from firebase_admin import credentials, messaging
import os
from concurrent.futures import ThreadPoolExecutor
from django.conf import settings

# Initialize Firebase Admin SDK
FIREBASE_INITIALIZED = False
FIREBASE_ERROR = None
FCM_ASYNC_WORKERS = int(os.getenv("FCM_ASYNC_WORKERS", "4"))
_FCM_EXECUTOR = ThreadPoolExecutor(
    max_workers=max(1, FCM_ASYNC_WORKERS),
    thread_name_prefix="fcm-send",
)


def _safe_print(message):
    print(message.encode("ascii", errors="ignore").decode("ascii"))


def _token_ref(token):
    if not token or not isinstance(token, str):
        return "invalid-token"
    return f"token_len={len(token)}"

try:
    cred_path = os.path.join(settings.BASE_DIR, 'firebase-adminsdk.json')
    
    # Check if file exists
    if not os.path.exists(cred_path):
        FIREBASE_ERROR = f'Firebase credentials file not found at: {cred_path}'
        _safe_print(f'[ERROR] {FIREBASE_ERROR}')
    else:
        if not firebase_admin._apps:
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            FIREBASE_INITIALIZED = True
            _safe_print('Firebase Admin SDK initialized successfully')
            _safe_print(f'Credentials file: {cred_path}')
        else:
            FIREBASE_INITIALIZED = True
            _safe_print('Firebase Admin SDK already initialized')
except Exception as e:
    FIREBASE_ERROR = str(e)
    _safe_print(f'[ERROR] Error initializing Firebase Admin SDK: {e}')
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
        _safe_print('Cannot send notification: Firebase Admin SDK not initialized')
        if FIREBASE_ERROR:
            _safe_print(f'Error: {FIREBASE_ERROR}')
        return False
    
    try:
        # Validate token
        if not fcm_token or not isinstance(fcm_token, str):
            _safe_print(f'[ERROR] Invalid FCM token: {_token_ref(fcm_token)}')
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
            # iOS fix: apns-push-type=alert is required since iOS 13+.
            # Without it APNs may reject the message on iOS 15+ devices.
            # Also explicitly sets sound so the notification is audible.
            apns=messaging.APNSConfig(
                headers={
                    'apns-push-type': 'alert',
                    'apns-priority': '10',
                },
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(
                        sound='default',
                        mutable_content=True,
                    ),
                ),
            ),
        )
        
        response = messaging.send(message)
        _safe_print(f'Notification sent successfully: {response}')
        return True
    except messaging.UnregisteredError:
        _safe_print(f'[ERROR] Token is invalid or unregistered: {_token_ref(fcm_token)}')
        return False
    except messaging.SenderIdMismatchError:
        _safe_print(f'[ERROR] Token does not match Firebase project: {_token_ref(fcm_token)}')
        return False
    except messaging.ThirdPartyAuthError:
        _safe_print('[ERROR] APNS authentication failed for iOS FCM delivery')
        return False
    except Exception as e:
        _safe_print(f'[ERROR] Error sending notification: {e}')
        _safe_print(f'Token reference: {_token_ref(fcm_token)}')
        _safe_print(f'Title: {title}')
        import traceback
        traceback.print_exc()
        return False


def _enqueue_fcm_send(func, *args, **kwargs):
    if not FIREBASE_INITIALIZED:
        _safe_print('Cannot queue notification: Firebase Admin SDK not initialized')
        return False

    try:
        _FCM_EXECUTOR.submit(func, *args, **kwargs)
        return True
    except RuntimeError:
        return func(*args, **kwargs)


def send_fcm_notification_async(fcm_token, title, body, data=None):
    return _enqueue_fcm_send(send_fcm_notification, fcm_token, title, body, data)


def send_fcm_data_message(fcm_token, data, ttl_seconds=60):
    """
    Send a data-only FCM message (no notification field).

    Use this for payloads that the app handles itself (e.g. incoming calls,
    ride requests).  Data-only messages always trigger the background
    handler on Android regardless of app state.

    Do NOT add a `notification=...` field to the AndroidConfig — adding one
    would make Android render a system notification directly and skip the
    Dart background handler, which is what drives our CallKit + ringtone +
    ride-request UI.
    """
    if not FIREBASE_INITIALIZED:
        _safe_print('Cannot send data message: Firebase Admin SDK not initialized')
        return False

    try:
        if not fcm_token or not isinstance(fcm_token, str):
            _safe_print(f'[ERROR] Invalid FCM token: {_token_ref(fcm_token)}')
            return False

        # Ensure every value is a string (FCM data payload requirement)
        str_data = {k: str(v) if v is not None else '' for k, v in (data or {}).items()}

        import datetime as _dt
        message = messaging.Message(
            data=str_data,
            token=fcm_token,
            android=messaging.AndroidConfig(
                priority='high',
                ttl=_dt.timedelta(seconds=int(ttl_seconds)),
            ),
            # iOS fix: apns-push-type MUST be 'background' for data-only / silent pushes.
            # apns-priority MUST be 5 (not 10) for background pushes — APNs silently
            # drops priority-10 background pushes (Apple developer docs § Sending
            # Notification Requests to APNs). Without this, data-only FCM messages
            # are completely invisible to iOS devices.
            apns=messaging.APNSConfig(
                headers={
                    'apns-push-type': 'background',
                    'apns-priority': '5',
                },
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(content_available=True),
                ),
            ),
        )

        response = messaging.send(message)
        _safe_print(f'Data message sent successfully: {response}')
        return True
    except messaging.UnregisteredError:
        _safe_print(f'[ERROR] Token is invalid or unregistered: {_token_ref(fcm_token)}')
        return False
    except messaging.SenderIdMismatchError:
        _safe_print(f'[ERROR] Token does not match Firebase project: {_token_ref(fcm_token)}')
        return False
    except messaging.ThirdPartyAuthError:
        _safe_print('[ERROR] APNS authentication failed for iOS data-message delivery')
        return False
    except Exception as e:
        _safe_print(f'[ERROR] Error sending data message: {e}')
        import traceback
        traceback.print_exc()
        return False


def send_fcm_data_message_async(fcm_token, data, ttl_seconds=60):
    return _enqueue_fcm_send(send_fcm_data_message, fcm_token, data, ttl_seconds)


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
        _safe_print('Cannot send notification: Firebase Admin SDK not initialized')
        if FIREBASE_ERROR:
            _safe_print(f'Error: {FIREBASE_ERROR}')
        return None
    
    try:
        # Filter out None and empty tokens
        valid_tokens = [token for token in fcm_tokens if token and isinstance(token, str)]
        
        if not valid_tokens:
            _safe_print('[WARN] No valid FCM tokens provided')
            return None
        
        _safe_print(f'Sending multicast to {len(valid_tokens)} tokens')
        
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
                # iOS fix: same as send_fcm_notification — apns-push-type=alert
                # required since iOS 13+ or APNs may drop the message.
                apns=messaging.APNSConfig(
                    headers={
                        'apns-push-type': 'alert',
                        'apns-priority': '10',
                    },
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(
                            sound='default',
                            mutable_content=True,
                        ),
                    ),
                ),
            )
            messages.append(message)
        
        # Use send_each_for_multicast (new API in firebase-admin 7.x)
        response = messaging.send_each(messages)
        
        # Count successes and failures
        success_count = sum(1 for r in response.responses if r.success)
        failure_count = len(response.responses) - success_count
        
        _safe_print(f'Sent {success_count} notifications')
        if failure_count > 0:
            _safe_print(f'[WARN] Failed to send {failure_count} notifications')
            # Log first few failures for debugging
            for idx, resp in enumerate(response.responses[:3]):
                if not resp.success:
                    _safe_print(f'Failure {idx+1}: {resp.exception}')
        
        # Create a compatible response object
        class CompatibleResponse:
            def __init__(self, responses):
                self.responses = responses
                self.success_count = sum(1 for r in responses if r.success)
                self.failure_count = len(responses) - self.success_count
        
        return CompatibleResponse(response.responses)
    except Exception as e:
        _safe_print(f'[ERROR] Error sending multicast notification: {e}')
        _safe_print(f'Title: {title}')
        _safe_print(f'Token count: {len(fcm_tokens)}')
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
    
    _safe_print('send_message_notification called')
    _safe_print(f'Recipient: {recipient_user.email}')
    _safe_print(f'Sender: {sender_name} (ID: {sender_user.id})')
    _safe_print(f'Chat ID: {chat_id}')
    
    # Get user's active FCM tokens
    fcm_tokens = FCMToken.objects.filter(
        user=recipient_user,
        is_active=True
    ).values_list('token', flat=True)
    
    token_count = len(fcm_tokens)
    _safe_print(f'Found {token_count} active FCM tokens')
    
    if not fcm_tokens:
        _safe_print(f'[WARN] No FCM tokens found for user: {recipient_user.email}')
        return
    
    # Truncate long messages
    truncated_message = message_text[:100] + '...' if len(message_text) > 100 else message_text
    
    # Send notification to each token
    success_count = 0
    for token in fcm_tokens:
        _safe_print(f'Sending to token: {token[:50]}...')
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
