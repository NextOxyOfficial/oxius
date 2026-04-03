from celery import shared_task
import logging

from .services import NearestDriverDispatch, RideAutoCancel

logger = logging.getLogger(__name__)


@shared_task
def cascade_expired_ride_targets():
    """
    Celery task to check for rides where targeted driver didn't respond within 1 minute
    and cascade to the next nearest driver.
    
    Runs every 30 seconds.
    """
    try:
        cascaded_count = NearestDriverDispatch.check_and_cascade_expired_targets()
        if cascaded_count > 0:
            logger.info(f"Cascaded {cascaded_count} ride(s) to next nearest driver")
        return cascaded_count
    except Exception as e:
        logger.exception(f"Error in cascade_expired_ride_targets task: {e}")
        return 0


@shared_task
def cancel_expired_rides():
    """
    Celery task to auto-cancel rides that have been searching for more than 15 minutes
    without finding a driver.
    
    Runs every 2 minutes.
    """
    try:
        cancelled_count = RideAutoCancel.check_and_cancel_expired_rides()
        if cancelled_count > 0:
            logger.info(f"Auto-cancelled {cancelled_count} expired ride(s)")
        return cancelled_count
    except Exception as e:
        logger.exception(f"Error in cancel_expired_rides task: {e}")
        return 0


@shared_task
def mark_stale_drivers_offline():
    """Mark drivers offline when their device has been silent beyond the stale threshold.

    Runs every 2 minutes. Catches drivers whose app was killed or lost connectivity
    without explicitly calling the toggle-offline endpoint.
    """
    try:
        count = NearestDriverDispatch.mark_stale_drivers_offline()
        if count > 0:
            logger.info(f"Marked {count} stale driver(s) offline")
        return count
    except Exception as e:
        logger.exception(f"Error in mark_stale_drivers_offline task: {e}")
        return 0
