from django.urls import re_path

from .consumers import DriverDispatchConsumer, RideTrackingConsumer

websocket_urlpatterns = [
    re_path(r"^ws/rides/(?P<ride_id>[0-9a-f-]+)/$", RideTrackingConsumer.as_asgi()),
    re_path(r"^ws/rides/driver/dispatch/$", DriverDispatchConsumer.as_asgi()),
]
