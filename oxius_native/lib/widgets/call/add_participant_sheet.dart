import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/adsyconnect_service.dart';

/// Picks who to pull into a call that is already running.
///
/// The list is the user's recent conversations rather than a full contact
/// search: the person you want mid-call is almost always someone you were
/// already talking to, and a search field is a lot to ask of someone holding a
/// phone to their ear.
class AddParticipantSheet extends StatefulWidget {
  const AddParticipantSheet({super.key, required this.excludedUserIds});

  /// People already in the call. Showing them would only invite a tap that
  /// the server answers with "already_in_call".
  final Set<String> excludedUserIds;

  /// Returns the selected user ids, or null if the sheet was dismissed.
  static Future<List<String>?> show(
    BuildContext context, {
    required Set<String> excludedUserIds,
  }) {
    return showModalBottomSheet<List<String>>(
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

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final rooms = await AdsyConnectService.getChatRooms(pageSize: 40);
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
                    : () => Navigator.pop(context, _selected.toList()),
                child: Text(
                  _selected.isEmpty
                      ? 'কাউকে বাছুন'
                      : '${_selected.length} জনকে যোগ করুন',
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

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _contacts.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: Colors.white.withValues(alpha: 0.06),
      ),
      itemBuilder: (context, index) {
        final contact = _contacts[index];
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
