import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/auth_provider.dart';

// PLACEHOLDER - replaced by the real screen in a later step.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This is the Profile page.'),
            const SizedBox(height: 16),
            // TEMPORARY: lets us test login/logout until the real profile exists.
            ElevatedButton(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              child: const Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }
}
