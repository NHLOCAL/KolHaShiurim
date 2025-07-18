import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:torah_shiurim_transfer/core/database/database.dart';
import 'package:torah_shiurim_transfer/core/providers/providers.dart';

// This provider gets the source files from the user's device.
final _sourceFilesProvider =
    FutureProvider.autoDispose<List<File>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final fileService = ref.watch(fileServiceProvider);

  // CHANGED: Now correctly uses the runtime mountPath and the configured sourcePath.
  return authState.maybeMap(
    user: (userState) async {
      // The full path is the combination of the detected mount path (e.g., E:\)
      // and the relative source path from the DB (e.g., records\).
      final sourcePath =
          p.join(userState.mountPath, userState.device.sourcePath);
      return fileService.getAudioFiles(sourcePath);
    },
    orElse: () => [],
  );
});

// This provider gets the list of rabbis the user is allowed to copy to.
final _allowedRabbisProvider = StreamProvider.autoDispose<List<Rabbi>>((ref) {
  final authState = ref.watch(authStateProvider);
  final db = ref.watch(databaseProvider);

  return authState.maybeMap(
    user: (userState) => db.watchPermissionsForUser(userState.user.id),
    orElse: () => Stream.value([]),
  );
});

class UserTransferScreen extends ConsumerStatefulWidget {
  const UserTransferScreen({super.key});
  @override
  ConsumerState<UserTransferScreen> createState() => _UserTransferScreenState();
}

class _UserTransferScreenState extends ConsumerState<UserTransferScreen> {
  File? _selectedFile;
  Rabbi? _selectedRabbi;
  DateTime _selectedDate = DateTime.now();
  final _topicController = TextEditingController();
  bool _isCopying = false;
  String? _lastCopiedFileName;

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  String _getNewFileName() {
    if (_selectedRabbi == null || _selectedFile == null) return "שם קובץ...";
    final date = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final topic = _topicController.text.trim();
    // Sanitize topic to be a valid file name part
    final sanitizedTopic = topic.replaceAll(RegExp(r'[\\/*?:"<>|]'), '');
    final extension = p.extension(_selectedFile!.path);
    return "$date - ${_selectedRabbi!.name} - ${sanitizedTopic.isNotEmpty ? sanitizedTopic : 'ללא נושא'}$extension";
  }

  Future<void> _copyFile() async {
    if (_selectedFile == null || _selectedRabbi == null) return;

    setState(() {
      _isCopying = true;
      _lastCopiedFileName = null;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authState = ref.read(authStateProvider);

    try {
      final newFileName = _getNewFileName();
      final destinationDirectory = _selectedRabbi!.targetPath;
      final destinationPath = p.join(destinationDirectory, newFileName);

      await ref.read(fileServiceProvider).copyFile(
            sourceFile: _selectedFile!,
            destinationDirectory: destinationDirectory,
            newFileName: newFileName,
          );

      // Log the transfer to the database
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
        },
        orElse: () {},
      );

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('הקובץ "$newFileName" הועתק בהצלחה!'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset the form and show the last copied file name
      setState(() {
        _lastCopiedFileName = newFileName;
        _selectedFile = null;
        _topicController.clear();
        _selectedRabbi = null;
      });
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content: Text('שגיאה בהעתקת הקובץ: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isCopying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sourceFilesAsync = ref.watch(_sourceFilesProvider);
    final allowedRabbisAsync = ref.watch(_allowedRabbisProvider);
    final authState = ref.watch(authStateProvider);

    final userName =
        authState.maybeMap(user: (u) => u.user.name, orElse: () => '');
    final deviceSerial = authState.maybeMap(
        user: (u) => u.device.serialNumber, orElse: () => '');

    return Scaffold(
      appBar: AppBar(
        title: Text('העברת שיעורים - שלום, $userName'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20.0),
          child: Text('התקן מחובר: $deviceSerial',
              style: Theme.of(context).textTheme.bodySmall),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'התנתק וחזור למסך המתנה',
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: Row(
        children: [
          // Left side: Source files list
          Expanded(
            flex: 2,
            child: Card(
              margin: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("קבצים מההתקן",
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: sourceFilesAsync.when(
                      data: (files) => files.isEmpty
                          ? const Center(
                              child: Text('לא נמצאו קבצי שמע בתיקיית המקור.'))
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
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                      : null,
                                  onTap: () => setState(() {
                                    _selectedFile = file;
                                    _lastCopiedFileName =
                                        null; // Clear last copied when selecting new file
                                  }),
                                );
                              },
                            ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) =>
                          Center(child: Text('שגיאה בטעינת קבצים: $err')),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Right side: Transfer details form
          Expanded(
            flex: 3,
            child: Card(
              margin: const EdgeInsets.fromLTRB(0, 8, 8, 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: AbsorbPointer(
                  absorbing: _isCopying,
                  child: Opacity(
                    opacity: _isCopying ? 0.5 : 1.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('פרטי העברה',
                            style: Theme.of(context).textTheme.headlineSmall),
                        const Divider(),
                        if (_selectedFile == null &&
                            _lastCopiedFileName != null)
                          Card(
                            color: Colors.green.shade50,
                            child: ListTile(
                              leading: const Icon(Icons.check_circle,
                                  color: Colors.green),
                              title: const Text("העתקה הושלמה"),
                              subtitle: Text(_lastCopiedFileName!),
                            ),
                          ),
                        if (_selectedFile == null &&
                            _lastCopiedFileName == null)
                          const Expanded(
                              child: Center(
                                  child: Text("בחר קובץ מהרשימה כדי להתחיל."))),
                        if (_selectedFile != null)
                          Expanded(
                            child: ListView(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.file_present),
                                  title: const Text("קובץ מקור:"),
                                  subtitle:
                                      Text(p.basename(_selectedFile!.path)),
                                ),
                                const SizedBox(height: 20),
                                allowedRabbisAsync.when(
                                  data: (rabbis) =>
                                      DropdownButtonFormField<Rabbi>(
                                    value: _selectedRabbi,
                                    items: rabbis
                                        .map((rabbi) => DropdownMenuItem(
                                            value: rabbi,
                                            child: Text(rabbi.name)))
                                        .toList(),
                                    onChanged: (val) =>
                                        setState(() => _selectedRabbi = val),
                                    decoration: const InputDecoration(
                                        labelText: 'בחר רב',
                                        border: OutlineInputBorder()),
                                  ),
                                  loading: () => const Center(
                                      child: CircularProgressIndicator()),
                                  error: (err, stack) => Text('שגיאה: $err'),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _topicController,
                                  decoration: const InputDecoration(
                                      labelText: 'נושא השיעור (אופציונלי)',
                                      border: OutlineInputBorder()),
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 16),
                                ListTile(
                                  title: Text(
                                      "תאריך השיעור: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}"),
                                  trailing: const Icon(Icons.calendar_today),
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _selectedDate,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime.now()
                                          .add(const Duration(days: 365)),
                                    );
                                    if (picked != null) {
                                      setState(() => _selectedDate = picked);
                                    }
                                  },
                                ),
                                const SizedBox(height: 24),
                                Text('שם קובץ היעד:',
                                    style:
                                        Theme.of(context).textTheme.titleSmall),
                                const SizedBox(height: 4),
                                Text(
                                  _getNewFileName(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.grey.shade700),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        if (_selectedFile != null) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: _isCopying
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Icon(Icons.copy_all_outlined),
                            label: const Text('העתק את השיעור'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                            ),
                            onPressed:
                                _selectedRabbi == null ? null : _copyFile,
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
