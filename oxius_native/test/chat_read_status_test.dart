import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:oxius_native/widgets/chat/chat_message_bubble.dart';

/// The read state has to survive a rebuild.
///
/// It used to live inside the smart-timestamp row, which only appears on the
/// first message or after a 3-minute gap — so the tick showed the moment you
/// sent (the optimistic entry forces a timestamp) and then vanished as soon
/// as the thread was rebuilt from the server. These tests pin the new
/// contract: the newest outgoing message carries the status, always.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Map<String, dynamic> msg({
    required bool isMe,
    bool seen = false,
    bool showStatus = false,
    bool showTimestamp = false,
    bool pending = false,
  }) =>
      {
        'id': 'm${isMe}_${seen}_$showStatus',
        'message': 'hello',
        'type': 'text',
        'timestamp': DateTime(2026, 1, 1, 10),
        'timeDisplay': '10:00 AM',
        'isMe': isMe,
        'isSeen': seen,
        'showStatus': showStatus,
        'showTimestamp': showTimestamp,
        if (pending) 'pending': true,
        'reactions': const [],
      };

  Future<void> pump(WidgetTester tester, Map<String, dynamic> m) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatMessageBubble(
          message: m,
          showAvatar: false,
          userName: 'Rahim',
          voicePosition: Duration.zero,
          voiceDuration: Duration.zero,
          onReply: (_) {},
          onPlayVoice: (_, __) {},
          onViewImage: (_) {},
          onDownloadDoc: (_, __) {},
          onScrollToMessage: (_) {},
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('newest outgoing message keeps its double tick after a rebuild',
      (tester) async {
    // No timestamp row at all — this is the post-reload shape that used to
    // render nothing.
    await pump(tester, msg(isMe: true, seen: true, showStatus: true));
    // Icon only — no words. The double tick IS the "seen" signal.
    expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);
    expect(find.text('সিন'), findsNothing);
    // The time is not printed when only the status asked for the row.
    expect(find.text('10:00 AM'), findsNothing);
  });

  testWidgets('delivered-but-unread shows a single tick', (tester) async {
    await pump(tester, msg(isMe: true, seen: false, showStatus: true));
    expect(find.byIcon(Icons.done_rounded), findsOneWidget);
    expect(find.text('পাঠানো হয়েছে'), findsNothing);
  });

  testWidgets('older outgoing messages carry no status row', (tester) async {
    await pump(tester, msg(isMe: true, seen: true, showStatus: false));
    expect(find.byIcon(Icons.done_all_rounded), findsNothing);
    expect(find.byIcon(Icons.done_rounded), findsNothing);
  });

  testWidgets('a message still sending shows a clock, not a verdict',
      (tester) async {
    await pump(
        tester, msg(isMe: true, showStatus: true, pending: true));
    expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
  });

  testWidgets('an older message reveals its tick when tapped open',
      (tester) async {
    final m = msg(isMe: true, seen: true, showStatus: false)
      ..['showTimestamp'] = true
      ..['timeRevealAnimated'] = true;
    await pump(tester, m);
    expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);
  });

  testWidgets('incoming messages never show a status', (tester) async {
    await pump(tester, msg(isMe: false, seen: true, showStatus: true));
    expect(find.byIcon(Icons.done_all_rounded), findsNothing);
  });

  testWidgets('the timestamp still prints when the gap rule asks for it',
      (tester) async {
    await pump(
        tester,
        msg(isMe: true, seen: true, showStatus: true, showTimestamp: true));
    expect(find.text('10:00 AM'), findsOneWidget);
    expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);
  });
}
