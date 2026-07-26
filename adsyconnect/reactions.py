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


def _broadcast(scope, message_id, reactions, recipient_ids):
    """Push the new reaction state to everyone in the thread.

    Reactions used to reach the other person only when their poll happened to
    refetch, which read as "reactions need a reload". `user_ids` travels with
    each emoji so every client can derive its own reacted_by_me.
    """
    from .views import _broadcast_to_user

    grouped = {}
    for r in reactions:
        grouped.setdefault(r.emoji, []).append(str(r.user_id))
    payload = [
        {"emoji": e, "count": len(ids), "user_ids": ids}
        for e, ids in sorted(grouped.items(), key=lambda kv: -len(kv[1]))
    ]
    event = {
        "type": "message_reaction",
        "scope": scope,
        "message_id": str(message_id),
        "reactions": payload,
    }
    for uid in recipient_ids:
        _broadcast_to_user(uid, event)


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

    fresh = list(msg.reactions.all())
    _broadcast("direct", msg.id, fresh, [room.user1_id, room.user2_id])
    return Response(_serialize(fresh, request.user.id))


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

    fresh = list(msg.reactions.all())
    _broadcast(
        "group",
        msg.id,
        fresh,
        list(
            ChatGroupMembership.objects.filter(group=msg.group)
            .values_list("user_id", flat=True)
        ),
    )
    return Response(_serialize(fresh, request.user.id))


def _reactor_rows(reactions, request):
    """Who reacted — the rows the "tap a reaction" sheet lists.

    Kept as its own call rather than embedded in every message: the bubbles
    only need counts, and carrying every reactor in the thread payload would
    grow it for a list most people never open.
    """
    rows = []
    for r in reactions:
        u = r.user
        if u is None:
            continue
        image = ""
        try:
            if u.image:
                image = request.build_absolute_uri(u.image.url)
        except ValueError:      # file field set but storage has no url
            image = ""
        rows.append({
            "emoji": r.emoji,
            "user_id": str(u.id),
            "name": (u.name or "").strip() or u.username or "",
            "image": image,
            "is_verified": bool(u.kyc),
            "is_pro": bool(u.is_pro),
        })
    return rows


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def message_reactors(request, message_id):
    """Who reacted to a 1:1 message."""
    msg = Message.objects.filter(id=message_id).select_related("chatroom").first()
    if msg is None:
        return Response({"error": "Message not found"}, status=404)
    room = msg.chatroom
    if request.user.id not in (room.user1_id, room.user2_id):
        return Response({"error": "Not a participant"}, status=403)
    return Response({
        "reactors": _reactor_rows(
            msg.reactions.select_related("user").all(), request
        )
    })


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def group_message_reactors(request, message_id):
    """Who reacted to a group message."""
    msg = GroupMessage.objects.filter(id=message_id).select_related("group").first()
    if msg is None:
        return Response({"error": "Message not found"}, status=404)
    if not ChatGroupMembership.objects.filter(
        group=msg.group, user=request.user
    ).exists():
        return Response({"error": "Not a member"}, status=403)
    return Response({
        "reactors": _reactor_rows(
            msg.reactions.select_related("user").all(), request
        )
    })
