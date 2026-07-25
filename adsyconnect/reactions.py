"""Emoji reactions on chat messages (long-press a bubble).

One reaction per user per message: sending a different emoji replaces it,
sending the same emoji again clears it (toggle) — the behaviour every
messenger uses.
"""
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import (
    ChatGroupMembership,
    GroupMessage,
    GroupMessageReaction,
    Message,
    MessageReaction,
)

# Keep the payload small and predictable — clients render this set.
ALLOWED_EMOJI = {"👍", "❤️", "😂", "😮", "😢", "🙏", "🔥", "😡"}


def _serialize(reactions, me_id):
    """[{emoji, count, reacted_by_me}] — enough to render the chips."""
    counts = {}
    mine = None
    for r in reactions:
        counts[r.emoji] = counts.get(r.emoji, 0) + 1
        if str(r.user_id) == str(me_id):
            mine = r.emoji
    return {
        "reactions": [
            {"emoji": e, "count": c, "reacted_by_me": e == mine}
            for e, c in sorted(counts.items(), key=lambda kv: -kv[1])
        ],
        "my_reaction": mine,
    }


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def react_to_message(request, message_id):
    """Toggle/replace the caller's reaction on a 1:1 message."""
    emoji = (request.data.get("emoji") or "").strip()
    msg = Message.objects.filter(id=message_id).select_related("chatroom").first()
    if msg is None:
        return Response({"error": "Message not found"}, status=404)
    # Only the two participants may react.
    room = msg.chatroom
    if request.user.id not in (room.user1_id, room.user2_id):
        return Response({"error": "Not a participant"}, status=403)
    if emoji and emoji not in ALLOWED_EMOJI:
        return Response({"error": "Unsupported emoji"}, status=400)

    existing = MessageReaction.objects.filter(
        message=msg, user=request.user
    ).first()
    if not emoji or (existing and existing.emoji == emoji):
        if existing:
            existing.delete()          # tap the same emoji → clear
    elif existing:
        existing.emoji = emoji         # different emoji → replace
        existing.save(update_fields=["emoji"])
    else:
        MessageReaction.objects.create(
            message=msg, user=request.user, emoji=emoji
        )

    return Response(_serialize(msg.reactions.all(), request.user.id))


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def react_to_group_message(request, message_id):
    """Toggle/replace the caller's reaction on a group message."""
    emoji = (request.data.get("emoji") or "").strip()
    msg = GroupMessage.objects.filter(id=message_id).select_related("group").first()
    if msg is None:
        return Response({"error": "Message not found"}, status=404)
    if not ChatGroupMembership.objects.filter(
        group=msg.group, user=request.user
    ).exists():
        return Response({"error": "Not a member"}, status=403)
    if emoji and emoji not in ALLOWED_EMOJI:
        return Response({"error": "Unsupported emoji"}, status=400)

    existing = GroupMessageReaction.objects.filter(
        message=msg, user=request.user
    ).first()
    if not emoji or (existing and existing.emoji == emoji):
        if existing:
            existing.delete()
    elif existing:
        existing.emoji = emoji
        existing.save(update_fields=["emoji"])
    else:
        GroupMessageReaction.objects.create(
            message=msg, user=request.user, emoji=emoji
        )

    return Response(_serialize(msg.reactions.all(), request.user.id))
