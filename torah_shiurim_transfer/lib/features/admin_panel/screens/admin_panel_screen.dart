import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:torah_shiurim_transfer/core/database/database.dart';
import 'package:torah_shiurim_transfer/core/providers/providers.dart';
import 'package:torah_shiurim_transfer/models/device_info.dart';
import 'package:torah_shiurim_transfer/services/log_service.dart';

class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logService = ref.read(logServiceProvider);
    logService.logInfo('Admin Panel screen opened.');

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('פאנל ניהול'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'התנתקות',
              onPressed: () {
                logService.logUserActivity('Admin clicked logout button.');
                ref.read(authStateProvider.notifier).logout();
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.person_outline), text: 'משתמשים'),
              Tab(icon: Icon(Icons.mic_external_on_outlined), text: 'רבנים'),
              Tab(icon: Icon(Icons.usb_outlined), text: 'התקנים'),
              Tab(icon: Icon(Icons.settings_outlined), text: 'הגדרות'),
            ],
          ),
        ),
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            _UsersManagementTab(),
            _RabbisManagementTab(),
            _DevicesManagementTab(),
            _SettingsManagementTab(),
          ],
        ),
      ),
    );
  }
}

void _showDeleteConfirmation(BuildContext context, String itemType,
    String itemName, VoidCallback onDelete) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('אישור מחיקה'),
      content:
          Text('האם למחוק את ה$itemType "$itemName"?\nפעולה זו אינה הפיכה.'),
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

class _UsersManagementTab extends ConsumerWidget {
  const _UsersManagementTab();

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

            String subtitleText = user.isAdmin ? 'מנהל' : 'משתמש רגיל';
            if (user.additionalInfo != null &&
                user.additionalInfo!.isNotEmpty) {
              subtitleText += '\nפרטים נוספים: ${user.additionalInfo}';
            }

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading:
                    Icon(user.isAdmin ? Icons.shield_outlined : Icons.person),
                title: Text(user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(subtitleText),
                isThreeLine: user.additionalInfo != null &&
                    user.additionalInfo!.isNotEmpty,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!user.isAdmin)
                      TextButton(
                        child: const Text('הרשאות'),
                        onPressed: () {
                          logService.logUserActivity(
                              'Admin opened permissions dialog for user: ${user.name}');
                          _showPermissionsDialog(context, ref, user);
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Theme.of(context).colorScheme.error,
                      tooltip: 'מחק משתמש',
                      onPressed: () => _showDeleteConfirmation(
                          context, 'משתמש', user.name, () async {
                        try {
                          await ref.read(databaseProvider).deleteUser(user.id);
                          logService.logUserActivity(
                              'Admin deleted user: ${user.name} (ID: ${user.id})');
                        } catch (e, st) {
                          logService.logError(
                              'Failed to delete user: ${user.name}', e, st);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('שגיאה במחיקת משתמש: $e')));
                        }
                      }),
                    ),
                  ],
                ),
                onTap: () {
                  logService.logUserActivity(
                      'Admin opened "Edit User" dialog for user: ${user.name}');
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

  void _showPermissionsDialog(BuildContext context, WidgetRef ref, User user) {
    showDialog(
      context: context,
      builder: (context) => _PermissionsDialog(user: user),
    );
  }

  void _showUserDialog(BuildContext context, WidgetRef ref, {User? user}) {
    final nameController = TextEditingController(text: user?.name);
    bool isAdmin = user?.isAdmin ?? false;

    final additionalInfoController =
        TextEditingController(text: user?.additionalInfo);
    final formKey = GlobalKey<FormState>();
    final logService = ref.read(logServiceProvider);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                          labelText: 'שם משתמש', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'שדה חובה' : null,
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: additionalInfoController,
                      decoration: const InputDecoration(
                          labelText: 'פרטים נוספים (טלפון, שיעור, ועד וכו\')',
                          border: OutlineInputBorder()),
                      textAlign: TextAlign.start,
                      minLines: 3,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('האם מנהל?'),
                      value: isAdmin,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            isAdmin = value;
                          });
                        }
                      },
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
                        isAdmin: drift.Value(isAdmin),
                        additionalInfo: drift.Value(
                            additionalInfoController.text.trim().isEmpty
                                ? null
                                : additionalInfoController.text.trim()),
                      );
                      try {
                        if (user == null) {
                          final newUserId = await ref
                              .read(databaseProvider)
                              .insertUser(companion);
                          logService.logUserActivity(
                              'Admin added new user: ${nameController.text} (ID: $newUserId, isAdmin: $isAdmin)');
                        } else {
                          await ref.read(databaseProvider).updateUser(
                                companion.copyWith(id: drift.Value(user.id)),
                              );
                          logService.logUserActivity(
                              'Admin updated user: ${user.name} (ID: ${user.id}) to ${nameController.text}, isAdmin: $isAdmin');
                        }
                        Navigator.of(context).pop();
                      } catch (e, st) {
                        logService.logError(
                            'Failed to save user: ${nameController.text}',
                            e,
                            st);
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('שגיאה בשמירת משתמש: $e')));
                      }
                    }
                  },
                  child: const Text('שמירה'),
                ),
              ],
            );
          },
        );
      },
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
  Map<int, TextEditingController> _pathControllers = {};
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
    for (var controller in _pathControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadInitialPermissions() async {
    _logService
        .logInfo('Loading initial permissions for user: ${widget.user.name}');
    try {
      final initialPermissions = await ref
          .read(databaseProvider)
          .getPermissionsForUser(widget.user.id);
      if (mounted) {
        final newSelectedIds = <int>{};
        final newControllers = <int, TextEditingController>{};
        for (final p in initialPermissions) {
          newSelectedIds.add(p.rabbiId);

          newControllers[p.rabbiId] =
              TextEditingController(text: p.specificPath);
        }
        setState(() {
          _selectedRabbiIds = newSelectedIds;
          _pathControllers = newControllers;
          _isLoading = false;
        });
        _logService.logInfo(
            'Initial permissions loaded successfully for user: ${widget.user.name}');
      }
    } catch (e, st) {
      _logService.logError(
          'Failed to load initial permissions for user: ${widget.user.name}',
          e,
          st);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('שגיאה בטעינת הרשאות: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickSpecificPath(Rabbi rabbi) async {
    _logService.logUserActivity(
        'Admin picking specific path for rabbi: ${rabbi.name}');
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
              'Selected directory ($selectedDirectory) is not within rabbi\'s base path ($initialDirectory).');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('יש לבחור תיקיה בתוך תיקיית הרב המוגדרת.')),
          );
        }
        return;
      }

      String relativePath =
          selectedDirectory.substring(initialDirectory.length);

      relativePath = relativePath.replaceAll(r'\', '/');
      if (relativePath.startsWith('/')) {
        relativePath = relativePath.substring(1);
      }
      if (relativePath.endsWith('/')) {
        relativePath = relativePath.substring(0, relativePath.length - 1);
      }

      if (mounted) {
        _logService.logInfo(
            'Selected relative path for rabbi ${rabbi.name}: $relativePath');
        _pathControllers[rabbi.id]?.text = relativePath;
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

                    _pathControllers.putIfAbsent(
                        rabbi.id, () => TextEditingController());
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CheckboxListTile(
                          value: isSelected,
                          title: Text(rabbi.name),
                          subtitle: Text('נתיב בסיס: ${rabbi.targetPath}',
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.right),
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedRabbiIds.add(rabbi.id);
                                _logService.logInfo(
                                    'Admin selected rabbi ${rabbi.name} for user ${widget.user.name}.');
                              } else {
                                _selectedRabbiIds.remove(rabbi.id);
                                _pathControllers.remove(rabbi.id)?.dispose();
                                _logService.logInfo(
                                    'Admin deselected rabbi ${rabbi.name} for user ${widget.user.name}.');
                              }
                            });
                          },
                        ),
                        if (isSelected)
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                            child: TextFormField(
                              controller: _pathControllers[rabbi.id],
                              decoration: InputDecoration(
                                labelText: 'הגבלת תיקיה (אופציונלי)',
                                hintText: 'לדוגמה: תשפ״ד/שיעורים',
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.folder_open),
                                  onPressed: () => _pickSpecificPath(rabbi),
                                  tooltip: 'בחר תיקיה מתוך תיקיית הרב',
                                ),
                              ),
                              textAlign: TextAlign.start,
                            ),
                          ),
                      ],
                    );
                  }).toList(),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) {
                  _logService.logError(
                      'Error loading rabbis for permissions dialog', e, st);
                  return Center(child: Text('שגיאה בטעינת רבנים: $e'));
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _logService.logUserActivity(
                'Admin cancelled permissions dialog for user: ${widget.user.name}.');
            Navigator.of(context).pop();
          },
          child: const Text('ביטול'),
        ),
        FilledButton(
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  final permissionsToSet = <int, String?>{};
                  for (final rabbiId in _selectedRabbiIds) {
                    final path = _pathControllers[rabbiId]?.text.trim();

                    permissionsToSet[rabbiId] =
                        (path != null && path.isNotEmpty) ? path : null;
                  }
                  try {
                    await ref.read(databaseProvider).setPermissionsForUser(
                          widget.user.id,
                          permissionsToSet,
                        );
                    _logService.logUserActivity(
                        'Admin set permissions for user ${widget.user.name} (ID: ${widget.user.id}). Permissions: $permissionsToSet');
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  } catch (e, st) {
                    _logService.logError(
                        'Failed to set permissions for user: ${widget.user.name}',
                        e,
                        st);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('שגיאה בשמירת הרשאות: $e')));
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

class _RabbisManagementTab extends ConsumerWidget {
  const _RabbisManagementTab();

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
          padding: const EdgeInsets.all(8),
          itemCount: rabbis.length,
          itemBuilder: (context, index) {
            final rabbi = rabbis[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.folder_special_outlined),
                title: Text(rabbi.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('נתיב: ${rabbi.targetPath}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Theme.of(context).colorScheme.error,
                  tooltip: 'מחק רב',
                  onPressed: () => _showDeleteConfirmation(
                      context, 'רב', rabbi.name, () async {
                    try {
                      await ref.read(databaseProvider).deleteRabbi(rabbi.id);
                      logService.logUserActivity(
                          'Admin deleted rabbi: ${rabbi.name} (ID: ${rabbi.id})');
                    } catch (e, st) {
                      logService.logError(
                          'Failed to delete rabbi: ${rabbi.name}', e, st);
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('שגיאה במחיקת רב: $e')));
                    }
                  }),
                ),
                onTap: () {
                  logService.logUserActivity(
                      'Admin opened "Edit Rabbi" dialog for rabbi: ${rabbi.name}');
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
                    labelText: 'שם הרב', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'שדה חובה' : null,
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: pathController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'נתיב יעד (במחשב)',
                  border: const OutlineInputBorder(),
                  prefixIcon: IconButton(
                    icon: const Icon(Icons.folder_open),
                    onPressed: () async {
                      logService.logUserActivity(
                          'Admin picking target path for rabbi.');
                      String? selectedDirectory =
                          await FilePicker.platform.getDirectoryPath();
                      if (selectedDirectory != null) {
                        pathController.text = selectedDirectory;
                        logService.logInfo(
                            'Selected target path: $selectedDirectory');
                      } else {
                        logService.logInfo('Target path picker cancelled.');
                      }
                    },
                  ),
                ),
                validator: (v) => v!.isEmpty ? 'שדה חובה' : null,
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
              child: const Text('ביטול')),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final companion = RabbisCompanion(
                  name: drift.Value(nameController.text),
                  targetPath: drift.Value(pathController.text),
                );
                try {
                  if (rabbi == null) {
                    final newRabbiId =
                        await ref.read(databaseProvider).insertRabbi(companion);
                    logService.logUserActivity(
                        'Admin added new rabbi: ${nameController.text} (ID: $newRabbiId, Path: ${pathController.text})');
                  } else {
                    await ref.read(databaseProvider).updateRabbi(
                        companion.copyWith(id: drift.Value(rabbi.id)));
                    logService.logUserActivity(
                        'Admin updated rabbi: ${rabbi.name} (ID: ${rabbi.id}) to ${nameController.text}, Path: ${pathController.text}');
                  }
                  Navigator.of(context).pop();
                } catch (e, st) {
                  logService.logError(
                      'Failed to save rabbi: ${nameController.text}', e, st);
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('שגיאה בשמירת רב: $e')));
                }
              }
            },
            child: const Text('שמירה'),
          ),
        ],
      ),
    );
  }
}

class _DevicesManagementTab extends ConsumerWidget {
  const _DevicesManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(allDevicesProvider);
    final logService = ref.read(logServiceProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('הוסף התקן'),
        onPressed: () {
          logService.logUserActivity('Admin opened "Add Device" dialog.');
          _showDeviceDialog(context, ref);
        },
      ),
      body: devicesAsync.when(
        data: (devices) => ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: devices.length,
          itemBuilder: (context, index) {
            final deviceWithUser = devices[index];
            final device = deviceWithUser.device;
            final user = deviceWithUser.user;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.memory),
                title: Text('מספר סידורי: ${device.serialNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    'משוייך ל: ${user.name}\nנתיב מקור: ${device.sourcePath.isEmpty ? 'שורש הכונן' : device.sourcePath}'),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Theme.of(context).colorScheme.error,
                  tooltip: 'מחק התקן',
                  onPressed: () => _showDeleteConfirmation(
                      context, 'התקן', device.serialNumber, () async {
                    try {
                      await ref.read(databaseProvider).deleteDevice(device.id);
                      logService.logUserActivity(
                          'Admin deleted device: ${device.serialNumber} (ID: ${device.id})');
                    } catch (e, st) {
                      logService.logError(
                          'Failed to delete device: ${device.serialNumber}',
                          e,
                          st);
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('שגיאה במחיקת התקן: $e')));
                    }
                  }),
                ),
                onTap: () {
                  logService.logUserActivity(
                      'Admin opened "Edit Device" dialog for device: ${device.serialNumber}');
                  _showDeviceDialog(context, ref, device: device);
                },
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) {
          logService.logError('Error loading devices data', e, st);
          return Center(child: Text('Error: $e'));
        },
      ),
    );
  }

  void _showDeviceDialog(BuildContext context, WidgetRef ref,
      {Device? device}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DeviceDialog(device: device),
    );
  }
}

class _DeviceDialog extends ConsumerStatefulWidget {
  final Device? device;
  const _DeviceDialog({this.device});

  @override
  ConsumerState<_DeviceDialog> createState() => __DeviceDialogState();
}

class __DeviceDialogState extends ConsumerState<_DeviceDialog> {
  late TextEditingController _serialController;
  late TextEditingController _sourcePathController;
  int? _selectedUserId;
  final _formKey = GlobalKey<FormState>();

  String? _mountPath;
  bool _isLoading = false;
  bool _isChangingSerial = false;
  bool _isEditingSerial = false;
  late final LogService _logService;

  @override
  void initState() {
    super.initState();
    _logService = ref.read(logServiceProvider);
    _serialController =
        TextEditingController(text: widget.device?.serialNumber);
    _sourcePathController =
        TextEditingController(text: widget.device?.sourcePath);
    _selectedUserId = widget.device?.userId;
    _isEditingSerial = widget.device == null;

    if (widget.device != null) {
      _findCurrentMountPath();
    }
  }

  @override
  void dispose() {
    _serialController.dispose();
    _sourcePathController.dispose();
    super.dispose();
  }

  Future<void> _findCurrentMountPath() async {
    if (widget.device == null) return;
    _logService.logInfo(
        'Attempting to find current mount path for device serial: ${widget.device!.serialNumber}');
    try {
      final devices = await ref.read(connectedDevicesProvider.future);
      final connectedDevice = devices.firstWhere(
        (d) => d.serialNumber == widget.device!.serialNumber,
      );
      if (mounted) {
        setState(() {
          _mountPath = connectedDevice.mountPath;
        });
        _logService.logInfo(
            'Found mount path for ${widget.device!.serialNumber}: $_mountPath');
      }
    } catch (e) {
      _logService.logInfo(
          'Mount path not found for device ${widget.device!.serialNumber}: $e');
    }
  }

  String _generateRandomSerial() {
    final random = Random();
    const chars = 'ABCDEF0123456789';
    final part1 = String.fromCharCodes(Iterable.generate(
        4, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
    final part2 = String.fromCharCodes(Iterable.generate(
        4, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
    final generatedSerial = '$part1-$part2';
    _logService.logInfo('Generated random serial number: $generatedSerial');
    return generatedSerial;
  }

  Future<void> _locateDevice() async {
    setState(() => _isLoading = true);
    _logService.logUserActivity('Admin initiated device location process.');
    try {
      final selectedPath = await FilePicker.platform.getDirectoryPath(
        lockParentWindow: true,
        dialogTitle: 'בחר תיקיית מקור מההתקן החיצוני',
      );
      if (selectedPath == null) {
        _logService.logInfo('Device location cancelled by user.');
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      _logService.logInfo('User selected path: $selectedPath');

      final devices = await ref.read(connectedDevicesProvider.future);
      if (!mounted) return;

      if (devices.isEmpty) {
        _logService
            .logWarning('No external drives found during device location.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("לא נמצאו כוננים חיצוניים.")),
        );
        setState(() => _isLoading = false);
        return;
      }

      ConnectedDeviceInfo? drive;
      try {
        drive = devices.firstWhere((d) => selectedPath.startsWith(d.mountPath));
      } catch (e) {
        drive = null;
      }

      if (drive == null) {
        if (mounted) {
          _logService.logWarning(
              'Selected path ($selectedPath) is not on a recognized external drive.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text("התיקיה שנבחרה אינה נמצאת על כונן חיצוני מזוהה.")),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      String relativePath =
          selectedPath.substring(drive.mountPath.length).trim();
      if (relativePath.startsWith(r'\') || relativePath.startsWith('/')) {
        relativePath = relativePath.substring(1);
      }

      if (mounted) {
        setState(() {
          _mountPath = drive!.mountPath;
          _serialController.text = drive.serialNumber;
          _sourcePathController.text = relativePath;
          _isLoading = false;
          _isEditingSerial = false;
        });
        _logService.logInfo(
            'Device located successfully. MountPath: $_mountPath, Serial: ${_serialController.text}, SourcePath: $_sourcePathController.text');
      }
    } catch (e, st) {
      _logService.logError('Error during device location process.', e, st);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _changeDeviceSerial() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      _logService.logWarning(
          'Attempted to change device serial with invalid form data.');
      return;
    }

    setState(() => _isChangingSerial = true);
    _logService.logUserActivity(
        'Admin attempting to change serial for device at $_mountPath to ${_serialController.text}.');
    try {
      final resultMessage = await ref
          .read(deviceServiceProvider)
          .changeVolumeSerialNumber(_mountPath!, _serialController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('הפעולה הצליחה: $resultMessage'),
              backgroundColor: Colors.green),
        );
        _logService.logUserActivity(
            'Successfully changed serial number for device: $_mountPath to ${_serialController.text}. Message: $resultMessage');
      }
    } catch (e, st) {
      _logService.logError(
          'Failed to change serial number for device at $_mountPath to ${_serialController.text}.',
          e,
          st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChangingSerial = false);
      }
    }
  }

  Future<void> _saveDevice() async {
    if (_formKey.currentState!.validate()) {
      final serialNumber = _serialController.text;
      final companion = DevicesCompanion(
        serialNumber: drift.Value(serialNumber),
        sourcePath: drift.Value(_sourcePathController.text),
        userId: drift.Value(_selectedUserId!),
      );

      try {
        if (widget.device == null) {
          final newDeviceId =
              await ref.read(databaseProvider).insertDevice(companion);
          _logService.logUserActivity(
              'Admin added new device: $serialNumber (ID: $newDeviceId), assigned to user ID: $_selectedUserId, SourcePath: ${_sourcePathController.text}');
        } else {
          await ref.read(databaseProvider).updateDevice(
              companion.copyWith(id: drift.Value(widget.device!.id)));
          _logService.logUserActivity(
              'Admin updated device: ${widget.device!.serialNumber} (ID: ${widget.device!.id}) to $serialNumber, assigned to user ID: $_selectedUserId, SourcePath: ${_sourcePathController.text}');
        }
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e, st) {
        _logService.logError('Failed to save device: $serialNumber', e, st);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('שגיאה בשמירה: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      _logService
          .logWarning('Attempted to save device with invalid form data.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);

    return AlertDialog(
      title: Text(widget.device == null ? 'הוספת התקן חדש' : 'עריכת התקן'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.drive_folder_upload_outlined),
                label: Text(
                    _isLoading ? "נא המתן..." : "אתר התקן ובחר תיקיית מקור"),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48)),
                onPressed: _isLoading ? null : _locateDevice,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _serialController,
                readOnly: !_isEditingSerial,
                decoration: InputDecoration(
                  labelText: 'מספר סידורי',
                  border: const OutlineInputBorder(),
                  prefixIcon: IconButton(
                    icon: Icon(_isEditingSerial ? Icons.lock_open : Icons.edit),
                    onPressed: () {
                      setState(() {
                        _isEditingSerial = !_isEditingSerial;
                        _logService.logInfo(
                            'Admin toggled serial number editing for device dialog. Now: $_isEditingSerial');
                      });
                    },
                    tooltip:
                        _isEditingSerial ? 'נעל עריכה' : 'אפשר עריכה ידנית',
                  ),
                  suffixIcon: _isEditingSerial
                      ? IconButton(
                          icon: const Icon(Icons.casino_outlined),
                          tooltip: 'צור מספר אקראי',
                          onPressed: () {
                            _serialController.text = _generateRandomSerial();
                          },
                        )
                      : null,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'שדה חובה';
                  final sanitized = v.replaceAll('-', '');
                  if (!RegExp(r'^[0-9A-Fa-f]{8}$', caseSensitive: false)
                      .hasMatch(sanitized)) {
                    return 'פורמט לא תקין (8 תווים הקסדצימליים)';
                  }
                  return null;
                },
              ),
              if (Platform.isWindows && _mountPath != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: OutlinedButton.icon(
                    icon: _isChangingSerial
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.sync_alt),
                    label: const Text("שנה מספר סריאלי בהתקן"),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 40),
                        foregroundColor: Theme.of(context).colorScheme.primary),
                    onPressed: _isChangingSerial ? null : _changeDeviceSerial,
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sourcePathController,
                decoration: const InputDecoration(
                  labelText: 'נתיב מקור (יחסית לכונן)',
                  hintText: 'לדוגמה: records (או ריק לשורש)',
                  border: OutlineInputBorder(),
                ),
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 16),
              usersAsync.when(
                data: (users) => DropdownButtonFormField<int>(
                  value: _selectedUserId,
                  hint: const Text('בחר משתמש לשיוך'),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'משתמש משוייך',
                  ),
                  items: users
                      .where((u) => !u.isAdmin)
                      .map((u) =>
                          DropdownMenuItem(value: u.id, child: Text(u.name)))
                      .toList(),
                  onChanged: (id) {
                    setState(() => _selectedUserId = id);
                    final selectedUser = users.firstWhere(
                        (u) => u.id == id); // NEW: Get selected user name
                    _logService.logInfo(
                        'Admin selected user ${selectedUser.name} (ID: $id) for device association.'); // NEW
                  },
                  validator: (id) => id == null ? 'שדה חובה' : null,
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, st) {
                  _logService.logError(
                      'Error loading users for device dialog', e, st);
                  return Text("Error: $e");
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () {
              _logService.logUserActivity('Admin cancelled device dialog.');
              Navigator.of(context).pop();
            },
            child: const Text('ביטול')),
        FilledButton(
          onPressed: _saveDevice,
          child: const Text('שמירה'),
        ),
      ],
    );
  }
}

class _SettingsManagementTab extends ConsumerWidget {
  const _SettingsManagementTab();

  Future<void> _backupSettings(BuildContext context, WidgetRef ref) async {
    final logService = ref.read(logServiceProvider);
    logService.logUserActivity('Admin initiated settings backup.');
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final db = ref.read(databaseProvider);

      final users = await db.select(db.users).get();
      final devices = await db.select(db.devices).get();
      final rabbis = await db.select(db.rabbis).get();
      final permissions = await db.select(db.userRabbiPermissions).get();
      final settings = await db.getAppSettings();

      final backupData = {
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'users': users.map((u) => u.toJson()).toList(),
        'devices': devices.map((d) => d.toJson()).toList(),
        'rabbis': rabbis.map((r) => r.toJson()).toList(),
        'userRabbiPermissions': permissions.map((p) => p.toJson()).toList(),
        'appSettings': settings.toJson(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      final fileName =
          'torah_shiurim_backup_${DateTime.now().toIso8601String().split('T').first}.json';
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'שמור קובץ גיבוי',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsString(jsonString);
        logService.logInfo('Settings backup saved to: $result');
        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
                content: Text('הגיבוי נשמר בהצלחה: $result'),
                backgroundColor: Colors.green),
          );
        }
      } else {
        logService.logInfo('Settings backup save was cancelled by user.');
      }
    } catch (e, st) {
      logService.logError('Failed to backup settings', e, st);
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
              content: Text('שגיאה ביצירת הגיבוי: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _restoreSettings(BuildContext context, WidgetRef ref) async {
    final logService = ref.read(logServiceProvider);
    logService.logUserActivity('Admin initiated settings restore.');
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('אזהרה: שחזור הגדרות'),
        content: const Text(
            'פעולה זו תמחק את כל המשתמשים (למעט מנהלים), ההתקנים, הרבנים וההרשאות הנוכחיים ותחליף אותם בנתונים מקובץ הגיבוי.\n\nהאם אתה בטוח שברצונך להמשיך?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ביטול')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('אני מאשר, המשך'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      logService.logInfo(
          'Settings restore was cancelled by user at confirmation dialog.');
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        logService.logInfo('Settings restore file picker was cancelled.');
        return;
      }
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString);

      final db = ref.read(databaseProvider);
      await db.transaction(() async {
        logService.logInfo("Starting database restore transaction.");

        await db.delete(db.userRabbiPermissions).go();
        await db.delete(db.devices).go();
        await db.delete(db.rabbis).go();
        await (db.delete(db.users)..where((u) => u.isAdmin.equals(false))).go();
        logService.logInfo(
            "Cleared non-admin users, devices, rabbis, and permissions.");

        final settingsMap = backupData['appSettings'] as Map<String, dynamic>;
        await db.updateAppSettings(AppSettingsCompanion(
          convertToMp3: drift.Value(settingsMap['convertToMp3']),
          mp3Bitrate: drift.Value(settingsMap['mp3Bitrate']),
        ));
        logService.logInfo("Restored app settings.");

        final oldNewRabbiIdMap = <int, int>{};
        final rabbisList = backupData['rabbis'] as List;
        for (final rabbiMap in rabbisList) {
          final oldId = rabbiMap['id'] as int;
          final newId = await db.into(db.rabbis).insert(RabbisCompanion.insert(
                name: rabbiMap['name'],
                targetPath: rabbiMap['targetPath'],
              ));
          oldNewRabbiIdMap[oldId] = newId;
        }
        logService.logInfo("Restored ${rabbisList.length} rabbis.");

        final oldNewUserIdMap = <int, int>{};
        final usersList = backupData['users'] as List;
        for (final userMap in usersList) {
          if (userMap['isAdmin'] == false) {
            final oldId = userMap['id'] as int;
            final newId = await db.into(db.users).insert(UsersCompanion.insert(
                  name: userMap['name'],
                  isAdmin: const drift.Value(false),
                  additionalInfo: drift.Value(userMap['additionalInfo']),
                ));
            oldNewUserIdMap[oldId] = newId;
          }
        }
        logService
            .logInfo("Restored ${oldNewUserIdMap.length} non-admin users.");

        final devicesList = backupData['devices'] as List;
        for (final deviceMap in devicesList) {
          final oldUserId = deviceMap['userId'] as int;
          final newUserId = oldNewUserIdMap[oldUserId];
          if (newUserId != null) {
            await db.into(db.devices).insert(DevicesCompanion.insert(
                  userId: newUserId,
                  serialNumber: deviceMap['serialNumber'],
                  sourcePath: deviceMap['sourcePath'],
                ));
          }
        }
        logService.logInfo("Restored devices.");

        final permissionsList = backupData['userRabbiPermissions'] as List;
        for (final permMap in permissionsList) {
          final oldUserId = permMap['userId'] as int;
          final oldRabbiId = permMap['rabbiId'] as int;
          final newUserId = oldNewUserIdMap[oldUserId];
          final newRabbiId = oldNewRabbiIdMap[oldRabbiId];
          if (newUserId != null && newRabbiId != null) {
            await db.into(db.userRabbiPermissions).insert(
                UserRabbiPermissionsCompanion.insert(
                    userId: newUserId,
                    rabbiId: newRabbiId,
                    specificPath: drift.Value(permMap['specificPath'])));
          }
        }
        logService.logInfo("Restored permissions.");
      });

      logService
          .logUserActivity('Settings successfully restored from ${file.path}.');
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
              content: Text('ההגדרות שוחזרו בהצלחה. הנתונים מתרעננים.'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e, st) {
      logService.logError('Failed to restore settings', e, st);
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
              content: Text('שגיאה בשחזור ההגדרות: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final logService = ref.read(logServiceProvider);

    return Scaffold(
      body: settingsAsync.when(
        data: (settings) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'הגדרות המרה ל-MP3',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Divider(height: 24),
                      SwitchListTile(
                        title: const Text('המר קבצים ל-MP3 בעת ההעתקה'),
                        subtitle: const Text(
                            'הפעלה תגרום להמרת כל קובץ שמע לפורמט MP3. דורש התקנת ffmpeg.'),
                        value: settings.convertToMp3,
                        onChanged: (value) async {
                          try {
                            await ref.read(databaseProvider).updateAppSettings(
                                  AppSettingsCompanion(
                                      convertToMp3: drift.Value(value)),
                                );
                            logService.logUserActivity(
                                'Admin changed "Convert to MP3" setting to: $value.');
                          } catch (e, st) {
                            logService.logError(
                                'Failed to update "Convert to MP3" setting',
                                e,
                                st);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('שגיאה בעדכון הגדרה: $e')));
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: settings.convertToMp3 ? 1.0 : 0.4,
                        child: IgnorePointer(
                          ignoring: !settings.convertToMp3,
                          child: DropdownButtonFormField<int>(
                            value: settings.mp3Bitrate,
                            decoration: const InputDecoration(
                              labelText: 'איכות (Bitrate)',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 64, child: Text('נמוכה (64kbps)')),
                              DropdownMenuItem(
                                  value: 128, child: Text('בינונית (128kbps)')),
                              DropdownMenuItem(
                                  value: 192, child: Text('גבוהה (192kbps)')),
                              DropdownMenuItem(
                                  value: 256,
                                  child: Text('גבוהה מאוד (256kbps)')),
                              DropdownMenuItem(
                                  value: 320, child: Text('מעולה (320kbps)')),
                            ],
                            onChanged: (value) async {
                              if (value != null) {
                                try {
                                  await ref
                                      .read(databaseProvider)
                                      .updateAppSettings(
                                        AppSettingsCompanion(
                                            mp3Bitrate: drift.Value(value)),
                                      );
                                  logService.logUserActivity(
                                      'Admin changed MP3 bitrate setting to: ${value}kbps.');
                                } catch (e, st) {
                                  logService.logError(
                                      'Failed to update MP3 bitrate setting',
                                      e,
                                      st);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('שגיאה בעדכון הגדרה: $e')));
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'גיבוי ושחזור',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Divider(height: 24),
                      ListTile(
                        leading: const Icon(Icons.backup_outlined),
                        title: const Text('גיבוי הגדרות והרשאות'),
                        subtitle: const Text(
                            'שמור את כלל הגדרות המערכת לקובץ גיבוי.'),
                        onTap: () => _backupSettings(context, ref),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: Icon(Icons.restore_page_outlined,
                            color: Theme.of(context).colorScheme.error),
                        title: Text('שחזור הגדרות מקובץ',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                        subtitle: Text('פעולה זו תחליף את כל ההגדרות הנוכחיות.',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                        onTap: () => _restoreSettings(context, ref),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) {
          logService.logError('Error loading app settings', e, st);
          return Center(child: Text('Error loading settings: $e'));
        },
      ),
    );
  }
}
