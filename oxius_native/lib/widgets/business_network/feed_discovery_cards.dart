import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../services/microgig_service.dart';
import '../../services/news_service.dart';
import '../../services/workspace_service.dart';
import '../../models/microgig_models.dart';
import '../../models/news_models.dart';
import '../../config/app_config.dart';
import '../../screens/gig_details_screen.dart';
import '../../screens/news_detail_screen.dart';
import '../../screens/micro_gigs_screen.dart';
import '../../screens/workspace/gig_detail_screen.dart';
import '../../screens/workspace/workspace_screen.dart';

/// One tile inside a discovery row.
class FeedDiscoveryItem {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? badge;
  final VoidCallback onTap;

  const FeedDiscoveryItem({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.imageUrl,
    this.badge,
  });
}

/// Reusable horizontal "discovery" section shown between feed posts
/// (micro gigs / news / workspace gigs). Mirrors the sponsored-products look.
/// Deliberately restrained: neutral bordered surfaces, accent used only for
/// the icon and links — no gradient fills.
class FeedDiscoveryCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final VoidCallback onSeeAll;
  final List<FeedDiscoveryItem> items;

  const FeedDiscoveryCard({
    super.key,
    required this.icon,
    required this.accent,
    required this.title,
    required this.onSeeAll,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDF0F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 10, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 15, color: accent),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onSeeAll,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    child: Row(
                      children: [
                        Text('সব দেখুন',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: accent)),
                        Icon(Icons.chevron_right_rounded, size: 16, color: accent),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Horizontal tiles
          SizedBox(
            height: 176,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) => _tile(items[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(FeedDiscoveryItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 150,
                height: 100,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: 320,
                        placeholder: (c, u) =>
                            Container(color: const Color(0xFFF1F5F9)),
                        errorWidget: (c, u, e) => _iconTile(),
                      )
                    else
                      _iconTile(),
                    if (item.badge != null)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.62),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item.badge!,
                            style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
                height: 1.25,
              ),
            ),
            if (item.subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                item.subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: accent),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _iconTile() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Center(
          child: Icon(Icons.image_outlined, size: 28, color: Color(0xFF94A3B8))),
    );
  }
}

/// A per-type in-memory cache so the same data isn't re-fetched for every slot
/// or every scroll — fetched once, reused across the whole feed session.
class _DiscoveryStore<T> {
  List<T>? data;
  Future<List<T>>? inFlight;

  Future<List<T>> load(Future<List<T>> Function() fetcher) {
    if (data != null) return Future.value(data);
    inFlight ??= fetcher().then((v) {
      data = v;
      return v;
    }).catchError((_) {
      inFlight = null;
      return <T>[];
    });
    return inFlight!;
  }
}

// ── Micro gigs ──────────────────────────────────────────────────────────────
final _microStore = _DiscoveryStore<MicroGig>();

class FeedMicroGigsCard extends StatefulWidget {
  const FeedMicroGigsCard({super.key});
  @override
  State<FeedMicroGigsCard> createState() => _FeedMicroGigsCardState();
}

class _FeedMicroGigsCardState extends State<FeedMicroGigsCard> {
  List<MicroGig> _gigs = const [];

  @override
  void initState() {
    super.initState();
    _microStore
        .load(() => MicrogigService.getMicroGigs(showSubmitted: false))
        .then((v) {
      if (mounted) {
        setState(() => _gigs =
            v.where((g) => g.isAvailable).take(8).toList());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_gigs.isEmpty) return const SizedBox.shrink();
    return FeedDiscoveryCard(
      icon: Icons.bolt_rounded,
      accent: const Color(0xFF6366F1),
      title: 'নতুন গিগস — সহজে ইনকাম',
      onSeeAll: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const MicroGigsScreen())),
      items: _gigs
          .map((g) => FeedDiscoveryItem(
                title: g.title,
                subtitle: '৳${g.price.toStringAsFixed(0)} • কাজ প্রতি',
                badge: '${g.remainingSlots} স্লট বাকি',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            GigDetailsScreen(gigSlug: g.slug))),
              ))
          .toList(),
    );
  }
}

// ── News ────────────────────────────────────────────────────────────────────
final _newsStore = _DiscoveryStore<NewsPost>();

/// One news story rendered like a regular feed post (full-width image, title
/// underneath, "আরো পড়ুন") so it blends into the scroll instead of reading
/// as a promo carousel. Each feed slot shows a different story via [index].
class FeedNewsCard extends StatefulWidget {
  final int index;
  const FeedNewsCard({super.key, this.index = 0});
  @override
  State<FeedNewsCard> createState() => _FeedNewsCardState();
}

class _FeedNewsCardState extends State<FeedNewsCard> {
  List<NewsPost> _posts = const [];

  @override
  void initState() {
    super.initState();
    _newsStore.load(() async {
      final res = await NewsService.getPosts(page: 1);
      return res.results;
    }).then((v) {
      if (mounted) setState(() => _posts = v.take(10).toList());
    });
  }

  String _img(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    return raw.startsWith('http') ? raw : '${AppConfig.mediaBaseUrl}$raw';
  }

  static const _accent = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    if (_posts.isEmpty) return const SizedBox.shrink();
    final post = _posts[widget.index % _posts.length];
    final img = _img(post.image);

    void openStory() => Navigator.push(context,
        MaterialPageRoute(builder: (_) => NewsDetailScreen(slug: post.slug)));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDF0F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — same anatomy as a post header, branded as news.
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.newspaper_rounded,
                      size: 15, color: _accent),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'এডসি নিউজ',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/adsy-news'),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      children: [
                        Text('সব খবর',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _accent)),
                        Icon(Icons.chevron_right_rounded,
                            size: 16, color: _accent),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Full-width image like a post's media.
          if (img.isNotEmpty)
            GestureDetector(
              onTap: openStory,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: img,
                  fit: BoxFit.cover,
                  memCacheWidth: 1080,
                  placeholder: (c, u) =>
                      Container(color: const Color(0xFFF1F5F9)),
                  errorWidget: (c, u, e) =>
                      Container(color: const Color(0xFFF1F5F9)),
                ),
              ),
            ),
          // Title below the image, post-style.
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: GestureDetector(
              onTap: openStory,
              child: Text(
                post.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                  height: 1.4,
                ),
              ),
            ),
          ),
          // Read-more action.
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 12),
            child: GestureDetector(
              onTap: openStory,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'আরো পড়ুন',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _accent,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_forward_rounded, size: 15, color: _accent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Workspace gigs ──────────────────────────────────────────────────────────
final _workspaceStore = _DiscoveryStore<Map<String, dynamic>>();

class FeedWorkspaceGigsCard extends StatefulWidget {
  const FeedWorkspaceGigsCard({super.key});
  @override
  State<FeedWorkspaceGigsCard> createState() => _FeedWorkspaceGigsCardState();
}

class _FeedWorkspaceGigsCardState extends State<FeedWorkspaceGigsCard> {
  List<Map<String, dynamic>> _gigs = const [];

  @override
  void initState() {
    super.initState();
    _workspaceStore.load(() async {
      final res = await WorkspaceService().fetchGigs();
      return List<Map<String, dynamic>>.from(res['results'] ?? const []);
    }).then((v) {
      if (mounted) setState(() => _gigs = v.take(8).toList());
    });
  }

  String _img(dynamic raw) {
    final s = (raw ?? '').toString();
    if (s.isEmpty) return '';
    return s.startsWith('http') ? s : '${AppConfig.mediaBaseUrl}$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_gigs.isEmpty) return const SizedBox.shrink();
    return FeedDiscoveryCard(
      icon: Icons.work_outline_rounded,
      accent: const Color(0xFF059669),
      title: 'ওয়ার্কস্পেস গিগস',
      onSeeAll: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const WorkspaceScreen())),
      items: _gigs.map((g) {
        final price = g['price']?.toString() ?? '0';
        return FeedDiscoveryItem(
          title: (g['title'] ?? '').toString(),
          subtitle: '৳$price',
          imageUrl: _img(g['image_url'] ?? g['image']),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      GigDetailScreen(gigId: g['id'].toString()))),
        );
      }).toList(),
    );
  }
}
