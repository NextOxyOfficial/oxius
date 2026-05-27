import re

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

from .models import AppVersionConfig


def _parse_build(value):
    try:
        return max(0, int(value))
    except (TypeError, ValueError):
        return 0


def _parse_version(value):
    parts = re.findall(r"\d+", str(value or ""))
    return tuple(int(part) for part in parts[:4]) or (0,)


def _version_lt(left, right):
    left_parts = _parse_version(left)
    right_parts = _parse_version(right)
    length = max(len(left_parts), len(right_parts))
    return left_parts + (0,) * (length - len(left_parts)) < right_parts + (0,) * (
        length - len(right_parts)
    )


def _is_outdated(current_version, current_build, target_version, target_build):
    if target_build and current_build:
        return current_build < target_build
    return _version_lt(current_version, target_version)


@api_view(["GET"])
@permission_classes([AllowAny])
def check_app_version(request):
    platform = (request.query_params.get("platform") or "").strip().lower()
    current_version = (request.query_params.get("version") or "").strip()
    current_build = _parse_build(request.query_params.get("build"))

    if platform not in {AppVersionConfig.PLATFORM_ANDROID, AppVersionConfig.PLATFORM_IOS}:
        return Response(
            {
                "update_available": False,
                "force_update": False,
                "error": "platform must be android or ios",
            },
            status=400,
        )

    config = (
        AppVersionConfig.objects.filter(platform=platform, is_active=True)
        .order_by("-latest_build", "-updated_at")
        .first()
    )
    if not config:
        return Response(
            {
                "update_available": False,
                "force_update": False,
                "platform": platform,
            }
        )

    update_available = _is_outdated(
        current_version,
        current_build,
        config.latest_version,
        config.latest_build,
    )
    below_minimum = False
    if config.minimum_supported_version or config.minimum_supported_build:
        below_minimum = _is_outdated(
            current_version,
            current_build,
            config.minimum_supported_version or config.latest_version,
            config.minimum_supported_build,
        )

    force_update = bool(update_available and (config.force_update or below_minimum))

    return Response(
        {
            "update_available": update_available,
            "force_update": force_update,
            "platform": platform,
            "latest_version": config.latest_version,
            "latest_build": config.latest_build,
            "minimum_supported_version": config.minimum_supported_version,
            "minimum_supported_build": config.minimum_supported_build,
            "store_url": config.store_url,
            "title": config.title,
            "message": config.message,
            "snooze_hours": config.snooze_hours,
        }
    )
