import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/app_config.dart';
import 'screens/home_screen.dart';
import 'screens/inbox_screen.dart';
import 'screens/my_gigs_screen.dart';
import 'screens/post_gig_screen.dart';
import 'screens/business_network/business_network_screen.dart';
import 'screens/business_network/mindforce_screen.dart';
import 'screens/classified_category_list_screen.dart';
import 'screens/classified_post_details_screen.dart';
import 'screens/classified_post_form_screen.dart';
import 'screens/my_classified_posts_screen.dart';
import 'screens/sale_list_screen.dart';
import 'screens/sale_detail_screen.dart';
import 'screens/my_sale_posts_screen.dart';
import 'screens/create_sale_post_screen.dart';
import 'screens/seller_profile_screen.dart';
import 'screens/upgrade_to_pro_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/wallet/wallet_screen.dart';
import 'screens/mobile_recharge/mobile_recharge_screen.dart';
import 'screens/eshop_screen.dart';
import 'screens/eshop_manager_screen.dart';
import 'screens/news_screen.dart';
import 'screens/about_screen.dart';
import 'screens/faq_screen.dart';
import 'screens/contact_us_screen.dart';
import 'screens/refer_friend_screen.dart';
import 'screens/terms_and_conditions_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'pages/login_page.dart';
import 'pages/reset_password_page.dart';
import 'pages/register_page.dart';
import 'services/auth_service.dart';
import 'services/user_state_service.dart';
import 'services/translation_service.dart';
import 'models/cart_item.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set status bar to white with dark icons
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Print app configuration (shows which environment is active)
  AppConfig.printConfig();
  
  // Initialize translation service
  print('Initializing translation service...');
  final translationService = TranslationService();
  await translationService.initialize();
  print('Translation service initialized with locale: ${translationService.currentLanguage}');
  
  // Initialize user state service (this will initialize auth service internally)
  print('Initializing authentication session...');
  final userState = UserStateService();
  await userState.initialize();
  
  if (userState.isAuthenticated) {
    print('Session restored successfully for user: ${userState.userName}');
  } else {
    print('No existing session found');
  }
  
  runApp(MyApp(userState: userState));
}

class MyApp extends StatelessWidget {
  final UserStateService userState;
  
  const MyApp({super.key, required this.userState});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: userState,
      builder: (context, child) {
        // Show splash screen while initializing
        if (userState.isInitializing) {
          return MaterialApp(
            title: 'AdsyClub Native',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF10B981)),
              useMaterial3: true,
              textTheme: GoogleFonts.robotoTextTheme(),
              appBarTheme: const AppBarTheme(
                systemOverlayStyle: SystemUiOverlayStyle(
                  statusBarColor: Colors.white,
                  statusBarIconBrightness: Brightness.dark,
                  statusBarBrightness: Brightness.light,
                ),
              ),
            ),
            home: const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF10B981),
                ),
              ),
            ),
          );
        }

        return Portal(
          child: MaterialApp(
            title: 'AdsyClub Native',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF10B981)),
              useMaterial3: true,
              textTheme: GoogleFonts.robotoTextTheme(),
              appBarTheme: const AppBarTheme(
                systemOverlayStyle: SystemUiOverlayStyle(
                  statusBarColor: Colors.white,
                  statusBarIconBrightness: Brightness.dark,
                  statusBarBrightness: Brightness.light,
                ),
              ),
            ),
            // Use initialRoute instead of home to avoid conflict
            initialRoute: '/',
            routes: {
            '/': (context) => const HomeScreen(),
            '/login': (context) => const LoginPageRedesigned(),
            '/register': (context) => const RegisterPage(),
            '/reset-password': (context) => const ResetPasswordPage(),
            '/inbox': (context) => const InboxScreen(),
            '/my-gigs': (context) => const MyGigsScreen(),
            '/post-a-gig': (context) => const PostGigScreen(),
            '/business-network': (context) => const BusinessNetworkScreen(),
            '/mindforce': (context) => const MindForceScreen(),
            '/deposit-withdraw': (context) => const WalletScreen(),
            '/pending-tasks': (context) => Scaffold(
              appBar: AppBar(title: const Text('Pending Tasks')),
              body: const Center(child: Text('Coming Soon!')),
            ),
            '/mobile-recharge': (context) => const MobileRechargeScreen(),
            '/upgrade-to-pro': (context) => const UpgradeToProScreen(),
            '/eshop': (context) => const EshopScreen(),
            '/shop-manager': (context) => const EshopManagerScreen(),
            '/adsy-news': (context) => const NewsScreen(),
            '/about': (context) => const AboutScreen(),
            '/faq': (context) => const FaqScreen(),
            '/contact-us': (context) => const ContactUsScreen(),
            '/refer-a-friend': (context) => const ReferFriendScreen(),
            '/terms-and-conditions': (context) => const TermsAndConditionsScreen(),
            '/privacy-policy': (context) => const PrivacyPolicyScreen(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/classified-category') {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => ClassifiedCategoryListScreen(
                  categoryId: args?['categoryId'] ?? '',
                  categorySlug: args?['categorySlug'] ?? '',
                ),
              );
            } else if (settings.name == '/classified-post-details') {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => ClassifiedPostDetailsScreen(
                  postId: args?['postId'] ?? '',
                  postSlug: args?['postSlug'] ?? '',
                ),
              );
            } else if (settings.name == '/classified-post-form') {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => ClassifiedPostFormScreen(
                  postId: args?['postId'],
                  categoryId: args?['categoryId'],
                ),
              );
            } else if (settings.name == '/my-classified-posts') {
              return MaterialPageRoute(
                builder: (context) => const MyClassifiedPostsScreen(),
              );
            } else if (settings.name == '/sale') {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => SaleListScreen(
                  categoryId: args?['categoryId'],
                  categoryName: args?['categoryName'],
                ),
              );
            } else if (settings.name == '/sale/detail') {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => SaleDetailScreen(
                  slug: args?['slug'],
                  id: args?['id'],
                ),
              );
            } else if (settings.name == '/my-sale-posts') {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => MySalePostsScreen(
                  initialTab: args?['tab'],
                ),
              );
            } else if (settings.name == '/create-sale-post') {
              return MaterialPageRoute(
                builder: (context) => const CreateSalePostScreen(),
              );
            } else if (settings.name == '/seller-profile') {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => SellerProfileScreen(
                  userId: args?['userId'],
                ),
              );
            } else if (settings.name == '/checkout') {
              final args = settings.arguments as Map<String, dynamic>?;
              final cartItems = args?['cartItems'] as List<CartItem>? ?? [];
              return MaterialPageRoute(
                builder: (context) => CheckoutScreen(
                  cartItems: cartItems,
                ),
              );
            }
            return null;
          },
          ),
        );
      },
    );
  }
}