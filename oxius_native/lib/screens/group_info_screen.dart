import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/app_config.dart';
import '../services/adsyconnect_service.dart';
import '../services/auth_service.dart';
import '../widgets/chat/member_picker_sheet.dart';
import '../widgets/common/adsy_toast.dart';
import 'business_network/profile_screen.dart';

/// Group settings / management. What each side can do:
///
/// Everyone: see members & roles, mute/unmute, leave.
/// Admin, additionally: rename group, change photo, add members,
/// remove members, promote/demote admins, delete the group.
///
/// Pops 'left' or 'deleted' when the caller must close the chat.
class GroupInfoScreen extends StatefulWidget {
  final Map<String, dynamic> group;

  const GroupInfoScreen({super.key, required this.group});

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  late Map<String, dynamic> _group;
  bool _muted = false;
  // Member-list search query (lowercased).
  String _memberQuery = '';

  String get _groupId => (_group['id'] ?? '').toString();
  String get _myId => AuthService.currentUser?.id ?? '';
  bool get _isAdmin => _group['my_role'] == 'admin';
  String get _creatorId => (_group['creator'] ?? '').toString();

  List<Map<String, dynamic>> get _members =>
      List<Map<String, dynamic>>.from((_group['members'] as List? ?? [])
          .map((m) => Map<String, dynamic>.from(m)));

  @override
  void initState() {
    super.initState();
    _group = Map<String, dynamic>.from(widget.group);
  }

  Future<void> _refresh() async {
    final groups = await AdsyConnectService.getGroups();
    if (!mounted) return;
    final updated = groups
        .map<Map<String, dynamic>>((g) => Map<String, dynamic>.from(g))
        .where((g) => g['id'].toString() == _groupId)
        .toList();
    if (updated.isNotEmpty) setState(() => _group = updated.first);
  }

  Future<void> _rename() async {
    final controller =
        TextEditingController(text: (_group['name'] ?? '').toString());
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('গ্রুপের নাম বদলান'),
        content: TextField(
          controller: controller,
          maxLength: 80,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'নতুন নাম'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('বাতিল')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('সেভ করুন')),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || !mounted) return;
    final res = await AdsyConnectService.updateGroup(_groupId, name: newName);
    if (!mounted) return;
    if (res != null) {
      setState(() => _group = res);
      AdsyToast.success(context, 'নাম বদলানো হয়েছে');
    } else {
      AdsyToast.error(context, 'নাম বদলানো যায়নি');
    }
  }

  Future<void> _changePhoto() async {
    try {
      final picked = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked == null || !mounted) return;
      final res =
          await AdsyConnectService.updateGroup(_groupId, imagePath: picked.path);
      if (!mounted) return;
      if (res != null) {
        setState(() => _group = res);
        AdsyToast.success(context, 'গ্রুপের ছবি বদলানো হয়েছে');
      } else {
        AdsyToast.error(context, 'ছবি বদলানো যায়নি');
      }
    } catch (_) {
      if (mounted) AdsyToast.error(context, 'ছবি নেওয়া যায়নি');
    }
  }

  Future<void> _addMembers() async {
    final selected = await showModalBottomSheet<List<String>>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => const MemberPickerSheet(),
    );
    if (selected == null || selected.isEmpty || !mounted) return;
    final ok = await AdsyConnectService.addGroupMembers(_groupId, selected);
    if (!mounted) return;
    if (ok) {
      AdsyToast.success(context, 'মেম্বার যোগ হয়েছে');
      _refresh();
    } else {
      AdsyToast.error(context, 'মেম্বার যোগ করা যায়নি');
    }
  }

  Future<void> _toggleMute() async {
    final next = !_muted;
    final ok = await AdsyConnectService.setGroupMuted(_groupId, next);
    if (!mounted) return;
    if (ok) {
      setState(() => _muted = next);
      AdsyToast.info(context, next ? 'গ্রুপ মিউট হয়েছে' : 'আনমিউট হয়েছে');
    } else {
      AdsyToast.error(context, 'করা যায়নি');
    }
  }

  Future<void> _leave() async {
    final confirm = await _confirm(
        'গ্রুপ ছাড়বেন?', '"${_group['name']}" থেকে বেরিয়ে যাবেন।', 'গ্রুপ ছাড়ুন');
    if (confirm != true || !mounted) return;
    final ok = await AdsyConnectService.leaveGroup(_groupId);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop('left');
    } else {
      AdsyToast.error(context, 'গ্রুপ ছাড়া যায়নি');
    }
  }

  Future<void> _deleteGroup() async {
    final confirm = await _confirm('গ্রুপ ডিলিট করবেন?',
        'সব মেসেজসহ গ্রুপটি স্থায়ীভাবে মুছে যাবে। এটা আর ফেরানো যাবে না।', 'ডিলিট করুন');
    if (confirm != true || !mounted) return;
    final ok = await AdsyConnectService.deleteGroup(_groupId);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop('deleted');
    } else {
      AdsyToast.error(context, 'ডিলিট করা যায়নি');
    }
  }

  Future<bool?> _confirm(String title, String body, String action) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('বাতিল')),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626)),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(action)),
        ],
      ),
    );
  }

  void _memberActions(Map<String, dynamic> m) {
    final u = Map<String, dynamic>.from(m['user'] ?? {});
    final uid = (u['id'] ?? '').toString();
    final isAdminRow = m['role'] == 'admin';
    final isCreatorRow = uid == _creatorId;
    if (!_isAdmin || uid == _myId) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            if (!isAdminRow)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined,
                    color: Color(0xFF2563EB)),
                title: const Text('কো-অ্যাডমিন বানান'),
                subtitle: const Text(
                    'গ্রুপ ম্যানেজমেন্টের সব ক্ষমতা পাবেন',
                    style: TextStyle(fontSize: 11.5)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final ok = await AdsyConnectService.promoteGroupAdmin(
                      _groupId, uid);
                  if (!mounted) return;
                  if (ok) {
                    AdsyToast.success(context, 'কো-অ্যাডমিন বানানো হয়েছে');
                    _refresh();
                  } else {
                    AdsyToast.error(context, 'করা যায়নি');
                  }
                },
              ),
            if (isAdminRow && !isCreatorRow)
              ListTile(
                leading: const Icon(Icons.remove_moderator_outlined,
                    color: Color(0xFFD97706)),
                title: const Text('কো-অ্যাডমিন থেকে সরান'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final ok = await AdsyConnectService.demoteGroupAdmin(
                      _groupId, uid);
                  if (!mounted) return;
                  if (ok) {
                    AdsyToast.info(context, 'কো-অ্যাডমিন থেকে সরানো হয়েছে');
                    _refresh();
                  } else {
                    AdsyToast.error(context, 'করা যায়নি');
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.person_remove_outlined,
                  color: Color(0xFFDC2626)),
              title: const Text('গ্রুপ থেকে remove করুন',
                  style: TextStyle(color: Color(0xFFDC2626))),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await AdsyConnectService.removeGroupMember(
                    _groupId, uid);
                if (!mounted) return;
                if (ok) {
                  AdsyToast.info(context, 'Remove করা হয়েছে');
                  _refresh();
                } else {
                  AdsyToast.error(context, 'Remove করা যায়নি');
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = (_group['name'] ?? '').toString();
    final imageUrl = (_group['image_url'] ?? '').toString();
    final members = _members;
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
        title: const Text('গ্রুপ ইনফো',
            style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 17,
                fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Header: photo + name + count — compact.
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 66,
                      height: 66,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: Color(0xFFEFF6FF)),
                      clipBehavior: Clip.antiAlias,
                      alignment: Alignment.center,
                      child: imageUrl.isNotEmpty
                          ? Image.network(imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.groups,
                                  size: 30,
                                  color: Color(0xFF3B82F6)))
                          : const Icon(Icons.groups,
                              size: 30, color: Color(0xFF3B82F6)),
                    ),
                    if (_isAdmin)
                      Positioned(
                        bottom: -1,
                        right: -1,
                        child: InkWell(
                          onTap: _changePhoto,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF2563EB),
                              border:
                                  Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt,
                                size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A))),
                    ),
                    if (_isAdmin) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: _rename,
                        child: Icon(Icons.edit_outlined,
                            size: 15, color: Colors.grey.shade500),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text('${members.length} জন মেম্বার',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Quick actions — dense rows.
          Container(
            color: Colors.white,
            child: Column(
              children: [
                if (_isAdmin)
                  _actionTile(Icons.person_add_alt_1_outlined,
                      'মেম্বার যোগ করুন', _addMembers),
                _actionTile(
                    _muted
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                    _muted ? 'আনমিউট করুন' : 'মিউট করুন',
                    _toggleMute),
                _actionTile(Icons.logout_rounded, 'গ্রুপ ছাড়ুন', _leave,
                    danger: true),
                if (_isAdmin)
                  _actionTile(Icons.delete_forever_outlined,
                      'গ্রুপ ডিলিট করুন', _deleteGroup,
                      danger: true),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Members
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
                  child: Text('মেম্বার · ${members.length}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          color: Colors.grey.shade500)),
                ),
                // Member search — filters the list as you type.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: TextField(
                    onChanged: (v) =>
                        setState(() => _memberQuery = v.trim().toLowerCase()),
                    style: const TextStyle(fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'মেম্বার খুঁজুন',
                      hintStyle: TextStyle(
                          color: Colors.grey.shade500, fontSize: 13),
                      prefixIcon: Icon(Icons.search_rounded,
                          size: 18, color: Colors.grey.shade500),
                      prefixIconConstraints:
                          const BoxConstraints(minWidth: 36, minHeight: 0),
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                ...members.where(_matchesMemberQuery).map(_memberTile),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _matchesMemberQuery(Map<String, dynamic> m) {
    if (_memberQuery.isEmpty) return true;
    final u = Map<String, dynamic>.from(m['user'] ?? {});
    final haystack = [
      u['first_name'] ?? '',
      u['last_name'] ?? '',
      u['username'] ?? '',
    ].join(' ').toLowerCase();
    return haystack.contains(_memberQuery);
  }

  Widget _actionTile(IconData icon, String label, VoidCallback onTap,
      {bool danger = false}) {
    final color = danger ? const Color(0xFFDC2626) : const Color(0xFF334155);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _memberTile(Map<String, dynamic> m) {
    final u = Map<String, dynamic>.from(m['user'] ?? {});
    final uid = (u['id'] ?? '').toString();
    final name = [
      (u['first_name'] ?? '').toString(),
      (u['last_name'] ?? '').toString(),
    ].where((s) => s.isNotEmpty).join(' ');
    final display =
        name.isNotEmpty ? name : (u['username'] ?? 'User').toString();
    final avatar = AppConfig.getAbsoluteUrl((u['avatar'] ?? '').toString());
    final isAdminRow = m['role'] == 'admin';
    final isMe = uid == _myId;
    return InkWell(
      // Row tap opens the member's BN profile; admin actions moved to ⋮.
      onTap: uid.isEmpty
          ? null
          : () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ProfileScreen(userId: uid)),
              ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xFFEFF6FF)),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: avatar.isNotEmpty
                  ? Image.network(avatar,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Text(
                          display.isNotEmpty ? display[0].toUpperCase() : '?',
                          style: const TextStyle(
                              color: Color(0xFF3B82F6),
                              fontWeight: FontWeight.w700)))
                  : Text(display.isNotEmpty ? display[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: Color(0xFF3B82F6),
                          fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(isMe ? '$display (আপনি)' : display,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            if (isAdminRow) ...[
              const SizedBox(width: 6),
              // Creator = অ্যাডমিন (green); promoted admins = কো-অ্যাডমিন
              // (indigo) — same powers, distinct label.
              Builder(builder: (_) {
                final isCreatorRow = uid == _creatorId;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isCreatorRow
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(isCreatorRow ? 'অ্যাডমিন' : 'কো-অ্যাডমিন',
                      style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: isCreatorRow
                              ? const Color(0xFF059669)
                              : const Color(0xFF4F46E5))),
                );
              }),
            ],
            if (_isAdmin && !isMe) ...[
              const SizedBox(width: 4),
              // Admin member-management sheet.
              InkWell(
                onTap: () => _memberActions(m),
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.more_vert,
                      size: 17, color: Colors.grey.shade400),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
