// TEMPORARY DEBUG PROBE — delete after the shorts null->bool hunt.
// Boots straight into the BN shorts Discover reel with real API data so the
// crash surfaces in the `flutter run` console without manual navigation.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'models/business_network_models.dart';
import 'services/business_network_service.dart';
import 'screens/business_network/shorts_viewer.dart';

void main() {
  FlutterError.onError = (details) {
    debugPrint('PROBE-FLUTTER-ERROR: ${details.exception}');
    debugPrint('PROBE-STACK: ${details.stack}');
  };
  runApp(const _ProbeApp());
}

class _ProbeApp extends StatelessWidget {
  const _ProbeApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _ProbeHome(),
    );
  }
}

class _ProbeHome extends StatefulWidget {
  const _ProbeHome();

  @override
  State<_ProbeHome> createState() => _ProbeHomeState();
}

class _ProbeHomeState extends State<_ProbeHome> {
  List<BusinessNetworkPost>? _posts;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await BusinessNetworkService.getShortsFeed(
        startPage: 1,
        pageSize: 12,
        pageWindow: 2,
      );
      final posts = (result['posts'] as List<BusinessNetworkPost>?) ?? [];
      debugPrint('PROBE: loaded ${posts.length} shorts posts');
      // Also exercise the sponsored-boost path directly: fetch each post by
      // identifier (the single-post endpoint) like _SponsoredShortPage does.
      for (final p in posts.take(3)) {
        final ident = p.slug.isNotEmpty ? p.slug : p.id.toString();
        final detail = await BusinessNetworkService.getPostByIdentifier(ident);
        debugPrint(
            'PROBE: getPostByIdentifier($ident) -> ${detail == null ? 'NULL' : 'ok id=${detail.id} media=${detail.media.length}'}');
      }
      if (!mounted) return;
      setState(() => _posts = posts);
    } catch (e, st) {
      debugPrint('PROBE-LOAD-ERROR: $e');
      debugPrint('PROBE-LOAD-STACK: $st');
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final posts = _posts;
    if (_error != null) {
      return Scaffold(body: Center(child: Text('load error: $_error')));
    }
    if (posts == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: ShortsViewer(
        posts: posts,
        onClose: () {},
      ),
    );
  }
}
