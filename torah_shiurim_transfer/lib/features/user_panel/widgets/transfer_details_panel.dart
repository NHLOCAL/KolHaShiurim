import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:material_hebrew_date_picker/material_hebrew_date_picker.dart';
import 'package:path/path.dart' as p;
import 'package:torah_shiurim_transfer/core/database/database.dart';
import 'package:torah_shiurim_transfer/core/providers/providers.dart';
import 'package:torah_shiurim_transfer/features/user_panel/providers/user_panel_providers.dart';
import 'package:torah_shiurim_transfer/services/log_service.dart';

class TransferDetailsPanel extends ConsumerStatefulWidget {
  final File? selectedFile;
  final VoidCallback onCopyComplete;

  const TransferDetailsPanel({
    super.key,
    required this.selectedFile,
    required this.onCopyComplete,
  });

  @override
  ConsumerState<TransferDetailsPanel> createState() =>
      _TransferDetailsPanelState();
}

class _TransferDetailsPanelState extends ConsumerState<TransferDetailsPanel> {
  UserPermissionInfo? _selectedPermission;
  JewishDate _selectedDate = JewishDate();
  final _topicController = TextEditingController();
  bool _isCopying = false;
  AppSetting? _appSettings;
  late final LogService _logService;

  final List<List<String>> _hebrewKeys = const [
    ['-', '0', '9', '8', '7', '6', '5', '4', '3', '2', '1'],
    ['(', ')', 'פ', 'ם', 'ן', 'ו', 'ט', 'א', 'ר', 'ק', '\''],
    [',', 'ף', 'ך', 'ל', 'ח', 'י', 'ע', 'כ', 'ג', 'ד', 'ש'],
    ['.', 'ץ', 'ת', 'צ', 'מ', 'נ', 'ה', 'ב', 'ס', 'ז'],
  ];

  @override
  void initState() {
    super.initState();
    _logService = ref.read(logServiceProvider);
    _loadSettings();
    _logService.logInfo('Transfer Details Panel initialized.');
  }

  @override
  void didUpdateWidget(covariant TransferDetailsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedFile != null && oldWidget.selectedFile == null) {
      _resetForm();
    }
  }

  Future<void> _loadSettings() async {
    _logService.logInfo('Loading app settings for user panel.');
    try {
      final settings = await ref.read(databaseProvider).getAppSettings();
      if (mounted) {
        setState(() {
          _appSettings = settings;
        });
        _logService.logInfo('App settings loaded successfully for user panel.');
      }
    } catch (e, st) {
      _logService.logError('Failed to load app settings for user panel', e, st);
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _logService.logInfo('Resetting transfer form.');
    setState(() {
      _selectedPermission = null;
      _topicController.clear();
      _selectedDate = JewishDate();
    });
  }

  String _getNewFileName() {
    if (_selectedPermission == null || widget.selectedFile == null) {
      return 'שם קובץ...';
    }
    final formatter = HebrewDateFormatter()
      ..hebrewFormat = true
      ..useGershGershayim = false;
    final dateStr = formatter.format(_selectedDate).replaceAll("'", "׳");
    final topic = _topicController.text.trim();
    final sanitizedTopic = topic.replaceAll(RegExp(r'[\/*?:"><|]'), '');
    final extension = (_appSettings?.convertToMp3 ?? false)
        ? '.mp3'
        : p.extension(widget.selectedFile!.path);
    final fileName =
        'XX - $dateStr - ${_selectedPermission!.rabbi.name}${sanitizedTopic.isNotEmpty ? ' - $sanitizedTopic' : ''}$extension';
    _logService.logInfo('Generated new file name preview: $fileName');
    return fileName;
  }

  Future<String> _determineFinalFileName() async {
    if (_selectedPermission == null || widget.selectedFile == null) {
      _logService.logError(
          "Cannot determine final filename, selection is incomplete.",
          null,
          StackTrace.current);
      throw Exception("Cannot determine filename, selection is incomplete.");
    }

    // 1. Get base info for filename
    final formatter = HebrewDateFormatter()
      ..hebrewFormat = true
      ..useGershGershayim = false;
    final dateStr = formatter.format(_selectedDate).replaceAll("'", "׳");
    final topic = _topicController.text.trim();
    final sanitizedTopic = topic.replaceAll(RegExp(r'[\/*?:"><|]'), '');
    final extension = (_appSettings?.convertToMp3 ?? false)
        ? '.mp3'
        : p.extension(widget.selectedFile!.path);
    final rabbiName = _selectedPermission!.rabbi.name;

    // 2. Determine destination directory
    final baseDirectory = _selectedPermission!.rabbi.targetPath;
    final subDirectory = _selectedPermission!.specificPath;
    final destinationDirectory =
        (subDirectory != null && subDirectory.isNotEmpty)
            ? p.join(baseDirectory, subDirectory)
            : baseDirectory;

    // 3. Find next sequential number based on ALL files in the directory
    int nextNumber = 1;
    try {
      final dir = Directory(destinationDirectory);
      if (await dir.exists()) {
        int maxNumber = 0;
        // This regex finds any file starting with a number and a hyphen,
        // making the numbering global to the folder, regardless of date.
        final regex = RegExp(r'^(\d+)\s*-');

        await for (final entity in dir.list()) {
          if (entity is File) {
            final filename = p.basename(entity.path);
            final match = regex.firstMatch(filename);
            if (match != null) {
              final number = int.tryParse(match.group(1)!);
              if (number != null && number > maxNumber) {
                maxNumber = number;
              }
            }
          }
        }
        nextNumber = maxNumber + 1;
      }
    } catch (e, st) {
      _logService.logError(
          "Error determining next file number in '$destinationDirectory'. Defaulting to 1.",
          e,
          st);
      nextNumber = 1; // Fallback on error
    }

    _logService
        .logInfo("Determined next file number in folder is $nextNumber.");

    // 4. Format and assemble final name
    final formattedNumber = nextNumber.toString().padLeft(2, '0');
    final finalFileName =
        '$formattedNumber - $dateStr - $rabbiName${sanitizedTopic.isNotEmpty ? ' - $sanitizedTopic' : ''}$extension';

    _logService.logInfo('Determined final file name: $finalFileName');
    return finalFileName;
  }

  Future<void> _showPostCopyOptionsDialog(
      File sourceFile, String newFileName) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('העתקה הושלמה!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("הקובץ הועבר בהצלחה בשם:"),
              const SizedBox(height: 8),
              Text(
                newFileName,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text("מה ברצונך לעשות עם קובץ המקור?"),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("השאר קובץ מקור"),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.errorContainer,
                foregroundColor: theme.colorScheme.onErrorContainer,
              ),
              child: const Text("מחק קובץ מקור"),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await sourceFile.delete();
                  _logService.logUserActivity(
                      "Source file ${sourceFile.path} deleted successfully by user request.");
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text("קובץ המקור נמחק בהצלחה."),
                      backgroundColor: Colors.orange,
                    ),
                  );
                } catch (e, st) {
                  _logService.logError(
                      "Failed to delete source file ${sourceFile.path}", e, st);
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text("שגיאה במחיקת קובץ המקור: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );

    ref.read(lastCopiedFileNameProvider.notifier).state = null;
    widget.onCopyComplete();
  }

  Future<void> _copyFile() async {
    if (widget.selectedFile == null ||
        _selectedPermission == null ||
        _appSettings == null) {
      _logService.logWarning(
          'Attempted to copy file with missing selections (file, permission, or settings).');
      return;
    }

    setState(() => _isCopying = true);
    ref.read(lastCopiedFileNameProvider.notifier).state = null;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authState = ref.read(authStateProvider);
    final sourceFile = widget.selectedFile!;

    _logService.logUserActivity(
        'User initiating file transfer for: ${sourceFile.path}');

    try {
      final newFileName = await _determineFinalFileName();
      final baseDirectory = _selectedPermission!.rabbi.targetPath;
      final subDirectory = _selectedPermission!.specificPath;

      final destinationDirectory =
          (subDirectory != null && subDirectory.isNotEmpty)
              ? p.join(baseDirectory, subDirectory)
              : baseDirectory;

      final destinationPath = p.join(destinationDirectory, newFileName);
      final fileService = ref.read(fileServiceProvider);

      _logService.logInfo(
          'Copying/converting file from ${sourceFile.path} to $destinationPath (Convert to MP3: ${_appSettings!.convertToMp3})');
      if (_appSettings!.convertToMp3) {
        await fileService.convertAndCopyFile(
          sourceFile: sourceFile,
          destinationDirectory: destinationDirectory,
          newFileName: newFileName,
          bitrate: _appSettings!.mp3Bitrate,
        );
      } else {
        await fileService.copyFile(
          sourceFile: sourceFile,
          destinationDirectory: destinationDirectory,
          newFileName: newFileName,
        );
      }

      await authState.maybeWhen(
        user: (user, device, mountPath) async {
          await ref.read(databaseProvider).logTransfer(
                TransfersCompanion.insert(
                  userId: user.id,
                  sourceFile: sourceFile.path,
                  destinationFile: destinationPath,
                  timestamp: DateTime.now(),
                ),
              );
          _logService.logUserActivity(
              'Transfer logged for user ${user.name}: Source ${sourceFile.path}, Destination: $destinationPath');
        },
        orElse: () {
          _logService.logInfo(
              'Transfer completed but no user active to log to DB. Source: ${sourceFile.path}, Destination: $destinationPath');
        },
      );

      _logService.logInfo('File transfer successful: $newFileName');

      await _showPostCopyOptionsDialog(sourceFile, newFileName);
    } catch (e, st) {
      _logService.logError(
          'Error during file transfer from ${sourceFile.path}', e, st);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('שגיאה בהעתקת הקובץ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCopying = false);
      }
    }
  }

  Future<void> _pickHebrewDate() async {
    _logService.logUserActivity(
        'User opened Hebrew date picker. Current date: ${_selectedDate.toString()}');
    final initial = _selectedDate.getGregorianCalendar();

    final currentJewishYear = JewishDate().getJewishYear();
    final firstHebrew = (JewishDate()
          ..setJewishDate(currentJewishYear - 30, JewishDate.TISHREI, 1))
        .getGregorianCalendar();
    final lastHebrew = (JewishDate()
          ..setJewishDate(
            currentJewishYear + 50,
            JewishDate.ELUL,
            29,
          ))
        .getGregorianCalendar();

    final DateTime? picked = await showMaterialHebrewDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstHebrew,
      lastDate: lastHebrew,
      hebrewFormat: true,
    );

    if (picked != null) {
      final newJd = JewishDate();
      newJd.setDate(picked);
      setState(() => _selectedDate = newJd);
      _logService.logInfo('User selected Hebrew date: ${newJd.toString()}');
    } else {
      _logService.logInfo('Hebrew date picker cancelled.');
    }
  }

  Widget _buildHebrewKeyboard(Color buttonColor, Color textColor) {
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: buttonColor,
      foregroundColor: textColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(vertical: 16),
    );

    const keyTextStyle = TextStyle(fontSize: 22, fontWeight: FontWeight.bold);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var row in _hebrewKeys)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: Row(
              children: row.map((key) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3.0),
                    child: ElevatedButton(
                      style: buttonStyle,
                      onPressed: () {
                        _topicController.text += key;
                        _topicController.selection = TextSelection.fromPosition(
                            TextPosition(offset: _topicController.text.length));
                        _logService.logInfo(
                            'Hebrew keyboard input: "$key", current topic: "${_topicController.text}"');
                      },
                      child: Text(key, style: keyTextStyle),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.0),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: ElevatedButton(
                    style: buttonStyle.copyWith(
                      padding: WidgetStateProperty.all(
                          const EdgeInsets.symmetric(vertical: 16)),
                    ),
                    onPressed: () {
                      final text = _topicController.text;
                      if (text.isNotEmpty) {
                        _topicController.text =
                            text.substring(0, text.length - 1);
                        _topicController.selection = TextSelection.fromPosition(
                            TextPosition(offset: _topicController.text.length));
                        _logService.logInfo(
                            'Hebrew keyboard backspace, current topic: "${_topicController.text}"');
                      }
                    },
                    child: const Icon(Icons.backspace_outlined, size: 22),
                  ),
                ),
              ),
              Expanded(
                flex: 8,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: ElevatedButton.icon(
                    style: buttonStyle,
                    onPressed: () {
                      _topicController.text += ' ';
                      _logService.logInfo(
                          'Hebrew keyboard space, current topic: "${_topicController.text}"');
                    },
                    icon: const Icon(Icons.space_bar),
                    label: const Text('רווח', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final allowedRabbisAsync = ref.watch(allowedRabbisProvider);
    final lastCopiedFileName = ref.watch(lastCopiedFileNameProvider);

    final theme = Theme.of(context);
    final buttonColor = theme.colorScheme.secondaryContainer;
    final buttonTextColor = theme.colorScheme.onSecondaryContainer;

    if (_appSettings == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(4, 8, 8, 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AbsorbPointer(
          absorbing: _isCopying,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _isCopying ? 0.5 : 1.0,
            child: _buildFormContent(theme, allowedRabbisAsync, buttonColor,
                buttonTextColor, lastCopiedFileName),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent(
      ThemeData theme,
      AsyncValue<List<UserPermissionInfo>> allowedRabbisAsync,
      Color buttonColor,
      Color buttonTextColor,
      String? lastCopiedFileName) {
    if (widget.selectedFile == null) {
      return Center(
        child: (lastCopiedFileName != null)
            ? Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 48),
                      const SizedBox(height: 16),
                      Text('העתקה הושלמה!',
                          style: theme.textTheme.titleLarge
                              ?.copyWith(color: Colors.green.shade800)),
                      const SizedBox(height: 8),
                      Text(lastCopiedFileName, textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      const Text('בחר קובץ נוסף מהרשימה להעתקה.'),
                    ],
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_forward,
                      size: 48, color: theme.disabledColor),
                  const SizedBox(height: 16),
                  Text(
                    'בחר קובץ מהרשימה כדי להתחיל',
                    style: theme.textTheme.headlineSmall,
                  ),
                ],
              ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('פרטי העברה', style: theme.textTheme.headlineSmall),
        const Divider(height: 24),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.file_present),
                  title: const Text('קובץ מקור:'),
                  subtitle: Text(p.basename(widget.selectedFile!.path)),
                ),
                const SizedBox(height: 20),
                allowedRabbisAsync.when(
                  data: (permissions) =>
                      DropdownButtonFormField<UserPermissionInfo>(
                    value: _selectedPermission,
                    items: permissions
                        .map((p) => DropdownMenuItem(
                            value: p, child: Text(p.rabbi.name)))
                        .toList(),
                    onChanged: (val) {
                      setState(() => _selectedPermission = val);
                      _logService.logUserActivity(
                          'User selected rabbi: ${val?.rabbi.name}');
                    },
                    decoration: const InputDecoration(
                        labelText: 'בחר רב', border: OutlineInputBorder()),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) {
                    _logService.logError(
                        'Error loading allowed rabbis', err, stack);
                    return Text('שגיאה: $err');
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _topicController,
                  decoration: const InputDecoration(
                      labelText: 'נושא השיעור (אופציונלי)',
                      border: OutlineInputBorder()),
                  onChanged: (_) => setState(() {}),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.start,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                      side: BorderSide(color: theme.disabledColor),
                      borderRadius: BorderRadius.circular(8)),
                  title: Text(
                      'תאריך השיעור: ${(HebrewDateFormatter()..hebrewFormat = true).format(_selectedDate)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickHebrewDate,
                ),
                const SizedBox(height: 24),
                _buildHebrewKeyboard(buttonColor, buttonTextColor),
                const SizedBox(height: 24),
                Text('שם קובץ היעד:', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                SelectableText(
                  _getNewFileName(),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.secondary),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: _isCopying
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.copy_all_outlined),
          label: const Text('העתק את השיעור'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            textStyle: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold),
          ),
          onPressed: _selectedPermission == null ? null : _copyFile,
        ),
      ],
    );
  }
}
