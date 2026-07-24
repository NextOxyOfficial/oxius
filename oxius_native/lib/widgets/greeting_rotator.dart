import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

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
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'শুভ সকাল ☀️';
    if (h >= 12 && h < 16) return 'শুভ দুপুর 🌤️';
    if (h >= 16 && h < 18) return 'শুভ বিকাল 🌇';
    if (h >= 18 && h < 20) return 'শুভ সন্ধ্যা 🌆';
    return 'শুভ রাত্রি 🌙';
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
    if (_items.length < 2) return;
    _timer = Timer.periodic(const Duration(milliseconds: 3600), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _items.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _items.isEmpty ? _localGreeting() : _items[_index];
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
