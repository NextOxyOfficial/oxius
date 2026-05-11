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
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
          onPressed: () {
            if (isSearchMode) {
              onCloseSearch();
              return;
            }
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.pop(context);
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
      onTap: () => Navigator.pushNamed(
        context,
        '/business-network/profile',
        arguments: {'userId': userId},
      ),
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
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
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
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                maxLines: 1,
                textDirection: TextDirection.ltr,
              )..layout();

              final availableWidth = constraints.maxWidth - badgeWidth;
              final needsScroll = textPainter.width > availableWidth;

              const nameStyle = TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.3,
                shadows: [
                  Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 2),
                ],
              );

              if (needsScroll) {
                return SizedBox(
                  height: 20,
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
            fontSize: 11,
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
        icon: const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white, size: 22),
      ),
      IconButton(
        onPressed: hasMatches ? onNextMatch : null,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 22),
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
        icon: const Icon(Icons.call_rounded, color: Colors.white, size: 20),
      ),
      IconButton(
        onPressed: () => onStartCall('video'),
        icon: const Icon(Icons.videocam_rounded, color: Colors.white, size: 22),
      ),
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
        offset: const Offset(0, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder: (context) => [
          _menuItem('search', Icons.search_rounded, 'Search messages', const Color(0xFF3B82F6)),
          _menuItem('view_profile', Icons.person_rounded, 'View ABN Profile', const Color(0xFF3B82F6)),
          _menuItem(
            blockedByMe ? 'unblock' : 'block',
            blockedByMe ? Icons.lock_open_rounded : Icons.block_rounded,
            blockedByMe ? 'Unblock' : 'Block',
            blockedByMe ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
          ),
          _menuItem('report', Icons.flag_rounded, 'Report', const Color(0xFFEF4444)),
        ],
        onSelected: onMenuAction,
      ),
    ];
  }

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label,
    Color iconColor,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
