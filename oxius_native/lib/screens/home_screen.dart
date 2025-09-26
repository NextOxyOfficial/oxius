import 'package:flutter/material.dart';
import '../widgets/header.dart';
import '../widgets/mobile_drawer.dart';
import '../widgets/hero_banner.dart';
import '../widgets/sale_category.dart';
import '../widgets/classified_services_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      drawer: const MobileDrawer(),
      body: CustomScrollView(
        slivers: [
          const AppHeader(
            key: ValueKey('home_header'),
            identifier: 'home',
          ),
          SliverToBoxAdapter(child: const HeroBanner()),
          SliverToBoxAdapter(child: const SaleCategory()),
          SliverToBoxAdapter(child: const ClassifiedServicesSection()),
        ],
      ),
    );
  }
}