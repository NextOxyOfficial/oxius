import 'package:flutter/material.dart';
import '../widgets/header.dart';
import '../widgets/footer.dart';
import '../widgets/mobile_drawer.dart';
import '../widgets/mobile_navigation_bar.dart';
import '../widgets/hero_banner.dart';
import '../widgets/sale_category.dart';
import '../widgets/classified_services_section.dart';
import '../services/scroll_direction_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ScrollController _scrollController;
  final ScrollDirectionService _scrollService = ScrollDirectionService();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollService.initialize(_scrollController);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      drawer: const MobileDrawer(),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              const AppHeader(
                key: ValueKey('home_header'),
                identifier: 'home',
              ),
              SliverToBoxAdapter(child: const HeroBanner()),
              SliverToBoxAdapter(child: const SaleCategory()),
              SliverToBoxAdapter(child: const ClassifiedServicesSection()),
              const SliverToBoxAdapter(child: AppFooter()),
            ],
          ),
          
          // Mobile Navigation Bar
          const MobileNavigationBar(),
        ],
      ),
    );
  }
}