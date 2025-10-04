import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kol_hashiurim/core/database/database.dart';
import 'package:kol_hashiurim/core/providers/providers.dart';
class RabbiManagementTab extends ConsumerWidget {
  const RabbiManagementTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rabbisAsync = ref.watch(allRabbisProvider);
    final logService = ref.read(logServiceProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('הוסף רב'),
        onPressed: () {
          logService.logUserActivity('Admin opened "Add Rabbi" dialog.');
          _showRabbiDialog(context, ref);
        },
      ),
      body: rabbisAsync.when(
        data: (rabbis) => ListView.builder(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
          itemCount: rabbis.length,
          itemBuilder: (context, index) {
            final rabbi = rabbis[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.folder_special_outlined),
                title: Text(
                  rabbi.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('נתיב: ${rabbi.targetPath}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Theme.of(context).colorScheme.error,
                  tooltip: 'מחק רב',
                  onPressed: () => _showDeleteConfirmation(
                    context,
                    'רב',
                    rabbi.name,
                    () async {
                      try {
                        await ref.read(databaseProvider).deleteRabbi(rabbi.id);
                        logService.logUserActivity(
                          'Admin deleted rabbi: ${rabbi.name} (ID: ${rabbi.id})',
                        );
                      } catch (e, st) {
                        logService.logError(
                          'Failed to delete rabbi: ${rabbi.name}',
                          e,
                          st,
                        );
                        if (context.mounted) {
                          String errorMessage = 'שגיאה במחיקת הרב.';
                          if (e.toString().contains(
                            'FOREIGN KEY constraint failed',
                          )) {
                            errorMessage =
                                'לא ניתן למחוק רב שיש לו הרשאות משוייכות למשתמשים. יש להסיר את ההרשאות תחילה.';
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errorMessage),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
                onTap: () {
                  logService.logUserActivity(
                    'Admin opened "Edit Rabbi" dialog for rabbi: ${rabbi.name}',
                  );
                  _showRabbiDialog(context, ref, rabbi: rabbi);
                },
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) {
          logService.logError('Error loading rabbis data', e, st);
          return Center(child: Text('Error: $e'));
        },
      ),
    );
  }
  void _showRabbiDialog(BuildContext context, WidgetRef ref, {Rabbi? rabbi}) {
    final nameController = TextEditingController(text: rabbi?.name);
    final pathController = TextEditingController(text: rabbi?.targetPath);
    final formKey = GlobalKey<FormState>();
    final logService = ref.read(logServiceProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(rabbi == null ? 'הוספת רב חדש' : 'עריכת פרטי רב'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'שם הרב',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'שדה חובה' : null,
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: pathController,
                decoration: InputDecoration(
                  labelText: 'נתיב יעד (במחשב)',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.folder_open),
                    tooltip: 'בחר תיקיה',
                    onPressed: () async {
                      logService.logUserActivity(
                        'Admin picking target path for rabbi.',
                      );
                      final selectedDirectory = await FilePicker.platform
                          .getDirectoryPath();
                      if (selectedDirectory != null) {
                        pathController.text = selectedDirectory;
                        logService.logInfo(
                          'Selected target path: $selectedDirectory',
                        );
                      }
                    },
                  ),
                ),
                validator: (v) => v!.isEmpty ? 'שדה חובה' : null,
                textAlign: TextAlign.start,
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              logService.logUserActivity('Admin cancelled rabbi dialog.');
              Navigator.of(context).pop();
            },
            child: const Text('ביטול'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final companion = RabbisCompanion(
                  name: drift.Value(nameController.text),
                  targetPath: drift.Value(pathController.text),
                );
                try {
                  if (rabbi == null) {
                    final newRabbiId = await ref
                        .read(databaseProvider)
                        .insertRabbi(companion);
                    logService.logUserActivity(
                      'Admin added new rabbi: ${nameController.text} (ID: $newRabbiId, Path: ${pathController.text})',
                    );
                  } else {
                    await ref
                        .read(databaseProvider)
                        .updateRabbi(
                          companion.copyWith(id: drift.Value(rabbi.id)),
                        );
                    logService.logUserActivity(
                      'Admin updated rabbi: ${rabbi.name} (ID: ${rabbi.id}) to ${nameController.text}, Path: ${pathController.text}',
                    );
                  }
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                } catch (e, st) {
                  logService.logError(
                    'Failed to save rabbi: ${nameController.text}',
                    e,
                    st,
                  );
                  if (context.mounted) {
                    String errorMessage =
                        'שגיאה בשמירת הרב. פרטים נוספים ביומן.';
                    if (e.toString().contains(
                      'UNIQUE constraint failed: rabbis.name',
                    )) {
                      errorMessage = 'שם הרב שהוזן כבר קיים במערכת.';
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('שמירה'),
          ),
        ],
      ),
    );
  }
  void _showDeleteConfirmation(
    BuildContext context,
    String itemType,
    String itemName,
    VoidCallback onDelete,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('אישור מחיקה'),
        content: Text(
          'האם למחוק את ה$itemType "$itemName"?\nפעולה זו אינה הפיכה.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            ),
            onPressed: () {
              onDelete();
              Navigator.of(context).pop();
            },
            child: const Text('מחק'),
          ),
        ],
      ),
    );
  }
}