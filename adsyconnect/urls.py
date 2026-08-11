from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .reactions import (
    group_message_reactors,
    message_reactors,
    react_to_group_message,
    react_to_message,
)
from .views import (
    ChatRoomViewSet, MessageViewSet, MessageReportViewSet,
    BlockedUserViewSet, OnlineStatusViewSet, TypingStatusViewSet,
    ChatGroupViewSet,
    agora_rtc_token, agora_config, call_media_connected, firebase_custom_token, send_call_notification, send_call_status,
    call_config, livekit_token, invite_to_call, start_group_call,
    group_active_call, join_group_call,
    set_active_chat, clear_active_chat, heartbeat)

router = DefaultRouter()
router.register(r'chatrooms', ChatRoomViewSet, basename='chatroom')
router.register(r'groups', ChatGroupViewSet, basename='chat-group')
router.register(r'messages', MessageViewSet, basename='message')
router.register(r'reports', MessageReportViewSet, basename='report')
router.register(r'blocked-users', BlockedUserViewSet, basename='blocked-user')
router.register(r'online-status', OnlineStatusViewSet, basename='online-status')
router.register(r'typing-status', TypingStatusViewSet, basename='typing-status')

urlpatterns = [
    path('firebase-token/', firebase_custom_token, name='firebase_custom_token'),
    path('agora-config/', agora_config, name='agora_config'),
    path('agora-token/', agora_rtc_token, name='agora_rtc_token'),
    # Which engine the app should use, and a token scoped to one live call.
    path('call-config/', call_config, name='call_config'),
    path('livekit-token/', livekit_token, name='livekit_token'),
    path('call-media-connected/', call_media_connected,
         name='call_media_connected'),
    path('send-call-notification/', send_call_notification, name='send_call_notification'),
    path('send-call-status/', send_call_status, name='send_call_status'),
    # Ring more people into a call that is already running.
    path('invite-to-call/', invite_to_call, name='invite_to_call'),
    # Ring a whole group chat at once.
    path('start-group-call/', start_group_call, name='start_group_call'),
    # Walk into a call the group is already on.
    path('groups/<uuid:group_id>/active-call/', group_active_call,
         name='group_active_call'),
    path('join-group-call/', join_group_call, name='join_group_call'),
    path('set-active-chat/', set_active_chat, name='set_active_chat'),
    path('clear-active-chat/', clear_active_chat, name='clear_active_chat'),
    path('heartbeat/', heartbeat, name='heartbeat'),
    # Emoji reactions (long-press a bubble)
    path('messages/<uuid:message_id>/reactors/', message_reactors,
         name='message-reactors'),
    path('group-messages/<uuid:message_id>/reactors/', group_message_reactors,
         name='group-message-reactors'),
    path('messages/<uuid:message_id>/react/', react_to_message,
         name='react_to_message'),
    path('group-messages/<uuid:message_id>/react/', react_to_group_message,
         name='react_to_group_message'),
    path('', include(router.urls)),
]
