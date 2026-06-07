import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/deep_link_service.dart';
import '../../services/home_popup_service.dart';
import '../../utils/url_launcher_utils.dart';

class HomePopupDialog extends StatefulWidget {
  const HomePopupDialog({
    super.key,
    required this.popup,
  });

  final HomePopup popup;

  @override
  State<HomePopupDialog> createState() => _HomePopupDialogState();
}

class _HomePopupDialogState extends State<HomePopupDialog> {
  bool _tracked = false;

  void _close() {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).maybePop();
  }

  Future<void> _openTarget() async {
    final target = widget.popup.link?.trim();
    if (target == null || target.isEmpty) return;

    _close();

    if (widget.popup.openExternal) {
      await UrlLauncherUtils.launchExternalUrl(target);
      return;
    }

    final normalized = _normalizeAdsyTarget(target);
    final uri = Uri.tryParse(normalized);
    final isAdsyWebLink = uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        (uri.host == 'adsyclub.com' || uri.host == 'www.adsyclub.com');

    if (isAdsyWebLink ||
        normalized.startsWith('/') ||
        !normalized.contains('://')) {
      await DeepLinkService.instance.openInternalLink(normalized);
      return;
    }

    await UrlLauncherUtils.launchExternalUrl(normalized);
  }

  String _normalizeAdsyTarget(String target) {
    final trimmed = target.trim();
    final lower = trimmed.toLowerCase();
    if (lower.startsWith('adsyclub.com/') ||
        lower.startsWith('www.adsyclub.com/')) {
      return 'https://$trimmed';
    }
    return trimmed;
  }

  void _trackShown() {
    if (_tracked) return;
    _tracked = true;
    HomePopupService.trackMobileView(widget.popup.id);
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final maxWidth = screen.width < 520 ? screen.width - 24 : 520.0;
    final maxHeight = screen.height * 0.68;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: _openTarget,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  widget.popup.imageUrl,
                  fit: BoxFit.contain,
                  width: maxWidth,
                  frameBuilder:
                      (context, child, frame, wasSynchronouslyLoaded) {
                    if (wasSynchronouslyLoaded || frame != null) {
                      _trackShown();
                      return child;
                    }
                    return const SizedBox(
                      width: 72,
                      height: 72,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, error, __) {
                    if (kDebugMode) {
                      return Container(
                        width: maxWidth,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(0, 0, 0, 0.72),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          'Popup image failed to load\n${widget.popup.imageUrl}\n$error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
            Positioned(
              top: -12,
              right: -8,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 6,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _close,
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(
                      Icons.close_rounded,
                      color: Color(0xFF111827),
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
