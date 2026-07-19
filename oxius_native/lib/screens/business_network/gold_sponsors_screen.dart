import 'package:flutter/material.dart';

import '../../models/gold_sponsor_models.dart';
import '../../services/gold_sponsor_service.dart';
import '../../widgets/business_network/gold_sponsors_slider.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'become_gold_sponsor_screen.dart';

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

  // Open the shared sponsor details bottom sheet (same as the feed slider)
  // instead of jumping straight to the sponsor's external URL.
  void _openOffer(GoldSponsor sponsor) {
    showGoldSponsorDetails(context, sponsor);
  }

  String? _offerUrl(GoldSponsor sponsor) {
    final website = sponsor.website?.trim();
    if (website != null && website.isNotEmpty) return website;
    final profileUrl = sponsor.profileUrl?.trim();
    if (profileUrl != null && profileUrl.isNotEmpty) return profileUrl;
    return null;
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: FutureBuilder<List<GoldSponsor>>(
        future: _sponsorsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
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
              separatorBuilder: (_, __) => const SizedBox(height: 0),
              itemBuilder: (context, index) {
                return _buildSponsorCard(sponsors[index]);
              },
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      foregroundColor: const Color(0xFF0F172A),
      elevation: 0.5,
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Gold Sponsors',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              height: 1.1,
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: 1),
          Text(
            'Premium partners and exclusive offers',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
      actions: [
        // Apply / become a sponsor
        InkWell(
          onTap: _openBecomeSponsor,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add_rounded,
                color: Color(0xFFD97706), size: 22),
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  void _openBecomeSponsor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.94,
          child: const BecomeGoldSponsorScreen(),
        ),
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
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildLogo(sponsor.logo),
                      const SizedBox(width: 12),
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
                                      fontWeight: FontWeight.w700,
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
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.3,
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
    // FIXED square logo. It used to be AspectRatio(1) stretched to the info
    // column's intrinsic height — on devices where the Bengali text renders
    // taller, the logo ballooned and squeezed/truncated the right column.
    return SizedBox(
      width: 64,
      height: 64,
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
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
    // Plain text (no bordered chip) — cleaner, less boxed look.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.visibility_outlined,
            size: 13, color: Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Text(
          '$views views',
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
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
                color: Color(0xFFD97706),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.open_in_new_rounded,
                size: 13, color: Color(0xFFD97706)),
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
