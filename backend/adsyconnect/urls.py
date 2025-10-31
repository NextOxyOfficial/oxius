from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'chatrooms', views.ChatRoomViewSet, basename='chatroom')
router.register(r'messages', views.MessageViewSet, basename='message')
router.register(r'reports', views.MessageReportViewSet, basename='report')
router.register(r'online-status', views.OnlineStatusViewSet, basename='online-status')
router.register(r'typing-status', views.TypingStatusViewSet, basename='typing-status')

urlpatterns = [
    path('', include(router.urls)),
]
