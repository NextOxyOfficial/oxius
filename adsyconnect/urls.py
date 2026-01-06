from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    ChatRoomViewSet, MessageViewSet, MessageReportViewSet,
    BlockedUserViewSet, OnlineStatusViewSet, TypingStatusViewSet,
    firebase_custom_token, send_call_notification, send_call_status,
    set_active_chat, clear_active_chat, heartbeat
)

router = DefaultRouter()
router.register(r'chatrooms', ChatRoomViewSet, basename='chatroom')
router.register(r'messages', MessageViewSet, basename='message')
router.register(r'reports', MessageReportViewSet, basename='report')
router.register(r'blocked-users', BlockedUserViewSet, basename='blocked-user')
router.register(r'online-status', OnlineStatusViewSet, basename='online-status')
router.register(r'typing-status', TypingStatusViewSet, basename='typing-status')

urlpatterns = [
    path('firebase-token/', firebase_custom_token, name='firebase_custom_token'),
    path('send-call-notification/', send_call_notification, name='send_call_notification'),
    path('send-call-status/', send_call_status, name='send_call_status'),
    path('set-active-chat/', set_active_chat, name='set_active_chat'),
    path('clear-active-chat/', clear_active_chat, name='clear_active_chat'),
    path('heartbeat/', heartbeat, name='heartbeat'),
    path('', include(router.urls)),
]
