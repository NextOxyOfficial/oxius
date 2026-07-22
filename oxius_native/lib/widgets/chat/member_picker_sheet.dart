import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../services/adsyconnect_service.dart';
import '../../services/user_search_service.dart';
import '../common/adsy_loading.dart';

/// Search-and-select users bottom sheet; pops the selected user-id list.
/// Used for adding members to an existing group.
class MemberPickerSheet extends StatefulWidget {
  const MemberPickerSheet({super.key});

  @override
  State<MemberPickerSheet> createState() => _MemberPickerSheetState();
}

class _MemberPickerSheetState extends State<MemberPickerSheet> {
  final TextEditingController _search = TextEditingController();
  final Map<String, Map<String, dynamic>> _selected = {};
  List<Map<String, dynamic>> _results = [];
  // People you already chat with — shown BEFORE any search so known faces
  // are one tap away (searching a common name floods with strangers).
  List<Map<String, dynamic>> _recent = [];
  bool _loadingRecent = true;
  bool _searching = false;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    _search.addListener(_onChanged);
    _loadRecentPartners();
  }

  Future<void> _loadRecentPartners() async {
    try {
      final rooms = await AdsyConnectService.getChatRooms(page: 1, pageSize: 30);
      if (!mounted) return;
      final seen = <String>{};
      final recent = <Map<String, dynamic>>[];
      for (final r in rooms) {
        if (r['is_group'] == true) continue;
        final u = r['other_user'] ?? {};
        final id = (u['id'] ?? '').toString();
        if (id.isEmpty || seen.contains(id)) continue;
        seen.add(id);
        final name = [
          (u['first_name'] ?? '').toString(),
          (u['last_name'] ?? '').toString(),
        ].where((s) => s.isNotEmpty).join(' ');
        recent.add({
          'id': id,
          'name': name.isNotEmpty ? name : (u['username'] ?? 'User').toString(),
          'avatar': u['avatar'] ?? u['image'],
        });
      }
      setState(() {
        _recent = recent;
        _loadingRecent = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingRecent = false);
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _onChanged() {
    final q = _search.text.trim();
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _searching = false;
      });
      return;
    }
    final seq = ++_seq;
    setState(() => _searching = true);
    UserSearchService.searchUsers(q).then((users) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _results = users
            .map((u) => {
                  'id': u.id,
                  'name': u.name.isNotEmpty ? u.name : (u.username ?? 'User'),
                  'avatar': u.image ?? u.avatar,
                })
            .toList();
        _searching = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 10),
              const Text('মেম্বার সিলেক্ট  করুন',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded,
                        color: Colors.grey.shade500, size: 20),
                    hintText: 'নাম দিয়ে সার্চ করুন',
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                ),
              ),
              Flexible(
                child: Builder(builder: (context) {
                  final searchMode = _search.text.trim().isNotEmpty;
                  // No query → known people (recent chat partners) up front.
                  final list = searchMode ? _results : _recent;
                  final busy = searchMode ? _searching : _loadingRecent;
                  if (busy) {
                    return const Padding(
                        padding: EdgeInsets.all(20),
                        child: AdsyLoadingIndicator());
                  }
                  if (list.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(22),
                      child: Text(
                          searchMode
                              ? 'কেউ পাওয়া যায়নি'
                              : 'নাম লিখে সার্চ করুন',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade600)),
                    );
                  }
                  return ListView.builder(
                            shrinkWrap: true,
                            itemCount: list.length + (searchMode ? 0 : 1),
                            itemBuilder: (_, index) {
                              if (!searchMode && index == 0) {
                                return const Padding(
                                  padding: EdgeInsets.fromLTRB(16, 8, 16, 2),
                                  child: Text('আপনার পরিচিতরা',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF94A3B8),
                                          letterSpacing: 0.3)),
                                );
                              }
                              final i = searchMode ? index : index - 1;
                              final u = list[i];
                              final id = u['id'].toString();
                              final sel = _selected.containsKey(id);
                              final avatar = AppConfig.getAbsoluteUrl(
                                  (u['avatar'] ?? '').toString());
                              final name = u['name'].toString();
                              return ListTile(
                                dense: true,
                                leading: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFEFF6FF)),
                                  clipBehavior: Clip.antiAlias,
                                  alignment: Alignment.center,
                                  child: avatar.isNotEmpty
                                      ? Image.network(avatar,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _initial(name))
                                      : _initial(name),
                                ),
                                title: Text(name,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                                trailing: Icon(
                                  sel
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked,
                                  color: sel
                                      ? const Color(0xFF2563EB)
                                      : Colors.grey.shade400,
                                ),
                                onTap: () => setState(() {
                                  if (sel) {
                                    _selected.remove(id);
                                  } else {
                                    _selected[id] = u;
                                  }
                                }),
                              );
                            },
                          );
                }),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () =>
                            Navigator.pop(context, _selected.keys.toList()),
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB)),
                    child: Text('যোগ করুন (${_selected.length})'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _initial(String name) => Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
            color: Color(0xFF3B82F6), fontWeight: FontWeight.w700),
      );
}
