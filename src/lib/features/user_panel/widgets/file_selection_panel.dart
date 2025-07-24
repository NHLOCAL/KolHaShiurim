import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:kol_hashiurim/core/providers/providers.dart';
import 'package:kol_hashiurim/features/user_panel/providers/user_panel_providers.dart';

class FileSelectionPanel extends ConsumerWidget {
  final File? selectedFile;
  final ValueChanged<File> onFileSelected;

  const FileSelectionPanel({
    super.key,
    required this.selectedFile,
    required this.onFileSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sourceFilesAsync = ref.watch(sourceFilesProvider);
    final logService = ref.read(logServiceProvider);

    return Card(
      margin: const EdgeInsets.fromLTRB(8, 8, 4, 8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text('קבצים מההתקן', style: theme.textTheme.titleLarge),
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
                      ),
                    )
                  : ListView.builder(
                      itemCount: files.length,
                      itemBuilder: (context, index) {
                        final file = files[index];
                        final isSelected = selectedFile?.path == file.path;
                        return ListTile(
                          title: Text(p.basename(file.path)),
                          leading: const Icon(Icons.audio_file_outlined),
                          tileColor: isSelected
                              ? theme.colorScheme.primaryContainer
                              : null,
                          onTap: () {
                            onFileSelected(file);
                            ref
                                    .read(lastCopiedFileNameProvider.notifier)
                                    .state =
                                null;
                            logService.logUserActivity(
                              'User selected file: ${file.path}',
                            );
                          },
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) {
                logService.logError('Error loading source files', err, stack);
                return Center(child: Text('שגיאה בטעינת קבצים: $err'));
              },
            ),
          ),
        ],
      ),
    );
  }
}
