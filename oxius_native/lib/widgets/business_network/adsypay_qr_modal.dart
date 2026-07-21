import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../screens/wallet/wallet_screen.dart';
import '../../services/auth_service.dart';
import '../../services/deep_link_service.dart';
import '../../services/wallet_service.dart';
import '../common/adsy_loading.dart';
import '../common/adsy_toast.dart';

/// AdsyPay QR — a professional bottom sheet with two jobs:
///
///  • RECEIVE: show the user's payment QR (`adsypay://pay/<id>`).
///  • SCAN: read a QR and act on it INTELLIGENTLY, but only within AdsyClub:
///      – payment QR  → the wallet transfer screen opens with the recipient
///        already filled — the user only types the amount + password;
///      – any adsyclub.com / adsyclub:// link (profile, post, product…)
///        → navigates in-app via the deep-link service;
///      – anything else → a clear "this QR is not AdsyClub's" message.
class AdsyPayQrSheet extends StatefulWidget {
  final String qrData;

  const AdsyPayQrSheet({super.key, required this.qrData});

  /// Present as a rounded bottom sheet.
  static Future<void> show(BuildContext context, {required String qrData}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdsyPayQrSheet(qrData: qrData),
    );
  }

  @override
  State<AdsyPayQrSheet> createState() => _AdsyPayQrSheetState();
}

class _AdsyPayQrSheetState extends State<AdsyPayQrSheet> {
  int _tab = 0; // 0 = receive, 1 = scan & send
  bool _resolving = false;

  static const _green = Color(0xFF059669);
  static const _greenDark = Color(0xFF047857);
  static const _dark = Color(0xFF0F172A);
  static const _slate = Color(0xFF64748B);

  // ── Smart scan handling ──────────────────────────────────────────────────

  Future<void> _startScan() async {
    final raw = await Navigator.of(context, rootNavigator: true).push<String>(
      MaterialPageRoute(builder: (_) => const _AdsyQrScannerScreen()),
    );
    if (!mounted || raw == null || raw.trim().isEmpty) return;
    await _handleScanned(raw.trim());
  }

  Future<void> _handleScanned(String value) async {
    // 1) AdsyPay payment QR → transfer screen with the recipient autofilled.
    if (value.startsWith('adsypay://pay/')) {
      final userId = value.substring('adsypay://pay/'.length).trim();
      if (userId.isEmpty) {
        _showNotAdsyDialog(value);
        return;
      }
      setState(() => _resolving = true);
      try {
        final userData = await WalletService.getUserById(userId);
        if (!mounted) return;
        setState(() => _resolving = false);
        final contact =
            (userData?['email'] ?? userData?['phone'])?.toString() ?? '';
        if (contact.isEmpty) {
          AdsyToast.error(
              context, 'এই ইউজারের পেমেন্ট তথ্য পাওয়া যায়নি।');
          return;
        }
        final name = (userData?['name'] ??
                userData?['first_name'] ??
                'AdsyClub ইউজার')
            .toString();
        final navigator = Navigator.of(context, rootNavigator: true);
        navigator.pop(); // close the sheet
        navigator.push(MaterialPageRoute(
          builder: (_) => WalletScreen(
            initialTab: 2,
            initialTransferContact: contact,
          ),
        ));
        // Small heads-up so the user knows who they're paying.
        AdsyToast.success(navigator.context, '$name-কে টাকা পাঠান');
      } catch (_) {
        if (!mounted) return;
        setState(() => _resolving = false);
        AdsyToast.error(context, 'ইউজার খুঁজে পাওয়া যায়নি। আবার চেষ্টা করুন।');
      }
      return;
    }

    // 2) Any AdsyClub link (profile / post / product / …) → open in-app.
    if (_isAdsyClubLink(value)) {
      final navigator = Navigator.of(context, rootNavigator: true);
      navigator.pop();
      await DeepLinkService.instance.openInternalLink(value);
      return;
    }

    // 3) Everything else — clearly not ours.
    _showNotAdsyDialog(value);
  }

  bool _isAdsyClubLink(String v) {
    final uri = Uri.tryParse(v);
    if (uri == null) return false;
    if (uri.scheme == 'adsyclub' || uri.scheme == 'adsypay') return true;
    if (uri.scheme != 'http' && uri.scheme != 'https') return false;
    final host = uri.host.toLowerCase();
    return host == 'adsyclub.com' ||
        host == 'www.adsyclub.com' ||
        host.endsWith('.adsyclub.com');
  }

  void _showNotAdsyDialog(String value) {
    final preview = value.length > 96 ? '${value.substring(0, 96)}…' : value;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner_rounded,
                color: Color(0xFFDC2626), size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text('এটি AdsyClub-এর QR নয়',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _dark)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'নিরাপত্তার জন্য AdsyPay শুধুমাত্র AdsyClub-এর QR কোড পড়ে — পেমেন্ট, প্রোফাইল বা adsyclub.com লিংক।',
              style: TextStyle(fontSize: 13, height: 1.5, color: _slate),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                preview,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5, color: _slate),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বুঝেছি',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: _green)),
          ),
        ],
      ),
    );
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Brand header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded,
                    color: Color(0xFF10B981), size: 30),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AdsyPay',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _dark,
                              letterSpacing: -0.3)),
                      SizedBox(height: 1),
                      Text('ডিজিটাল পেমেন্ট — স্ক্যান, পাঠান, রিসিভ করুন',
                          style: TextStyle(fontSize: 11.5, color: _slate)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded,
                      color: _slate, size: 22),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Segmented tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _segButton(0, Icons.qr_code_2_rounded, 'রিসিভ'),
                  _segButton(1, Icons.qr_code_scanner_rounded, 'স্ক্যান ও পাঠান'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _tab == 0 ? _buildReceive() : _buildScanSend(),
          ),
        ],
      ),
    );
  }

  Widget _segButton(int index, IconData icon, String label) {
    final selected = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2)),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? _green : _slate),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? _dark : _slate)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceive() {
    final u = AuthService.currentUser;
    final name = [u?.firstName ?? '', u?.lastName ?? '']
        .where((s) => s.trim().isNotEmpty)
        .join(' ')
        .trim();
    return Padding(
      key: const ValueKey('receive'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD1FAE5), width: 2),
            ),
            child: QrImageView(
              data: widget.qrData,
              version: QrVersions.auto,
              size: 180,
              backgroundColor: Colors.transparent,
            ),
          ),
          const SizedBox(height: 10),
          if (name.isNotEmpty)
            Text(name,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
          const SizedBox(height: 4),
          const Text(
            'এই QR কোডটি দেখালে যে-কেউ AdsyPay দিয়ে আপনাকে সরাসরি টাকা পাঠাতে পারবে।',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, height: 1.5, color: _slate),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_rounded, size: 14, color: _green),
                SizedBox(width: 6),
                Text('সিকিউর পেমেন্ট',
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _greenDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanSend() {
    return Padding(
      key: const ValueKey('scan'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // What the scanner understands — informative, at a glance.
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('QR স্ক্যান করলে যা হবে',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: _dark)),
                const SizedBox(height: 10),
                _scanInfoRow(Icons.payments_rounded, const Color(0xFF059669),
                    'পেমেন্ট QR', 'ট্রান্সফার স্ক্রিনে রিসিভার অটো-ফিল হবে — শুধু টাকার পরিমাণ ও পাসওয়ার্ড দিন'),
                const SizedBox(height: 8),
                _scanInfoRow(Icons.person_rounded, const Color(0xFF2563EB),
                    'প্রোফাইল / লিংক QR', 'AdsyClub-এর যেকোনো প্রোফাইল, পোস্ট বা পেজে সরাসরি নিয়ে যাবে'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _resolving ? null : _startScan,
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13)),
              ),
              icon: _resolving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: AdsyLoadingIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.qr_code_scanner_rounded, size: 20),
              label: Text(_resolving ? 'যাচাই হচ্ছে…' : 'QR স্ক্যান করুন',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () {
                final navigator = Navigator.of(context, rootNavigator: true);
                navigator.pop();
                navigator.push(MaterialPageRoute(
                    builder: (_) => const WalletScreen(initialTab: 2)));
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: _dark,
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13)),
              ),
              icon: const Icon(Icons.send_rounded, size: 17, color: _slate),
              label: const Text('ম্যানুয়ালি টাকা পাঠান',
                  style:
                      TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scanInfoRow(
      IconData icon, Color color, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _dark)),
              const SizedBox(height: 1),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 11.5, height: 1.4, color: _slate)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Full-screen scanner that returns the RAW QR value (no prefix stripping —
/// the sheet decides what the code means).
class _AdsyQrScannerScreen extends StatefulWidget {
  const _AdsyQrScannerScreen();

  @override
  State<_AdsyQrScannerScreen> createState() => _AdsyQrScannerScreenState();
}

class _AdsyQrScannerScreenState extends State<_AdsyQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('QR স্ক্যান করুন'),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_done) return;
              for (final barcode in capture.barcodes) {
                final raw = barcode.rawValue;
                if (raw != null && raw.isNotEmpty) {
                  _done = true;
                  Navigator.pop(context, raw);
                  break;
                }
              }
            },
          ),
          // Frame overlay + hint
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF34D399), width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 48,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'AdsyClub-এর পেমেন্ট, প্রোফাইল বা লিংক QR ফ্রেমের ভেতরে ধরুন',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white, fontSize: 12.5, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
