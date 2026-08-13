import 'package:flutter/material.dart';

import '../../screens/adsy_connect_chat_interface.dart';
import '../../services/adsyconnect_service.dart';
import '../../services/house_ads_service.dart';
import '../../utils/media_headers.dart';
import '../../utils/time_utils.dart';
import '../common/adsy_toast.dart';
import '../app_network_image.dart';
import 'package:oxius_native/l10n/tr.dart';

/// The people who messaged an advertiser from one of their ads.
///
/// This is what an advertiser gets INSTEAD of a dead end when they tap their
/// own ad's "মেসেজ করুন": their own ad can't message them, but the ad's whole
/// purpose is these conversations, so the button opens the list of them.
class AdLeadsSheet extends StatefulWidget {
  /// Limit to one ad; null lists every lead the caller has received.
  final String? adId;
  final String adTitle;

  const AdLeadsSheet({super.key, this.adId, this.adTitle = ''});

  static Future<void> show(
    BuildContext context, {
    String? adId,
    String adTitle = '',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdLeadsSheet(adId: adId, adTitle: adTitle),
    );
  }

  @override
  State<AdLeadsSheet> createState() => _AdLeadsSheetState();
}

class _AdLeadsSheetState extends State<AdLeadsSheet> {
  bool _loading = true;
  List<AdLead> _leads = const [];
  String? _openingFor;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final leads = await HouseAdsService.fetchLeads(adId: widget.adId);
    if (!mounted) return;
    setState(() {
      _leads = leads;
      _loading = false;
    });
  }

  /// Continue the conversation. The lead usually carries the room it started
  /// in; when it doesn't (an older lead, or a room the advertiser deleted),
  /// the room is resolved from the person instead of failing.
  Future<void> _openChat(AdLead lead) async {
    setState(() => _openingFor = lead.userId);
    var roomId = lead.chatroomId;
    try {
      if (roomId.isEmpty) {
        final room = await AdsyConnectService.getOrCreateChatRoom(lead.userId);
        roomId = room['id']?.toString() ?? '';
      }
    } catch (_) {
      roomId = '';
    }
    if (!mounted) return;
    setState(() => _openingFor = null);
    if (roomId.isEmpty) {
      AdsyToast.error(context, tr('চ্যাট খোলা যায়নি, একটু পরে চেষ্টা করুন।'));
      return;
    }
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdsyConnectChatInterface(
          chatroomId: roomId,
          userId: lead.userId,
          userName: lead.userName,
          userAvatar: lead.userImage,
          profession: lead.profession,
          isVerified: lead.isVerified,
          isPro: lead.isPro,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Container(
      constraints: BoxConstraints(maxHeight: height * 0.78),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('বিজ্ঞাপনের লিড'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.adTitle.isNotEmpty
                            ? widget.adTitle
                            : tr('যারা আপনার বিজ্ঞাপন থেকে মেসেজ করেছেন'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5A6273),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_loading && _leads.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_leads.length}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Flexible(child: _body()),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 44),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_leads.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(28, 34, 28, 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.forum_outlined,
                size: 34, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              tr('এখনো কোনো লিড আসেনি'),
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tr('কেউ আপনার বিজ্ঞাপনের "মেসেজ করুন" বাটন থেকে লিখলে তাকে ') +
              tr('এখানে পাবেন — মেসেজের সাথে কোন বিজ্ঞাপন থেকে এসেছে সেটিও ') +
              tr('দেখা যাবে।'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: Color(0xFF5A6273),
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _leads.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, indent: 68, color: Color(0xFFF1F5F9)),
      itemBuilder: (_, i) => _row(_leads[i]),
    );
  }

  Widget _row(AdLead lead) {
    final message = lead.lastMessage.trim().isNotEmpty
        ? lead.lastMessage.trim()
        : lead.firstMessage.trim();
    final when = lead.lastMessageAt;
    return InkWell(
      onTap: _openingFor == null ? () => _openChat(lead) : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 11, 14, 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _avatar(lead),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          lead.userName.isEmpty ? tr('ব্যবহারকারী') : lead.userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      if (lead.isVerified) ...[
                        const SizedBox(width: 3),
                        const Icon(Icons.verified,
                            size: 14, color: Color(0xFF3B82F6)),
                      ],
                      if (!lead.isRead) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (when != null)
                        Text(
                          TimeUtils.formatTimeAgo(when.toIso8601String()),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF858E9C),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message.isEmpty ? tr('মেসেজ করেছেন') : message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  if (widget.adId == null && lead.adTitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '📣 ${lead.adTitle}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5A6273),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            if (_openingFor == lead.userId)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  Widget _avatar(AdLead lead) {
    if (lead.userImage.isEmpty) {
      return Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Color(0xFFF1F5F9),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.person, size: 22, color: Color(0xFF94A3B8)),
      );
    }
    return ClipOval(
      child: AppNetworkImage(
        lead.userImage,
        width: 44,
        height: 44,
        httpHeaders: kMediaHeaders,
        errorWidget: Container(
          width: 44,
          height: 44,
          color: const Color(0xFFF1F5F9),
          child: const Icon(Icons.person, size: 22, color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }
}
