import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/app_config.dart';

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
    return AppBar(
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF3B82F6).withOpacity(0.95),
              const Color(0xFF6366F1).withOpacity(0.95),
              const Color(0xFF8B5CF6).withOpacity(0.95),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      leadingWidth: 40,
      leading: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: Colors.white, size: 22),
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
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search messages',
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.7),
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
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final avatarUrl = AppConfig.getAbsoluteUrl(userAvatar ?? '');
    return Stack(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.white.withOpacity(0.3), width: 2),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
              ),
            ),
            child: avatarUrl.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _initials(),
                    ),
                  )
                : _initials(),
          ),
        ),
        if (isOnline)
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
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
          color: Colors.white,
          fontSize: 16,
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
    final badgeWidth = (isVerified ? 19.0 : 0.0) + (isPro ? 35.0 : 0.0);
    return Row(
      children: [
        Expanded(
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
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.3,
                shadows: [
                  Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 1),
                      blurRadius: 2),
                ],
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
          const Icon(Icons.verified, size: 15, color: Color(0xFF3B82F6)),
        ],
        if (isPro) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
              ),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Text(
              'PRO',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusRow() {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOnline ? const Color(0xFF10B981) : Colors.grey.shade400,
            boxShadow: isOnline
                ? [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          isTyping
              ? 'Typing...'
              : isOnline
                  ? 'Online'
                  : lastSeenLabel,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isTyping
                ? const Color(0xFF93C5FD)
                : isOnline
                    ? const Color(0xFF10B981)
                    : Colors.white.withOpacity(0.7),
          ),
        ),
      ],
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
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      IconButton(
        onPressed: hasMatches ? onPrevMatch : null,
        icon: const Icon(Icons.keyboard_arrow_up_rounded,
            color: Colors.white, size: 22),
      ),
      IconButton(
        onPressed: hasMatches ? onNextMatch : null,
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: Colors.white, size: 22),
      ),
      IconButton(
        onPressed: onCloseSearch,
        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
      ),
    ];
  }

  List<Widget> _buildNormalActions() {
    return [
      IconButton(
        onPressed: () => onStartCall('audio'),
        icon: const Icon(Icons.call_rounded, color: Colors.white, size: 24),
      ),
      IconButton(
        onPressed: () => onStartCall('video'),
        icon: const Icon(Icons.videocam_rounded, color: Colors.white, size: 26),
      ),
      Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.more_vert_rounded,
              color: Colors.white, size: 24),
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
            iconColor: const Color(0xFF3B82F6),
          ),
          _menuItem(
            close: close,
            value: 'view_profile',
            icon: Icons.person_rounded,
            label: 'View ABN Profile',
            iconColor: const Color(0xFF3B82F6),
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
