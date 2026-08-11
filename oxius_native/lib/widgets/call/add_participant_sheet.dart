import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/adsyconnect_service.dart';

/// Picks who to pull into a call that is already running.
///
/// The list is the user's own conversations, and the search box filters that
/// list — it never queries the directory. That is the whole point: anyone
/// reachable here is somebody the user has already exchanged messages with,
/// so the feature cannot be turned into a way to ring strangers. A global
/// people-search behind an "add to call" button is a spam tool with extra
/// steps.
///
/// Recent conversations come first, so the person wanted mid-call is usually
/// already on screen and the search box is there for the times they are not.
class AddParticipantSheet extends StatefulWidget {
  const AddParticipantSheet({super.key, required this.excludedUserIds});

  /// People already in the call. Showing them would only invite a tap that
  /// the server answers with "already_in_call".
  final Set<String> excludedUserIds;

  /// Returns the selected contacts as {id, name, avatar}, or null if the
  /// sheet was dismissed.
  ///
  /// The names come back with the ids because the caller needs them and this
  /// is the only place that has them — the invite endpoint answers with user
  /// ids and a status, so a roster built from that alone could only count
  /// people, not name them.
  static Future<List<Map<String, dynamic>>?> show(
    BuildContext context, {
    required Set<String> excludedUserIds,
  }) {
    return showModalBottomSheet<List<Map<String, dynamic>>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AddParticipantSheet(excludedUserIds: excludedUserIds),
    );
  }

  @override
  State<AddParticipantSheet> createState() => _AddParticipantSheetState();
}

class _AddParticipantSheetState extends State<AddParticipantSheet> {
  final Set<String> _selected = <String>{};
  List<Map<String, dynamic>> _contacts = const [];
  bool _loading = true;

  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final next = _searchController.text.trim().toLowerCase();
      if (next == _query) return;
      setState(() => _query = next);
    });
    unawaited(_load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// The conversations matching what has been typed.
  ///
  /// Filtered in memory over the list already fetched, which is what keeps
  /// this a search of the user's own contacts rather than of everyone.
  List<Map<String, dynamic>> get _visible {
    if (_query.isEmpty) return _contacts;
    return _contacts
        .where((contact) =>
            (contact['name'] as String).toLowerCase().contains(_query))
        .toList();
  }

  Future<void> _load() async {
    try {
      // Larger than the list can show, because the search box reaches past
      // what fits on screen and a contact missing from the page is a contact
      // the user cannot find at all.
      final rooms = await AdsyConnectService.getChatRooms(pageSize: 200);
      final contacts = <Map<String, dynamic>>[];
      final seen = <String>{};
      for (final room in rooms) {
        if (room is! Map) continue;
        final other = room['other_user'];
        if (other is! Map) continue;
        final id = other['id']?.toString() ?? '';
        // A deactivated account cannot answer, so it has no business being
        // offered as someone to add.
        if (id.isEmpty ||
            seen.contains(id) ||
            widget.excludedUserIds.contains(id) ||
            other['is_active'] == false ||
            other['is_suspended'] == true) {
          continue;
        }
        seen.add(id);
        contacts.add({
          'id': id,
          'name': _displayName(other),
          'avatar': other['avatar']?.toString() ?? '',
        });
      }
      if (!mounted) return;
      setState(() {
        _contacts = contacts;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  static String _displayName(Map<dynamic, dynamic> user) {
    final first = user['first_name']?.toString().trim() ?? '';
    final last = user['last_name']?.toString().trim() ?? '';
    final joined = [first, last].where((part) => part.isNotEmpty).join(' ');
    if (joined.isNotEmpty) return joined;
    final name = user['name']?.toString().trim() ?? '';
    if (name.isNotEmpty) return name;
    final username = user['username']?.toString().trim() ?? '';
    if (username.contains('@')) return username.split('@').first;
    return username.isNotEmpty ? username : 'AdsyClub user';
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Container(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.72),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: media.padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Row(
              children: [
                Text(
                  'Add to call',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (!_loading && _contacts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 14.5),
                cursorColor: const Color(0xFF34D399),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Search your chats',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.38),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 19, color: Colors.white.withValues(alpha: 0.5)),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: Icon(Icons.close_rounded,
                              size: 18,
                              color: Colors.white.withValues(alpha: 0.6)),
                          onPressed: _searchController.clear,
                        ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          Flexible(child: _buildBody()),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF34D399),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _selected.isEmpty
                    ? null
                    : () => Navigator.pop(
                          context,
                          _contacts
                              .where((c) => _selected.contains(c['id']))
                              .toList(),
                        ),
                child: Text(
                  _selected.isEmpty
                      ? 'Select people'
                      : 'Add ${_selected.length}',
                  style: const TextStyle(
                    color: Color(0xFF04231A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_contacts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Text(
          'No one available to add.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final visible = _visible;
    if (visible.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Text(
          // Says WHY, so a blank result does not read as a broken search.
          'No match. You can only add people you have chatted with.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: visible.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: Colors.white.withValues(alpha: 0.06),
      ),
      itemBuilder: (context, index) {
        final contact = visible[index];
        final id = contact['id'] as String;
        final avatar = contact['avatar'] as String;
        final picked = _selected.contains(id);

        return ListTile(
          onTap: () => setState(() {
            if (!_selected.remove(id)) _selected.add(id);
          }),
          leading: CircleAvatar(
            radius: 21,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
            child: avatar.isEmpty
                ? const Icon(Icons.person_rounded, color: Colors.white70)
                : null,
          ),
          title: Text(
            contact['name'] as String,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          trailing: Icon(
            picked
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: picked
                ? const Color(0xFF34D399)
                : Colors.white.withValues(alpha: 0.28),
          ),
        );
      },
    );
  }
}
