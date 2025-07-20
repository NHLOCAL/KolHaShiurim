import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:torah_shiurim_transfer/core/providers/providers.dart';
import 'package:torah_shiurim_transfer/features/admin_panel/device_management_tab.dart';
import 'package:torah_shiurim_transfer/features/admin_panel/rabbi_management_tab.dart';
import 'package:torah_shiurim_transfer/features/admin_panel/user_management_tab.dart';
import 'package:torah_shiurim_transfer/features/admin_panel/widgets/settings_tab.dart';

class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The log service is no longer used directly in this shell widget.
    // ref.read(logServiceProvider).logInfo('Admin Panel screen opened.');

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('פאנל ניהול'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'התנתקות',
              onPressed: () {
                // Log service is available via ref here if needed for the logout action
                ref
                    .read(logServiceProvider)
                    .logUserActivity('Admin clicked logout button.');
                ref.read(authStateProvider.notifier).logout();
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.person_outline), text: 'משתמשים'),
              Tab(icon: Icon(Icons.mic_external_on_outlined), text: 'רבנים'),
              Tab(icon: Icon(Icons.usb_outlined), text: 'התקנים'),
              Tab(icon: Icon(Icons.settings_outlined), text: 'הגדרות'),
            ],
          ),
        ),
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            UserManagementTab(),
            RabbiManagementTab(),
            DeviceManagementTab(),
            SettingsTab(),
          ],
        ),
      ),
    );
  }
}
