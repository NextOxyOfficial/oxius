import 'package:flutter/material.dart';

import '../../models/gold_sponsor_models.dart';
import '../../services/gold_sponsor_service.dart';
import '../../utils/url_launcher_utils.dart';

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
      backgroundColor: const Color(0xFFFFFBEB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: FutureBuilder<List<GoldSponsor>>(
                future: _sponsorsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingList();
                  }

                  final sponsors = snapshot.data ?? [];
                  if (sponsors.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    color: const Color(0xFFD97706),
                    onRefresh: _refresh,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                      itemCount: sponsors.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildSponsorCard(sponsors[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.30)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB45309).withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF92400E),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Gold Sponsors',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF78350F),
                    height: 1.05,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Premium partners and exclusive offers',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFFACC15)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.workspace_premium, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSponsorCard(GoldSponsor sponsor) {
    final offerUrl = _offerUrl(sponsor);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE68A)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF92400E).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLogo(sponsor.logo),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        sponsor.businessName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    if (sponsor.isFeatured) _buildFeaturedChip(),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  _descriptionFor(sponsor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 12),
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
    );
  }

  Widget _buildLogo(String? logo) {
    return Container(
      width: 62,
      height: 62,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFFACC15)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.20),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipOval(
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
      size: 26,
    );
  }

  Widget _buildFeaturedChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.45)),
      ),
      child: const Text(
        'Featured',
        style: TextStyle(
          color: Color(0xFFD97706),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildViewsChip(int views) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.visibility_outlined, size: 13, color: Color(0xFF6B7280)),
          const SizedBox(width: 4),
          Text(
            '$views views',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferButton(GoldSponsor sponsor, bool enabled) {
    return InkWell(
      onTap: enabled ? () => _openOffer(sponsor) : null,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
                )
              : null,
          color: enabled ? null : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              enabled ? 'View Offer' : 'No Link',
              style: TextStyle(
                color: enabled ? Colors.white : const Color(0xFF6B7280),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (enabled) ...[
              const SizedBox(width: 5),
              const Icon(Icons.open_in_new_rounded, size: 13, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) {
        return Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.70),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
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
                Icon(Icons.workspace_premium, size: 46, color: Color(0xFFF59E0B)),
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
