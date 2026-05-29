import 'package:flutter/material.dart';

import '../../models/gold_sponsor_models.dart';
import '../../services/gold_sponsor_service.dart';
import '../../utils/url_launcher_utils.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';

class GoldSponsorsScreen extends StatefulWidget {
  const GoldSponsorsScreen({super.key});

  @override
  State<GoldSponsorsScreen> createState() => _GoldSponsorsScreenState();
}

class _GoldSponsorsScreenState extends State<GoldSponsorsScreen> {
  late Future<List<GoldSponsor>> _sponsorsFuture;

  @override
  void initState() {
    super.initState();
    _sponsorsFuture = GoldSponsorService.getGoldSponsors();
  }

  Future<void> _refresh() async {
    setState(() {
      _sponsorsFuture = GoldSponsorService.getGoldSponsors();
    });
    await _sponsorsFuture;
  }

  Future<void> _openOffer(GoldSponsor sponsor) async {
    final url = _offerUrl(sponsor);
    if (url == null) {
      _showMessage('No offer link available for this sponsor');
      return;
    }

    await GoldSponsorService.incrementViews(sponsor.id);
    final opened = await UrlLauncherUtils.launchExternalUrl(url);
    if (!opened && mounted) {
      _showMessage('Could not open sponsor offer');
    }
  }

  String? _offerUrl(GoldSponsor sponsor) {
    final website = sponsor.website?.trim();
    if (website != null && website.isNotEmpty) return website;

    final profileUrl = sponsor.profileUrl?.trim();
    if (profileUrl != null && profileUrl.isNotEmpty) return profileUrl;

    return null;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF92400E),
      ),
    );
  }

  String _descriptionFor(GoldSponsor sponsor) {
    final raw = sponsor.businessDescription?.trim();
    if (raw == null || raw.isEmpty) {
      return 'Explore this verified Gold Sponsor and their latest offers.';
    }

    return raw
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    child: FutureBuilder<List<GoldSponsor>>(
                      future: _sponsorsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _buildLoadingList();
                        }

                        final sponsors = snapshot.data ?? [];
                        if (sponsors.isEmpty) {
                          return _buildEmptyState();
                        }

                        return AdsyRefreshIndicator(
                          color: const Color(0xFFD97706),
                          onRefresh: _refresh,
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(6, 6, 6, 24),
                            itemCount: sponsors.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 0),
                            itemBuilder: (context, index) {
                              return _buildSponsorCard(sponsors[index]);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: Colors.white, size: 22),
            tooltip: 'Back',
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Gold Sponsors',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.05,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Premium partners and exclusive offers',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.workspace_premium, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSponsorCard(GoldSponsor sponsor) {
    final offerUrl = _offerUrl(sponsor);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openOffer(sponsor),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFFE5E7EB).withValues(alpha: 0.92),
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(1, 10, 0, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildLogo(sponsor.logo),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    sponsor.businessName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF111827),
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                                if (sponsor.isFeatured) _buildFeaturedChip(),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _descriptionFor(sponsor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.25,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildViewsChip(sponsor.views),
                                const Spacer(),
                                _buildOfferButton(sponsor, offerUrl != null),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(String? logo) {
    return Container(
      width: 60,
      height: 60,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFFACC15)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          color: Colors.white,
          child: logo != null && logo.trim().isNotEmpty
              ? Image.network(
                  logo,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildLogoFallback(),
                )
              : _buildLogoFallback(),
        ),
      ),
    );
  }

  Widget _buildLogoFallback() {
    return const Icon(
      Icons.business_rounded,
      color: Color(0xFFB45309),
      size: 24,
    );
  }

  Widget _buildFeaturedChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
        ),
      ),
      child: const Text(
        'Featured',
        style: TextStyle(
          color: Color(0xFFD97706),
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildViewsChip(int views) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.visibility_outlined,
              size: 12, color: Color(0xFF6B7280)),
          const SizedBox(width: 4),
          Text(
            '$views views',
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferButton(GoldSponsor sponsor, bool enabled) {
    if (!enabled) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: () => _openOffer(sponsor),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'View Offer',
              style: TextStyle(
                color: Color(0xFFF97316),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.open_in_new_rounded,
                size: 13, color: Color(0xFFF97316)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 24),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 0),
      itemBuilder: (_, __) {
        return Container(
          height: 96,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFFE5E7EB).withValues(alpha: 0.92),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return AdsyRefreshIndicator(
      color: const Color(0xFFD97706),
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        children: [
          const SizedBox(height: 80),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              children: const [
                Icon(Icons.workspace_premium,
                    size: 46, color: Color(0xFFF59E0B)),
                SizedBox(height: 12),
                Text(
                  'No sponsors available',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF78350F),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Please check again later.',
                  style: TextStyle(color: Color(0xFF92400E)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
