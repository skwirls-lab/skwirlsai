import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/onboarding/onboarding_flow.dart';

class SkwirlsApp extends ConsumerWidget {
  const SkwirlsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'SkwirlsAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: settings.hasCompletedOnboarding
          ? const HomeScreen()
          : OnboardingFlow(
              onComplete: () {
                // Force rebuild to show home screen
                ref.invalidate(settingsProvider);
              },
            ),
    );
  }
}
