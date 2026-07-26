import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../screens/business_network/profile_screen.dart';
import '../../services/adsyconnect_service.dart';
import '../common/adsy_loading.dart';
import '../common/adsy_pro_badge.dart';

/// Who reacted to a message — opened by tapping the reaction chips under a
/// bubble (1:1 and group both).
///
/// Filter tabs across the top ("All" + one per emoji) mirror what every
/// messenger does. Rows carry the same verified/Pro badges the rest of the app
/// uses and open the person's Business Network profile.
class MessageReactorsSheet extends StatefulWidget {
  final String messageId;
  final bool isGroup;

  const MessageReactorsSheet({
    super.key,
    required this.messageId,
    this.isGroup = false,
  });

  static Future<void> show(
    BuildContext context, {
    required String messageId,
    bool isGroup = false,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MessageReactorsSheet(
        messageId: messageId,
        isGroup: isGroup,
      ),
    );
  }

  @override
  State<MessageReactorsSheet> createState() => _MessageReactorsSheetState();
}

class _MessageReactorsSheetState extends State<MessageReactorsSheet> {
  List<dynamic> _rows = const [];
  bool _loading = true;
  // null = the "All" tab.
  String? _emojiFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await AdsyConnectService.fetchMessageReactors(
      widget.messageId,
      isGroup: widget.isGroup,
    );
    if (!mounted) return;
    setState(() {
      _rows = rows ?? const [];
      _loading = false;
    });
  }

  /// Emoji in the order the chips show them — most-reacted first.
  List<MapEntry<String, int>> get _tabs {
    final counts = <String, int>{};
    for (final r in _rows) {
      final e = (r as Map)['emoji']?.toString() ?? '';
      if (e.isEmpty) continue;
      counts[e] = (counts[e] ?? 0) + 1;
    }
    final list = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  List<dynamic> get _visible => _emojiFilter == null
      ? _rows
      : _rows
          .where((r) => (r as Map)['emoji']?.toString() == _emojiFilter)
          .toList();

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.7;
    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: AdsyLoadingIndicator(),
            )
          else if (_rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Text(
                'এখনো কেউ রিঅ্যাক্ট করেননি',
                style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              ),
            )
          else ...[
            _tabRow(),
            const Divider(height: 1, color: Color(0xFFEEF2F6)),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: _visible.length,
                itemBuilder: (_, i) => _row(_visible[i] as Map),
              ),
            ),
          ],
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _tabRow() {
    final tabs = _tabs;
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _tab(label: 'সব ${_rows.length}', selected: _emojiFilter == null,
              onTap: () => setState(() => _emojiFilter = null)),
          for (final t in tabs)
            _tab(
              label: '${t.key} ${t.value}',
              selected: _emojiFilter == t.key,
              onTap: () => setState(() => _emojiFilter = t.key),
            ),
        ],
      ),
    );
  }

  Widget _tab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEFF6FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(Map r) {
    final uid = r['user_id']?.toString() ?? '';
    final name = r['name']?.toString() ?? '';
    final avatar = AppConfig.getAbsoluteUrl(r['image']?.toString() ?? '');
    return InkWell(
      onTap: uid.isEmpty
          ? null
          : () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen(userId: uid)),
              );
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        child: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: const Color(0xFFEFF6FF),
              backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
              child: avatar.isEmpty
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  if (r['is_verified'] == true) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified,
                        size: 15, color: Color(0xFF3B82F6)),
                  ],
                  if (r['is_pro'] == true) ...[
                    const SizedBox(width: 4),
                    const AdsyProBadge(fontSize: 9),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(r['emoji']?.toString() ?? '',
                style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
