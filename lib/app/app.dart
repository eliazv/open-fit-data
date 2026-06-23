import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/shell/app_shell.dart';
import 'providers.dart';
import 'theme.dart';

/// True quando l'onboarding è stato completato almeno una volta.
final onboardingDoneProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(archiveRepositoryProvider);
  final value = await repo.getMeta(MetaKeys.onboardingDone);
  return value == 'true';
});

class OpenFitDataApp extends ConsumerWidget {
  const OpenFitDataApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const _RootGate(),
    );
  }
}

class _RootGate extends ConsumerWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = ref.watch(onboardingDoneProvider);
    return done.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const OnboardingScreen(),
      data: (isDone) => isDone ? const AppShell() : const OnboardingScreen(),
    );
  }
}
