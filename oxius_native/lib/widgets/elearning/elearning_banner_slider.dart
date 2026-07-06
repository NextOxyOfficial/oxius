import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:oxius_native/utils/image_utils.dart';
import 'package:oxius_native/config/app_config.dart';
import 'package:oxius_native/services/deep_link_service.dart';
import 'package:oxius_native/services/elearning_service.dart';
import 'package:oxius_native/services/translation_service.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';

/// Dynamic, admin-managed promotional slider for the eLearning screen.
///
/// Slides are fetched from the backend (`/api/elearning/banners/`). Each slide
/// can open an internal app route or an external URL depending on its
/// `link_type`, so new promos/updates can be added purely from Django admin.
class ElearningBannerSlider extends StatefulWidget {
  const ElearningBannerSlider({super.key});

  @override
  State<ElearningBannerSlider> createState() => _ElearningBannerSliderState();
}

class _ElearningBannerSliderState extends State<ElearningBannerSlider> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _currentIndex = 0;

  List<Map<String, dynamic>> _banners = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadBanners() async {
    final banners = await ElearningService.fetchBanners();
    if (!mounted) return;
    setState(() {
      _banners = banners.where((b) {
        final img = (b['image'] ?? '').toString().trim();
        return img.isNotEmpty;
      }).toList();
      _loading = false;
    });
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    if (_banners.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _banners.length <= 1) return;
      final next = (_currentIndex + 1) % _banners.length;
      if (_controller.hasClients) {
        _controller.animateToPage(
          next,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  String? _slideTarget(Map<String, dynamic> banner) {
    final raw = (banner['link_url'] ?? banner['link'] ?? '').toString().trim();
    return raw.isEmpty ? null : raw;
  }

  String _slideLinkType(Map<String, dynamic> banner) {
    final raw = (banner['link_type'] ?? '').toString().trim().toLowerCase();
    if (raw == 'external') return 'external';
    if (raw == 'internal') return 'internal';
    return 'none';
  }

  Future<void> _openSlide(Map<String, dynamic> banner) async {
    final target = _slideTarget(banner);
    final type = _slideLinkType(banner);
    if (target == null || type == 'none') return;

    if (type == 'external') {
      final parsed = Uri.tryParse(
        target.startsWith('http') ? target : 'https://$target',
      );
      if (parsed != null) {
        try {
          await launchUrl(parsed, mode: LaunchMode.externalApplication);
        } catch (_) {
          if (mounted) {
            AdsyToast.error(
                context,
                TranslationService()
                    .t('el_link_failed', fallback: 'Could not open the link'));
          }
        }
      }
      return;
    }

    // Internal route (e.g. /elearning, /eshop, /sale ...)
    try {
      await DeepLinkService.instance.openInternalLink(target);
    } catch (_) {
      if (!mounted) return;
      final route = target.startsWith('/') ? target : '/$target';
      try {
        await Navigator.pushNamed(context, route);
      } catch (_) {
        if (mounted) {
          AdsyToast.error(
              context,
              TranslationService().t('el_page_not_ready',
                  fallback: 'This page is not available yet'));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final height = (screenWidth * 0.42).clamp(150.0, 240.0);

    if (_loading) {
      return _SliderShell(
        height: height,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      );
    }

    // Nothing configured yet — keep the screen clean.
    if (_banners.isEmpty) return const SizedBox.shrink();

    return _SliderShell(
      height: height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              final banner = _banners[index];
              final imageUrl = AppConfig.getAbsoluteUrl(
                (banner['image'] ?? '').toString(),
              );
              final tappable = _slideTarget(banner) != null &&
                  _slideLinkType(banner) != 'none';

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: tappable ? () => _openSlide(banner) : null,
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: AppImage.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorWidget: Container(
                      color: const Color(0xFFEEF2FF),
                      child: const Center(
                        child: Icon(Icons.image_outlined,
                            size: 40, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (_banners.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_banners.length, (index) {
                  final active = index == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _SliderShell extends StatelessWidget {
  final double height;
  final Widget child;

  const _SliderShell({required this.height, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: child,
      ),
    );
  }
}
