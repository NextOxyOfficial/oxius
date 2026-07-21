import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/app_config.dart';
import '../services/adsyconnect_service.dart';
import '../services/user_search_service.dart';
import '../widgets/common/adsy_loading.dart';
import '../widgets/common/adsy_pro_badge.dart';
import '../widgets/common/adsy_toast.dart';

/// Create a new AdsyConnect group.
///
/// Layout (Messenger-style): a centered identity header — big photo picker
/// with a camera badge and the name field right under it — then the member
/// picker: pill search, horizontally-scrolling selected avatars (tap ✕ to
/// remove), and a paged candidate list (20/page infinite scroll from existing
/// chats; typing searches every user). Fixed CTA at the bottom.
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
  // Concept UI: name shows as text + pen, search collapses to an icon.
  bool _editingName = false;
  bool _memberSearchOpen = false;
  int _seq = 0;

  bool _creating = false;
  String? _imagePath;

  static const int _pageSize = 20;
  static const Color _blue = Color(0xFF111827);

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
          'isVerified': u['kyc'] == true || u['is_verified'] == true,
          'isPro': u['is_pro'] == true,
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
                  'isVerified': u.isVerified,
                  'isPro': u.isPro,
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
      AdsyToast.warning(context, 'অন্তত একজন মেম্বার সিলেক্ট  করুন');
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF334155)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text('নতুন গ্রুপ',
            style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 17,
                fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              controller: _listScroll,
              slivers: [
                // ── Centered identity header ──
                SliverToBoxAdapter(child: _buildIdentityHeader()),
                // ── Selected member avatars ──
                if (_selected.isNotEmpty)
                  SliverToBoxAdapter(child: _buildSelectedRow()),
                // ── Members header: title + expanding chat-style search ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 8, 0),
                    child: Row(
                      children: [
                        const Text(
                          'মেম্বার',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 280),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) =>
                                  SizeTransition(
                                sizeFactor: animation,
                                axis: Axis.horizontal,
                                axisAlignment: 1,
                                child: FadeTransition(
                                    opacity: animation, child: child),
                              ),
                              child: _memberSearchOpen
                                  ? Container(
                                      key: const ValueKey(
                                          'member_search_open'),
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: TextField(
                                        controller: _search,
                                        autofocus: true,
                                        style: const TextStyle(
                                            fontSize: 13.5),
                                        textAlignVertical:
                                            TextAlignVertical.center,
                                        decoration: InputDecoration(
                                          hintText: 'মেম্বার সার্চ করুন',
                                          hintStyle: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 13),
                                          isDense: true,
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 10),
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(
                                      key: ValueKey('member_search_closed')),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _memberSearchOpen = !_memberSearchOpen;
                              if (!_memberSearchOpen) _search.clear();
                            });
                          },
                          icon: Icon(
                            _memberSearchOpen
                                ? Icons.close_rounded
                                : Icons.search_rounded,
                            color: const Color(0xFF64748B),
                            size: 21,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ── Section label ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 6, 22, 4),
                    child: Text(
                      _search.text.trim().isEmpty
                          ? 'আপনার রিসেন্ট চ্যাট একটিভিটি থেকে'
                          : 'সার্চ রেজাল্ট',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          color: Colors.grey.shade500),
                    ),
                  ),
                ),
                // ── Candidates ──
                if (_searching)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(26),
                      child: Center(child: AdsyLoadingIndicator()),
                    ),
                  )
                else if (_visible.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(26),
                      child: Center(
                        child: _loadingChats
                            ? const AdsyLoadingIndicator()
                            : Text('কেউ পাওয়া যায়নি',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600)),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        if (i >= _visible.length) {
                          return const Padding(
                            padding: EdgeInsets.all(14),
                            child: Center(
                                child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: AdsyLoadingIndicator())),
                          );
                        }
                        return _candidateTile(_visible[i]);
                      },
                      childCount: _visible.length + (_loadingChats ? 1 : 0),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            ),
          ),
          _buildBottomCta(),
        ],
      ),
    );
  }

  // Big centered photo picker with a camera badge; the group name shows as
  // text + edit pen — tapping the pen reveals a compact inline input.
  Widget _buildIdentityHeader() {
    final typedName = _name.text.trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Column(
        children: [
          InkWell(
            onTap: _pickPhoto,
            borderRadius: BorderRadius.circular(48),
            child: Stack(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _imagePath == null ? const Color(0xFFF1F5F9) : null,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _imagePath != null
                      ? Image.file(File(_imagePath!),
                          width: 96, height: 96, fit: BoxFit.cover)
                      : const Icon(Icons.groups_rounded,
                          size: 42, color: Color(0xFF334155)),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _blue,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_editingName)
            // Compact chat-style input, shown only while editing.
            TextField(
              controller: _name,
              autofocus: true,
              maxLength: 80,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              onSubmitted: (_) => setState(() => _editingName = false),
              onTapOutside: (_) {
                FocusManager.instance.primaryFocus?.unfocus();
                setState(() => _editingName = false);
              },
              decoration: InputDecoration(
                hintText: 'গ্রুপের নাম দিন',
                hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400),
                counterText: '',
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide.none,
                ),
              ),
            )
          else
            // Name as plain text + edit pen (concept-minimal).
            InkWell(
              onTap: () => setState(() => _editingName = true),
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        typedName.isEmpty ? 'গ্রুপের নাম দিন' : typedName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: typedName.isEmpty
                              ? FontWeight.w500
                              : FontWeight.w800,
                          color: typedName.isEmpty
                              ? Colors.grey.shade400
                              : const Color(0xFF111827),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit_rounded,
                          size: 13, color: Color(0xFF334155)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Selected members as avatar bubbles with a ✕ badge — wraps onto new
  // lines instead of a single horizontal slider.
  Widget _buildSelectedRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 6, 6),
      child: Wrap(
        runSpacing: 10,
        children: _selected.values.map((u) {
          final name = u['name'].toString();
          final avatar =
              AppConfig.getAbsoluteUrl((u['avatar'] ?? '').toString());
          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: SizedBox(
              width: 56,
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFEFF6FF),
                          border: Border.all(
                              color: _blue.withValues(alpha: 0.35),
                              width: 1.5),
                        ),
                        clipBehavior: Clip.antiAlias,
                        alignment: Alignment.center,
                        child: avatar.isNotEmpty
                            ? Image.network(avatar,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _initial(name))
                            : _initial(name),
                      ),
                      Positioned(
                        top: -4,
                        right: -4,
                        child: InkWell(
                          onTap: () => setState(
                              () => _selected.remove(u['id'].toString())),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF475569),
                              border:
                                  Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.close,
                                size: 11, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(name.split(' ').first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569))),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomCta() {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            onPressed: _creating ? null : _create,
            style: FilledButton.styleFrom(
              backgroundColor: _blue,
              disabledBackgroundColor: const Color(0xFF93C5FD),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999)),
            ),
            child: _creating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white)))
                : Text(
                    _selected.isEmpty
                        ? 'গ্রুপ তৈরি করুন'
                        : 'গ্রুপ তৈরি করুন · ${_selected.length} জন',
                    style: const TextStyle(
                        fontSize: 15.5, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }

  Widget _candidateTile(Map<String, dynamic> u) {
    final id = u['id'].toString();
    final sel = _selected.containsKey(id);
    final avatar = AppConfig.getAbsoluteUrl((u['avatar'] ?? '').toString());
    final name = u['name'].toString();
    return InkWell(
      onTap: () => setState(() {
        if (sel) {
          _selected.remove(id);
        } else {
          _selected[id] = u;
        }
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xFFEFF6FF)),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              // Dynamic profile photo with a letter fallback.
              child: avatar.isNotEmpty
                  ? Image.network(avatar,
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _initial(name))
                  : _initial(name),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937))),
                  ),
                  if (u['isVerified'] == true) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified,
                        size: 14, color: Color(0xFF2563EB)),
                  ],
                  if (u['isPro'] == true) ...[
                    const SizedBox(width: 4),
                    const AdsyProBadge(fontSize: 9),
                  ],
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 23,
              height: 23,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: sel ? _blue : Colors.transparent,
                border: Border.all(
                  color: sel ? _blue : Colors.grey.shade400,
                  width: 1.6,
                ),
              ),
              child: sel
                  ? const Icon(Icons.check, size: 15, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _initial(String name) => Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
            color: Color(0xFF334155),
            fontSize: 17,
            fontWeight: FontWeight.w700),
      );
}
