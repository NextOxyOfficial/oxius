import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../utils/adsy_ios_scale.dart';
import 'package:oxius_native/widgets/common/adsy_pro_badge.dart';

/// A scrolling text widget for long usernames that don't fit in the AppBar.
class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const MarqueeText({
    super.key,
    required this.text,
    required this.style,
  });

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> {
  late ScrollController _scrollController;
  Timer? _scrollTimer;
  bool _isScrollingForward = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted || !_scrollController.hasClients) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;

      if (maxScroll <= 0) return;

      if (_isScrollingForward) {
        if (currentScroll >= maxScroll) {
          _isScrollingForward = false;
          _scrollTimer?.cancel();
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) _startAutoScroll();
          });
        } else {
          _scrollController.jumpTo(currentScroll + 0.5);
        }
      } else {
        if (currentScroll <= 0) {
          _isScrollingForward = true;
          _scrollTimer?.cancel();
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) _startAutoScroll();
          });
        } else {
          _scrollController.jumpTo(currentScroll - 0.5);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(widget.text, style: widget.style, maxLines: 1),
    );
  }
}

/// Standalone AppBar for the AdsyConnect chat screen.
///
/// Accepts all display state as constructor params and uses callbacks
/// for user interactions, keeping the main state class clean.
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final String? userAvatar;
  final String userId;
  final bool isVerified;
  final bool isPro;
  final bool isOnline;
  final bool isTyping;

  /// Pre-formatted "last seen …" string (e.g. "Last seen 2h ago").
  final String lastSeenLabel;
  final bool blockedByMe;

  /// When true, a muted (crossed-out) bell is shown next to the name so the
  /// user knows notifications for this chat are silenced.
  final bool isMuted;

  // Search mode
  final bool isSearchMode;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final String searchQuery;
  final int searchMatchCount;
  final int currentMatchPosition;

  // Callbacks
  final VoidCallback onBack;
  final VoidCallback onCloseSearch;
  final VoidCallback onPrevMatch;
  final VoidCallback onNextMatch;
  final VoidCallback onViewProfile;
  final void Function(String callType) onStartCall;
  final void Function(String action) onMenuAction;

  const ChatAppBar({
    super.key,
    required this.userName,
    this.userAvatar,
    required this.userId,
    this.isVerified = false,
    this.isPro = false,
    required this.isOnline,
    required this.isTyping,
    required this.lastSeenLabel,
    required this.blockedByMe,
    this.isMuted = false,
    required this.isSearchMode,
    required this.searchController,
    required this.searchFocusNode,
    required this.searchQuery,
    required this.searchMatchCount,
    required this.currentMatchPosition,
    required this.onBack,
    required this.onCloseSearch,
    required this.onPrevMatch,
    required this.onNextMatch,
    required this.onViewProfile,
    required this.onStartCall,
    required this.onMenuAction,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    // Concept design: clean white bar, dark ink icons, hairline divider.
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      shape: const Border(
        bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
      ),
      leadingWidth: 40,
      leading: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: Color(0xFF111827), size: 22),
          onPressed: () {
            if (isSearchMode) {
              onCloseSearch();
              return;
            }
            FocusManager.instance.primaryFocus?.unfocus();
            onBack();
          },
          padding: EdgeInsets.zero,
        ),
      ),
      titleSpacing: 0,
      title: isSearchMode ? _buildSearchField() : _buildTitleRow(context),
      actions: isSearchMode ? _buildSearchActions() : _buildNormalActions(),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: searchController,
      focusNode: searchFocusNode,
      style: const TextStyle(
        color: Color(0xFF111827),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search messages',
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.only(right: 8, top: 12, bottom: 12),
      ),
    );
  }

  Widget _buildTitleRow(BuildContext context) {
    return GestureDetector(
      onTap: onViewProfile,
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 10),
          Expanded(child: _buildUserInfo()),
          // Muted indicator — a crossed-out bell so the user understands why
          // this chat is silent. Sits at the right edge of the name area.
          if (isMuted) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_off_rounded,
                size: 16,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final avatarUrl = AppConfig.getAbsoluteUrl(userAvatar ?? '');
    return Stack(
      children: [
        Container(
          width: 40 * adsyIosBoxScale(),
          height: 40 * adsyIosBoxScale(),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFF1F5F9),
          ),
          clipBehavior: Clip.antiAlias,
          child: avatarUrl.isNotEmpty
              ? Image.network(
                  avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _initials(),
                )
              : _initials(),
        ),
        if (isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _initials() {
    return Center(
      child: Text(
        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Color(0xFF334155),
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildNameRow(),
        const SizedBox(height: 2),
        _buildStatusRow(),
      ],
    );
  }

  Widget _buildNameRow() {
    final badgeWidth = (isVerified ? 21.0 : 0.0) + (isPro ? 35.0 : 0.0);
    return Row(
      children: [
        // Flexible(loose) — with Expanded a short name still claimed the
        // full row width, shoving the verified/PRO badges to the far right
        // edge instead of sitting next to the name.
        Flexible(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textPainter = TextPainter(
                text: TextSpan(
                  text: userName,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700),
                ),
                maxLines: 1,
                textDirection: TextDirection.ltr,
              )..layout();

              final availableWidth = constraints.maxWidth - badgeWidth;
              final needsScroll = textPainter.width > availableWidth;

              const nameStyle = TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
                letterSpacing: -0.3,
              );

              if (needsScroll) {
                return SizedBox(
                  height: 22,
                  child: MarqueeText(text: userName, style: nameStyle),
                );
              }
              return Text(
                userName,
                style: nameStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
        ),
        if (isVerified) ...[
          const SizedBox(width: 4),
          const Icon(Icons.verified, size: 15, color: Color(0xFF2563EB)),
        ],
        if (isPro) ...[
          const SizedBox(width: 4),
          const AdsyProBadge(),
        ],
      ],
    );
  }

  Widget _buildStatusRow() {
    return Text(
      isTyping
          ? 'Typing...'
          : isOnline
              ? 'Online'
              : lastSeenLabel,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: isTyping
            ? const Color(0xFF16A34A)
            : isOnline
                ? const Color(0xFF16A34A)
                : const Color(0xFF94A3B8),
      ),
    );
  }

  List<Widget> _buildSearchActions() {
    final hasMatches = searchMatchCount > 0;
    return [
      if (searchQuery.trim().isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Center(
            child: Text(
              hasMatches
                  ? '${currentMatchPosition + 1}/$searchMatchCount'
                  : '0/0',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      IconButton(
        onPressed: hasMatches ? onPrevMatch : null,
        icon: const Icon(Icons.keyboard_arrow_up_rounded,
            color: Color(0xFF111827), size: 22),
      ),
      IconButton(
        onPressed: hasMatches ? onNextMatch : null,
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF111827), size: 22),
      ),
      IconButton(
        onPressed: onCloseSearch,
        icon: const Icon(Icons.close_rounded,
            color: Color(0xFF111827), size: 20),
      ),
    ];
  }

  List<Widget> _buildNormalActions() {
    return [
      IconButton(
        onPressed: () => onStartCall('video'),
        icon: const Icon(Icons.videocam_outlined,
            color: Color(0xFF111827), size: 24),
      ),
      IconButton(
        onPressed: () => onStartCall('audio'),
        icon: const Icon(Icons.call_outlined,
            color: Color(0xFF111827), size: 22),
      ),
      Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.more_vert_rounded,
              color: Color(0xFF111827), size: 24),
          onPressed: () => _showActionMenu(ctx),
        ),
      ),
    ];
  }

  void _showActionMenu(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    final overlayState = Overlay.maybeOf(context, rootOverlay: true);
    final overlayBox = overlayState?.context.findRenderObject() as RenderBox?;

    if (box == null || overlayState == null || overlayBox == null) return;

    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    final overlaySize = overlayBox.size;
    const menuWidth = 206.0;
    const margin = 8.0;
    final left = (topLeft.dx + box.size.width - menuWidth)
        .clamp(margin, overlaySize.width - menuWidth - margin)
        .toDouble();
    final top = (topLeft.dy + box.size.height + 6)
        .clamp(margin, overlaySize.height - 236)
        .toDouble();

    OverlayEntry? entry;
    void close() {
      entry?.remove();
      entry = null;
    }

    entry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: close,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            top: top,
            left: left,
            width: menuWidth,
            child: Material(
              color: Colors.transparent,
              child: _buildActionMenuSurface(close),
            ),
          ),
        ],
      ),
    );

    overlayState.insert(entry!);
  }

  Widget _buildActionMenuSurface(VoidCallback close) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _menuItem(
            close: close,
            value: 'search',
            icon: Icons.search_rounded,
            label: 'Search messages',
            iconColor: const Color(0xFF334155),
          ),
          _menuItem(
            close: close,
            value: 'view_profile',
            icon: Icons.person_rounded,
            label: 'View ABN Profile',
            iconColor: const Color(0xFF334155),
          ),
          _menuItem(
            close: close,
            value: 'clear_chat',
            icon: Icons.cleaning_services_rounded,
            label: 'Clear messages',
            iconColor: const Color(0xFF334155),
          ),
          _menuItem(
            close: close,
            value: blockedByMe ? 'unblock' : 'block',
            icon: blockedByMe ? Icons.lock_open_rounded : Icons.block_rounded,
            label: blockedByMe ? 'Unblock' : 'Block',
            iconColor:
                blockedByMe ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
          ),
          _menuItem(
            close: close,
            value: 'report',
            icon: Icons.flag_rounded,
            label: 'Report',
            iconColor: const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required VoidCallback close,
    required String value,
    required IconData icon,
    required String label,
    required Color iconColor,
  }) {
    return InkWell(
      onTap: () {
        close();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onMenuAction(value);
        });
      },
      child: SizedBox(
        height: 48,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: Icon(icon, size: 19, color: iconColor),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
