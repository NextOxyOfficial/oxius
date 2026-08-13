import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../l10n/tr.dart';
import '../services/api_service.dart';

/// The line under the "হাই, name" header. Cycles smoothly through a
/// backend-driven list — time-of-day wish, today's Bengali date, and any
/// custom messages the admin added — so new greetings need no app release.
///
/// GET /api/home-greetings/ -> {"items": [...]}. Falls back to a local
/// time-of-day wish while (or if) the fetch never lands.
class GreetingRotator extends StatefulWidget {
  final TextStyle style;
  const GreetingRotator({super.key, required this.style});

  @override
  State<GreetingRotator> createState() => _GreetingRotatorState();
}

class _GreetingRotatorState extends State<GreetingRotator> {
  List<String> _items = [];
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _items = [_localGreeting()];
    _load();
  }

  static String _localGreeting() {
    // Mirrors the backend boundaries (বিকেল 4-7pm, সন্ধ্যা 7-8pm).
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return tr('শুভ সকাল ☀️');
    if (h >= 12 && h < 16) return tr('শুভ দুপুর 🌤️');
    if (h >= 16 && h < 19) return tr('শুভ বিকেল 🌇');
    if (h >= 19 && h < 20) return tr('শুভ সন্ধ্যা 🌆');
    return tr('শুভ রাত্রি 🌙');
  }

  /// What may actually be shown for the current language.
  ///
  /// The backend sends this list in Bengali — a time-of-day wish, today's date
  /// on the Bangla calendar, and whatever the admin typed — and the endpoint
  /// takes no language parameter. Rendering it verbatim is why the very first
  /// line of the home screen stayed Bengali with English selected, which is
  /// what App Store review screenshotted.
  ///
  /// Known phrases translate through the dictionary. Anything still carrying
  /// Bengali afterwards — a Bangla-calendar date, a new admin message — is
  /// dropped rather than shown, and if that empties the list the local English
  /// greeting stands in. Bengali mode keeps every item untouched.
  List<String> get _visibleItems {
    if (trIsBengali) return _items;
    final out = <String>[];
    for (final raw in _items) {
      final t = trBn(raw);
      if (!untranslatedBengali(t)) out.add(t);
    }
    return out.isEmpty ? [_localGreeting()] : out;
  }

  Future<void> _load() async {
    try {
      final res = await ApiService.client
          .get(Uri.parse('${ApiService.baseUrl}/home-greetings/'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200 || !mounted) return;
      final data = json.decode(res.body);
      final list = (data is Map ? data['items'] : null);
      if (list is List) {
        final items = [
          for (final e in list)
            if (e != null && e.toString().trim().isNotEmpty) e.toString()
        ];
        if (items.isNotEmpty) {
          setState(() {
            _items = items;
            if (_index >= _items.length) _index = 0;
          });
          _startRotation();
        }
      }
    } catch (_) {
      // Keep the local greeting on any failure.
    }
  }

  void _startRotation() {
    _timer?.cancel();
    // Rotate over what is actually showable: in English mode the backend list
    // can collapse to a single item once the Bengali-only ones are dropped,
    // and a one-item rotation is just a flicker.
    if (_visibleItems.length < 2) return;
    _timer = Timer.periodic(const Duration(milliseconds: 3600), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _visibleItems.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _visibleItems;
    // _index is driven by a timer that may outlive a language change, so clamp
    // rather than trusting it against a list that just got shorter.
    final text = items.isEmpty
        ? _localGreeting()
        : items[_index % items.length];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) {
        // Slide up + fade — one line replaces the other cleanly.
        final offset = Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(anim);
        return ClipRect(
          child: SlideTransition(
            position: offset,
            child: FadeTransition(opacity: anim, child: child),
          ),
        );
      },
      child: Text(
        text,
        key: ValueKey(text),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: widget.style,
      ),
    );
  }
}
