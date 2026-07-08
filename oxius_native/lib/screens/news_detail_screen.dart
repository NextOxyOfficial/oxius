import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/news_models.dart';
import '../services/news_service.dart';
import '../services/translation_service.dart';
import '../utils/network_error_handler.dart';
import '../utils/url_launcher_utils.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_share_sheet.dart';

class NewsDetailScreen extends StatefulWidget {
  final String slug;

  const NewsDetailScreen({
    super.key,
    required this.slug,
  });

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  static const Color _accent = Color(0xFF2563EB);
  static const Color _ink = Color(0xFF0F172A);
  static const Color _body = Color(0xFF334155);
  static const Color _muted = Color(0xFF64748B);
  static const Color _faint = Color(0xFF94A3B8);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _hairline = Color(0xFFF1F5F9);

  final TranslationService _translationService = TranslationService();

  NewsPost? _post;
  bool _loading = true;
  Object? _error;
  List<NewsPost> _latestPosts = const [];

  @override
  void initState() {
    super.initState();
    _translationService.addListener(_onTranslationsChanged);
    _loadPost();
    _loadLatestPosts();
  }

  @override
  void dispose() {
    _translationService.removeListener(_onTranslationsChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant NewsDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slug != widget.slug) {
      _loadPost();
      _loadLatestPosts();
    }
  }

  void _onTranslationsChanged() {
    if (!mounted) return;
    setState(() {});
  }

  bool get _isBn => !_translationService.currentLanguage.startsWith('en');

  String _t(String key, {required String en, required String bn}) {
    return _translationService.t(key, fallback: _isBn ? bn : en);
  }

  Future<void> _loadPost() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final post = await NewsService.getPostBySlug(widget.slug);
      if (!mounted) return;
      setState(() {
        _post = post;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadLatestPosts() async {
    try {
      final response = await NewsService.getPosts(page: 1);
      if (!mounted) return;
      setState(() {
        _latestPosts = response.results
            .where((p) => p.slug != widget.slug)
            .take(6)
            .toList();
      });
    } catch (_) {
      // Latest news is a secondary section; the article stays readable
      // without it, so failures here are silently ignored.
    }
  }

  Future<void> _sharePost() async {
    final post = _post;
    if (post == null) return;
    await AdsyShareSheet.show(
      context,
      data: AdsyShareData(
        title: post.title,
        description: post.summary,
        url: 'https://adsyclub.com/adsy-news/${post.slug}',
        imageUrl: post.image,
        subject: post.title,
        eyebrow: 'AdsyNews',
        hashtags: post.tags,
      ),
    );
  }

  void _openPost(NewsPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsDetailScreen(slug: post.slug),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _loading
          ? const Center(child: AdsyLoadingIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: _ink, size: 22),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'AdsyNews',
        style: TextStyle(
          color: _ink,
          fontWeight: FontWeight.w800,
          fontSize: 16,
          letterSpacing: -0.2,
        ),
      ),
      actions: [
        IconButton(
          tooltip: _t('news_share', en: 'Share', bn: 'শেয়ার করুন'),
          icon: const Icon(Icons.share_outlined, color: _ink, size: 20),
          onPressed: _post == null ? null : _sharePost,
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _hairline),
      ),
    );
  }

  Widget _buildErrorState() {
    final isNetwork = NetworkErrorHandler.isNetworkError(_error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
                border: Border.all(color: _border),
              ),
              child: Icon(
                isNetwork ? Icons.wifi_off_rounded : Icons.article_outlined,
                color: _faint,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _t('news_load_failed',
                  en: 'Could not load this article',
                  bn: 'খবরটা লোড করা গেল না'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isNetwork
                  ? _t('news_check_connection',
                      en:
                          'Please check your internet connection and try again.',
                      bn: 'ইন্টারনেট সংযোগটা একটু দেখে আবার চেষ্টা করুন।')
                  : _t('news_try_again_later',
                      en: 'Something went wrong. Please try again.',
                      bn: 'কোথাও একটা সমস্যা হয়েছে। আবার চেষ্টা করুন।'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _muted, height: 1.5),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _loadPost,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label:
                  Text(_t('news_retry', en: 'Retry', bn: 'আবার চেষ্টা করুন')),
              style: OutlinedButton.styleFrom(
                foregroundColor: _accent,
                side: const BorderSide(color: _border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                textStyle: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final post = _post!;
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (post.image != null) _buildHeroImage(post),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (post.tags.isNotEmpty) ...[
                      _buildTags(post),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: _ink,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildMetaRow(post),
                    const SizedBox(height: 16),
                    const Divider(color: _hairline, height: 1, thickness: 1),
                    const SizedBox(height: 4),
                    _buildArticleBody(post),
                    if (post.comments.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildCommentsSection(post),
                    ],
                  ],
                ),
              ),
              if (_latestPosts.isNotEmpty) _buildLatestNewsSection(),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage(NewsPost post) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: CachedNetworkImage(
            imageUrl: post.image!,
            fit: BoxFit.cover,
            memCacheWidth: 1280,
            fadeInDuration: const Duration(milliseconds: 120),
            placeholder: (context, url) => Container(
              color: _hairline,
              child: const Center(child: AdsyLoadingIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              color: _hairline,
              child: const Icon(
                Icons.image_not_supported_outlined,
                size: 36,
                color: _faint,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTags(NewsPost post) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: post.tags.take(3).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            tag.toUpperCase(),
            style: const TextStyle(
              color: _accent,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetaRow(NewsPost post) {
    final author = post.authorDetails;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _hairline,
            border: Border.all(color: _border),
            image: author?.image != null
                ? DecorationImage(
                    image: CachedNetworkImageProvider(author!.image!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: author?.image == null
              ? const Icon(Icons.person_outline_rounded,
                  size: 18, color: _faint)
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                author?.displayName ?? 'AdsyNews',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                  color: _ink,
                ),
              ),
              if (author?.profession != null &&
                  author!.profession!.isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(
                  author.profession!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: _muted),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              post.formattedDate,
              style: const TextStyle(fontSize: 12, color: _muted),
            ),
            const SizedBox(height: 2),
            Text(
              _isBn
                  ? '${post.readTime} মিনিটের পড়া'
                  : '${post.readTime} min read',
              style: const TextStyle(fontSize: 11.5, color: _faint),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildArticleBody(NewsPost post) {
    return Html(
      data: _constrainHtmlImages(post.content),
      onLinkTap: (url, attributes, element) {
        UrlLauncherUtils.launchExternalUrl(url);
      },
      style: {
        "body": Style(
          fontSize: FontSize(15),
          lineHeight: const LineHeight(1.65),
          color: _body,
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
        ),
        "p": Style(
          margin: Margins.only(bottom: 12),
        ),
        "a": Style(
          color: _accent,
          textDecoration: TextDecoration.none,
        ),
        "h1": Style(
          fontSize: FontSize(19),
          fontWeight: FontWeight.w800,
          color: _ink,
          lineHeight: const LineHeight(1.35),
          margin: Margins.only(top: 20, bottom: 10),
        ),
        "h2": Style(
          fontSize: FontSize(17.5),
          fontWeight: FontWeight.w700,
          color: _ink,
          lineHeight: const LineHeight(1.35),
          margin: Margins.only(top: 16, bottom: 8),
        ),
        "h3": Style(
          fontSize: FontSize(16),
          fontWeight: FontWeight.w700,
          color: _ink,
          lineHeight: const LineHeight(1.35),
          margin: Margins.only(top: 12, bottom: 6),
        ),
        "blockquote": Style(
          margin: Margins.symmetric(vertical: 12),
          padding: HtmlPaddings.only(left: 14),
          border: const Border(left: BorderSide(color: _border, width: 3)),
          color: _muted,
        ),
        "li": Style(
          margin: Margins.only(bottom: 6),
        ),
        "img": Style(
          margin: Margins.symmetric(vertical: 12),
          width: Width(100, Unit.percent),
          height: Height.auto(),
        ),
      },
    );
  }

  Widget _buildCommentsSection(NewsPost post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: _hairline, height: 1, thickness: 1),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              _t('news_comments', en: 'Comments', bn: 'মন্তব্য'),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: _ink,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _hairline,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${post.comments.length}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: post.comments.length,
          separatorBuilder: (context, index) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: _hairline, height: 1, thickness: 1),
          ),
          itemBuilder: (context, index) =>
              _buildCommentTile(post.comments[index]),
        ),
      ],
    );
  }

  Widget _buildCommentTile(NewsComment comment) {
    final name =
        (comment.userName != null && comment.userName!.trim().isNotEmpty)
            ? comment.userName!.trim()
            : _t('news_anonymous', en: 'Anonymous', bn: 'নাম প্রকাশে অনিচ্ছুক');
    final initial = name.characters.first.toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _hairline,
                border: Border.all(color: _border),
              ),
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                  color: _ink,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatCommentDate(comment.createdAt),
              style: const TextStyle(fontSize: 11, color: _faint),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 39),
          child: Text(
            comment.content,
            style: const TextStyle(
              fontSize: 13.5,
              color: _body,
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLatestNewsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('news_more_news', en: 'More News', bn: 'আরও খবর'),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: _ink,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < _latestPosts.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      color: _hairline,
                      height: 1,
                      thickness: 1,
                      indent: 14,
                      endIndent: 14,
                    ),
                  _buildLatestNewsRow(
                    _latestPosts[i],
                    isFirst: i == 0,
                    isLast: i == _latestPosts.length - 1,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestNewsRow(NewsPost post,
      {required bool isFirst, required bool isLast}) {
    return InkWell(
      onTap: () => _openPost(post),
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(isFirst ? 14 : 0),
        bottom: Radius.circular(isLast ? 14 : 0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 72,
                height: 72,
                child: post.image != null
                    ? CachedNetworkImage(
                        imageUrl: post.image!,
                        fit: BoxFit.cover,
                        memCacheWidth: 144,
                        memCacheHeight: 144,
                        fadeInDuration: const Duration(milliseconds: 120),
                        placeholder: (context, url) =>
                            Container(color: _hairline),
                        errorWidget: (context, url, error) => Container(
                          color: _hairline,
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            size: 20,
                            color: _faint,
                          ),
                        ),
                      )
                    : Container(
                        color: _hairline,
                        child: const Icon(
                          Icons.article_outlined,
                          size: 22,
                          color: _faint,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                      color: _ink,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    post.formattedDate,
                    style: const TextStyle(fontSize: 11.5, color: _faint),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.chevron_right_rounded, size: 18, color: _faint),
            ),
          ],
        ),
      ),
    );
  }

  String _constrainHtmlImages(String html) {
    return html.replaceAllMapped(
      RegExp(r'<img\b([^>]*)>', caseSensitive: false),
      (match) {
        final attrs = match.group(1) ?? '';
        final styleMatch =
            RegExp(r'style\s*=\s*"([^"]*)"', caseSensitive: false)
                .firstMatch(attrs);
        const requiredStyle = 'max-width:100%;height:auto;';

        if (styleMatch != null) {
          final currentStyle = styleMatch.group(1) ?? '';
          final nextAttrs = attrs.replaceFirst(
            styleMatch.group(0)!,
            'style="$currentStyle;$requiredStyle"',
          );
          return '<img$nextAttrs>';
        }

        return '<img$attrs style="$requiredStyle">';
      },
    );
  }

  String _formatCommentDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return _isBn
          ? '${difference.inDays} দিন আগে'
          : '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return _isBn
          ? '${difference.inHours} ঘণ্টা আগে'
          : '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return _isBn
          ? '${difference.inMinutes} মিনিট আগে'
          : '${difference.inMinutes}m ago';
    } else {
      return _isBn ? 'এইমাত্র' : 'Just now';
    }
  }
}
