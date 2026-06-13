import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../config/app_config.dart';
import '../../utils/url_launcher_utils.dart';
import 'adsy_toast.dart';

class AdsyShareData {
  final String title;
  final String url;
  final String? description;
  final String? imageUrl;
  final String? subject;
  final String? eyebrow;
  final List<String> hashtags;

  const AdsyShareData({
    required this.title,
    required this.url,
    this.description,
    this.imageUrl,
    this.subject,
    this.eyebrow,
    this.hashtags = const [],
  });

  String get cleanTitle {
    final value = _plainText(title);
    return value.isEmpty ? 'AdsyClub' : value;
  }

  String get cleanUrl => url.trim();

  String get cleanDescription => _plainText(description ?? '');

  String get cleanImageUrl => AppConfig.getAbsoluteUrl(imageUrl);

  String get shareSubject {
    final value = _plainText(subject ?? cleanTitle);
    return value.isEmpty ? cleanTitle : value;
  }

  String get cleanEyebrow => _plainText(eyebrow ?? '');

  String get shareText {
    final parts = <String>[
      cleanTitle,
      if (cleanDescription.isNotEmpty) cleanDescription,
      cleanUrl,
    ];
    return parts.where((part) => part.trim().isNotEmpty).join('\n\n');
  }

  String get hashtagText {
    return hashtags
        .map((tag) => tag.trim().replaceAll('#', ''))
        .where((tag) => tag.isNotEmpty)
        .join(',');
  }

  static String _plainText(String value) {
    var text = value.trim();
    if (text.isEmpty) return '';

    text = text.replaceAll(
      RegExp(
        r'</?(br|p|div|li|ul|ol|h[1-6]|blockquote|section|article)[^>]*>',
        caseSensitive: false,
      ),
      ' ',
    );
    text = text.replaceAll(RegExp(r'<[^>]*>'), ' ');
    text = _decodeHtmlEntities(text);
    text = text.replaceAll(RegExp(r'<[^>]*>'), ' ');
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _decodeHtmlEntities(String value) {
    const namedEntities = <String, String>{
      'amp': '&',
      'lt': '<',
      'gt': '>',
      'quot': '"',
      'apos': "'",
      '#39': "'",
      'nbsp': ' ',
      'ndash': '-',
      'mdash': '-',
      'hellip': '...',
    };

    return value.replaceAllMapped(
      RegExp(r'&(#x?[0-9a-fA-F]+|[a-zA-Z][a-zA-Z0-9]+);'),
      (match) {
        final entity = match.group(1)!;
        final lower = entity.toLowerCase();
        final named = namedEntities[lower];
        if (named != null) return named;

        int? codePoint;
        if (lower.startsWith('#x')) {
          codePoint = int.tryParse(lower.substring(2), radix: 16);
        } else if (lower.startsWith('#')) {
          codePoint = int.tryParse(lower.substring(1));
        }

        if (codePoint == null || codePoint <= 0 || codePoint > 0x10FFFF) {
          return match.group(0)!;
        }

        return String.fromCharCode(codePoint);
      },
    );
  }
}

class AdsyShareSheet {
  static Future<void> show(
    BuildContext context, {
    required AdsyShareData data,
  }) async {
    if (data.cleanUrl.isEmpty) {
      AdsyToast.error(context, 'Share link is not available.');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AdsyShareSheetBody(data: data),
    );
  }

  static Future<void> nativeShare(
    BuildContext context, {
    required AdsyShareData data,
  }) async {
    try {
      await Share.share(data.shareText, subject: data.shareSubject);
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: data.cleanUrl));
      if (context.mounted) {
        AdsyToast.success(context, 'Share failed. Link copied instead.');
      }
    }
  }
}

class _AdsyShareSheetBody extends StatefulWidget {
  final AdsyShareData data;

  const _AdsyShareSheetBody({required this.data});

  @override
  State<_AdsyShareSheetBody> createState() => _AdsyShareSheetBodyState();
}

class _AdsyShareSheetBodyState extends State<_AdsyShareSheetBody> {
  bool _copied = false;

  AdsyShareData get data => widget.data;

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: data.cleanUrl));
    if (!mounted) return;
    setState(() => _copied = true);
    AdsyToast.success(context, 'Link copied to clipboard');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _nativeShare() async {
    Navigator.pop(context);
    await AdsyShareSheet.nativeShare(context, data: data);
  }

  Future<void> _openShareUrl(String url) async {
    Navigator.pop(context);
    final ok = await UrlLauncherUtils.launchExternalUrl(url);
    if (!ok && mounted) {
      AdsyToast.error(context, 'Could not open share app.');
    }
  }

  String _platformUrl(String platform) {
    final encodedUrl = Uri.encodeComponent(data.cleanUrl);
    final encodedText = Uri.encodeComponent(data.shareText);
    final encodedTitle = Uri.encodeComponent(data.cleanTitle);
    final encodedDescription = Uri.encodeComponent(
      data.cleanDescription.isEmpty ? data.cleanTitle : data.cleanDescription,
    );

    switch (platform) {
      case 'whatsapp':
        return 'https://wa.me/?text=$encodedText';
      case 'facebook':
        return 'https://www.facebook.com/sharer/sharer.php?u=$encodedUrl';
      case 'x':
        final hashtags =
            data.hashtagText.isEmpty ? '' : '&hashtags=${data.hashtagText}';
        return 'https://x.com/intent/tweet?text=$encodedTitle&url=$encodedUrl$hashtags';
      case 'linkedin':
        return 'https://www.linkedin.com/sharing/share-offsite/?url=$encodedUrl';
      case 'telegram':
        return 'https://t.me/share/url?url=$encodedUrl&text=$encodedTitle';
      case 'email':
        return 'mailto:?subject=$encodedTitle&body=$encodedDescription%0A%0A$encodedUrl';
    }
    return data.cleanUrl;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(2, 0, 2, bottomInset),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/icons/share.png',
                            width: 20,
                            height: 20,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Share',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SharePreview(data: data),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.link_rounded,
                            size: 18, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            data.cleanUrl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _copyLink,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF059669),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 30),
                          ),
                          child: Text(_copied ? 'Copied' : 'Copy'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _SharePlatformButton(
                          tooltip: 'More apps',
                          label: 'More',
                          iconAsset: 'assets/icons/share.png',
                          color: const Color(0xFF4F46E5),
                          onTap: _nativeShare,
                        ),
                        _SharePlatformButton(
                          tooltip: 'WhatsApp',
                          label: 'WhatsApp',
                          icon: Icons.chat_rounded,
                          color: const Color(0xFF16A34A),
                          onTap: () => _openShareUrl(_platformUrl('whatsapp')),
                        ),
                        _SharePlatformButton(
                          tooltip: 'Facebook',
                          label: 'Facebook',
                          icon: Icons.facebook_rounded,
                          color: const Color(0xFF1877F2),
                          onTap: () => _openShareUrl(_platformUrl('facebook')),
                        ),
                        _SharePlatformButton(
                          tooltip: 'X',
                          label: 'X',
                          textIcon: 'X',
                          color: const Color(0xFF111827),
                          onTap: () => _openShareUrl(_platformUrl('x')),
                        ),
                        _SharePlatformButton(
                          tooltip: 'LinkedIn',
                          label: 'LinkedIn',
                          icon: Icons.business_center_rounded,
                          color: const Color(0xFF0A66C2),
                          onTap: () => _openShareUrl(_platformUrl('linkedin')),
                        ),
                        _SharePlatformButton(
                          tooltip: 'Telegram',
                          label: 'Telegram',
                          icon: Icons.send_rounded,
                          color: const Color(0xFF229ED9),
                          onTap: () => _openShareUrl(_platformUrl('telegram')),
                        ),
                        _SharePlatformButton(
                          tooltip: 'Email',
                          label: 'Email',
                          icon: Icons.email_rounded,
                          color: const Color(0xFFEA580C),
                          onTap: () => _openShareUrl(_platformUrl('email')),
                        ),
                        _SharePlatformButton(
                          tooltip: 'Copy',
                          label: 'Copy',
                          icon: _copied
                              ? Icons.check_rounded
                              : Icons.copy_rounded,
                          color: const Color(0xFF059669),
                          onTap: _copyLink,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SharePreview extends StatelessWidget {
  final AdsyShareData data;

  const _SharePreview({required this.data});

  @override
  Widget build(BuildContext context) {
    final imageUrl = data.cleanImageUrl;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Container(
              width: 76,
              height: 76,
              // No backdrop behind real images — thumbnails with transparent
              // corners were exposing this as a gray square. Keep the tint
              // only for the no-image icon fallback.
              color: imageUrl.isEmpty ? const Color(0xFFF1F5F9) : Colors.white,
              child: imageUrl.isEmpty
                  ? const Icon(
                      Icons.public_rounded,
                      color: Color(0xFF64748B),
                      size: 28,
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.public_rounded,
                        color: Color(0xFF64748B),
                        size: 28,
                      ),
                    ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (data.cleanEyebrow.isNotEmpty) ...[
                    Text(
                      data.cleanEyebrow.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    data.cleanTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (data.cleanDescription.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      data.cleanDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.25,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SharePlatformButton extends StatelessWidget {
  final String tooltip;
  final String label;
  final IconData? icon;
  final String? iconAsset;
  final String? textIcon;
  final Color color;
  final VoidCallback onTap;

  const _SharePlatformButton({
    required this.tooltip,
    required this.label,
    required this.color,
    required this.onTap,
    this.icon,
    this.iconAsset,
    this.textIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 54,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 30,
                  height: 28,
                  child: Center(
                    child: iconAsset != null
                        ? Image.asset(
                            iconAsset!,
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                          )
                        : textIcon != null
                            ? Text(
                                textIcon!,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              )
                            : Icon(icon, size: 23, color: color),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
