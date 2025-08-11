import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kol_hashiurim/core/database/database.dart';
import 'package:kol_hashiurim/core/providers/providers.dart';
import 'package:kol_hashiurim/services/log_service.dart';

class UserManagementTab extends ConsumerWidget {
  const UserManagementTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);
    final logService = ref.read(logServiceProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('הוסף משתמש'),
        onPressed: () {
          logService.logUserActivity('Admin opened "Add User" dialog.');
          _showUserDialog(context, ref);
        },
      ),
      body: usersAsync.when(
        data: (users) => ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            String subtitleText = 'משתמש רגיל';
            if (user.additionalInfo != null &&
                user.additionalInfo!.isNotEmpty) {
              subtitleText += '\nפרטים נוספים: ${user.additionalInfo}';
            }
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(
                  user.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(subtitleText),
                isThreeLine:
                    user.additionalInfo != null &&
                    user.additionalInfo!.isNotEmpty,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      child: const Text('הרשאות'),
                      onPressed: () {
                        logService.logUserActivity(
                          'Admin opened permissions dialog for user: ${user.name}',
                        );
                        _showPermissionsDialog(context, ref, user);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Theme.of(context).colorScheme.error,
                      tooltip: 'מחק משתמש',
                      onPressed: () => _showDeleteConfirmation(
                        context,
                        'משתמש',
                        user.name,
                        () async {
                          try {
                            await ref
                                .read(databaseProvider)
                                .deleteUser(user.id);
                            logService.logUserActivity(
                              'Admin deleted user: ${user.name} (ID: ${user.id})',
                            );
                          } catch (e, st) {
                            logService.logError(
                              'Failed to delete user: ${user.name}',
                              e,
                              st,
                            );
                            if (context.mounted) {
                              String errorMessage = 'שגיאה במחיקת משתמש.';
                              if (e.toString().contains(
                                'FOREIGN KEY constraint failed',
                              )) {
                                errorMessage =
                                    'לא ניתן למחוק משתמש המשוייך להתקן. יש למחוק את ההתקן תחילה.';
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
                  ],
                ),
                onTap: () {
                  logService.logUserActivity(
                    'Admin opened "Edit User" dialog for user: ${user.name}',
                  );
                  _showUserDialog(context, ref, user: user);
                },
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) {
          logService.logError('Error loading users data', e, st);
          return Center(child: Text('Error: $e'));
        },
      ),
    );
  }

  void _showUserDialog(BuildContext context, WidgetRef ref, {User? user}) {
    final nameController = TextEditingController(text: user?.name);
    final additionalInfoController = TextEditingController(
      text: user?.additionalInfo,
    );
    final formKey = GlobalKey<FormState>();
    final logService = ref.read(logServiceProvider);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(user == null ? 'הוספת משתמש חדש' : 'עריכת משתמש'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'שם משתמש',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'שדה חובה' : null,
                  textAlign: TextAlign.start,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: additionalInfoController,
                  decoration: const InputDecoration(
                    labelText: 'פרטים נוספים (טלפון, שיעור, ועד וכו\')',
                    border: OutlineInputBorder(),
                  ),
                  textAlign: TextAlign.start,
                  minLines: 3,
                  maxLines: 5,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ביטול'),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final companion = UsersCompanion(
                    name: drift.Value(nameController.text),
                    additionalInfo: drift.Value(
                      additionalInfoController.text.trim().isEmpty
                          ? null
                          : additionalInfoController.text.trim(),
                    ),
                  );
                  try {
                    if (user == null) {
                      final newUserId = await ref
                          .read(databaseProvider)
                          .insertUser(companion);
                      logService.logUserActivity(
                        'Admin added new user: ${nameController.text} (ID: $newUserId)',
                      );
                    } else {
                      await ref
                          .read(databaseProvider)
                          .updateUser(
                            companion.copyWith(id: drift.Value(user.id)),
                          );
                      logService.logUserActivity(
                        'Admin updated user: ${user.name} (ID: ${user.id}) to ${nameController.text}',
                      );
                    }
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  } catch (e, st) {
                    logService.logError(
                      'Failed to save user: ${nameController.text}',
                      e,
                      st,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'שגיאה בשמירת המשתמש. פרטים נוספים ביומן.',
                          ),
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
        );
      },
    );
  }

  void _showPermissionsDialog(BuildContext context, WidgetRef ref, User user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PermissionsDialog(user: user),
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

class _PermissionsDialog extends ConsumerStatefulWidget {
  final User user;
  const _PermissionsDialog({required this.user});
  @override
  ConsumerState<_PermissionsDialog> createState() => _PermissionsDialogState();
}

class _PermissionsDialogState extends ConsumerState<_PermissionsDialog> {
  Set<int> _selectedRabbiIds = {};
  Map<int, List<TextEditingController>> _pathControllers = {};
  bool _isLoading = true;
  late final LogService _logService;
  @override
  void initState() {
    super.initState();
    _logService = ref.read(logServiceProvider);
    _loadInitialPermissions();
  }

  @override
  void dispose() {
    for (var controllerList in _pathControllers.values) {
      for (var controller in controllerList) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _loadInitialPermissions() async {
    _logService.logInfo(
      'Loading initial permissions for user: ${widget.user.name}',
    );
    try {
      final initialPermissions = await ref
          .read(databaseProvider)
          .getPermissionsForUser(widget.user.id);
      if (mounted) {
        final newSelectedIds = <int>{};
        final newControllers = <int, List<TextEditingController>>{};
        for (final p in initialPermissions) {
          newSelectedIds.add(p.rabbiId);
          final rawPathData = p.specificPath;
          List<String?> paths = [];
          if (rawPathData != null && rawPathData.isNotEmpty) {
            try {
              final decoded = json.decode(rawPathData) as List;
              paths = decoded.map((e) => e as String?).toList();
            } catch (e) {
              paths.add(rawPathData);
            }
          }
          newControllers[p.rabbiId] = paths
              .map((path) => TextEditingController(text: path))
              .toList();
        }
        setState(() {
          _selectedRabbiIds = newSelectedIds;
          _pathControllers = newControllers;
          _isLoading = false;
        });
        _logService.logInfo(
          'Initial permissions loaded successfully for user: ${widget.user.name}',
        );
      }
    } catch (e, st) {
      _logService.logError(
        'Failed to load initial permissions for user: ${widget.user.name}',
        e,
        st,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('שגיאה בטעינת הרשאות: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _addPathController(int rabbiId) {
    setState(() {
      _pathControllers[rabbiId]!.add(TextEditingController());
    });
  }

  void _removePathController(int rabbiId, int index) {
    setState(() {
      _pathControllers[rabbiId]![index].dispose();
      _pathControllers[rabbiId]!.removeAt(index);
    });
  }

  Future<void> _pickSpecificPath(Rabbi rabbi, int pathIndex) async {
    _logService.logUserActivity(
      'Admin picking specific path for rabbi: ${rabbi.name}',
    );
    final initialDirectory = rabbi.targetPath;
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      initialDirectory: initialDirectory,
      lockParentWindow: true,
      dialogTitle: 'בחר תיקיית יעד ספציפית עבור ${rabbi.name}',
    );
    if (selectedDirectory != null) {
      if (!selectedDirectory.startsWith(initialDirectory)) {
        if (mounted) {
          _logService.logWarning(
            'Selected directory ($selectedDirectory) is not within rabbi\'s base path ($initialDirectory).',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('יש לבחור תיקיה בתוך תיקיית הרב המוגדרת.'),
            ),
          );
        }
        return;
      }
      String relativePath = selectedDirectory.substring(
        initialDirectory.length,
      );
      relativePath = relativePath.replaceAll(r'\', '/');
      if (relativePath.startsWith('/')) {
        relativePath = relativePath.substring(1);
      }
      if (relativePath.endsWith('/')) {
        relativePath = relativePath.substring(0, relativePath.length - 1);
      }
      if (mounted) {
        _logService.logInfo(
          'Selected relative path for rabbi ${rabbi.name}: $relativePath',
        );
        _pathControllers[rabbi.id]?[pathIndex].text = relativePath;
        setState(() {});
      }
    } else {
      _logService.logInfo('Directory picker for specific path cancelled.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final allRabbis = ref.watch(allRabbisProvider);
    return AlertDialog(
      title: Text('עריכת הרשאות עבור ${widget.user.name}'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : allRabbis.when(
                data: (rabbis) => ListView(
                  shrinkWrap: true,
                  children: rabbis.map<Widget>((rabbi) {
                    final isSelected = _selectedRabbiIds.contains(rabbi.id);
                    if (isSelected && _pathControllers[rabbi.id] == null) {
                      _pathControllers[rabbi.id] = [];
                    }
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CheckboxListTile(
                          value: isSelected,
                          title: Text(rabbi.name),
                          subtitle: Text(
                            'נתיב בסיס: ${rabbi.targetPath}',
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.right,
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedRabbiIds.add(rabbi.id);
                                _pathControllers[rabbi.id] = [];
                                _logService.logInfo(
                                  'Admin selected rabbi ${rabbi.name} for user ${widget.user.name}.',
                                );
                              } else {
                                _selectedRabbiIds.remove(rabbi.id);
                                _pathControllers
                                    .remove(rabbi.id)
                                    ?.forEach((c) => c.dispose());
                                _pathControllers.remove(rabbi.id);
                                _logService.logInfo(
                                  'Admin deselected rabbi ${rabbi.name} for user ${widget.user.name}.',
                                );
                              }
                            });
                          },
                        ),
                        if (isSelected)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              16.0,
                              0,
                              16.0,
                              8.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_pathControllers[rabbi.id]!.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: Text(
                                      'למשתמש תהיה גישה לכל תיקיית הבסיס של הרב.',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ..._pathControllers[rabbi.id]!
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                      int idx = entry.key;
                                      TextEditingController controller =
                                          entry.value;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4.0,
                                        ),
                                        child: TextFormField(
                                          controller: controller,
                                          decoration: InputDecoration(
                                            labelText: 'נתיב משנה ${idx + 1}',
                                            hintText: 'לדוגמה: תשפ״ד/שיעורים',
                                            border: const OutlineInputBorder(),
                                            suffixIcon: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.folder_open,
                                                  ),
                                                  onPressed: () =>
                                                      _pickSpecificPath(
                                                        rabbi,
                                                        idx,
                                                      ),
                                                  tooltip:
                                                      'בחר תיקיה מתוך תיקיית הרב',
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                  ),
                                                  onPressed: () =>
                                                      _removePathController(
                                                        rabbi.id,
                                                        idx,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          textAlign: TextAlign.start,
                                          textDirection: TextDirection.ltr,
                                        ),
                                      );
                                    }),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: () => _addPathController(rabbi.id),
                                  icon: const Icon(Icons.add),
                                  label: const Text('הוסף הגבלת תיקיה'),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  }).toList(),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) {
                  _logService.logError(
                    'Error loading rabbis for permissions dialog',
                    e,
                    st,
                  );
                  return Center(child: Text('שגיאה בטעינת רבנים: $e'));
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _logService.logUserActivity(
              'Admin cancelled permissions dialog for user: ${widget.user.name}.',
            );
            Navigator.of(context).pop();
          },
          child: const Text('ביטול'),
        ),
        FilledButton(
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  final permissionsToSet = <int, List<String?>>{};
                  for (final rabbiId in _selectedRabbiIds) {
                    final controllers = _pathControllers[rabbiId]!;
                    permissionsToSet[rabbiId] = controllers
                        .map((c) => c.text)
                        .toList();
                  }
                  try {
                    await ref
                        .read(databaseProvider)
                        .setPermissionsForUser(
                          widget.user.id,
                          permissionsToSet,
                        );
                    _logService.logUserActivity(
                      'Admin set permissions for user ${widget.user.name} (ID: ${widget.user.id}). Permissions: $permissionsToSet',
                    );
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  } catch (e, st) {
                    _logService.logError(
                      'Failed to set permissions for user: ${widget.user.name}',
                      e,
                      st,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('שגיאה בשמירת הרשאות: $e')),
                      );
                      setState(() => _isLoading = false);
                    }
                  }
                },
          child: const Text('שמור'),
        ),
      ],
    );
  }
}
