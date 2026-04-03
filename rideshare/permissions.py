from rest_framework.permissions import BasePermission

from .models import DriverProfile


class IsApprovedDriver(BasePermission):
    message = "You must be an approved driver to perform this action."

    def has_permission(self, request, view):
        user = getattr(request, "user", None)
        if not user or not user.is_authenticated:
            return False
        # Use EXISTS check to avoid selecting every DriverProfile column.
        return DriverProfile.objects.filter(
            user_id=user.id,
            approval_status="approved",
        ).exists()


class IsRideParticipant(BasePermission):
    message = "You do not have permission to access this ride."

    def has_object_permission(self, request, view, obj):
        user = getattr(request, "user", None)
        if not user or not user.is_authenticated:
            return False

        if getattr(user, "is_superuser", False):
            return True

        return obj.rider_id == user.id or getattr(obj.assigned_driver, "user_id", None) == user.id
