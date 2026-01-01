import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:flutter_html/flutter_html.dart';
import '../../models/gold_sponsor_models.dart';
import '../../services/gold_sponsor_service.dart';
import '../../utils/url_launcher_utils.dart';

class GoldSponsorsSlider extends StatefulWidget {
  const GoldSponsorsSlider({super.key});

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
      margin: const EdgeInsets.only(bottom: 12),
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
                    // TODO: Navigate to full sponsors page
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.amber.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: onTap != null ? Colors.amber.shade700 : const Color(0xFF374151),
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Compact Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber.shade400, Colors.yellow.shade500],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.star_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Gold Sponsor',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, size: 22, color: Colors.grey.shade600),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner Carousel
                      if (_banners.isNotEmpty && !_isLoadingBanners)
                        Stack(
                          children: [
                            SizedBox(
                              height: 180,
                              child: PageView.builder(
                                controller: _pageController,
                                onPageChanged: (index) => setState(() => _currentBannerIndex = index),
                                itemCount: _banners.length,
                                itemBuilder: (context, index) {
                                  return Image.network(
                                    _banners[index].image,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.amber.shade50,
                                      child: Icon(Icons.image, size: 40, color: Colors.amber.shade300),
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (_banners.length > 1)
                              Positioned(
                                bottom: 8,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    _banners.length,
                                    (index) => Container(
                                      width: 5,
                                      height: 5,
                                      margin: const EdgeInsets.symmetric(horizontal: 2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _currentBannerIndex == index
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.4),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Business Name & Logo
                            Row(
                              children: [
                                // Logo
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.amber.shade400, Colors.yellow.shade500],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: widget.sponsor.logo != null
                                          ? Image.network(
                                              widget.sponsor.logo!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Icon(
                                                Icons.business,
                                                size: 28,
                                                color: Colors.grey.shade400,
                                              ),
                                            )
                                          : Icon(Icons.business, size: 28, color: Colors.grey.shade400),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                
                                // Business Name
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.sponsor.businessName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.3,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                      if (widget.sponsor.businessDescription != null) ...[
                                        const SizedBox(height: 3),
                                        Html(
                                          data: widget.sponsor.businessDescription!,
                                          onLinkTap: (url, attributes, element) {
                                            UrlLauncherUtils.launchExternalUrl(url);
                                          },
                                          style: {
                                            '*': Style(
                                              margin: Margins.zero,
                                              padding: HtmlPaddings.zero,
                                              fontSize: FontSize(12),
                                              color: Colors.grey.shade600,
                                              lineHeight: const LineHeight(1.3),
                                              maxLines: 2,
                                              textOverflow: TextOverflow.ellipsis,
                                            ),
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Contact Info
                            if (widget.sponsor.contactEmail != null)
                              _buildContactRow(
                                Icons.email_rounded,
                                widget.sponsor.contactEmail!,
                                null,
                              ),
                            if (widget.sponsor.phoneNumber != null)
                              _buildContactRow(
                                Icons.phone_rounded,
                                widget.sponsor.phoneNumber!,
                                null,
                              ),
                            if (widget.sponsor.website != null)
                              _buildContactRow(
                                Icons.language_rounded,
                                widget.sponsor.website!,
                                () => _launchUrl(widget.sponsor.website!),
                              ),
                            
                            // Visit Button
                            if (widget.sponsor.profileUrl != null) ...[
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _launchUrl(widget.sponsor.profileUrl!);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Visit Profile',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
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
}
