import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:torah_shiurim_transfer/core/database/database.dart';
import 'package:torah_shiurim_transfer/core/providers/providers.dart';
import 'package:torah_shiurim_transfer/models/device_info.dart';
import 'package:torah_shiurim_transfer/services/device_service.dart';

class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
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
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _UsersManagementTab(),
            _RabbisManagementTab(),
            _DevicesManagementTab(),
          ],
        ),
      ),
    );
  }
}

// --- Users Management Tab ---
class _UsersManagementTab extends ConsumerWidget {
  const _UsersManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showUserDialog(context, ref),
      ),
      body: usersAsync.when(
        data: (users) => ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              leading:
                  Icon(user.isAdmin ? Icons.shield_outlined : Icons.person),
              title: Text(user.name),
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
                    onPressed: () async {
                      await ref.read(databaseProvider).deleteUser(user.id);
                    },
                  ),
                ],
              ),
              onTap: () => _showUserDialog(context, ref, user: user),
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
                      decoration: const InputDecoration(labelText: 'שם משתמש'),
                      validator: (v) => v!.isEmpty ? 'שדה חובה' : null,
                    ),
                    CheckboxListTile(
                      title: const Text('האם מנהל?'),
                      value: isAdmin,
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
        ElevatedButton(
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

// --- Rabbis Management Tab ---
class _RabbisManagementTab extends ConsumerWidget {
  const _RabbisManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rabbisAsync = ref.watch(allRabbisProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showRabbiDialog(context, ref),
      ),
      body: rabbisAsync.when(
        data: (rabbis) => ListView.builder(
          itemCount: rabbis.length,
          itemBuilder: (context, index) {
            final rabbi = rabbis[index];
            return ListTile(
              leading: const Icon(Icons.folder_special_outlined),
              title: Text(rabbi.name),
              subtitle: Text('נתיב: ${rabbi.targetPath}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await ref.read(databaseProvider).deleteRabbi(rabbi.id);
                },
              ),
              onTap: () => _showRabbiDialog(context, ref, rabbi: rabbi),
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
                decoration: const InputDecoration(labelText: 'שם הרב'),
                validator: (v) => v!.isEmpty ? 'שדה חובה' : null,
              ),
              TextFormField(
                controller: pathController,
                readOnly: true, // Make it read-only to force using the button
                decoration: InputDecoration(
                  labelText: 'נתיב יעד (במחשב)',
                  suffixIcon: IconButton(
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
                // FIXED: Removed the incorrect 'drift.' prefix.
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

// --- Devices Management Tab ---
class _DevicesManagementTab extends ConsumerWidget {
  const _DevicesManagementTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(allDevicesProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showDeviceDialog(context, ref),
      ),
      body: devicesAsync.when(
        data: (devices) => ListView.builder(
          itemCount: devices.length,
          itemBuilder: (context, index) {
            final deviceWithUser = devices[index];
            final device = deviceWithUser.device;
            final user = deviceWithUser.user;
            return ListTile(
              leading: const Icon(Icons.memory),
              title: Text('התקן: ${device.serialNumber}'),
              subtitle: Text(
                  'משוייך ל: ${user.name}\nנתיב מקור: ${device.sourcePath}'),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await ref.read(databaseProvider).deleteDevice(device.id);
                },
              ),
              onTap: () => _showDeviceDialog(context, ref, device: device),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.folder_open),
                      label: const Text("בחר תיקיית מקור"),
                      onPressed: () async {
                        // 1. Let user pick a directory.
                        final selectedPath =
                            await FilePicker.platform.getDirectoryPath(
                          lockParentWindow: true,
                          dialogTitle: 'בחר תיקיית מקור מההתקן החיצוני',
                        );
                        if (selectedPath == null) return; // User canceled.

                        // 2. Find the drive that contains this path.
                        final devices = await DeviceService()
                            .watchConnectedDevices()
                            .first;
                        if (devices.isEmpty) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("לא נמצאו כוננים חיצוניים.")),
                            );
                          }
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      "התיקיה שנבחרה אינה נמצאת על כונן חיצוני מזוהה.")),
                            );
                          }
                          return;
                        }

                        // 3. Calculate relative path.
                        String relativePath = selectedPath
                            .substring(drive.mountPath.length)
                            .trim();
                        if (relativePath.startsWith(r'\')) {
                          relativePath = relativePath.substring(1);
                        }

                        // 4. Update controllers.
                        setState(() {
                          serialController.text = drive!.serialNumber;
                          sourcePathController.text = relativePath;
                        });
                      },
                    ),
                    TextFormField(
                      controller: serialController,
                      readOnly: true, // Serial should be read-only
                      decoration: const InputDecoration(
                        labelText: 'מספר סידורי (מזוהה אוטומטית)',
                      ),
                      validator: (v) => v!.isEmpty ? 'שדה חובה' : null,
                    ),
                    TextFormField(
                      controller: sourcePathController,
                      decoration: const InputDecoration(
                        labelText: 'נתיב מקור (יחסית לכונן)',
                        hintText: 'לדוגמה: records (או ריק לשורש הכונן)',
                      ),
                      // Validator is now optional
                    ),
                    usersAsync.when(
                      data: (users) => DropdownButtonFormField<int>(
                        value: selectedUserId,
                        hint: const Text('בחר משתמש לשיוך'),
                        items: users
                            .where((u) => !u.isAdmin)
                            .map((u) => DropdownMenuItem(
                                value: u.id, child: Text(u.name)))
                            .toList(),
                        onChanged: (id) => setState(() => selectedUserId = id),
                        validator: (id) => id == null ? 'שדה חובה' : null,
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (e, st) => Text("Error: $e"),
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
                      final serialNumber = serialController.text;
                      final currentId = device?.id;

                      // Check if the serial number is already used by ANOTHER device.
                      final allDevices =
                          await ref.read(allDevicesProvider.future);
                      final conflictingDevice = allDevices.where((d) {
                        return d.device.serialNumber == serialNumber &&
                            d.device.id != currentId;
                      });

                      if (conflictingDevice.isNotEmpty) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'שגיאה: המספר הסידורי כבר משויך להתקן אחר.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return; // Stop execution
                      }

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
