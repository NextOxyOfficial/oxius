import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:flutter_html/flutter_html.dart';
import '../../models/gold_sponsor_models.dart';
import '../../screens/business_network/gold_sponsors_screen.dart';
import '../../services/gold_sponsor_service.dart';
import '../../utils/url_launcher_utils.dart';

class GoldSponsorsSlider extends StatefulWidget {
  final EdgeInsetsGeometry? margin;

  const GoldSponsorsSlider({super.key, this.margin});

  @override
  State<GoldSponsorsSlider> createState() => _GoldSponsorsSliderState();
}

class _GoldSponsorsSliderState extends State<GoldSponsorsSlider> {
  List<GoldSponsor> _sponsors = [];
  bool _isLoading = true;
  final Set<String> _viewedSponsors = {};

  @override
  void initState() {
    super.initState();
    _loadSponsors();
  }

  Future<void> _loadSponsors() async {
    setState(() => _isLoading = true);
    final sponsors = await GoldSponsorService.getGoldSponsors();
    if (mounted) {
      setState(() {
        _sponsors = sponsors;
        _isLoading = false;
      });
    }
  }

  Future<void> _incrementViews(String sponsorId) async {
    if (!_viewedSponsors.contains(sponsorId)) {
      _viewedSponsors.add(sponsorId);
      await GoldSponsorService.incrementViews(sponsorId);
    }
  }

  void _showSponsorModal(GoldSponsor sponsor) {
    _incrementViews(sponsor.id);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SponsorDetailModal(sponsor: sponsor),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Always show the container - never hide it completely
    return Container(
      margin: widget.margin ?? const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade50, Colors.yellow.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade100, width: 0.5),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade500, Colors.yellow.shade500],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.star, size: 14, color: Colors.white),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Gold Sponsors',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD97706),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GoldSponsorsScreen(),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.amber.shade700,
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 16, color: Colors.amber.shade700),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Content: Loading, Empty, or Sponsors List
          if (_isLoading)
            _buildLoadingContent()
          else if (_sponsors.isEmpty)
            _buildEmptyContent()
          else
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _sponsors.take(5).length,
                itemBuilder: (context, index) {
                  final sponsor = _sponsors[index];
                  return _buildSponsorItem(sponsor);
                },
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildLoadingContent() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            width: 80,
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.amber.shade100,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 60,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Text(
        'No sponsors available at the moment',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSponsorItem(GoldSponsor sponsor) {
    return GestureDetector(
      onTap: () => _showSponsorModal(sponsor),
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade400, Colors.yellow.shade400],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipOval(
                      child: sponsor.logo != null
                          ? Image.network(
                              sponsor.logo!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: Icon(Icons.business, color: Colors.grey.shade400, size: 24),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey.shade200,
                              child: Icon(Icons.business, color: Colors.grey.shade400, size: 24),
                            ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber.shade500, Colors.yellow.shade500],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star, size: 10, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              sponsor.businessName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF78350F),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// Sponsor Detail Modal
class _SponsorDetailModal extends StatefulWidget {
  final GoldSponsor sponsor;

  const _SponsorDetailModal({required this.sponsor});

  @override
  State<_SponsorDetailModal> createState() => _SponsorDetailModalState();
}

class _SponsorDetailModalState extends State<_SponsorDetailModal> {
  List<SponsorBanner> _banners = [];
  bool _isLoadingBanners = true;
  int _currentBannerIndex = 0;
  final PageController _pageController = PageController();
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_banners.isNotEmpty && mounted) {
        final nextPage = (_currentBannerIndex + 1) % _banners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadBanners() async {
    final banners = await GoldSponsorService.getSponsorBanners(widget.sponsor.id);
    if (mounted) {
      setState(() {
        _banners = banners;
        _isLoadingBanners = false;
      });
      if (_banners.isNotEmpty) {
        _startAutoPlay();
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildContactRow(IconData icon, String text, VoidCallback? onTap) {
    final row = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.amber.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: onTap != null ? Colors.amber.shade700 : const Color(0xFF374151),
                fontWeight: FontWeight.w500,
                height: 1.4,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
    
    return onTap != null
        ? GestureDetector(onTap: onTap, child: row)
        : row;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Grab handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner + overlapping logo + views chip
                      SizedBox(
                        height: 210,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Banner image (or gradient fallback)
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: 172,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (_banners.isNotEmpty && !_isLoadingBanners)
                                    PageView.builder(
                                      controller: _pageController,
                                      onPageChanged: (i) => setState(
                                          () => _currentBannerIndex = i),
                                      itemCount: _banners.length,
                                      itemBuilder: (context, index) =>
                                          Image.network(
                                        _banners[index].image,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _bannerFallback(),
                                      ),
                                    )
                                  else
                                    _bannerFallback(),
                                  // Bottom gradient for legibility
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      height: 90,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.45),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Gold Sponsor badge
                                  Positioned(
                                      top: 12, left: 12, child: _goldBadge()),
                                  // Close button
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.4),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close_rounded,
                                            color: Colors.white, size: 18),
                                      ),
                                    ),
                                  ),
                                  // Page dots
                                  if (_banners.length > 1)
                                    Positioned(
                                      bottom: 10,
                                      left: 0,
                                      right: 0,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: List.generate(
                                          _banners.length,
                                          (index) => Container(
                                            width: 6,
                                            height: 6,
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 2),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: _currentBannerIndex == index
                                                  ? Colors.white
                                                  : Colors.white
                                                      .withOpacity(0.45),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Logo overlapping the banner bottom-left
                            Positioned(
                              top: 138,
                              left: 16,
                              child: Container(
                                width: 72,
                                height: 72,
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(13),
                                  child: widget.sponsor.logo != null
                                      ? Image.network(widget.sponsor.logo!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _logoFallback())
                                      : _logoFallback(),
                                ),
                              ),
                            ),
                            // Views chip on the banner (bottom-right)
                            Positioned(
                              top: 142,
                              right: 14,
                              child: _viewsChip(widget.sponsor.views),
                            ),
                          ],
                        ),
                      ),

                      // Business name
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
                        child: Text(
                          widget.sponsor.businessName,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),

                      // Full business description — no truncation so sponsors
                      // can share complete details about their business.
                      if (widget.sponsor.businessDescription != null &&
                          widget.sponsor.businessDescription!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFEFF1F4)),
                            ),
                            child: Html(
                              data: widget.sponsor.businessDescription!,
                              onLinkTap: (url, attributes, element) {
                                UrlLauncherUtils.launchExternalUrl(url);
                              },
                              style: {
                                '*': Style(
                                  margin: Margins.zero,
                                  padding: HtmlPaddings.zero,
                                  fontSize: FontSize(15.5),
                                  color: const Color(0xFF374151),
                                  lineHeight: const LineHeight(1.6),
                                ),
                              },
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Contact info
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                        child: Column(
                          children: [
                            if (widget.sponsor.contactEmail != null)
                              _buildContactRow(Icons.email_rounded,
                                  widget.sponsor.contactEmail!, null),
                            if (widget.sponsor.phoneNumber != null)
                              _buildContactRow(Icons.phone_rounded,
                                  widget.sponsor.phoneNumber!, null),
                            if (widget.sponsor.website != null)
                              _buildContactRow(
                                  Icons.language_rounded,
                                  widget.sponsor.website!,
                                  () => _launchUrl(widget.sponsor.website!)),
                          ],
                        ),
                      ),

                      // Visit Profile
                      if (widget.sponsor.profileUrl != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 14, 4, 0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _launchUrl(widget.sponsor.profileUrl!);
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.amber.shade500,
                                    Colors.orange.shade500,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.open_in_new_rounded,
                                      color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Visit Profile',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _goldBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.amber.shade500, Colors.orange.shade400]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: Colors.white, size: 15),
          SizedBox(width: 4),
          Text('Gold Sponsor',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              )),
        ],
      ),
    );
  }

  Widget _logoFallback() {
    return Container(
      color: Colors.amber.shade50,
      child: Icon(Icons.business, size: 30, color: Colors.amber.shade300),
    );
  }

  Widget _bannerFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.amber.shade300, Colors.orange.shade400],
        ),
      ),
      child: Center(
        child: Icon(Icons.workspace_premium_rounded,
            size: 54, color: Colors.white.withOpacity(0.85)),
      ),
    );
  }

  Widget _viewsChip(int views) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility_rounded, size: 15, color: Colors.amber.shade700),
          const SizedBox(width: 5),
          Text(
            '${_formatViews(views)} views',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  String _formatViews(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}
