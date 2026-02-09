import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers.dart';
import '../../dashboard/ui/home_screen.dart';
import 'login_screen.dart';
import 'verify_email_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    return authState.when(
      data: (user) {
        if (user == null) return const LoginScreen();
        final needsVerification = user.providerData
                .any((info) => info.providerId == 'password') &&
            !user.emailVerified;
        if (needsVerification) {
          return VerifyEmailScreen(email: user.email ?? '');
        }
        return const HomeScreen();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Auth error: $error')),
      ),
    );
  }
}
