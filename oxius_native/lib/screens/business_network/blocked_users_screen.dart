import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../services/business_network_service.dart';
import '../../widgets/common/adsy_loading.dart';
import '../../widgets/common/adsy_toast.dart';
import 'profile_screen.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  bool _isLoading = true;
  final Set<String> _unblockingIds = {};
  List<Map<String, dynamic>> _blockedUsers = [];

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() => _isLoading = true);
    final users = await BusinessNetworkService.getBlockedUsers();
    if (!mounted) return;
    setState(() {
      _blockedUsers = users;
      _isLoading = false;
    });
  }

  Map<String, dynamic> _blockedInfo(Map<String, dynamic> item) {
    final raw = item['blocked_info'] ?? item['blocked'];
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return {'id': raw?.toString() ?? ''};
  }

  String _displayName(Map<String, dynamic> user) {
    final first = (user['first_name'] ?? '').toString().trim();
    final last = (user['last_name'] ?? '').toString().trim();
    final fullName = [first, last].where((part) => part.isNotEmpty).join(' ');
    if (fullName.isNotEmpty) return fullName;
    final username = (user['username'] ?? '').toString().trim();
    return username.isNotEmpty ? username : 'Blocked user';
  }

  String _avatarUrl(Map<String, dynamic> user) {
    return AppConfig.getAbsoluteUrl(
      user['avatar']?.toString() ?? user['image']?.toString(),
    );
  }

  Future<void> _unblock(Map<String, dynamic> item) async {
    final user = _blockedInfo(item);
    final userId = (user['id'] ?? item['blocked'] ?? '').toString();
    if (userId.isEmpty || _unblockingIds.contains(userId)) return;

    setState(() => _unblockingIds.add(userId));
    final success = await BusinessNetworkService.unblockUser(userId);
    if (!mounted) return;

    setState(() {
      _unblockingIds.remove(userId);
      if (success) {
        _blockedUsers.removeWhere((blockedItem) {
          final blocked = _blockedInfo(blockedItem);
          return (blocked['id'] ?? blockedItem['blocked'] ?? '').toString() ==
              userId;
        });
      }
    });

    if (success) {
      AdsyToast.success(context, 'User unblocked');
    } else {
      AdsyToast.error(context, 'Failed to unblock user');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Blocked Users',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      body: AdsyRefreshIndicator(
        onRefresh: _loadBlockedUsers,
        color: const Color(0xFF3B82F6),
        child: _isLoading
            ? const Center(child: AdsyLoadingIndicator())
            : _blockedUsers.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
                    itemCount: _blockedUsers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _buildBlockedTile(_blockedUsers[index]),
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 110),
        Center(
          child: Column(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF1F5F9),
                ),
                child: Icon(Icons.block_rounded,
                    size: 44, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 22),
              const Text(
                'No blocked users',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: Text(
                  "You haven't blocked anyone yet. People you block can't "
                  "message you or see your activity.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13.5,
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBlockedTile(Map<String, dynamic> item) {
    final user = _blockedInfo(item);
    final userId = (user['id'] ?? item['blocked'] ?? '').toString();
    final avatarUrl = _avatarUrl(user);
    final name = _displayName(user);
    final username = (user['username'] ?? '').toString();
    final isUnblocking = _unblockingIds.contains(userId);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDF0F4)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: userId.isEmpty
              ? null
              : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(userId: userId),
                    ),
                  ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFEFF2F6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: avatarUrl.isNotEmpty
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _avatarInitial(name),
                        )
                      : _avatarInitial(name),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        username.isNotEmpty ? '@$username' : 'Blocked user',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: isUnblocking ? null : () => _unblock(item),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    backgroundColor: const Color(0xFFFEF2F2),
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(0, 38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isUnblocking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: AdsyLoadingIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Unblock',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarInitial(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }
}
