import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:torah_shiurim_transfer/core/license/license_manager.dart';
import 'package:torah_shiurim_transfer/core/providers/providers.dart';

class LicenseScreen extends ConsumerStatefulWidget {
  final LicenseManager licenseManager;
  const LicenseScreen({required this.licenseManager, Key? key})
      : super(key: key);

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

  Future<void> _verify() async {
    if (_controller.text.isEmpty) {
      setState(() => _statusMessage = 'יש להדביק או לטעון רישיון תחילה.');
      return;
    }
    setState(() {
      _isLoading = true;
      _statusMessage = 'מאמת רישיון...';
    });

    // Get the log service from the provider
    final logService = ref.read(logServiceProvider);

    // Pass the log service to the verification function
    final valid = await widget.licenseManager
        .verifyAndSaveLicense(_controller.text, logService);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('הפעלת רישיון תוכנה')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'כדי להפעיל את התוכנה, יש לטעון קובץ רישיון תקף.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _controller,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'הדבק רישיון (JSON) או טען מקובץ',
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
                              child: CircularProgressIndicator(strokeWidth: 2))
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
                        color: _statusMessage!.contains('שגיאה') ||
                                _statusMessage!.contains('אינו תקף')
                            ? Colors.red
                            : Colors.green.shade800),
                  ),
                ],
                const Spacer(),
                Card(
                  elevation: 0,
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceVariant
                      .withOpacity(0.5),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        const Text('טביעת אצבע של חומרה זו:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        SelectableText(_hardwareFingerprint,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontFamily: 'monospace', fontSize: 12)),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
