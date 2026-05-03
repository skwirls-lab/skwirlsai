import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import 'welcome_screen.dart';
import 'hardware_analysis_screen.dart';
import 'model_download_screen.dart';
import 'auth_screen.dart';

class OnboardingFlow extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const OnboardingFlow({super.key, required this.onComplete});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  int _currentStep = 0;
  String? _selectedModelId;

  @override
  Widget build(BuildContext context) {
    return switch (_currentStep) {
      0 => WelcomeScreen(
          onGetStarted: () => setState(() => _currentStep = 1),
        ),
      1 => HardwareAnalysisScreen(
          onModelSelected: (modelId) {
            _selectedModelId = modelId;
            setState(() => _currentStep = 2);
          },
          onCustomModel: () {
            // Skip download, go to auth
            setState(() => _currentStep = 3);
          },
        ),
      2 => ModelDownloadScreen(
          modelId: _selectedModelId!,
          onComplete: () => setState(() => _currentStep = 3),
          onSkip: () => setState(() => _currentStep = 3),
        ),
      3 => AuthScreen(
          onComplete: () async {
            await ref.read(settingsProvider.notifier).completeOnboarding();
            widget.onComplete();
          },
        ),
      _ => WelcomeScreen(
          onGetStarted: () => setState(() => _currentStep = 1),
        ),
    };
  }
}
