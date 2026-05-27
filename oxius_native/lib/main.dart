import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'utils/app_fonts.dart';
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
import 'widgets/classified_services_section.dart';
import 'screens/sale_list_screen.dart';
import 'screens/sale_detail_screen.dart';
import 'screens/my_sale_posts_screen.dart';
import 'screens/create_sale_post_screen.dart';
import 'screens/seller_profile_screen.dart';
import 'screens/upgrade_to_pro_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/wallet/wallet_screen.dart';
import 'screens/mobile_recharge/mobile_recharge_screen.dart';
import 'widgets/ios_web_redirect_screen.dart';
import 'utils/payment_policy.dart';
import 'widgets/ios_payment_blocked_widget.dart';
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
import 'screens/food_zone_screen.dart';
import 'screens/settings_screen.dart';
import 'pages/login_page.dart';
import 'pages/reset_password_page.dart';
import 'pages/register_page.dart';
import 'services/deep_link_service.dart';
import 'services/adsyconnect_realtime_service.dart';
import 'services/agora_call_service.dart';
import 'services/app_update_service.dart';
import 'services/rideshare_driver_presence_service.dart';
import 'services/user_state_service.dart';
import 'services/translation_service.dart';
import 'services/online_status_service.dart';
import 'services/telemetry.dart';
import 'models/cart_item.dart';
import 'screens/call_screen.dart';
import 'widgets/ongoing_call_bar.dart';
import 'screens/rideshare/rideshare_screen.dart';
import 'screens/rideshare/rideshare_history_screen.dart';
import 'screens/rideshare/rideshare_vehicles_screen.dart';

/// Runs an async task with a hard timeout. Logs and swallows errors so a single
/// failing init step never blocks app startup (root cause of iPad blank screen).
Future<void> _safeInit(
  String name,
  Future<void> Function() task, {
  Duration timeout = const Duration(seconds: 8),
}) async {
  final span = Telemetry.startSpan('init.$name');
  try {
    await task().timeout(timeout);
    span.stop(success: true);
  } catch (e, stack) {
    span.stop(success: false, extra: {'error_type': e.runtimeType.toString()});
    Telemetry.recordError(e, stack, reason: 'init:$name', fatal: false);
  }
}

void main() async {
  // Production telemetry: capture every uncaught framework / platform /
  // zone error and route it through Telemetry. External sinks (e.g.
  // FirebaseCrashlytics) can plug in by assigning Telemetry.onError /
  // Telemetry.onBreadcrumb after Firebase is initialised.
  Telemetry.installGlobalErrorHandlers();

  WidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------
  // PERFORMANCE: Tune the global Flutter ImageCache.
  // Default = 1000 entries / 100 MB which is OK for small apps, but a
  // super-app with feed/marketplace/news/profile images burns through the
  // 100 MB budget quickly on mid-range devices and triggers re-decode
  // flicker. Raise the byte budget and cap entry count so common in-feed
  // thumbnails are kept hot. Memory is reclaimed automatically on pressure.
  PaintingBinding.instance.imageCache
    ..maximumSize = 400
    ..maximumSizeBytes = 200 * 1024 * 1024; // 200 MB

  // Configure system UI synchronously (cheap, no I/O).
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Create the user state service immediately. Its `isInitializing` flag drives
  // the splash UI in MyApp, so we can show a real Flutter splash instantly
  // instead of leaving the iOS LaunchScreen up while we do network work
  // (which is what caused the App Store reviewer to see a "blank screen" on
  // iPad: heavy awaits before runApp() were hanging on Apple's network).
  final userState = UserStateService();

  // Show the app NOW. MyApp will render the splash because
  // userState.isInitializing is true until _bootstrap completes.
  runApp(MyApp(userState: userState));

  // App lifecycle (foreground/background/inactive/detached) breadcrumbs.
  // Cheap — single observer, no per-frame work.
  WidgetsBinding.instance.addObserver(TelemetryLifecycleObserver());
  Telemetry.event('app.start');

  // Bootstrap everything else in the background, with timeouts.
  // ignore: unawaited_futures
  _bootstrap(userState);
}

Future<void> _bootstrap(UserStateService userState) async {
  AppConfig.printConfig();

  // -----------------------------------------------------------------
  // STAGE 1 — cheap, must run before anything async-network.
  // Run synchronously-ish so subsequent stages can depend on them.
  // -----------------------------------------------------------------
  await _safeInit('preflightCallStateCleanup',
      () => FCMService.preflightCallStateCleanup());

  await _safeInit('systemUIMode', () async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  });

  // Firebase MUST complete before FCM init (FCM depends on FirebaseApp).
  await _safeInit(
    'Firebase',
    () => Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ),
    timeout: const Duration(seconds: 10),
  );

  // -----------------------------------------------------------------
  // STAGE 2 — independent inits run in PARALLEL.
  // Previously these 5 awaits were sequential ~3-4 s on cold start.
  // Future.wait drops it to the duration of the slowest one.
  // -----------------------------------------------------------------
  await Future.wait([
    _safeInit('FCM', () => FCMService.initialize(),
        timeout: const Duration(seconds: 10)),
    _safeInit(
        'IOSPermissions', () => AgoraCallService.preRegisterIOSPermissions()),
    _safeInit('RideshareDriverPresence',
        () => RideshareDriverPresenceService.initialize()),
    _safeInit('Translation', () async {
      await TranslationService().initialize();
    }),
  ]);

  // Consume any local notification tap that happened while app was killed.
  // Must run after FCMService.initialize() so the navigator key is set up.
  await _safeInit('FCMPendingNotification',
      () => FCMService.consumePendingLocalNotificationPayload());

  // User session is the most important – give it a slightly longer timeout
  // but still bounded so the splash always resolves.
  await _safeInit('UserState', () => userState.initialize(),
      timeout: const Duration(seconds: 12));

  await _safeInit('DeepLink', () => DeepLinkService.instance.init());

  if (userState.isAuthenticated) {
    print('Session restored: ${userState.userName}');
    // Post-auth inits — independent, run in parallel.
    await Future.wait([
      _safeInit(
          'FCM auth state', () => FCMService.handleAuthenticationState(true)),
      _safeInit(
          'Agora restore', () => AgoraCallService.restorePersistedCallState()),
      _safeInit('FCM token sync', () => FCMService.syncTokenWithBackend()),
      _safeInit('AdsyConnect connect',
          () => AdsyConnectRealtimeService.instance.connect()),
      _safeInit('RideshareDriverPresence restore',
          () => RideshareDriverPresenceService.restoreIfNeeded()),
    ]);
    try {
      OnlineStatusService.start();
    } catch (e) {
      print('[init] OnlineStatusService FAILED (non-fatal): $e');
    }
  } else {
    print('No existing session');
    await _safeInit(
        'Agora clear', () => AgoraCallService.clearPersistedCallState());
    await _safeInit(
        'FCM auth state', () => FCMService.handleAuthenticationState(false));
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
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme:
                  ColorScheme.fromSeed(seedColor: const Color(0xFF10B981)),
              useMaterial3: true,
              textTheme: AppFonts.robotoTextTheme(),
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
            navigatorObservers: [
              FCMService.routeObserver,
              TelemetryNavigatorObserver(),
            ],
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              // Global tap-to-dismiss keyboard. Wrapping at MaterialApp.builder
              // level means every screen inherits the behavior without each
              // route needing its own GestureDetector.
              return AppUpdateGate(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    final currentFocus = FocusScope.of(context);
                    if (!currentFocus.hasPrimaryFocus &&
                        currentFocus.focusedChild != null) {
                      currentFocus.focusedChild!.unfocus();
                    }
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      child ?? const SizedBox.shrink(),
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: OngoingCallBar(),
                      ),
                    ],
                  ),
                ),
              );
            },
            theme: ThemeData(
              colorScheme:
                  ColorScheme.fromSeed(seedColor: const Color(0xFF10B981)),
              useMaterial3: true,
              textTheme: AppFonts.robotoTextTheme(),
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
              '/pending-tasks': (context) => const HomeScreen(),
              '/mobile-recharge': (context) => const MobileRechargeScreen(),
              '/upgrade-to-pro': (context) => const UpgradeToProScreen(),
              '/eshop': (context) => const EshopScreen(),
              '/shop-manager': (context) => const EshopManagerScreen(),
              '/classified': (context) => const ClassifiedServicesPage(),
              '/adsy-news': (context) => const NewsScreen(),
              '/about': (context) => const AboutScreen(),
              '/faq': (context) => const FaqScreen(),
              '/contact-us': (context) => const ContactUsScreen(),
              '/refer-a-friend': (context) => const ReferFriendScreen(),
              '/terms-and-conditions': (context) =>
                  const TermsAndConditionsScreen(),
              '/privacy-policy': (context) => const PrivacyPolicyScreen(),
              '/food-zone': (context) => const FoodZoneScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/rideshare': (context) => const RideshareScreen(),
              '/rideshare/history': (context) => const RideshareHistoryScreen(),
              '/rideshare/driver-history': (context) =>
                  const RideshareHistoryScreen(asDriver: true),
              '/rideshare/vehicles': (context) =>
                  const RideshareVehiclesScreen(),
            },
            onGenerateRoute: (settings) {
              final routeUri = Uri.tryParse(settings.name ?? '');
              if (routeUri?.path == '/deposit-withdraw') {
                return MaterialPageRoute(
                  builder: (context) => WalletScreen(
                    paymentCallbackUrl:
                        routeUri?.queryParameters['payment_callback_url'],
                  ),
                );
              }

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
                    userName: args?['userName'],
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
                    calleeName:
                        args?['calleeName'] ?? args?['callerName'] ?? 'Unknown',
                    calleeAvatar:
                        args?['calleeAvatar'] ?? args?['callerAvatar'],
                    callId: args?['callId'] ?? args?['call_id'],
                    isIncoming: args?['isIncoming'] ?? false,
                    callType: args?['callType'] ?? 'video',
                    isReturning: args?['isReturning'] ?? false,
                  ),
                );
              }
              return null;
            },
            // CRITICAL SAFETY NET: if any code calls `Navigator.pushNamed`
            // with a route that does not exist in `routes` or `onGenerateRoute`,
            // Flutter will throw "Could not find a generator for route ...".
            // That exception leaves `Navigator._debugLocked == true` on web,
            // which silently bricks every subsequent tap / push across the
            // entire app until full reload. Returning a fallback route here
            // keeps the navigator transaction clean and surfaces the bug as
            // a visible screen instead of a frozen UI.
            onUnknownRoute: (settings) {
              Telemetry.event('nav.unknown_route', tags: {
                'name': settings.name ?? '<null>',
              });
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Page not found')),
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Route "${settings.name}" is not registered.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
