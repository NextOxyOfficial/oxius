import 'package:flutter/material.dart';
import '../services/user_state_service.dart';
import '../pages/login_page.dart';

/// Authentication Guard Middleware
/// Similar to Vue's auth.ts middleware for protecting routes
/// Use this to wrap any widget that requires authentication
class AuthGuard extends StatelessWidget {
  final Widget child;
  final String? redirectRoute;
  final bool requireAuth;

  const AuthGuard({
    super.key,
    required this.child,
    this.redirectRoute,
    this.requireAuth = true,
  });

  @override
  Widget build(BuildContext context) {
    final userState = UserStateService();

    return ListenableBuilder(
      listenable: userState,
      builder: (context, _) {
        // If authentication is required and user is not authenticated
        if (requireAuth && !userState.isAuthenticated) {
          // Show login page or redirect
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ),
              );
            }
          });
          
          // Show loading while redirecting
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF10B981),
              ),
            ),
          );
        }

        // User is authenticated or auth not required, show child
        return child;
      },
    );
  }
}

/// Route Guard Helper Function
/// Use this in route generation to protect routes
class AuthRouteGuard {
  /// Check if user can access a route
  static bool canAccessRoute(String route, UserStateService userState) {
    // Public routes that don't require authentication
    final publicRoutes = [
      '/',
      '/login',
      '/register',
      '/about',
      '/contact',
      '/privacy',
      '/terms',
      '/order',
    ];

    // Check if route is public
    for (final publicRoute in publicRoutes) {
      if (route == publicRoute || route.startsWith('$publicRoute/')) {
        return true;
      }
    }

    // Protected route - check authentication
    return userState.isAuthenticated;
  }

  /// Navigate with authentication check
  static Future<void> navigateWithGuard({
    required BuildContext context,
    required String route,
    Map<String, dynamic>? arguments,
  }) async {
    final userState = UserStateService();

    if (canAccessRoute(route, userState)) {
      // User can access, navigate normally
      if (context.mounted) {
        await Navigator.of(context).pushNamed(
          route,
          arguments: arguments,
        );
      }
    } else {
      // User needs to login first
      if (context.mounted) {
        // Show message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to access this feature'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to login with return route
        await Navigator.of(context).pushNamed(
          '/login',
          arguments: {'returnRoute': route, 'arguments': arguments},
        );
      }
    }
  }

  /// Push replacement with authentication check
  static Future<void> pushReplacementWithGuard({
    required BuildContext context,
    required String route,
    Map<String, dynamic>? arguments,
  }) async {
    final userState = UserStateService();

    if (canAccessRoute(route, userState)) {
      if (context.mounted) {
        await Navigator.of(context).pushReplacementNamed(
          route,
          arguments: arguments,
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to access this feature'),
            backgroundColor: Colors.orange,
          ),
        );

        await Navigator.of(context).pushReplacementNamed(
          '/login',
          arguments: {'returnRoute': route, 'arguments': arguments},
        );
      }
    }
  }
}

/// Extension on BuildContext for easier auth navigation
extension AuthNavigationExtension on BuildContext {
  /// Navigate to a route with automatic authentication check
  Future<void> navigateWithAuth(String route, {Map<String, dynamic>? arguments}) async {
    await AuthRouteGuard.navigateWithGuard(
      context: this,
      route: route,
      arguments: arguments,
    );
  }

  /// Push replacement with automatic authentication check
  Future<void> pushReplacementWithAuth(String route, {Map<String, dynamic>? arguments}) async {
    await AuthRouteGuard.pushReplacementWithGuard(
      context: this,
      route: route,
      arguments: arguments,
    );
  }
}
