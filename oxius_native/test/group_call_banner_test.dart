// The join banner: what it says, and when it offers a way in.
//
// The label is the whole reason the banner is worth a row of the chat —
// "Rahim and 2 others are on a call" is something you act on, "a call is
// happening" is not — so it is the part worth pinning down.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oxius_native/widgets/call/group_call_banner.dart';

void main() {
  group('groupCallBannerLabel', () {
    test('names the person and counts the rest', () {
      expect(
        groupCallBannerLabel(
            names: ['Rahim', 'Karim'], participantCount: 3, isVideo: false),
        'Rahim and 2 others on a call',
      );
    });

    test('says "other", singular, for two people', () {
      expect(
        groupCallBannerLabel(
            names: ['Rahim'], participantCount: 2, isVideo: false),
        'Rahim and 1 other on a call',
      );
    });

    test('one person on the call is just that person', () {
      expect(
        groupCallBannerLabel(
            names: ['Rahim'], participantCount: 1, isVideo: true),
        'Rahim is on a call',
      );
    });

    test('falls back to the call type when nobody is named', () {
      expect(
        groupCallBannerLabel(names: [], participantCount: 3, isVideo: true),
        'Video call in progress',
      );
      expect(
        groupCallBannerLabel(names: [], participantCount: 3, isVideo: false),
        'Audio call in progress',
      );
    });

    test('blank names count as no names, not as a person', () {
      expect(
        groupCallBannerLabel(
            names: ['', '   '], participantCount: 2, isVideo: false),
        'Audio call in progress',
      );
    });

    test('a count that lags behind the names never reads as negative', () {
      // participant_count and participants come from one response, but a
      // count of 0 with a name in the list must still read as a sentence.
      expect(
        groupCallBannerLabel(
            names: ['Rahim'], participantCount: 0, isVideo: false),
        'Rahim is on a call',
      );
    });
  });

  group('GroupCallJoinBanner', () {
    Future<void> pump(WidgetTester tester, Map<String, dynamic>? call,
        {bool joining = false, VoidCallback? onJoin}) {
      return tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GroupCallJoinBanner(
            call: call,
            joining: joining,
            onJoin: onJoin ?? () {},
          ),
        ),
      ));
    }

    Map<String, dynamic> callOf({bool full = false, String type = 'audio'}) => {
          'call_id': 'c1',
          'channel_name': 'c_join_1',
          'call_type': type,
          'participant_count': 2,
          'participants': [
            {'id': '1', 'name': 'Rahim'},
          ],
          'is_full': full,
        };

    testWidgets('no call, no banner', (tester) async {
      await pump(tester, null);
      expect(find.text('Join'), findsNothing);
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('offers a way in and reports the tap', (tester) async {
      var tapped = 0;
      await pump(tester, callOf(), onJoin: () => tapped++);

      expect(find.text('Rahim and 1 other on a call'), findsOneWidget);
      await tester.tap(find.text('Join'));
      expect(tapped, 1);
    });

    testWidgets('a full call offers nothing to tap', (tester) async {
      var tapped = 0;
      await pump(tester, callOf(full: true), onJoin: () => tapped++);

      expect(find.text('Call is full'), findsOneWidget);
      expect(find.text('Join'), findsNothing);
      expect(tapped, 0);
    });

    testWidgets('the button cannot be tapped twice while joining',
        (tester) async {
      var tapped = 0;
      await pump(tester, callOf(), joining: true, onJoin: () => tapped++);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(TextButton));
      expect(tapped, 0);
    });

    testWidgets('a video call says so', (tester) async {
      await pump(tester, callOf(type: 'video'));
      expect(find.byIcon(Icons.videocam_rounded), findsOneWidget);
      expect(find.byIcon(Icons.call_rounded), findsNothing);
    });
  });
}
