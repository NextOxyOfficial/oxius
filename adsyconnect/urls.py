from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    ChatRoomViewSet, MessageViewSet, MessageReportViewSet,
    BlockedUserViewSet, OnlineStatusViewSet, TypingStatusViewSet
)

router = DefaultRouter()
router.register(r'chatrooms', ChatRoomViewSet, basename='chatroom')
router.register(r'messages', MessageViewSet, basename='message')
router.register(r'reports', MessageReportViewSet, basename='report')
router.register(r'blocked-users', BlockedUserViewSet, basename='blocked-user')
router.register(r'online-status', OnlineStatusViewSet, basename='online-status')
router.register(r'typing-status', TypingStatusViewSet, basename='typing-status')

urlpatterns = [
    path('', include(router.urls)),
]
