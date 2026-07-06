import 'package:flutter/material.dart';

import '../../app.dart';
import 'email_verification_screen.dart';
import 'main_shell_screen.dart';
import 'onboarding_screen.dart';
import 'welcome_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = OceanMatchScope.of(context);
    if (!controller.isAuthenticated) {
      return const WelcomeScreen();
    }
    if (!controller.hasActiveAccount) {
      return const EmailVerificationScreen();
    }
    if (!controller.isProfileComplete) {
      return const OnboardingScreen();
    }
    return const MainShellScreen();
  }
}
