import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;

import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/business_network_service.dart';
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
import '../common/adsy_share_sheet.dart';
import '../common/adsy_toast.dart';
import '../login_prompt_dialog.dart';
import 'news_comments_sheet.dart';

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

// Completed gigs live in MicrogigService.submittedGigSlugs — a global,
// cross-surface registry (feed card, gig list, details screen all report
// there) — so the card shows its "done" state no matter where the task was
// completed, without a reload.

// Bumped on pull-to-refresh; micro-gig cards listen and reload fresh gigs
// (with showSubmitted:false, so completed ones are excluded).
final ValueNotifier<int> _microGigsResetTick = ValueNotifier<int>(0);

/// Call from the feed's pull-to-refresh so completed tasks disappear and gigs
/// are refetched.
void resetMicroGigsFeed() {
  _microStore.data = null;
  _microStore.inFlight = null;
  _microGigsResetTick.value++;
}

/// One available micro gig shown as an "earn now" card between posts — only
/// when the user still has uncompleted gigs. Each feed slot rotates to the
/// next gig via [index].
class FeedMicroGigsCard extends StatefulWidget {
  final int index;
  const FeedMicroGigsCard({super.key, this.index = 0});
  @override
  State<FeedMicroGigsCard> createState() => _FeedMicroGigsCardState();
}

class _FeedMicroGigsCardState extends State<FeedMicroGigsCard> {
  List<MicroGig> _gigs = const [];

  static const _accent = Color(0xFF6366F1);

  @override
  void initState() {
    super.initState();
    _microGigsResetTick.addListener(_onFeedReset);
    // A submission made on ANY surface flips this card to its done state.
    MicrogigService.submissionTick.addListener(_onSubmissionChange);
    _loadGigs();
  }

  @override
  void dispose() {
    _microGigsResetTick.removeListener(_onFeedReset);
    MicrogigService.submissionTick.removeListener(_onSubmissionChange);
    super.dispose();
  }

  void _onSubmissionChange() {
    if (mounted) setState(() {});
  }

  // Feed was refreshed — refetch gigs (submitted ones are now excluded).
  void _onFeedReset() {
    if (mounted) _loadGigs();
  }

  void _loadGigs() {
    _microStore
        .load(() => MicrogigService.getMicroGigs(showSubmitted: false))
        .then((v) {
      if (mounted) {
        setState(
            () => _gigs = v.where((g) => g.isAvailable).take(12).toList());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_gigs.isEmpty) return const SizedBox.shrink();
    final gig = _gigs[widget.index % _gigs.length];
    final categoryImg = gig.categoryDetails?.image ?? '';
    final isDone = MicrogigService.submittedGigSlugs.contains(gig.slug);

    Future<void> openGig() async {
      // Completed: the details screen records the slug in
      // MicrogigService.markSubmitted, whose tick listener repaints this card
      // with the "সম্পন্ন" state in place — do NOT swap in a new task (that
      // killed the user's intent to scroll). It drops out of the feed on the
      // next pull-to-refresh.
      await Navigator.push<bool>(
          context,
          MaterialPageRoute(
              builder: (_) => GigDetailsScreen(gigSlug: gig.slug)));
    }

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
            padding: const EdgeInsets.fromLTRB(12, 0, 10, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.bolt_rounded, size: 15, color: _accent),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'টাস্ক কমপ্লিট করে ইনকাম করুন',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MicroGigsScreen())),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      children: [
                        Text('সব দেখুন',
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
          // The gig itself
          InkWell(
            onTap: isDone ? null : openGig,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category thumb (e.g. Facebook/YouTube logo)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 46,
                      height: 46,
                      child: categoryImg.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: categoryImg,
                              fit: BoxFit.cover,
                              memCacheWidth: 120,
                              placeholder: (c, u) =>
                                  Container(color: const Color(0xFFF1F5F9)),
                              errorWidget: (c, u, e) => _thumbFallback(),
                            )
                          : _thumbFallback(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gig.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              '৳${gig.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: _accent,
                              ),
                            ),
                            const Text(
                              '  •  কাজ প্রতি',
                              style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF6B7280)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                    color: const Color(0xFFE2E8F0)),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${gig.remainingSlots} স্লট বাকি',
                                style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // CTA — "earn" normally, or a "completed" state after the user
          // submits the task (stays in place until the next feed refresh).
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: double.infinity,
              height: 34,
              child: isDone
                  ? Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 16, color: Color(0xFF059669)),
                          SizedBox(width: 6),
                          Text(
                            'টাস্ক কমপ্লিট হয়েছে',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF047857)),
                          ),
                        ],
                      ),
                    )
                  : ElevatedButton(
                      onPressed: openGig,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999)),
                      ),
                      child: const Text(
                        'ইনকাম করুন',
                        style:
                            TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbFallback() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Icon(Icons.bolt_rounded, size: 22, color: Color(0xFF94A3B8)),
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
  // Live count overrides so a new comment/reshare shows without a reload.
  int? _commentCount;
  int? _shareCount;

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
                    'এডজি নিউজ',
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
          // Read-more + actions. Comment and share mirror a post's action row
          // so news behaves like the rest of the feed.
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 6, 8),
            child: Row(
              children: [
                GestureDetector(
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
                      Icon(Icons.arrow_forward_rounded,
                          size: 15, color: _accent),
                    ],
                  ),
                ),
                const Spacer(),
                _newsAction(
                  icon: Icons.mode_comment_outlined,
                  label: _labelWithCount(
                      'Comments', _commentCount ?? post.commentCount),
                  onTap: () => NewsCommentsSheet.show(
                    context,
                    newsId: '${post.id}',
                    newsTitle: post.title,
                    onCountChanged: (n) {
                      if (mounted) setState(() => _commentCount = n);
                    },
                  ),
                ),
                _newsAction(
                  icon: Icons.share_outlined,
                  label: _labelWithCount(
                      'Share', _shareCount ?? post.shareCount),
                  onTap: () => _shareStory(post),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _labelWithCount(String label, int count) =>
      count > 0 ? '$label ($count)' : label;

  Widget _newsAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Share sheet with a repost composer, same as a Business Network post — the
  // repost lands on the user's feed as a news reshare.
  void _shareStory(NewsPost post) {
    AdsyShareSheet.show(
      context,
      data: AdsyShareData(
        title: post.title,
        url: '${AppConfig.mediaBaseUrl}/adsy-news/${post.slug}',
        eyebrow: 'এডজি নিউজ',
        repostHint: 'এই খবর নিয়ে কিছু বলুন...',
        onRepost: (caption) async {
          if (!AuthService.isAuthenticated) {
            if (mounted) {
              LoginPromptDialog.show(context, action: 'খবর শেয়ার করতে');
            }
            return false;
          }
          final created = await BusinessNetworkService.reshareNews(
            '${post.id}',
            caption: caption,
          );
          if (created == null) return false;
          if (mounted) {
            setState(() =>
                _shareCount = (_shareCount ?? post.shareCount) + 1);
            AdsyToast.success(context, 'খবরটি আপনার ফিডে শেয়ার হয়েছে');
          }
          return true;
        },
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

// ── পুরাতন কেনাবেচা (sale marketplace) ─────────────────────────────────────
final _saleStore = _DiscoveryStore<Map<String, dynamic>>();

class FeedSaleCard extends StatefulWidget {
  const FeedSaleCard({super.key});
  @override
  State<FeedSaleCard> createState() => _FeedSaleCardState();
}

class _FeedSaleCardState extends State<FeedSaleCard> {
  List<Map<String, dynamic>> _posts = const [];

  @override
  void initState() {
    super.initState();
    _saleStore.load(() async {
      final uri = Uri.parse('${ApiService.baseUrl}/sale/posts/')
          .replace(queryParameters: {'page': '1'});
      final resp = await http.get(uri);
      if (resp.statusCode != 200) return <Map<String, dynamic>>[];
      final data = json.decode(resp.body);
      final results = data is Map ? (data['results'] ?? []) : data;
      return List<Map<String, dynamic>>.from(
          (results as List).whereType<Map<String, dynamic>>());
    }).then((v) {
      if (mounted) setState(() => _posts = v.take(10).toList());
    });
  }

  String _img(Map<String, dynamic> p) {
    final main = (p['main_image'] ?? '').toString();
    if (main.isNotEmpty) return main;
    final images = p['images'];
    if (images is List && images.isNotEmpty && images.first is Map) {
      return (images.first['image'] ?? '').toString();
    }
    return '';
  }

  String? _place(Map<String, dynamic> p) {
    final district = (p['district'] ?? '').toString().trim();
    final division = (p['division'] ?? '').toString().trim();
    if (district.isNotEmpty) return district;
    if (division.isNotEmpty) return division;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_posts.isEmpty) return const SizedBox.shrink();
    return FeedDiscoveryCard(
      icon: Icons.sync_alt_rounded,
      accent: const Color(0xFF0D9488),
      title: 'পুরাতন কেনাবেচা',
      onSeeAll: () => Navigator.pushNamed(context, '/sale'),
      items: _posts.map((p) {
        final price = (p['price'] ?? '0').toString();
        final priceNum = double.tryParse(price) ?? 0;
        final place = _place(p);
        return FeedDiscoveryItem(
          title: (p['title'] ?? '').toString(),
          subtitle: place == null
              ? '৳${priceNum.toStringAsFixed(0)}'
              : '৳${priceNum.toStringAsFixed(0)} • $place',
          imageUrl: _img(p),
          // Route params are typed String? — raw map values may be ints and
          // hard-crash the detail page with a TypeError.
          onTap: () => Navigator.pushNamed(context, '/sale/detail',
              arguments: {
                'slug': p['slug']?.toString(),
                'id': p['id']?.toString(),
              }),
        );
      }).toList(),
    );
  }
}
