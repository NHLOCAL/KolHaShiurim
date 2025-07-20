import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:torah_shiurim_transfer/core/database/database.dart';
import 'package:torah_shiurim_transfer/core/providers/providers.dart';
import 'package:torah_shiurim_transfer/models/device_info.dart';

class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('פאנל ניהול'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'התנתקות',
              onPressed: () => ref.read(authStateProvider.notifier).logout(),
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
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('הוסף משתמש'),
        onPressed: () => _showUserDialog(context, ref),
      ),
      body: usersAsync.when(
        data: (users) => ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading:
                    Icon(user.isAdmin ? Icons.shield_outlined : Icons.person),
                title: Text(user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(user.isAdmin ? 'מנהל' : 'משתמש רגיל'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!user.isAdmin)
                      TextButton(
                        child: const Text('הרשאות'),
                        onPressed: () =>
                            _showPermissionsDialog(context, ref, user),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Theme.of(context).colorScheme.error,
                      tooltip: 'מחק משתמש',
                      onPressed: () => _showDeleteConfirmation(
                          context, 'משתמש', user.name, () {
                        ref.read(databaseProvider).deleteUser(user.id);
                      }),
                    ),
                  ],
                ),
                onTap: () => _showUserDialog(context, ref, user: user),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
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
    final formKey = GlobalKey<FormState>();

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
                      );
                      if (user == null) {
                        await ref.read(databaseProvider).insertUser(companion);
                      } else {
                        await ref.read(databaseProvider).updateUser(
                              companion.copyWith(id: drift.Value(user.id)),
                            );
                      }
                      Navigator.of(context).pop();
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
  late Future<List<int>> _initialPermissionsFuture;
  Set<int> _selectedRabbiIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialPermissionsFuture =
        ref.read(databaseProvider).getPermissionIdsForUser(widget.user.id);
    _initialPermissionsFuture.then((ids) {
      if (mounted) {
        setState(() {
          _selectedRabbiIds = ids.toSet();
          _isLoading = false;
        });
      }
    });
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
                    return CheckboxListTile(
                      value: isSelected,
                      title: Text(rabbi.name),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedRabbiIds.add(rabbi.id);
                          } else {
                            _selectedRabbiIds.remove(rabbi.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('שגיאה בטעינת רבנים: $e')),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ביטול'),
        ),
        FilledButton(
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  await ref.read(databaseProvider).setPermissionsForUser(
                        widget.user.id,
                        _selectedRabbiIds.toList(),
                      );
                  if (mounted) {
                    setState(() => _isLoading = false);
                    Navigator.of(context).pop();
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
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('הוסף רב'),
        onPressed: () => _showRabbiDialog(context, ref),
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
                  onPressed: () =>
                      _showDeleteConfirmation(context, 'רב', rabbi.name, () {
                    ref.read(databaseProvider).deleteRabbi(rabbi.id);
                  }),
                ),
                onTap: () => _showRabbiDialog(context, ref, rabbi: rabbi),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showRabbiDialog(BuildContext context, WidgetRef ref, {Rabbi? rabbi}) {
    final nameController = TextEditingController(text: rabbi?.name);
    final pathController = TextEditingController(text: rabbi?.targetPath);
    final formKey = GlobalKey<FormState>();

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
                      String? selectedDirectory =
                          await FilePicker.platform.getDirectoryPath();
                      if (selectedDirectory != null) {
                        pathController.text = selectedDirectory;
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ביטול')),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final companion = RabbisCompanion(
                  name: drift.Value(nameController.text),
                  targetPath: drift.Value(pathController.text),
                );
                if (rabbi == null) {
                  await ref.read(databaseProvider).insertRabbi(companion);
                } else {
                  await ref.read(databaseProvider).updateRabbi(
                      companion.copyWith(id: drift.Value(rabbi.id)));
                }
                Navigator.of(context).pop();
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
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('הוסף התקן'),
        onPressed: () => _showDeviceDialog(context, ref),
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
                      context, 'התקן', device.serialNumber, () {
                    ref.read(databaseProvider).deleteDevice(device.id);
                  }),
                ),
                onTap: () => _showDeviceDialog(context, ref, device: device),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showDeviceDialog(BuildContext context, WidgetRef ref,
      {Device? device}) {
    final serialController = TextEditingController(text: device?.serialNumber);
    final sourcePathController =
        TextEditingController(text: device?.sourcePath);
    int? selectedUserId = device?.userId;
    final formKey = GlobalKey<FormState>();

    String? detectedMountPath;
    bool isLoading = false;
    bool isChangingSerial = false;
    bool isEditingSerial = device == null;

    String generateRandomSerial() {
      final random = Random();
      const chars = 'ABCDEF0123456789';
      final part1 = String.fromCharCodes(Iterable.generate(
          4, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
      final part2 = String.fromCharCodes(Iterable.generate(
          4, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
      return '$part1-$part2';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final usersAsync = ref.watch(allUsersProvider);

            return AlertDialog(
              title: Text(device == null ? 'הוספת התקן חדש' : 'עריכת התקן'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.drive_folder_upload_outlined),
                        label: Text(isLoading
                            ? "נא המתן..."
                            : "אתר התקן ובחר תיקיית מקור"),
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48)),
                        onPressed: isLoading
                            ? null
                            : () async {
                                setState(() => isLoading = true);
                                try {
                                  final selectedPath = await FilePicker.platform
                                      .getDirectoryPath(
                                    lockParentWindow: true,
                                    dialogTitle:
                                        'בחר תיקיית מקור מההתקן החיצוני',
                                  );
                                  if (selectedPath == null) {
                                    setState(() => isLoading = false);
                                    return;
                                  }

                                  final devices = await ref
                                      .read(connectedDevicesProvider.future);

                                  if (!context.mounted) return;

                                  if (devices.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              "לא נמצאו כוננים חיצוניים.")),
                                    );
                                    setState(() => isLoading = false);
                                    return;
                                  }

                                  ConnectedDeviceInfo? drive;
                                  try {
                                    drive = devices.firstWhere((d) =>
                                        selectedPath.startsWith(d.mountPath));
                                  } catch (e) {
                                    drive = null;
                                  }

                                  if (drive == null) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                "התיקיה שנבחרה אינה נמצאת על כונן חיצוני מזוהה.")),
                                      );
                                    }
                                    setState(() => isLoading = false);
                                    return;
                                  }

                                  String relativePath = selectedPath
                                      .substring(drive.mountPath.length)
                                      .trim();
                                  if (relativePath.startsWith(r'\') ||
                                      relativePath.startsWith('/')) {
                                    relativePath = relativePath.substring(1);
                                  }

                                  if (context.mounted) {
                                    setState(() {
                                      detectedMountPath = drive!.mountPath;
                                      serialController.text =
                                          drive.serialNumber;
                                      sourcePathController.text = relativePath;
                                      isLoading = false;
                                      isEditingSerial = false;
                                    });
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    setState(() => isLoading = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('שגיאה: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: serialController,
                        readOnly: !isEditingSerial,
                        decoration: InputDecoration(
                          labelText: 'מספר סידורי',
                          border: const OutlineInputBorder(),
                          prefixIcon: IconButton(
                            icon: Icon(
                                isEditingSerial ? Icons.lock_open : Icons.edit),
                            onPressed: () {
                              setState(() {
                                isEditingSerial = !isEditingSerial;
                              });
                            },
                            tooltip: isEditingSerial
                                ? 'נעל עריכה'
                                : 'אפשר עריכה ידנית',
                          ),
                          suffixIcon: isEditingSerial
                              ? IconButton(
                                  icon: const Icon(Icons.casino_outlined),
                                  tooltip: 'צור מספר אקראי',
                                  onPressed: () {
                                    serialController.text =
                                        generateRandomSerial();
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
                      if (Platform.isWindows && detectedMountPath != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: OutlinedButton.icon(
                            icon: isChangingSerial
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Icon(Icons.sync_alt),
                            label: const Text("שנה מספר סריאלי בהתקן"),
                            style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 40),
                                foregroundColor:
                                    Theme.of(context).colorScheme.primary),
                            onPressed: isChangingSerial
                                ? null
                                : () async {
                                    if (formKey.currentState?.validate() ??
                                        false) {
                                      setState(() => isChangingSerial = true);
                                      try {
                                        final resultMessage = await ref
                                            .read(deviceServiceProvider)
                                            .changeVolumeSerialNumber(
                                                detectedMountPath!,
                                                serialController.text);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    'הפעולה הצליחה: $resultMessage'),
                                                backgroundColor: Colors.green),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text('שגיאה: $e'),
                                                backgroundColor: Colors.red),
                                          );
                                        }
                                      } finally {
                                        if (context.mounted) {
                                          setState(
                                              () => isChangingSerial = false);
                                        }
                                      }
                                    }
                                  },
                          ),
                        ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: sourcePathController,
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
                          value: selectedUserId,
                          hint: const Text('בחר משתמש לשיוך'),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'משתמש משוייך',
                          ),
                          items: users
                              .where((u) => !u.isAdmin)
                              .map((u) => DropdownMenuItem(
                                  value: u.id, child: Text(u.name)))
                              .toList(),
                          onChanged: (id) =>
                              setState(() => selectedUserId = id),
                          validator: (id) => id == null ? 'שדה חובה' : null,
                        ),
                        loading: () => const CircularProgressIndicator(),
                        error: (e, st) => Text("Error: $e"),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('ביטול')),
                FilledButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final serialNumber = serialController.text;
                      final companion = DevicesCompanion(
                        serialNumber: drift.Value(serialNumber),
                        sourcePath: drift.Value(sourcePathController.text),
                        userId: drift.Value(selectedUserId!),
                      );

                      try {
                        if (device == null) {
                          await ref
                              .read(databaseProvider)
                              .insertDevice(companion);
                        } else {
                          await ref.read(databaseProvider).updateDevice(
                              companion.copyWith(id: drift.Value(device.id)));
                        }
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('שגיאה בשמירה: $e'),
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
      },
    );
  }
}

class _SettingsManagementTab extends ConsumerWidget {
  const _SettingsManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);

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
                        onChanged: (value) {
                          ref.read(databaseProvider).updateAppSettings(
                                AppSettingsCompanion(
                                    convertToMp3: drift.Value(value)),
                              );
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
                            onChanged: (value) {
                              if (value != null) {
                                ref.read(databaseProvider).updateAppSettings(
                                      AppSettingsCompanion(
                                          mp3Bitrate: drift.Value(value)),
                                    );
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading settings: $e')),
      ),
    );
  }
}
