import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';

/// AuthGuard wraps a protected screen and redirects unauthenticated users
/// to the login screen immediately, preventing any access to protected routes.
///
/// Usage:
///   builder = const AuthGuard(child: UserListScreen());
class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isLoggedIn) {
      // Schedule a redirect after the current frame to avoid build-time navigation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!authProvider.isLoggedIn) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      });
      // Render a clean blank/loading scaffold while the redirect fires to avoid duplicate LoginScreen state
      return const Scaffold(
        body: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return child;
  }
}
