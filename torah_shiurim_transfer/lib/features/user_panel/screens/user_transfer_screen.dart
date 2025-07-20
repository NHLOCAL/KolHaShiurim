import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:material_hebrew_date_picker/material_hebrew_date_picker.dart';
import 'package:path/path.dart' as p;
import 'package:torah_shiurim_transfer/core/database/database.dart';
import 'package:torah_shiurim_transfer/core/providers/providers.dart';
import 'package:torah_shiurim_transfer/services/log_service.dart';

final _sourceFilesProvider =
    FutureProvider.autoDispose<List<File>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final fileService = ref.watch(fileServiceProvider);
  final logService = ref.read(logServiceProvider);

  ref.watch(_lastCopiedFileNameProvider);

  return authState.maybeMap(
    user: (userState) async {
      final sourcePath =
          p.join(userState.mountPath, userState.device.sourcePath);
      logService.logInfo(
          'Fetching audio files from device source path: $sourcePath for user: ${userState.user.name}');
      try {
        return await fileService.getAudioFiles(sourcePath);
      } catch (e, st) {
        logService.logError(
            'Failed to get audio files from $sourcePath', e, st);
        return [];
      }
    },
    orElse: () {
      logService
          .logInfo('No user logged in, returning empty list for source files.');
      return [];
    },
  );
});

final _allowedRabbisProvider =
    StreamProvider.autoDispose<List<UserPermissionInfo>>((ref) {
  final authState = ref.watch(authStateProvider);
  final db = ref.watch(databaseProvider);
  final logService = ref.read(logServiceProvider);

  return authState.maybeMap(
    user: (userState) {
      logService
          .logInfo('Watching permissions for user: ${userState.user.name}');
      return db.watchPermissionsForUser(userState.user.id);
    },
    orElse: () {
      logService.logInfo(
          'No user logged in, returning empty stream for allowed rabbis.');
      return Stream.value([]);
    },
  );
});

final _lastCopiedFileNameProvider = StateProvider<String?>((ref) => null);

class UserTransferScreen extends ConsumerStatefulWidget {
  const UserTransferScreen({super.key});

  @override
  ConsumerState<UserTransferScreen> createState() => _UserTransferScreenState();
}

class _UserTransferScreenState extends ConsumerState<UserTransferScreen> {
  File? _selectedFile;
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
    _logService.logInfo('User Transfer screen initialized.');
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
      _selectedFile = null;
      _selectedPermission = null;
      _topicController.clear();
      _selectedDate = JewishDate();
    });
  }

  String _getNewFileName() {
    if (_selectedPermission == null || _selectedFile == null) {
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
        : p.extension(_selectedFile!.path);
    final fileName =
        '$dateStr - ${_selectedPermission!.rabbi.name}${sanitizedTopic.isNotEmpty ? ' - $sanitizedTopic' : ''}$extension'; // NEW
    _logService.logInfo('Generated new file name: $fileName'); // NEW
    return fileName; // NEW
  }

  Future<void> _copyFile() async {
    if (_selectedFile == null ||
        _selectedPermission == null ||
        _appSettings == null) {
      _logService.logWarning(
          'Attempted to copy file with missing selections (file, permission, or settings).'); // NEW
      return;
    }

    setState(() => _isCopying = true);
    ref.read(_lastCopiedFileNameProvider.notifier).state = null;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authState = ref.read(authStateProvider);

    _logService.logUserActivity(
        'User initiating file transfer for: ${_selectedFile!.path}'); // NEW

    try {
      final newFileName = _getNewFileName();
      final baseDirectory = _selectedPermission!.rabbi.targetPath;
      final subDirectory = _selectedPermission!.specificPath;

      final destinationDirectory =
          (subDirectory != null && subDirectory.isNotEmpty)
              ? p.join(baseDirectory, subDirectory)
              : baseDirectory;

      final destinationPath = p.join(destinationDirectory, newFileName);
      final fileService = ref.read(fileServiceProvider);

      _logService.logInfo(
          'Copying/converting file from ${_selectedFile!.path} to $destinationPath (Convert to MP3: ${_appSettings!.convertToMp3})'); // NEW
      if (_appSettings!.convertToMp3) {
        await fileService.convertAndCopyFile(
          sourceFile: _selectedFile!,
          destinationDirectory: destinationDirectory,
          newFileName: newFileName,
          bitrate: _appSettings!.mp3Bitrate,
        );
      } else {
        await fileService.copyFile(
          sourceFile: _selectedFile!,
          destinationDirectory: destinationDirectory,
          newFileName: newFileName,
        );
      }

      // Log transfer to database
      await authState.maybeWhen(
        user: (user, device, mountPath) async {
          await ref.read(databaseProvider).logTransfer(
                TransfersCompanion.insert(
                  userId: user.id,
                  sourceFile: _selectedFile!.path,
                  destinationFile: destinationPath,
                  timestamp: DateTime.now(),
                ),
              );
          _logService.logUserActivity(
              'Transfer logged for user ${user.name}: Source ${_selectedFile!.path}, Destination: $destinationPath'); // NEW
        },
        orElse: () {
          _logService.logInfo(
              'Transfer completed but no user active to log to DB. Source: ${_selectedFile!.path}, Destination: $destinationPath'); // NEW
        },
      );

      ref.read(_lastCopiedFileNameProvider.notifier).state = newFileName;
      _logService.logInfo('File transfer successful: $newFileName'); // NEW
      _resetForm();
    } catch (e, st) {
      // NEW: Catch and log errors
      _logService.logError(
          'Error during file transfer from ${_selectedFile!.path}',
          e,
          st); // NEW
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
        'User opened Hebrew date picker. Current date: ${_selectedDate.toString()}'); // NEW
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
      _logService
          .logInfo('User selected Hebrew date: ${newJd.toString()}'); // NEW
    } else {
      // NEW: Log cancellation
      _logService.logInfo('Hebrew date picker cancelled.'); // NEW
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
                            'Hebrew keyboard input: "$key", current topic: "${_topicController.text}"'); // NEW
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
                            'Hebrew keyboard backspace, current topic: "${_topicController.text}"'); // NEW
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
                          'Hebrew keyboard space, current topic: "${_topicController.text}"'); // NEW
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
    final sourceFilesAsync = ref.watch(_sourceFilesProvider);
    final allowedRabbisAsync = ref.watch(_allowedRabbisProvider);
    final authState = ref.watch(authStateProvider);
    final lastCopiedFileName = ref.watch(_lastCopiedFileNameProvider);

    final userName =
        authState.maybeMap(user: (u) => u.user.name, orElse: () => '');
    final deviceSerial = authState.maybeMap(
        user: (u) => u.device.serialNumber, orElse: () => '');

    final theme = Theme.of(context);
    final buttonColor = theme.colorScheme.secondaryContainer;
    final buttonTextColor = theme.colorScheme.onSecondaryContainer;

    if (_appSettings == null) {
      _logService.logInfo(
          'User Transfer screen waiting for app settings to load.'); // NEW
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    _logService.logInfo(
        'User Transfer screen built for user: $userName, device: $deviceSerial');

    return Scaffold(
      appBar: AppBar(
        title: Text('העברת שיעורים - שלום, $userName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'התנתקות וסגירת הממשק',
            onPressed: () {
              _logService
                  .logUserActivity('User $userName clicked logout button.');
              ref.read(authStateProvider.notifier).logout();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20.0),
          child: Text(
            'התקן מחובר: $deviceSerial',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Card(
              margin: const EdgeInsets.fromLTRB(8, 8, 4, 8),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'קבצים מההתקן',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: sourceFilesAsync.when(
                      data: (files) => files.isEmpty
                          ? const Center(
                              child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'לא נמצאו קבצי שמע בתיקיית המקור.',
                                textAlign: TextAlign.center,
                              ),
                            ))
                          : ListView.builder(
                              itemCount: files.length,
                              itemBuilder: (context, index) {
                                final file = files[index];
                                final isSelected =
                                    _selectedFile?.path == file.path;
                                return ListTile(
                                  title: Text(p.basename(file.path)),
                                  leading:
                                      const Icon(Icons.audio_file_outlined),
                                  tileColor: isSelected
                                      ? theme.colorScheme.primaryContainer
                                      : null,
                                  onTap: () {
                                    setState(() {
                                      _selectedFile = file;
                                      ref
                                          .read(_lastCopiedFileNameProvider
                                              .notifier)
                                          .state = null;
                                    });
                                    _logService.logUserActivity(
                                        'User selected file: ${file.path}');
                                  },
                                );
                              },
                            ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) {
                        _logService.logError(
                            'Error loading source files', err, stack);
                        return Center(child: Text('שגיאה בטעינת קבצים: $err'));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Card(
              margin: const EdgeInsets.fromLTRB(4, 8, 8, 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: AbsorbPointer(
                  absorbing: _isCopying,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _isCopying ? 0.5 : 1.0,
                    child: _buildFormContent(theme, allowedRabbisAsync,
                        buttonColor, buttonTextColor, lastCopiedFileName),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent(
      ThemeData theme,
      AsyncValue<List<UserPermissionInfo>> allowedRabbisAsync,
      Color buttonColor,
      Color buttonTextColor,
      String? lastCopiedFileName) {
    if (_selectedFile == null) {
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
                  subtitle: Text(p.basename(_selectedFile!.path)),
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
