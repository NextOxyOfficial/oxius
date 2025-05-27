from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'batches', views.BatchViewSet)
router.register(r'divisions', views.DivisionViewSet)
router.register(r'subjects', views.SubjectViewSet)
router.register(r'videos', views.VideoLessonViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
