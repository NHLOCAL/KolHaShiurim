import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:torah_shiurim_transfer/core/providers/providers.dart';

class AuthGateScreen extends ConsumerWidget {
  const AuthGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(strokeWidth: 5),
              ),
              const SizedBox(height: 32),
              Text(
                'ממתין לחיבור התקן הקלטה',
                style: textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'אנא חבר את כונן ההקלטות למחשב כדי להתחיל בתהליך העברת השיעורים.',
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),
              ElevatedButton.icon(
                icon: const Icon(Icons.admin_panel_settings_outlined),
                label: const Text('כניסת מנהל'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  ref.read(authStateProvider.notifier).loginAsAdmin();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
