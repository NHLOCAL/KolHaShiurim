import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:torah_shiurim_transfer/features/admin_panel/device_management_tab.dart';
import 'package:torah_shiurim_transfer/features/admin_panel/rabbi_management_tab.dart';
import 'package:torah_shiurim_transfer/features/admin_panel/user_management_tab.dart';
import 'package:torah_shiurim_transfer/features/admin_panel/widgets/settings_tab.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.person_outline), text: 'משתמשים'),
              Tab(icon: Icon(Icons.mic_external_on_outlined), text: 'רבנים'),
              Tab(icon: Icon(Icons.usb_outlined), text: 'התקנים'),
              Tab(icon: Icon(Icons.settings_outlined), text: 'הגדרות'),
              Tab(icon: Icon(Icons.info_outline), text: 'אודות'),
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
            _AboutTab(),
          ],
        ),
      ),
    );
  }
}

class _AboutTab extends StatelessWidget {
  const _AboutTab();

  Future<void> _launchUri(BuildContext context, Uri uri) async {
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('לא ניתן לפתוח את הקישור: ${uri.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final linkStyle = TextStyle(
      color: Theme.of(context).colorScheme.primary,
      decoration: TextDecoration.underline,
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'אודות התוכנה',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'מערכת העברת שיעורים מאובטחת',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Divider(height: 32),
                    const Text(
                      'מערכת זו, פרי הפיתוח של "זה קל מערכות", היא פלטפורמה ייעודית לניהול והעברה מאובטחת של הקלטות שיעורי תורה. התוכנה פותחה במיוחד כדי לייעל ולהסדיר את תהליך הוספת השיעורים החדשים למאגר המרכזי.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    const ListTile(
                      leading: Icon(Icons.business_center_outlined),
                      title: Text('פותח ע"י: NH Local'),
                      subtitle: Text('חברת "זה קל מערכות"'),
                      minLeadingWidth: 20,
                    ),
                    ListTile(
                      leading: const Icon(Icons.alternate_email_outlined),
                      title: const Text('ליצירת קשר וקבלת רישיון'),
                      subtitle: Text('nh.local11@gmail.com', style: linkStyle),
                      onTap: () {
                        final emailUri = Uri(
                          scheme: 'https',
                          host: 'mail.google.com',
                          path: 'mail/',
                          queryParameters: {
                            'view': 'cm',
                            'fs': '1',
                            'to': 'nh.local11@gmail.com',
                            'su': 'פנייה בנוגע לתוכנת קול השיעורים',
                          },
                        );
                        _launchUri(context, emailUri);
                      },
                      minLeadingWidth: 20,
                    ),
                    ListTile(
                      leading: const Icon(Icons.link_outlined),
                      title: const Text('אתר המפתח'),
                      subtitle: Text('nhlocal.github.io', style: linkStyle),
                      onTap: () => _launchUri(
                        context,
                        Uri.parse('https://nhlocal.github.io'),
                      ),
                      minLeadingWidth: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
