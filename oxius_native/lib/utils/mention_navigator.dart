import 'package:flutter/material.dart';

import '../models/user_model.dart' as user_model;
import '../screens/business_network/profile_screen.dart';
import '../services/user_search_service.dart';
import '../widgets/common/adsy_toast.dart';

/// Resolves a tapped @mention to the RIGHT profile.
///
/// Mentions are stored as plain display names (the composer's user-id markup
/// is flattened before saving), so tapping one has to resolve by name — but
/// never blindly. The old behavior navigated to `results.first`, which sent
/// people to a random same-named profile. Rules now:
///   1. exactly one EXACT full-name match  -> open it
///   2. a single search result             -> open it
///   3. anything ambiguous                 -> a chooser sheet; the user picks
class MentionNavigator {
  static String _norm(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static Future<void> open(BuildContext context, String mentionName) async {
    List<user_model.User> users;
    try {
      users = await UserSearchService.searchUsers(mentionName.trim());
    } catch (_) {
      users = const [];
    }
    if (!context.mounted) return;

    if (users.isEmpty) {
      AdsyToast.info(context, 'ব্যবহারকারী খুঁজে পাওয়া যায়নি');
      return;
    }

    final target = _norm(mentionName);
    final exact =
        users.where((u) => _norm(u.name) == target).toList(growable: false);

    if (exact.length == 1) {
      _push(context, exact.first.id.toString());
      return;
    }
    final candidates = exact.isNotEmpty ? exact : users;
    if (candidates.length == 1) {
      _push(context, candidates.first.id.toString());
      return;
    }

    // Ambiguous — never guess; let the user pick the right person.
    final chosen = await showModalBottomSheet<user_model.User>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'কার প্রোফাইল দেখতে চান?',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  Text(
                    '@$mentionName',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
                itemCount: candidates.length.clamp(0, 8),
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (_, i) {
                  final u = candidates[i];
                  final img = (u.image ?? u.avatar ?? '').toString();
                  return ListTile(
                    onTap: () => Navigator.pop(sheetContext, u),
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFEFF6FF),
                      backgroundImage:
                          img.isNotEmpty ? NetworkImage(img) : null,
                      child: img.isEmpty
                          ? const Icon(Icons.person_rounded,
                              size: 20, color: Color(0xFF93C5FD))
                          : null,
                    ),
                    title: Text(
                      u.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A)),
                    ),
                    subtitle: (u.profession ?? '').isNotEmpty
                        ? Text(
                            u.profession!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF64748B)),
                          )
                        : null,
                    trailing: const Icon(Icons.chevron_right_rounded,
                        size: 20, color: Color(0xFF94A3B8)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (chosen != null && context.mounted) {
      _push(context, chosen.id.toString());
    }
  }

  static void _push(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId)),
    );
  }
}
