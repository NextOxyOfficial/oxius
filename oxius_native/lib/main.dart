import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/app_config.dart';
import 'services/fcm_service.dart';
import 'screens/home_screen.dart';
import 'screens/inbox_screen.dart';
import 'screens/my_gigs_screen.dart';
import 'screens/micro_gigs_screen.dart';
import 'screens/post_gig_screen.dart';
import 'screens/business_network/business_network_screen.dart';
import 'screens/business_network/mindforce_screen.dart';
import 'screens/business_network/profile_screen.dart';
import 'screens/notification_permission_gate.dart';
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
import 'screens/eshop_manager/eshop_manager_screen.dart';
import 'screens/news_screen.dart';
import 'screens/about_screen.dart';
import 'screens/faq_screen.dart';
import 'screens/contact_us_screen.dart';
import 'screens/refer_friend_screen.dart';
import 'screens/terms_and_conditions_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/elearning_screen.dart';
import 'pages/login_page.dart';
import 'pages/reset_password_page.dart';
import 'pages/register_page.dart';
import 'services/user_state_service.dart';
import 'services/translation_service.dart';
import 'models/cart_item.dart';
import 'screens/call_screen.dart';

void main() async {
  try {
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
    
    // Initialize Firebase
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
    
    // Initialize FCM
    print('Initializing FCM...');
    await FCMService.initialize();
    print('FCM initialized successfully');
    
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
      await FCMService.syncTokenWithBackend();
    } else {
      print('No existing session found');
    }
    
    runApp(MyApp(userState: userState));
  } catch (e, stackTrace) {
    print('Error during app initialization: $e');
    print('Stack trace: $stackTrace');
    
    // Run app with minimal setup if initialization fails
    runApp(
      MaterialApp(
        title: 'AdsyClub',
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'App initialization failed',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Error: $e'),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
            navigatorKey: FCMService.navigatorKey,
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
            navigatorKey: FCMService.navigatorKey,
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
            '/': (context) => const NotificationPermissionGate(
              child: HomeScreen(),
            ),
            '/login': (context) => const LoginPageRedesigned(),
            '/register': (context) => const RegisterPage(),
            '/reset-password': (context) => const ResetPasswordPage(),
            '/inbox': (context) => const InboxScreen(),
            '/support': (context) => const InboxScreen(initialTab: 2),
            '/my-gigs': (context) => const MyGigsScreen(),
            '/micro-gigs': (context) => const MicroGigsScreen(),
            '/post-a-gig': (context) => const PostGigScreen(),
            '/business-network': (context) => const BusinessNetworkScreen(),
            '/mindforce': (context) => const MindForceScreen(),
            '/courses': (context) => const ElearningScreen(),
            '/elearning': (context) => const ElearningScreen(),
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
            } else if (settings.name == '/eshop-manager') {
              return MaterialPageRoute(
                builder: (context) => const EshopManagerScreen(),
              );
            } else if (settings.name == '/seller-profile') {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => SellerProfileScreen(
                  userId: args?['userId'],
                ),
              );
            } else if (settings.name == '/business-network/profile') {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => ProfileScreen(
                  userId: args?['userId'] ?? '',
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
            } else if (settings.name == '/call') {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => CallScreen(
                  channelName: args?['channelName'] ?? '',
                  calleeId: args?['calleeId'] ?? args?['callerId'] ?? '',
                  calleeName: args?['calleeName'] ?? args?['callerName'] ?? 'Unknown',
                  calleeAvatar: args?['calleeAvatar'] ?? args?['callerAvatar'],
                  isIncoming: args?['isIncoming'] ?? false,
                  callType: args?['callType'] ?? 'video',
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