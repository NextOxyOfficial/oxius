import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../services/business_network_service.dart';
import '../../widgets/common/adsy_loading.dart';
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'User unblocked' : 'Failed to unblock user'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Blocked Users'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0.5,
      ),
      body: AdsyRefreshIndicator(
        onRefresh: _loadBlockedUsers,
        color: const Color(0xFF3B82F6),
        child: _isLoading
            ? const Center(child: AdsyLoadingIndicator())
            : _blockedUsers.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Icon(Icons.block_rounded,
                          size: 56, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        'No blocked users',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _blockedUsers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _blockedUsers[index];
                      final user = _blockedInfo(item);
                      final userId =
                          (user['id'] ?? item['blocked'] ?? '').toString();
                      final avatarUrl = _avatarUrl(user);
                      final name = _displayName(user);
                      final username = (user['username'] ?? '').toString();
                      final isUnblocking = _unblockingIds.contains(userId);

                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          leading: CircleAvatar(
                            backgroundImage: avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl.isEmpty
                                ? Text(name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : 'U')
                                : null,
                          ),
                          title: Text(name),
                          subtitle: username.isNotEmpty
                              ? Text('@$username')
                              : const Text('Blocked user'),
                          onTap: userId.isEmpty
                              ? null
                              : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ProfileScreen(userId: userId),
                                    ),
                                  ),
                          trailing: TextButton(
                            onPressed:
                                isUnblocking ? null : () => _unblock(item),
                            child: isUnblocking
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: AdsyLoadingIndicator(strokeWidth: 2),
                                  )
                                : const Text('Unblock'),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
