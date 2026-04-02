import json

from channels.db import database_sync_to_async
from channels.generic.websocket import AsyncJsonWebsocketConsumer

from .models import DriverProfile, Ride
from .services import DriverLocationService


class RideTrackingConsumer(AsyncJsonWebsocketConsumer):
    async def connect(self):
        self.ride_id = self.scope["url_route"]["kwargs"]["ride_id"]
        self.ride_group_name = f"ride_{self.ride_id}"
        user = self.scope.get("user")

        if not user or user.is_anonymous:
            await self.close(code=4001)
            return

        ride = await self._get_ride()
        if not ride:
            await self.close(code=4004)
            return

        allowed = (
            ride.rider_id == user.id
            or (ride.assigned_driver_id and ride.assigned_driver.user_id == user.id)
            or user.is_superuser
        )
        if not allowed:
            await self.close(code=4003)
            return

        await self.channel_layer.group_add(self.ride_group_name, self.channel_name)
        await self.accept()
        await self.send_json(
            {"type": "connection.established", "ride_id": self.ride_id}
        )

    async def disconnect(self, code):
        await self.channel_layer.group_discard(self.ride_group_name, self.channel_name)

    async def receive_json(self, content, **kwargs):
        user = self.scope.get("user")
        event = content.get("event")
        if event == "ping":
            await self.send_json({"type": "pong"})
            return

        if event == "location.update":
            ride = await self._get_ride()
            if (
                not ride
                or not ride.assigned_driver_id
                or ride.assigned_driver.user_id != user.id
            ):
                await self.send_json(
                    {
                        "type": "error",
                        "message": "Only the assigned driver can send location updates.",
                    }
                )
                return

            location = await self._save_location(content)
            await self.send_json(
                {
                    "type": "ack",
                    "event": "location.update",
                    "location_id": str(location.id),
                }
            )

        if event == "passenger.location":
            ride = await self._get_ride()
            if not ride or ride.rider_id != user.id:
                await self.send_json(
                    {
                        "type": "error",
                        "message": "Only the passenger can send passenger location.",
                    }
                )
                return

            await self.channel_layer.group_send(
                self.ride_group_name,
                {
                    "type": "passenger.location",
                    "ride_id": str(ride.id),
                    "latitude": str(content.get("latitude", "")),
                    "longitude": str(content.get("longitude", "")),
                    "heading": content.get("heading"),
                    "accuracy_meters": content.get("accuracy_meters"),
                },
            )

    async def ride_event(self, event):
        await self.send_json(event)

    async def driver_location(self, event):
        await self.send_json(event)

    async def passenger_location(self, event):
        await self.send_json(event)

    async def ride_request(self, event):
        await self.send_json(event)

    async def _get_ride(self):
        from channels.db import database_sync_to_async

        @database_sync_to_async
        def _fetch():
            try:
                return Ride.objects.select_related(
                    "rider", "assigned_driver__user"
                ).get(id=self.ride_id)
            except Ride.DoesNotExist:
                return None

        return await _fetch()

    async def _save_location(self, payload):
        from channels.db import database_sync_to_async

        @database_sync_to_async
        def _store():
            ride = Ride.objects.select_related("assigned_driver__user").get(
                id=self.ride_id
            )
            return DriverLocationService.update_location(
                driver_profile=ride.assigned_driver,
                latitude=payload.get("latitude"),
                longitude=payload.get("longitude"),
                ride=ride,
                heading=payload.get("heading"),
                speed_kph=payload.get("speed_kph"),
                accuracy_meters=payload.get("accuracy_meters"),
            )

        return await _store()


class DriverDispatchConsumer(AsyncJsonWebsocketConsumer):
    async def connect(self):
        user = self.scope.get("user")
        if not user or user.is_anonymous:
            await self.close(code=4001)
            return

        driver_profile = await self._get_driver_profile()
        if (
            not driver_profile
            or driver_profile.approval_status != "approved"
            or not driver_profile.is_online
        ):
            await self.close(code=4003)
            return

        self.driver_group_name = f"driver_{user.id}"
        await self.channel_layer.group_add("drivers_online", self.channel_name)
        await self.channel_layer.group_add(self.driver_group_name, self.channel_name)
        await self.accept()
        await self.send_json(
            {"type": "connection.established", "driver_id": str(user.id)}
        )

    async def disconnect(self, code):
        await self.channel_layer.group_discard("drivers_online", self.channel_name)
        if hasattr(self, "driver_group_name"):
            await self.channel_layer.group_discard(
                self.driver_group_name, self.channel_name
            )

    async def receive_json(self, content, **kwargs):
        event = content.get("event")
        if event == "ping":
            await self.send_json({"type": "pong"})

    async def ride_request(self, event):
        await self.send_json(event)

    async def ride_targeted(self, event):
        await self.send_json(event)

    async def ride_event(self, event):
        await self.send_json(event)

    async def _get_driver_profile(self):
        @database_sync_to_async
        def _fetch():
            return DriverProfile.objects.filter(user=self.scope.get("user")).first()

        return await _fetch()
