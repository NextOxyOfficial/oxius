import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/inbox_screen.dart';
import 'screens/my_gigs_screen.dart';
import 'screens/post_gig_screen.dart';
import 'screens/classified_category_list_screen.dart';
import 'screens/classified_post_details_screen.dart';
import 'screens/classified_post_form_screen.dart';
import 'screens/my_classified_posts_screen.dart';
import 'pages/login_page.dart';
import 'services/auth_service.dart';
import 'services/user_state_service.dart';
import 'services/translation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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

        return MaterialApp(
          title: 'AdsyClub Native',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF10B981)),
            useMaterial3: true,
            textTheme: GoogleFonts.robotoTextTheme(),
          ),
          // Use initialRoute instead of home to avoid conflict
          initialRoute: '/',
          routes: {
            '/': (context) => const HomeScreen(),
            '/login': (context) => const LoginPage(),
            '/inbox': (context) => const InboxScreen(),
            '/my-gigs': (context) => const MyGigsScreen(),
            '/post-a-gig': (context) => const PostGigScreen(),
            '/deposit-withdraw': (context) => Scaffold(
              appBar: AppBar(title: const Text('Deposit & Withdraw')),
              body: const Center(child: Text('Coming Soon!')),
            ),
            '/pending-tasks': (context) => Scaffold(
              appBar: AppBar(title: const Text('Pending Tasks')),
              body: const Center(child: Text('Coming Soon!')),
            ),
            '/mobile-recharge': (context) => Scaffold(
              appBar: AppBar(title: const Text('Mobile Recharge')),
              body: const Center(child: Text('Coming Soon!')),
            ),
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
            }
            return null;
          },
        );
      },
    );
  }
}