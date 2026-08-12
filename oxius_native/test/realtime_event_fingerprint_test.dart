// The dedupe fingerprint decides whether a socket frame is thrown away.
//
// It was previously private inside AdsyConnectRealtimeService and therefore
// untestable — and it was wrong in a way that silently disabled two whole
// features: every `bn_notification` produced the SAME constant fingerprint, so
// after the very first one the ring dropped them all and the bell never moved
// again. `group_updated` had the identical shape, so every group rename,
// removal and deletion after the first was discarded too.
import 'package:flutter_test/flutter_test.dart';
import 'package:oxius_native/services/realtime_event_fingerprint.dart';

Map<String, dynamic> bnNotification(String id, {int unread = 1}) => {
      'type': 'bn_notification',
      // The id is NESTED — this is the whole bug.
      'notification': {
        'id': id,
        'notification_type': 'like_post',
        'actor_name': 'Rahim',
      },
      'unread_count': unread,
    };

void main() {
  group('bn_notification — the blocker', () {
    test('two different notifications get different fingerprints', () {
      final first = eventFingerprint(bnNotification('n1'));
      final second = eventFingerprint(bnNotification('n2', unread: 2));
      expect(first, isNot(equals(second)),
          reason: 'identical fingerprints mean only the first is ever '
              'delivered and the bell freezes');
    });

    test('the same notification twice is recognised as a duplicate', () {
      expect(eventFingerprint(bnNotification('n1')),
          equals(eventFingerprint(bnNotification('n1'))));
    });

    test('twenty notifications produce twenty distinct fingerprints', () {
      // The original symptom: one delivered, nineteen swallowed.
      final seen = <String>{};
      for (var i = 0; i < 20; i++) {
        seen.add(eventFingerprint(bnNotification('n$i')));
      }
      expect(seen.length, 20);
    });

    test('a notification with no id is never deduped rather than collapsed',
        () {
      // Falling back to "" means "always deliver". The alternative — a shared
      // constant — is what broke it.
      final fp = eventFingerprint({
        'type': 'bn_notification',
        'notification': {'actor_name': 'Rahim'},
        'unread_count': 3,
      });
      expect(fp, isEmpty);
    });

    test('a malformed payload does not throw or collapse', () {
      expect(eventFingerprint({'type': 'bn_notification'}), isEmpty);
      expect(
          eventFingerprint(
              {'type': 'bn_notification', 'notification': 'not-a-map'}),
          isEmpty);
    });
  });

  group('group_updated — the same shape, the same bug', () {
    test('two different groups get different fingerprints', () {
      final a = eventFingerprint({
        'type': 'group_updated',
        'group': {'id': 'g1', 'name': 'A'},
      });
      final b = eventFingerprint({
        'type': 'group_updated',
        'group': {'id': 'g2', 'name': 'B'},
      });
      expect(a, isNot(equals(b)));
    });

    test('a removal is distinct from an update of the same group', () {
      // A member can be updated about a group and then removed from it; if
      // those collapsed, the removal would be dropped as a duplicate.
      final update = eventFingerprint({
        'type': 'group_updated',
        'group': {'id': 'g1', 'name': 'A'},
      });
      final removal = eventFingerprint({
        'type': 'group_updated',
        'group': {'id': 'g1', 'name': 'A'},
        'removed': true,
        'group_id': 'g1',
      });
      expect(update, isNot(equals(removal)));
    });

    test('a deletion (group == null) still fingerprints by group_id', () {
      final fp = eventFingerprint({
        'type': 'group_updated',
        'group': null,
        'removed': true,
        'group_id': 'g9',
      });
      expect(fp, contains('g9'));
      expect(fp, isNotEmpty);
    });

    test('no identifier at all means never dedupe', () {
      expect(eventFingerprint({'type': 'group_updated', 'group': null}),
          isEmpty);
    });
  });

  group('no regression in the other event types', () {
    test('new_message still keys on the nested message id', () {
      final a = eventFingerprint({
        'type': 'new_message',
        'message': {'id': 'm1', 'content': 'hi'},
      });
      final b = eventFingerprint({
        'type': 'new_message',
        'message': {'id': 'm2', 'content': 'hi'},
      });
      expect(a, isNot(equals(b)));
      expect(a, contains('msg:m1'));
    });

    test('an edit of the same message is still distinguishable', () {
      final before = eventFingerprint({
        'type': 'new_message',
        'message': {'id': 'm1', 'content': 'hi'},
      });
      final after = eventFingerprint({
        'type': 'new_message',
        'message': {'id': 'm1', 'content': 'hi, fixed'},
      });
      expect(before, isNot(equals(after)));
    });

    test('reactions and edits are still never deduped', () {
      expect(eventFingerprint({'type': 'message_reaction'}), isEmpty);
      expect(eventFingerprint({'type': 'message_edited'}), isEmpty);
      expect(eventFingerprint({'type': 'message_deleted'}), isEmpty);
    });

    test('call events still key on the call, status and timestamp', () {
      final ringing = eventFingerprint({
        'type': 'call_status',
        'call_id': 'c1',
        'status': 'ringing',
        'timestamp': '1',
      });
      final accepted = eventFingerprint({
        'type': 'call_status',
        'call_id': 'c1',
        'status': 'accepted',
        'timestamp': '2',
      });
      expect(ringing, isNot(equals(accepted)),
          reason: 'an accept must never be dropped as a duplicate ring');
    });

    test('typing on and off are distinct', () {
      final on = eventFingerprint({
        'type': 'typing_status',
        'chatroom_id': 'r1',
        'user_id': 'u1',
        'is_typing': true,
      });
      final off = eventFingerprint({
        'type': 'typing_status',
        'chatroom_id': 'r1',
        'user_id': 'u1',
        'is_typing': false,
      });
      expect(on, isNot(equals(off)));
    });

    test('presence online and offline are distinct', () {
      final online = eventFingerprint({
        'type': 'user_online_status',
        'user_id': 'u1',
        'is_online': true,
      });
      final offline = eventFingerprint({
        'type': 'user_online_status',
        'user_id': 'u1',
        'is_online': false,
      });
      expect(online, isNot(equals(offline)));
    });

    test('a top-level event_id still wins where one is supplied', () {
      expect(eventFingerprint({'type': 'anything', 'event_id': 'e1'}),
          equals('id:e1'));
    });
  });
}
