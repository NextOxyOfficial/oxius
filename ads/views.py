"""Public ad-config endpoint the app fetches on startup.

GET /api/ads/config/   -> master switch, SDK key, brand-safety rating, and the
                          enabled placements (with platform ad-unit ids).

The app dropped AdMob in Aug 2026 (publisher account terminated for invalid
traffic), so the ONLY field it reads now is `placements[key].frequency` — how
often a house ad repeats in a feed. `enabled`, `sdk_key`, `test_mode`,
`content_rating` and the ad-unit ids are kept because older installs still
parse them; nothing in the current app looks at them.

Note the asymmetry that keeps house ads safe: a placement that is missing from
the map is treated by the app as ON (a config outage must never blank out our
own inventory), and only a literal `false` turns a slot off — which this view
never emits today. If per-slot control of HOUSE ads is ever wanted, add a
separate field for it; do not repurpose `AdPlacement.enabled`, which is off
across the board from the AdMob era and would silently kill the whole feed.
"""
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

from .models import AdPlacement, AdSettings


@api_view(["GET"])
@permission_classes([AllowAny])
def ads_config(request):
    s = AdSettings.get()
    if not s.enabled:
        # Master switch off → app shows zero ads.
        return Response({"enabled": False, "placements": {}})

    placements = {}
    for p in AdPlacement.objects.filter(enabled=True):
        placements[p.key] = {
            "network": p.network,
            "format": p.ad_format,
            "ad_unit_id_android": p.ad_unit_id_android,
            "ad_unit_id_ios": p.ad_unit_id_ios,
            "frequency": p.frequency,
            "min_app_version": p.min_app_version,
        }

    return Response({
        "enabled": True,
        "sdk_key": s.applovin_sdk_key,
        "test_mode": s.test_mode,
        "content_rating": s.max_ad_content_rating,
        "placements": placements,
    })
