# -*- coding: utf-8 -*-
"""The group_updated event, tested through the CONSUMER — not around it.

tests_group_updates.py patches `_broadcast_to_user` and asserts on the dict it
captured. Every one of those assertions passed while the feature was completely
broken end to end, because the consumer in between silently dropped `removed`
and `group_id` before they ever reached a socket. A test that stops at the
sender cannot see a handler that throws half the payload away.

So these drive the real path:

    channel layer group_send  ->  ChatConsumer.group_updated  ->  websocket frame

and assert on the JSON the client actually receives.
"""
import json

from channels.db import database_sync_to_async
from channels.layers import get_channel_layer
from channels.testing import WebsocketCommunicator
from django.contrib.auth import get_user_model
from django.test import TransactionTestCase, override_settings

from .consumers import ChatConsumer
from .models import ChatGroup, ChatGroupMembership

User = get_user_model()

# The real Redis layer is not available in tests and would make them depend on
# a running server; the in-memory layer speaks the same API.
TEST_LAYERS = {
    "default": {"BACKEND": "channels.layers.InMemoryChannelLayer"},
}


@override_settings(CHANNEL_LAYERS=TEST_LAYERS)
class GroupUpdatedConsumerTests(TransactionTestCase):
    """TransactionTestCase because the consumer runs in its own async context
    and would not see rows created inside an outer atomic block."""

    def setUp(self):
        self.member = User.objects.create_user(
            username="cg1", email="cg1@example.com", password="x",
            first_name="Member", phone="+880100008001")
        self.other = User.objects.create_user(
            username="cg2", email="cg2@example.com", password="x",
            first_name="Other", phone="+880100008002")
        self.group = ChatGroup.objects.create(name="Squad", creator=self.other)
        for user in (self.member, self.other):
            ChatGroupMembership.objects.create(group=self.group, user=user)

    async def _connect(self, user):
        """A connected socket for [user], exactly as routing.py wires it."""
        communicator = WebsocketCommunicator(
            ChatConsumer.as_asgi(), "/ws/chat/%s/" % user.id
        )
        communicator.scope["user"] = user
        communicator.scope["url_route"] = {"kwargs": {"user_id": str(user.id)}}
        connected, _ = await communicator.connect()
        self.assertTrue(connected, "consumer refused the connection")
        # The consumer greets with connection_ready; drain it so the next
        # receive is the event under test.
        greeting = json.loads(await communicator.receive_from())
        self.assertEqual(greeting["type"], "connection_ready")
        return communicator

    async def _send_to(self, user, payload):
        """Publish through the channel layer, the way _broadcast_to_user does."""
        layer = get_channel_layer()
        await layer.group_send("user_%s" % user.id, payload)

    # ── removal ─────────────────────────────────────────────────────────────

    async def _removal_frame(self):
        communicator = await self._connect(self.member)
        await self._send_to(self.member, {
            "type": "group_updated",
            "group": {"id": str(self.group.id), "name": "Squad"},
            "removed": True,
            "group_id": str(self.group.id),
        })
        frame = json.loads(await communicator.receive_from())
        await communicator.disconnect()
        return frame

    def test_the_removed_flag_reaches_the_client(self):
        frame = self._run(self._removal_frame())
        self.assertTrue(
            frame["removed"],
            "the consumer dropped `removed` — the client cannot tell it was "
            "removed and will leave the screen open")

    def test_the_group_id_reaches_the_client_on_removal(self):
        frame = self._run(self._removal_frame())
        self.assertEqual(frame["group_id"], str(self.group.id))

    # ── group deletion ──────────────────────────────────────────────────────

    async def _deletion_frame(self):
        communicator = await self._connect(self.member)
        # A deleted group has no body left to send — group_id is the ONLY
        # identifier, which is why dropping it discarded the event entirely.
        await self._send_to(self.member, {
            "type": "group_updated",
            "group": None,
            "removed": True,
            "group_id": str(self.group.id),
        })
        frame = json.loads(await communicator.receive_from())
        await communicator.disconnect()
        return frame

    def test_group_deletion_still_identifies_the_group(self):
        frame = self._run(self._deletion_frame())
        self.assertIsNone(frame["group"])
        self.assertTrue(frame["removed"])
        self.assertEqual(
            frame["group_id"], str(self.group.id),
            "with group=None and no group_id the client has nothing to act on")

    # ── the ordinary case must not regress ─────────────────────────────────

    async def _rename_frame(self):
        communicator = await self._connect(self.other)
        # The pre-existing senders (create, add_members) send only `group`.
        await self._send_to(self.other, {
            "type": "group_updated",
            "group": {"id": str(self.group.id), "name": "Renamed"},
        })
        frame = json.loads(await communicator.receive_from())
        await communicator.disconnect()
        return frame

    def test_a_plain_update_is_not_marked_as_a_removal(self):
        frame = self._run(self._rename_frame())
        self.assertFalse(
            frame["removed"],
            "a rename must not read as a removal — the client would close the "
            "screen on every group edit")
        self.assertEqual(frame["group"]["name"], "Renamed")

    def test_a_plain_update_still_carries_an_identifier(self):
        """Older senders omit group_id, so it falls back to the group body."""
        frame = self._run(self._rename_frame())
        self.assertEqual(frame["group_id"], str(self.group.id))

    # ── isolation ───────────────────────────────────────────────────────────

    async def _other_user_sees_nothing(self):
        listener = await self._connect(self.other)
        await self._send_to(self.member, {
            "type": "group_updated",
            "group": None,
            "removed": True,
            "group_id": str(self.group.id),
        })
        nothing = await listener.receive_nothing(timeout=0.4)
        await listener.disconnect()
        return nothing

    def test_the_removal_goes_only_to_the_person_removed(self):
        self.assertTrue(
            self._run(self._other_user_sees_nothing()),
            "a removal addressed to one member reached another member's socket")

    # ── plumbing ────────────────────────────────────────────────────────────

    def _run(self, coro):
        """Run one async scenario and leave no database connection behind.

        The consumer touches the database from inside the event loop
        (register_connection on connect, the presence fan-out on disconnect),
        and those connections belong to the loop, not to the test thread. A
        first version of this file created a loop per test and never closed
        either, so TransactionTestCase could not drop the test database at
        teardown — which then made EVERY later `manage.py test` run stop and
        ask whether to delete `test_adsyclub`, reading EOF and dying.
        """
        import asyncio

        from django.db import connections

        loop = asyncio.new_event_loop()
        try:
            return loop.run_until_complete(coro)
        finally:
            # Close connections opened inside the loop before closing the loop.
            loop.run_until_complete(
                database_sync_to_async(connections.close_all)()
            )
            loop.close()
            connections.close_all()
