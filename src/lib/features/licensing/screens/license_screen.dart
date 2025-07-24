import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kol_hashiurim/core/license/license_manager.dart';
import 'package:kol_hashiurim/core/providers/providers.dart';
import 'package:url_launcher/url_launcher.dart';

class LicenseScreen extends ConsumerStatefulWidget {
  final LicenseManager licenseManager;
  const LicenseScreen({required this.licenseManager, super.key});

  @override
  ConsumerState<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends ConsumerState<LicenseScreen> {
  final _controller = TextEditingController();
  String? _statusMessage;
  bool _isLoading = false;
  String _hardwareFingerprint = 'טוען טביעת אצבע...';

  @override
  void initState() {
    super.initState();
    _pasteFromClipboard();
    _loadFingerprint();
  }

  Future<void> _loadFingerprint() async {
    final fp = await widget.licenseManager.getHardwareFingerprint();
    if (mounted) {
      setState(() {
        _hardwareFingerprint = fp;
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trimLeft().startsWith('{')) {
      setState(() {
        _controller.text = data.text!;
        _statusMessage = 'הרישיון הודבק מלוח העריכה.';
      });
    }
  }

  Future<void> _loadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'lic'],
    );
    if (result != null) {
      try {
        final content = await File(result.files.single.path!).readAsString();
        setState(() {
          _controller.text = content;
          _statusMessage = 'הרישיון נטען מקובץ.';
        });
      } catch (e) {
        setState(() {
          _statusMessage = 'שגיאה בקריאת הקובץ.';
        });
      }
    }
  }

  Future<void> _saveFingerprintToFile() async {
    if (_hardwareFingerprint.startsWith('טוען')) return;

    try {
      const fileName = 'hardware_fingerprint.txt';
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'שמור קובץ טביעת אצבע',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsString(_hardwareFingerprint);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('הקובץ נשמר בהצלחה: $result'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בשמירת הקובץ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _verify() async {
    if (_controller.text.isEmpty) {
      setState(() => _statusMessage = 'יש להדביק או לטעון רישיון תחילה.');
      return;
    }
    setState(() {
      _isLoading = true;
      _statusMessage = 'מאמת רישיון...';
    });

    final logService = ref.read(logServiceProvider);

    final valid = await widget.licenseManager.verifyAndSaveLicense(
      _controller.text,
      logService,
    );

    if (mounted) {
      if (valid) {
        ref.invalidate(licenseStatusProvider);
      } else {
        setState(() {
          _statusMessage = 'הרישיון אינו תקף או שפג תוקפו.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchUri(BuildContext context, Uri uri) async {
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('לא ניתן לפתוח את הקישור: ${uri.toString()}')),
        );
      }
    }
  }

  Widget _buildAboutCard(BuildContext context) {
    final linkStyle = TextStyle(
      color: Theme.of(context).colorScheme.primary,
      decoration: TextDecoration.underline,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'אודות התוכנה',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'מערכת העברת שיעורים מאובטחת',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Divider(height: 24),
            const ListTile(
              leading: Icon(Icons.business_center_outlined),
              title: Text('פותח ע"י: NH Local'),
              subtitle: Text('זה קל מערכות'),
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
              onTap: () =>
                  _launchUri(context, Uri.parse('https://nhlocal.github.io')),
              minLeadingWidth: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHardwareFingerprintCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            const Text(
              'שלח את "טביעת האצבע" למפתח לקבלת רישיון:',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: SelectableText(
                    _hardwareFingerprint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: 'העתק טביעת אצבע',
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: _hardwareFingerprint),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('טביעת אצבע הועתקה ללוח.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    ref
                        .read(logServiceProvider)
                        .logUserActivity(
                          'Hardware fingerprint copied to clipboard.',
                        );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.save_alt, size: 18),
                  tooltip: 'שמור לקובץ',
                  onPressed: _saveFingerprintToFile,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('הפעלת רישיון התוכנה')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              _buildAboutCard(context),
              const SizedBox(height: 16),
              _buildHardwareFingerprintCard(context),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              const Text(
                'לאחר קבלת הרישיון, הדבק אותו כאן או טען את הקובץ.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'הדבק רישיון (JSON)',
                ),
                onTap: _pasteFromClipboard,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.file_open),
                    onPressed: _isLoading ? null : _loadFile,
                    label: const Text('טען מקובץ'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.verified_user),
                    onPressed: _isLoading ? null : _verify,
                    label: const Text('הפעל'),
                  ),
                ],
              ),
              if (_statusMessage != null) ...[
                const SizedBox(height: 20),
                Text(
                  _statusMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        _statusMessage!.contains('שגיאה') ||
                            _statusMessage!.contains('אינו תקף')
                        ? Colors.red
                        : Colors.green.shade800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
