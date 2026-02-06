"""
URL configuration for backend project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.1/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""

from django.contrib import admin
from django.conf import settings
from django.conf.urls.static import static
from django.urls import path, include, re_path
from django.contrib.staticfiles.urls import staticfiles_urlpatterns
from base.views import index, assetlinks_json

# First set up the media files
urlpatterns = static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

# Then add the actual URL patterns
urlpatterns = urlpatterns + [
    path("admin/", admin.site.urls),
    path("tinymce/", include("tinymce.urls")),
    path("api/", include("base.urls")),
    path("api/geo/", include("cities.urls")),
    path("api/", include("mobile_recharge.urls")),
    path("api/", include("subscription.urls")),
    path("api/sale/", include("sale.urls")),  # Add the sale app URLs here
    path("api/bn/", include("business_network.urls")),
    path("api/news/", include("news.urls")),
    path(
        "api/",
        # Support ticket system URLs
        include("support.urls"),
    ),
    path("api/reviews/", include("reviews.urls")),  # Reviews system URLs
    path("api/elearning/", include("elearning.urls")),  # eLearning system URLs
    # global_popup system URLs
    path("api/global-popup/", include("global_popup.urls")),
    # AdsyConnect chat system URLs
    path("api/adsyconnect/", include("adsyconnect.urls")),
    # Workspace gigs system URLs
    path("api/workspace/", include("workspace.urls")),
    # Referral rewards system URLs
    path("api/referral-rewards/", include("referral_rewards.urls")),
    # Raise Up crowdfunding system URLs
    path("api/raise-up/", include("raise_up.urls")),
    # Android App Links - Digital Asset Links verification
    path(".well-known/assetlinks.json", assetlinks_json, name="assetlinks"),
    # for frontend
    path("", index, name="index"),
    path("<str:param>", index, name="index2"),
    path("<str:param>/", index, name="index2"),
    path("<str:param>/<str:param2>", index, name="index2"),
    path("<str:param>/<str:param2>/", index, name="index2"),
    path("<str:param>/<str:param2>/<str:param3>", index, name="index2"),
    path("<str:param>/<str:param2>/<str:param3>/", index, name="index2"),
    path("<str:param>/<str:param2>/<str:param3>/<str:param4>", index, name="index2"),
    path("<str:param>/<str:param2>/<str:param3>/<str:param4>/", index, name="index2"),
]

# Add static file handling in development
if settings.DEBUG:
    urlpatterns += staticfiles_urlpatterns()
