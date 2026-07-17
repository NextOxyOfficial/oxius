import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/app_config.dart';
import '../services/adsyconnect_service.dart';
import '../services/user_search_service.dart';
import '../widgets/common/adsy_loading.dart';
import '../widgets/common/adsy_toast.dart';

/// Create a new AdsyConnect group: photo, name, and members.
/// Candidates load PAGED from existing chats (20 at a time, infinite scroll);
/// typing in the search box surfaces any user on the platform.
/// Pops the created group map on success.
class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _search = TextEditingController();
  final ScrollController _listScroll = ScrollController();
  final Map<String, Map<String, dynamic>> _selected = {};

  // Paged chat-derived candidates.
  final List<Map<String, dynamic>> _chatCandidates = [];
  int _chatPage = 0;
  bool _hasMoreChats = true;
  bool _loadingChats = false;

  // Search results (all users) while a query is typed.
  List<Map<String, dynamic>> _searchResults = [];
  bool _searching = false;
  int _seq = 0;

  bool _creating = false;
  String? _imagePath;

  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearchChanged);
    _listScroll.addListener(_onScroll);
    _loadMoreChats();
  }

  @override
  void dispose() {
    _name.dispose();
    _search.dispose();
    _listScroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_search.text.trim().isNotEmpty) return; // search mode: no paging
    if (_listScroll.position.pixels >=
        _listScroll.position.maxScrollExtent - 160) {
      _loadMoreChats();
    }
  }

  // Load the next page of chat partners — keeps the screen light instead of
  // pulling every user at once.
  Future<void> _loadMoreChats() async {
    if (_loadingChats || !_hasMoreChats) return;
    setState(() => _loadingChats = true);
    try {
      final page = _chatPage + 1;
      final rooms = await AdsyConnectService.getChatRooms(
          page: page, pageSize: _pageSize);
      if (!mounted) return;
      final existing = _chatCandidates.map((c) => c['id']).toSet();
      final fresh = rooms.map<Map<String, dynamic>>((r) {
        final u = r['other_user'] ?? {};
        final name = [
          (u['first_name'] ?? '').toString(),
          (u['last_name'] ?? '').toString(),
        ].where((s) => s.isNotEmpty).join(' ');
        return {
          'id': (u['id'] ?? '').toString(),
          'name':
              name.isNotEmpty ? name : (u['username'] ?? 'User').toString(),
          'avatar': u['avatar'] ?? u['image'],
        };
      }).where(
          (u) => (u['id'] as String).isNotEmpty && !existing.contains(u['id']));
      setState(() {
        _chatCandidates.addAll(fresh);
        _chatPage = page;
        _hasMoreChats = rooms.length >= _pageSize;
        _loadingChats = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingChats = false);
    }
  }

  void _onSearchChanged() {
    final q = _search.text.trim();
    if (q.isEmpty) {
      setState(() {
        _searchResults = [];
        _searching = false;
      });
      return;
    }
    final seq = ++_seq;
    setState(() => _searching = true);
    UserSearchService.searchUsers(q).then((users) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _searchResults = users
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

  List<Map<String, dynamic>> get _visible =>
      _search.text.trim().isEmpty ? _chatCandidates : _searchResults;

  Future<void> _pickPhoto() async {
    try {
      final picked = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked != null && mounted) {
        setState(() => _imagePath = picked.path);
      }
    } catch (_) {
      if (mounted) AdsyToast.error(context, 'ছবি নেওয়া যায়নি');
    }
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      AdsyToast.warning(context, 'গ্রুপের নাম দিন');
      return;
    }
    if (_selected.isEmpty) {
      AdsyToast.warning(context, 'অন্তত একজন মেম্বার বাছাই করুন');
      return;
    }
    setState(() => _creating = true);
    final group = await AdsyConnectService.createGroup(
      name: name,
      memberIds: _selected.keys.toList(),
      imagePath: _imagePath,
    );
    if (!mounted) return;
    setState(() => _creating = false);
    if (group != null) {
      AdsyToast.success(context, 'গ্রুপ তৈরি হয়েছে');
      Navigator.of(context).pop(group);
    } else {
      AdsyToast.error(context, 'গ্রুপ তৈরি করা যায়নি');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF334155)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('নতুন গ্রুপ',
            style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 17,
                fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // ── Group identity card ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(
              children: [
                InkWell(
                  onTap: _pickPhoto,
                  borderRadius: BorderRadius.circular(32),
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEFF6FF),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _imagePath != null
                        ? Image.file(File(_imagePath!), fit: BoxFit.cover)
                        : const Icon(Icons.add_a_photo_outlined,
                            size: 22, color: Color(0xFF3B82F6)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _name,
                    maxLength: 80,
                    style: const TextStyle(
                        fontSize: 15.5, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'গ্রুপের নাম দিন',
                      hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w400),
                      counterText: '',
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF2563EB), width: 1.3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // ── Members section ──
          Expanded(
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Row(
                      children: [
                        const Text('মেম্বার',
                            style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A))),
                        const SizedBox(width: 6),
                        if (_selected.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text('${_selected.length} জন',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2563EB))),
                          ),
                      ],
                    ),
                  ),
                  if (_selected.isNotEmpty)
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        children: _selected.values
                            .map((u) => Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Chip(
                                    label: Text(u['name'].toString(),
                                        style:
                                            const TextStyle(fontSize: 12)),
                                    deleteIcon:
                                        const Icon(Icons.close, size: 15),
                                    onDeleted: () => setState(() =>
                                        _selected
                                            .remove(u['id'].toString())),
                                    backgroundColor: const Color(0xFFEFF6FF),
                                    side: const BorderSide(
                                        color: Color(0xFFDBEAFE)),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                    child: TextField(
                      controller: _search,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded,
                            color: Colors.grey.shade500, size: 20),
                        hintText: 'মেম্বার সার্চ করুন',
                        hintStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 14),
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 11),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF2563EB), width: 1.3),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _searching
                        ? const Center(child: AdsyLoadingIndicator())
                        : _visible.isEmpty
                            ? Center(
                                child: _loadingChats
                                    ? const AdsyLoadingIndicator()
                                    : Text('কেউ পাওয়া যায়নি',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600)),
                              )
                            : ListView.builder(
                                controller: _listScroll,
                                itemCount: _visible.length +
                                    (_loadingChats ? 1 : 0),
                                itemBuilder: (_, i) {
                                  if (i >= _visible.length) {
                                    return const Padding(
                                      padding: EdgeInsets.all(14),
                                      child: Center(
                                          child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child:
                                                  AdsyLoadingIndicator())),
                                    );
                                  }
                                  return _candidateTile(_visible[i]);
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
          // ── Fixed create button ──
          SafeArea(
            top: false,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _creating ? null : _create,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    disabledBackgroundColor: const Color(0xFF93C5FD),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13)),
                  ),
                  icon: _creating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white)))
                      : const Icon(Icons.group_add_outlined, size: 19),
                  label: Text(
                      _creating
                          ? 'তৈরি হচ্ছে…'
                          : _selected.isEmpty
                              ? 'গ্রুপ তৈরি করুন'
                              : 'গ্রুপ তৈরি করুন (${_selected.length} জন)',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _candidateTile(Map<String, dynamic> u) {
    final id = u['id'].toString();
    final sel = _selected.containsKey(id);
    final avatar = AppConfig.getAbsoluteUrl((u['avatar'] ?? '').toString());
    final name = u['name'].toString();
    return ListTile(
      onTap: () => setState(() {
        if (sel) {
          _selected.remove(id);
        } else {
          _selected[id] = u;
        }
      }),
      leading: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
            shape: BoxShape.circle, color: Color(0xFFEFF6FF)),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        // Dynamic profile photo with a letter fallback (same as chat list).
        child: avatar.isNotEmpty
            ? Image.network(avatar,
                fit: BoxFit.cover,
                width: 44,
                height: 44,
                errorBuilder: (_, __, ___) => _initial(name))
            : _initial(name),
      ),
      title: Text(name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:
              const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
      trailing: Icon(
        sel ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
        color: sel ? const Color(0xFF2563EB) : Colors.grey.shade400,
        size: 22,
      ),
    );
  }

  Widget _initial(String name) => Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
            color: Color(0xFF3B82F6),
            fontSize: 16,
            fontWeight: FontWeight.w700),
      );
}
