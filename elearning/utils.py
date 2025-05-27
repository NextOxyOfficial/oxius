# Utility functions for the elearning app

import logging
from django.utils import timezone
from django.db.models import F
from .models import VideoLesson

logger = logging.getLogger(__name__)

def track_video_view(video_id, user=None, session_key=None, ip_address=None):
    """
    Track a video view and increment the view count.
    
    Args:
        video_id: The ID of the VideoLesson
        user: Optional Django User object for authenticated users
        session_key: Session key for anonymous users
        ip_address: IP address of the viewer
    
    Returns:
        bool: True if view was counted, False otherwise
    """
    try:
        # Get the video
        video = VideoLesson.objects.get(pk=video_id)
        
        # Increment the view count
        video.views_count = F('views_count') + 1
        video.save(update_fields=['views_count'])
        
        # TODO: In a future enhancement, we could store more detailed view statistics:
        # - Create a VideoView model to track individual views
        # - Store user, session_key, ip_address, timestamp, watch_duration
        # - Implement rate limiting to prevent artificial view count inflation
        # - Aggregate statistics for reporting
        
        logger.info(f"View tracked for video {video_id} - User: {user.username if user else 'Anonymous'}, IP: {ip_address}")
        return True
        
    except VideoLesson.DoesNotExist:
        logger.warning(f"Attempted to track view for non-existent video: {video_id}")
        return False
    except Exception as e:
        logger.error(f"Error tracking view for video {video_id}: {str(e)}")
        return False
