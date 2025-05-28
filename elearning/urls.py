from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views
from . import session_views

router = DefaultRouter()
router.register(r'batches', views.BatchViewSet)
router.register(r'divisions', views.DivisionViewSet)
router.register(r'subjects', views.SubjectViewSet)
router.register(r'videos', views.VideoLessonViewSet)

urlpatterns = [
    path('', include(router.urls)),
    # Session management endpoints    
        path('sessions/', include([
        path('start/', session_views.start_elearning_session, name='start_session'),
        path('end/', session_views.end_elearning_session, name='end_session'),
        path('status/', session_views.get_session_status, name='session_status'),
        path('heartbeat/', session_views.heartbeat, name='session_heartbeat'),
        path('track-activity/', session_views.update_session_activity, name='track_activity'),
        path('track-viewing-time/', session_views.track_viewing_time, name='track_viewing_time'),
        path('force-close/', session_views.force_close_sessions, name='force_close_sessions'),
    ])),
]
