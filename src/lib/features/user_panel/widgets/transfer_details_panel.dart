import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:material_hebrew_date_picker/material_hebrew_date_picker.dart';
import 'package:path/path.dart' as p;
import 'package:kol_hashiurim/core/database/database.dart';
import 'package:kol_hashiurim/core/providers/providers.dart';
import 'package:kol_hashiurim/features/user_panel/providers/user_panel_providers.dart';
import 'package:kol_hashiurim/features/user_panel/utils/permission_selection.dart';
import 'package:kol_hashiurim/services/log_service.dart';
import 'package:kol_hashiurim/utils/file_name_sanitizer.dart';

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
  String? _selectedSpecificPath;
  JewishDate _selectedDate = JewishDate();
  final _topicController = TextEditingController();
  bool _isCopying = false;
  AppSetting? _appSettings;
  late final LogService _logService;
  AudioPlayer? _audioPlayer;
  double? _pendingSeekMillis;
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
    _audioPlayer = AudioPlayer();
    _loadSettings();
    _logService.logInfo('Transfer Details Panel initialized.');
  }
  @override
  void didUpdateWidget(covariant TransferDetailsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedFile != oldWidget.selectedFile) {
      _handleFileChange();
    }
  }
  /// Handles the safe transition between audio files to prevent threading errors
  /// on Windows (avoiding race conditions between stop and setFilePath).
  Future<void> _handleFileChange() async {
    // Always reset UI form when selection changes.
    _resetForm();
    final audioPlayer = _audioPlayer;
    if (audioPlayer == null || widget.selectedFile == null) {
      return;
    }
    try {
      // Stop playback properly and wait for it to finish.
      if (audioPlayer.playing ||
          audioPlayer.processingState != ProcessingState.idle) {
        await audioPlayer.stop();
      }
      // Load new file only if widget is still mounted.
      if (mounted && widget.selectedFile != null) {
        await audioPlayer.setFilePath(widget.selectedFile!.path);
      }
    } catch (e) {
      _logService.logError(
        "Error switching audio source",
        e,
        StackTrace.current,
      );
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
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _suspendAudioPlayer() async {
    final audioPlayer = _audioPlayer;
    if (audioPlayer == null) {
      return;
    }
    if (mounted) {
      setState(() {
        _audioPlayer = null;
      });
    } else {
      _audioPlayer = null;
    }
    try {
      await audioPlayer.stop();
    } catch (e, st) {
      _logService.logError('Failed to stop audio player before transfer', e, st);
    }
    try {
      await audioPlayer.dispose();
      _logService.logInfo('Audio player disposed before transfer.');
    } catch (e, st) {
      _logService.logError('Failed to dispose audio player before transfer', e, st);
    }
  }

  Future<void> _restoreAudioPlayer() async {
    if (!mounted || _audioPlayer != null) {
      return;
    }
    setState(() {
      _audioPlayer = AudioPlayer();
    });
    final audioPlayer = _audioPlayer;
    if (audioPlayer == null || widget.selectedFile == null) {
      return;
    }
    try {
      await audioPlayer.setFilePath(widget.selectedFile!.path);
      _logService.logInfo('Audio player restored after transfer.');
    } catch (e, st) {
      _logService.logError('Failed to restore audio player after transfer', e, st);
    }
  }
  void _resetForm() {
    _logService.logInfo('Resetting transfer form.');
    setState(() {
      _selectedPermission = null;
      _selectedSpecificPath = null;
      _topicController.clear();
      _selectedDate = JewishDate();
      _pendingSeekMillis = null;
    });
  }
  String _getNewFileName(UserPermissionInfo? permission) {
    if (permission == null || widget.selectedFile == null) {
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
        'XX - $dateStr - ${permission.rabbi.name}${sanitizedTopic.isNotEmpty ? ' - $sanitizedTopic' : ''}$extension';
    final safeFileName = sanitizeFileName(
      fileName,
      fallback: 'שיעור$extension',
    );
    _logService.logInfo('Generated new file name preview: $safeFileName');
    return safeFileName;
  }
  Future<String> _determineFinalFileName({
    required UserPermissionInfo permission,
    required String? specificPath,
  }) async {
    if (widget.selectedFile == null) {
      _logService.logError(
        "Cannot determine final filename, selection is incomplete.",
        null,
        StackTrace.current,
      );
      throw Exception("Cannot determine filename, selection is incomplete.");
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
    final rabbiName = permission.rabbi.name;
    final baseDirectory = permission.rabbi.targetPath;
    final destinationDirectory =
        (specificPath != null && specificPath.isNotEmpty)
        ? p.join(baseDirectory, specificPath)
        : baseDirectory;
    int nextNumber = 1;
    try {
      final dir = Directory(destinationDirectory);
      if (await dir.exists()) {
        int maxNumber = 0;
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
        st,
      );
      nextNumber = 1;
    }
    _logService.logInfo(
      "Determined next file number in folder is $nextNumber.",
    );
    final formattedNumber = nextNumber.toString().padLeft(2, '0');
    final finalFileName =
        '$formattedNumber - $dateStr - $rabbiName${sanitizedTopic.isNotEmpty ? ' - $sanitizedTopic' : ''}$extension';
    final safeFileName = sanitizeFileName(
      finalFileName,
      fallback: 'שיעור$extension',
    );
    _logService.logInfo('Determined final file name: $safeFileName');
    return safeFileName;
  }
  Future<void> _showPostCopyOptionsDialog(
    File sourceFile,
    String newFileName,
  ) async {
    if (!mounted) {
      _logService.logWarning(
        'Skipping post-copy dialog because widget is unmounted.',
      );
      return;
    }
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
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
                    "Source file ${sourceFile.path} deleted successfully by user request.",
                  );
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text("קובץ המקור נמחק בהצלחה."),
                      backgroundColor: Colors.orange,
                    ),
                  );
                } catch (e, st) {
                  _logService.logError(
                    "Failed to delete source file ${sourceFile.path}",
                    e,
                    st,
                  );
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
        _appSettings == null) {
      _logService.logWarning(
        'Attempted to copy file with missing selections (file, permission, or settings).',
      );
      return;
    }
    final permissions = ref.read(allowedRabbisProvider).maybeWhen(
          data: (data) => data,
          orElse: () => <UserPermissionInfo>[],
        );
    final resolvedSelection = resolvePermissionSelection(
      selectedPermission: _selectedPermission,
      selectedSpecificPath: _selectedSpecificPath,
      availablePermissions: permissions,
    );
    if (resolvedSelection.permission == null) {
      _logService.logWarning(
        'Attempted to copy file without a valid permission selection.',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('יש לבחור רב יעד להעברה'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (mounted &&
        (resolvedSelection.permission != _selectedPermission ||
            resolvedSelection.specificPath != _selectedSpecificPath)) {
      setState(() {
        _selectedPermission = resolvedSelection.permission;
        _selectedSpecificPath = resolvedSelection.specificPath;
      });
    }
    if (resolvedSelection.isPathSelectionRequired &&
        resolvedSelection.specificPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('יש לבחור תיקיית משנה ליעד'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    await _suspendAudioPlayer();
    setState(() => _isCopying = true);
    ref.read(lastCopiedFileNameProvider.notifier).state = null;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authState = ref.read(authStateProvider);
    final sourceFile = widget.selectedFile!;
    final selectedPermission = resolvedSelection.permission;
    final selectedSpecificPath = resolvedSelection.specificPath;
    _logService.logUserActivity(
      'User initiating file transfer for: ${sourceFile.path}',
    );
    try {
      final fileSize = await sourceFile.length();
      _logService.logInfo(
        'Source file size: $fileSize bytes.',
      );
    } catch (e, st) {
      _logService.logWarning(
        'Failed to read source file size: $e',
      );
      _logService.logError(
        'Error reading source file size.',
        e,
        st,
      );
    }
    try {
      final newFileName = await _determineFinalFileName(
        permission: selectedPermission!,
        specificPath: selectedSpecificPath,
      );
      final baseDirectory = selectedPermission!.rabbi.targetPath;
      final destinationDirectory =
          (selectedSpecificPath != null && selectedSpecificPath.isNotEmpty)
          ? p.join(baseDirectory, selectedSpecificPath)
          : baseDirectory;
      final destinationPath = p.join(destinationDirectory, newFileName);
      final fileService = ref.read(fileServiceProvider);
      _logService.logInfo(
        'Copying/converting file from ${sourceFile.path} to $destinationPath (Convert to MP3: ${_appSettings!.convertToMp3})',
      );
      _logService.logInfo(
        'User target details: rabbi="${selectedPermission.rabbi.name}", base="$baseDirectory", specific="${selectedSpecificPath ?? ''}".',
      );
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
          await ref
              .read(databaseProvider)
              .logTransfer(
                TransfersCompanion.insert(
                  userId: user.id,
                  sourceFile: sourceFile.path,
                  destinationFile: destinationPath,
                  timestamp: DateTime.now(),
                ),
              );
          _logService.logUserActivity(
            'Transfer logged for user ${user.name}: Source ${sourceFile.path}, Destination: $destinationPath',
          );
        },
        orElse: () {
          _logService.logInfo(
            'Transfer completed but no user active to log to DB. Source: ${sourceFile.path}, Destination: $destinationPath',
          );
        },
      );
      _logService.logInfo('File transfer successful: $newFileName');
      try {
        await _showPostCopyOptionsDialog(sourceFile, newFileName);
      } catch (e, st) {
        _logService.logError(
          'Failed to show post-copy dialog.',
          e,
          st,
        );
      }
    } catch (e, st) {
      _logService.logError(
        'Error during file transfer from ${sourceFile.path}',
        e,
        st,
      );
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
      await _restoreAudioPlayer();
    }
  }
  Future<void> _pickHebrewDate() async {
    _logService.logUserActivity(
      'User opened Hebrew date picker. Current date: ${_selectedDate.toString()}',
    );
    final initial = _selectedDate.getGregorianCalendar();
    final currentJewishYear = JewishDate().getJewishYear();
    final firstHebrew =
        (JewishDate()
              ..setJewishDate(currentJewishYear - 30, JewishDate.TISHREI, 1))
            .getGregorianCalendar();
    final lastHebrew =
        (JewishDate()
              ..setJewishDate(currentJewishYear + 50, JewishDate.ELUL, 29))
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
                          TextPosition(offset: _topicController.text.length),
                        );
                        _logService.logInfo(
                          'Hebrew keyboard input: "$key", current topic: "${_topicController.text}"',
                        );
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
                        const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    onPressed: () {
                      final text = _topicController.text;
                      if (text.isNotEmpty) {
                        _topicController.text = text.substring(
                          0,
                          text.length - 1,
                        );
                        _topicController.selection = TextSelection.fromPosition(
                          TextPosition(offset: _topicController.text.length),
                        );
                        _logService.logInfo(
                          'Hebrew keyboard backspace, current topic: "${_topicController.text}"',
                        );
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
                        'Hebrew keyboard space, current topic: "${_topicController.text}"',
                      );
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
  Widget _buildAudioPlayer() {
    final audioPlayer = _audioPlayer;
    if (audioPlayer == null) {
      return const SizedBox.shrink();
    }
    String formatDuration(Duration? d) {
      if (d == null) return "--:--";
      final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return "$minutes:$seconds";
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: StreamBuilder<PlayerState>(
          stream: audioPlayer.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing;
            Widget playPauseButton;
            if (processingState == ProcessingState.loading ||
                processingState == ProcessingState.buffering) {
              playPauseButton = const SizedBox(
                width: 48.0,
                height: 48.0,
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              );
            } else if (playing != true) {
              playPauseButton = IconButton(
                icon: const Icon(Icons.play_arrow),
                iconSize: 32,
                onPressed: audioPlayer.play,
              );
            } else if (processingState != ProcessingState.completed) {
              playPauseButton = IconButton(
                icon: const Icon(Icons.pause),
                iconSize: 32,
                onPressed: audioPlayer.pause,
              );
            } else {
              playPauseButton = IconButton(
                icon: const Icon(Icons.replay),
                iconSize: 32,
                onPressed: () => audioPlayer.seek(Duration.zero),
              );
            }
            return StreamBuilder<Duration?>(
              stream: audioPlayer.durationStream,
              builder: (context, snapshot) {
                final duration = snapshot.data ?? Duration.zero;
                return StreamBuilder<Duration>(
                  stream: audioPlayer.positionStream,
                  builder: (context, snapshot) {
                    var position = snapshot.data ?? Duration.zero;
                    if (position > duration) position = duration;
                    return Row(
                      children: [
                        playPauseButton,
                        Text(
                          formatDuration(position),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Expanded(
                          child: Slider(
                            activeColor: Theme.of(context).colorScheme.primary,
                            inactiveColor: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.3),
                            value: (_pendingSeekMillis ??
                                    position.inMilliseconds.toDouble())
                                .clamp(
                                  0,
                                  duration.inMilliseconds.toDouble(),
                                ),
                            max: duration.inMilliseconds.toDouble(),
                            onChanged: (value) => setState(
                              () => _pendingSeekMillis = value,
                            ),
                            onChangeEnd: (value) {
                              audioPlayer.seek(
                                Duration(milliseconds: value.round()),
                              );
                              setState(() => _pendingSeekMillis = null);
                            },
                          ),
                        ),
                        Text(
                          formatDuration(duration),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        StreamBuilder<double>(
                          stream: audioPlayer.volumeStream,
                          builder: (context, snapshot) {
                            return Row(
                              children: [
                                Icon(
                                  (snapshot.data ?? 1.0) > 0
                                      ? Icons.volume_up
                                      : Icons.volume_off,
                                  size: 20,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                ),
                                SizedBox(
                                  width: 100,
                                  child: Slider(
                                    activeColor:
                                        Theme.of(context).colorScheme.secondary,
                                    inactiveColor: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.3),
                                    value: snapshot.data ?? 1.0,
                                    onChanged: audioPlayer.setVolume,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
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
            child: _buildFormContent(
              theme,
              allowedRabbisAsync,
              buttonColor,
              buttonTextColor,
              lastCopiedFileName,
            ),
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
    String? lastCopiedFileName,
  ) {
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
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'העתקה הושלמה!',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.green.shade800,
                        ),
                      ),
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
                  Icon(
                    Icons.arrow_forward,
                    size: 48,
                    color: theme.disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'בחר קובץ מהרשימה כדי להתחיל',
                    style: theme.textTheme.headlineSmall,
                  ),
                ],
              ),
      );
    }
    final permissions = allowedRabbisAsync.value ?? const <UserPermissionInfo>[];
    final resolvedSelection = resolvePermissionSelection(
      selectedPermission: _selectedPermission,
      selectedSpecificPath: _selectedSpecificPath,
      availablePermissions: permissions,
    );
    if (mounted &&
        (resolvedSelection.permission != _selectedPermission ||
            resolvedSelection.specificPath != _selectedSpecificPath)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _selectedPermission = resolvedSelection.permission;
          _selectedSpecificPath = resolvedSelection.specificPath;
        });
      });
    }
    final showPathSelector = resolvedSelection.isPathSelectionRequired;
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
                const SizedBox(height: 12),
                _buildAudioPlayer(),
                const SizedBox(height: 20),
                allowedRabbisAsync.when(
                  data: (permissions) =>
                      DropdownButtonFormField<UserPermissionInfo>(
                        value: resolvedSelection.permission,
                        items: permissions
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.rabbi.name),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedPermission = val;
                            if (val != null) {
                              if (val.specificPaths.length == 1) {
                                _selectedSpecificPath = val.specificPaths.first;
                              } else {
                                _selectedSpecificPath = null;
                              }
                            } else {
                              _selectedSpecificPath = null;
                            }
                          });
                          _logService.logUserActivity(
                            'User selected rabbi: ${val?.rabbi.name}',
                          );
                        },
                        decoration: const InputDecoration(
                          labelText: 'בחר רב',
                          border: OutlineInputBorder(),
                        ),
                      ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) {
                    _logService.logError(
                      'Error loading allowed rabbis',
                      err,
                      stack,
                    );
                    return Text('שגיאה: $err');
                  },
                ),
                if (showPathSelector) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    value: resolvedSelection.specificPath,
                    items: resolvedSelection.permission!.specificPaths
                        .map(
                          (path) => DropdownMenuItem(
                            value: path,
                            child: Text(path ?? 'תיקיית הבסיס'),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() => _selectedSpecificPath = val);
                      _logService.logUserActivity(
                        'User selected specific path: $val',
                      );
                    },
                    decoration: const InputDecoration(
                      labelText: 'בחר תיקיית משנה ליעד',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: _topicController,
                  decoration: const InputDecoration(
                    labelText: 'נושא השיעור (אופציונלי)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.start,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: theme.disabledColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  title: Text(
                    'תאריך השיעור: ${(HebrewDateFormatter()..hebrewFormat = true).format(_selectedDate)}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickHebrewDate,
                ),
                const SizedBox(height: 24),
                _buildHebrewKeyboard(buttonColor, buttonTextColor),
                const SizedBox(height: 24),
                Text('שם קובץ היעד:', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                SelectableText(
                  _getNewFileName(resolvedSelection.permission),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
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
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.copy_all_outlined),
          label: const Text('העתק את השיעור'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            textStyle: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: resolvedSelection.permission == null ? null : _copyFile,
        ),
      ],
    );
  }
}
