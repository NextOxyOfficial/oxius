/// Deciding whether an incoming socket frame is a duplicate.
///
/// The socket can legitimately deliver the same frame twice — a reconnect
/// replays, the safety poll and the socket race each other — so the service
/// keeps a small ring of recent fingerprints and drops repeats. That makes the
/// fingerprint a load-bearing piece of logic: too loose and the user sees
/// doubles, too tight and **real events disappear**.
///
/// It lives here, as a pure function, because it was previously private inside
/// the service and therefore untestable. It was also wrong in a way no test
/// could have caught: every `bn_notification` hashed to the same constant
/// string, so a user received exactly ONE live notification per socket and the
/// bell never moved again.
library;

/// A stable key for [event], or an empty string to mean "never dedupe this".
///
/// Returning '' is a deliberate, existing idiom in this file — see the
/// reaction/edit cases below. The rule it encodes: when applying a replayed
/// event is harmless but dropping a real one is not, do not dedupe at all.
String eventFingerprint(Map<String, dynamic> event) {
  final type = event['type']?.toString() ?? '';

  // Do NOT dedupe reaction events at all. Keying on the state's CONTENT looked
  // right but reaction state legitimately repeats: react ❤️, un-react, react
  // ❤️ again produces a fingerprint identical to the first — still in the ring
  // — so the peer never saw the reaction come back. The handler just assigns
  // the server's full list, so replaying one is harmless; dropping one is not.
  if (type == 'message_reaction') {
    return '';
  }

  // Same reasoning: edit A->B->A->B makes the last event's content-keyed
  // fingerprint identical to the first's, still inside the ring — and the peer
  // misses the final state. Applying a replayed edit/delete is a harmless
  // idempotent merge; dropping a real one is not.
  if (type == 'message_edited' || type == 'message_deleted') {
    return '';
  }

  // Business Network notifications and group updates carry their identifier
  // NESTED — under `notification` and `group` respectively — so none of the
  // top-level lookups below could ever find one. Every such frame collapsed to
  // the same constant string ("bn_notification|||||||"), the ring swallowed
  // the second and all subsequent ones, and because a hit does not refresh the
  // ring entry it never aged out either. Symptom: the bell moved once, then
  // never again until the socket reconnected; and every group rename, removal
  // and deletion after the first was silently discarded.
  //
  // Prefer the nested id when it is there, and fall back to not deduping —
  // both handlers are idempotent (one assigns a server-supplied count, the
  // other reloads or closes a screen), so a replay costs nothing and a drop
  // costs the whole feature.
  if (type == 'bn_notification') {
    final nested = event['notification'];
    final id = nested is Map ? (nested['id']?.toString() ?? '') : '';
    return id.isEmpty ? '' : '$type|$id';
  }
  if (type == 'group_updated') {
    final groupId = (event['group_id'] ??
            (event['group'] is Map ? event['group']['id'] : null))
        ?.toString() ??
        '';
    // `removed` is part of the identity: a member can be removed from a group
    // they were just updated about, and those are different events.
    return groupId.isEmpty ? '' : '$type|$groupId|${event['removed'] ?? ''}';
  }

  final eventId = event['event_id'] ?? event['id'] ?? event['message_id'];
  if (eventId != null && eventId.toString().isNotEmpty) {
    return 'id:$eventId';
  }

  if (type == 'incoming_call' || type == 'call_status') {
    return [
      type,
      event['call_id']?.toString() ?? '',
      event['channel_name']?.toString() ?? '',
      event['status']?.toString() ?? '',
      event['caller_id']?.toString() ?? event['sender_id']?.toString() ?? '',
      event['receiver_id']?.toString() ?? '',
      event['timestamp']?.toString() ?? '',
    ].join('|');
  }

  // Chat events (new_message / message_sent / edits / deletes) carry their
  // identifiers inside the nested `message` map. With only top-level fields
  // every one of them hashed to the same fingerprint, so the dedupe filter
  // swallowed all but the FIRST event — the chat list then sat frozen until a
  // manual reload. Hash the message id (+ content state, so edits and
  // soft-deletes of the same message still get through).
  final message = event['message'];
  if (message is Map) {
    final mid = message['id']?.toString() ?? '';
    if (mid.isNotEmpty) {
      return '$type|msg:$mid'
          '|${message['is_deleted'] ?? ''}'
          '|${(message['content'] ?? '').hashCode}'
          '|${message['is_read'] ?? ''}';
    }
  }

  // Status-style events flip a boolean (typing on/off, online/offline) with no
  // timestamp — include the state itself so the "off" event isn't treated as a
  // duplicate of the earlier "on".
  return [
    type,
    event['chatroom_id'] ?? '',
    event['user_id'] ?? '',
    event['message_id'] ?? '',
    event['is_typing'] ?? '',
    event['is_online'] ?? '',
    event['status'] ?? '',
    event['timestamp'] ?? event['created_at'] ?? '',
  ].join('|');
}
