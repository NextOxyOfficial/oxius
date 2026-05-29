import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/workspace_service.dart';
import '../../services/api_service.dart';
import 'all_gigs_tab.dart';
import 'my_gigs_tab.dart';
import 'orders_received_tab.dart';
import 'gigs_ordered_tab.dart';
import 'create_gig_screen.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';

const _indigo = Color(0xFF6366F1);
const _violet = Color(0xFF8B5CF6);
const _slate50 = Color(0xFFF8FAFC);
const _slate100 = Color(0xFFF1F5F9);
const _slate200 = Color(0xFFE2E8F0);
const _slate500 = Color(0xFF64748B);
const _slate800 = Color(0xFF1E293B);

class WorkspaceScreen extends StatefulWidget {
  final int initialTab;

  const WorkspaceScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final WorkspaceService _workspaceService = WorkspaceService();

  List<Map<String, dynamic>> _banners = [];
  int _currentBannerIndex = 0;
  final PageController _bannerController = PageController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _loadBanners();
    _startBannerAutoplay();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _loadBanners() async {
    final banners = await _workspaceService.fetchBanners();
    if (mounted) {
      setState(() => _banners = banners);
    }
  }

  void _startBannerAutoplay() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _banners.isNotEmpty) {
        final nextIndex = (_currentBannerIndex + 1) % _banners.length;
        _bannerController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
        _startBannerAutoplay();
      }
    });
  }

  String _getImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '${ApiService.baseUrl.replaceAll('/api', '')}$url';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _slate50,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // App Bar
            SliverAppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              surfaceTintColor: Colors.white,
              floating: false,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: _slate800),
                onPressed: () => Navigator.pop(context),
              ),
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient:
                          const LinearGradient(colors: [_indigo, _violet]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.workspaces_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Workspaces',
                    style: GoogleFonts.inter(
                      color: _slate800,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              // Banner in expandedHeight
              expandedHeight: _banners.isNotEmpty ? 190 : 0,
              flexibleSpace: _banners.isNotEmpty
                  ? FlexibleSpaceBar(
                      background: Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: _buildBannerSlider(),
                      ),
                    )
                  : null,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: _indigo,
                    unselectedLabelColor: _slate500,
                    indicator: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _slate200),
                    ),
                    dividerColor: Colors.transparent,
                    splashBorderRadius: BorderRadius.circular(12),
                    labelStyle: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, fontSize: 14),
                    unselectedLabelStyle: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, fontSize: 14),
                    tabAlignment: TabAlignment.start,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                    tabs: const [
                      Tab(
                        height: 40,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.explore_rounded, size: 15),
                              SizedBox(width: 5),
                              Text('All Gigs'),
                            ],
                          ),
                        ),
                      ),
                      Tab(
                        height: 40,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_outline_rounded, size: 15),
                              SizedBox(width: 5),
                              Text('My Gigs'),
                            ],
                          ),
                        ),
                      ),
                      Tab(
                        height: 40,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inbox_rounded, size: 15),
                              SizedBox(width: 5),
                              Text('Orders Received'),
                            ],
                          ),
                        ),
                      ),
                      Tab(
                        height: 40,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shopping_bag_outlined, size: 15),
                              SizedBox(width: 5),
                              Text('Gigs Ordered'),
                            ],
                          ),
                        ),
                      ),
                      Tab(
                        height: 40,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_circle_outline_rounded, size: 15),
                              SizedBox(width: 5),
                              Text('Post a Gig'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            const AllGigsTab(),
            const MyGigsTab(),
            const OrdersReceivedTab(),
            const GigsOrderedTab(),
            CreateGigScreen(
              onGigCreated: () {
                _tabController.animateTo(1); // Go to My Gigs
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerSlider() {
    return Container(
      height: 125,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: PageView.builder(
              controller: _bannerController,
              onPageChanged: (index) {
                setState(() => _currentBannerIndex = index);
              },
              itemCount: _banners.length,
              itemBuilder: (context, index) {
                final banner = _banners[index];
                return CachedNetworkImage(
                  imageUrl:
                      _getImageUrl(banner['image_url'] ?? banner['image']),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: AdsyLoadingIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child:
                        const Icon(Icons.image, size: 40, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          // Progress indicators
          if (_banners.length > 1)
            Positioned(
              bottom: 8,
              left: 12,
              right: 12,
              child: Row(
                children: List.generate(
                  _banners.length,
                  (index) => Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _bannerController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      },
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: _currentBannerIndex == index
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
