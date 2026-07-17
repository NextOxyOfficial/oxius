import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../config/app_config.dart';
import '../../services/adsyconnect_service.dart';
import '../../services/user_search_service.dart';
import '../../utils/shared_post_message.dart';
import '../../utils/url_launcher_utils.dart';
import 'adsy_loading.dart';
import 'adsy_toast.dart';
import 'adsy_chat_icon.dart';

class AdsyShareData {
  final String title;
  final String url;
  final String? description;
  final String? imageUrl;
  final String? subject;
  final String? eyebrow;
  final List<String> hashtags;
  // When set, the sheet shows a "Repost to your profile" composer at the top.
  // Receives the caption; returns true on success.
  final Future<bool> Function(String caption)? onRepost;
  final String? repostHint;

  // Fired once per successful non-repost share action (chat send, WhatsApp,
  // native share, …) so the caller can bump the post's share counter.
  final VoidCallback? onShared;

  const AdsyShareData({
    required this.title,
    required this.url,
    this.description,
    this.imageUrl,
    this.subject,
    this.eyebrow,
    this.hashtags = const [],
    this.onRepost,
    this.repostHint,
    this.onShared,
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

  /// The structured payload sent when sharing into a chat — the recipient
  /// renders a minimal thumbnail + owner-name card (no link-preview chrome).
  /// The owner name is the title with any " on/— Business Network" suffix
  /// trimmed so only the person's name shows.
  String get chatShareContent {
    var owner = cleanTitle;
    for (final suffix in const [
      ' on Business Network',
      ' — Business Network',
      ' - Business Network',
      ' on AdsyClub',
    ]) {
      if (owner.endsWith(suffix)) {
        owner = owner.substring(0, owner.length - suffix.length).trim();
        break;
      }
    }
    final author = owner.isEmpty ? cleanTitle : owner;
    return SharedPostMessage(
      ownerName: author,
      thumbUrl: cleanImageUrl,
      postUrl: cleanUrl,
      authorName: author,
      // The post's own caption/content — shown under the author's name so the
      // card carries the real post, not a generic "Business Network" label.
      caption: cleanDescription,
    ).encode();
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
  bool _reposting = false;
  final TextEditingController _captionCtrl = TextEditingController();

  // Active (existing) chats shown as a "send to chat" row. Users are SELECTED
  // first (checkmark) and delivered together when the send button is tapped.
  bool _loadingChats = true;
  bool _sendingBatch = false;
  List<Map<String, dynamic>> _activeChats = [];
  final Set<String> _selectedRoomIds = {};
  final Set<String> _sentRoomIds = {};

  AdsyShareData get data => widget.data;

  @override
  void initState() {
    super.initState();
    _loadActiveChats();
  }

  Future<void> _loadActiveChats() async {
    try {
      final results = await Future.wait([
        AdsyConnectService.getChatRooms(pageSize: 30),
        AdsyConnectService.getGroups(),
      ]);
      if (!mounted) return;
      final rooms = results[0];
      final groups = results[1];
      setState(() {
        // Groups first, then 1:1 chats — both are share targets.
        _activeChats = [
          ...groups.map<Map<String, dynamic>>((g) {
            final name = (g['name'] ?? '').toString();
            return {
              'isGroup': true,
              'id': g['id']?.toString() ?? '',
              'name': name,
              'firstName': name,
              'avatar': g['image_url'],
            };
          }),
          ...rooms.map<Map<String, dynamic>>((r) {
            final u = r['other_user'] ?? {};
            final first = (u['first_name'] ?? '').toString();
            final last = (u['last_name'] ?? '').toString();
            final name = [first, last].where((s) => s.isNotEmpty).join(' ');
            return {
              'isGroup': false,
              'id': r['id']?.toString() ?? '',
              'userId': u['id']?.toString() ?? '',
              'name': name.isNotEmpty
                  ? name
                  : (u['username'] ?? 'User').toString(),
              'firstName': first.isNotEmpty
                  ? first
                  : (name.isNotEmpty ? name : 'User'),
              'avatar': u['avatar'],
            };
          }),
        ].where((r) => (r['id'] as String).isNotEmpty).toList();
        _loadingChats = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingChats = false);
    }
  }

  void _toggleSelect(Map<String, dynamic> room) {
    final id = room['id'] as String;
    if (_sentRoomIds.contains(id) || _sendingBatch) return;
    setState(() {
      if (_selectedRoomIds.contains(id)) {
        _selectedRoomIds.remove(id);
      } else {
        _selectedRoomIds.add(id);
      }
    });
  }

  Future<void> _sendSelected() async {
    if (_selectedRoomIds.isEmpty || _sendingBatch) return;
    setState(() => _sendingBatch = true);
    final targets = _activeChats
        .where((r) => _selectedRoomIds.contains(r['id']))
        .toList();
    int ok = 0;
    for (final room in targets) {
      try {
        if (room['isGroup'] == true) {
          final res = await AdsyConnectService.sendGroupMessage(
              room['id'] as String, data.chatShareContent);
          if (res == null) continue;
        } else {
          await AdsyConnectService.sendTextMessage(
            chatroomId: room['id'] as String,
            receiverId: room['userId'] as String,
            content: data.chatShareContent,
          );
        }
        _sentRoomIds.add(room['id'] as String);
        ok++;
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _selectedRoomIds.clear();
      _sendingBatch = false;
    });
    if (ok > 0) {
      data.onShared?.call();
      AdsyToast.success(context, '$ok জনকে পাঠানো হয়েছে');
      Navigator.of(context).pop(); // close the share sheet after sending
    } else {
      AdsyToast.error(context, 'পাঠানো যায়নি');
    }
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _doRepost() async {
    if (data.onRepost == null || _reposting) return;
    setState(() => _reposting = true);
    final ok = await data.onRepost!(_captionCtrl.text.trim());
    if (!mounted) return;
    setState(() => _reposting = false);
    if (ok) {
      Navigator.pop(context);
      AdsyToast.success(context, 'আপনার প্রোফাইলে শেয়ার হয়েছে');
    } else {
      AdsyToast.error(context, 'শেয়ার করা যায়নি। আবার চেষ্টা করুন।');
    }
  }

  Widget _buildRepostComposer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.repeat_rounded, size: 17, color: Color(0xFF111827)),
            SizedBox(width: 7),
            Text(
              'আপনার প্রোফাইলে শেয়ার করুন',
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827)),
            ),
          ],
        ),
        const SizedBox(height: 9),
        TextField(
          controller: _captionCtrl,
          maxLines: 6,
          minLines: 3,
          style: const TextStyle(fontSize: 14.5, height: 1.4),
          decoration: InputDecoration(
            hintText: data.repostHint ?? 'এই পোস্ট সম্পর্কে কিছু লিখুন…',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            isDense: true,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF111827), width: 1.3),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: _reposting ? null : _doRepost,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF94A3B8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11)),
            ),
            icon: _reposting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white)))
                : const Icon(Icons.repeat_rounded, size: 17),
            label: Text(_reposting ? 'পোস্ট হচ্ছে…' : 'প্রোফাইলে শেয়ার করুন',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ),
        const SizedBox(height: 4),
        const Divider(height: 18, color: Color(0xFFF1F5F9)),
      ],
    );
  }

  // Prominent "send to a chat" strip shown right under the profile-share
  // button. Lists the user's ACTIVE chats as avatar chips (one tap sends);
  // the search chip opens the full picker where typing surfaces new users.
  Widget _buildChatShareSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            AdsyChatIcon(size: 17),
            SizedBox(width: 7),
            Text('চ্যাটে শেয়ার করুন',
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827))),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 84,
          child: _loadingChats
              ? const Center(
                  child: SizedBox(
                      width: 22, height: 22, child: AdsyLoadingIndicator()))
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _activeChats.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 4),
                  itemBuilder: (_, i) {
                    if (i == 0) return _searchChip();
                    return _contactChip(_activeChats[i - 1]);
                  },
                ),
        ),
        if (_selectedRoomIds.isNotEmpty) ...[
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: _sendingBatch ? null : _sendSelected,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF93C5FD),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11)),
              ),
              icon: _sendingBatch
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : const Icon(Icons.send_rounded, size: 17),
              label: Text(
                  _sendingBatch
                      ? 'পাঠানো হচ্ছে…'
                      : 'পাঠান (${_selectedRoomIds.length})',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ],
        const Divider(height: 20, color: Color(0xFFF1F5F9)),
      ],
    );
  }

  // Opens the full picker (active chats + user search) for new people.
  Widget _searchChip() {
    return SizedBox(
      width: 62,
      child: InkWell(
        onTap: _shareToChat,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF3FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFDBE4FF)),
              ),
              child: const Icon(Icons.search_rounded,
                  color: Color(0xFF2563EB), size: 24),
            ),
            const SizedBox(height: 5),
            const Text('সার্চ',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569))),
          ],
        ),
      ),
    );
  }

  Widget _contactChip(Map<String, dynamic> room) {
    final id = room['id'] as String;
    final selected = _selectedRoomIds.contains(id);
    final sent = _sentRoomIds.contains(id);
    final isGroup = room['isGroup'] == true;
    final fallbackIcon = Icon(isGroup ? Icons.groups : Icons.person,
        color: const Color(0xFF3B82F6));
    final avatar = AppConfig.getAbsoluteUrl((room['avatar'] ?? '').toString());
    return SizedBox(
      width: 62,
      child: InkWell(
        onTap: sent ? null : () => _toggleSelect(room),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFEFF6FF),
                    border: selected
                        ? Border.all(color: const Color(0xFF2563EB), width: 2)
                        : null,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: avatar.isNotEmpty
                      ? Image.network(avatar,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => fallbackIcon)
                      : fallbackIcon,
                ),
                if (selected || sent)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: sent
                            ? Colors.black.withValues(alpha: 0.32)
                            : const Color(0xFF2563EB).withValues(alpha: 0.28),
                      ),
                      child: const Center(
                        child: Icon(Icons.check_rounded,
                            color: Colors.white, size: 24),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(room['firstName'].toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569))),
          ],
        ),
      ),
    );
  }

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
    data.onShared?.call();
    Navigator.pop(context);
    await AdsyShareSheet.nativeShare(context, data: data);
  }

  Future<void> _openShareUrl(String url) async {
    data.onShared?.call();
    Navigator.pop(context);
    final ok = await UrlLauncherUtils.launchExternalUrl(url);
    if (!ok && mounted) {
      AdsyToast.error(context, 'Could not open share app.');
    }
  }

  // Send this item into an AdsyConnect chat. The chat renders the URL as a
  // rich link-preview card, so no special message type is needed.
  Future<void> _shareToChat() async {
    // Capture the root navigator BEFORE popping — after the share sheet is
    // dismissed, `context` is defunct and can't open the picker (that was why
    // nothing appeared on tap).
    final navigator = Navigator.of(context, rootNavigator: true);
    final content = data.chatShareContent;
    final onShared = data.onShared;
    navigator.pop();
    await showModalBottomSheet<void>(
      context: navigator.context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChatPickerSheet(content: content, onShared: onShared),
    );
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
                  if (data.onRepost != null) ...[
                    _buildRepostComposer(),
                    const SizedBox(height: 14),
                  ],
                  // Send-to-chat sits right under the profile-share button.
                  _buildChatShareSection(),
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
                          icon: FontAwesomeIcons.shareNodes,
                          color: const Color(0xFF4F46E5),
                          onTap: _nativeShare,
                        ),
                        _SharePlatformButton(
                          tooltip: 'WhatsApp',
                          label: 'WhatsApp',
                          icon: FontAwesomeIcons.whatsapp,
                          color: const Color(0xFF25D366),
                          onTap: () => _openShareUrl(_platformUrl('whatsapp')),
                        ),
                        _SharePlatformButton(
                          tooltip: 'Facebook',
                          label: 'Facebook',
                          icon: FontAwesomeIcons.facebookF,
                          color: const Color(0xFF1877F2),
                          onTap: () => _openShareUrl(_platformUrl('facebook')),
                        ),
                        _SharePlatformButton(
                          tooltip: 'X',
                          label: 'X',
                          icon: FontAwesomeIcons.xTwitter,
                          color: const Color(0xFF111827),
                          onTap: () => _openShareUrl(_platformUrl('x')),
                        ),
                        _SharePlatformButton(
                          tooltip: 'LinkedIn',
                          label: 'LinkedIn',
                          icon: FontAwesomeIcons.linkedinIn,
                          color: const Color(0xFF0A66C2),
                          onTap: () => _openShareUrl(_platformUrl('linkedin')),
                        ),
                        _SharePlatformButton(
                          tooltip: 'Telegram',
                          label: 'Telegram',
                          icon: FontAwesomeIcons.telegram,
                          color: const Color(0xFF229ED9),
                          onTap: () => _openShareUrl(_platformUrl('telegram')),
                        ),
                        _SharePlatformButton(
                          tooltip: 'Email',
                          label: 'Email',
                          icon: FontAwesomeIcons.envelope,
                          color: const Color(0xFFEA580C),
                          onTap: () => _openShareUrl(_platformUrl('email')),
                        ),
                        _SharePlatformButton(
                          tooltip: 'Copy',
                          label: 'Copy',
                          icon: _copied
                              ? FontAwesomeIcons.check
                              : FontAwesomeIcons.copy,
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

/// Pick one of the user's existing chats and send [shareText] into it. The
/// chat interface renders the contained URL as a link-preview card.
class _ChatPickerSheet extends StatefulWidget {
  final String content;
  final VoidCallback? onShared;

  const _ChatPickerSheet({required this.content, this.onShared});

  @override
  State<_ChatPickerSheet> createState() => _ChatPickerSheetState();
}

class _ChatPickerSheetState extends State<_ChatPickerSheet> {
  bool _loading = true;
  bool _searching = false;
  bool _sendingBatch = false;
  // Selection is keyed by the OTHER user's id (so active-chat and searched
  // entries for the same person don't double up); the chosen item map is kept
  // so batch-send can resolve/create the room.
  final Map<String, Map<String, dynamic>> _selected = {};
  final Set<String> _sent = {};
  List<Map<String, dynamic>> _rooms = []; // active chats
  List<Map<String, dynamic>> _searchResults = [];
  final TextEditingController _search = TextEditingController();
  String _query = '';
  int _searchSeq = 0;

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearchChanged);
    _load();
  }

  @override
  void dispose() {
    _search.removeListener(_onSearchChanged);
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final v = _search.text.trim();
    if (v == _query) return;
    setState(() => _query = v);
    if (v.isEmpty) {
      setState(() {
        _searchResults = [];
        _searching = false;
      });
      return;
    }
    // Search all users (surfaces people not yet in an active chat).
    final seq = ++_searchSeq;
    setState(() => _searching = true);
    UserSearchService.searchUsers(v).then((users) {
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _searchResults = users
            .map((u) => {
                  'userId': u.id,
                  'name': u.name.isNotEmpty ? u.name : (u.username ?? 'User'),
                  'avatar': u.image ?? u.avatar,
                })
            .toList();
        _searching = false;
      });
    });
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        AdsyConnectService.getChatRooms(pageSize: 100),
        AdsyConnectService.getGroups(),
      ]);
      if (!mounted) return;
      final rooms = results[0];
      final groups = results[1];
      setState(() {
        _rooms = [
          // Groups are share targets too — listed first.
          ...groups.map<Map<String, dynamic>>((g) => {
                'isGroup': true,
                'id': g['id']?.toString() ?? '',
                'name': (g['name'] ?? '').toString(),
                'avatar': g['image_url'],
              }),
          ...rooms.map<Map<String, dynamic>>((r) {
            final u = r['other_user'] ?? {};
            final first = (u['first_name'] ?? '').toString();
            final last = (u['last_name'] ?? '').toString();
            final name = [first, last].where((s) => s.isNotEmpty).join(' ');
            return {
              'isGroup': false,
              'id': r['id']?.toString() ?? '',
              'userId': u['id']?.toString() ?? '',
              'name': name.isNotEmpty
                  ? name
                  : (u['username'] ?? 'User').toString(),
              'avatar': u['avatar'],
            };
          }),
        ].where((r) => (r['id'] as String).isNotEmpty).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Groups are keyed by group id, people by user id — never collide.
  String _keyOf(Map<String, dynamic> item) => item['isGroup'] == true
      ? 'g:${item['id']}'
      : (item['userId'] ?? '').toString();

  // Active chats initially; user-search results once a query is typed.
  List<Map<String, dynamic>> get _visible =>
      _query.isEmpty ? _rooms : _searchResults;

  void _toggle(Map<String, dynamic> item) {
    final key = _keyOf(item);
    if (key.isEmpty || _sent.contains(key) || _sendingBatch) return;
    setState(() {
      if (_selected.containsKey(key)) {
        _selected.remove(key);
      } else {
        _selected[key] = item;
      }
    });
  }

  Future<void> _sendSelected() async {
    if (_selected.isEmpty || _sendingBatch) return;
    setState(() => _sendingBatch = true);
    int ok = 0;
    for (final entry in _selected.entries.toList()) {
      final key = entry.key;
      final item = entry.value;
      try {
        if (item['isGroup'] == true) {
          final res = await AdsyConnectService.sendGroupMessage(
              (item['id'] ?? '').toString(), widget.content);
          if (res != null) {
            _sent.add(key);
            ok++;
          }
          continue;
        }
        final userId = (item['userId'] ?? '').toString();
        // A searched user may have no room yet — open/create it first.
        var roomId = (item['id'] ?? '').toString();
        if (roomId.isEmpty) {
          final room = await AdsyConnectService.getOrCreateChatRoom(userId);
          roomId = (room['id'] ?? '').toString();
        }
        if (roomId.isNotEmpty) {
          await AdsyConnectService.sendTextMessage(
            chatroomId: roomId,
            receiverId: userId,
            content: widget.content,
          );
          _sent.add(key);
          ok++;
        }
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _selected.clear();
      _sendingBatch = false;
    });
    if (ok > 0) {
      widget.onShared?.call();
      AdsyToast.success(context, '$ok জনকে পাঠানো হয়েছে');
      Navigator.of(context).pop(); // close the picker after sending
    } else {
      AdsyToast.error(context, 'পাঠানো যায়নি');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.72),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(999)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    const AdsyChatIcon(size: 19),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('চ্যাটে পাঠান',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827))),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded,
                          color: Colors.grey.shade500, size: 20),
                      hintText: 'সার্চ করুন',
                      hintStyle:
                          TextStyle(color: Colors.grey.shade500, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
              ),
              Flexible(
                child: (_loading || _searching)
                    ? const Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(
                          child: SizedBox(
                              width: 26,
                              height: 26,
                              child: AdsyLoadingIndicator()),
                        ),
                      )
                    : _visible.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(28),
                            child: Text(
                                _query.isEmpty
                                    ? 'কোনো চ্যাট নেই'
                                    : 'কোনো ব্যবহারকারী পাওয়া যায়নি',
                                style: TextStyle(color: Colors.grey.shade600)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 12),
                            itemCount: _visible.length,
                            itemBuilder: (_, i) => _tile(_visible[i]),
                          ),
              ),
              if (_selected.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _sendingBatch ? null : _sendSelected,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF93C5FD),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _sendingBatch
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white)))
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                          _sendingBatch
                              ? 'পাঠানো হচ্ছে…'
                              : 'পাঠান (${_selected.length})',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14.5)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(Map<String, dynamic> room) {
    final key = _keyOf(room);
    final selected = _selected.containsKey(key);
    final sent = _sent.contains(key);
    final isGroup = room['isGroup'] == true;
    final fallbackIcon = Icon(isGroup ? Icons.groups : Icons.person,
        color: const Color(0xFF3B82F6));
    final avatar = AppConfig.getAbsoluteUrl((room['avatar'] ?? '').toString());
    return ListTile(
      onTap: sent ? null : () => _toggle(room),
      leading: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
            shape: BoxShape.circle, color: Color(0xFFEFF6FF)),
        clipBehavior: Clip.antiAlias,
        child: avatar.isNotEmpty
            ? Image.network(avatar,
                fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallbackIcon)
            : fallbackIcon,
      ),
      title: Text(room['name'].toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B))),
      trailing: sent
          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981))
          : Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? const Color(0xFF2563EB) : Colors.grey.shade400,
            ),
    );
  }
}

class _SharePlatformButton extends StatelessWidget {
  final String tooltip;
  final String label;
  final FaIconData? icon;
  final Color color;
  final VoidCallback onTap;

  const _SharePlatformButton({
    required this.tooltip,
    required this.label,
    required this.color,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 60,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                      child: icon == null
                          ? null
                          : FaIcon(icon!, size: 20, color: color)),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
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
