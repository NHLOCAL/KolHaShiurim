import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:torah_shiurim_transfer/core/database/database.dart';
import 'package:torah_shiurim_transfer/core/providers/providers.dart';
// Note: Hiding 'Column' from drift to resolve ambiguity with Flutter's Column widget.
import 'package:drift/drift.dart' hide Column;

final _sourceFilesProvider = FutureProvider.autoDispose<List<File>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final fileService = ref.watch(fileServiceProvider);


  // .map provides the full state object, so this usage is correct.
  return authState.map(
    loggedOut: (_) => [],
    admin: (_) => [],
    user: (userState) async {
      final device = userState.device;
      final sourcePath = p.join(device.mountPath, device.sourcePath);
      return fileService.getAudioFiles(sourcePath);
    },
  );
});

final _allowedRabbisProvider = StreamProvider.autoDispose<List<Rabbi>>((ref) {
  final authState = ref.watch(authStateProvider);
  final db = ref.watch(databaseProvider);


  return authState.map(
    loggedOut: (_) => Stream.value([]),
    admin: (_) => Stream.value([]),
    user: (userState) => db.watchPermissionsForUser(userState.user.id),
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

  String _getNewFileName() {
    if (_selectedRabbi == null || _selectedFile == null) return "שם קובץ...";
    final date = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final topic = _topicController.text.trim();
    final extension = p.extension(_selectedFile!.path);
    return "$date - ${_selectedRabbi!.name} - ${topic.isNotEmpty ? topic : 'ללא נושא'}$extension";
  }

  Future<void> _copyFile() async {
    if (_selectedFile == null || _selectedRabbi == null) return;
    setState(() => _isCopying = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authState = ref.read(authStateProvider);

    try {
      final newFileName = _getNewFileName();
      await ref.read(fileServiceProvider).copyFile(
            sourceFile: _selectedFile!,
            destinationDirectory: _selectedRabbi!.targetPath,
            newFileName: newFileName,
          );


      // FIXED: .whenOrNull deconstructs the state into its properties (user, device).
      // The callback signature and usage are now correct.
      await authState.whenOrNull(
        user: (user, device) async {
          // FIXED: Removed the `Value()` wrapper from the arguments.
          // `TransfersCompanion.insert` expects raw values.
          await ref.read(databaseProvider).logTransfer(
                TransfersCompanion.insert(
                  userId: user.id,
                  sourceFile: _selectedFile!.path,
                  destinationFile: p.join(_selectedRabbi!.targetPath, newFileName),
                  timestamp: DateTime.now(),
                ),
              );
        },
      );

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('הקובץ הועתק בהצלחה!'), backgroundColor: Colors.green),
      );
      setState(() {
        _selectedFile = null;
        _topicController.clear();
      });
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('שגיאה בהעתקת הקובץ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isCopying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sourceFilesAsync = ref.watch(_sourceFilesProvider);
    final allowedRabbisAsync = ref.watch(_allowedRabbisProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('העברת שיעורים'),
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
          Expanded(
            flex: 2,
            child: Card(
              margin: const EdgeInsets.all(8),
              child: sourceFilesAsync.when(
                data: (files) => files.isEmpty
                    ? const Center(child: Text('לא נמצאו קבצי שמע בתיקיית המקור.'))
                    : ListView.builder(
                        itemCount: files.length,
                        itemBuilder: (context, index) {
                          final file = files[index];
                          final isSelected = _selectedFile?.path == file.path;
                          return ListTile(
                            title: Text(p.basename(file.path)),
                            leading: const Icon(Icons.audio_file),
                            tileColor: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
                            onTap: () => setState(() => _selectedFile = file),
                          );
                        },
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('שגיאה בטעינת קבצים: $err')),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Card(
              margin: const EdgeInsets.fromLTRB(0, 8, 8, 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: AbsorbPointer(
                  absorbing: _selectedFile == null || _isCopying,
                  child: Opacity(
                    opacity: _selectedFile == null || _isCopying ? 0.5 : 1.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('פרטי העברה', style: Theme.of(context).textTheme.headlineSmall),
                        const Divider(),
                        if (_selectedFile != null) Text("קובץ מקור: ${p.basename(_selectedFile!.path)}"),
                        const SizedBox(height: 20),
                        allowedRabbisAsync.when(
                          data: (rabbis) => DropdownButtonFormField<Rabbi>(
                            value: _selectedRabbi,
                            items: rabbis.map((rabbi) => DropdownMenuItem(value: rabbi, child: Text(rabbi.name))).toList(),
                            onChanged: (val) => setState(() => _selectedRabbi = val),
                            decoration: const InputDecoration(labelText: 'בחר רב', border: OutlineInputBorder()),
                          ),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, stack) => Text('שגיאה: $err'),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _topicController,
                          decoration: const InputDecoration(labelText: 'נושא השיעור', border: OutlineInputBorder()),
                           onChanged: (_) => setState((){}),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: Text("תאריך השיעור: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}"),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => _selectedDate = picked);
                            }
                          },
                        ),
                        const Spacer(),
                        Text('שם קובץ היעד:', style: Theme.of(context).textTheme.titleSmall),
                        Text(_getNewFileName(), style: Theme.of(context).textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: _isCopying ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.copy),
                            label: const Text('העתק שיעור'),
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                            onPressed: _selectedFile == null || _selectedRabbi == null || _isCopying ? null : _copyFile,
                          ),
                        ),
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